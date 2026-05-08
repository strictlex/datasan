create or replace function pflbp_check_inn(st varchar2) return number as
language java name
'Checker.CheckINN(java.lang.String) return boolean';
/ --HARDCODE FOR DEPLOYMENT

create or replace function pflbp_check_snils(st varchar2) return number as
language java name
'Checker.CheckSnils(java.lang.String) return boolean';
/ --HARDCODE FOR DEPLOYMENT

create or replace function pflbp_check_ogrn(st varchar2) return number as
language java name
'Checker.CheckOgrn(java.lang.String) return boolean';
/ --HARDCODE FOR DEPLOYMENT