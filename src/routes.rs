use axum::{
    extract::{DefaultBodyLimit, Path, State},
    http::{header, HeaderValue, StatusCode},
    response::{IntoResponse, Response},
    routing::{get, patch, post},
    Json, Router,
};
use base64::{engine::general_purpose::STANDARD as BASE64, Engine};
use chrono::{Duration, SecondsFormat, Utc};
use serde::{Deserialize, Serialize};
use serde_json::{json, Value};
use sqlx::{Row, SqlitePool};
use std::{path::PathBuf, sync::Arc};
use tokio::fs;
use uuid::Uuid;

const PRODUCT_SLUG: &str = "accessible-explanation-checkin";

#[derive(Clone)]
pub struct AppState {
    pub pool: SqlitePool,
    pub uploads_dir: PathBuf,
    pub billing_base: String,
    pub http: reqwest::Client,
    pub build_sha: String,
    pub database_file: Option<PathBuf>,
    pub persistence_dir: Option<PathBuf>,
}

#[derive(Debug)]
pub struct ApiError(StatusCode, String);

impl IntoResponse for ApiError {
    fn into_response(self) -> Response {
        (self.0, Json(json!({ "error": self.1 }))).into_response()
    }
}

impl From<sqlx::Error> for ApiError {
    fn from(error: sqlx::Error) -> Self {
        tracing::error!(%error, "database request failed");
        Self(
            StatusCode::INTERNAL_SERVER_ERROR,
            "The record could not be saved. Try again.".into(),
        )
    }
}

pub fn router(state: Arc<AppState>) -> Router {
    Router::new()
        .route("/health", get(health))
        .route("/api/checkins", post(create_checkin))
        .route("/api/checkins/:token", get(get_checkin))
        .route("/api/checkins/:token/submissions", post(create_submission))
        .route("/api/reviews/:token", get(get_review))
        .route(
            "/api/reviews/:token/submissions/:id",
            patch(update_submission),
        )
        .route(
            "/api/reviews/:token/submissions/:id/voice",
            get(get_voice).delete(delete_voice),
        )
        .route("/api/reviews/:token/export.csv", get(export_csv))
        .route("/api/receipts/:token", get(get_receipt))
        .layer(DefaultBodyLimit::max(6 * 1024 * 1024))
        .with_state(state)
}

async fn health(State(state): State<Arc<AppState>>) -> Json<Value> {
    Json(json!({ "status": "ok", "build_sha": state.build_sha }))
}

#[derive(Deserialize)]
struct CreateCheckin {
    title: String,
    prompt: String,
    voice_retention_days: i64,
    license: Option<String>,
}

#[derive(Serialize)]
struct CreatedCheckin {
    student_token: String,
    review_token: String,
    max_submissions: i64,
    voice_retention_days: i64,
}

async fn license_valid(state: &AppState, token: &str) -> bool {
    if token.len() > 2048 || token.is_empty() {
        return false;
    }
    let url = format!(
        "{}/api/v1/products/{}/verify",
        state.billing_base.trim_end_matches('/'),
        PRODUCT_SLUG
    );
    match state
        .http
        .get(url)
        .query(&[("license", token)])
        .send()
        .await
    {
        Ok(response) => response
            .json::<Value>()
            .await
            .ok()
            .and_then(|v| v["valid"].as_bool())
            .unwrap_or(false),
        Err(error) => {
            tracing::warn!(%error, "license verification unavailable");
            false
        }
    }
}

