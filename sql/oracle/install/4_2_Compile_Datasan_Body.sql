create or replace PACKAGE BODY PFLB_DATASAN as
function PFLB_GET_UNIQ_COL(towner_name varchar2, ttable_name varchar2, idtype in out varchar2)
return varchar2
as
tcolumn_name varchar2(255);
begin
    tcolumn_name:=NULL;
    pflb_datasan.PFLB_WRITE_LOGS('!@#$ Trying to find unique column');
begin
select distinct ind.column_name into tcolumn_name from all_ind_columns ind where ind.table_name=ttable_name and ind.table_owner=towner_name
                                                                             and exists(select 1 from all_indexes indexs
                                                                                                          join all_ind_columns nd on indexs.index_name=nd.index_name
                                                                                                          join all_tab_columns co on co.column_name=nd.column_name and co.owner=nd.table_owner and co.table_name=nd.table_name
                                                                                        where
                                                                                            (co.data_type='NUMBER' or co.data_type='VARCHAR2' or co.data_type='INTEGER') and
                                                                                            indexs.uniqueness='UNIQUE' and
                                                                                            ind.column_name=co.column_name and
                                                                                            co.owner=ind.table_owner and
                                                                                            co.table_name=ind.table_name
                                                                                          and (nd.column_position is null or nd.column_position = 1))
                                                                             and rownum=1;
select data_type into idtype from all_tab_columns where column_name=tcolumn_name and owner=towner_name and table_name=ttable_name;
exception
    when others then
    tcolumn_name:=NULL;
    pflb_datasan.PFLB_WRITE_LOGS('!@#$ Unique column is not found');
end;
return tcolumn_name;
end;
function PFLB_GET_KEY_COLUMN(towner_name varchar2, ttable_name varchar2, idtype in out varchar2)
return varchar2
as
tcolumn_name varchar2(255);
begin
    tcolumn_name:=NULL;
    pflb_datasan.PFLB_WRITE_LOGS('!@#$ Trying to find PK column');
begin
select distinct ind.column_name into tcolumn_name from all_ind_columns ind where ind.table_name=ttable_name and ind.table_owner=towner_name
                                                                             and exists(select 1 from all_constraints cons
                                                                                                          join all_cons_columns col on cons.constraint_name=col.constraint_name
                                                                                                          join all_indexes indexs on indexs.index_name=cons.index_name
                                                                                                          join all_tab_columns co on co.column_name=col.column_name and co.owner=cons.owner and co.table_name=cons.table_name
                                                                                        where
                                                                                            (co.data_type='NUMBER' or co.data_type='VARCHAR2' or co.data_type='INTEGER') and
                                                                                            indexs.uniqueness='UNIQUE' and
                                                                                            ind.column_name=col.column_name and
                                                                                            cons.owner=ind.table_owner and
                                                                                            cons.table_name=ind.table_name
                                                                                          and cons.constraint_type='P'
                                                                                          and (col.position is null or col.position = 1))
                                                                             and rownum=1;
select data_type into idtype from all_tab_columns where column_name=tcolumn_name and owner=towner_name and table_name=ttable_name;
exception
    when others then
    tcolumn_name:=NULL;
    tcolumn_name:=pflb_datasan.PFLB_GET_UNIQ_COL(towner_name, ttable_name, idtype);
    pflb_datasan.PFLB_WRITE_LOGS('!@#$ PK column is not found');
