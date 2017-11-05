/***************************************************/
/*****   ROWID adattípus formátuma és jelentése ****/
/*****       (lásd még DBMS_ROWID package)      ****/
/***************************************************/

/*
18 karakteren irodik ki, a kovetkezo formaban: OOOOOOFFFBBBBBBRRR
OOOOOO -  az objektum azonositoja (egészen pontosan az úgynevezett adatobjektum azonosítója)
FFF    -  fajl azonositoja (tablateren beluli relativ sorszam)
BBBBBB -  blokk azonosito (a fajlon beluli sorszam)
RRR    -  sor azonosito (a blokkon beluli sorszam)

A ROWID megjeleniteskor 64-es alapu kodolasban jelenik meg (Base64). 
Az egyes szamoknak (0-63) a következo karakterek felelnek meg:
A-Z -> (0-25), a-z -> (26-51), 0-9 -> (52-61), '+' -> (62), '/' -> (63)

Pl. 'AAAAAB' -> 000001
*/

---=== 1. feladat ===---
--Az egyes blokkokban hány sor van?

SELECT * FROM nikovits.cikk;

SELECT rownum, nikovits.cikk.* 
FROM nikovits.cikk;

SELECT rowid, nikovits.cikk.* 
FROM nikovits.cikk;

---=== 2. feladat ===---
/*
A NIKOVITS felhasználó CIKK táblája hány blokkot foglal le az adatbázisban? (ARAMIS)
(Vagyis hány olyan blokk van, ami ehhez a táblához van rendelve és így
azok már más táblákhoz nem adhatók hozzá?)
*/

SELECT blocks
FROM dba_segments
WHERE owner = 'NIKOVITS' AND segment_name = 'CIKK' AND segment_type = 'TABLE';

SELECT blocks
FROM dba_tables
WHERE owner = 'NIKOVITS' AND table_name = 'CIKK';

--Megfigyelhető, hogy minden lekérdezést más eredményt ad -> becsült eredmények csupán

---=== 3. feladat ===---
/*
A NIKOVITS felhasználó CIKK táblájának adatai hány blokkban helyezkednek el?
(Vagyis a tábla sorai ténylegesen hány blokkban vannak tárolva?)
!!! -> Ez a kérdés nem ugyanaz mint az előző.
*/

-- A ROWID [1, 15] értéke adja meg hogy pontosan melyik blokkban szerepel az adott sor
SELECT count(DISTINCT substr(ROWID, 1, 15)) 
FROM nikovits.cikk;

---=== 4. feladat ===---
--Az egyes blokkokban hány sor van?

SELECT substr(ROWID, 1, 15), count(*)
FROM nikovits.cikk
GROUP BY substr(ROWID, 1, 15)
ORDER BY 1;

---=== 5. feladat ===---
/*
Hozzunk létre egy táblát az EXAMPLE táblatéren, amelynek szerkezete azonos a nikovits.cikk 
tábláéval és pontosan 128 KB helyet foglal az adatbázisban. Foglaljunk le manuálisan további 
128 KB helyet a táblához. Vigyünk fel sorokat addig, amig az első blokk tele nem 
lesz, és 1 további sora lesz még a táblának a második blokkban.
(A felvitelt plsql programmal végezzük és ne kézzel, mert úgy kicsit sokáig tartana.)
*/

--Tábla létrehozása
CREATE TABLE husi
TABLESPACE example
STORAGE(INITIAL 128K)
AS SELECT * FROM nikovits.cikk WHERE 1 = 2;
--Így csak a struktúrát másoljuk le

--Extens lefoglalása
ALTER TABLE husi
ALLOCATE EXTENT (SIZE 128K);

--PL/SQL procedúrával sorok hozzáadása
DECLARE
    block_count NUMBER;
    i NUMBER := 1;
BEGIN
    WHILE TRUE LOOP
        INSERT INTO husi 
        SELECT * 
        FROM nikovits.cikk 
        WHERE i = ROWNUM; --Mindig más sort adjunk hozzá
        
        SELECT count(DISTINCT substr(rowid,1,15))
        INTO block_count 
        FROM husi;
        
        EXIT WHEN block_count > 1;
        i := i + 1;
    END LOOP;
END;
/

--Ellenőrzés
SELECT substr(ROWID, 1, 15), count(*)
FROM husi
GROUP BY substr(ROWID, 1, 15)
ORDER BY 1;

--Tábla kitörlése
DROP TABLE husi;