async fn create_checkin(
    State(state): State<Arc<AppState>>,
    Json(input): Json<CreateCheckin>,
) -> Result<(StatusCode, Json<CreatedCheckin>), ApiError> {
    let title = clean(&input.title, 1, 120, "Assignment name")?;
    let prompt = clean(&input.prompt, 4, 1200, "Prompt")?;
    let paid = match input.license.as_deref() {
        Some(token) => license_valid(&state, token).await,
        None => false,
    };
    let retention_max = if paid { 365 } else { 7 };
    if !(1..=retention_max).contains(&input.voice_retention_days) {
        return Err(ApiError(
            StatusCode::BAD_REQUEST,
            format!("Voice retention must be between 1 and {retention_max} days for this tier."),
        ));
    }
    let max_submissions = if paid { 500 } else { 35 };
    let id = Uuid::new_v4().to_string();
    let student_token = token();
    let review_token = token();
    sqlx::query("INSERT INTO checkins (id, student_token, review_token, title, prompt, created_at, voice_retention_days, max_submissions) VALUES (?, ?, ?, ?, ?, ?, ?, ?)")
        .bind(id).bind(&student_token).bind(&review_token).bind(title).bind(prompt)
        .bind(now()).bind(input.voice_retention_days).bind(max_submissions)
        .execute(&state.pool).await?;
    persist_database(&state).await?;
    Ok((
        StatusCode::CREATED,
        Json(CreatedCheckin {
            student_token,
            review_token,
            max_submissions,
            voice_retention_days: input.voice_retention_days,
        }),
    ))
}

#[derive(Serialize)]
struct PublicCheckin {
    title: String,
    prompt: String,
    voice_retention_days: i64,
    open: bool,
    submissions: i64,
    max_submissions: i64,
}

async fn get_checkin(
    State(state): State<Arc<AppState>>,
    Path(token): Path<String>,
) -> Result<Json<PublicCheckin>, ApiError> {
    let row = sqlx::query("SELECT c.title, c.prompt, c.voice_retention_days, c.max_submissions, COUNT(s.id) AS submissions FROM checkins c LEFT JOIN submissions s ON s.checkin_id=c.id WHERE c.student_token=? GROUP BY c.id")
        .bind(token).fetch_optional(&state.pool).await?.ok_or_else(not_found)?;
    let submissions: i64 = row.get("submissions");
    let max_submissions: i64 = row.get("max_submissions");
    Ok(Json(PublicCheckin {
        title: row.get("title"),
        prompt: row.get("prompt"),
        voice_retention_days: row.get("voice_retention_days"),
        open: submissions < max_submissions,
        submissions,
        max_submissions,
    }))
}

#[derive(Deserialize)]
struct NewSubmission {
    student_name: String,
    explanation_text: Option<String>,
    confidence: i64,
    voice_data: Option<String>,
    voice_mime: Option<String>,
}

#[derive(Serialize)]
struct CreatedSubmission {
    receipt_token: String,
    created_at: String,
    voice_delete_at: Option<String>,
}