end;
return tcolumn_name;
end;
function PFLB_GET_IDENTITY_COLUMN(towner_name varchar2, ttable_name varchar2)
return varchar2
as
tcolumn_name varchar2(255);
tsql varchar2(4000);
bdver integer:=pflb_datasan.PFLB_GET_BD_VER;
begin
pflb_datasan.PFLB_WRITE_LOGS('!@#$ Trying to find identity column');
begin
    if bdver>11 then
	tsql:='SELECT col.column_name
	FROM all_tab_columns col
	WHERE
		 col.table_name = '''||ttable_name||'''
         and col.owner = '''||towner_name||'''
		 AND col.column_name <> '' ''
		 AND col.identity_column = ''YES''';
EXECUTE IMMEDIATE tsql into tcolumn_name;
end if;
exception
    when others then
    tcolumn_name:=NULL;
    pflb_datasan.PFLB_WRITE_LOGS('!@#$ Identity column is not found');
end;

return tcolumn_name;
end;
function PFLB_GET_TABLE_NAME(tquery varchar2)
return varchar2
as
space_pos simple_integer:=0;
st_len simple_integer:=0;
update_pref varchar2(20):= 'update';
delete_pref varchar2(20):= 'delete from';
begin
	if instr(tquery, update_pref) > 0 then
		st_len := length(update_pref) + 2;
end if;

	if instr(tquery, delete_pref) > 0 then
		st_len := length(delete_pref) + 2;
end if;
space_pos := instr(tquery, ' ', st_len);
	if space_pos = 0 then
		space_pos := length(tquery) + 1;
end if;
return substr(tquery, st_len, space_pos - st_len);
end;
PROCEDURE PFLB_GET_INDEXES(towner_name varchar2, ttable_name varchar2, tcolumn_name varchar2)
as
begin
insert into pflb_temp_table_indexes
select table_owner, table_name, index_name, null, null, 0, ind.index_owner from all_ind_columns ind where ind.table_name=ttable_name and ind.column_name=tcolumn_name and ind.table_owner=towner_name
                                                                                                      and not exists(select 1 from all_constraints cons
                                                                                                                                       join all_cons_columns col on cons.table_name=col.table_name
                                                                                                                     where ind.table_name=cons.table_name and ind.column_name=col.column_name and ind.table_owner=col.owner
                                                                                                                       and cons.constraint_type='P');
commit;
end;
FUNCTION PFLB_GET_MAX_PROC_ID_c (
	tquery varchar2
) RETURN VARCHAR2 AS
 max_ids VARCHAR2(255);
BEGIN
    max_ids:=NULL;
  --  DBMS_OUTPUT.put_line(nvl(max_ids, 0));
begin
select max_id into max_ids from PFLB_PROCESSED_QUERIES_C
where md5 = cast(standard_hash(tquery, 'MD5') as varchar2(32));
exception
    when others then
	--	DBMS_OUTPUT.put_line('Error ' || SQLCODE || ': ' || SQLERRM);
        return max_ids;
end;
 --   DBMS_OUTPUT.put_line(nvl(max_ids, 0));
return max_ids;
END;
FUNCTION PFLB_GET_MAX_PROCESSED_ID (
	tquery varchar2
) RETURN NUMBER AS
 max_ids number;
BEGIN
    max_ids:=NULL;
  --  DBMS_OUTPUT.put_line(nvl(max_ids, 0));
begin
select max_id into max_ids from PFLB_PROCESSED_QUERIES
where md5 = cast(standard_hash(tquery, 'MD5') as varchar2(32));
exception
    when others then
	--	DBMS_OUTPUT.put_line('Error ' || SQLCODE || ': ' || SQLERRM);
        return max_ids;
end;
 --   DBMS_OUTPUT.put_line(nvl(max_ids, 0));
return max_ids;
END;
PROCEDURE PFLB_UPD_PROC_INFO (
	tquery varchar2,
	max_ids in out NUMBER
) as
tempt number;
insql varchar2(32000);
BEGIN
	insql := substr(tquery, 1, 3999);
select count(1) into tempt from PFLB_PROCESSED_QUERIES
where md5 = cast(standard_hash(insql, 'MD5') as varchar2(32));
if tempt<>0 then
update pflb_processed_queries set max_id = max_ids
where md5 = cast(standard_hash(insql, 'MD5') as varchar2(32));
else
		insert into pflb_processed_queries
		values (insql, cast(standard_hash(insql, 'MD5') as varchar2(32)), max_ids);
end if;
END;
PROCEDURE PFLB_UPD_PROC_INFO_C (
	tquery varchar2,
	max_ids in out varchar2
) as
tempt number;
insql varchar2(32000);
BEGIN
	insql := substr(tquery, 1, 3999);
select count(1) into tempt from PFLB_PROCESSED_QUERIES_C
where md5 = cast(standard_hash(insql, 'MD5') as varchar2(32));
if tempt<>0 then
update PFLB_PROCESSED_QUERIES_C set max_id = max_ids
where md5 = cast(standard_hash(insql, 'MD5') as varchar2(32));
else
		insert into PFLB_PROCESSED_QUERIES_C
		values (insql, cast(standard_hash(insql, 'MD5') as varchar2(32)), max_ids);
end if;
END;
PROCEDURE PFLB_GET_OR_CR_KEY_COL
(
    towner_name varchar2,
	ttable_name varchar2,
	tkey_column in out varchar2,
    sim integer,
    idctyp in out varchar2
)
AS
    tsql  varchar2(1000);
    rflag number:=0;
    tmax_id number;
    tmin_id number;
    tcount number;
    tidxname varchar2(255);
	identity_column varchar2(255);
	tddl varchar2(1000);
    idtype varchar2(255);
BEGIN

	tkey_column := pflb_get_key_column(towner_name,ttable_name,idtype);
	if tkey_column is null then
		identity_column := pflb_datasan.pflb_get_identity_column(towner_name,ttable_name);
		if identity_column is null then
			tkey_column := 'PFLB_DEPERS_ID';
            pflb_datasan.PFLB_WRITE_LOGS('Unique integer column is not found or it have too much space, creating it');
            if sim = 0 then
			tddl := 'alter table ' || towner_name||'.'|| ttable_name  || ' add ' || tkey_column || ' integer';
            pflb_datasan.PFLB_WRITE_LOGS(tddl);
begin
EXECUTE IMMEDIATE tddl;
exception
            when others then
				if SQLCODE = -1430 then
            pflb_datasan.PFLB_WRITE_LOGS('Column already exists, skipping');
else
					raise;
end if;
end;
            tddl := 'UPDATE '|| towner_name||'.'|| ttable_name  ||
   ' SET '|| tkey_column ||' = PFLB_tmp_SEQ.nextval';
EXECUTE IMMEDIATE tddl;
commit;
if length(ttable_name)>19 then
            tidxname:=substr(ttable_name,length(ttable_name)-19+1);
else
            tidxname:=ttable_name;
end if;
			tddl := 'create unique index IDX_U_PFLB_' || tidxname || ' on ' ||towner_name||'.'|| ttable_name || ' (' || tkey_column || ' asc)';
			--DBMS_OUTPUT.put_line(tddl);
begin
EXECUTE IMMEDIATE tddl;
exception
            when others then
				if SQLCODE = -955 then
                pflb_datasan.PFLB_WRITE_LOGS('Index already exists, skipping');
else
					raise;
end if;
end;
end if;
else
        pflb_datasan.PFLB_WRITE_LOGS('Key column is not found, but identity column exists');
        if sim = 0 then
        if length(ttable_name)>19 then
            tidxname:=substr(ttable_name,length(ttable_name)-19+1);
else
            tidxname:=ttable_name;
end if;
			tddl := 'create unique index IDX_U_PFLB_' || tidxname || ' on ' ||towner_name||'.'|| ttable_name || ' (' || identity_column || ' asc)';
			--DBMS_OUTPUT.put_line(tddl);
begin
EXECUTE IMMEDIATE tddl;
exception
            when others then
				if SQLCODE = -955 then
					pflb_datasan.PFLB_WRITE_LOGS('Index already exists, skipping');
else
					raise;
end if;
end;
			tkey_column := identity_column;
end if;
end if;
end if;
            if idtype is null then
            idtype:='INTEGER';
end if;
            idctyp:=idtype;
END;
PROCEDURE PFLB_DROP_COL_IDX(
    towner_name varchar2,
	ttable_name varchar2)
AS
	tddl varchar2(1000);
    tidxname varchar2(255);
	tcolumn_name varchar2(255);
BEGIN
pflb_datasan.PFLB_WRITE_LOGS('Checking temp_id_column on '||towner_name||'.'||ttable_name||', start dropping it');
select case when exists
    (
        select column_name
        from all_tab_columns ind where ind.table_name=ttable_name and ind.owner=towner_name
                                   and (ind.column_name='PFLB_ID' or ind.column_name='PFLB_DEPERS_ID')
    )
                then 1
            else 0
           end
into tcolumn_name
from dual;


if tcolumn_name = 1 then
    pflb_datasan.PFLB_WRITE_LOGS('temp_id_column exist, start dropping it');
begin
select case when exists
    (
        select column_name
        from all_ind_columns ind where ind.table_name=ttable_name and ind.table_owner=towner_name
                                   and (ind.column_name='PFLB_ID' or ind.column_name='PFLB_DEPERS_ID')
    )
                then 1
            else 0
           end
into tcolumn_name
from dual;
if length(ttable_name)>19 then
            tidxname:=substr(ttable_name,length(ttable_name)-19+1);
else
            tidxname:=ttable_name;
end if;
			tddl := 'drop index IDX_U_PFLB_' || tidxname;
            if tcolumn_name = 1 then
            pflb_datasan.PFLB_WRITE_LOGS('Trying to drop Index');
			--DBMS_OUTPUT.put_line(tddl);
EXECUTE IMMEDIATE tddl;
pflb_datasan.PFLB_WRITE_LOGS('Index dropped');
else
            pflb_datasan.PFLB_WRITE_LOGS('Index not exist');
end if;
exception
        when others then
        pflb_datasan.PFLB_WRITE_LOGS('Error ' || SQLCODE || ': ' || SQLERRM);
			if SQLCODE = -1418 then
				raise;
end if;
end;
select column_name into tcolumn_name
from all_tab_columns ind where ind.table_name=ttable_name and ind.owner=towner_name
                           and (ind.column_name='PFLB_ID' or ind.column_name='PFLB_DEPERS_ID');
tddl := 'alter table ' || towner_name ||'.'|| ttable_name || ' drop column ' || tcolumn_name;
pflb_datasan.PFLB_WRITE_LOGS('Trying to drop Column_id');
		--DBMS_OUTPUT.put_line(tddl);
begin
EXECUTE IMMEDIATE tddl;
pflb_datasan.PFLB_WRITE_LOGS('Column dropped');
exception
        when others then
        pflb_datasan.PFLB_WRITE_LOGS('Error ' || SQLCODE || ': ' || SQLERRM);
			if SQLCODE = -1418 then
				raise;
end if;
end;
end if;
END;
function PFLB_COMBINE_SQL(tmain_part varchar2, twhere_clause varchar2)
return varchar2
as
	tindex simple_integer := instr(tmain_part, ' where ');
    told_where varchar2(32767);
begin
if twhere_clause is not null and twhere_clause!='0' then
	if tindex > 0 then
		told_where := substr(tmain_part, tindex + 7, length(tmain_part));
      --  DBMS_OUTPUT.put_line(lpad(tmain_part, tindex) || 'where (' || told_where || ') and (' || twhere_clause || ')');
return lpad(tmain_part, tindex) || 'where (' || told_where || ') and (' || twhere_clause || ')';
else
   -- DBMS_OUTPUT.put_line(tmain_part || ' where ' || twhere_clause);
		return tmain_part || ' where ' || twhere_clause;
end if;
else
    return tmain_part;
end if;
  --  DBMS_OUTPUT.put_line('!');
return '!';
end;
PROCEDURE PFLB_GENERATE_UPDATE (
	insql in out varchar2,
    distOwnerName varchar2,
	distTableName  varchar2,
	encodeFunctionName varchar2,
	encodeMethod varchar2
    )
AS
curRow int;
tSql varchar2(32767);
ttab char(1) := chr(9);
esql varchar2(511);
multiarflag integer;
dictflag integer;
npositioncount integer;
i integer;
tvalue varchar2(2000);
viewCont_ownerName varchar2(255);
viewCont_tableName varchar2(255);
viewCont_columnName varchar2(255);
viewCont_encodetype varchar2(255);
viewCont_columnencodetype varchar2(255);
viewCont_columnmlen integer;
dict_method varchar2(255);
dict_count integer;
dict_cur_it integer;
dict_id integer;
cursor curs_viewContent is
select owner_name, table_name, column_name, encode_method, column_encode_type,column_max_len
from pflb_viewContent
where table_name = distTableName and distOwnerName=owner_name
;
cursor curs_dict_val is
select id_dict
from pflb_dict_types
where encode_method=viewCont_encodetype and column_encode_type=viewCont_columnencodetype
;
begin
open curs_viewContent;
fetch curs_viewContent
    into viewCont_ownerName, viewCont_tableName, viewCont_columnName, viewCont_encodetype, viewCont_columnencodetype,viewCont_columnmlen;
insql := 'update ' || viewCont_ownerName||'.'||distTableName;



	curRow := 0;
	loop
pflb_datasan.pflb_get_indexes(viewCont_ownerName, viewCont_tableName, viewCont_columnName);
select count(1) into multiarflag from pflb_multiargs_functions where encode_method=viewCont_encodetype and column_encode_type=viewCont_columnencodetype;
select count(1) into dictflag from pflb_dict_args where encode_method=viewCont_encodetype and column_encode_type=viewCont_columnencodetype;
if upper(viewCont_columnencodetype)='DELETEN' then
            esql:='null';
        elsif multiarflag>0 then
select count(1) into npositioncount from pflb_multiargs_functions join
                                         pflb_fun_args_value on id=fun_id where encode_method=viewCont_encodetype and column_encode_type=viewCont_columnencodetype;
i:=1;
            esql:=encodeFunctionName || '_' || viewCont_encodetype || '_' || viewCont_columnencodetype || '(';
            if viewCont_columnmlen is not null then
                esql:=esql||', '||to_char(viewCont_columnmlen);
end if;
            while i<npositioncount+1
            loop
select value into tvalue from pflb_multiargs_functions join
                              pflb_fun_args_value on id=fun_id where encode_method=viewCont_encodetype and column_encode_type=viewCont_columnencodetype and position=i;
if upper(tvalue)='!$COLUMN_NAME!$' then
                    tvalue:=viewCont_columnName;
end if;
                esql:=esql||tvalue;
                if i!=npositioncount then
                    esql:=esql||', ';
end if;
                i:=i+1;
end loop;
            esql:=esql||')';
            --dict processing
        elsif dictflag>0 then
select count(1) into npositioncount from pflb_dict_args where encode_method=viewCont_encodetype and column_encode_type=viewCont_columnencodetype;
i:=1;
select distinct function_name into dict_method from pflb_dict_args where encode_method=viewCont_encodetype and column_encode_type=viewCont_columnencodetype;
esql:=dict_method || '(';
            while i<npositioncount+1
            loop
select arg_value into tvalue from pflb_dict_args where encode_method=viewCont_encodetype and column_encode_type=viewCont_columnencodetype and arg_pos=i;
--col if
if upper(tvalue)='!$COLUMN_NAME!$' then
                    tvalue:=viewCont_columnName;
                    --col if
                    --len if
                elsif upper(tvalue)='!$LEN!$' then
                        if nvl(viewCont_columnmlen,0) <=0 then
                            tvalue:='''MaxLenghthSTR=false''';
else
                            tvalue:='''MaxLenghthSTR='||nvl(viewCont_columnmlen,0)||'''';
end if;
                    --len if
                    --dict if
                elsif upper(tvalue)='!$DICT!$' then
                    dict_cur_it:=0;
select count(1) into dict_count from pflb_dict_types where encode_method=viewCont_encodetype and column_encode_type=viewCont_columnencodetype;
tvalue:='';
open curs_dict_val;
fetch curs_dict_val
    into dict_id;
loop
tvalue:=tvalue||dict_id;
fetch curs_dict_val
    into dict_id;
exit when curs_dict_val%NOTFOUND;
                        tvalue:=tvalue||',';
end loop;
close curs_dict_val;
tvalue:=''''||tvalue||'''';
                    --dict if
end if;
                esql:=esql||tvalue;
                if i!=npositioncount then
                    esql:=esql||', ';
end if;
                i:=i+1;
end loop;
            esql:=esql||')';
            --dict processing end
else
            esql:=encodeFunctionName || '_' || viewCont_encodetype || '_' || viewCont_columnencodetype || '(' || viewCont_columnName;
        if viewCont_columnmlen is not null then
            esql:=esql||', '||to_char(viewCont_columnmlen);
end if;
	esql:=esql||')';
end if;
		if curRow = 0 then
			insql := insql || ' set ' || viewCont_columnName || ' = ' || esql;
else
			insql := insql || ', ' || viewCont_columnName || ' = ' || esql;
end if;
		curRow := curRow + 1;
fetch curs_viewContent
    into viewCont_ownerName, viewCont_tableName, viewCont_columnName, viewCont_encodetype, viewCont_columnencodetype,viewCont_columnmlen;
exit when curs_viewContent%NOTFOUND;
end loop;--end loop for columns
close curs_viewContent;
pflb_datasan.PFLB_WRITE_LOGS('Update string is created');
    pflb_datasan.PFLB_WRITE_LOGS('#index table is filled');
end;
PROCEDURE PFLB_ENABLE_INDEXES

AS
tSql varchar2(32767);
index_ownerName varchar2(255);
index_tableName varchar2(255);
index_indexName varchar2(255);
cursor cur_indexes is
select distinct owner_name, table_name, index_name
from PFLB_TEMP_TABLE_INDEXES
;
begin
open cur_indexes;
fetch cur_indexes
    into index_ownerName, index_tableName, index_indexName
;
if index_indexName is not null then
    loop
        tSql := 'alter index ' ||index_ownerName||'.'|| index_indexName || ' rebuild ONLINE';
        PFLB_DATASAN.PFLB_WRITE_LOGS(tSql);
    --    DBMS_OUTPUT.put_line(tSql);
EXECUTE IMMEDIATE tSql;

fetch cur_indexes
    into index_ownerName, index_tableName, index_indexName
;
exit when cur_indexes%NOTFOUND;
end loop;
end if;
close cur_indexes;
end;
PROCEDURE PFLB_DISABLE_INDEXES_API
AS
jerror number;
dis number;
begin
    jerror := 0;
    dis := 1;
  loop
select count(1) into jerror from pflb_active_status;
exit when jerror > 0;
select count(1) into dis from pflb_temp_table_indexes where index_status is null;
exit when dis = 0;
end loop;
  pflb_datasan.pflb_write_logs('Exit pflb_disable_indexes');
end;
PROCEDURE PFLB_DISABLE_INDEXES(table_ownerName varchar2,
table_tableName varchar2)
AS
tSql varchar2(32767);
index_ownerName varchar2(255);
index_indexName varchar2(255);
cursor cur_indexes is
select distinct index_owner, index_name
from PFLB_TEMP_TABLE_INDEXES where index_status is null and owner_name=table_ownerName and table_name=table_tableName
;
begin
open cur_indexes;
fetch cur_indexes
    into index_ownerName, index_indexName
;
--DBMS_OUTPUT.put_line(index_indexName);
if index_indexName is not null then
loop
	tSql := 'alter index ' ||index_ownerName||'.'|| index_indexName ||  ' unusable';
    PFLB_DATASAN.PFLB_WRITE_LOGS(tSql);
--	DBMS_OUTPUT.put_line(tSql);

EXECUTE IMMEDIATE tSql;
update PFLB_TEMP_TABLE_INDEXES set index_status='NOT_PROCESSED' where index_owner=index_ownerName and index_name=index_indexName;
commit;
fetch cur_indexes
    into index_ownerName, index_indexName
;
exit when cur_indexes%NOTFOUND;
end loop;
end if;
close cur_indexes;
end;
PROCEDURE PFLB_UPDATE_JOB(
upstr varchar2,owner_n varchar2, table_n varchar2, dictflag integer)
as
tt varchar2(255);
flag number;
checks varchar2(4000);
ssid number;
rndc number;
metrid integer;
checker exception;
ccount number;
dictfl number;
begin
flag:=0;
begin
select PFLB_UPD_METR_SEQ.NEXTVAL into metrid from dual;
insert into PFLB_UPD_JOBS_METRICS
(id, job_query, job_start, channel)
values
    (metrid, upstr,current_timestamp,1);
commit;
if dictflag=1 then
select count(1) into dictfl from pflb_viewcontent v
                                     join pflb_dict_types d on d.column_encode_type=v.column_encode_type and v.encode_method=d.encode_method
where v.owner_name=owner_n and v.table_name=table_n;
if dictfl>0 then
pflb_datasan.pflb_dict_fill(owner_n,table_n);
end if;
end if;
set transaction isolation level read committed;
select sys_context('userenv','SID') into ssid from dual;
update pflb_active_jobs set SID=ssid where upstring=upstr;
commit;
EXECUTE IMMEDIATE upstr;
--pflb_datasan.PFLB_WRITE_LOGS(upstr);
delete from PFLB_ACTIVE_JOBS
where upstring=upstr;
commit;
update PFLB_UPD_JOBS_METRICS set job_end=current_timestamp, job_elaps_time=current_timestamp-job_start where id=metrid;
commit;
exception
 when others then
 pflb_datasan.PFLB_WRITE_LOGS('Error ' || SQLCODE || ': ' || SQLERRM);
 pflb_datasan.PFLB_UPD_ERR_HAND(upstr,owner_n,table_n,SQLCODE,ssid);
end;
end;
-- chess
PROCEDURE PFLB_EXEC_BY_RANGES_C(
    ownerName varchar2,
    TableName varchar2,
    where_clause varchar2,
	tquery varchar2,
	trows_per_tran number,
    threads integer,
    mthreads integer,
    priory integer,
    tk_column varchar2,
    sim integer
    )
AS
    fend number;
	ttable_name varchar2(255);
	tmin_id varchar2(255);
	tmax_id varchar2(255);
    eid number;
    qid number;
	tkey_column varchar2(255) := tk_column;
	tidentity_column varchar2(255);
	tsql  varchar2(32767);
    jsql varchar2(32767);
	tdelta number;
    jcount number;
    jcount_2 number;
    vcount1 number;
    vcount2 number;
    somemagic varchar2(5);
    jerror number;
    eflag number;
	trange_begin varchar2(255);
	trange_end varchar2(255);
    rflag integer :=1;
    rcount integer;
    av_thr integer;
    thr_op integer;
    thr_am integer;
    cont_flag integer;
    l_job number := null;
	tmax_processed_id varchar2(255);
	twhere_clause varchar2(32767);
	tresult_sql varchar2(32767);
    tresult_sql_even varchar2(32767);
    tresult_sql_even_m varchar2(32767);
	tmax_bigint varchar2(50) := '9223372036854775807';
	tsimulate number(1,0) := 1;
    idcurs      sys_refcursor;
      idtable   id_table_c;
BEGIN
begin
    pflb_datasan.PFLB_WRITE_LOGS('Starting to update ' || TableName || ' table');
update pflb_active_channels set status='PROCESSING' where priority=priory;
commit;
tmax_processed_id := pflb_datasan.PFLB_GET_MAX_PROC_ID_C(tquery);
	if tmax_processed_id = tmax_bigint then
    pflb_datasan.PFLB_WRITE_LOGS('Table ' || TableName || ' was already processed');
else
    if sim = 0 then
    tsql := 'select min(' || tkey_column || ') from '|| ownerName ||'.'|| TableName;
EXECUTE IMMEDIATE tsql INTO tmin_id;
tsql := 'select max(' || tkey_column || ') from '|| ownerName ||'.'|| TableName;
EXECUTE IMMEDIATE tsql INTO tmax_id ;
pflb_datasan.PFLB_WRITE_LOGS( tmin_id );
pflb_datasan.PFLB_WRITE_LOGS( tmax_id );
    if (tmax_processed_id > tmin_id) and (tmax_processed_id is not null) then
            tmin_id:=tmax_processed_id;
end if;
	if tmin_id is null
	then
        pflb_datasan.PFLB_WRITE_LOGS('Table ' || TableName || ' is probably empty');
		pflb_datasan.pflb_drop_col_idx(OwnerName,TableName);

		return;
end if;
open idcurs FOR 'SELECT '||tkey_column||' FROM '|| ownerName ||'.'|| TableName|| ' where '||tkey_column||' > '''||tmin_id||''' order by '||tkey_column||' asc';
FETCH idcurs
    BULK COLLECT INTO idtable
      LIMIT trows_per_tran;
pflb_datasan.PFLB_WRITE_LOGS( TableName );
select max(id) into trange_end from table(idtable);
trange_end:=trange_end;
      if trange_end is null then
      trange_end:=tmax_id;
end if;
    trange_begin:=tmin_id;
    pflb_datasan.PFLB_WRITE_LOGS(trange_begin||' '||TableName);
    fend:=0;
    eflag:=1;
    pflb_datasan.PFLB_WRITE_LOGS('Order by id on ' || TableName || ' is complited');
    if trange_begin=tmin_id then

        twhere_clause :=''''||trange_begin || ''' = ' || tkey_column;
        tresult_sql := pflb_datasan.pflb_combine_sql(tquery, twhere_clause);
                    if where_clause is not null then
                    tresult_sql := pflb_datasan.pflb_combine_sql(tresult_sql, where_clause);
