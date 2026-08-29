use sqlx::{
    sqlite::{SqliteConnectOptions, SqliteJournalMode, SqlitePoolOptions},
    SqlitePool,
};
use std::{
    path::{Path, PathBuf},
    str::FromStr,
    time::Duration,
};
use tokio::{fs, io::AsyncWriteExt};

pub fn sqlite_path(database_url: &str) -> Option<PathBuf> {
    database_url
        .strip_prefix("sqlite:")
        .filter(|path| !path.starts_with(":memory:"))
        .map(|path| PathBuf::from(path.split('?').next().unwrap_or(path)))
}

pub async fn restore_snapshot(
    database_file: &Path,
    persistence_dir: &Path,
) -> Result<(), std::io::Error> {
    let snapshot = persistence_dir.join("checkins.db");
    let usable_snapshot = fs::metadata(&snapshot)
        .await
        .map(|metadata| metadata.len() > 0)
        .unwrap_or(false);
    if usable_snapshot {
        if let Some(parent) = database_file.parent() {
            fs::create_dir_all(parent).await?;
        }
        copy_contents(&snapshot, database_file).await?;
    }
    Ok(())
}

pub async fn save_snapshot(
    database_file: &Path,
    persistence_dir: &Path,
) -> Result<(), std::io::Error> {
    fs::create_dir_all(persistence_dir).await?;
    let snapshot = persistence_dir.join("checkins.db");
    // Azure Files does not permit POSIX rename or chmod operations. Rust's
    // fs::copy copies permission bits after the bytes and therefore fails with
    // EPERM on the mounted SMB share. Stream only the file contents instead.
    // One replica means no peer can read the snapshot while it is refreshed.
    copy_contents(database_file, &snapshot).await
}

async fn copy_contents(source: &Path, destination: &Path) -> Result<(), std::io::Error> {
    let mut source = fs::File::open(source).await?;
    let mut destination = fs::OpenOptions::new()
        .create(true)
        .truncate(true)
        .write(true)
        .open(destination)
        .await?;
    tokio::io::copy(&mut source, &mut destination).await?;
    destination.flush().await?;
    destination.sync_all().await
}

pub async fn connect(database_url: &str) -> Result<SqlitePool, sqlx::Error> {
    if database_url.starts_with("sqlite:") && !database_url.contains(":memory:") {
        if let Some(path) = sqlite_path(database_url) {
            if let Some(parent) = path.parent() {
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

#[cfg(test)]
mod tests {
    use super::*;

    #[tokio::test]
    async fn durable_snapshot_round_trips_a_local_database_file() {
        let temp = tempfile::tempdir().unwrap();
        let database_file = temp.path().join("runtime/checkins.db");
        let persistence_dir = temp.path().join("durable");
        fs::create_dir_all(database_file.parent().unwrap())
            .await
            .unwrap();
        fs::write(&database_file, b"sqlite snapshot").await.unwrap();
        save_snapshot(&database_file, &persistence_dir)
            .await
            .unwrap();
        fs::remove_file(&database_file).await.unwrap();
        restore_snapshot(&database_file, &persistence_dir)
            .await
            .unwrap();
        assert_eq!(fs::read(database_file).await.unwrap(), b"sqlite snapshot");
    }

    #[cfg(unix)]
    #[tokio::test]
    async fn durable_snapshot_replaces_bytes_without_copying_posix_permissions() {
        use std::os::unix::fs::PermissionsExt;

        let temp = tempfile::tempdir().unwrap();
        let database_file = temp.path().join("runtime.db");
        let persistence_dir = temp.path().join("durable");
        let snapshot = persistence_dir.join("checkins.db");
        fs::create_dir_all(&persistence_dir).await.unwrap();
        fs::write(&database_file, b"new snapshot").await.unwrap();
        fs::write(&snapshot, b"old snapshot").await.unwrap();
        fs::set_permissions(&database_file, std::fs::Permissions::from_mode(0o600))
            .await
            .unwrap();
        fs::set_permissions(&snapshot, std::fs::Permissions::from_mode(0o644))
            .await
            .unwrap();

        save_snapshot(&database_file, &persistence_dir)
            .await
            .unwrap();

        assert_eq!(fs::read(&snapshot).await.unwrap(), b"new snapshot");
        assert_eq!(
            fs::metadata(&snapshot).await.unwrap().permissions().mode() & 0o777,
            0o644
        );
    }
}
