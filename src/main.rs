mod db;
mod routes;

use axum::{http::{header, HeaderName, HeaderValue}, Router};
use routes::AppState;
use std::{net::SocketAddr, path::PathBuf, sync::Arc, time::Duration};
use tokio::net::TcpListener;
use tower_http::{
    compression::CompressionLayer,
    request_id::{MakeRequestUuid, PropagateRequestIdLayer, SetRequestIdLayer},
    services::{ServeDir, ServeFile},
    set_header::SetResponseHeaderLayer,
    trace::TraceLayer,
};
use tower_governor::{governor::GovernorConfigBuilder, GovernorLayer};

#[tokio::main]
async fn main() -> Result<(), Box<dyn std::error::Error>> {
    tracing_subscriber::fmt().json().with_env_filter(tracing_subscriber::EnvFilter::try_from_default_env().unwrap_or_else(|_| "info,tower_http=info".into())).init();
    let database_url = std::env::var("DATABASE_URL").unwrap_or_else(|_| "sqlite:data/checkins.db?mode=rwc".into());
    let uploads_dir = PathBuf::from(std::env::var("UPLOADS_DIR").unwrap_or_else(|_| "data/uploads".into()));
    let dist_dir = PathBuf::from(std::env::var("DIST_DIR").unwrap_or_else(|_| "dist".into()));
    let state = Arc::new(AppState { pool: db::connect(&database_url).await?, uploads_dir, billing_base: std::env::var("BILLING_BASE_URL").unwrap_or_else(|_| "https://pilot-api.sociobot.in".into()), http: reqwest::Client::builder().timeout(Duration::from_secs(8)).build()?, build_sha: std::env::var("BUILD_SHA").unwrap_or_else(|_| "development".into()) });
    if let Ok(count) = routes::cleanup_expired_voice(&state).await { tracing::info!(count, "expired voice cleanup complete"); }
    let cleanup_state = state.clone();
    tokio::spawn(async move { let mut timer=tokio::time::interval(Duration::from_secs(3600)); loop { timer.tick().await; if let Err(error)=routes::cleanup_expired_voice(&cleanup_state).await { tracing::error!(%error,"voice cleanup failed"); } } });
    let request_id = HeaderName::from_static("x-request-id");
    let static_service = ServeDir::new(&dist_dir).fallback(ServeFile::new(dist_dir.join("index.html")));
    let rate_limit = Arc::new(GovernorConfigBuilder::default().per_second(1).burst_size(120).finish().expect("valid rate limit"));
    let app = Router::new().merge(routes::router(state)).fallback_service(static_service)
        .layer(GovernorLayer { config: rate_limit })
        .layer(SetResponseHeaderLayer::if_not_present(header::X_CONTENT_TYPE_OPTIONS, HeaderValue::from_static("nosniff")))
        .layer(SetResponseHeaderLayer::if_not_present(header::REFERRER_POLICY, HeaderValue::from_static("no-referrer")))
        .layer(SetResponseHeaderLayer::if_not_present(header::CONTENT_SECURITY_POLICY, HeaderValue::from_static("default-src 'self'; img-src 'self' data:; media-src 'self' blob:; connect-src 'self' https://pilot-api.sociobot.in https://api.sociobot.in; style-src 'self' 'unsafe-inline'; script-src 'self'; base-uri 'none'; frame-ancestors 'none'; form-action 'self' https://pilot-api.sociobot.in https://api.sociobot.in")))
        .layer(CompressionLayer::new()).layer(TraceLayer::new_for_http())
        .layer(PropagateRequestIdLayer::new(request_id.clone())).layer(SetRequestIdLayer::new(request_id, MakeRequestUuid));
    let port: u16 = std::env::var("PORT").ok().and_then(|v|v.parse().ok()).unwrap_or(8080);
    let address = SocketAddr::from(([0,0,0,0],port));
    tracing::info!(%address, "server listening");
    axum::serve(TcpListener::bind(address).await?, app.into_make_service_with_connect_info::<SocketAddr>()).with_graceful_shutdown(shutdown()).await?;
    Ok(())
}

async fn shutdown() { let ctrl_c=async { tokio::signal::ctrl_c().await.expect("install Ctrl+C handler"); }; #[cfg(unix)] let terminate=async { tokio::signal::unix::signal(tokio::signal::unix::SignalKind::terminate()).expect("install SIGTERM handler").recv().await; }; #[cfg(not(unix))] let terminate=std::future::pending::<()>(); tokio::select! { _=ctrl_c=>{}, _=terminate=>{} } tracing::info!("shutdown signal received"); }