end if;
		--	DBMS_OUTPUT.put_line(tresult_sql);
        pflb_datasan.PFLB_WRITE_LOGS(tresult_sql);
                    jsql:='begin PFLB_DATASAN.PFLB_UPDATE_JOB('''||pflb_fix_upd(tresult_sql)||''','''||ownerName||''','''||tableName||''',1); end;';
insert into PFLB_ACTIVE_JOBS(upstring,priority)
values
    (tresult_sql,priory);
sys.dbms_job.submit( l_job, jsql,sysdate,null );
   --         DBMS_OUTPUT.put_line('PFLB_UPD_PROC_INFO(tquery, trange_end)');
commit;

end if;
	while fend<1
	loop
       -- pflb_datasan.PFLB_WRITE_LOGS('CHECK 123 ');
select count(1) into jerror from pflb_active_status where (channel=0 and status='!@#$Ending all processes') or (channel=priory and status like '!@#$Skipping%');
if (trange_begin >= tmax_id and qid is null)
                            then
                                pflb_datasan.PFLB_WRITE_LOGS(trange_begin||' '||TableName);
                                pflb_datasan.PFLB_WRITE_LOGS(tmax_id||' '||TableName);
                                if jerror<1 then
                                    PFLB_DATASAN.PFLB_SLEEP(1);
select min(id) into qid from pflb_even_tables where id not in (
    select id from pflb_even_tables t1
                       join pflb_active_jobs t2 on t1.conc_job_1=t2.upstring
                       join pflb_active_jobs t3 on t1.conc_job_2=t3.upstring
    where id>0
) and id<>(select max(id) from pflb_even_tables)
                                                and job_query like '%'||ownerName||'.'||TableName||'%';
if trange_end>=tmax_id then
select min(id) into qid from pflb_even_tables where id not in (
    select id from pflb_even_tables t1
                       join pflb_active_jobs t2 on t1.conc_job_1=t2.upstring
    where id>0
)
                                                and job_query like '%'||ownerName||'.'||TableName||'%';
end if;
                                    if qid is null then
select count(1) into vcount1 from pflb_even_tables where job_query like '%'||ownerName||'.'||TableName||'%';
select  count(1) into vcount2 from pflb_active_jobs where priority=priory;
if vcount1<1 and vcount2<1 then
                                            pflb_datasan.PFLB_WRITE_LOGS('CHECK 5 ');
                                            fend:=1;
end if;
end if;
else
                                        fend:=1;
end if;
                                --  pflb_datasan.PFLB_WRITE_LOGS('CHECK 5 ');
else
                            --  pflb_datasan.PFLB_WRITE_LOGS('CHECK 6 ');
                            if jerror<1 then
                                cont_flag:=0;
select count(1) into jcount from pflb_active_jobs where priority=priory;
if jcount<threads then
                                    cont_flag:=1;
else
select count(1) into jcount_2 from pflb_active_jobs;
select mthreads-nvl(sum(treads_amt),0) into av_thr from pflb_active_channels;
select nvl(sum(treads_amt),0)+av_thr into thr_am from pflb_active_channels where priority=1 or priority=2;
select thr_am-nvl(sum(treads_amt),0) into thr_op from pflb_active_channels where (priority=1 or priority=2) and priority!=priory and status!='HOLD';
if jcount_2<thr_am and jcount<thr_op then
                                        cont_flag:=1;
end if;
end if;
                                if cont_flag=1 then
                                -- pflb_datasan.PFLB_WRITE_LOGS('CHECK 7 ');
select min(id) into qid from pflb_even_tables where id not in (
    select id from pflb_even_tables t1
                       join pflb_active_jobs t2 on t1.conc_job_1=t2.upstring
                       join pflb_active_jobs t3 on t1.conc_job_2=t3.upstring
    where id>0
) and id<>(select max(id) from pflb_even_tables)
                                                and job_query like '%'||ownerName||'.'||TableName||'%';
if trange_end>=tmax_id then
select min(id) into qid from pflb_even_tables where id not in (
    select id from pflb_even_tables t1
                       join pflb_active_jobs t2 on t1.conc_job_1=t2.upstring
    where id>0
)
                                                and job_query like '%'||ownerName||'.'||TableName||'%';
end if;
                                    --  pflb_datasan.PFLB_WRITE_LOGS('CHECK qid '||qid||' trange_end '||trange_end||' tmax_id '||tmax_id||' mod(eflag,2) '||mod(eflag,2));
                                        if qid is not null then
select job_query into tresult_sql_even from pflb_even_tables where id=qid;
pflb_datasan.PFLB_WRITE_LOGS(tresult_sql_even);
                                            jsql:='begin PFLB_DATASAN.PFLB_UPDATE_JOB('''||pflb_fix_upd(tresult_sql_even)||''','''||ownerName||''','''||tableName||''',1); end;';
insert into PFLB_ACTIVE_JOBS(upstring,priority)
values
    (tresult_sql_even,priory);
delete from pflb_even_tables where id=qid;
-- pflb_datasan.PFLB_WRITE_LOGS('CHECK 1 ');
-- pflb_datasan.PFLB_WRITE_LOGS(tresult_sql_even);
sys.dbms_job.submit( l_job, jsql,sysdate,null );
commit;

-- pflb_datasan.PFLB_WRITE_LOGS('CHECK 1 ');
elsif mod(eflag,2)=0 then
                                            eflag:=eflag+1;
                                            twhere_clause :=''''||trange_begin || ''' < ' || tkey_column || ' and ' ||
                                            tkey_column || ' <= ''' || trange_end||'''';
                                            if tsimulate = 1
                                            then
                                                twhere_clause := twhere_clause;
end if;
                                            --print 'Range ' + convert(varchar, @range_begin) + ' - ' + convert(varchar, @range_end)
                                            if (trange_begin >= tmax_processed_id) or (tmax_processed_id is null)
                                            then
                                                tresult_sql_even_m := pflb_datasan.pflb_combine_sql(tquery, twhere_clause);
                                                if where_clause is not null then
                                                    tresult_sql_even_m := pflb_datasan.pflb_combine_sql(tresult_sql_even_m, where_clause);
end if;
insert into pflb_even_tables ( job_query, conc_job_1)
values ( tresult_sql_even_m, tresult_sql);
select max(id) into eid from pflb_even_tables;
if eid is null then
                                                    eid:=0;
end if;
commit;
-- pflb_datasan.PFLB_WRITE_LOGS(tresult_sql_even_m);
end if;
                                            trange_begin := trange_end;
                                            pflb_datasan.PFLB_WRITE_LOGS(trange_begin||' 1 '||TableName);
begin
FETCH idcurs
    BULK COLLECT INTO idtable
                                                LIMIT trows_per_tran;
exception
                                                when others then
                                                close idcurs;
open idcurs FOR 'SELECT '||tkey_column||' FROM '|| ownerName ||'.'|| TableName|| ' where '||tkey_column||' > '''||trange_begin||''' order by '||tkey_column||' asc';
FETCH idcurs
    BULK COLLECT INTO idtable
                                                LIMIT trows_per_tran;
end;
select max(id) into trange_end from table(idtable);
trange_end:=trange_end;
                                            if trange_end is null then
                                                trange_end:=tmax_id;
end if;
                                            --  pflb_datasan.PFLB_WRITE_LOGS('CHECK 2 ');
                                        elsif mod(eflag,2)=1 then

                                            --   pflb_datasan.PFLB_WRITE_LOGS('CHECK 3 en ');
                                            eflag:=eflag+1;
                                            twhere_clause :=''''||trange_begin || ''' < ' || tkey_column || ' and ' ||
                                            tkey_column || ' <= ''' || trange_end||'''';
                                            if tsimulate = 1
                                            then
                                                twhere_clause := twhere_clause;
end if;
                                            --print 'Range ' + convert(varchar, @range_begin) + ' - ' + convert(varchar, @range_end)
                                            if (trange_begin >= tmax_processed_id) or (tmax_processed_id is null)
                                            then
                                                tresult_sql := pflb_datasan.pflb_combine_sql(tquery, twhere_clause);
                                                if where_clause is not null then
                                                    tresult_sql := pflb_datasan.pflb_combine_sql(tresult_sql, where_clause);
end if;
                                                --	DBMS_OUTPUT.put_line(tresult_sql);
                                                pflb_datasan.PFLB_WRITE_LOGS(tresult_sql);
                                                jsql:='begin PFLB_DATASAN.PFLB_UPDATE_JOB('''||pflb_fix_upd(tresult_sql)||''','''||ownerName||''','''||tableName||''',1); end;';
insert into PFLB_ACTIVE_JOBS(upstring,priority)
values
    (tresult_sql,priory);
update pflb_even_tables set conc_job_2=tresult_sql where id=eid;
sys.dbms_job.submit( l_job, jsql,sysdate,null );
                                                --         DBMS_OUTPUT.put_line('PFLB_UPD_PROC_INFO_C(tquery, trange_end)');
commit;
pflb_datasan.PFLB_UPD_PROC_INFO_C(tquery, trange_end);
end if;
                                            trange_begin := trange_end;
                                            pflb_datasan.PFLB_WRITE_LOGS(trange_begin||' 2 '||TableName);
begin
FETCH idcurs
    BULK COLLECT INTO idtable
                                                LIMIT trows_per_tran;
exception
                                                when others then
                                                close idcurs;
open idcurs FOR 'SELECT '||tkey_column||' FROM '|| ownerName ||'.'|| TableName|| ' where '||tkey_column||' > '''||trange_begin||''' order by '||tkey_column||' asc';
FETCH idcurs
    BULK COLLECT INTO idtable
                                                LIMIT trows_per_tran;
end;
select max(id) into trange_end from table(idtable);
trange_end:=trange_end;
                                            if trange_end is null then
                                                trange_end:=tmax_id;
end if;
                                            --   pflb_datasan.PFLB_WRITE_LOGS('CHECK 3 ');
                                        elsif qid is null and jcount = 0 then
                                            pflb_datasan.PFLB_WRITE_LOGS('CHECK 6 '||mod(eflag,2));
                                            fend:=1;
else
                                            --  pflb_datasan.PFLB_WRITE_LOGS('CHECK 4 ');
                                            PFLB_DATASAN.PFLB_SLEEP(1/2);
end if;
else
                                        PFLB_DATASAN.PFLB_SLEEP(1/2);
end if;
else
                                    pflb_datasan.PFLB_WRITE_LOGS('CHECK 7 ');
                                    fend:=1;
end if;
end if;
end loop;
close idcurs;
update pflb_active_channels set status='HOLD' where priority=priory;
commit;
select count(1) into jerror from pflb_active_status where (channel=0 and status='!@#$Ending all processes') or (channel=priory and status like '!@#$Skipping%');
if jerror<1 then
    jcount:=1;
    while jcount>0
    loop
select count(1) into jcount from pflb_active_jobs where priority=priory;
select count(1) into jerror from pflb_active_status where (channel=0 and status='!@#$Ending all processes') or (channel=priory and status like '!@#$Skipping%');
if jerror>0 then
    jcount:=0;
end if;
    PFLB_DATASAN.PFLB_SLEEP(1/2);
end loop;
	pflb_datasan.PFLB_UPD_PROC_INFO_C (tquery, tmax_bigint);	-- ?s????N?N‚?°??N‚?°, ???·???°N‡?°NZN‰?°N? ?????»??N?NZ ???±N€?°?±??N‚??N? N‚?°?±?»??N†N‹.
   -- DBMS_OUTPUT.put_line('PFLB_UPD_PROC_INFO_C (tquery, tmax_bigint)');
    --DBMS_OUTPUT.put_line('pflb_drop_col_idx (ttable_name)');
end if;
end if;
end if;
exception
    when others then
update pflb_processed_tables set status='SKIPPED' where owner_name=ownerName and table_name=TableName;
pflb_datasan.PFLB_WRITE_LOGS('Error ' || SQLCODE || ': ' || SQLERRM);
commit;
end;
END;
PROCEDURE PFLB_EXEC_BY_RANG_STHR_C(
    ownerName varchar2,
    TableName varchar2,
    where_clause varchar2,
	tquery varchar2,
	trows_per_tran number,
    threads integer,
    mthreads integer,
    priory integer,
    tk_column varchar2,
    sim integer
    )
AS
    fend number;
	ttable_name varchar2(255);
	tmin_id varchar2(255);
	tmax_id varchar2(255);
    eid number;
    qid number;
	tkey_column varchar2(255) := tk_column;
	tidentity_column varchar2(255);
	tsql  varchar2(32767);
    jsql varchar2(32767);
	tdelta number;
    jcount number;
    jcount_2 number;
    vcount1 number;
    vcount2 number;
    somemagic varchar2(5);
    jerror number;
    eflag number;
	trange_begin varchar2(255);
	trange_end varchar2(255);
    rflag integer :=1;
    rcount integer;
    av_thr integer;
    thr_op integer;
    thr_am integer;
    cont_flag integer;
    l_job number := null;
	tmax_processed_id varchar2(255);
	twhere_clause varchar2(32767);
	tresult_sql varchar2(32767);
    tresult_sql_even varchar2(32767);
    tresult_sql_even_m varchar2(32767);
	tmax_bigint varchar2(50) := '9223372036854775807';
	tsimulate number(1,0) := 1;
    idcurs      sys_refcursor;
      idtable   id_table_c;
BEGIN
begin
    pflb_datasan.PFLB_WRITE_LOGS('Starting to update ' || TableName || ' table');
update pflb_active_channels set status='PROCESSING' where priority=priory;
commit;
tmax_processed_id := pflb_datasan.PFLB_GET_MAX_PROC_ID_C(tquery);
	if tmax_processed_id = tmax_bigint then
    pflb_datasan.PFLB_WRITE_LOGS('Table ' || TableName || ' was already processed');
else
    if sim = 0 then
    tsql := 'select min(' || tkey_column || ') from '|| ownerName ||'.'|| TableName;
EXECUTE IMMEDIATE tsql INTO tmin_id;
tsql := 'select max(' || tkey_column || ') from '|| ownerName ||'.'|| TableName;
EXECUTE IMMEDIATE tsql INTO tmax_id ;
pflb_datasan.PFLB_WRITE_LOGS( tmin_id );
pflb_datasan.PFLB_WRITE_LOGS( tmax_id );
    if (tmax_processed_id > tmin_id) and (tmax_processed_id is not null) then
            tmin_id:=tmax_processed_id;
end if;
	if tmin_id is null
	then
        pflb_datasan.PFLB_WRITE_LOGS('Table ' || TableName || ' is probably empty');
		pflb_datasan.pflb_drop_col_idx(OwnerName,TableName);

		return;
end if;
open idcurs FOR 'SELECT '||tkey_column||' FROM '|| ownerName ||'.'|| TableName|| ' where '||tkey_column||' > '''||tmin_id||''' order by '||tkey_column||' asc';
FETCH idcurs
    BULK COLLECT INTO idtable
      LIMIT trows_per_tran;
pflb_datasan.PFLB_WRITE_LOGS( TableName );
select max(id) into trange_end from table(idtable);
trange_end:=trange_end;
      if trange_end is null then
      trange_end:=tmax_id;
end if;
    trange_begin:=tmin_id;
    pflb_datasan.PFLB_WRITE_LOGS(trange_begin||' '||TableName);
    fend:=0;
    eflag:=1;
    pflb_datasan.PFLB_WRITE_LOGS('Order by id on ' || TableName || ' is complited');
    if trange_begin=tmin_id then

        twhere_clause :=''''||trange_begin || ''' = ' || tkey_column;
        tresult_sql := pflb_datasan.pflb_combine_sql(tquery, twhere_clause);
                    if where_clause is not null then
                    tresult_sql := pflb_datasan.pflb_combine_sql(tresult_sql, where_clause);
