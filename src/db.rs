use sqlx::{sqlite::SqlitePoolOptions, SqlitePool};
use std::path::Path;

pub async fn connect(database_url: &str) -> Result<SqlitePool, sqlx::Error> {
    if database_url.starts_with("sqlite:") && !database_url.contains(":memory:") {
        if let Some(path) = database_url.strip_prefix("sqlite:") {
            let path = path.split('?').next().unwrap_or(path);
            if let Some(parent) = Path::new(path).parent() {
                std::fs::create_dir_all(parent).ok();
            }
        }
    }
    let pool = SqlitePoolOptions::new()
        .max_connections(8)
        .connect(database_url)
        .await?;
    for statement in include_str!("../migrations/0001_initial.sql").split(';') {
        let statement = statement.trim();
        if !statement.is_empty() {
            sqlx::query(statement).execute(&pool).await?;
        }
    }
    Ok(pool)
}

