/*************************************************/
/************** Adatb�zis objektumok *************/
/**************    (DBA_OBJECTS)     *************/
/*************************************************/

---=== 1. feladat ===---
--Kinek a tulajdon�ban van a DBA_TABLES nev� n�zet (illetve a DUAL nev� t�bla)?

SELECT OWNER FROM DBA_VIEWS WHERE VIEW_NAME like 'DBA_TABLES';
SELECT OWNER FROM DBA_TABLES WHERE TABLE_NAME like 'DUAL';

---=== 2. feladat ===---
--Kinek a tulajdon�ban van a DBA_TABLES nev� szinonima (illetve a DUAL nev�)?
--(Az im�nti k�t lek�rdez�s megmagyar�zza, hogy mi�rt tudjuk el�rni �ket.)

SELECT OWNER FROM DBA_SYNONYMS WHERE TABLE_NAME like 'DBA_TABLES';
SELECT OWNER FROM DBA_SYNONYMS WHERE TABLE_NAME like 'DUAL';

---=== 3. feladat ===---
--Milyen t�pus� objektumai vannak az orauser nev� felhaszn�l�nak az adatb�zisban?

SELECT distinct OBJECT_TYPE FROM DBA_OBJECTS WHERE OWNER like 'ORAUSER';

---=== 4. feladat ===---
--H�ny k�l�nb�z� t�pus� objektum van nyilv�ntartva az adatb�zisban?

SELECT count(distinct OBJECT_TYPE) FROM DBA_OBJECTS;

---=== 5. feladat ===---
--Melyek ezek a t�pusok?

SELECT distinct OBJECT_TYPE FROM DBA_OBJECTS;

---=== 6. feladat ===---
--Kik azok a felhaszn�l�k, akiknek t�bb mint 10 f�le objektumuk van?

SELECT OWNER 
FROM DBA_OBJECTS 
GROUP BY OWNER 
HAVING count(distinct OBJECT_TYPE) > 10;

---=== 7. feladat ===---
--Kik azok a felhaszn�l�k, akiknek van triggere �s n�zete is?

SELECT OWNER
FROM DBA_OBJECTS 
WHERE OBJECT_TYPE = 'TRIGGER' OR OBJECT_TYPE = 'VIEW'
GROUP BY OWNER
HAVING count(distinct OBJECT_TYPE) = 2;

---=== 8. feladat ===---
--Kik azok a felhaszn�l�k, akiknek van n�zete, de nincs triggere?

(
    SELECT OWNER
    FROM DBA_OBJECTS 
    WHERE OBJECT_TYPE = 'TRIGGER' OR OBJECT_TYPE = 'VIEW'
    GROUP BY OWNER
    HAVING count(distinct OBJECT_TYPE) = 2
)
MINUS
(
    SELECT OWNER
    FROM DBA_OBJECTS 
    WHERE OBJECT_TYPE = 'TRIGGER'
    GROUP BY OWNER
);

---=== 9. feladat ===---
--Kik azok a felhaszn�l�k, akiknek t�bb mint 40 t�bl�juk, de maximum 37 index�k van?

(
    SELECT OWNER
    FROM DBA_OBJECTS
    WHERE OBJECT_TYPE = 'TABLE'
    GROUP BY OWNER
    HAVING count(OBJECT_TYPE) > 40
)
INTERSECT
(
    SELECT OWNER
    FROM DBA_OBJECTS
    WHERE OBJECT_TYPE = 'INDEX'
    GROUP BY OWNER
    HAVING count(OBJECT_TYPE) <= 37
);

---=== 10. feladat ===---
--Melyek azok az objektum t�pusok, amelyek t�nyleges t�rol�st ig�nyelnek, vagyis
--tartoznak hozz�juk adatblokkok? (A t�bbinek csak a defin�ci�ja t�rol�dik adatsz�t�rban)

SELECT distinct object_type 
FROM dba_objects 
WHERE data_object_id is not null;

---=== 11. feladat ===---
--Melyek azok az objektum t�pusok, amelyek nem ig�nyelnek t�nyleges t�rol�st, vagyis nem
--tartoznak hozz�juk adatblokkok? (Ezeknek csak a defin�ci�ja t�rol�dik adatsz�t�rban)

SELECT distinct object_type 
FROM dba_objects 
WHERE data_object_id is null;

---=== B�nusz ===---
--Az ut�bbi k�t lek�rdez�s metszete nem �res. Vajon mi�rt? -> l�sd majd part�cion�l�s

(
    SELECT distinct object_type 
    FROM dba_objects 
    WHERE data_object_id is not null
)
INTERSECT
(
    SELECT distinct object_type 
    FROM dba_objects 
    WHERE data_object_id is  null
);

/*************************************************/
/************     T�bl�k oszlopai      ***********/
/************    (DBA_TAB_COLUMNS)     ***********/
/*************************************************/

---=== 1. feladat ===---
--H�ny oszlopa van a nikovits.emp t�bl�nak?

SELECT count(*)
FROM DBA_TAB_COLUMNS
WHERE OWNER = 'NIKOVITS' AND TABLE_NAME = 'EMP';

---=== 2. feladat ===---
--Milyen t�pus� a nikovits.emp t�bla 6. oszlopa?

SELECT DATA_TYPE
FROM DBA_TAB_COLUMNS
WHERE OWNER = 'NIKOVITS' AND TABLE_NAME = 'EMP' AND COLUMN_ID = 6;

