create or replace function pflb_encode_hash_char(st varchar2) return varchar2 as
language java name
'OraSQL.EncodeHashChar(java.lang.String) return java.lang.String';
/ --HARDCODE FOR DEPLOYMENT
create or replace function pflb_encode_hash_cardnumber(st varchar2) return varchar2 as
language java name
'OraSQL.EncodeHashChar(java.lang.String) return java.lang.String';
/ --HARDCODE FOR DEPLOYMENT
create or replace function pflb_encode_hash_ip(st varchar2) return varchar2 as
language java name
'OraSQL.EncodeHashChar(java.lang.String) return java.lang.String';
/ --HARDCODE FOR DEPLOYMENT
create or replace function  pflb_encode_hash_ogrn(st varchar2) return varchar2 as
language java name
'OraSQL.EncodeHashCharOgrn(java.lang.String) return java.lang.String';
/ --HARDCODE FOR DEPLOYMENT
create or replace function pflb_encode_hash_innumber(st varchar2) return varchar2 as
language java name
'OraSQL.EncodeHashCharInn(java.lang.String) return java.lang.String';
/ --HARDCODE FOR DEPLOYMENT
create or replace function pflb_encode_hash_binary(st BINARY_INTEGER) return BINARY_INTEGER as
language java name
'OraSQL.EncodeHashBinary(java.lang.Byte[]) return java.lang.Byte[]';
/ --HARDCODE FOR DEPLOYMENT
create or replace function pflb_encode_hash_date(st date) return date as
language java name 
'OraSQL.EncodeHashDate(java.sql.Timestamp) return java.sql.Timestamp';
/ --HARDCODE FOR DEPLOYMENT

create or replace function pflb_encode_hash_bdate(st date) return date as
language java name 
'OraSQL.EncodeHashBDate(java.sql.Timestamp) return java.sql.Timestamp';
/ --HARDCODE FOR DEPLOYMENT
create or replace function pflb_encode_hash_cdate(st date) return date as
language java name 
'OraSQL.EncodeHashCDate(java.sql.Timestamp) return java.sql.Timestamp';
/ --HARDCODE FOR DEPLOYMENT
create or replace function pflb_encode_hash_chardel(st varchar2) return varchar2 as
language java name
'OraSQL.EncodeHashCharDel(java.lang.String) return java.lang.String';
/ --HARDCODE FOR DEPLOYMENT
create or replace function pflb_encode_hash_ppchar(st varchar2) return varchar2 as
language java name
'OraSQL.EncodeHashCharPassport(java.lang.String) return java.lang.String';
/ --HARDCODE FOR DEPLOYMENT
create or replace function pflb_encode_hash_snilsnumber(st varchar2) return varchar2 as
language java name
'OraSQL.EncodeHashCharSnils(java.lang.String) return java.lang.String';
/ --HARDCODE FOR DEPLOYMENT
create or replace function pflb_encode_hash_nchar(st varchar2) return varchar2 as
language java name
'OraSQL.EncodeHashCharFirm(java.lang.String) return java.lang.String';
/ --HARDCODE FOR DEPLOYMENT
create or replace function pflb_encode_hash_PHONENUMBER(st varchar2) return varchar2 as
language java name
'OraSQL.EncodeHashCharPhone(java.lang.String) return java.lang.String';
/ --HARDCODE FOR DEPLOYMENT
create or replace FUNCTION pflb_encode_dict_famgetwithlen(st VARCHAR2, maxLength NUMBER) RETURN VARCHAR2 AS
LANGUAGE JAVA NAME 'FamDict.GetFamWithLen(java.lang.String, int) return java.lang.String';
/ --HARDCODE FOR DEPLOYMENT
create or replace FUNCTION pflb_encode_dict_namegetwithlen(st VARCHAR2, maxLength NUMBER) RETURN VARCHAR2 AS
LANGUAGE JAVA NAME 'NameDict.GetNameWithLen(java.lang.String, int) return java.lang.String';
/ --HARDCODE FOR DEPLOYMENT
CREATE OR REPLACE FUNCTION pflb_encode_dict_otchgetwithlen(st VARCHAR2, maxLength NUMBER) RETURN VARCHAR2 AS
LANGUAGE JAVA NAME 'OtchDict.GetOtchWithLen(java.lang.String, int) return java.lang.String';
/ --HARDCODE FOR DEPLOYMENT
CREATE OR REPLACE FUNCTION pflb_encode_dict_fiogetwithlen(st VARCHAR2, maxLength NUMBER) RETURN VARCHAR2 AS
LANGUAGE JAVA NAME 'FIODict.GetFioWithLen(java.lang.String, int) return java.lang.String';
/ --HARDCODE FOR DEPLOYMENT
create or replace procedure pflb_dict_fam_add(st varchar2) as
language java name
'FamDict.AddName(java.lang.String)';
/ --HARDCODE FOR DEPLOYMENT

create or replace procedure pflb_dict_fam_shuffle(key varchar2, range NUMBER) as
language java name
'FamDict.ArraysShuffle(java.lang.String, int)';
/ --HARDCODE FOR DEPLOYMENT

