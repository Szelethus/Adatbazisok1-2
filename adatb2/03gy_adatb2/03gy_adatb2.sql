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


-- HÁZI FELADAT (kicsit több időt igényel, mint a gyakorlaton megoldottak)
-- ------------
-- Irjunk meg egy PL/SQL fuggvenyt, ami a  ROWID 64-es kodolasanak megfelelo
-- szamot adja vissza. A fuggveny parametere egy karakterlanc, eredmenye 
-- pedig a kodolt numerikus ertek legyen. (Eleg ha a fuggveny maximum 6 
-- hosszu, helyesen kodolt karakterlancokra mukodik, hosszabb karakterlancra,
-- vagy rosszul kodolt parameterre adjon vissza -1-et.)
-- Ennek a fv-nek a segitsegevel adjuk meg egy tablabeli sor pontos fizikai 
-- elhelyezkedeset. (Melyik fajl, melyik blokk, melyik sora) Peldaul az
-- ORAUSER.DOLGOZO tabla azon sorara, ahol a dolgozo neve 'KING'.

-- Nem biztos hogy ez volt a feladat.
CREATE FUNCTION base64_char_to_dec(ch VARCHAR2) RETURN NUMBER IS
  c NUMBER := ascii(ch);
  errOR_code NUMBER := 0;
BEGIN
  IF    ascii('A') <= c AND c <= ascii('Z') THEN
    RETURN c - ascii('A');
  ELSIF ascii('a') <= c AND c <= ascii('z') THEN
    RETURN c - ascii('a') + 26;
  ELSIF ascii('0') <= c AND c <= ascii('9') THEN
    RETURN c - ascii('0') + 52;
  ELSIF ascii('+') = c THEN
    RETURN 62;
  ELSIF ascii('/') = c THEN
    RETURN 63;
  END IF;
  RETURN errOR_code;
END;
/

CREATE FUNCTION base64_string_to_dec(base64str VARCHAR2) RETURN NUMBER IS
  summ NUMBER := 0;
  str VARCHAR2(100) := base64str;
  ch VARCHAR2(1);
  ch_value NUMBER;
BEGIN
  LOOP
    EXIT WHEN str IS NULL;
    ch := substr(str, 1, 1);
    ch_value := base64_char_to_dec(ch);
    str := substr(str, 2);
    summ := summ + ch_value;
    IF str IS NOT NULL THEN
      summ := summ * 64;
    END IF;
  END LOOP;
  RETURN summ;
END;
/

CREATE OR replace PROCEDURE rowid_to_parts(rowidStr VARCHAR2) IS
  obj_id   NUMBER;
  file_id  NUMBER;
  block_id NUMBER;
  row_id   NUMBER;
BEGIN
  SELECT base64_string_to_dec(substr(rowidStr, 1, 6)),
         base64_string_to_dec(substr(rowidStr, 7, 3)),
         base64_string_to_dec(substr(rowidStr, 10, 6)),
         base64_string_to_dec(substr(rowidStr, 16, 3))
  INTO obj_id, file_id, block_id, row_id
  FROM dual;
  
  dbms_output.put_line('obj_id: '   || obj_id   ||
                     ', file_id: '  || file_id  ||
                     ', block_id: ' || block_id ||
                     ', row_id: '   || row_id);
END;
/

SET SERVEROUTPUT ON
EXECUTE rowid_to_parts('AAASOwAAEAAAAIUAAW');
-- results: obj_id: 74672, file_id: 4, block_id: 532, row_id: 22, which is correct
