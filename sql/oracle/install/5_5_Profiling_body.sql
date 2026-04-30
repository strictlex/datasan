-- TODO:
-- * logging groups and levels (info, error, debug...)
-- *
-- *
--
create or replace package body pflbp_datasan_prep as

   ------------------------------------------------------------------------------------------------
   -- LOGGER
   --
   -- Needs table:
   -- CREATE TABLE pflbp_logs(id NUMBER PRIMARY KEY, lstr VARCHAR2(4000 BYTE), ldate TIMESTAMP(6));
   -- and sequence:
   -- CREATE SEQUENCE pflbp_logs_seq START WITH 1 INCREMENT BY 1 NOCACHE NOCYCLE;
   --
   procedure w_log (logstring varchar2) is pragma autonomous_transaction;
   begin
      insert into pflbp_logs (id, lstr, ldate) values (pflbp_logs_seq.nextval, logstring, sysdate);
      commit;
   end w_log;


   ------------------------------------------------------------------------------------------------
   -- error printer
   --
   procedure log_last_error (p_prefix varchar2 default null) is 
      pragma autonomous_transaction;
      l_msg clob;
   begin
      l_msg := nvl(p_prefix, '') || chr(10) || '--- ERROR STACK --------------------------'  || chr(10) || dbms_utility.format_error_stack     || chr(10) || 
                                               '--- ERROR BACKTRACE (line#) ---------------' || chr(10) || dbms_utility.format_error_backtrace || chr(10) || 
                                               '--- CALL STACK ----------------------------' || chr(10) || dbms_utility.format_call_stack;
      pflbp_datasan_prep.w_log(l_msg);
      commit;
   end log_last_error;


   ------------------------------------------------------------------------------------------------ 
   -- Обрабатывает словарные правила из таблицы pflbp_DICT_SEARCH_RULES.
   --
   procedure dict_job (owner varchar2, table_name varchar2, column_name varchar2, depth_l number) as
      l_limit       number := depth_l;
      l_result      number := 0;
      v_sql         varchar2(4000);
      total_count   number := 0;
      percent_count number(12, 4) := 0;
   begin
      --pflbp_datasan_prep.w_log('Start of procedure pflbp_DATASAN_PREP.DICTIONARY');

      for rule_rec in (select rule, description from pflbp_dict_search_rules) loop
         pflbp_datasan_prep.w_log('Processing rule: ' || rule_rec.description);

         v_sql := 'SELECT COUNT(*) FROM ' || owner || '.' || table_name || ' WHERE ROWNUM <= :l_limit';
         pflbp_datasan_prep.w_log('SQL for count total amount of rows:');
         pflbp_datasan_prep.w_log(v_sql);
         execute immediate v_sql
           into total_count
            using l_limit;

         v_sql := 'SELECT COUNT(1) ' || 'FROM ( ' || 'SELECT ' || column_name || ' '  || 
                  'FROM ( ' || 'SELECT ' || column_name || ' ' || 'FROM ' || owner || '.' || table_name || ' ' || 
                  'WHERE ROWNUM <= ' || l_limit || ' ' || ') l ' || 'INNER JOIN ' || rule_rec.rule || ' r ' || 
                  'ON UPPER(l."' || column_name || '") LIKE ''%''||UPPER(r.pflb_value)||''%'' ' || ')';

         pflbp_datasan_prep.w_log(v_sql);

         execute immediate v_sql into l_result;

         if l_result >= 1 then
            percent_count := ( l_result / total_count ) * 100;
            pflbp_datasan_prep.w_log('Check result: ' || l_result);
            pflbp_datasan_prep.w_log('Percentage of successful checks: ' || percent_count || '%');

            merge into profile p
            using (
               select owner as owner, table_name as table_name, column_name as column_name, rule_rec.rule as method, percent_count as percents, rule_rec.description as description
               from dual
            ) src on ( p.owner = src.owner and p.table_name = src.table_name and p.column_name = src.column_name and p.method = src.method and p.description = src.description )
            when matched then update
                set p.percents = src.percents
            when not matched then
                insert(owner, table_name, column_name, method, percents, description)
                values(src.owner, src.table_name, src.column_name, src.method, src.percents, src.description);
         --else
            --pflbp_datasan_prep.w_log('No rows passed the check.');
         end if;

      end loop;

      --pflbp_datasan_prep.w_log('Procedure DICTIONARY complete.');
   exception
      when others then
        pflbp_datasan_prep.log_last_error('Error in [dict_job], table [' || owner || '.' || table_name || '], column [' || column_name || ']; ');
   end;


   ------------------------------------------------------------------------------------------------ 
   --
   --   
   procedure regexp_job (owner varchar2, table_name  varchar2, column_name varchar2, depth_l number) as
      l_limit       number := depth_l;
      l_result      varchar2(200);
      l_res_val     number;
      v_sql         varchar2(4000);
      total_count   number := 0;
      percent_count number(12, 4) := 0;
   begin
      --pflbp_datasan_prep.w_log('Start of procedure pflbp_DATASAN_PREP.REGEXP_JOB');

      for rule_rec in (select rule, description, validatemethod from pflbp_regexp_search_rules) loop      
         pflbp_datasan_prep.w_log('Processing rule: ' || rule_rec.description);
         pflbp_datasan_prep.w_log('Processing rule: ' || rule_rec.rule);

         v_sql := 'SELECT COUNT(*) FROM ' || owner || '.' || table_name || ' WHERE ROWNUM <= :l_limit';
         pflbp_datasan_prep.w_log('SQL for count total amount of rows:');
         pflbp_datasan_prep.w_log(v_sql);

         execute immediate v_sql into total_count using l_limit;

         if rule_rec.validatemethod is null then
            v_sql := 'SELECT COUNT(*) FROM (SELECT 1 FROM ' || '(SELECT * FROM ' || owner || '.'  || table_name || 
                    ' WHERE ROWNUM <= ' || l_limit || ') ' || 'WHERE REGEXP_LIKE("' || column_name || '", :rule)) ';
         else
            v_sql := 'SELECT sum(to_number(nvl(val,0))) FROM (SELECT to_number(' || rule_rec.validatemethod || 
                     '(regexp_substr("' || column_name || '", :rule))) val FROM ( SELECT * FROM ' || owner || 
                     '.' || table_name || ' WHERE ROWNUM <= ' || l_limit || ')) ';
         end if;

         pflbp_datasan_prep.w_log('SQL for check :');
         pflbp_datasan_prep.w_log(v_sql);
         pflbp_datasan_prep.w_log(l_limit);
         pflbp_datasan_prep.w_log(rule_rec.rule);

         execute immediate v_sql into l_result using rule_rec.rule;
         l_res_val := to_number(nvl(l_result, 0));
         
         if l_res_val >= 1 then
            percent_count := ( l_res_val / total_count ) * 100;
            pflbp_datasan_prep.w_log('Check result ' || rule_rec.description || ': ' || l_res_val);
            pflbp_datasan_prep.w_log('Percentage of successful checks: ' || percent_count || '%');

            merge into profile p
            using (
               select owner as owner, table_name as table_name, column_name as column_name, rule_rec.rule as method, percent_count as percents, rule_rec.description as description
               from dual
            ) src on (p.owner = src.owner and p.table_name = src.table_name and p.column_name = src.column_name and p.method = src.method and p.description = src.description )
            when matched then update
                set p.percents = src.percents
            when not matched then
                insert(owner, table_name, column_name, method, percents, description)
                values(src.owner, src.table_name, src.column_name, src.method, src.percents, src.description);
         --else
            -- pflbp_datasan_prep.w_log('No rows passed the check. ' || rule_rec.description);
         end if;

      end loop;

      -- pflbp_datasan_prep.w_log('Procedure REGEXP_SNILS complete.');

   exception
      when others then
        pflbp_datasan_prep.log_last_error('Error in [regexp_job], table [' || owner || '.' || table_name || '], column [' || column_name || ']; ');
   end;

   

   ------------------------------------------------------------------------------------------------   
   --
   --   
   procedure profile_job(owner varchar2, table_name varchar2, column_name varchar2, depth_l number) as
      ssid number;
      l_start TIMESTAMP := SYSTIMESTAMP;
   begin
      begin
         select sys_context('userenv', 'SID') into ssid from dual;
         update pflbp_active_jobs set sid = ssid where upstring = owner || '.' || table_name || '.' || column_name;
         commit;
         begin
            pflbp_datasan_prep.dict_job(owner, table_name, column_name, depth_l);
            commit;
            pflbp_datasan_prep.regexp_job(owner, table_name, column_name, depth_l);
            commit;
         exception
            when others then
               -- pflbp_datasan_prep.w_log('Error in table ' || owner || '.' || table_name || ', column ' || column_name || ': ' || sqlerrm);
               pflbp_datasan_prep.log_last_error('Error in [profile_job(170)], table [' || owner || '.' || table_name || '], column [' || column_name || ']; ');
               rollback;
               delete from pflbp_active_jobs where upstring = owner || '.' || table_name || '.' || column_name;
               insert into pflbp_nprofiled_columns values (owner, table_name, column_name);
               commit;
         end;
         delete from pflbp_active_jobs where upstring = owner || '.' || table_name || '.' || column_name;
         commit;

      pflbp_datasan_prep.w_log('Profile Job done in ' || (SYSTIMESTAMP - l_start) || ' for ' || owner||'.'||table_name||'.'||column_name);
   
      exception
         when others then
            pflbp_datasan_prep.log_last_error('Error in [profile_job(180)], table [' || owner || '.' || table_name || '], column [' || column_name || ']; ');
            delete from pflbp_active_jobs where upstring = owner || '.' || table_name || '.' || column_name;
            insert into pflbp_nprofiled_columns values (owner, table_name, column_name);
            commit;
      end;
   end;






   ------------------------------------------------------------------------------------------------   
   --
   --       
   PROCEDURE profile_worker (
     p_thread_id IN PLS_INTEGER,
     p_threads   IN PLS_INTEGER,
     p_depth_l   IN NUMBER
   ) AS
     l_count NUMBER;
   BEGIN
     pflbp_datasan_prep.w_log( 'Started worker #' || p_thread_id || ' of ' || p_threads );

     UPDATE pflbp_worker_tracking SET status = 'RUNNING' WHERE worker_id = p_thread_id;
     COMMIT;

      FOR rec IN (SELECT owner, table_name, column_name, idx FROM profile_view_by_rows_asc) LOOP
         -- check for signal to stop
         select count(1) into l_count from pflbp_active_status;
         IF l_count > 0 THEN EXIT; END IF;

         IF MOD(rec.idx-1, p_threads)+1 != p_thread_id THEN
            CONTINUE; 
         END IF;
         
         -- check if the table is already done
         SELECT COUNT(*) INTO l_count FROM last_profiled_table WHERE owner = rec.owner AND table_name  = rec.table_name AND column_name = rec.column_name;
         IF l_count > 0 THEN
            pflbp_datasan_prep.w_log('Skipped column: ' || rec.owner || '.' || rec.table_name || ', column: ' || rec.column_name || ' by worker #' || p_thread_id);
            CONTINUE;
         END IF;

         insert into last_profiled_table (owner, table_name, column_name) values (rec.owner, rec.table_name, rec.column_name);
         pflbp_datasan_prep.w_log('worker #' || p_thread_id || ' checks table: ' || rec.owner || '.' || rec.table_name || ', column: ' || rec.column_name);
         pflbp_datasan_prep.profile_job(rec.owner, rec.table_name, rec.column_name, p_depth_l);
      END LOOP;

   pflbp_datasan_prep.w_log('worker #' || p_thread_id || ' finished processing tables.');
   UPDATE pflbp_worker_tracking SET end_time = SYSTIMESTAMP, status = 'COMPLETED' WHERE worker_id = p_thread_id;
   COMMIT;

   EXCEPTION
      WHEN OTHERS THEN
         pflbp_datasan_prep.log_last_error('Error in [profile_worker#' || p_thread_id || ' of ' || p_threads || ']; ');
         pflbp_datasan_prep.w_log('worker #' || p_thread_id || ' exiting');
         UPDATE pflbp_worker_tracking SET end_time = SYSTIMESTAMP, status = 'FAILED' WHERE worker_id = p_thread_id;
         COMMIT;
   END profile_worker;



   ------------------------------------------------------------------------------------------------   
   --
   --    
   procedure spawn_profile_workers (p_depth_l in number, p_threads in pls_integer) as
      l_job number;
   begin

      for i in 1..p_threads loop
         INSERT INTO pflbp_worker_tracking(worker_id, start_time, status) VALUES(i, SYSTIMESTAMP, 'PENDING');         
         COMMIT;
         dbms_job.submit(
            job       => l_job,
            what      => 'BEGIN pflbp_datasan_prep.profile_worker(' || i || ',' || p_threads || ',' || p_depth_l || '); END;',
            next_date => sysdate,
            interval  => null
         );
         SYS.DBMS_LOCK.SLEEP(1);
      end loop;
      commit;

   exception
      when others then
        pflbp_datasan_prep.log_last_error('Error in [spawn_profile_workers]; ');

   end spawn_profile_workers;



   ------------------------------------------------------------------------------------------------   
   --
   --   
   procedure update_profile_summary as
   begin
      merge into profile_summary ps
      using (
         select 
            owner, 
            table_name, 
            column_name, 
            case when mc = 1 then 'N' else 'Y' end as comb_method,
            case when mc = 1 then description else null end as method_desc
         from (select owner, table_name, column_name, description, count(1) over(partition by owner, table_name, column_name, description) as mc from profile)
         group by owner, table_name, column_name, description, mc
      ) src on (ps.owner = src.owner and ps.table_name = src.table_name and ps.column_name = src.column_name )
      when matched then update
        set ps.comb_method = src.comb_method, ps.method_desc = src.method_desc
      when not matched then
        insert(owner, table_name, column_name, comb_method, method_desc)
        values(src.owner, src.table_name, src.column_name, src.comb_method, src.method_desc);

      pflbp_datasan_prep.w_log('Data was successfully updated or inserted into PROFILE_SUMMARY.');
   exception
      when others then
        pflbp_datasan_prep.log_last_error('Error in [update_profile_summary]; ');
   end;



   ------------------------------------------------------------------------------------------------   
   --
   --   
   PROCEDURE log_progress as 
      v_total_cnt      NUMBER;
      v_done_cnt       NUMBER;
      v_pct            NUMBER(5,2);
      v_start          TIMESTAMP := SYSTIMESTAMP;
      v_active_jobs    NUMBER;
      v_profile_cnt    NUMBER;
      v_rate_secs_per  NUMBER;
      v_elapsed_secs   NUMBER;
      v_remaining_secs NUMBER;
      v_worker_cnt     NUMBER;
      v_eta            INTERVAL DAY(3) TO SECOND;
      v_elapsed       INTERVAL DAY(3) TO SECOND;
   BEGIN
   
      SELECT COUNT(*) INTO v_total_cnt FROM profile_table_with_nums;

      LOOP
         SELECT COUNT(*) INTO v_done_cnt FROM last_profiled_table;

         IF v_total_cnt > 0 THEN v_pct := ROUND(100 * v_done_cnt / v_total_cnt, 2); ELSE v_pct := 0; END IF;

         v_elapsed_secs := (CAST(SYSTIMESTAMP AS DATE) - CAST(v_start     AS DATE)) * 24 * 60 * 60;

         -- estimate ETA
         IF v_done_cnt > 0 THEN
            v_rate_secs_per  := v_elapsed_secs / v_done_cnt;
            v_remaining_secs := (v_total_cnt - v_done_cnt) * v_rate_secs_per;
            v_eta            := NUMTODSINTERVAL(v_remaining_secs, 'SECOND');
         ELSE
            v_eta := NULL;
         END IF;

         -- how many active jobs remain
         SELECT COUNT(*) INTO v_active_jobs FROM pflbp_active_jobs;

         -- how many rows added to PROFILE
         SELECT COUNT(*) INTO v_profile_cnt FROM profile;

         -- total elapsed as INTERVAL
         v_elapsed := NUMTODSINTERVAL(v_elapsed_secs, 'SECOND');

          -- count total workers ever started
         SELECT COUNT(*) INTO v_worker_cnt FROM pflbp_worker_tracking WHERE status = 'RUNNING';

         -- write snapshot
         INSERT INTO progress_log(log_time, done_cnt, total_cnt, pct, eta, active_jobs, elapsed_time, profile_cnt, workers_count) 
         VALUES (SYSTIMESTAMP, v_done_cnt, v_total_cnt, v_pct, v_eta, v_active_jobs, v_elapsed, v_profile_cnt, v_worker_cnt);
         COMMIT;

         DBMS_LOCK.SLEEP(60);
      END LOOP;

   END log_progress;




   ------------------------------------------------------------------------------------------------   
   --
   --   
   procedure profile_update (
      depth_l     number default 100, 
      threads     number default 4, 
      sleep_time  number default 0.1,
      workers     number default 0
    ) as
      l_job       number := null;
      l_job_log   number := null;
      fend        number := 1;
      jsql        varchar2(4000);
      l_count   NUMBER;
   begin

      pflbp_datasan_prep.w_log('PROFILE_UPDATE STARTED');

      DELETE FROM pflbp_worker_tracking;
      COMMIT;

      pflbp_datasan_prep.spawn_profile_workers(p_depth_l => depth_l, p_threads => workers);


      --pflbp_datasan_prep.log_progress;
      DBMS_JOB.SUBMIT(
         job       => l_job_log,
         what      => 'BEGIN pflbp_datasan_prep.log_progress; END;',
         next_date => SYSDATE,
         interval  => NULL
      );
      COMMIT;

      for tab_rec in (select owner, table_name, column_name from profile_view_sorted_by_rows_count) loop
         -- pflbp_datasan_prep.w_log('Check table: ' || tab_rec.owner || '.' || tab_rec.table_name || ', column: ' || tab_rec.column_name);

         SELECT COUNT(*) INTO l_count
            FROM last_profiled_table
         WHERE owner       = tab_rec.owner
            AND table_name  = tab_rec.table_name
            AND column_name = tab_rec.column_name;

         IF l_count > 0 THEN
            pflbp_datasan_prep.w_log('Skipped column: ' || tab_rec.owner || '.' || tab_rec.table_name || ', column: ' || tab_rec.column_name || ' by main process');
            CONTINUE;  -- next tab_rec
         END IF;

         fend := 1;
         while fend > 0 loop
            select count(1) into fend from pflbp_active_status;
            if fend < 1 then
               select count(1) into fend from pflbp_active_jobs;
               if fend < threads then
                  fend := 0;
               end if;
            else
               RETURN; -- ! insert anything into pflbp_active_status to stop process
            end if;
            IF fend > 0 THEN
               SYS.DBMS_LOCK.SLEEP(sleep_time);
            END IF;
         end loop;
         
         insert into last_profiled_table (owner, table_name, column_name) values (tab_rec.owner, tab_rec.table_name, tab_rec.column_name);

         begin
            insert into pflbp_active_jobs ( upstring ) values (tab_rec.owner  || '.'  || tab_rec.table_name  || '.'  || tab_rec.column_name);
            commit;
            jsql := 'pflbp_DATASAN_PREP.PROFILE_JOB(''' || tab_rec.owner || ''', ''' || tab_rec.table_name || ''', ''' || tab_rec.column_name || ''',' || depth_l || ');';
            sys.dbms_job.submit(l_job, jsql, sysdate, null);
            commit;

         exception
            when others then
               pflbp_datasan_prep.log_last_error('Error in [profile_update(252)]; ');
               delete from pflbp_active_jobs where upstring = tab_rec.owner || '.' || tab_rec.table_name || '.' || tab_rec.column_name;
               commit;
         end;

      end loop;

      fend := 1;
      while fend > 0 loop
         select count(1) into fend from pflbp_active_status;
         if fend < 1 then
            select count(1) into fend from pflbp_active_jobs;
         else
            fend := 0;
         end if;
         sys.dbms_lock.sleep(1);
      end loop;

      begin
         pflbp_datasan_prep.update_profile_summary;
         commit;
      exception
         when others then
            pflbp_datasan_prep.log_last_error('Error in [profile_update(275)]; ');
            rollback;
      end;

      BEGIN
         DBMS_JOB.REMOVE(l_job_log);
         COMMIT;
      EXCEPTION WHEN OTHERS THEN NULL;
      END;

      pflbp_datasan_prep.w_log('DONE! All checks complete.');
   exception
      when others then
         pflbp_datasan_prep.log_last_error('Error in [profile_update(282)]; ');
         rollback;
   end;
end;
/
