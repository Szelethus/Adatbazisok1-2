---=== 1. feladat ===---
-- Adjuk meg azon szállítások összmennyiségét, ahol ckod=2 és szkod=2.
EXPLAIN PLAN SET statement_id = 'cikk2_orig'
    FOR
SELECT sum(mennyiseg)
FROM nikovits.szallit sz NATURAL JOIN nikovits.cikk c
WHERE ckod = 2 AND szkod = 2;

SELECT plan_table_output FROM TABLE(dbms_xplan.display('plan_table','cikk2_orig','all'));

-- Adjuk meg úgy a lekérdezést, hogy ne használjon indexet.
EXPLAIN PLAN SET statement_id = 'cikk2_no_index'
    FOR
SELECT /*+ no_index(sz) no_index(c) */ sum(mennyiseg)
FROM nikovits.szallit sz NATURAL JOIN nikovits.cikk c
WHERE ckod = 2 AND szkod = 2;

select plan_table_output from table(dbms_xplan.display('plan_table','cikk2_no_index','all'));

-- A végrehajtási tervben két indexet használjon, és képezze a sorazonosítók metszetét (AND-EQUAL).
-- nem jó!
EXPLAIN PLAN SET statement_id = 'cikk2_and_equal'
    FOR
SELECT /*+ AND_EQUAL(sz) */ sum(mennyiseg)
FROM nikovits.szallit sz NATURAL JOIN nikovits.cikk c
WHERE ckod = 2 AND szkod = 2;

select plan_table_output from table(dbms_xplan.display('plan_table','cikk2_and_equal','all')); 

---=== 2. feladat ===---
-- Adjuk meg a Pecs-i telephelyű szállítók által szállított piros cikkek összmennyiségét.

EXPLAIN PLAN SET statement_id = 'cikk3_orig'
    FOR
SELECT sum(mennyiseg)
FROM nikovits.szallit NATURAL JOIN nikovits.cikk NATURAL JOIN nikovits.szallito
WHERE szin = 'piros' AND telephely = 'Pecs';

select plan_table_output from table(dbms_xplan.display('plan_table','cikk3_orig','all')); 

-- Adjuk meg úgy a lekérdezést, hogy a szallit táblát el?ször a cikk táblával join-olja az oracle.
EXPLAIN PLAN SET statement_id = 'cikk3_order_change'
    FOR
SELECT /*+ leading(sz c) */ sum(mennyiseg)
FROM nikovits.szallit sz NATURAL JOIN nikovits.cikk c NATURAL JOIN nikovits.szallito szo
WHERE szin = 'piros' AND telephely = 'Pecs';

select plan_table_output from table(dbms_xplan.display('plan_table','cikk3_order_change','all')); 

-- Adjuk meg úgy a lekérdezést, hogy a szallit táblát el?ször a szallito táblával join-olja az oracle.
EXPLAIN PLAN SET statement_id = 'cikk3_order_change2'
    FOR
SELECT /*+ leading(sz szo) */ sum(mennyiseg)
FROM nikovits.szallit sz NATURAL JOIN nikovits.cikk c NATURAL JOIN nikovits.szallito szo
WHERE szin = 'piros' AND telephely = 'Pecs';

select plan_table_output from table(dbms_xplan.display('plan_table','cikk3_order_change2','all')); 

---=== 3. feladat ===---
-- Adjuk meg azon szállítások összmennyiségét, ahol ckod=1 vagy szkod=2.
EXPLAIN PLAN SET statement_id = 'cikk4_orig'
    FOR
SELECT sum(mennyiseg)
FROM nikovits.szallit sz NATURAL JOIN nikovits.cikk c
WHERE ckod = 1 OR szkod = 2;

select plan_table_output from table(dbms_xplan.display('plan_table','cikk4_orig','all')); 

--Adjuk meg úgy a lekérdezést, hogy ne használjon indexet.
EXPLAIN PLAN SET statement_id = 'cikk4_no_index'
    FOR
