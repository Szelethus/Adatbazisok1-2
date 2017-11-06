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

