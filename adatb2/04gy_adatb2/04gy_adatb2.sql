/**********************************************************/
/**                     Oracle indexek                   **/
/**  (DBA_INDEXES, DBA_IND_COLUMNS, DBA_IND_EXPRESSIONS) **/
/**********************************************************/

---=== 1. feladat ===---
/*
Hozzunk létre egy vagy több táblához több különböző indexet, legyen köztük több oszlopos,
csökkenő sorrendű, bitmap, függvény alapú stb. (Ehhez használhatók az ab2_oracle.doc
állományban szereplő példák, vagy a cr_index.txt-ben szereplők.)
Az alábbi lekérdezésekkel megállapítjuk az iménti indexeknek mindenféle tulajdonságait a 
katalógusokból.
*/

CREATE TABLE husi
AS SELECT *
FROM nikovits.dolgozo;

-- Egy soros index
CREATE INDEX fizetes
ON husi(fizetes);

-- Több soros index
CREATE INDEX dkod_dnev
ON husi(dkod, dnev);

-- Csökkenő sorrend
CREATE INDEX dkod
ON husi(dkod DESC);

-- Egyedi index
CREATE UNIQUE INDEX dkod_unique
ON husi(dkod);

-- Bitmap index
CREATE BITMAP INDEX oazon_bitmap
ON husi(oazon);

-- Fordított index
CREATE INDEX dkod_reverse
ON husi(dkod) REVERSE;

-- Tömörített index
CREATE INDEX dkod_dnev_compressed
ON husi(dkod, dnev) COMPRESS 1;

-- Függvény alapú index
-- Létrehozunk egy függvényt (dkod-ot megfelezi)
CREATE OR REPLACE FUNCTION half_dkod ( dkod IN NUMBER ) RETURN NUMBER DETERMINISTIC IS -- determinisztikusnak kell lennie
BEGIN
  RETURN dkod / 2;
END;
/

-- Létrehozzuk az indexet
CREATE INDEX half_dkod 
ON husi(dnev);

-- Példa lekérdezés
SELECT half_dkod(dkod)
FROM husi;

-- Információk az indexekről

SELECT * 
FROM dba_indexes
WHERE table_owner = 'PW9YIK' AND table_name = 'HUSI';

DROP TABLE husi;

---=== 2. feladat ===---
-- Adjuk meg azoknak a tábláknak a nevét, amelyeknek van csökkenő sorrendben indexelt oszlopa.

SELECT table_name
FROM dba_ind_columns
WHERE descend = 'DESC';

---=== 3. feladat ===---
--Miért ilyen furcsa az oszlopnév?
--> lásd DBA_IND_EXPRESSIONS

-- what?

---=== 4. feladat ===---
--Adjuk meg azoknak az indexeknek a nevét, amelyek legalább 9 oszloposak.
--(Vagyis a táblának legalább 9 oszlopát vagy egyéb kifejezését indexelik.)

SELECT table_owner, table_name, count(*)
FROM dba_ind_columns
GROUP BY table_owner, table_name
HAVING count(*) >= 9;

---=== 5. feladat ===---
--Adjuk meg az SH.SALES táblára létrehozott bitmap indexek nevét.

SELECT index_name
FROM dba_indexes
WHERE table_owner = 'SH' AND table_name = 'SALES' AND index_type = 'BITMAP';

---=== 6. feladat ===---
--Adjuk meg azon kétoszlopos indexek nevét és tulajdonosát, amelyeknek legalább 
--az egyik kifejezése függvény alapú.
(
    -- kétoszlopú indexek
    SELECT index_owner, table_name, index_name
    FROM dba_ind_columns
    GROUP BY index_owner, table_name, index_name
    HAVING count(column_name) = 2
)
MINUS
(
    -- nem függvény alapú indexek
    SELECT owner AS index_owner, table_name, index_name
    FROM dba_indexes
    WHERE index_type NOT LIKE 'FUNCTION-BASED%'
);

---=== 7. feladat ===---
--Adjuk meg az egyikükre, pl. az OE tulajdonában lévőre, hogy milyen kifejezések szerint 
--vannak indexelve a soraik. (Vagyis mi a függveny, ami alapján a bejegyzések készülnek.)

SELECT column_expression
FROM (
    -- Előző feladatból
    (
        -- kétoszlopú indexek
        SELECT index_owner, table_name, index_name
        FROM dba_ind_columns
        GROUP BY index_owner, table_name, index_name
        HAVING count(column_name) = 2
    )
    MINUS
    (
        -- nem függvény alapú indexek
        SELECT owner AS index_owner, table_name, index_name
        FROM dba_indexes
        WHERE index_type NOT LIKE 'FUNCTION-BASED%'
    )
) NATURAL JOIN dba_ind_expressions
WHERE table_owner = 'OE';

---=== 8. feladat ===---
-- Adjuk meg a NIKOVITS felhasználó tulajdonában levő index-szervezett táblák nevét.
-- (Melyik táblatéren vannak ezek a táblák? -> miért nem látható?)

SELECT table_name, tablespace_name, iot_name, iot_type
FROM dba_tables
WHERE owner = 'NIKOVITS' AND iot_type = 'IOT';

---=== 9. feladat ===---
--Adjuk meg a fenti táblák index részét, és azt, hogy ezek az index részek (szegmensek) 
--melyik táblatéren vannak?

SELECT table_name, index_name, index_type, tablespace_name 
FROM dba_indexes 
WHERE table_owner='NIKOVITS' AND index_type LIKE '%IOT%';

---=== 10. feladat ===---


SELECT first.table_name
FROM dba_tab_columns first, dba_tab_columns second
WHERE first.owner = 'NIKOVITS' AND second.owner = first.owner AND 
        first.column_id = 2 AND second.column_id = 7 AND first.data_type = second.data_type;
        
CREATE OR REPLACE PROCEDURE zhfeladat IS

BEGIN
    FOR row IN (
        SELECT 
            dbms_rowid.rowid_relative_fno(ROWID) file_id,
            dbms_rowid.rowid_block_number(ROWID) block_id,
            count(*) row_count
        FROM nikovits.hallgatok
        GROUP BY 
            dbms_rowid.rowid_relative_fno(ROWID),
            dbms_rowid.rowid_block_number(ROWID)
        HAVING count(*) > 100
    ) LOOP
        dbms_output.put_line(row.file_id||' '||row.block_id||' '||row.row_count);
    END LOOP;
END;
/

SET SERVEROUTPUT ON;

EXECUTE ZHFELADAT;