end if;
		--	DBMS_OUTPUT.put_line(tresult_sql);
        pflb_datasan.PFLB_WRITE_LOGS(tresult_sql);
                    jsql:='begin PFLB_DATASAN.PFLB_UPDATE_JOB('''||pflb_fix_upd(tresult_sql)||''','''||ownerName||''','''||tableName||''',0); end;';
insert into PFLB_ACTIVE_JOBS(upstring,priority)
values
    (tresult_sql,priory);
commit;
execute immediate jsql;
pflb_datasan.PFLB_UPD_PROC_INFO_c(tquery, trange_begin);
   --         DBMS_OUTPUT.put_line('PFLB_UPD_PROC_INFO(tquery, trange_end)');
commit;

end if;
	while fend<1
	loop
       -- pflb_datasan.PFLB_WRITE_LOGS('CHECK 123 ');
select count(1) into jerror from pflb_active_status where (channel=0 and status='!@#$Ending all processes') or (channel=priory and status like '!@#$Skipping%');
if jerror>=1 then
            fend:=1;
else
select treads_amt into thr_op from pflb_active_channels where priority=priory;
if thr_op>1 then
update pflb_active_channels set status='CHANGE_THR_BEHAVE' where priority=priory;
commit;
fend:=1;
else
                if (trange_begin >= tmax_id) then
                    fend:=1;
else
                    if tsimulate = 1
                    then
                    twhere_clause := twhere_clause;
end if;
		--print 'Range ' + convert(varchar, @range_begin) + ' - ' + convert(varchar, @range_end)
                    if (trange_begin >= tmax_processed_id) or (tmax_processed_id is null)
                    then
                    twhere_clause :=''''||trange_begin || ''' < ' || tkey_column || ' and ' ||
                                            tkey_column || ' <= ''' || trange_end||'''';
                    tresult_sql := pflb_datasan.pflb_combine_sql(tquery, twhere_clause);
                    if where_clause is not null then
                    tresult_sql := pflb_datasan.pflb_combine_sql(tresult_sql, where_clause);
end if;
		--	DBMS_OUTPUT.put_line(tresult_sql);
        pflb_datasan.PFLB_WRITE_LOGS(tresult_sql);
                    jsql:='begin PFLB_DATASAN.PFLB_UPDATE_JOB('''||pflb_fix_upd(tresult_sql)||''','''||ownerName||''','''||tableName||''',0); end;';
insert into PFLB_ACTIVE_JOBS(upstring,priority)
values
    (tresult_sql,priory);
commit;
execute immediate jsql;
--         DBMS_OUTPUT.put_line('PFLB_UPD_PROC_INFO(tquery, trange_end)');
commit;
pflb_datasan.PFLB_UPD_PROC_INFO_c(tquery, trange_end);
                    trange_begin := trange_end;
                    pflb_datasan.PFLB_WRITE_LOGS(trange_begin||' 2 '||TableName);
begin
FETCH idcurs
    BULK COLLECT INTO idtable
      LIMIT trows_per_tran;
exception
 when others then
 close idcurs;
open idcurs FOR 'SELECT '||tkey_column||' FROM '|| ownerName ||'.'|| TableName|| ' where '||tkey_column||' > '||trange_begin||' order by '||tkey_column||' asc';
FETCH idcurs
    BULK COLLECT INTO idtable
      LIMIT trows_per_tran;
end;
select max(id) into trange_end from table(idtable);
trange_end:=trange_end;
      if trange_end is null then
      trange_end:=tmax_id;
end if;
else
begin
FETCH idcurs
    BULK COLLECT INTO idtable
      LIMIT trows_per_tran;
exception
 when others then
 close idcurs;
open idcurs FOR 'SELECT '||tkey_column||' FROM '|| ownerName ||'.'|| TableName|| ' where '||tkey_column||' > '||trange_begin||' order by '||tkey_column||' asc';
FETCH idcurs
    BULK COLLECT INTO idtable
      LIMIT trows_per_tran;
end;
end if;
end if;
end if;
end if;
end loop;
close idcurs;
update pflb_active_channels set status='HOLD' where priority=priory;
commit;
end if;
end if;
exception
    when others then
update pflb_processed_tables set status='SKIPPED' where owner_name=ownerName and table_name=TableName;
pflb_datasan.PFLB_WRITE_LOGS('Error ' || SQLCODE || ': ' || SQLERRM);
commit;
end;
END;
PROCEDURE PFLB_EXEC_BY_RANGES(
    ownerName varchar2,
    TableName varchar2,
    where_clause varchar2,
	tquery varchar2,
	trows_per_tran number,
    threads integer,
    mthreads integer,
    priory integer,
    tk_column varchar2,
    sim integer
    )
AS
    fend number;
	ttable_name varchar2(255);
	tmin_id number;
	tmax_id number;
    eid number;
    qid number;
	tkey_column varchar2(255) := tk_column;
	tidentity_column varchar2(255);
	tsql  varchar2(32767);
    jsql varchar2(32767);
	tdelta number;
    jcount number;
    jcount_2 number;
    vcount1 number;
    vcount2 number;
    somemagic varchar2(5);
    jerror number;
    eflag number;
	trange_begin number;
	trange_end number;
    rflag integer :=1;
    rcount integer;
    av_thr integer;
    thr_op integer;
    thr_am integer;
    cont_flag integer;
    l_job number := null;
	tmax_processed_id number;
	twhere_clause varchar2(32767);
	tresult_sql varchar2(32767);
    tresult_sql_even varchar2(32767);
    tresult_sql_even_m varchar2(32767);
	tmax_bigint number := 9223372036854775807;
	tsimulate number(1,0) := 1;
    idcurs      sys_refcursor;
      idtable   id_table;
BEGIN
begin
    pflb_datasan.PFLB_WRITE_LOGS('Starting to update ' || TableName || ' table');
update pflb_active_channels set status='PROCESSING' where priority=priory;
commit;
tmax_processed_id := pflb_datasan.PFLB_GET_MAX_PROCESSED_ID(tquery);
	if tmax_processed_id = tmax_bigint then
    pflb_datasan.PFLB_WRITE_LOGS('Table ' || TableName || ' was already processed');
else
    if sim = 0 then
    tsql := 'select min(' || tkey_column || ') from '|| ownerName ||'.'|| TableName;
EXECUTE IMMEDIATE tsql INTO tmin_id;
tsql := 'select max(' || tkey_column || ') from '|| ownerName ||'.'|| TableName;
EXECUTE IMMEDIATE tsql INTO tmax_id ;
if (tmax_processed_id > tmin_id) and (tmax_processed_id is not null) then
            tmin_id:=tmax_processed_id;
end if;
pflb_datasan.PFLB_WRITE_LOGS( tmin_id );
pflb_datasan.PFLB_WRITE_LOGS( tmax_id );
	if tmin_id is null
	then
        pflb_datasan.PFLB_WRITE_LOGS('Table ' || TableName || ' is probably empty');
		pflb_datasan.pflb_drop_col_idx(OwnerName,TableName);

		return;
end if;
    pflb_datasan.PFLB_WRITE_LOGS( 'Trying to open cursor for ' || ownerName ||'.'|| TableName);
open idcurs FOR 'SELECT '||tkey_column||' FROM '|| ownerName ||'.'|| TableName|| ' where '||tkey_column||' >= '||tmin_id||' order by '||tkey_column||' asc';
pflb_datasan.PFLB_WRITE_LOGS( 'Cursor is opened for ' || ownerName ||'.'|| TableName);
FETCH idcurs
    BULK COLLECT INTO idtable
      LIMIT trows_per_tran;
pflb_datasan.PFLB_WRITE_LOGS( 'First value is fetched for ' || ownerName ||'.'|| TableName);
      pflb_datasan.PFLB_WRITE_LOGS( TableName );
select max(id) into trange_end from table(idtable);
trange_end:=trange_end;
      if trange_end is null then
      trange_end:=tmax_id;
end if;
    trange_begin:=tmin_id;
    pflb_datasan.PFLB_WRITE_LOGS(trange_begin||' '||TableName);
    fend:=0;
    eflag:=1;
    pflb_datasan.PFLB_WRITE_LOGS('Order by id on ' || TableName || ' is complited');
    if tmax_processed_id=tmin_id or tmax_processed_id is null then

        twhere_clause :=cast((trange_begin) as varchar2) || ' = ' || tkey_column;
        tresult_sql := pflb_datasan.pflb_combine_sql(tquery, twhere_clause);
                    if where_clause is not null and where_clause!='0' then
                    tresult_sql := pflb_datasan.pflb_combine_sql(tresult_sql, where_clause);
end if;
		--	DBMS_OUTPUT.put_line(tresult_sql);
        pflb_datasan.PFLB_WRITE_LOGS(tresult_sql);
                    jsql:='begin PFLB_DATASAN.PFLB_UPDATE_JOB('''||pflb_fix_upd(tresult_sql)||''','''||ownerName||''','''||tableName||''',1); end;';
insert into PFLB_ACTIVE_JOBS(upstring,priority)
values
    (tresult_sql,priory);
sys.dbms_job.submit( l_job, jsql,sysdate,null );
                    pflb_datasan.PFLB_UPD_PROC_INFO(tquery, trange_begin);
   --         DBMS_OUTPUT.put_line('PFLB_UPD_PROC_INFO(tquery, trange_end)');
commit;

end if;
	while fend<1
	loop
       -- pflb_datasan.PFLB_WRITE_LOGS('CHECK 123 ');
select count(1) into jerror from pflb_active_status where (channel=0 and status='!@#$Ending all processes') or (channel=priory and status like '!@#$Skipping%');
if (trange_begin >= tmax_id and qid is null)
        then
        pflb_datasan.PFLB_WRITE_LOGS(trange_begin||' '||TableName);
        pflb_datasan.PFLB_WRITE_LOGS(tmax_id||' '||TableName);
        if jerror<1 then
        PFLB_DATASAN.PFLB_SLEEP(1);
select min(id) into qid from pflb_even_tables where id not in (
    select id from pflb_even_tables t1
                       join pflb_active_jobs t2 on t1.conc_job_1=t2.upstring
                       join pflb_active_jobs t3 on t1.conc_job_2=t3.upstring
    where id>0
) and id<>(select max(id) from pflb_even_tables)
                                                and job_query like '%'||ownerName||'.'||TableName||'%';
if trange_end>=tmax_id then
select min(id) into qid from pflb_even_tables where id not in (
    select id from pflb_even_tables t1
                       join pflb_active_jobs t2 on t1.conc_job_1=t2.upstring
    where id>0
)
                                                and job_query like '%'||ownerName||'.'||TableName||'%';
end if;
                        if qid is null then
select count(1) into vcount1 from pflb_even_tables where job_query like '%'||ownerName||'.'||TableName||'%';
select  count(1) into vcount2 from pflb_active_jobs where priority=priory;
if vcount1<1 and vcount2<1 then
                        pflb_datasan.PFLB_WRITE_LOGS('CHECK 5 ');
        fend:=1;
end if;
end if;
else
        fend:=1;
end if;
      --  pflb_datasan.PFLB_WRITE_LOGS('CHECK 5 ');
else
      --  pflb_datasan.PFLB_WRITE_LOGS('CHECK 6 ');
        if jerror<1 then
            cont_flag:=0;
select count(1) into jcount from pflb_active_jobs where priority=priory;
if jcount<threads then
                cont_flag:=1;
else
select count(1) into jcount_2 from pflb_active_jobs;
select mthreads-nvl(sum(treads_amt),0) into av_thr from pflb_active_channels;
select nvl(sum(treads_amt),0)+av_thr into thr_am from pflb_active_channels where priority=1 or priority=2;
select thr_am-nvl(sum(treads_amt),0) into thr_op from pflb_active_channels where (priority=1 or priority=2) and priority!=priory and status!='HOLD';
if jcount_2<thr_am and jcount<thr_op then
                    cont_flag:=1;
end if;
end if;
                if cont_flag=1 then
               -- pflb_datasan.PFLB_WRITE_LOGS('CHECK 7 ');
select min(id) into qid from pflb_even_tables where id not in (
    select id from pflb_even_tables t1
                       join pflb_active_jobs t2 on t1.conc_job_1=t2.upstring
                       join pflb_active_jobs t3 on t1.conc_job_2=t3.upstring
    where id>0
) and id<>(select max(id) from pflb_even_tables)
                                                and job_query like '%'||ownerName||'.'||TableName||'%';
if trange_end>=tmax_id then
select min(id) into qid from pflb_even_tables where id not in (
    select id from pflb_even_tables t1
                       join pflb_active_jobs t2 on t1.conc_job_1=t2.upstring
    where id>0
)
                                                and job_query like '%'||ownerName||'.'||TableName||'%';
end if;
                      --  pflb_datasan.PFLB_WRITE_LOGS('CHECK qid '||qid||' trange_end '||trange_end||' tmax_id '||tmax_id||' mod(eflag,2) '||mod(eflag,2));
                                        if qid is not null then
select job_query into tresult_sql_even from pflb_even_tables where id=qid;
pflb_datasan.PFLB_WRITE_LOGS(tresult_sql_even);
                    jsql:='begin PFLB_DATASAN.PFLB_UPDATE_JOB('''||pflb_fix_upd(tresult_sql_even)||''','''||ownerName||''','''||tableName||''',1); end;';
insert into PFLB_ACTIVE_JOBS(upstring,priority)
values
    (tresult_sql_even,priory);
delete from pflb_even_tables where id=qid;
-- pflb_datasan.PFLB_WRITE_LOGS('CHECK 1 ');
-- pflb_datasan.PFLB_WRITE_LOGS(tresult_sql_even);
sys.dbms_job.submit( l_job, jsql,sysdate,null );
commit;

-- pflb_datasan.PFLB_WRITE_LOGS('CHECK 1 ');
elsif mod(eflag,2)=0 then
                    eflag:=eflag+1;
                    twhere_clause :=cast((trange_begin) as varchar2) || ' < ' || tkey_column || ' and ' ||
							tkey_column || ' <= ' || cast((trange_end) as varchar2);
                    if tsimulate = 1
                    then
                    twhere_clause := twhere_clause;
end if;
		--print 'Range ' + convert(varchar, @range_begin) + ' - ' + convert(varchar, @range_end)
                    if (trange_begin >= tmax_processed_id) or (tmax_processed_id is null)
                    then
                    tresult_sql_even_m := pflb_datasan.pflb_combine_sql(tquery, twhere_clause);
                    if where_clause is not null and where_clause!='0' then
                    tresult_sql_even_m := pflb_datasan.pflb_combine_sql(tresult_sql_even_m, where_clause);
end if;
insert into pflb_even_tables ( job_query, conc_job_1)
values ( tresult_sql_even_m, tresult_sql);
select max(id) into eid from pflb_even_tables;
if eid is null then eid:=0;
end if;
commit;
-- pflb_datasan.PFLB_WRITE_LOGS(tresult_sql_even_m);
end if;
                     trange_begin := trange_end;
                     pflb_datasan.PFLB_WRITE_LOGS(trange_begin||' 1 '||TableName);
begin
FETCH idcurs
    BULK COLLECT INTO idtable
      LIMIT trows_per_tran;
exception
 when others then
 close idcurs;
open idcurs FOR 'SELECT '||tkey_column||' FROM '|| ownerName ||'.'|| TableName|| ' where '||tkey_column||' > '||trange_begin||' order by '||tkey_column||' asc';
FETCH idcurs
    BULK COLLECT INTO idtable
      LIMIT trows_per_tran;
end;
select max(id) into trange_end from table(idtable);
trange_end:=trange_end;
      if trange_end is null then
      trange_end:=tmax_id;
end if;
                  --  pflb_datasan.PFLB_WRITE_LOGS('CHECK 2 ');
                                elsif mod(eflag,2)=1 then

                 --   pflb_datasan.PFLB_WRITE_LOGS('CHECK 3 en ');
                    eflag:=eflag+1;
                    twhere_clause :=cast((trange_begin) as varchar2) || ' < ' || tkey_column || ' and ' ||
							tkey_column || ' <= ' || cast((trange_end) as varchar2);
                    if tsimulate = 1
                    then
                    twhere_clause := twhere_clause;
end if;
		--print 'Range ' + convert(varchar, @range_begin) + ' - ' + convert(varchar, @range_end)
                    if (trange_begin >= tmax_processed_id) or (tmax_processed_id is null)
                    then
                    tresult_sql := pflb_datasan.pflb_combine_sql(tquery, twhere_clause);
                    if where_clause is not null and where_clause!='0' then
                    tresult_sql := pflb_datasan.pflb_combine_sql(tresult_sql, where_clause);
end if;
		--	DBMS_OUTPUT.put_line(tresult_sql);
        pflb_datasan.PFLB_WRITE_LOGS(tresult_sql);
                    jsql:='begin PFLB_DATASAN.PFLB_UPDATE_JOB('''||pflb_fix_upd(tresult_sql)||''','''||ownerName||''','''||tableName||''',1); end;';
insert into PFLB_ACTIVE_JOBS(upstring,priority)
values
    (tresult_sql,priory);
update pflb_even_tables set conc_job_2=tresult_sql where id=eid;
sys.dbms_job.submit( l_job, jsql,sysdate,null );
   --         DBMS_OUTPUT.put_line('PFLB_UPD_PROC_INFO(tquery, trange_end)');
commit;
pflb_datasan.PFLB_UPD_PROC_INFO(tquery, trange_end);
end if;
                    trange_begin := trange_end;
                    pflb_datasan.PFLB_WRITE_LOGS(trange_begin||' 2 '||TableName);
begin
FETCH idcurs
    BULK COLLECT INTO idtable
      LIMIT trows_per_tran;
exception
 when others then
 close idcurs;
open idcurs FOR 'SELECT '||tkey_column||' FROM '|| ownerName ||'.'|| TableName|| ' where '||tkey_column||' > '||trange_begin||' order by '||tkey_column||' asc';
FETCH idcurs
    BULK COLLECT INTO idtable
      LIMIT trows_per_tran;
end;
select max(id) into trange_end from table(idtable);
trange_end:=trange_end;
      if trange_end is null then
      trange_end:=tmax_id;
end if;
   --   pflb_datasan.PFLB_WRITE_LOGS('CHECK 3 ');
      elsif qid is null and jcount = 0 then
      pflb_datasan.PFLB_WRITE_LOGS('CHECK 6 '||mod(eflag,2));
      fend:=1;
else
    --  pflb_datasan.PFLB_WRITE_LOGS('CHECK 4 ');
                PFLB_DATASAN.PFLB_SLEEP(1/2);
end if;
else
                PFLB_DATASAN.PFLB_SLEEP(1/2);
end if;
else
        pflb_datasan.PFLB_WRITE_LOGS('CHECK 7 ');
        fend:=1;
end if;
end if;
end loop;
close idcurs;
update pflb_active_channels set status='HOLD' where priority=priory;
commit;
select count(1) into jerror from pflb_active_status where (channel=0 and status='!@#$Ending all processes') or (channel=priory and status like '!@#$Skipping%');
if jerror<1 then
    jcount:=1;
    while jcount>0
    loop
select count(1) into jcount from pflb_active_jobs where priority=priory;
select count(1) into jerror from pflb_active_status where (channel=0 and status='!@#$Ending all processes') or (channel=priory and status like '!@#$Skipping%');
if jerror>0 then
    jcount:=0;
end if;
    PFLB_DATASAN.PFLB_SLEEP(1/2);
end loop;
	pflb_datasan.PFLB_UPD_PROC_INFO (tquery, tmax_bigint);	-- ?s????N?N‚?°??N‚?°, ???·???°N‡?°NZN‰?°N? ?????»??N?NZ ???±N€?°?±??N‚??N? N‚?°?±?»??N†N‹.
   -- DBMS_OUTPUT.put_line('PFLB_UPD_PROC_INFO (tquery, tmax_bigint)');
    --DBMS_OUTPUT.put_line('pflb_drop_col_idx (ttable_name)');
end if;
end if;
end if;
exception
    when others then
update pflb_processed_tables set status='SKIPPED' where owner_name=ownerName and table_name=TableName;
pflb_datasan.PFLB_WRITE_LOGS('Error ' || SQLCODE || ': ' || SQLERRM);
commit;
end;
END;
PROCEDURE PFLB_EXEC_BY_RANG_STHR(
    ownerName varchar2,
    TableName varchar2,
    where_clause varchar2,
	tquery varchar2,
	trows_per_tran number,
    threads integer,
    mthreads integer,
    priory integer,
    tk_column varchar2,
    sim integer
    )
AS
    fend number;
	ttable_name varchar2(255);
	tmin_id number;
	tmax_id number;
    eid number;
    qid number;
	tkey_column varchar2(255) := tk_column;
	tidentity_column varchar2(255);
	tsql  varchar2(32767);
    jsql varchar2(32767);
	tdelta number;
    jcount number;
    jcount_2 number;
    vcount1 number;
    vcount2 number;
    somemagic varchar2(5);
    jerror number;
    eflag number;
	trange_begin number;
	trange_end number;
    rflag integer :=1;
    rcount integer;
    av_thr integer;
    thr_op integer;
    thr_am integer;
    cont_flag integer;
    l_job number := null;
	tmax_processed_id number;
	twhere_clause varchar2(32767);
	tresult_sql varchar2(32767);
    tresult_sql_even varchar2(32767);
    tresult_sql_even_m varchar2(32767);
	tmax_bigint number := 9223372036854775807;
	tsimulate number(1,0) := 1;
    idcurs      sys_refcursor;
      idtable   id_table;
BEGIN
begin
    pflb_datasan.PFLB_WRITE_LOGS('Starting to update ' || TableName || ' table');
update pflb_active_channels set status='PROCESSING' where priority=priory;
commit;
tmax_processed_id := pflb_datasan.PFLB_GET_MAX_PROCESSED_ID(tquery);
	if tmax_processed_id = tmax_bigint then
    pflb_datasan.PFLB_WRITE_LOGS('Table ' || TableName || ' was already processed');
else
    if sim = 0 then
    tsql := 'select min(' || tkey_column || ') from '|| ownerName ||'.'|| TableName;
EXECUTE IMMEDIATE tsql INTO tmin_id;
tsql := 'select max(' || tkey_column || ') from '|| ownerName ||'.'|| TableName;
EXECUTE IMMEDIATE tsql INTO tmax_id ;
if (tmax_processed_id > tmin_id) and (tmax_processed_id is not null) then
            tmin_id:=tmax_processed_id;
end if;
pflb_datasan.PFLB_WRITE_LOGS( tmin_id );
pflb_datasan.PFLB_WRITE_LOGS( tmax_id );
	if tmin_id is null
	then
        pflb_datasan.PFLB_WRITE_LOGS('Table ' || TableName || ' is probably empty');
		pflb_datasan.pflb_drop_col_idx(OwnerName,TableName);

		return;
end if;
open idcurs FOR 'SELECT '||tkey_column||' FROM '|| ownerName ||'.'|| TableName|| ' where '||tkey_column||' >= '||tmin_id||' order by '||tkey_column||' asc';
FETCH idcurs
    BULK COLLECT INTO idtable
      LIMIT trows_per_tran;
pflb_datasan.PFLB_WRITE_LOGS( TableName );
select max(id) into trange_end from table(idtable);
trange_end:=trange_end;
      if trange_end is null then
      trange_end:=tmax_id;
end if;
    trange_begin:=tmin_id;
    pflb_datasan.PFLB_WRITE_LOGS(trange_begin||' '||TableName);
    fend:=0;
    eflag:=1;
    pflb_datasan.PFLB_WRITE_LOGS('Order by id on ' || TableName || ' is complited');
    if tmax_processed_id=tmin_id or tmax_processed_id is null then

        twhere_clause :=cast((trange_begin) as varchar2) || ' = ' || tkey_column;
        tresult_sql := pflb_datasan.pflb_combine_sql(tquery, twhere_clause);
                    if where_clause is not null and where_clause!='0' then
                    tresult_sql := pflb_datasan.pflb_combine_sql(tresult_sql, where_clause);
end if;
		--	DBMS_OUTPUT.put_line(tresult_sql);
        pflb_datasan.PFLB_WRITE_LOGS(tresult_sql);
                    jsql:='begin PFLB_DATASAN.PFLB_UPDATE_JOB('''||pflb_fix_upd(tresult_sql)||''','''||ownerName||''','''||tableName||''',0); end;';
insert into PFLB_ACTIVE_JOBS(upstring,priority)
values
    (tresult_sql,priory);
commit;
execute immediate jsql;
pflb_datasan.PFLB_UPD_PROC_INFO(tquery, trange_begin);
   --         DBMS_OUTPUT.put_line('PFLB_UPD_PROC_INFO(tquery, trange_end)');
commit;

end if;
	while fend<1
	loop
       -- pflb_datasan.PFLB_WRITE_LOGS('CHECK 123 ');
select count(1) into jerror from pflb_active_status where (channel=0 and status='!@#$Ending all processes') or (channel=priory and status like '!@#$Skipping%');
if jerror>=1 then
            fend:=1;
else
select treads_amt into thr_op from pflb_active_channels where priority=priory;
if thr_op>1 then
update pflb_active_channels set status='CHANGE_THR_BEHAVE' where priority=priory;
commit;
fend:=1;
else
                if (trange_begin >= tmax_id) then
                    fend:=1;
else
                    if tsimulate = 1
                    then
                    twhere_clause := twhere_clause;
end if;
		--print 'Range ' + convert(varchar, @range_begin) + ' - ' + convert(varchar, @range_end)
                    if (trange_begin >= tmax_processed_id) or (tmax_processed_id is null)
                    then
                    twhere_clause :=cast((trange_begin) as varchar2) || ' < ' || tkey_column || ' and ' ||
							tkey_column || ' <= ' || cast((trange_end) as varchar2);
                    tresult_sql := pflb_datasan.pflb_combine_sql(tquery, twhere_clause);
                    if where_clause is not null and where_clause!='0' then
                    tresult_sql := pflb_datasan.pflb_combine_sql(tresult_sql, where_clause);
end if;
		--	DBMS_OUTPUT.put_line(tresult_sql);
        pflb_datasan.PFLB_WRITE_LOGS(tresult_sql);
                    jsql:='begin PFLB_DATASAN.PFLB_UPDATE_JOB('''||pflb_fix_upd(tresult_sql)||''','''||ownerName||''','''||tableName||''',0); end;';
insert into PFLB_ACTIVE_JOBS(upstring,priority)
values
    (tresult_sql,priory);
commit;
execute immediate jsql;
--         DBMS_OUTPUT.put_line('PFLB_UPD_PROC_INFO(tquery, trange_end)');
commit;
pflb_datasan.PFLB_UPD_PROC_INFO(tquery, trange_end);
                    trange_begin := trange_end;
                    pflb_datasan.PFLB_WRITE_LOGS(trange_begin||' 2 '||TableName);
begin
FETCH idcurs
    BULK COLLECT INTO idtable
      LIMIT trows_per_tran;
exception
 when others then
 close idcurs;
open idcurs FOR 'SELECT '||tkey_column||' FROM '|| ownerName ||'.'|| TableName|| ' where '||tkey_column||' > '||trange_begin||' order by '||tkey_column||' asc';
FETCH idcurs
    BULK COLLECT INTO idtable
      LIMIT trows_per_tran;
end;
select max(id) into trange_end from table(idtable);
trange_end:=trange_end;
      if trange_end is null then
      trange_end:=tmax_id;
end if;
else
begin
FETCH idcurs
    BULK COLLECT INTO idtable
      LIMIT trows_per_tran;
exception
 when others then
 close idcurs;
open idcurs FOR 'SELECT '||tkey_column||' FROM '|| ownerName ||'.'|| TableName|| ' where '||tkey_column||' > '||trange_begin||' order by '||tkey_column||' asc';
FETCH idcurs
    BULK COLLECT INTO idtable
      LIMIT trows_per_tran;
end;
end if;
end if;
end if;
end if;
end loop;
close idcurs;

--update pflb_active_channels set status='HOLD' where priority=priory;
commit;
end if;
end if;
exception
    when others then
update pflb_processed_tables set status='SKIPPED' where owner_name=ownerName and table_name=TableName;
pflb_datasan.PFLB_WRITE_LOGS('Error ' || SQLCODE || ': ' || SQLERRM);
commit;
end;
END;
PROCEDURE PFLB_GEN_AND_EXEC_UPD_DE(
    lickey varchar2,
    encodeFunctionName varchar2,
	encodeMethod varchar2,
	rows_per_update number,
    threads integer,
    mthreads integer,
    sim integer,
    priory integer,
    viewCont_ownerName varchar2,
    distTableName varchar2,
    where_clause varchar2
    )
as
ttab char(1) := chr(9);

insql varchar2(32767);
curRow number;
tSql varchar(32767);
trancount number:=0;
sdate timestamp;
tkey_column varchar2(255);
viewCont_tableName varchar2(255);
viewCont_columnName varchar2(255);
ctime varchar2(255);
pid number;
jerror number;
l_job number := null;
end_flag integer;
act_stat_flag integer;
tab_proc_flag integer;
table_proc_flag integer;
ind_count integer;
curt_count integer;
avind_c integer;
rowpupd integer:=0;
nrows integer;
api_flag integer:=0;
idcoltype varchar2(32);
ssid number;
begin
select sys_context('userenv','SID') into ssid from dual;
update pflb_active_channels set sid=ssid where priority=priory;
commit;
--1. table #viewContent contains table_name, column_name values for current data type
--2. table #indexes contains table_name, index_name that should be disabled before update executing adn enabled after that
select sysdate into sdate from dual;
If lickey='70FCD8-DA7721-A47226-9C2ED7'
then
pflb_datasan.PFLB_WRITE_LOGS('!@#$ Lic key is verificated '||distTableName);
--loop at distinct table names
insert into pflb_active_status (channel, status) values (priory,'!@#$Starting sched');
commit;
end_flag:=0;
act_stat_flag:=0;
tab_proc_flag:=0;
table_proc_flag:=0;
ind_count:=1;
curt_count:=0;
avind_c:=0;
jerror:=0;
idcoltype:='NUMBER';
update pflb_active_status set status='!@#$Updating '||viewCont_ownerName||'.'||distTableName where channel=priory;
commit;
select count(1) into table_proc_flag from pflb_processed_tables where owner_name=viewCont_ownerName and table_name=distTableName;
pflb_datasan.PFLB_WRITE_LOGS('!@#$ FLAG '||table_proc_flag||viewCont_ownerName||'.'||distTableName);
select count(1) into jerror from pflb_active_status where (channel=0 and status='!@#$Ending all processes') or (channel=priory and status like '!@#$Skipping%');
if jerror<1 then
if table_proc_flag=0 then
pflb_datasan.PFLB_WRITE_LOGS('!@#$ Start processing on '||viewCont_ownerName||'.'||distTableName);
pflb_datasan.PFLB_WRITE_LOGS('!@#$ Generating update string for '||distTableName);
	pflb_datasan.pflb_generate_update (
		insql,
        viewCont_ownerName,
		distTableName,
		encodeFunctionName,
		encodeMethod)
	;

begin
		--disable indexes
select to_char(current_timestamp,'YYYY/MM/DD HH24:MI:SS') into ctime from dual;
select pflb_proc_tab_id.NEXTVAL into pid from dual;
insert into pflb_processed_tables(id,owner_name,table_name,status,dep_time)
values (pid,viewCont_ownerName, distTableName, 'PROCESSING', ctime);
commit;
pflb_datasan.PFLB_WRITE_LOGS('!@#$ Disable indexes for '||distTableName);
        if sim = 0 then
select count(1) into api_flag from pflb_livestatus;
if api_flag>0 then
            pflb_datasan.PFLB_DISABLE_INDEXES_API();
else
            pflb_datasan.pflb_disable_indexes(viewCont_ownerName ,distTableName);
end if;
        pflb_datasan.PFLB_DISABLE_TRIGGERS(viewCont_ownerName ,distTableName);
end if;
        pflb_datasan.PFLB_WRITE_LOGS('!@#$ Starting to update '||distTableName);
        pflb_datasan.PFLB_GET_OR_CR_KEY_COL(viewCont_ownerName, distTableName, tkey_column, sim, idcoltype);
        if rowpupd<=0 then
        rowpupd:=rows_per_update;
end if;
        if idcoltype='VARCHAR2' then
        pflb_datasan.pflb_exec_by_ranges_c (viewCont_ownerName ,distTableName, where_clause, insql, rowpupd, threads, mthreads, priory, tkey_column, sim);
else
		pflb_datasan.pflb_exec_by_ranges (viewCont_ownerName ,distTableName, where_clause, insql, rowpupd, threads, mthreads, priory, tkey_column, sim);
end if;
        if sim = 0 then
		--pflb_datasan.pflb_enable_indexes();
select count(1) into jerror from pflb_active_status where (channel=0 and status='!@#$Ending all processes') or (channel=priory and status like '!@#$Skipping%');
if jerror<1 then
                pflb_datasan.PFLB_ENABLE_TRIGGERS(viewCont_ownerName ,distTableName);
update pflb_temp_table_indexes set table_status='PROCESSED' where owner_name=viewCont_ownerName and table_name=distTableName;
update pflb_processed_tables set status='PROCESSED', dep_time=ctime where id=pid;
commit;
else
update pflb_temp_table_indexes set table_status='SKIPPED' where owner_name=viewCont_ownerName and table_name=distTableName;
update pflb_processed_tables set status='SKIPPED' where id=pid;
commit;
end if;
end if;
exception
    when others then
    pflb_datasan.PFLB_WRITE_LOGS('Error ' || SQLCODE || ': ' || SQLERRM);
    pflb_datasan.PFLB_WRITE_LOGS('Processing table ' || viewCont_ownerName||'.'||distTableName || ' failed');
rollback;
update pflb_temp_table_indexes set table_status='SKIPPED' where owner_name=viewCont_ownerName and table_name=distTableName;
update pflb_processed_tables set status='SKIPPED' where id=pid;
update pflb_active_status set status='!@#$Skipping '||viewCont_ownerName||'.'||distTableName where channel=priory;
commit;
end;
commit;
select (to_char(extract( day from dtime )*24 + extract( hour from dtime )) ||':'|| to_char(extract( minute from dtime ))||':' || to_char(extract( second from dtime ))) into ctime from (select current_timestamp-(to_timestamp(ctime, 'YYYY/MM/DD HH24:MI:SS')) dtime from dual) t;
update pflb_processed_tables set dep_time=ctime where id=pid;
commit;
pflb_datasan.PFLB_WRITE_LOGS('!@#$ Processing on '||viewCont_ownerName||'.'||distTableName||' ended');
end if;
else
        pflb_datasan.PFLB_WRITE_LOGS('!@#$ Job error, process is stopped');
end if;
        PFLB_DATASAN.PFLB_SLEEP(7);
else
pflb_datasan.PFLB_WRITE_LOGS('!@#$ Lic key is not verificated '||distTableName);
end if;
delete from pflb_active_channels
where priority=priory;
delete from pflb_active_status
where channel=priory;
commit;
end;
PROCEDURE PFLB_GEN_AND_EXEC_UPD_AS(
    lickey varchar2,
    encodeFunctionName varchar2,
	encodeMethod varchar2,
	rows_per_update number,
    threads integer,
    mthreads integer,
    sim integer,
    priory integer,
    viewCont_ownerName varchar2,
    distTableName varchar2,
    where_clause varchar2
    )
as
ttab char(1) := chr(9);

insql varchar2(32767);
curRow number;
tSql varchar(32767);
trancount number:=0;
sdate timestamp;
tkey_column varchar2(255);
viewCont_tableName varchar2(255);
viewCont_columnName varchar2(255);
ctime varchar2(255);
pid number;
jerror number;
l_job number := null;
end_flag integer;
act_stat_flag integer;
table_proc_flag integer;
tab_proc_flag integer;
ind_count integer;
curt_count integer;
avind_c integer;
rowpupd integer:=0;
nrows integer;
api_flag integer:=0;
idcoltype varchar2(32);
thr_am integer:=threads;
statflag integer:=0;
cur_count integer:=priory-1;
ssid number;
begin
select sys_context('userenv','SID') into ssid from dual;
update pflb_active_channels set sid=ssid where priority=priory;
commit;
--1. table #viewContent contains table_name, column_name values for current data type
--2. table #indexes contains table_name, index_name that should be disabled before update executing adn enabled after that
--PFLB_DATASAN.PFLB_SLEEP(2);
select sysdate into sdate from dual;
If lickey='70FCD8-DA7721-A47226-9C2ED7'
then
pflb_datasan.PFLB_WRITE_LOGS('!@#$ Lic key is verificated '||distTableName);
--loop at distinct table names
pflb_datasan.PFLB_WRITE_LOGS('!@#$Init dicts for channel #'||priory);
PFLB_DATASAN.PFLB_DICT_FILL_ALL();
insert into pflb_active_status (channel, status) values (priory,'!@#$Starting sched');
commit;
cur_count:=0;
statflag:=0;
end_flag:=0;
act_stat_flag:=0;
tab_proc_flag:=0;
table_proc_flag:=0;
ind_count:=1;
curt_count:=0;
avind_c:=0;
idcoltype:='NUMBER';
update pflb_active_status set status='!@#$Updating '||viewCont_ownerName||'.'||distTableName where channel=priory;
commit;
select count(1) into table_proc_flag from pflb_processed_tables where owner_name=viewCont_ownerName and table_name=distTableName;
pflb_datasan.PFLB_WRITE_LOGS('!@#$ FLAG '||table_proc_flag||viewCont_ownerName||'.'||distTableName);
select count(1) into jerror from pflb_active_status where (channel=0 and status='!@#$Ending all processes') or (channel=priory and status like '!@#$Skipping%');
if jerror<1 then
if table_proc_flag=0 then

pflb_datasan.PFLB_WRITE_LOGS('!@#$ Start processing on '||viewCont_ownerName||'.'||distTableName);
pflb_datasan.PFLB_WRITE_LOGS('!@#$ Generating update string for '||distTableName);
	pflb_datasan.pflb_generate_update (
		insql,
        viewCont_ownerName,
		distTableName,
		encodeFunctionName,
		encodeMethod)
	;

begin
		--disable indexes
select to_char(current_timestamp,'YYYY/MM/DD HH24:MI:SS') into ctime from dual;
select pflb_proc_tab_id.NEXTVAL into pid from dual;
insert into pflb_processed_tables(id,owner_name,table_name,status,dep_time)
values (pid,viewCont_ownerName, distTableName, 'PROCESSING', ctime);
commit;
update pflb_active_channels set status='PREPROC_PROCEDURES' where priority=priory;
commit;
pflb_datasan.PFLB_WRITE_LOGS('!@#$ Disable indexes for '||distTableName);
        if sim = 0 then
select count(1) into api_flag from pflb_livestatus;
if api_flag>0 then
            pflb_datasan.PFLB_DISABLE_INDEXES_API();
else
            pflb_datasan.pflb_disable_indexes(viewCont_ownerName ,distTableName);
end if;
        pflb_datasan.PFLB_DISABLE_TRIGGERS(viewCont_ownerName ,distTableName);
end if;
        pflb_datasan.PFLB_GET_OR_CR_KEY_COL(viewCont_ownerName, distTableName, tkey_column, sim, idcoltype);
        if rowpupd<=0 then
        rowpupd:=rows_per_update;
end if;
select treads_amt into thr_am from pflb_active_channels where priority=priory;
if thr_am<=1 then
                        --update pflb_active_channels set status='CHANGE_THR_BEHAVE' where priority=priory;
                        --commit;
        if idcoltype='VARCHAR2' then
        pflb_datasan.PFLB_WRITE_LOGS('!@#$ Starting to sthr_c update '||distTableName);
        pflb_datasan.PFLB_EXEC_BY_RANG_STHR_C (viewCont_ownerName ,distTableName, where_clause, insql, rowpupd, threads, mthreads, priory, tkey_column, sim);
else
        pflb_datasan.PFLB_WRITE_LOGS('!@#$ Starting to sthr update '||distTableName);
		pflb_datasan.PFLB_EXEC_BY_RANG_STHR (viewCont_ownerName ,distTableName, where_clause, insql, rowpupd, threads, mthreads, priory, tkey_column, sim);
end if;
end if;

select treads_amt into thr_am from pflb_active_channels where priority=priory;
--CHANGE_THR_BEHAVE update pflb_active_channels set status='CHANGE_THR_BEHAVE' where priority=priory;

select count(1) into statflag from pflb_active_channels where (priority=priory and (status like '%CHANGE_THR_BEHAVE%' or status like '%PREPROC_PROCEDURES%'));
select count(1) into jerror from pflb_active_status where (channel=0 and status='!@#$Ending all processes') or (channel=priory and status like '!@#$Skipping%');
if thr_am>1 and statflag>0 and jerror<1 then
                    if idcoltype='VARCHAR2' then
                        pflb_datasan.PFLB_WRITE_LOGS('!@#$ Starting to multithr_c update '||distTableName);
                        pflb_datasan.pflb_exec_by_ranges_c (viewCont_ownerName ,distTableName, where_clause, insql, rowpupd, thr_am, mthreads, priory, tkey_column, sim);
else
                        pflb_datasan.PFLB_WRITE_LOGS('!@#$ Starting to multithr update '||distTableName);
                        pflb_datasan.pflb_exec_by_ranges (viewCont_ownerName ,distTableName, where_clause, insql, rowpupd, thr_am, mthreads, priory, tkey_column, sim);
end if;
end if;

        if sim = 0 then
		--pflb_datasan.pflb_enable_indexes();
select count(1) into jerror from pflb_active_status where (channel=0 and status='!@#$Ending all processes') or (channel=priory and status like '!@#$Skipping%');
if jerror<1 then
                pflb_datasan.PFLB_ENABLE_TRIGGERS(viewCont_ownerName ,distTableName);
update pflb_temp_table_indexes set table_status='PROCESSED' where owner_name=viewCont_ownerName and table_name=distTableName;
update pflb_processed_tables set status='PROCESSED' where id=pid;
commit;
else
update pflb_temp_table_indexes set table_status='SKIPPED' where owner_name=viewCont_ownerName and table_name=distTableName;
update pflb_processed_tables set status='SKIPPED' where id=pid;
commit;
end if;
end if;
exception
    when others then
    pflb_datasan.PFLB_WRITE_LOGS('Error ' || SQLCODE || ': ' || SQLERRM);
    pflb_datasan.PFLB_WRITE_LOGS('Processing table ' || viewCont_ownerName||'.'||distTableName || ' failed');
rollback;
update pflb_temp_table_indexes set table_status='SKIPPED' where owner_name=viewCont_ownerName and table_name=distTableName;
update pflb_processed_tables set status='SKIPPED' where id=pid;
update pflb_active_status set status='!@#$Skipping '||viewCont_ownerName||'.'||distTableName where channel=priory;
commit;
end;
commit;
select (to_char(extract( day from dtime )*24 + extract( hour from dtime )) ||':'|| to_char(extract( minute from dtime ))||':' || to_char(extract( second from dtime ))) into ctime from (select current_timestamp-(to_timestamp(ctime, 'YYYY/MM/DD HH24:MI:SS')) dtime from dual) t;
update pflb_processed_tables set dep_time=ctime where id=pid;
commit;
pflb_datasan.PFLB_WRITE_LOGS('!@#$ Processing on '||viewCont_ownerName||'.'||distTableName||' ended');
end if;
else
        pflb_datasan.PFLB_WRITE_LOGS('!@#$ Job error, process is stopped');
end if;
PFLB_DATASAN.PFLB_SLEEP(7);
else
pflb_datasan.PFLB_WRITE_LOGS('!@#$ Lic key is not verificated '||distTableName);
end if;
delete from pflb_active_channels
where priority=priory;
delete from pflb_active_status
where channel=priory;
commit;
end;
PROCEDURE PFLB_PROCESS_DATA_TYPE(
    lickey varchar2,
    encodeMethod varchar2,
    threads integer,
	rows_per_update number,
    sim integer,
    thread_per_dechannel number,
    de_channel number,
    as_channel number
    )
AS
    ttab char(1) := chr(9);
	encodeFunctionName varchar2(100) := 'PFLB_ENCODE';
	tableType varchar2(255);
	viewName varchar2(255);
    end_table_loop_flag integer:=0;
	tempSql varchar2(32767);
    tSql varchar2(32767);
    tempc number :=0;
    end_flag integer := 0;
    ch_count integer := 0;
    l_job number := null;
    tr1 number :=ceil(threads/4);
    tr2 number :=ceil(threads/8*3);
    tr3 number :=ceil(threads-tr1-tr2);
    c_priory integer:=1;
    current_threads integer:=0;
    delta_threads integer:=0;
    viewCont_ownerName_de varchar2(255);
    distTableName_de varchar2(255);
    where_clause_de varchar2(255);
    nrows_de integer;
    rowpupd_de integer;
    viewCont_ownerName_as varchar2(255);
    distTableName_as varchar2(255);
    where_clause_as varchar2(255);
    nrows_as integer;
    rowpupd_as integer;
    ascount integer;
    decount integer;
    chs_count integer;

cursor cur_distictTableName_as is
select distinct owner_name, p.table_name, nvl(where_clause,0), a.num_rows, nvl(p.update_rows,rows_per_update) from pflb_viewContent p
                                                                                                                       join all_tables a on a.owner=p.owner_name and a.table_name=p.table_name
order by num_rows asc,owner_name,p.table_name asc;
cursor cur_distictTableName_de is
select distinct owner_name, pflb_viewContent.table_name, nvl(where_clause,0), a.num_rows, nvl(pflb_viewContent.update_rows,rows_per_update) from pflb_viewContent
                                                                                                                                                     join all_tables a on a.owner=pflb_viewContent.owner_name and a.table_name=pflb_viewContent.table_name
order by num_rows desc,owner_name,pflb_viewContent.table_name desc;

begin
pflb_datasan.PFLB_WRITE_LOGS('!@#$ enter to generate_update');
update pflb_livestatus set status = 'ACTIVE';
commit;
--needed to enable and disable indexes
select count(1) into tempc from user_objects where object_name='PFLB_TEMP_TABLE_INDEXES' and object_type='TABLE' and rownum=1;
/*IF tempc <>0 then
    EXECUTE IMMEDIATE 'TRUNCATE TABLE PFLB_TEMP_TABLE_INDEXES';
    end if;
    */
EXECUTE IMMEDIATE 'TRUNCATE TABLE PFLB_PROCESSED_TABLES';
tempc:=0;
open cur_distictTableName_de;
open cur_distictTableName_as;
tsql:='begin PFLB_DATASAN.PFLB_INDEX_SCHED('||tr1||'); end;';
    pflb_datasan.PFLB_WRITE_LOGS(tsql);
    sys.dbms_job.submit( l_job, tsql,sysdate,null );
commit;
while end_table_loop_flag<=0
        loop
select count(1) into ascount from pflb_active_channels where treads_amt=1;
select count(1) into decount from pflb_active_channels where treads_amt=thread_per_dechannel;
select count(1) into chs_count from pflb_active_status where (channel=0 and status='!@#$Ending all processes');
if ch_count<=0 then
            if decount<de_channel then
            fetch cur_distictTableName_de
	into viewCont_ownerName_de ,distTableName_de, where_clause_de,nrows_de,rowpupd_de;
    if (viewCont_ownerName_de=viewCont_ownerName_as and distTableName_de=distTableName_as) or end_table_loop_flag=1 then
        end_table_loop_flag:=1;
else
select nvl(min(priority),1)+1 into c_priory from (select priority,abs(priority - nvl(lead(priority,1) over (order by priority),0)) prdelta from pflb_active_channels order by priority) where prdelta>1;
insert into PFLB_ACTIVE_CHANNELS(CHANNEL_NAME,PRIORITY,TREADS_AMT)
values
    ('Update_sch_de',c_priory,thread_per_dechannel);
commit;
tsql:='begin pflb_datasan.PFLB_GEN_AND_EXEC_UPD_DE('''||lickey||''', '''||encodeFunctionName||''', '''||encodeMethod||''', '||rowpupd_de||', '||thread_per_dechannel||', '||threads||', '||sim||', '||c_priory||', '''||viewCont_ownerName_de||''', '''||distTableName_de||''', '''||where_clause_de||''');end; ';
    pflb_datasan.PFLB_WRITE_LOGS(tsql);
   sys.dbms_job.submit( l_job, tsql,sysdate,null );
commit;
end if;
end if;

            if ascount<as_channel then
            fetch cur_distictTableName_as
	into viewCont_ownerName_as ,distTableName_as, where_clause_as,nrows_as,rowpupd_as
;
            if (viewCont_ownerName_de=viewCont_ownerName_as and distTableName_de=distTableName_as) or end_table_loop_flag=1 then
                end_table_loop_flag:=1;
else
select nvl(min(priority),1)+1 into c_priory from (select priority,abs(priority - nvl(lead(priority,1) over (order by priority),0)) prdelta from pflb_active_channels order by priority) where prdelta>1;
insert into PFLB_ACTIVE_CHANNELS(CHANNEL_NAME,PRIORITY,TREADS_AMT)
values
    ('Update_sch_as',c_priory,1);
commit;
tsql:='begin pflb_datasan.PFLB_GEN_AND_EXEC_UPD_AS('''||lickey||''', '''||encodeFunctionName||''', '''||encodeMethod||''', '||rowpupd_as||', '||as_channel||', '||threads||', '||sim||', '||c_priory||', '''||viewCont_ownerName_as||''', '''||distTableName_as||''', '''||where_clause_as||''');end;';
            pflb_datasan.PFLB_WRITE_LOGS(tsql);
            sys.dbms_job.submit( l_job, tsql,sysdate,null );
commit;
end if;
end if;
            if ascount>=as_channel and decount>=de_channel then
                PFLB_DATASAN.PFLB_SLEEP(5);
end if;
else
            end_table_loop_flag:=1;
end if;

end loop;

    while end_flag=0
    loop
select count(1) into ch_count from pflb_active_channels;
if ch_count=0 then
    end_flag:=1;
end if;
select count(1) into ch_count from pflb_active_status where (channel=0 and status='!@#$Ending all processes');
if ch_count>0 then
    end_flag:=1;
else
select nvl(sum(treads_amt),0) into current_threads from pflb_active_channels where priority!=1;
if current_threads<tr3 then
select sum(treads_amt) into current_threads from pflb_active_channels where priority=nvl((select max(priority) from pflb_active_channels where priority!=1),-1);
if current_threads is not null then
select sum(nvl(treads_amt,0)) into delta_threads from pflb_active_channels where priority!=1;
delta_threads:=tr3-delta_threads;
                current_threads:=current_threads+delta_threads;
select nvl(max(priority),-1) into c_priory from pflb_active_channels where priority!=1;
update pflb_active_channels set treads_amt=current_threads where priority=c_priory;
commit;
pflb_datasan.PFLB_WRITE_LOGS('!@#$ Setting threads_amt = '||current_threads||' for priority = '||c_priory);
end if;
end if;
end if;
    PFLB_DATASAN.PFLB_SLEEP(10);
end loop;
    if end_flag=0 then
    pflb_datasan.pflb_drop_all_col_idx(lickey);
end if;
update pflb_livestatus set status = 'FINISHED';
commit;
pflb_datasan.PFLB_WRITE_LOGS('!@#$ exit from generate_update');
end;
procedure PFLB_WRITE_LOGS
(
logstring varchar2
)
as
maxid integer;
ssid integer;
begin
select sys_context('userenv','SID') into ssid from dual;
select max(id) into maxid from pflb_logs;
if maxid is null then
maxid:=1;
end if;
insert into pflb_logs(id,lstr, ldate,sid)
values
    (maxid+1, substr(logstring,0,3997), sysdate, ssid);
commit;
end;
PROCEDURE PFLB_DROP_ALL_COL_IDX(
    lickey varchar2
    )
as
ttab char(1) := chr(9);

insql varchar2(32767);
distTableName varchar2(255);
tSql varchar(32767);
sdate timestamp;
viewCont_tableName varchar2(255);
viewCont_ownerName varchar2(255);
viewCont_columnName varchar2(255);
cursor cur_distictTableName is
select distinct owner_name, table_name from pflb_viewContent t where owner_name||table_name not in (select owner_name||table_name from pflb_processed_tables where status='SKIPPED');
begin
pflb_datasan.PFLB_WRITE_LOGS('!@#$ Start dropping all temp columns');
--1. table #viewContent contains table_name, column_name values for current data type
--2. table #indexes contains table_name, index_name that should be disabled before update executing adn enabled after that
select sysdate into sdate from dual;

--loop at distinct table names
open cur_distictTableName;
fetch cur_distictTableName
    into viewCont_ownerName ,distTableName
;

loop
pflb_datasan.PFLB_WRITE_LOGS('!@#$ Start processing on '||distTableName);
PFLB_DROP_COL_IDX(
    viewCont_ownerName,
	distTableName)
	;
fetch cur_distictTableName
    into viewCont_ownerName ,distTableName
;
exit when cur_distictTableName%NOTFOUND;
end loop;--end loop for distinct table name
close cur_distictTableName;
pflb_datasan.PFLB_WRITE_LOGS('!@#$ All temp columns dropped');
end;
PROCEDURE PFLB_ENABLE_TRIGGERS
(towner varchar2, ttablename varchar2)
AS
tSql varchar2(32767);
triggerName varchar2(255);
trigowner varchar2(255);
cursor cur_triggers is
select towner, trigger_name from pflb_table_triggers where tableowner=towner and table_name=ttablename;
begin
open cur_triggers;
fetch cur_triggers
    into trigowner,triggerName
;
if triggerName is not null then
    loop
        tSql := 'alter trigger ' ||trigowner||'.'||triggerName|| ' ENABLE';
    --    DBMS_OUTPUT.put_line(tSql);
        pflb_datasan.pflb_write_logs(tsql);
EXECUTE IMMEDIATE tSql;
delete from pflb_table_triggers where towner=trigowner and trigger_name=triggername and table_name=ttablename and tableowner=towner;
commit;
fetch cur_triggers
    into trigowner,triggerName
;
exit when cur_triggers%NOTFOUND;
end loop;
end if;
close cur_triggers;
end;
PROCEDURE PFLB_DISABLE_TRIGGERS
(towner varchar2, ttablename varchar2)
AS
tSql varchar2(32767);
triggerName varchar2(255);
trigowner varchar2(255);
cursor cur_triggers is
select owner, trigger_name from all_triggers where table_owner=towner and table_name=ttablename and status = 'ENABLED';
begin
open cur_triggers;
fetch cur_triggers
    into trigowner,triggerName
;
if triggerName is not null then
    loop
        tSql := 'alter trigger ' ||trigowner||'.'||triggerName|| ' DISABLE';
    --    DBMS_OUTPUT.put_line(tSql);
        pflb_datasan.pflb_write_logs(tsql);
EXECUTE IMMEDIATE tSql;
insert into pflb_table_triggers (towner, trigger_name, table_name, tableowner) values (trigowner, triggerName, ttablename, towner);
commit;
fetch cur_triggers
    into trigowner,triggerName
;
exit when cur_triggers%NOTFOUND;
end loop;
end if;
close cur_triggers;
end;
function PFLB_FIX_UPD(upstr varchar2)
return varchar2
as
str varchar2(4000):=upstr;
flag integer:=0;
tinst integer:=1;
lastinstr integer:=1;
begin
    while flag=0
    loop
    tinst:=lastinstr;
    lastinstr:=instr(str,'''',lastinstr+1);
    --pflb_datasan.pflb_write_logs(str);
    if lastinstr is not null and lastinstr!=0 then
    str:=substr(str,1,lastinstr)||''''||substr(str,lastinstr+1);
    lastinstr:=lastinstr+1;
    tinst:=lastinstr;
else
    flag:=1;
end if;
end loop;
return str;
end;

PROCEDURE PFLB_ENABLE_INDEX_JOB(
index_ownerName varchar2,
index_tableName varchar2,
index_indexName varchar2,
threads integer
)

AS
tSql varchar2(32767);
threads_base integer;
log_flag varchar2(20);
begin
begin
insert into PFLB_ACTIVE_CHANNELS(CHANNEL_NAME,PRIORITY,TREADS_AMT)
values
    ('Rebuild_index_'||index_ownername||'.'||index_tablename||'.'||index_indexName,(select max(priority)+1 from pflb_active_channels),threads);
commit;
select logging, degree into log_flag, threads_base from all_indexes where table_owner=index_ownerName and index_name=index_indexName;
PFLB_DATASAN.PFLB_WRITE_LOGS('Rebuilding index '||index_indexName||' on table: ' ||index_ownerName||'.'||index_tableName);
        tSql := 'alter index ' ||index_ownerName||'.'|| index_indexName || ' rebuild ONLINE'||' parallel '||threads||' nologging';
    --    DBMS_OUTPUT.put_line(tSql);
EXECUTE IMMEDIATE tSql;
PFLB_DATASAN.PFLB_WRITE_LOGS('Index '||index_indexName||' rebuilded on table: ' ||index_ownerName||'.'||index_tableName);
         PFLB_DATASAN.PFLB_WRITE_LOGS('Trying to restore settings of index '||index_indexName||' on table: ' ||index_ownerName||'.'||index_tableName);
        if log_flag='YES' then
        tSql := 'alter index ' ||index_ownerName||'.'|| index_indexName || ' parallel '||threads_base||' logging';
    --    DBMS_OUTPUT.put_line(tSql);
EXECUTE IMMEDIATE tSql;
else
        tSql := 'alter index ' ||index_ownerName||'.'|| index_indexName || ' parallel '||threads_base||' nologging';
    --    DBMS_OUTPUT.put_line(tSql);
EXECUTE IMMEDIATE tSql;
end if;
        PFLB_DATASAN.PFLB_WRITE_LOGS('Settings for index '||index_indexName||' restored on table: ' ||index_ownerName||'.'||index_tableName);
        PFLB_DATASAN.PFLB_WRITE_LOGS('Trying to delete from temp_table_indexes '||index_indexName||' on table: ' ||index_ownerName||'.'||index_tableName);
        tsql:='delete from pflb_temp_table_indexes where owner_name='''||index_ownerName||''' and table_name='''||index_tableName||''' and index_name='''||index_indexName||'''';
    --    DBMS_OUTPUT.put_line(tSql);
EXECUTE IMMEDIATE tSql;
commit;
PFLB_DATASAN.PFLB_WRITE_LOGS('All jobs for index '||index_indexName||' are complited on table: ' ||index_ownerName||'.'||index_tableName);
delete from PFLB_ACTIVE_CHANNELS
where CHANNEL_NAME=('Rebuild_index_'||index_ownername||'.'||index_tablename||'.'||index_indexName);
commit;
exception
    when others then
    pflb_datasan.PFLB_WRITE_LOGS(tsql||' ;; '||'Error ' || SQLCODE || ': ' || SQLERRM);
update pflb_temp_table_indexes set table_status='SKIPPED' where owner_name=index_ownerName and table_name=index_tableName and index_name=index_indexName;
commit;
delete from PFLB_ACTIVE_CHANNELS
where CHANNEL_NAME=('Rebuild_index_'||index_ownername||'.'||index_tablename||'.'||index_indexName);
commit;
end;
end;

PROCEDURE PFLB_INDEX_SCHED(
threads_am number
)
AS
tSql varchar2(32767);
index_ownerName varchar2(255);
index_tableName varchar2(255);
index_indexName varchar2(255);
end_flag integer;
act_stat_flag integer;
tab_proc_flag integer;
ind_count integer;
curt_count integer;
l_job number := null;
avind_c integer;
begin
end_flag:=0;
act_stat_flag:=0;
tab_proc_flag:=0;
ind_count:=1;
curt_count:=0;
avind_c:=0;
PFLB_DATASAN.PFLB_WRITE_LOGS('Loading index scheduler');
    loop
select nvl(sum(threads),0) into curt_count from pflb_temp_table_indexes;
if curt_count<threads_am then
select count(*) into avind_c from pflb_temp_table_indexes where table_status='PROCESSED' and (nvl(index_status,0)!='PROCESSING' and nvl(index_status,0)!='SKIPPED');
if avind_c>0 then
select nvl(owner_name,0),nvl(table_name,0),nvl(index_name,0) into index_ownerName,index_tableName,index_indexName from pflb_temp_table_indexes where table_status='PROCESSED' and nvl(index_status,0)!='PROCESSING' and nvl(index_status,0)!='SKIPPED' and rownum=1;
if index_indexName !='0' then
                    tsql:='begin PFLB_DATASAN.PFLB_ENABLE_INDEX_JOB('||''''||index_ownerName||''','''||index_tableName||''','''||index_indexName||''',4); end;';
