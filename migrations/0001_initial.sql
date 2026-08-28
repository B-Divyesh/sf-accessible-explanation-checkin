PRAGMA foreign_keys = ON;

CREATE TABLE IF NOT EXISTS checkins (
    id TEXT PRIMARY KEY,
    student_token TEXT NOT NULL UNIQUE,
    review_token TEXT NOT NULL UNIQUE,
    title TEXT NOT NULL,
    prompt TEXT NOT NULL,
    created_at TEXT NOT NULL,
    voice_retention_days INTEGER NOT NULL,
    max_submissions INTEGER NOT NULL
);

CREATE TABLE IF NOT EXISTS submissions (
    id TEXT PRIMARY KEY,
    checkin_id TEXT NOT NULL REFERENCES checkins(id) ON DELETE CASCADE,
    receipt_token TEXT NOT NULL UNIQUE,
    student_name TEXT NOT NULL,
    explanation_text TEXT,
    confidence INTEGER NOT NULL,
    voice_file TEXT,
    voice_mime TEXT,
    voice_delete_at TEXT,
    created_at TEXT NOT NULL,
    teacher_tags TEXT NOT NULL DEFAULT '[]',
    teacher_note TEXT NOT NULL DEFAULT '',
    follow_up INTEGER NOT NULL DEFAULT 0
);

CREATE INDEX IF NOT EXISTS submissions_checkin_created
    ON submissions(checkin_id, created_at DESC);
CREATE INDEX IF NOT EXISTS submissions_voice_expiry
    ON submissions(voice_delete_at) WHERE voice_file IS NOT NULL;

