/*************************************************/
/**********       Egyéb objektumok       *********/
/**********  (DBA_SYNONYMS, DBA_VIEWS,   *********/
/********** DBA_SEQUENCES, DBA_DB_LINKS) *********/   
/*************************************************/

---=== 1. feladat ===---
/*
Adjuk ki az alábbi utasítást (ARAMIS adatbázisban)
  SELECT * FROM sz1;
majd derítsük ki, hogy kinek melyik tábláját kérdeztük le. 
(Ha esetleg nézettel találkozunk, azt is fejtsük ki, hogy az mit kérdez le.)
*/

SELECT owner, object_name, object_type
FROM dba_objects
WHERE object_name = 'SZ1';
--Kiderítettük, hogy SZ1 egy synonym

SELECT table_name
FROM dba_synonyms
WHERE synonym_name = 'SZ1';
--Kiderítettük, hogy V1-re mutat

SELECT text
FROM dba_views
WHERE view_name = 'V1';

---=== 2. feladat ===---
/*
Hozzunk létre egy szekvenciát, amelyik az osztály azonosítókat fogja generálni
a számunkra. Minden osztály azonosító a 10-nek többszöröse legyen.
Vigyünk fel 3 új osztályt és osztályonként minimum 3 dolgozót a táblákba. 
Az osztály azonosítókat a szekvencia segítségével állítsuk elő, és ezt tegyük
be a táblába. (Vagyis ne kézzel írjuk be a 10, 20, 30 ... stb. azonosítót.)
A felvitel után módosítsuk a 10-es osztály azonosítóját a következő érvényes (generált)
osztály azonosítóra. (Itt is a szekvencia segítségével adjuk meg, hogy mi lesz a 
következő azonosító.) A 10-es osztály dolgozóinak az osztályazonosító ertékét is 
módosítsuk az új értékre.
*/

CREATE SEQUENCE class_id_seq
    START WITH   50
    INCREMENT BY 10
    NOCACHE
    NOCYCLE;
    
CREATE TABLE husi_osztaly AS SELECT * FROM nikovits.osztaly;
CREATE TABLE husi_dolgozo AS SELECT * FROM nikovits.dolgozo;

BEGIN
    FOR i IN 1..3 LOOP
        INSERT INTO husi_osztaly
        (oazon)
        VALUES
        (class_id_seq.nextval);
    END LOOP;
    
    UPDATE husi_osztaly
    SET oazon = class_id_seq.nextval
    WHERE oazon = 10;
    
    UPDATE husi_dolgozo
    SET oazon = class_id_seq.currval
    WHERE oazon = 10;
END;
/

drop sequence class_id_seq;
drop table husi_osztaly;
drop table husi_dolgozo;

---=== 3. feladat ===---
/*
Hozzunk létre adatbázis-kapcsolót (database link) a GRID97 adatbázisban,
amelyik a másik (ARAMIS) adatbázisra mutat. 
CREATE DATABASE LINK aramis CONNECT TO felhasznalo IDENTIFIED BY jelszo
USING 'aramis';
Ennek segítségével adjuk meg a következő lekérdezéseket. 
A lekérdezések alapjául szolgáló táblák:

NIKOVITS.VILAG_ORSZAGAI   GRID97 adatbázis
NIKOVITS.FOLYOK           ARAMIS adatbázis

Az országok egyedi azonosítója a TLD (Top Level Domain) oszlop.
Az ország hivatalos nyelveit vesszőkkel elválasztva a NYELV oszlop tartalmazza.
A GDP (Gross Domestic Product -> hazai bruttó össztermék) dollárban van megadva.
A folyók egyedi azonosítója a NEV oszlop.
A folyók vízhozama m3/s-ban van megadva, a vízgyűjtő területük km2-ben.
A folyó által érintett országok azonosítóit (TLD) a forrástól a torkolatig 
(megfelelő sorrendben vesszőkkel elválasztva) az ORSZAGOK oszlop tartalmazza.
A FORRAS_ORSZAG és TORKOLAT_ORSZAG hasonló módon a megfelelő országok azonosítóit
tartalmazza. (Vigyázat!!! egy folyó torkolata országhatárra is eshet, pl. Duna)


- Adjuk meg azoknak az országoknak a nevét, amelyeket a Mekong nevű folyó érint.

-* Adjuk meg azoknak az országoknak a nevét, amelyeket a Mekong nevű folyó érint.
   Most az országok nevét a megfelelő sorrendben (folyásirányban) adjuk meg.
*/