async fn create_submission(
    State(state): State<Arc<AppState>>,
    Path(student_token): Path<String>,
    Json(input): Json<NewSubmission>,
) -> Result<(StatusCode, Json<CreatedSubmission>), ApiError> {
    let name = clean(&input.student_name, 1, 80, "Name")?;
    if !(1..=5).contains(&input.confidence) {
        return Err(ApiError(
            StatusCode::BAD_REQUEST,
            "Choose a confidence from 1 to 5.".into(),
        ));
    }
    let explanation = input
        .explanation_text
        .as_deref()
        .map(str::trim)
        .filter(|v| !v.is_empty())
        .map(str::to_string);
    if explanation
        .as_ref()
        .is_some_and(|v| v.chars().count() > 4000)
    {
        return Err(ApiError(
            StatusCode::BAD_REQUEST,
            "Explanation must be 4,000 characters or fewer.".into(),
        ));
    }
    if explanation.is_none() && input.voice_data.is_none() {
        return Err(ApiError(
            StatusCode::BAD_REQUEST,
            "Add a text explanation, a voice explanation, or both.".into(),
        ));
    }
    let checkin = sqlx::query("SELECT voice_retention_days FROM checkins WHERE student_token=?")
        .bind(&student_token)
        .fetch_optional(&state.pool)
        .await?
        .ok_or_else(not_found)?;
    let id = Uuid::new_v4().to_string();
    let receipt_token = token();
    let created_at = now();
    let mut voice_file: Option<String> = None;
    let mut voice_mime: Option<String> = None;
    let mut voice_delete_at: Option<String> = None;
    if let Some(encoded) = input.voice_data {
        let mime = input.voice_mime.as_deref().unwrap_or("");
        if !["audio/webm", "audio/ogg", "audio/mp4", "audio/mpeg"]
            .iter()
            .any(|allowed| mime.starts_with(allowed))
        {
            return Err(ApiError(
                StatusCode::BAD_REQUEST,
                "That recording format is not supported. Use text instead or try another browser."
                    .into(),
            ));
        }
        let bytes = BASE64.decode(encoded).map_err(|_| {
            ApiError(
                StatusCode::BAD_REQUEST,
                "The voice recording could not be read. Record it again.".into(),
            )
        })?;
        if bytes.len() > 4 * 1024 * 1024 {
            return Err(ApiError(
                StatusCode::PAYLOAD_TOO_LARGE,
                "The voice recording is over 4 MB. Record a shorter explanation or use text."
                    .into(),
            ));
        }
        fs::create_dir_all(&state.uploads_dir)
            .await
            .map_err(io_error)?;
        let filename = format!("{}.audio", id);
        fs::write(state.uploads_dir.join(&filename), bytes)
            .await
            .map_err(io_error)?;
        voice_file = Some(filename);
        voice_mime = Some(mime.to_string());
        let days: i64 = checkin.get("voice_retention_days");
        voice_delete_at =
            Some((Utc::now() + Duration::days(days)).to_rfc3339_opts(SecondsFormat::Secs, true));
    }
    // Keep the count predicate and insert in one SQLite statement. With the
    // pool's single writer connection this is atomic even when many students
    // submit at the same instant.
    let result = sqlx::query("INSERT INTO submissions (id, checkin_id, receipt_token, student_name, explanation_text, confidence, voice_file, voice_mime, voice_delete_at, created_at) SELECT ?, c.id, ?, ?, ?, ?, ?, ?, ?, ? FROM checkins c WHERE c.student_token=? AND (SELECT COUNT(*) FROM submissions s WHERE s.checkin_id=c.id) < c.max_submissions")
        .bind(&id).bind(&receipt_token).bind(name).bind(explanation).bind(input.confidence)
        .bind(&voice_file).bind(&voice_mime).bind(&voice_delete_at).bind(&created_at).bind(&student_token).execute(&state.pool).await;
    let result = match result {
        Ok(result) => result,
        Err(error) => {
            if let Some(filename) = voice_file {
                let _ = fs::remove_file(state.uploads_dir.join(filename)).await;
            }
            return Err(error.into());
        }
    };
    if result.rows_affected() == 0 {
        if let Some(filename) = voice_file {
            let _ = fs::remove_file(state.uploads_dir.join(filename)).await;
        }
        return Err(ApiError(
            StatusCode::CONFLICT,
            "This check-in has reached its submission limit. Ask your teacher for a new link."
                .into(),
        ));
    }
    persist_database(&state).await?;
    Ok((
        StatusCode::CREATED,
        Json(CreatedSubmission {
            receipt_token,
            created_at,
            voice_delete_at,
        }),
    ))
}

#[derive(Serialize)]
struct Review {
    title: String,
    prompt: String,
    voice_retention_days: i64,
    submissions: Vec<Submission>,
}
#[derive(Serialize)]
struct Submission {
    id: String,
    student_name: String,
    explanation_text: Option<String>,
    confidence: i64,
    has_voice: bool,
    voice_delete_at: Option<String>,
    created_at: String,
    teacher_tags: Vec<String>,
    teacher_note: String,
    follow_up: bool,
    receipt_token: String,
}

async fn get_review(
    State(state): State<Arc<AppState>>,
    Path(review_token): Path<String>,
) -> Result<Json<Review>, ApiError> {
    let checkin = sqlx::query(
        "SELECT id, title, prompt, voice_retention_days FROM checkins WHERE review_token=?",
    )
    .bind(review_token)
    .fetch_optional(&state.pool)
    .await?
    .ok_or_else(not_found)?;
    let rows = sqlx::query("SELECT id, student_name, explanation_text, confidence, voice_file, voice_delete_at, created_at, teacher_tags, teacher_note, follow_up, receipt_token FROM submissions WHERE checkin_id=? ORDER BY created_at DESC")
        .bind(checkin.get::<String,_>("id")).fetch_all(&state.pool).await?;
    let submissions = rows.into_iter().map(row_to_submission).collect();
    Ok(Json(Review {
        title: checkin.get("title"),
        prompt: checkin.get("prompt"),
        voice_retention_days: checkin.get("voice_retention_days"),
        submissions,
    }))
}