update pflb_temp_table_indexes set index_status='PROCESSING', threads=4 where owner_name=index_ownerName and table_name=index_tableName and index_name=index_indexName;
commit;
sys.dbms_job.submit( l_job, tsql,sysdate,null );
commit;
else
                    PFLB_DATASAN.PFLB_SLEEP(1);
end if;
end if;
end if;
select count(1) into tab_proc_flag from pflb_temp_table_indexes where table_status='PROCESSED';
if tab_proc_flag<=0 then
select count(1) into tab_proc_flag from pflb_active_channels;
if tab_proc_flag<=0 then
                end_flag:=1;
end if;
end if;
select count(1) into act_stat_flag from pflb_active_status where (channel=0 and status='!@#$Ending all processes');
if act_stat_flag>0 then
            end_flag:=1;
end if;
        if end_flag=1 then
            PFLB_DATASAN.PFLB_WRITE_LOGS('Unloading index scheduler');
            exit;
end if;
        PFLB_DATASAN.PFLB_SLEEP(3);
end loop;
end;
PROCEDURE PFLB_DICT_FILL(OWNER_N VARCHAR2, TABLE_N VARCHAR2)
AS	VAL CLOB;
DICT_SHUFFLE_METHOD_C VARCHAR2(255);
TSQL VARCHAR2(255);
SKEY VARCHAR2(255):='abc';
SPERC INTEGER:=10;
isLegacy integer;
id_dict integer;
logstr VARCHAR2(4000);
CURSOR CURS_DICTFILL IS
SELECT DISTINCT D.DICT_SHUFFLE_METHOD,D.ID_DICT FROM PFLB_VIEWCONTENT V
                                                         JOIN PFLB_DICT_TYPES D ON D.COLUMN_ENCODE_TYPE=V.COLUMN_ENCODE_TYPE AND V.ENCODE_METHOD=D.ENCODE_METHOD
                                                         JOIN PFLB_DICT T ON D.ID_DICT=T.ID
