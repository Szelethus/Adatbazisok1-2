---=== 1. feladat ===---
-- Adjuk meg azon sz�ll�t�sok �sszmennyis�g�t, ahol ckod=2 �s szkod=2.
EXPLAIN PLAN SET statement_id = 'cikk2_orig'
    FOR
SELECT sum(mennyiseg)
FROM nikovits.szallit sz NATURAL JOIN nikovits.cikk c
WHERE ckod = 2 AND szkod = 2;

select plan_table_output from table(dbms_xplan.display('plan_table','cikk2_orig','all'));

-- Adjuk meg �gy a lek�rdez�st, hogy ne haszn�ljon indexet.
EXPLAIN PLAN SET statement_id = 'cikk2_no_index'
    FOR
SELECT /*+ no_index(sz) no_index(c) */ sum(mennyiseg)
FROM nikovits.szallit sz NATURAL JOIN nikovits.cikk c
WHERE ckod = 2 AND szkod = 2;

select plan_table_output from table(dbms_xplan.display('plan_table','cikk2_no_index','all'));

-- A v�grehajt�si tervben k�t indexet haszn�ljon, �s k�pezze a sorazonos�t�k metszet�t (AND-EQUAL).
-- nem j�!
EXPLAIN PLAN SET statement_id = 'cikk2_and_equal'
    FOR
SELECT /*+ AND_EQUAL(sz) */ sum(mennyiseg)
FROM nikovits.szallit sz NATURAL JOIN nikovits.cikk c
WHERE ckod = 2 AND szkod = 2;

select plan_table_output from table(dbms_xplan.display('plan_table','cikk2_and_equal','all')); 

---=== 2. feladat ===---
-- Adjuk meg a Pecs-i telephely? sz�ll�t�k �ltal sz�ll�tott piros cikkek �sszmennyis�g�t.

EXPLAIN PLAN SET statement_id = 'cikk3_orig'
    FOR
SELECT sum(mennyiseg)
FROM nikovits.szallit NATURAL JOIN nikovits.cikk NATURAL JOIN nikovits.szallito
WHERE szin = 'piros' AND telephely = 'Pecs';

select plan_table_output from table(dbms_xplan.display('plan_table','cikk3_orig','all')); 

-- Adjuk meg �gy a lek�rdez�st, hogy a szallit t�bl�t el?sz�r a cikk t�bl�val join-olja az oracle.
EXPLAIN PLAN SET statement_id = 'cikk3_order_change'
    FOR
SELECT /*+ leading(sz c) */ sum(mennyiseg)
FROM nikovits.szallit sz NATURAL JOIN nikovits.cikk c NATURAL JOIN nikovits.szallito szo
WHERE szin = 'piros' AND telephely = 'Pecs';

select plan_table_output from table(dbms_xplan.display('plan_table','cikk3_order_change','all')); 

-- Adjuk meg �gy a lek�rdez�st, hogy a szallit t�bl�t el?sz�r a szallito t�bl�val join-olja az oracle.
EXPLAIN PLAN SET statement_id = 'cikk3_order_change2'
    FOR
SELECT /*+ leading(sz szo) */ sum(mennyiseg)
FROM nikovits.szallit sz NATURAL JOIN nikovits.cikk c NATURAL JOIN nikovits.szallito szo
WHERE szin = 'piros' AND telephely = 'Pecs';

select plan_table_output from table(dbms_xplan.display('plan_table','cikk3_order_change2','all')); 

---=== 3. feladat ===---
-- Adjuk meg azon sz�ll�t�sok �sszmennyis�g�t, ahol ckod=1 vagy szkod=2.
EXPLAIN PLAN SET statement_id = 'cikk4_orig'
    FOR
SELECT sum(mennyiseg)
FROM nikovits.szallit sz NATURAL JOIN nikovits.cikk c
WHERE ckod = 1 OR szkod = 2;

select plan_table_output from table(dbms_xplan.display('plan_table','cikk4_orig','all')); 

--Adjuk meg �gy a lek�rdez�st, hogy ne haszn�ljon indexet.
EXPLAIN PLAN SET statement_id = 'cikk4_no_index'
    FOR
SELECT /*+ no_index(sz) no_index(c) */ sum(mennyiseg)
FROM nikovits.szallit sz NATURAL JOIN nikovits.cikk c
WHERE ckod = 1 OR szkod = 2;

select plan_table_output from table(dbms_xplan.display('plan_table','cikk4_no_index','all'));

-- A v�grehajt�si tervben k�t indexet haszn�ljon, �s k�pezze a kapott sorok uni�j�t (CONCATENATION).
EXPLAIN PLAN SET statement_id = 'cikk4_concat'
    FOR
SELECT /*+ index(sz) index(c) USE_CONCAT */ sum(mennyiseg)
FROM nikovits.szallit sz NATURAL JOIN nikovits.cikk c
WHERE ckod = 1 OR szkod = 2;

select plan_table_output from table(dbms_xplan.display('plan_table','cikk4_concat','all'));
