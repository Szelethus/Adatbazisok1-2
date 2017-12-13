EXPLAIN PLAN SET statement_id = 'cikk3_orig'
    FOR
SELECT sum(mennyiseg)
FROM nikovits.szallit NATURAL JOIN nikovits.cikk NATURAL JOIN nikovits.szallito
WHERE szin = 'piros' AND telephely = 'Pecs';

select plan_table_output from table(dbms_xplan.display('plan_table','cikk3_orig','all')); 

EXPLAIN PLAN SET statement_id = 'cikk3_hash_no_index'
    FOR
SELECT /*+ use_hash(s1 c s2) no_index(s1) no_index(c) no_index(s2) */sum(mennyiseg)
FROM nikovits.szallit s1 NATURAL JOIN nikovits.cikk c NATURAL JOIN nikovits.szallito s2
WHERE szin = 'piros' AND telephely = 'Pecs';

select plan_table_output from table(dbms_xplan.display('plan_table','cikk3_hash_no_index','all')); 

EXPLAIN PLAN SET statement_id = 'cikk3_szallit_index'
    FOR
SELECT /*+ index(s1) no_index(c) no_index(s2) */sum(mennyiseg)
FROM nikovits.szallit s1 NATURAL JOIN nikovits.cikk c NATURAL JOIN nikovits.szallito s2
WHERE szin = 'piros' AND telephely = 'Pecs';

select plan_table_output from table(dbms_xplan.display('plan_table','cikk3_szallit_index','all')); 

------------------------------------------------------------

EXPLAIN PLAN SET statement_id = 'sh'
    FOR
SELECT /*+ INDEX_COMBINE(c2) no_index(c1) */ *
FROM sh.customers c2 NATURAL JOIN sh.countries c1
WHERE c2.cust_year_of_birth = 1700;

select plan_table_output from table(dbms_xplan.display('plan_table','sh','all')); 

EXPLAIN PLAN SET statement_id = 'sh2'
    FOR
SELECT /*+ no_index(c) no_index(s) */ c.cust_year_of_birth
FROM sh.customers c NATURAL JOIN sh.sales s
GROUP BY c.cust_year_of_birth
ORDER BY c.cust_year_of_birth;

select plan_table_output from table(dbms_xplan.display('plan_table','sh2','all')); 

delete from plan_table;