WHERE V.OWNER_NAME=OWNER_N AND V.TABLE_NAME=TABLE_N;
BEGIN
OPEN CURS_DICTFILL;
FETCH CURS_DICTFILL
    INTO DICT_SHUFFLE_METHOD_C, id_dict
;
LOOP
EXIT WHEN CURS_DICTFILL%NOTFOUND;
select count(1) into isLegacy from pflb_dict_legacy where function_name=DICT_SHUFFLE_METHOD_C;
SELECT VALUE INTO VAL FROM PFLB_DICT where id=id_dict FETCH NEXT 1 ROWS ONLY;
if isLegacy>0 then
        TSQL:='begin '||DICT_SHUFFLE_METHOD_C||'( :val , :skey ); end;';
EXECUTE IMMEDIATE TSQL USING VAL,SKEY;
else
        TSQL:='declare logstr VARCHAR2(4000); begin select '||DICT_SHUFFLE_METHOD_C||'( :idd ,'||'''dict_'||id_dict||''''||', :val ) into logstr from dual; end;';
EXECUTE IMMEDIATE TSQL USING id_dict,val;
end if;
    --PFLB_DATASAN.PFLB_WRITE_LOGS(TSQL);
    if isLegacy<1 then
        TSQL:='declare logstr VARCHAR2(4000); begin select pflb_generate_dictionary_pairs( '||id_dict||', :skey ) into logstr from dual; end;';
