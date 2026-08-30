mod db;
mod http_policy;
mod routes;

use axum::{
    extract::Request,
    http::{header, HeaderName, HeaderValue},
    middleware,
    response::{Html, IntoResponse, Response},
    routing::{get, get_service},
    Router,
};
use routes::AppState;
use std::{
    net::SocketAddr,
    path::{Path, PathBuf},
    sync::Arc,
    time::Duration,
};
use tokio::net::TcpListener;
use tower_governor::{
    governor::GovernorConfigBuilder, key_extractor::SmartIpKeyExtractor, GovernorLayer,
};
use tower_http::{
    compression::CompressionLayer,
    request_id::{MakeRequestUuid, PropagateRequestIdLayer, SetRequestIdLayer},
    services::{ServeDir, ServeFile},
    set_header::SetResponseHeaderLayer,
    trace::TraceLayer,
};

#[tokio::main]
async fn main() -> Result<(), Box<dyn std::error::Error>> {
    tracing_subscriber::fmt()
        .json()
        .with_env_filter(
            tracing_subscriber::EnvFilter::try_from_default_env()
                .unwrap_or_else(|_| "info,tower_http=info".into()),
        )
        .init();
    let (data_dir, data_dir_supplied) = config_value("DATA_DIR", &default_data_dir());
    let (database_url, database_supplied) = config_value(
        "DATABASE_URL",
        &format!("sqlite:{data_dir}/checkins.db?mode=rwc"),
    );
    let (uploads_dir, uploads_supplied) =
        config_value("UPLOADS_DIR", &format!("{data_dir}/uploads"));
    let (dist_dir, dist_supplied) = config_value("DIST_DIR", "dist");
    let (billing_base, billing_supplied) =
        config_value("BILLING_BASE_URL", "https://api.sociobot.in");
    let (build_sha, build_sha_supplied) = config_value("BUILD_SHA", "development");
    let persistence_dir = std::env::var("PERSISTENCE_DIR")
        .ok()
        .filter(|value| !value.trim().is_empty())
        .map(PathBuf::from);
    tracing::info!(
        database = config_source(database_supplied),
        data_dir = config_source(data_dir_supplied),
        uploads = config_source(uploads_supplied),
        dist = config_source(dist_supplied),
        billing = config_source(billing_supplied),
        build_sha = config_source(build_sha_supplied),
        persistence = if persistence_dir.is_some() {
            "supplied"
        } else {
            "generated_default"
        },
        "runtime configuration initialized"
    );
    let database_file = db::sqlite_path(&database_url);
    if let (Some(database_file), Some(persistence_dir)) = (&database_file, &persistence_dir) {
        db::restore_snapshot(database_file, persistence_dir).await?;
    }
    let state = Arc::new(AppState {
        pool: db::connect(&database_url).await?,
        uploads_dir: PathBuf::from(uploads_dir),
        billing_base,
        http: reqwest::Client::builder()
            .timeout(Duration::from_secs(8))
            .build()?,
        build_sha,
        database_file,
        persistence_dir,
    });
    if let Ok(count) = routes::cleanup_expired_voice(&state).await {
        tracing::info!(count, "expired voice cleanup complete");
    }
    let cleanup_state = state.clone();
    tokio::spawn(async move {
        let mut timer = tokio::time::interval(Duration::from_secs(3600));
        loop {
            timer.tick().await;
            if let Err(error) = routes::cleanup_expired_voice(&cleanup_state).await {
                tracing::error!(%error,"voice cleanup failed");
            }
        }
    });
    let request_id = HeaderName::from_static("x-request-id");
    let dist_dir = PathBuf::from(dist_dir);
    let index_file = ServeFile::new(dist_dir.join("index.html"));
    let static_files = Router::new()
        .nest_service("/assets", ServeDir::new(dist_dir.join("assets")))
        .route_service(
            "/doorway.svg",
            get_service(ServeFile::new(dist_dir.join("doorway.svg"))),
        )
        .route_service(
            "/apple-touch-icon.png",
            get_service(ServeFile::new(dist_dir.join("apple-touch-icon.png"))),
        )
        .route_service(
            "/manifest.webmanifest",
            get_service(ServeFile::new(dist_dir.join("manifest.webmanifest"))),
        )
        .route_service(
            "/robots.txt",
            get_service(ServeFile::new(dist_dir.join("robots.txt"))),
        )
        .route_service(
            "/sitemap.xml",
            get_service(ServeFile::new(dist_dir.join("sitemap.xml"))),
        )
        .route_service(
            "/sw.js",
            get_service(ServeFile::new(dist_dir.join("sw.js"))),
        );
    let spa = Router::new()
        .route_service("/", get_service(index_file.clone()))
        .route_service("/create", get_service(index_file.clone()))
        .route_service("/demo", get_service(index_file.clone()))
        .route_service("/pricing", get_service(index_file.clone()))
        .route_service("/privacy", get_service(index_file.clone()))
        .route_service("/terms", get_service(index_file.clone()))
        .route_service("/c/:token", get_service(index_file.clone()))
        .route_service("/review/:token", get_service(index_file.clone()))
        .route_service("/receipt/:token", get_service(index_file));
    let mut rate_limit_builder =
        GovernorConfigBuilder::default().key_extractor(SmartIpKeyExtractor);
    let rate_limit = Arc::new(
        rate_limit_builder
            .per_second(1)
            .burst_size(120)
            .finish()
            .expect("valid rate limit"),
    );
    let cache_build_sha = state.build_sha.clone();
    let api = routes::router(state).layer(GovernorLayer { config: rate_limit });
    let app = Router::new().merge(api).merge(static_files).merge(spa).fallback(get(not_found_page))
        .layer(middleware::from_fn_with_state(cache_build_sha, response_policy))
        .layer(SetResponseHeaderLayer::if_not_present(header::X_CONTENT_TYPE_OPTIONS, HeaderValue::from_static("nosniff")))
        .layer(SetResponseHeaderLayer::if_not_present(header::REFERRER_POLICY, HeaderValue::from_static("no-referrer")))
        .layer(SetResponseHeaderLayer::if_not_present(header::STRICT_TRANSPORT_SECURITY, HeaderValue::from_static("max-age=31536000; includeSubDomains")))
        .layer(SetResponseHeaderLayer::if_not_present(HeaderName::from_static("permissions-policy"), HeaderValue::from_static("camera=(), geolocation=(), payment=(), microphone=(self)")))
        .layer(SetResponseHeaderLayer::if_not_present(header::CONTENT_SECURITY_POLICY, HeaderValue::from_static("default-src 'self'; img-src 'self' data:; media-src 'self' blob:; connect-src 'self' https://api.sociobot.in; style-src 'self' 'unsafe-inline'; script-src 'self'; base-uri 'none'; frame-ancestors 'none'; form-action 'self' https://api.sociobot.in")))
        .layer(CompressionLayer::new()).layer(TraceLayer::new_for_http())
        .layer(PropagateRequestIdLayer::new(request_id.clone())).layer(SetRequestIdLayer::new(request_id, MakeRequestUuid));
    let port: u16 = std::env::var("PORT")
        .ok()
        .and_then(|v| v.parse().ok())
        .unwrap_or(8080);
    let address = SocketAddr::from(([0, 0, 0, 0], port));
    tracing::info!(%address, "server listening");
    axum::serve(
        TcpListener::bind(address).await?,
        app.into_make_service_with_connect_info::<SocketAddr>(),
    )
    .with_graceful_shutdown(shutdown())
    .await?;
    Ok(())
}

