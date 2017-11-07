/*
Minden feladat úgy szerepel, hogy az eredménynek milyen oszlopokból kell állnia.
Ha valaki eredményt nem küld, a feladatát nem értékelem!
Az ARAMIS adatbázisban kell dolgozni.
*/

---=== 5. feladat (10 pont) ===---
--Adjuk meg az SH felhasnáló olyan tábláit, amelyekre létre van hozva BITMAP index és a
--táblának nincs NUMBER(10,2) típusú oszlopa! (Táblanév)

---=== 6. feladat (10 pont) ===---
--Adjuk meg a NIKOVITS felhasználó tulajdonában lévő cluster indexek (clusterre létrehozott
--indexek) nevét és méretét. (Név, Méret)

---=== 7. feladat (12 pont) ===---
--Írjunk meg egy PL/SQL procedúrát, amelyik kiírja, hogy a NIKOVITS.HALLGATOK táblának
--melyek azok az adatblokkjai, amelyekben nincs egyetlen sor sem (File_id, Block_id)

CREATE OR REPLACE PROCEDURE zh7f IS
BEGIN
    NULL;
END;
/