--GRID97 még mindig nem müxik :'(

/*******************************************************************/
/***              Adattárolással kapcsolatos fogalmak            ***/
/***         (DBA_TABLES, DBA_DATA_FILES, DBA_TEMP_FILES,        ***/
/*** DBA_TABLESPACES, DBA_SEGMENTS, DBA_EXTENTS, DBA_FREE_SPACE) ***/
/*******************************************************************/

---=== 1. feladat ===---
--Adjuk meg az adatbázishoz tartozó adatfile-ok (és temporális fájlok) nevét és méretét
--méret szerint csökkenő sorrendben.

SELECT file_name, bytes
FROM dba_data_files
ORDER BY bytes DESC;

---=== 2. feladat ===---
/*
Adjuk meg, hogy milyen tablaterek vannak letrehozva az adatbazisban,
az egyes tablaterek hany adatfajlbol allnak, es mekkora az osszmeretuk.
(tablater_nev, fajlok_szama, osszmeret)
!!! Vigyázat, van temporális táblatér is.
*/

(
    SELECT tablespace_name, count(file_name) AS number_of_files, sum(bytes)
    FROM DBA_DATA_FILES
    GROUP BY tablespace_name
)
UNION
(
    SELECT tablespace_name, count(file_name) AS number_of_files, sum(bytes)
    FROM DBA_TEMP_FILES
    GROUP BY tablespace_name
);

---=== 3. feladat ===---
--Mekkora az adatblokkok merete a USERS táblatéren?

SELECT block_size
FROM dba_tablespaces
WHERE tablespace_name = 'USERS';

---=== 4. feladat ===---
--Van-e olyan táblatér, amelynek nincs DBA_DATA_FILES-beli adatfájlja?
--Ennek adatai hol tárolódnak? -> DBA_TEMP_FILES

select tablespace_name from dba_tablespaces where tablespace_name not in (select distinct tablespace_name from dba_data_files); //ha ennek van visszateresi erteke, akkor igen

---=== 5. feladat ===---
--Melyik a legnagyobb méretű tábla szegmens az adatbázisban (a tulajdonost is adjuk meg) 
--és hány extensből áll? (A particionált táblákat most ne vegyük figyelembe.)

--Legnagyobb méret vajon mire utal? A megoldás hasonló akkor is, ha nem byte-ra, hanem extensre gondolt.

SELECT owner, segment_name, extents
FROM (
    SELECT owner, segment_name, extents
    FROM dba_segments
    ORDER BY bytes DESC
)
WHERE rownum = 1;

---=== 6. feladat ===---
--Melyik a legnagyobb meretű index szegmens az adatbázisban és hány blokkból áll?
--(A particionalt indexeket most ne vegyuk figyelembe.)

SELECT owner, segment_name, blocks
FROM (
    SELECT owner, segment_name, blocks
    FROM dba_segments
    WHERE segment_type = 'INDEX'
    ORDER BY bytes DESC
)
WHERE rownum = 1;

---=== 7. feldat ===---
--Adjuk meg adatfájlonkent, hogy az egyes adatfájlokban mennyi a foglalt 
--hely osszesen (írassuk ki a fájlok méretét is).

--Nem vagyok benne biztos hogy jól értelmeztem a feladatot

SELECT file_name, bytes AS occupied_space
FROM dba_data_files;

---=== 8. feladat ===---
--Melyik ket felhasznalo objektumai foglalnak osszesen a legtobb helyet az adatbazisban?
--Vagyis ki foglal a legtöbb helyet, és ki a második legtöbbet?

SELECT owner, allocated_space
FROM (
    SELECT owner, sum(bytes) AS allocated_space
    FROM dba_segments
    GROUP BY owner
    ORDER BY sum(bytes) DESC
)
WHERE rownum <= 2;

---=== 9. feladat ===---
--Hány extens van a 'users01.dbf' adatfájlban? Mekkora ezek összmérete?

