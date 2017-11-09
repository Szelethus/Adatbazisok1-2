/*************************************************/
/************** Adatbázis objektumok *************/
/**************    (DBA_OBJECTS)     *************/
/*************************************************/

---=== 1. feladat ===---
--Kinek a tulajdonában van a DBA_TABLES nevű nézet (illetve a DUAL nevű tábla)?

SELECT OWNER FROM DBA_VIEWS WHERE VIEW_NAME like 'DBA_TABLES';
SELECT OWNER FROM DBA_TABLES WHERE TABLE_NAME like 'DUAL';

---=== 2. feladat ===---
--Kinek a tulajdonában van a DBA_TABLES nevű szinonima (illetve a DUAL nevű)?
--(Az iménti két lekérdezés megmagyarázza, hogy miért tudjuk elérni őket.)

SELECT OWNER FROM DBA_SYNONYMS WHERE TABLE_NAME like 'DBA_TABLES';
SELECT OWNER FROM DBA_SYNONYMS WHERE TABLE_NAME like 'DUAL';

---=== 3. feladat ===---
--Milyen típusú objektumai vannak az orauser nevű felhasználónak az adatbázisban?

SELECT distinct OBJECT_TYPE FROM DBA_OBJECTS WHERE OWNER like 'ORAUSER';

---=== 4. feladat ===---
--Hány különböző típusú objektum van nyilvántartva az adatbázisban?

SELECT count(distinct OBJECT_TYPE) FROM DBA_OBJECTS;

---=== 5. feladat ===---
--Melyek ezek a típusok?

SELECT distinct OBJECT_TYPE FROM DBA_OBJECTS;

---=== 6. feladat ===---
--Kik azok a felhasználók, akiknek több mint 10 féle objektumuk van?

SELECT OWNER 
FROM DBA_OBJECTS 
GROUP BY OWNER 
HAVING count(distinct OBJECT_TYPE) > 10;

---=== 7. feladat ===---
--Kik azok a felhasználók, akiknek van triggere és nézete is?

SELECT OWNER
FROM DBA_OBJECTS 
WHERE OBJECT_TYPE = 'TRIGGER' OR OBJECT_TYPE = 'VIEW'
GROUP BY OWNER
HAVING count(distinct OBJECT_TYPE) = 2;

---=== 8. feladat ===---
--Kik azok a felhasználók, akiknek van nézete, de nincs triggere?

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
--Kik azok a felhasználók, akiknek több mint 40 táblájuk, de maximum 37 indexük van?

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
--Melyek azok az objektum típusok, amelyek tényleges tárolást igényelnek, vagyis
--tartoznak hozzájuk adatblokkok? (A többinek csak a definíciója tárolódik adatszótárban)

SELECT distinct object_type 
FROM dba_objects 
WHERE data_object_id is not null;

---=== 11. feladat ===---
--Melyek azok az objektum típusok, amelyek nem igényelnek tényleges tárolást, vagyis nem
--tartoznak hozzájuk adatblokkok? (Ezeknek csak a definíciója tárolódik adatszótárban)

SELECT distinct object_type 
FROM dba_objects 
WHERE data_object_id is null;

---=== Bónusz ===---
--Az utóbbi két lekérdezés metszete nem üres. Vajon miért? -> lásd majd partícionálás

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
/************     Táblák oszlopai      ***********/
/************    (DBA_TAB_COLUMNS)     ***********/
/*************************************************/

---=== 1. feladat ===---
--Hány oszlopa van a nikovits.emp táblának?

SELECT count(*)
FROM DBA_TAB_COLUMNS
WHERE OWNER = 'NIKOVITS' AND TABLE_NAME = 'EMP';

---=== 2. feladat ===---
--Milyen típusú a nikovits.emp tábla 6. oszlopa?

SELECT DATA_TYPE
FROM DBA_TAB_COLUMNS
WHERE OWNER = 'NIKOVITS' AND TABLE_NAME = 'EMP' AND COLUMN_ID = 6;

---=== 3. feladat ===---
--Adjuk meg azoknak a tábláknak a tulajdonosát és nevét, amelyeknek van 'Z' betűvel 
--kezdődő oszlopa.

SELECT distinct OWNER, TABLE_NAME
FROM DBA_TAB_COLUMNS
WHERE TABLE_NAME LIKE 'Z%';

---=== 4. feladat ===---
--Adjuk meg azoknak a tábláknak a nevét, amelyeknek legalább 8 darab dátum tipusú oszlopa van.

SELECT TABLE_NAME
FROM DBA_TAB_COLUMNS
WHERE DATA_TYPE = 'DATE'
GROUP BY TABLE_NAME
HAVING count(DATA_TYPE) >= 8;

---=== 5. feladat ===---
-- Adjuk meg azoknak a tábláknak a nevét, amelyeknek 1. es 4. oszlopa is VARCHAR2 tipusú.

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
--Írjunk meg egy PLSQL procedúrát, amelyik a paraméterül kapott karakterlánc alapján 
--kiírja azoknak a tábláknak a nevét és tulajdonosát, amelyek az adott karakterlánccal 
--kezdődnek. (Ha a paraméter kisbetűs, akkor is működjön a procedúra!)
--A fenti procedúra segítségével írjuk ki a Z betűvel kezdődő táblák nevét és tulajdonosát.

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
/**************     Házi feladat      ************/
/*************************************************/

/*
Írjunk meg egy plsql procedúrát, amelyik a paraméterül kapott táblára kiírja 
az őt létrehozó CREATE TABLE utasítást. 
  PROCEDURE cr_tab(p_owner VARCHAR2, p_tabla VARCHAR2) 
Elég ha az oszlopok típusát és DEFAULT értékeit kíírja, és elég ha a következő típusú 
oszlopokra működik.
  CHAR, VARCHAR2, NCHAR, NVARCHAR2, BLOB, CLOB, NCLOB, NUMBER, FLOAT, BINARY_FLOAT, DATE, ROWID
*/

CREATE OR REPLACE PROCEDURE cr_tab(p_owner VARCHAR2, p_tabla VARCHAR2) IS
BEGIN
    dbms_output.put_line('CREATE TABLE ' || p_tabla ||'(');
    
--Fontos megjegyzés: 'ORA-00997: illegal use of LONG datatype' error ugrik fel, ha 
--'distinct' kulcsszó és 'data_default' is szerepel a 'dba_tab_columns' tábla lekérdezésekor.
--A 'distinct'-et ilyenkor törölni kell.

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

--Teszteljük a procedúrát az alábbi táblával.
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

DROP TABLE tipus_proba;