fn row_to_submission(row: sqlx::sqlite::SqliteRow) -> Submission {
    let tags: String = row.get("teacher_tags");
    Submission {
        id: row.get("id"),
        student_name: row.get("student_name"),
        explanation_text: row.get("explanation_text"),
        confidence: row.get("confidence"),
        has_voice: row.get::<Option<String>, _>("voice_file").is_some(),
        voice_delete_at: row.get("voice_delete_at"),
        created_at: row.get("created_at"),
        teacher_tags: serde_json::from_str(&tags).unwrap_or_default(),
        teacher_note: row.get("teacher_note"),
        follow_up: row.get::<i64, _>("follow_up") == 1,
        receipt_token: row.get("receipt_token"),
    }
}

#[derive(Deserialize)]
struct ReviewUpdate {
    teacher_tags: Vec<String>,
    teacher_note: String,
    follow_up: bool,
}

async fn update_submission(
    State(state): State<Arc<AppState>>,
    Path((review_token, id)): Path<(String, String)>,
    Json(input): Json<ReviewUpdate>,
) -> Result<Json<Value>, ApiError> {
    let allowed = [
        "Clear reasoning",
        "Needs follow-up",
        "New strategy",
        "AI use discussed",
        "Misconception",
    ];
    if input.teacher_tags.len() > 5
        || input
            .teacher_tags
            .iter()
            .any(|t| !allowed.contains(&t.as_str()))
    {
        return Err(ApiError(
            StatusCode::BAD_REQUEST,
            "One or more review tags are not recognized.".into(),
        ));
    }
    if input.teacher_note.chars().count() > 1000 {
        return Err(ApiError(
            StatusCode::BAD_REQUEST,
            "Teacher note must be 1,000 characters or fewer.".into(),
        ));
    }
    let result = sqlx::query("UPDATE submissions SET teacher_tags=?, teacher_note=?, follow_up=? WHERE id=? AND checkin_id=(SELECT id FROM checkins WHERE review_token=?)")
        .bind(serde_json::to_string(&input.teacher_tags).unwrap()).bind(input.teacher_note.trim()).bind(input.follow_up as i64).bind(id).bind(review_token).execute(&state.pool).await?;
    if result.rows_affected() == 0 {
        return Err(not_found());
    }
    persist_database(&state).await?;
    Ok(Json(json!({"saved": true})))
}

async fn get_voice(
    State(state): State<Arc<AppState>>,
    Path((review_token, id)): Path<(String, String)>,
) -> Result<Response, ApiError> {
    let row = sqlx::query("SELECT voice_file, voice_mime FROM submissions WHERE id=? AND checkin_id=(SELECT id FROM checkins WHERE review_token=?)").bind(id).bind(review_token).fetch_optional(&state.pool).await?.ok_or_else(not_found)?;
    let filename: Option<String> = row.get("voice_file");
    let filename = filename.ok_or_else(|| {
        ApiError(
            StatusCode::GONE,
            "This voice recording has been deleted.".into(),
        )
    })?;
    let bytes = fs::read(state.uploads_dir.join(filename))
        .await
        .map_err(|_| {
            ApiError(
                StatusCode::GONE,
                "This voice recording has been deleted.".into(),
            )
        })?;
    let mime: String = row
        .get::<Option<String>, _>("voice_mime")
        .unwrap_or_else(|| "audio/webm".into());
    Ok((
        [
            (
                header::CONTENT_TYPE,
                HeaderValue::from_str(&mime).unwrap_or(HeaderValue::from_static("audio/webm")),
            ),
            (
                header::CACHE_CONTROL,
                HeaderValue::from_static("private, no-store"),
            ),
        ],
        bytes,
    )
        .into_response())
}