EXECUTE IMMEDIATE TSQL USING SKEY;
end if;
FETCH CURS_DICTFILL
    INTO DICT_SHUFFLE_METHOD_C, id_dict
;
END LOOP;
END;

PROCEDURE PFLB_DICT_FILL_ALL
AS	VAL CLOB;
DICT_SHUFFLE_METHOD_C VARCHAR2(255);
TSQL VARCHAR2(255);
SKEY VARCHAR2(255):='abc';
SPERC INTEGER:=10;
id_dict integer;
isLegacy integer;
logstr VARCHAR2(4000);
CURSOR CURS_DICTFILL IS
SELECT DISTINCT D.DICT_SHUFFLE_METHOD,D.ID_DICT FROM PFLB_VIEWCONTENT V
                                                         JOIN PFLB_DICT_TYPES D ON D.COLUMN_ENCODE_TYPE=V.COLUMN_ENCODE_TYPE AND V.ENCODE_METHOD=D.ENCODE_METHOD
                                                         JOIN PFLB_DICT T ON D.ID_DICT=T.ID;
BEGIN
OPEN CURS_DICTFILL;
FETCH CURS_DICTFILL
    INTO DICT_SHUFFLE_METHOD_C, id_dict
;
LOOP
EXIT WHEN CURS_DICTFILL%NOTFOUND;
SELECT VALUE INTO VAL FROM PFLB_DICT where id=id_dict FETCH NEXT 1 ROWS ONLY;
select count(1) into isLegacy from pflb_dict_legacy where function_name=DICT_SHUFFLE_METHOD_C;
if isLegacy>0 then
        TSQL:='begin '||DICT_SHUFFLE_METHOD_C||'( :val , :skey ); end;';