async fn not_found_page() -> Response {
    (
        axum::http::StatusCode::NOT_FOUND,
        Html(include_str!("../frontend/public/404.html")),
    )
        .into_response()
}

fn config_value(name: &str, default: &str) -> (String, bool) {
    match std::env::var(name) {
        Ok(value) if !value.trim().is_empty() => (value, true),
        _ => (default.into(), false),
    }
}

fn config_source(supplied: bool) -> &'static str {
    if supplied {
        "supplied"
    } else {
        "generated_default"
    }
}

fn default_data_dir() -> String {
    data_dir_for(Path::new("/data"))
}

fn data_dir_for(candidate: &Path) -> String {
    if candidate.is_dir() {
        candidate.display().to_string()
    } else {
        "data".into()
    }
}

async fn response_policy(
    axum::extract::State(build_sha): axum::extract::State<String>,
    request: Request,
    next: middleware::Next,
) -> Response {
    let path = request.uri().path().to_owned();
    http_policy::apply_response_policy(next.run(request).await, &path, &build_sha)
}

async fn shutdown() {
    let ctrl_c = async {
        tokio::signal::ctrl_c()
            .await
            .expect("install Ctrl+C handler");
    };
    #[cfg(unix)]
    let terminate = async {
        tokio::signal::unix::signal(tokio::signal::unix::SignalKind::terminate())
            .expect("install SIGTERM handler")
            .recv()
            .await;
    };
    #[cfg(not(unix))]
    let terminate = std::future::pending::<()>();
    tokio::select! { _=ctrl_c=>{}, _=terminate=>{} }
    tracing::info!("shutdown signal received");
}

#[cfg(test)]
mod tests {
    use super::*;
    use axum::{body::Body, http::Request};
    use tower::ServiceExt;

    #[test]
    fn default_data_directory_uses_the_factory_mount_when_present() {
        let mount = tempfile::tempdir().unwrap();
        assert_eq!(
            data_dir_for(mount.path()),
            mount.path().display().to_string()
        );
        assert_eq!(data_dir_for(Path::new("/does-not-exist")), "data");
    }

    #[tokio::test]
    async fn rate_limit_uses_forwarded_client_ip_and_returns_retry_after() {
        let mut builder = GovernorConfigBuilder::default().key_extractor(SmartIpKeyExtractor);
        let config = Arc::new(
            builder
                .per_second(60)
                .burst_size(2)
                .finish()
                .expect("valid test rate limit"),
        );
        let app = Router::new()
            .route("/api/test", get(|| async { "ok" }))
            .layer(GovernorLayer { config });

        for expected in [200, 200, 429] {
            let response = app
                .clone()
                .oneshot(
                    Request::get("/api/test")
                        .header("x-forwarded-for", "203.0.113.7, 10.0.0.1")
                        .body(Body::empty())
                        .unwrap(),
                )
                .await
                .unwrap();
            assert_eq!(response.status().as_u16(), expected);
            if expected == 429 {
                assert!(response.headers().contains_key(header::RETRY_AFTER));
            }
        }

        let other_client = app
            .oneshot(
                Request::get("/api/test")
                    .header("x-forwarded-for", "198.51.100.9")
                    .body(Body::empty())
                    .unwrap(),
            )
            .await
            .unwrap();
        assert_eq!(other_client.status(), axum::http::StatusCode::OK);
    }
}
