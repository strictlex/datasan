create or replace package pflbp_datasan_prep as
  
   procedure w_log (logstring varchar2);

   procedure log_last_error (p_prefix varchar2 default null);

   procedure dict_job (owner varchar2, table_name varchar2, column_name varchar2, depth_l number);

   procedure regexp_job (owner varchar2, table_name  varchar2, column_name varchar2, depth_l number);   

   procedure profile_job (owner varchar2, table_name varchar2, column_name varchar2, depth_l number);

   procedure profile_worker (p_thread_id IN PLS_INTEGER, p_threads IN PLS_INTEGER, p_depth_l IN NUMBER);

   procedure spawn_profile_workers (p_depth_l in number, p_threads in pls_integer);

   procedure update_profile_summary;

   PROCEDURE log_progress;

   procedure profile_update(depth_l number default 100, threads number default 4, sleep_time number default 0.1, workers number default 0);

end pflbp_datasan_prep;
/