---=== 3. feladat ===---
--Adjuk meg azoknak a t�bl�knak a tulajdonos�t �s nev�t, amelyeknek van 'Z' bet�vel 
--kezd�d� oszlopa.

SELECT distinct OWNER, TABLE_NAME
FROM DBA_TAB_COLUMNS
WHERE TABLE_NAME LIKE 'Z%';

---=== 4. feladat ===---
--Adjuk meg azoknak a t�bl�knak a nev�t, amelyeknek legal�bb 8 darab d�tum tipus� oszlopa van.

SELECT TABLE_NAME
FROM DBA_TAB_COLUMNS
WHERE DATA_TYPE = 'DATE'
GROUP BY TABLE_NAME
HAVING count(DATA_TYPE) >= 8;

---=== 5. feladat ===---
-- Adjuk meg azoknak a t�bl�knak a nev�t, amelyeknek 1. es 4. oszlopa is VARCHAR2 tipus�.

(
    SELECT TABLE_NAME
    FROM DBA_TAB_COLUMNS
    WHERE COLUMN_ID = 1 AND DATA_TYPE = 'VARCHAR2'
)
UNION
(
    SELECT TABLE_NAME
    FROM DBA_TAB_COLUMNS
    WHERE COLUMN_ID = 4 AND DATA_TYPE = 'VARCHAR2'
);

---=== 4. feladat ===---
--�rjunk meg egy PLSQL proced�r�t, amelyik a param�ter�l kapott karakterl�nc alapj�n 
--ki�rja azoknak a t�bl�knak a nev�t �s tulajdonos�t, amelyek az adott karakterl�nccal 
--kezd�dnek. (Ha a param�ter kisbet�s, akkor is m�k�dj�n a proced�ra!)
--A fenti proced�ra seg�ts�g�vel �rjuk ki a Z bet�vel kezd�d� t�bl�k nev�t �s tulajdonos�t.

CREATE OR REPLACE PROCEDURE table_print(p_kar VARCHAR2) IS
    CURSOR curs1 IS select owner, table_name 
                    from dba_tables
                    where table_name like upper(p_kar)||'%';
    rec curs1%ROWTYPE;
BEGIN
    OPEN curs1;
    LOOP
        FETCH curs1 INTO rec;
        EXIT WHEN curs1%NOTFOUND;
        dbms_output.put_line(to_char(rec.owner)||' - '||rec.table_name);
    END LOOP;
    CLOSE curs1;
END;
/

SET SERVEROUTPUT ON
EXECUTE table_print('Z');

/*************************************************/
/**************     H�zi feladat      ************/
/*************************************************/

/*
�rjunk meg egy plsql proced�r�t, amelyik a param�ter�l kapott t�bl�ra ki�rja 
az �t l�trehoz� CREATE TABLE utas�t�st. 
  PROCEDURE cr_tab(p_owner VARCHAR2, p_tabla VARCHAR2) 
El�g ha az oszlopok t�pus�t �s DEFAULT �rt�keit k��rja, �s el�g ha a k�vetkez� t�pus� 
oszlopokra m�k�dik.
  CHAR, VARCHAR2, NCHAR, NVARCHAR2, BLOB, CLOB, NCLOB, NUMBER, FLOAT, BINARY_FLOAT, DATE, ROWID
*/

CREATE OR REPLACE PROCEDURE cr_tab(p_owner VARCHAR2, p_tabla VARCHAR2) IS
BEGIN
    dbms_output.put_line('CREATE TABLE ' || p_tabla ||'(');
    
--Fontos megjegyz�s: 'ORA-00997: illegal use of LONG datatype' error ugrik fel, ha 
--'distinct' kulcssz� �s 'data_default' is szerepel a 'dba_tab_columns' t�bla lek�rdez�sekor.
--A 'distinct'-et ilyenkor t�r�lni kell.

    FOR rec IN (
        select column_name, data_type, data_default, data_length
        from dba_tab_columns
        where owner = upper(p_owner) AND table_name = upper(p_tabla)
    ) LOOP
        dbms_output.put(rpad(' ', 4)||rpad(rec.column_name, 15)||rec.data_type||'('||rec.data_length||')');
        IF rec.data_default IS NOT NULL THEN
            dbms_output.put(' DEFAULT '||to_char(rec.data_default));
        END IF;
        dbms_output.put_line(',');
    END LOOP;
    
    dbms_output.put_line(');');
END;
/

--Tesztelj�k a proced�r�t az al�bbi t�bl�val.
CREATE TABLE tipus_proba(
    c10 CHAR(10) DEFAULT 'bubu', 
    vc20 VARCHAR2(20), 
    nc10 NCHAR(10), 
    nvc15 NVARCHAR2(15), 
    blo BLOB, 
    clo CLOB, 
    nclo NCLOB, 
    num NUMBER, 
    num10_2 NUMBER(10,2), 
    num10 NUMBER(10) DEFAULT 100, 
    flo FLOAT, 
    bin_flo binary_float DEFAULT '2e+38', 
    bin_doub binary_double DEFAULT 2e+40,
    dat DATE DEFAULT TO_DATE('2007.01.01', 'yyyy.mm.dd'), 
    rid ROWID
);

set serveroutput on;
execute cr_tab('pw9yik', 'tipus_proba');