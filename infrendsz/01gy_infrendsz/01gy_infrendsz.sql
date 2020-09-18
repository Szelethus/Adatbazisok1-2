/*===------------------------------===*/
/*===---------- Triggerek ---------===*/
/*===------------------------------===*/

---=== 1. feladat ===---
/*
Az ORAUSER nevű oracle felhasználó tulajdonában van egy DOLGOZO nevű
tábla. Hozzunk létre a saját sémánkban egy azonos nevű és tartalmú táblát,
valamint egy TRIGGER_LOG nevű táblát, aminek a következő a szerkezete:
     (  idopont    DATE,
        muvelet    VARCHAR2(20),
        esemeny    VARCHAR2(80)   
     )
*/

-- A couple sanity checks.

SELECT *
FROM DBA_TABLES
WHERE (OWNER like 'ORAUSER') AND (TABLE_NAME like 'DOLGOZO');

SELECT * FROM ORAUSER.DOLGOZO;

-- Copy the table.

DROP TABLE DOLGOZO;
CREATE TABLE DOLGOZO AS SELECT * FROM ORAUSER.DOLGOZO;

SELECT * FROM PW9YIK.DOLGOZO;

-- Create the TRIGGER_LOG table.

DROP TABLE TRIGGER_LOG;
CREATE TABLE TRIGGER_LOG(
    idopont    DATE,
    muvelet    VARCHAR2(20),
    esemeny    VARCHAR2(80)
);

SELECT * FROM TRIGGER_LOG;

/*
Hozzunk létre egy triggert, ami akkor aktivizálódik ha a dolgozo tábla
fizetes oszlopát módosítják.

A trigger a következő műveleteket végezze el:

Ha a dolgozó új fizetése nagyobb lesz mint 4000 akkor erről tegyen egy 
bejegyzést a trigger_log táblába. Az esemény oszlopba írja be a régi és az 
új fizetést is.

Az elnök (foglalkozas = 'PRESIDENT') fizetését ne engedje módositani. 
(A módosítás után a fizetés maradjon a régi.) Erről is tegyen egy bejegyzést
a trigger_log táblába. Az esemény oszlopba írja be, hogy a fizetés nem 
változott.
*/

CREATE OR REPLACE TRIGGER RAISE_LOGGING
BEFORE UPDATE OF FIZETES ON DOLGOZO
FOR EACH ROW
DECLARE
    trigger_msg VARCHAR2(80) := 'dkod: ' || :OLD.dkod || ', fizetes: ';
BEGIN
    IF :OLD.foglalkozas = 'PRESIDENT' THEN
        trigger_msg := trigger_msg || 'valtozatlan';
        :NEW.fizetes := :OLD.fizetes;
        RAISE_APPLICATION_ERROR(-20900, 'DONT MESS WITH THE BOSS!');
    END IF;
    
    IF (:NEW.fizetes - :OLD.fizetes > 4000) THEN
        trigger_msg := trigger_msg || :OLD.fizetes || ' -> ' || :NEW.FIZETES;
    END IF;
    
    INSERT INTO TRIGGER_LOG (idopont, muvelet, esemeny)
    VALUES (CURRENT_TIMESTAMP, 'fizetesemeles', trigger_msg);
END;
/

-- Take a look at the original tables.
SELECT * FROM PW9YIK.DOLGOZO;
SELECT * FROM PW9YIK.TRIGGER_LOG;

-- Update to test the trigger.
UPDATE DOLGOZO SET FIZETES = FIZETES + 4801 WHERE DKOD = 7369;
UPDATE DOLGOZO SET FIZETES = FIZETES + 4801 WHERE FOGLALKOZAS = 'PRESIDENT';

-- Evaluate.
SELECT * FROM PW9YIK.DOLGOZO;
SELECT * FROM PW9YIK.TRIGGER_LOG;

---=== 2. Feladat ===---
/*
Hozzunk létre egy TRIGGER_LOG2 nevű táblát is, aminek a szerkezete a következő:
     ( idopont     DATE, 
       muvelet     VARCHAR2(20), 
       uj_osszfiz  NUMBER
     )
*/

DROP TABLE TRIGGER_LOG2;
CREATE TABLE TRIGGER_LOG2(
    idopont    DATE,
    muvelet    VARCHAR2(20),
    uj_osszfiz NUMBER
);

SELECT * FROM TRIGGER_LOG2;

/*
Hozzunk létre egy triggert, ami akkor aktivizálodik ha a dolgozo tablara
valamilyen modosito muveletet (INSERT, DELETE, UPDATE) hajtanak vegre.
A trigger irja be a trigger_log2 tablaba a modositas idopontjat, a muveletet
es az uj osszfizetest. Ha az uj osszfizetes nagyobb lenne mint 40000, akkor
a trigger utasitsa vissza a modosito muveletet, és hibaüzenetkent küldje vissza,
hogy 'Tul nagy osszfizetes'. Ez esetben naplóznia sem kell.
*/

CREATE OR REPLACE TRIGGER EVENT_LOGGER
AFTER UPDATE OR INSERT OR DELETE ON DOLGOZO
DECLARE
    uj_ossz_fiz  NUMBER;
BEGIN
    SELECT SUM(fizetes) INTO uj_ossz_fiz FROM DOLGOZO;
    IF (uj_ossz_fiz > 40000) THEN
        RAISE_APPLICATION_ERROR(-20900, 'NOT AFFORDABLE!');
    END IF;

    INSERT INTO TRIGGER_LOG2 (idopont, muvelet, uj_osszfiz)
    VALUES (CURRENT_TIMESTAMP, 'modositas', uj_ossz_fiz);
END;
/

-- Take a look at the original tables.
SELECT * FROM PW9YIK.DOLGOZO;
SELECT SUM(fizetes) FROM PW9YIK.DOLGOZO;
SELECT * FROM PW9YIK.TRIGGER_LOG2;

-- Update to test the trigger.
UPDATE DOLGOZO SET FIZETES = FIZETES + 40500;
UPDATE DOLGOZO SET FIZETES = FIZETES + 100;

-- Evaluate.
SELECT * FROM PW9YIK.DOLGOZO;
SELECT * FROM PW9YIK.TRIGGER_LOG2;
