-- Права необходимые для компиляции PFLB_DATASAN
-- v$session используется в процедуре PFLB_UPD_ERR_HAND
GRANT SELECT ON v_$session TO FULL_SCHEMA_TEST
/
GRANT SELECT ON v_$mystat TO FULL_SCHEMA_TEST
/
GRANT SELECT ON v_$statname TO FULL_SCHEMA_TEST
/