SELECT sum(extents)
FROM dba_data_files f CROSS JOIN dba_segments s
WHERE file_name LIKE '%users01.dbf' AND f.tablespace_name = s.tablespace_name
GROUP BY file_name;

---=== 10. feladat ===---
--Hány összefüggő szabad terület van a 'users01.dbf' adatfájlban? Mekkora ezek összmérete?

SELECT count(*), sum(s.bytes)
FROM dba_data_files f CROSS JOIN dba_free_space s
WHERE file_name LIKE '%users01.dbf' AND f.tablespace_name = s.tablespace_name
GROUP BY file_name;

---=== 11. feladat ===---
--Hány százalékban foglalt a 'users01.dbf' adatfájl?

--Amennyiben arra gondolt hogy a max méret a MAXBYTES oszlop
SELECT trunc(bytes / maxbytes * 100, 2) AS used_percentage
FROM dba_data_files
WHERE file_name LIKE '%users01.dbf';

--Amennyiben arra gondolt hogy a max méret az amit korábban kiszámoltunk oszlop
SELECT trunc(bytes / (bytes + (
    SELECT sum(s.bytes)
    FROM dba_data_files f CROSS JOIN dba_free_space s
    WHERE file_name LIKE '%users01.dbf' AND f.tablespace_name = s.tablespace_name
    GROUP BY file_name
))* 100, 2) AS used_percentage
FROM dba_data_files
WHERE file_name LIKE '%users01.dbf';

---=== 12. feladat ===---
--Van-e a NIKOVITS felhasználónak olyan táblája, amelyik több adatfájlban is foglal helyet? (Aramis)

SELECT segment_name, count( distinct file_id)
FROM dba_extents
WHERE owner = 'NIKOVITS' AND segment_type = 'TABLE'
GROUP BY segment_name
HAVING count( distinct file_id ) > 1;

---=== 13. feladat ===---
--Válasszunk ki a fenti táblákból egyet (pl. tabla_123) és adjuk meg, hogy ez a 
--tábla mely adatfájlokban foglal helyet.

SELECT distinct file_name
FROM dba_extents e CROSS JOIN dba_data_files f
WHERE segment_name = 'TABLA_123' AND owner = 'NIKOVITS' AND segment_type = 'TABLE' AND e.file_id = f.file_id;

---=== 14. feladat ===---
--Melyik táblatéren van az ORAUSER felhasználó dolgozo táblája?

SELECT tablespace_name
FROM dba_tables
WHERE owner = 'ORAUSER' AND table_name = 'DOLGOZO';

---=== 15. feladat ===---
--Melyik táblatéren van a NIKOVITS felhasználó ELADASOK táblája? (Miért lesz null?)

SELECT tablespace_name
FROM dba_tables
WHERE owner = 'NIKOVITS' AND table_name = 'ELADASOK';
--nem tudom a választ :D

---=== 16. feladat ===---
--Írjunk meg egy PLSQL procedúrát, amelyik a paraméterül kapott felhasználónévre kiírja 
--a felhasználó legrégebben létrehozott tábláját, annak méretét byte-okban, valamint a létrehozás
--dátumat.

CREATE OR REPLACE PROCEDURE regi_tabla(p_user VARCHAR2) IS 
    CURSOR curs IS
            SELECT object_name, created
            FROM dba_objects
            WHERE object_type = 'TABLE' AND owner = upper(p_user)
            ORDER BY created ASC;
    rec curs%ROWTYPE;
    
    occupied_bytes NUMBER;
BEGIN
    OPEN curs;
    FETCH curs INTO rec;
    IF curs%NOTFOUND THEN
    
        SELECT bytes INTO occupied_bytes
        FROM dba_segments
        WHERE owner = upper(p_user) AND segment_name = rec.object_name;

        dbms_output.put_line(rec.object_name||' '||rec.created||' '||occupied_bytes);
    END IF;
    CLOSE curs;
END;
/

SET SERVEROUTPUT ON
EXECUTE regi_tabla('nikovits'); --works pretty well
EXECUTE regi_tabla('pw9yik'); --FUCKING CUNT PIECE OF SHIT