EXECUTE IMMEDIATE TSQL USING VAL,SKEY;
else
        TSQL:='declare logstr VARCHAR2(4000); begin select '||DICT_SHUFFLE_METHOD_C||'( :idd ,'||'''dict_'||id_dict||''''||', :val ) into logstr from dual; end;';
EXECUTE IMMEDIATE TSQL USING id_dict,val;
end if;
    --PFLB_DATASAN.PFLB_WRITE_LOGS(TSQL);
    if isLegacy<1 then
        TSQL:='declare logstr VARCHAR2(4000); begin select pflb_generate_dictionary_pairs( '||id_dict||', :skey ) into logstr from dual; end;';
EXECUTE IMMEDIATE TSQL USING SKEY;
end if;
FETCH CURS_DICTFILL
    INTO DICT_SHUFFLE_METHOD_C, id_dict
;
END LOOP;
END;

PROCEDURE PFLB_UPD_ERR_HAND(
upstr varchar2,owner_n varchar2, table_n varchar2, SQL_ERR integer, ssid integer)
as
tt varchar2(255);
flag number;
ERRTIER integer;
DESCR varchar2(4000);
checkdef integer;
chn integer;
checks varchar2(4000);
ccount number;
begin
select count(*) into checkdef from pflb_up_err_tab where ERR_CODE=SQL_ERR;
if checkdef<1 then
select count(*) into checkdef from pflb_up_err_tab where ERR_CODE=0;
if checkdef>0 then
select ERR_TIER,DESCRIPTION into ERRTIER,DESCR from pflb_up_err_tab where ERR_CODE=0 fetch next 1 row only;
else
errtier:=4;
DESCR:='!@#$Default error tier undifined, used tier 4 instead(CHECK TABLE PFLB_UPD_ERR_HAND FOR ERR_CODE=0)';
end if;
else
select ERR_TIER,DESCRIPTION into ERRTIER,DESCR from pflb_up_err_tab where ERR_CODE=SQL_ERR fetch next 1 row only;
end if;
pflb_datasan.PFLB_WRITE_LOGS('Error ' || SQL_ERR || ': ' || DESCR);
if ERRTIER=1 then
        insert into pflb_upd_errors (owner,table_name, updstr,ERR_CODE) values (owner_n,table_n,upstr,SQL_ERR);
delete from PFLB_ACTIVE_JOBS
where upstring=upstr;
commit;
elsif ERRTIER=2  then
        insert into pflb_upd_errors (owner,table_name, updstr,ERR_CODE) values (owner_n,table_n,upstr,SQL_ERR);
select
    blocking_session into checks
from
    v$session
where
    SID=ssid
order by
    blocking_session;
if checks is null then checks:='1';
else
select count(1) into ccount from pflb_active_jobs where sid=to_number(checks);
if ccount>0 then
select upstring into checks from pflb_active_jobs where sid=to_number(checks);
else checks:='1';
end if;
end if;
insert into pflb_even_tables values ((select max(id) from pflb_even_tables)+1000000, upstr, checks, '1');
delete from PFLB_ACTIVE_JOBS
where upstring=upstr;
commit;
elsif ERRTIER=3  then
select priority into chn from pflb_active_jobs where upstring=upstr;
insert into pflb_upd_errors (owner,table_name, updstr,ERR_CODE) values (owner_n,table_n,upstr,SQL_ERR);
update pflb_active_status set status='!@#$Skipping '||owner_n||'.'||table_n where channel=chn;
insert into pflb_even_tables values ((select max(id) from pflb_even_tables)+1000000, upstr, '1', '1');
delete from PFLB_ACTIVE_JOBS
where upstring=upstr;
update pflb_processed_tables set status='SKIPPED' where owner_name=owner_n and table_name=table_n;
commit;
elsif ERRTIER=4  then
select priority into chn from pflb_active_jobs where upstring=upstr;
insert into pflb_upd_errors (owner,table_name, updstr,ERR_CODE) values (owner_n,table_n,upstr,SQL_ERR);
update pflb_active_status set status='!@#$Skipping '||owner_n||'.'||table_n where channel=chn;
delete from PFLB_ACTIVE_JOBS
where upstring=upstr;
update pflb_processed_tables set status='SKIPPED' where owner_name=owner_n and table_name=table_n;
commit;
elsif ERRTIER=5  then
        insert into pflb_upd_errors (owner,table_name, updstr,ERR_CODE) values (owner_n,table_n,upstr,SQL_ERR);
insert into pflb_active_status (channel, status) values (0,'!@#$Ending all processes');
insert into pflb_even_tables values ((select max(id) from pflb_even_tables)+1000000, upstr, '1', '1');
delete from PFLB_ACTIVE_JOBS
where upstring=upstr;
update pflb_processed_tables set status='SKIPPED' where owner_name=owner_n and table_name=table_n;
commit;
elsif ERRTIER=6  then
        insert into pflb_upd_errors (owner,table_name, updstr,ERR_CODE) values (owner_n,table_n,upstr,SQL_ERR);
insert into pflb_active_status (channel, status) values (0,'!@#$Ending all processes');
delete from PFLB_ACTIVE_JOBS
where upstring=upstr;
update pflb_processed_tables set status='SKIPPED' where owner_name=owner_n and table_name=table_n;
commit;
end if;


end;
PROCEDURE PFLB_CHECK_DEP_ST
as
flag number;
tcount number;
vcount number;
begin
flag:=0;
tcount:=0;
vcount:=0;
begin
select count(1) into flag from pflb_active_jobs;
if flag>0 then
RAISE_APPLICATION_ERROR(-20010, '!@#$Datasan.Error#20010: PFLB_ACTIVE_JOBS is not empty');
end if;

select count(1) into flag from pflb_even_tables;
if flag>0 then
RAISE_APPLICATION_ERROR(-20011, '!@#$Datasan.Error#20011: PFLB_EVEN_TABLES is not empty');
end if;

select count(1) into flag from (
                                   select e.err_code, err_tier from pflb_upd_errors e
                                                                        join pflb_up_err_tab t on e.err_code=t.err_code
                                   union
                                   select err_code,(select err_tier from pflb_up_err_tab where err_code=0) err_tier from pflb_upd_errors where err_code not in (select err_code from pflb_up_err_tab)
                               )
where err_tier>=3;
if flag>0 then
RAISE_APPLICATION_ERROR(-20012, '!@#$Datasan.Error#20012: Errors were occured during depersonalization. Check PFLB_UPD_ERRORS');
end if;

select count(1) into tcount from(
                                    select distinct v.owner_name,p.table_name,status from pflb_viewcontent v
                                                                                              join
                                                                                          pflb_processed_tables p on v.owner_name=p.owner_name and v.table_name=p.table_name
                                    where status='PROCESSED'
                                );

select count(1) into vcount from (select distinct owner_name, table_name from pflb_viewcontent);

if vcount-tcount>0 then
RAISE_APPLICATION_ERROR(-20013, '!@#$Datasan.Error#20013: Not all tables from profile are processed, Check pflb_processed_tables');
end if;





exception
 when others then
             pflb_datasan.PFLB_WRITE_LOGS('Error ' || SQLCODE || ': ' || SQLERRM);
					raise;
end;
end;
function PFLB_GET_BD_VER
return integer
as
bd_ver integer;
begin
select substr(banner,17,2) into bd_ver from v$version where rownum=1;
return bd_ver;
end;
function PFLB_GET_DS_VER
return varchar2
as
DS_VER varchar2(255);
begin
select 'Datasan core 1.0.54.0.01 ver.' into DS_VER from dual;
return DS_VER;
end;

PROCEDURE PFLB_SLEEP(secs number)
as
vers number;
tsql varchar2(1000);
begin
vers:=0;

vers:=pflb_datasan.pflb_get_bd_ver;
if vers<19 then
tsql:='call dbms_lock.sleep(';
else
tsql:='call dbms_session.sleep(';
end if;
tsql:=tsql||':val)';
--pflb_datasan.pflb_write_logs(tsql);
execute immediate tsql using secs;

end;


end PFLB_DATASAN;