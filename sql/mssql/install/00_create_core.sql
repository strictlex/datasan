-- ЗАГЛУШКА. Заменить реальными установочными скриптами DataSan.

IF OBJECT_ID('dbo.pflb_logs', 'U') IS NULL
BEGIN
    CREATE TABLE dbo.pflb_logs (
        log_id      BIGINT IDENTITY(1,1) PRIMARY KEY,
        log_time    DATETIME2 DEFAULT SYSDATETIME(),
        log_level   VARCHAR(16),
        message     NVARCHAR(4000)
    );
END
GO
