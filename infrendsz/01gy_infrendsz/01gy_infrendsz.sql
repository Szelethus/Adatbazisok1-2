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

-- The actual trigger.
CREATE OR REPLACE TRIGGER GY01TRIGGER
BEFORE UPDATE OF FIZETES ON DOLGOZO
FOR EACH ROW
DECLARE
    trigger_msg VARCHAR2(80) := 'dkod: ' || :OLD.dkod || ', fizetes: ';
BEGIN
    IF :OLD.foglalkozas = 'PRESIDENT' THEN
        trigger_msg := trigger_msg || 'valtozatlan';
        :NEW.fizetes := :OLD.fizetes;
        --RAISE_APPLICATION_ERROR(-20900, 'DONT MESS WITH THE BOSS!');
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
