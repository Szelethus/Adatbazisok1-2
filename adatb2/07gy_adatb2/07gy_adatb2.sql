/*****************************/

create table PLAN_TABLE (
        statement_id       varchar2(30),
        plan_id            number,
        timestamp          date,
        remarks            varchar2(4000),
        operation          varchar2(30),
        options            varchar2(255),
        object_node        varchar2(128),
        object_owner       varchar2(30),
        object_name        varchar2(30),
        object_alias       varchar2(65),
        object_instance    numeric,
        object_type        varchar2(30),
        optimizer          varchar2(255),
        search_columns     number,
        id                 numeric,
        parent_id          numeric,
        depth              numeric,
        position           numeric,
        cost               numeric,
        cardinality        numeric,
        bytes              numeric,
        other_tag          varchar2(255),
        partition_start    varchar2(255),
        partition_stop     varchar2(255),
        partition_id       numeric,
        other              long,
        distribution       varchar2(30),
        cpu_cost           numeric,
        io_cost            numeric,
        temp_space         numeric,
        access_predicates  varchar2(4000),
        filter_predicates  varchar2(4000),
        projection         varchar2(4000),
        time               numeric,
        qblock_name        varchar2(30),
        other_xml          clob
);

DROP TABLE PLAN_TABLE;

EXPLAIN PLAN SET statement_id='ut1'  -- ut1 -> az utasításnak egyedi nevet adunk
  FOR 
  SELECT avg(fizetes) FROM nikovits.dolgozo;
  
SELECT * FROM PLAN_TABLE;

SELECT LPAD(' ', 2*(level-1))||operation||' + '||options||' + '||object_name terv
FROM plan_table
START WITH id = 0 AND statement_id = 'ut1'                 -- az utasítás neve szerepel itt
CONNECT BY PRIOR id = parent_id AND statement_id = 'ut1'   -- meg itt
ORDER SIBLINGS BY position;


SELECT SUBSTR(LPAD(' ', 2*(LEVEL-1))||operation||' + '||options||' + '||object_name, 1, 50) terv,
  cost, cardinality, bytes, io_cost, cpu_cost
FROM plan_table
START WITH ID = 0 AND STATEMENT_ID = 'ut1'                 -- az utasítás neve szerepel itt
CONNECT BY PRIOR id = parent_id AND statement_id = 'ut1'   -- meg itt
ORDER SIBLINGS BY position;

select plan_table_output from table(dbms_xplan.display('plan_table','ut1','all'));
select plan_table_output from table(dbms_xplan.display());

CREATE TABLE dolgozo AS SELECT * FROM nikovits.dolgozo;
CREATE TABLE osztaly AS SELECT * FROM nikovits.osztaly;
CREATE TABLE Fiz_kategoria  AS SELECT * FROM nikovits.Fiz_kategoria;

EXPLAIN PLAN SET statement_id='ut2'  -- ut1 -> az utasításnak egyedi nevet adunk
  FOR 
SELECT DISTINCT onev
FROM dolgozo NATURAL JOIN osztaly
WHERE fizetes > (
    SELECT also
    FROM FIZ_KATEGORIA
    WHERE kategoria = 1
) AND fizetes <= (
    SELECT felso
    FROM FIZ_KATEGORIA
    WHERE kategoria = 1
);

CREATE INDEX ind_onev
ON osztaly(onev);

select plan_table_output from table(dbms_xplan.display('plan_table','ut1','all'));
select plan_table_output from table(dbms_xplan.display('plan_table','ut2','all'));

---=== 1. feladat ===---
-- Adjuk meg úgy a lekérdezést, hogy egyik táblára se használjon indexet az oracle. 
EXPLAIN PLAN SET statement_id = 'cikk_orig'
    FOR
SELECT sum(mennyiseg)
FROM nikovits.szallit NATURAL JOIN nikovits.cikk
WHERE szin = 'piros';

select plan_table_output from table(dbms_xplan.display('plan_table','cikk_orig','all'));

---=== 2. feladat ===---
-- Adjuk meg úgy a lekérdezést, hogy csak az egyik táblára használjon indexet az oracle. 
EXPLAIN PLAN SET statement_id = 'cikk_index_one_table'
    FOR
SELECT /*+ index(c) */ sum(mennyiseg)
FROM nikovits.szallit NATURAL JOIN nikovits.cikk c
WHERE szin = 'piros';

select plan_table_output from table(dbms_xplan.display('plan_table','cikk_index_one_table','all'));

---=== 3. feladat ===---
-- Adjuk meg úgy a lekérdezést, hogy mindkét táblára használjon indexet az oracle.
EXPLAIN PLAN SET statement_id = 'cikk_index_two_tables'
    FOR
SELECT /*+ index(c) index(sz) */ sum(mennyiseg)
FROM nikovits.szallit sz NATURAL JOIN nikovits.cikk c
WHERE szin = 'piros';

select plan_table_output from table(dbms_xplan.display('plan_table','cikk_index_two_tables','all'));

---=== 4. feladat ===---
-- Adjuk meg úgy a lekérdezést, hogy a két táblát SORT-MERGE módszerrel kapcsolja össze.

EXPLAIN PLAN SET statement_id = 'cikk_sort_merge'
    FOR
SELECT /*+ USE_MERGE(sz c) */ sum(mennyiseg)
FROM nikovits.szallit sz NATURAL JOIN nikovits.cikk c
WHERE szin = 'piros';

select plan_table_output from table(dbms_xplan.display('plan_table','cikk_sort_merge','all'));

---===  5. feladat ===---
-- Adjuk meg úgy a lekérdezést, hogy a két táblát NESTED-LOOPS módszerrel kapcsolja össze. 

EXPLAIN PLAN SET statement_id = 'cikk_nested_loops'
    FOR
SELECT /*+ USE_NL(sz c) */ sum(mennyiseg)
FROM nikovits.szallit sz NATURAL JOIN nikovits.cikk c
WHERE szin = 'piros';

select plan_table_output from table(dbms_xplan.display('plan_table','cikk_nested_loops','all'));

---=== 6. feladat ===---
-- Adjuk meg úgy a lekérdezést, hogy a két táblát HASH-JOIN módszerrel kapcsolja össze.

EXPLAIN PLAN SET statement_id = 'cikk_hash_join'
    FOR
SELECT /*+ USE_HASH(sz c) */ sum(mennyiseg)
FROM nikovits.szallit sz NATURAL JOIN nikovits.cikk c
WHERE szin = 'piros';

select plan_table_output from table(dbms_xplan.display('plan_table','cikk_hash_join','all'));

---=== 7. feladat ===---
-- Adjuk meg úgy a lekérdezést, hogy a két táblát NESTED-LOOPS módszerrel kapcsolja össze,
-- és ne használjon indexet. 

EXPLAIN PLAN SET statement_id = 'cikk_nested_loops_no_index'
    FOR
SELECT /*+ no_index(sz) no_index(c) USE_NL(sz c) */ sum(mennyiseg)
FROM nikovits.szallit sz NATURAL JOIN nikovits.cikk c
WHERE szin = 'piros';

select plan_table_output from table(dbms_xplan.display('plan_table','cikk_nested_loops_no_index','all'));