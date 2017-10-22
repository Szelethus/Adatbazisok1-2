/*************************************************/
/**********       Egy�b objektumok       *********/
/**********  (DBA_SYNONYMS, DBA_VIEWS,   *********/
/********** DBA_SEQUENCES, DBA_DB_LINKS) *********/   
/*************************************************/

---=== 1. feladat ===---
/*
Adjuk ki az al�bbi utas�t�st (ARAMIS adatb�zisban)
  SELECT * FROM sz1;
majd der�ts�k ki, hogy kinek melyik t�bl�j�t k�rdezt�k le. 
(Ha esetleg n�zettel tal�lkozunk, azt is fejts�k ki, hogy az mit k�rdez le.)
*/

SELECT owner, object_name, object_type
FROM dba_objects
WHERE object_name = 'SZ1';
--Kider�tett�k, hogy SZ1 egy synonym

SELECT table_name
FROM dba_synonyms
WHERE synonym_name = 'SZ1';
--Kider�tett�k, hogy V1-re mutat

SELECT text
FROM dba_views
WHERE view_name = 'V1';

---=== 2. feladat ===---
/*
Hozzunk l�tre egy szekvenci�t, amelyik az oszt�ly azonos�t�kat fogja gener�lni
a sz�munkra. Minden oszt�ly azonos�t� a 10-nek t�bbsz�r�se legyen.
Vigy�nk fel 3 �j oszt�lyt �s oszt�lyonk�nt minimum 3 dolgoz�t a t�bl�kba. 
Az oszt�ly azonos�t�kat a szekvencia seg�ts�g�vel �ll�tsuk el�, �s ezt tegy�k
be a t�bl�ba. (Vagyis ne k�zzel �rjuk be a 10, 20, 30 ... stb. azonos�t�t.)
A felvitel ut�n m�dos�tsuk a 10-es oszt�ly azonos�t�j�t a k�vetkez� �rv�nyes (gener�lt)
oszt�ly azonos�t�ra. (Itt is a szekvencia seg�ts�g�vel adjuk meg, hogy mi lesz a 
k�vetkez� azonos�t�.) A 10-es oszt�ly dolgoz�inak az oszt�lyazonos�t� ert�k�t is 
m�dos�tsuk az �j �rt�kre.
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
Hozzunk l�tre adatb�zis-kapcsol�t (database link) a GRID97 adatb�zisban,
amelyik a m�sik (ARAMIS) adatb�zisra mutat. 
CREATE DATABASE LINK aramis CONNECT TO felhasznalo IDENTIFIED BY jelszo
USING 'aramis';
Ennek seg�ts�g�vel adjuk meg a k�vetkez� lek�rdez�seket. 
A lek�rdez�sek alapj�ul szolg�l� t�bl�k:

NIKOVITS.VILAG_ORSZAGAI   GRID97 adatb�zis
NIKOVITS.FOLYOK           ARAMIS adatb�zis

Az orsz�gok egyedi azonos�t�ja a TLD (Top Level Domain) oszlop.
Az orsz�g hivatalos nyelveit vessz�kkel elv�lasztva a NYELV oszlop tartalmazza.
A GDP (Gross Domestic Product -> hazai brutt� �sszterm�k) doll�rban van megadva.
A foly�k egyedi azonos�t�ja a NEV oszlop.
A foly�k v�zhozama m3/s-ban van megadva, a v�zgy�jt� ter�let�k km2-ben.
A foly� �ltal �rintett orsz�gok azonos�t�it (TLD) a forr�st�l a torkolatig 
(megfelel� sorrendben vessz�kkel elv�lasztva) az ORSZAGOK oszlop tartalmazza.
A FORRAS_ORSZAG �s TORKOLAT_ORSZAG hasonl� m�don a megfelel� orsz�gok azonos�t�it
tartalmazza. (Vigy�zat!!! egy foly� torkolata orsz�ghat�rra is eshet, pl. Duna)


- Adjuk meg azoknak az orsz�goknak a nev�t, amelyeket a Mekong nev� foly� �rint.

-* Adjuk meg azoknak az orsz�goknak a nev�t, amelyeket a Mekong nev� foly� �rint.
   Most az orsz�gok nev�t a megfelel� sorrendben (foly�sir�nyban) adjuk meg.
*/

--GRID97 m�g mindig nem m�xik :'(

/*******************************************************************/
/***              Adatt�rol�ssal kapcsolatos fogalmak            ***/
/***         (DBA_TABLES, DBA_DATA_FILES, DBA_TEMP_FILES,        ***/
/*** DBA_TABLESPACES, DBA_SEGMENTS, DBA_EXTENTS, DBA_FREE_SPACE) ***/
/*******************************************************************/

---=== 1. feladat ===---
--Adjuk meg az adatb�zishoz tartoz� adatfile-ok (�s tempor�lis f�jlok) nev�t �s m�ret�t
--m�ret szerint cs�kken� sorrendben.

SELECT file_name, bytes
FROM dba_data_files
ORDER BY bytes DESC;