async fn delete_voice(
    State(state): State<Arc<AppState>>,
    Path((review_token, id)): Path<(String, String)>,
) -> Result<Json<Value>, ApiError> {
    let row = sqlx::query("SELECT voice_file FROM submissions WHERE id=? AND checkin_id=(SELECT id FROM checkins WHERE review_token=?)").bind(&id).bind(&review_token).fetch_optional(&state.pool).await?.ok_or_else(not_found)?;
    if let Some(filename) = row.get::<Option<String>, _>("voice_file") {
        let _ = fs::remove_file(state.uploads_dir.join(filename)).await;
    }
    sqlx::query("UPDATE submissions SET voice_file=NULL, voice_mime=NULL, voice_delete_at=NULL WHERE id=? AND checkin_id=(SELECT id FROM checkins WHERE review_token=?)").bind(id).bind(review_token).execute(&state.pool).await?;
    persist_database(&state).await?;
    Ok(Json(json!({"deleted": true})))
}

async fn get_receipt(
    State(state): State<Arc<AppState>>,
    Path(token): Path<String>,
) -> Result<Json<Value>, ApiError> {
    let row = sqlx::query("SELECT s.student_name, s.explanation_text, s.confidence, s.created_at, s.voice_file, s.voice_delete_at, c.title, c.prompt FROM submissions s JOIN checkins c ON c.id=s.checkin_id WHERE s.receipt_token=?")
        .bind(token).fetch_optional(&state.pool).await?.ok_or_else(not_found)?;
    Ok(Json(
        json!({"student_name":row.get::<String,_>("student_name"), "explanation_text":row.get::<Option<String>,_>("explanation_text"), "confidence":row.get::<i64,_>("confidence"), "created_at":row.get::<String,_>("created_at"), "has_voice":row.get::<Option<String>,_>("voice_file").is_some(), "voice_delete_at":row.get::<Option<String>,_>("voice_delete_at"), "title":row.get::<String,_>("title"), "prompt":row.get::<String,_>("prompt")}),
    ))
}

async fn export_csv(
    State(state): State<Arc<AppState>>,
    Path(review_token): Path<String>,
) -> Result<Response, ApiError> {
    let review = get_review(State(state), Path(review_token)).await?.0;
    let mut csv = String::from("student_name,confidence,submitted_at,explanation,tags,follow_up,teacher_note,voice_status\n");
    for s in review.submissions {
        let fields = [
            s.student_name,
            s.confidence.to_string(),
            s.created_at,
            s.explanation_text.unwrap_or_default(),
            s.teacher_tags.join("; "),
            s.follow_up.to_string(),
            s.teacher_note,
            if s.has_voice {
                "available".into()
            } else {
                "none or deleted".into()
            },
        ];
        csv.push_str(
            &fields
                .iter()
                .map(|v| csv_cell(v))
                .collect::<Vec<_>>()
                .join(","),
        );
        csv.push('\n');
    }
    Ok((
        [
            (header::CONTENT_TYPE, "text/csv; charset=utf-8"),
            (
                header::CONTENT_DISPOSITION,
                "attachment; filename=explanation-checkin.csv",
            ),
            (header::CACHE_CONTROL, "private, no-store"),
        ],
        csv,
    )
        .into_response())
}

pub async fn cleanup_expired_voice(state: &AppState) -> Result<u64, sqlx::Error> {
    let rows = sqlx::query("SELECT id, voice_file FROM submissions WHERE voice_file IS NOT NULL AND voice_delete_at <= ?").bind(now()).fetch_all(&state.pool).await?;
    let mut deleted = 0;
    for row in rows {
        if let Some(file) = row.get::<Option<String>, _>("voice_file") {
            let _ = fs::remove_file(state.uploads_dir.join(file)).await;
        }
        sqlx::query("UPDATE submissions SET voice_file=NULL, voice_mime=NULL, voice_delete_at=NULL WHERE id=?").bind(row.get::<String,_>("id")).execute(&state.pool).await?;
        deleted += 1;
    }
    if deleted > 0 {
        if let Err(error) = persist_database(state).await {
            tracing::error!(?error, "database snapshot failed after voice cleanup");
        }
    }
    Ok(deleted)
}

async fn persist_database(state: &AppState) -> Result<(), ApiError> {
    if let (Some(database_file), Some(persistence_dir)) =
        (&state.database_file, &state.persistence_dir)
    {
        crate::db::save_snapshot(database_file, persistence_dir)
            .await
            .map_err(io_error)?;
    }
    Ok(())
}