create or replace function pflb_encode_dict_famget(st varchar2) return varchar2 as
language java name
'FamDict.GetName(java.lang.String) returns java.lang.String';
/ --HARDCODE FOR DEPLOYMENT

create or replace procedure pflb_dict_fam_clear as
language java name
'FamDict.ClearNames()';
/ --HARDCODE FOR DEPLOYMENT
create or replace procedure pflb_dict_fam_fill(st clob) as
language java name
'FamDict.AddNames(java.sql.Clob)';
/ --HARDCODE FOR DEPLOYMENT
create or replace function pflb_encode_dict_fioget(st varchar2) return varchar2 AS
language java name 
'FIODict.GetFio(java.lang.String) return java.lang.String';
/ --HARDCODE FOR DEPLOYMENT
create or replace procedure pflb_dict_names_add(st varchar2) as
language java name
'NameDict.AddName(java.lang.String)';
/ --HARDCODE FOR DEPLOYMENT

create or replace procedure pflb_dict_names_shuffle(key varchar2, range NUMBER) as
language java name
'NameDict.ArraysShuffle(java.lang.String, int)';
/ --HARDCODE FOR DEPLOYMENT

create or replace function pflb_encode_dict_nameget(st varchar2) return varchar2 as
language java name
'NameDict.GetName(java.lang.String) returns java.lang.String';
/ --HARDCODE FOR DEPLOYMENT

create or replace procedure pflb_dict_names_clear as
language java name
'NameDict.ClearNames()';
/ --HARDCODE FOR DEPLOYMENT

create or replace function pflb_dict_names_check_size return number as
language java name
'NameDict.CheckSize() returns int';
/ --HARDCODE FOR DEPLOYMENT
create or replace procedure pflb_dict_names_fill(st clob) as
language java name
'NameDict.AddNames(java.sql.Clob)';
/ --HARDCODE FOR DEPLOYMENT
create or replace procedure pflb_dict_otch_add(st varchar2) as
language java name
'OtchDict.AddName(java.lang.String)';
/ --HARDCODE FOR DEPLOYMENT

create or replace procedure pflb_dict_otch_shuffle(key varchar2, range NUMBER) as
language java name
'OtchDict.ArraysShuffle(java.lang.String, int)';
/ --HARDCODE FOR DEPLOYMENT

create or replace function pflb_encode_dict_otchget(st varchar2) return varchar2 as
language java name
'OtchDict.GetName(java.lang.String) returns java.lang.String';
/ --HARDCODE FOR DEPLOYMENT

create or replace procedure pflb_dict_otch_clear as
language java name
'OtchDict.ClearNames()';
/ --HARDCODE FOR DEPLOYMENT
create or replace procedure pflb_dict_otch_fill(st clob) as
language java name
'OtchDict.AddNames(java.sql.Clob)';
/ --HARDCODE FOR DEPLOYMENT

create or replace procedure PFLB_DICT_FAMGET_SF(value clob, skey varchar2)
as
srange number := 10;
begin 
pflb_dict_fam_fill(value);
pflb_dict_fam_shuffle(skey,srange);
end;
/ --HARDCODE FOR DEPLOYMENT



create or replace procedure PFLB_DICT_NAMEGET_SF(value clob, skey varchar2)
as
srange number := 10;
begin 
pflb_dict_names_fill(value);
pflb_dict_names_shuffle(skey,srange);
end;
/ --HARDCODE FOR DEPLOYMENT



create or replace procedure PFLB_DICT_OTCHGET_SF(value clob, skey varchar2)
as
srange number := 10;
begin 
pflb_dict_OTCH_fill(value);
pflb_dict_OTCH_shuffle(skey,srange);
end;
/ --HARDCODE FOR DEPLOYMENT

create function PFLB_ANONYMIZE_VALUE_MULTI
(dict_ids varchar2, delimiters_table varchar2, enable_hash varchar2, max_length varchar2, val varchar2)
    return varchar2
        as language java name
'depers_by_dict.pflb_anonymize_value_multi(java.lang.String, java.lang.String, java.lang.String, java.lang.String, java.lang.String) return java.lang.String';
/ --HARDCODE FOR DEPLOYMENT
CREATE OR REPLACE FUNCTION pflb_load_dictionary_from_clob(
    p_dict_id   NUMBER,
    p_dict_name VARCHAR2,
    p_data      CLOB
) RETURN VARCHAR2
AS LANGUAGE JAVA
NAME 'depers_by_dict.pflb_load_dictionary_from_clob(int, java.lang.String, java.sql.Clob) return java.lang.String';
/ --HARDCODE FOR DEPLOYMENT
CREATE OR REPLACE FUNCTION pflb_generate_dictionary_pairs(
    p_dict_id     NUMBER,
    p_shuffle_key VARCHAR2
) RETURN VARCHAR2
AS LANGUAGE JAVA
NAME 'depers_by_dict.pflb_generate_dictionary_pairs(int, java.lang.String) return java.lang.String';
