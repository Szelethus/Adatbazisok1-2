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

SELECT ROWNUM, nikovits.cikk.* 
FROM nikovits.cikk;

SELECT ROWID, nikovits.cikk.* 
FROM nikovits.cikk;

---=== 2. feladat ===---
/*
A NIKOVITS felhasználó CIKK táblája hány blokkot foglal le az adatbázISban? (ARAMIS)
(VagyIS hány olyan blokk van, ami ehhez a táblához van rENDelve és így
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
(VagyIS a tábla sorai ténylegesen hány blokkban vannak tárolva?)
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
tábláéval és pontosan 128 KB helyet foglal az adatbázISban. Foglaljunk le manuálISan további 
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
        
        SELECT count(DISTINCT substr(ROWID,1,15))
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

---=== 6. feladat ===---
/*
Állapítsuk meg, hogy a SH.SALES táblának a következő adatokkal azonosított sora
(time_id='1998.01.10', prod_id=13, cust_id=2380) melyik adatfájlban van,
azon belül melyik blokkban, és a blokkon belül hányadik a sor?
*/

--A megoldásban használt base64_string_to_dec függvény a házi feladatban van implementálva lentebb.

--Melyik fájl
SELECT file_name
FROM dba_data_files
WHERE file_id = ANY (
    SELECT base64_string_to_dec(substr(ROWID, 7, 3))
    FROM SH.SALES
    WHERE time_id = to_date('1998.01.10', 'yyyy.mm.dd') AND prod_id = 13 AND cust_id = 2380
);

--Azon belül melyik blokk
SELECT base64_string_to_dec(substr(ROWID, 10, 6))
FROM SH.SALES
WHERE time_id = to_date('1998.01.10', 'yyyy.mm.dd') AND prod_id = 13 AND cust_id = 2380;

--Azon belül hanyadik sor
SELECT base64_string_to_dec(substr(ROWID, 16, 3))
FROM SH.SALES
WHERE time_id = to_date('1998.01.10', 'yyyy.mm.dd') AND prod_id = 13 AND cust_id = 2380;

---=== 7. feladat ===---
--Az előző feladatban megadott sor melyik partícióban van?
--Mennyi az objektum azonosítója, és ez milyen objektum?

SELECT partition_name
FROM (
    SELECT *
    FROM dba_extents
    WHERE owner = 'SH' AND segment_name = 'SALES' AND block_id <= ANY (
        SELECT base64_string_to_dec(substr(ROWID, 10, 6))
        FROM SH.SALES
        WHERE time_id = to_date('1998.01.10', 'yyyy.mm.dd') AND prod_id = 13 AND cust_id = 2380
    )
    ORDER BY block_id DESC
)
WHERE ROWNUM = 1;

---=== 8. feladat ===---
--Írjunk meg egy PLSQL procedúrát, amelyik kiírja, hogy a NIKOVITS.TABLA_123 táblának melyik 
--adatblokkjában hány sor van. (file_id, blokk_id, darab)

CREATE OR REPLACE PROCEDURE num_of_rows IS 
    file_name VARCHAR2(300);
    block_id VARCHAR2(300);
BEGIN
    FOR row IN (
        SELECT substr(ROWID, 1, 15) AS rowid_1_15, count(*) AS count
        FROM nikovits.tabla_123
        GROUP BY substr(ROWID, 1, 15)
    ) LOOP
        dbms_output.put_line('file_id: ' ||rpad(base64_string_to_dec(substr(row.rowid_1_15,  7, 3)),  3)||
                            ' blokk_id: '||rpad(base64_string_to_dec(substr(row.rowid_1_15, 10, 6)), 10)||
                            ' darab: '   ||row.count);
    END LOOP;
END;
/
SET SERVEROUTPUT ON
EXECUTE num_of_rows();

/*************************************************/
/**************     Házi feladat      ************/
/*************************************************/
/*
Irjunk meg egy PL/SQL fuggvenyt, ami a  ROWID 64-es kodolasanak megfelelo
szamot adja vissza. A fuggveny parametere egy karakterlanc, eredmenye 
pedig a kodolt numerikus ertek legyen. (Eleg ha a fuggveny maximum 6 
hosszu, helyesen kodolt karakterlancokra mukodik, hosszabb karakterlancra,
vagy rosszul kodolt parameterre adjon vissza -1-et.)
Ennek a fv-nek a segitsegevel adjuk meg egy tablabeli sor pontos fizikai 
elhelyezkedeset. (Melyik fajl, melyik blokk, melyik sora) Peldaul az
ORAUSER.DOLGOZO tabla azon sorara, ahol a dolgozo neve 'KING'.
*/

-- Nem biztos hogy ez volt a feladat.
CREATE FUNCTION base64_char_to_dec(ch VARCHAR2) RETURN NUMBER IS
    c NUMBER := ascii(ch);
    error_code NUMBER := 0;
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
    RETURN error_code;
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