SELECT /*+ no_index(sz) no_index(c) */ sum(mennyiseg)
FROM nikovits.szallit sz NATURAL JOIN nikovits.cikk c
WHERE ckod = 1 OR szkod = 2;

select plan_table_output from table(dbms_xplan.display('plan_table','cikk4_no_index','all'));

-- A végrehajtási tervben két indexet használjon, és képezze a kapott sorok unióját (CONCATENATION).
EXPLAIN PLAN SET statement_id = 'cikk4_concat'
    FOR
SELECT /*+ index(sz) index(c) USE_CONCAT */ sum(mennyiseg)
FROM nikovits.szallit sz NATURAL JOIN nikovits.cikk c
WHERE ckod = 1 OR szkod = 2;

select plan_table_output from table(dbms_xplan.display('plan_table','cikk4_concat','all'));

---=== 4. feladat ===---    
--Adjuk meg azoknak a vevőknek a nevét (SH.CUSTOMERS), akik nőneműek (cust_gender = 'F') és szinglik
--(cust_marital_status = 'single'), vagy 1917 és 1920 között születtek (cust_year_of_birth). 

EXPLAIN PLAN SET statement_id = 'cust_orig'
    FOR
SELECT cust_id, cust_first_name, cust_last_name
FROM sh.customers
WHERE (cust_gender = 'F' AND cust_marital_status = 'single') 
    OR cust_year_of_birth BETWEEN '1917' AND '1920';
    
select plan_table_output from table(dbms_xplan.display('plan_table','cust_orig','all'));

--Vegyük rá az Oracle-t, hogy a meglévő bitmap indexek alapján érje el a tábla sorait.

--Kérdezzük le a táblán definiált bitmap indexeket
SELECT index_name
FROM dba_indexes
WHERE table_owner = 'SH' AND table_name = 'CUSTOMERS' AND INDEX_TYPE = 'BITMAP';

EXPLAIN PLAN SET statement_id = 'cust_bitmap'
    FOR
SELECT /*+ INDEX_COMBINE(c) */ cust_id, cust_first_name, cust_last_name
FROM sh.customers c
WHERE (cust_gender = 'F' AND cust_marital_status = 'single') 
    OR cust_year_of_birth BETWEEN '1917' AND '1920';
    
select plan_table_output from table(dbms_xplan.display('plan_table','cust_bitmap','all'));

--Vegyük rá, hogy ne használja ezeket az indexeket.

EXPLAIN PLAN SET statement_id = 'cust_no_index'
    FOR
SELECT /*+ NO_INDEX(c) */ cust_id, cust_first_name, cust_last_name
FROM sh.customers c
WHERE (cust_gender = 'F' AND cust_marital_status = 'single') 
    OR cust_year_of_birth BETWEEN '1917' AND '1920';
    
select plan_table_output from table(dbms_xplan.display('plan_table','cust_no_index','all'));

---=== 5. feladat ===---


/*
SELECT STATEMENT +  +
  SORT + AGGREGATE +
    HASH JOIN +  +
      TABLE ACCESS + FULL + PRODUCTS
      HASH JOIN +  +
        TABLE ACCESS + BY INDEX ROWID + CUSTOMERS
          BITMAP CONVERSION + TO ROWIDS +
            BITMAP INDEX + SINGLE VALUE + CUSTOMERS_YOB_BIX
        PARTITION RANGE + ALL +
          TABLE ACCESS + FULL + SALES
*/


EXPLAIN PLAN SET statement_id = 'test'
    FOR
SELECT /*+ full(p) */ *
FROM sh.products p 
WHERE  NOT EXISTS(
    SELECT  /*+ INDEX_COMBINE(c CUSTOMERS_YOB_BIX) full(s) USE_HASH(s c) */ c.cust_year_of_birth
    FROM sh.customers c NATURAL JOIN sh.sales s 
    WHERE c.cust_year_of_birth = 1900
);
    
select plan_table_output from table(dbms_xplan.display('plan_table','test','all'));


delete from plan_table;  