/*
Minden feladat úgy szerepel, hogy az eredménynek milyen oszlopokból kell állnia.
Ha valaki eredményt nem küld, a feladatát nem értékelem!
Az ARAMIS adatbázisban kell dolgozni.
*/

---=== 5. feladat ===---
/*
Hányan vannak, és mennyi helyet foglalnak összesen az adatbázisban az SH felhasználó
BITMAP indexei (partícionált indexe is lehet!) (Darab, Összméret)
*/

---=== 6. feladat ===---
/*
Adjuk meg a NIKOVITS felhasználó azon tábláinak nevét, amelyeknek az 5. és 7. oszlopa
ugyanolyan típusú. A hossz és a pontosság nem számít, az alaptípus legyen azonos.(Név)
*/
SELECT DISTINCT first.table_name AS Név
FROM dba_tab_columns first, dba_tab_columns second
WHERE first.owner = 'NIKOVITS' AND second.owner = first.owner  AND first.table_name = second.table_name AND 
        first.column_id = 2 AND second.column_id = 7 AND first.data_type = second.data_type;
        
---=== 7. feladat ===---
/*
Írjunk egy PL/SQL procedúrát, amelyik kiírja, hogy a NIKOVTIS.HALLGATOK táblának
melyek azok az adatblokkjai, amelyekben több, mint 100 sor van. (File_num, Blokk_num, Sorok)
*/

CREATE OR REPLACE PROCEDURE zhfeladat IS

BEGIN
    FOR row IN (
        SELECT 
            dbms_rowid.rowid_relative_fno(ROWID) file_id,
            dbms_rowid.rowid_block_number(ROWID) block_id,
            count(*) row_count
        FROM nikovits.hallgatok
        GROUP BY 
            dbms_rowid.rowid_relative_fno(ROWID),
            dbms_rowid.rowid_block_number(ROWID)
        HAVING count(*) > 100
    ) LOOP
        dbms_output.put_line(row.file_id||' '||row.block_id||' '||row.row_count);
    END LOOP;
END;
/

SET SERVEROUTPUT ON;
EXECUTE ZHFELADAT;