---=== 2. feladat ===---
/*
Adjuk meg, hogy milyen tablaterek vannak letrehozva az adatbazisban,
az egyes tablaterek hany adatfajlbol allnak, es mekkora az osszmeretuk.
(tablater_nev, fajlok_szama, osszmeret)
!!! Vigy�zat, van tempor�lis t�blat�r is.
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
--Mekkora az adatblokkok merete a USERS t�blat�ren?

SELECT block_size
FROM dba_tablespaces
WHERE tablespace_name = 'USERS';

---=== 4. feladat ===---
--Van-e olyan t�blat�r, amelynek nincs DBA_DATA_FILES-beli adatf�jlja?
--Ennek adatai hol t�rol�dnak? -> DBA_TEMP_FILES

--van :D Ez azt�n egy neh�z feladato volt

---=== 5. feladat ===---
--Melyik a legnagyobb m�ret� t�bla szegmens az adatb�zisban (a tulajdonost is adjuk meg) 
--�s h�ny extensb�l �ll? (A particion�lt t�bl�kat most ne vegy�k figyelembe.)

--Legnagyobb m�ret vajon mire utal? A megold�s hasonl� akkor is, ha nem byte-ra, hanem extensre gondolt.

SELECT owner, segment_name, extents
FROM (
    SELECT owner, segment_name, extents
    FROM dba_segments
    ORDER BY bytes DESC
)
WHERE rownum = 1;

---=== 6. feladat ===---
--Melyik a legnagyobb meret� index szegmens az adatb�zisban �s h�ny blokkb�l �ll?
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
--Adjuk meg adatf�jlonkent, hogy az egyes adatf�jlokban mennyi a foglalt 
--hely osszesen (�rassuk ki a f�jlok m�ret�t is).

--Nem vagyok benne biztos hogy j�l �rtelmeztem a feladatot

SELECT file_name, bytes AS occupied_space
FROM dba_data_files;

---=== 8. feladat ===---
--Melyik ket felhasznalo objektumai foglalnak osszesen a legtobb helyet az adatbazisban?
--Vagyis ki foglal a legt�bb helyet, �s ki a m�sodik legt�bbet?

SELECT owner, allocated_space
FROM (
    SELECT owner, sum(bytes) AS allocated_space
    FROM dba_segments
    GROUP BY owner
    ORDER BY sum(bytes) DESC
)
WHERE rownum <= 2;

---=== 9. feladat ===---
--H�ny extens van a 'users01.dbf' adatf�jlban? Mekkora ezek �sszm�rete?

SELECT sum(extents)
FROM dba_data_files f CROSS JOIN dba_segments s
WHERE file_name LIKE '%users01.dbf' AND f.tablespace_name = s.tablespace_name
GROUP BY file_name;

---=== 10. feladat ===---
--H�ny �sszef�gg� szabad ter�let van a 'users01.dbf' adatf�jlban? Mekkora ezek �sszm�rete?

SELECT count(*), sum(s.bytes)
FROM dba_data_files f CROSS JOIN dba_free_space s
WHERE file_name LIKE '%users01.dbf' AND f.tablespace_name = s.tablespace_name
GROUP BY file_name;

---=== 11. feladat ===---
--H�ny sz�zal�kban foglalt a 'users01.dbf' adatf�jl?

--Amennyiben arra gondolt hogy a max m�ret a MAXBYTES oszlop
SELECT trunc(bytes / maxbytes * 100, 2) AS used_percentage
FROM dba_data_files
WHERE file_name LIKE '%users01.dbf';

--Amennyiben arra gondolt hogy a max m�ret az amit kor�bban kisz�moltunk oszlop
SELECT trunc(bytes / (bytes + (
    SELECT sum(s.bytes)
    FROM dba_data_files f CROSS JOIN dba_free_space s
    WHERE file_name LIKE '%users01.dbf' AND f.tablespace_name = s.tablespace_name
    GROUP BY file_name
))* 100, 2) AS used_percentage
FROM dba_data_files
WHERE file_name LIKE '%users01.dbf';

---=== 12. feladat ===---
--Van-e a NIKOVITS felhaszn�l�nak olyan t�bl�ja, amelyik t�bb adatf�jlban is foglal helyet? (Aramis)

SELECT segment_name, count( distinct file_id)
FROM dba_extents
WHERE owner = 'NIKOVITS' AND segment_type = 'TABLE'
GROUP BY segment_name
HAVING count( distinct file_id ) > 1;

---=== 13. feladat ===---
--V�lasszunk ki a fenti t�bl�kb�l egyet (pl. tabla_123) �s adjuk meg, hogy ez a 
--t�bla mely adatf�jlokban foglal helyet.

SELECT distinct file_name
FROM dba_extents e CROSS JOIN dba_data_files f
WHERE segment_name = 'TABLA_123' AND owner = 'NIKOVITS' AND segment_type = 'TABLE' AND e.file_id = f.file_id;

---=== 14. feladat ===---
--Melyik t�blat�ren van az ORAUSER felhaszn�l� dolgozo t�bl�ja?

SELECT tablespace_name
FROM dba_tables
WHERE owner = 'ORAUSER' AND table_name = 'DOLGOZO';

---=== 15. feladat ===---
--Melyik t�blat�ren van a NIKOVITS felhaszn�l� ELADASOK t�bl�ja? (Mi�rt lesz null?)

SELECT tablespace_name
FROM dba_tables
WHERE owner = 'NIKOVITS' AND table_name = 'ELADASOK';
--nem tudom a v�laszt :D

---=== 16. feladat ===---
--�rjunk meg egy PLSQL proced�r�t, amelyik a param�ter�l kapott felhaszn�l�n�vre ki�rja 
--a felhaszn�l� legr�gebben l�trehozott t�bl�j�t, annak m�ret�t byte-okban, valamint a l�trehoz�s
--d�tumat.

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