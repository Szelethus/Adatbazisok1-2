/***********************************************************************************/
/***                                 Partícionálás                               ***/
/*** (DBA_PART_TABLES, DBA_PART_INDEXES, DBA_TAB_PARTITIONS, DBA_IND_PARTITIONS, ***/ 
/***     DBA_TAB_SUBPARTITIONS, DBA_IND_SUBPARTITIONS, DBA_PART_KEY_COLUMNS)     ***/
/***********************************************************************************/

---=== 1. feladat ===---
-- meg az SH felhasználó tulajdonában levõ partícionált táblák nevét és a 
--particionálás típusát.

SELECT table_name, partitioning_type 
FROM dba_part_tables 
WHERE owner = 'SH';

---=== 2. feladat ===---
/*
Soroljuk fel az SH.COSTS tábla partícióit valamint, hogy hány blokkot foglalnak
az egyes partíciók. (Vigyázat! Egyes adatszótárak csak becsült méretet tartalmaznak.
A pontos méreteket az extenseknél és szegmenseknél keressük.)
*/

SELECT partition_name, blocks 
FROM dba_tab_partitions 
WHERE table_owner = 'SH' AND table_name = 'COSTS';

SELECT segment_name, partition_name, blocks 
FROM dba_segments 
WHERE owner = 'SH' AND segment_type = 'TABLE PARTITION' AND segment_name = 'COSTS';

---=== 3. feladat ===---
--Adjuk meg, hogy az SH.COSTS tábla mely oszlop(ok) szerint van particionálva.

SELECT column_name, column_position 
FROM dba_part_key_columns 
WHERE owner = 'SH' AND name = 'COSTS' AND object_type = 'TABLE';

---=== 4. feladat ===---
--Adjuk meg, hogy a NIKOVITS.ELADASOK3 illetve az SH.COSTS táblák második partíciójában
--milyen értékek szerepelhetnek.

SELECT partition_name, partition_position pos, high_value, partition_position 
FROM dba_tab_partitions 
WHERE (
    table_owner = 'NIKOVITS' AND table_name = 'ELADASOK3' OR table_owner = 'SH' AND table_name = 'COSTS'
) AND partition_position = 2;

---=== 5. feladat ===---
/*
Adjuk meg egy partícionált tábla logikai és fizikai részeit (pl. NIKOVITS.ELADASOK). 
Maga a tábla most is logikai objektum, a partíciói vannak fizikailag tárolva.
Nézzük meg az objektumok és a szegmensek között is.
*/

SELECT object_name, object_type, subobject_name, object_id, data_object_id
FROM dba_objects 
WHERE owner = 'NIKOVITS' AND object_name = 'ELADASOK';

SELECT * 
FROM dba_segments 
WHERE owner = 'NIKOVITS' AND segment_name = 'ELADASOK';

---=== 6. feladat ===---
--Illetve ha alpartíciói is vannak (pl. nikovits.eladasok4), akkor csak az alpartíciók 
--vannak tárolva. Nézzük meg az objektumok és a szegmensek között is.

SELECT object_name, object_type, subobject_name, object_id, data_object_id
FROM dba_objects 
WHERE owner = 'NIKOVITS' AND object_name = 'ELADASOK4';

SELECT * 
FROM dba_segments 
WHERE owner = 'NIKOVITS' AND segment_name = 'ELADASOK4';

---=== 7. feladat ===---
--Melyik a legnagyobb méretû partícionált tábla az adatbázisban a partíciók 
--összméretét tekintve? (az alpartícióval rendelkezõ táblákat is vegyük figyelembe)

SELECT owner, segment_name, SUM(bytes) 
FROM dba_segments 
WHERE segment_type LIKE 'TABLE%PARTITION'
GROUP BY owner, segment_name
ORDER BY SUM(bytes) DESC;

/***********************************************************************************/
/***                              Klaszter (CLUSTER)                             ***/
/***  (DBA_CLUSTERS, DBA_CLU_COLUMNS, DBA_TABLES, DBA_CLUSTER_HASH_EXPRESSIONS)  ***/
/***********************************************************************************/

---=== 1. feladat ===---
/*
Hozzunk létre egy DOLGOZO(dazon, nev, beosztas, fonoke, fizetes, oazon ... stb.) 
és egy OSZTALY(oazon, nev, telephely ... stb.) nevû táblát. 
(lásd NIKOVITS.DOLGOZO és NIKOVITS.OSZTALY)
A két táblának az osztály azonosítója (oazon) lesz a közös oszlopa. A két táblát 
egy index alapú CLUSTEREN hozzuk létre. (Elõbb persze létre kell hozni a clustert is.)
Majd tegyünk bele 3 osztályt, és osztályonként két dolgozót.
*/

---=== 2. feladat ===---
--Adjunk meg egy olyan clustert az adatbázisban (ha van ilyen), amelyen még nincs
--egy tábla sem. 

(
    SELECT owner, cluster_name 
    FROM dba_clusters  
)
MINUS
(
    SELECT owner, cluster_name 
    FROM dba_tables;
)

---=== 3. feladat ===---
--Adjunk meg egy olyant, amelyiken legalább 6 darab tábla van.

SELECT owner, cluster_name 
FROM dba_tables 
WHERE cluster_name IS NOT NULL
GROUP BY owner, cluster_name HAVING COUNT(*) >= 6;

---=== 4. feladat ===---
--Adjunk meg egy olyan clustert, amelynek a cluster kulcsa 3 oszlopból áll.
--(Vigyázat!!! Több tábla is lehet rajta)

SELECT owner, cluster_name 
FROM dba_clu_columns  
GROUP BY owner, cluster_name 
HAVING COUNT(DISTINCT clu_column_name) = 3;

/********************/
/*** HASH CLUSTER ***/
/********************/

---=== 1. feladat ===---
--Hány olyan hash cluster van az adatbázisban, amely nem az oracle alapértelmezés 
--szerinti hash függvényén alapul?

SELECT COUNT(*) 
FROM (
    SELECT owner, cluster_name, hash_expression 
    FROM dba_cluster_hash_expressions
);

---=== 2. feladat ===---
/*
Hozzunk létre egy hash clustert és rajta két táblát, majd szúrjunk be a 
táblákba sorokat úgy, hogy a két táblának 2-2 sora ugyanabba a blokkba 
kerüljön. Ellenõrizzük is egy lekérdezéssel, hogy a 4 sor valóban ugyanabban 
a blokkban van-e. (A ROWID lekérdezésével)
TIPP: A sorok elhelyezését befolyásolni tudjuk a HASH IS megadásával.
*/


