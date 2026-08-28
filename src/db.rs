use sqlx::{
    sqlite::{SqliteConnectOptions, SqliteJournalMode, SqlitePoolOptions},
    SqlitePool,
};
use std::{path::Path, str::FromStr, time::Duration};

pub async fn connect(database_url: &str) -> Result<SqlitePool, sqlx::Error> {
    if database_url.starts_with("sqlite:") && !database_url.contains(":memory:") {
        if let Some(path) = database_url.strip_prefix("sqlite:") {
            let path = path.split('?').next().unwrap_or(path);
            if let Some(parent) = Path::new(path).parent() {
                std::fs::create_dir_all(parent).ok();
            }
        }
    }
    // Azure Files is a durable SMB volume. DELETE journaling and an explicit
    // busy timeout avoid WAL side files and allow its file-lock propagation to
    // settle before schema setup or a write gives up.
    let options = SqliteConnectOptions::from_str(database_url)?
        .create_if_missing(true)
        .journal_mode(SqliteJournalMode::Delete)
        .busy_timeout(Duration::from_secs(30));
    let pool = SqlitePoolOptions::new()
        // This service is deliberately deployed as one durable SQLite writer.
        // A single connection serializes quota checks and writes, avoiding both
        // SQLite lock storms and a read-then-insert quota race.
        .max_connections(1)
        .connect_with(options)
        .await?;
    for statement in include_str!("../migrations/0001_initial.sql").split(';') {
        let statement = statement.trim();
        if !statement.is_empty() {
            let mut retry_delay = Duration::from_millis(250);
            let mut last_error = None;
            for attempt in 0..5 {
                match sqlx::query(statement).execute(&pool).await {
                    Ok(_) => {
                        last_error = None;
                        break;
                    }
                    Err(error) if is_locked(&error) && attempt < 4 => {
                        last_error = Some(error);
                        tokio::time::sleep(retry_delay).await;
                        retry_delay *= 2;
                    }
                    Err(error) => return Err(error),
                }
            }
            if let Some(error) = last_error {
                return Err(error);
            }
        }
    }
    Ok(pool)
}

fn is_locked(error: &sqlx::Error) -> bool {
    error.to_string().contains("database is locked")
}