fn clean(value: &str, min: usize, max: usize, label: &str) -> Result<String, ApiError> {
    let trimmed = value.trim();
    let length = trimmed.chars().count();
    if length < min || length > max {
        Err(ApiError(
            StatusCode::BAD_REQUEST,
            format!("{label} must be between {min} and {max} characters."),
        ))
    } else {
        Ok(trimmed.to_string())
    }
}
fn token() -> String {
    Uuid::new_v4().simple().to_string()
}
fn now() -> String {
    Utc::now().to_rfc3339_opts(SecondsFormat::Secs, true)
}
fn not_found() -> ApiError {
    ApiError(
        StatusCode::NOT_FOUND,
        "That private link is not valid. Check that you copied the whole link.".into(),
    )
}
fn io_error(error: std::io::Error) -> ApiError {
    tracing::error!(%error, "file request failed");
    ApiError(
        StatusCode::INTERNAL_SERVER_ERROR,
        "The voice recording could not be stored. Your text has not been submitted; try again."
            .into(),
    )
}
fn csv_cell(value: &str) -> String {
    let safe = if value.starts_with(['=', '+', '-', '@']) {
        format!("'{value}")
    } else {
        value.to_string()
    };
    format!("\"{}\"", safe.replace('"', "\"\""))
}

#[cfg(test)]
mod tests {
    use super::*;
    use axum::{body::Body, http::Request};
    use http_body_util::BodyExt;
    use tower::ServiceExt;

    #[test]
    fn trims_and_validates_input() {
        assert_eq!(clean("  hello ", 1, 10, "Field").unwrap(), "hello");
        assert!(clean("", 1, 10, "Field").is_err());
    }
    #[test]
    fn escapes_csv_formula_and_quotes_as_text() {
        assert_eq!(csv_cell("a\"b"), "\"a\"\"b\"");
        assert_eq!(csv_cell("=2+2"), "\"'=2+2\"");
    }

    async fn json_response(response: Response) -> Value {
        let bytes = response.into_body().collect().await.unwrap().to_bytes();
        serde_json::from_slice(&bytes).unwrap()
    }

    async fn test_app() -> (Router, tempfile::TempDir) {
        let temp = tempfile::tempdir().unwrap();
        let database = format!("sqlite:{}?mode=rwc", temp.path().join("test.db").display());
        let state = Arc::new(AppState {
            pool: crate::db::connect(&database).await.unwrap(),
            uploads_dir: temp.path().join("uploads"),
            billing_base: "http://127.0.0.1:1".into(),
            http: reqwest::Client::new(),
            build_sha: "test".into(),
            database_file: None,
            persistence_dir: None,
        });
        (router(state), temp)
    }

