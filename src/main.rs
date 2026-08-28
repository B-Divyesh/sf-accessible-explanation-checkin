mod db;
mod http_policy;
mod routes;

use axum::{
    extract::Request,
    http::{header, HeaderName, HeaderValue},
    middleware,
    response::Response,
    Router,
};
use routes::AppState;
use std::{net::SocketAddr, path::PathBuf, sync::Arc, time::Duration};
use tokio::net::TcpListener;
use tower_governor::{governor::GovernorConfigBuilder, GovernorLayer};
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
    let (database_url, database_supplied) =
        config_value("DATABASE_URL", "sqlite:data/checkins.db?mode=rwc");
    let (uploads_dir, uploads_supplied) = config_value("UPLOADS_DIR", "data/uploads");
    let (dist_dir, dist_supplied) = config_value("DIST_DIR", "dist");
    let (billing_base, billing_supplied) =
        config_value("BILLING_BASE_URL", "https://api.sociobot.in");
    let (build_sha, build_sha_supplied) = config_value("BUILD_SHA", "development");
    tracing::info!(
        database = config_source(database_supplied),
        uploads = config_source(uploads_supplied),
        dist = config_source(dist_supplied),
        billing = config_source(billing_supplied),
        build_sha = config_source(build_sha_supplied),
        "runtime configuration initialized"
    );
    let state = Arc::new(AppState {
        pool: db::connect(&database_url).await?,
        uploads_dir: PathBuf::from(uploads_dir),
        billing_base,
        http: reqwest::Client::builder()
            .timeout(Duration::from_secs(8))
            .build()?,
        build_sha,
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
    let static_service =
        ServeDir::new(&dist_dir).fallback(ServeFile::new(dist_dir.join("index.html")));
    let rate_limit = Arc::new(
        GovernorConfigBuilder::default()
            .per_second(1)
            .burst_size(120)
            .finish()
            .expect("valid rate limit"),
    );
    let cache_build_sha = state.build_sha.clone();
    let app = Router::new().merge(routes::router(state)).fallback_service(static_service)
        .layer(middleware::from_fn_with_state(cache_build_sha, response_policy))
        .layer(GovernorLayer { config: rate_limit })
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
