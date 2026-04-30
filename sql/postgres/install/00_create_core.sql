-- ЗАГЛУШКА. Заменить реальными установочными скриптами DataSan.

CREATE TABLE IF NOT EXISTS pflb_logs (
    log_id      BIGSERIAL PRIMARY KEY,
    log_time    TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    log_level   VARCHAR(16),
    message     TEXT
);