    #[tokio::test]
    async fn complete_free_checkin_flow() {
        let (app, _temp) = test_app().await;
        let create = app.clone().oneshot(Request::post("/api/checkins").header("content-type", "application/json").body(Body::from(r#"{"title":"Water cycle","prompt":"What step changed your thinking?","voice_retention_days":3}"#)).unwrap()).await.unwrap();
        assert_eq!(create.status(), StatusCode::CREATED);
        let created = json_response(create).await;
        let student = created["student_token"].as_str().unwrap();
        let review = created["review_token"].as_str().unwrap();

        let public = app
            .clone()
            .oneshot(
                Request::get(format!("/api/checkins/{student}"))
                    .body(Body::empty())
                    .unwrap(),
            )
            .await
            .unwrap();
        assert_eq!(public.status(), StatusCode::OK);
        assert_eq!(json_response(public).await["title"], "Water cycle");

        let submit = app.clone().oneshot(Request::post(format!("/api/checkins/{student}/submissions")).header("content-type", "application/json").body(Body::from(r#"{"student_name":"Sam","explanation_text":"I checked evaporation against the diagram.","confidence":4,"voice_data":"dGVzdA==","voice_mime":"audio/webm"}"#)).unwrap()).await.unwrap();
        assert_eq!(submit.status(), StatusCode::CREATED);
        let receipt = json_response(submit).await["receipt_token"]
            .as_str()
            .unwrap()
            .to_string();

        let teacher = app
            .clone()
            .oneshot(
                Request::get(format!("/api/reviews/{review}"))
                    .body(Body::empty())
                    .unwrap(),
            )
            .await
            .unwrap();
        let teacher_json = json_response(teacher).await;
        let submission_id = teacher_json["submissions"][0]["id"].as_str().unwrap();
        assert_eq!(teacher_json["submissions"][0]["confidence"], 4);

        let update = app.clone().oneshot(Request::patch(format!("/api/reviews/{review}/submissions/{submission_id}")).header("content-type", "application/json").body(Body::from(r#"{"teacher_tags":["Clear reasoning"],"teacher_note":"Ask about condensation.","follow_up":true}"#)).unwrap()).await.unwrap();
        assert_eq!(update.status(), StatusCode::OK);

        let receipt_response = app
            .clone()
            .oneshot(
                Request::get(format!("/api/receipts/{receipt}"))
                    .body(Body::empty())
                    .unwrap(),
            )
            .await
            .unwrap();
        assert_eq!(json_response(receipt_response).await["student_name"], "Sam");
        let csv = app
            .clone()
            .oneshot(
                Request::get(format!("/api/reviews/{review}/export.csv"))
                    .body(Body::empty())
                    .unwrap(),
            )
            .await
            .unwrap();
        assert_eq!(csv.status(), StatusCode::OK);
        assert_eq!(
            csv.headers()[header::CONTENT_TYPE],
            "text/csv; charset=utf-8"
        );
        let voice = app
            .clone()
            .oneshot(
                Request::get(format!(
                    "/api/reviews/{review}/submissions/{submission_id}/voice"
                ))
                .body(Body::empty())
                .unwrap(),
            )
            .await
            .unwrap();
        assert_eq!(voice.status(), StatusCode::OK);
        assert_eq!(
            voice.into_body().collect().await.unwrap().to_bytes(),
            "test"
        );
        let delete = app
            .clone()
            .oneshot(
                Request::delete(format!(
                    "/api/reviews/{review}/submissions/{submission_id}/voice"
                ))
                .body(Body::empty())
                .unwrap(),
            )
            .await
            .unwrap();
        assert_eq!(delete.status(), StatusCode::OK);
        let health = app
            .oneshot(Request::get("/health").body(Body::empty()).unwrap())
            .await
            .unwrap();
        assert_eq!(json_response(health).await["build_sha"], "test");
    }

    #[tokio::test]
    async fn concurrent_submissions_stop_exactly_at_the_free_limit() {
        let (app, _temp) = test_app().await;
        let create = app
            .clone()
            .oneshot(
                Request::post("/api/checkins")
                    .header("content-type", "application/json")
                    .body(Body::from(r#"{"title":"Limit test","prompt":"Describe the choice you made.","voice_retention_days":1}"#))
                    .unwrap(),
            )
            .await
            .unwrap();
        let student = json_response(create).await["student_token"]
            .as_str()
            .unwrap()
            .to_owned();

        let mut submissions = Vec::new();
        for number in 0..40 {
            let app = app.clone();
            let student = student.clone();
            submissions.push(tokio::spawn(async move {
                app.oneshot(
                    Request::post(format!("/api/checkins/{student}/submissions"))
                        .header("content-type", "application/json")
                        .body(Body::from(format!(
                            r#"{{"student_name":"Student {number}","explanation_text":"I can explain my choice.","confidence":3}}"#
                        )))
                        .unwrap(),
                )
                .await
                .unwrap()
                .status()
            }));
        }
        let mut created = 0;
        let mut limited = 0;
        for submission in submissions {
            match submission.await.unwrap() {
                StatusCode::CREATED => created += 1,
                StatusCode::CONFLICT => limited += 1,
                status => panic!("unexpected submission status {status}"),
            }
        }
        assert_eq!(created, 35);
        assert_eq!(limited, 5);

        let checkin = app
            .oneshot(
                Request::get(format!("/api/checkins/{student}"))
                    .body(Body::empty())
                    .unwrap(),
            )
            .await
            .unwrap();
        let checkin = json_response(checkin).await;
        assert_eq!(checkin["submissions"], 35);
        assert_eq!(checkin["max_submissions"], 35);
        assert_eq!(checkin["open"], false);
    }
}
