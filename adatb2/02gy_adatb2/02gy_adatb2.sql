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