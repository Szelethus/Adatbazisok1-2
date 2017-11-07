/*
Minden feladat úgy szerepel, hogy az eredménynek milyen oszlopokból kell állnia.
Ha valaki eredményt nem küld, a feladatát nem értékelem!
Az ARAMIS adatbázisban kell dolgozni.
*/

---=== 5. feladat (10 pont) ===---
--Adjuk meg az SH felhasnáló olyan tábláit, amelyekre létre van hozva BITMAP index és a
--táblának nincs NUMBER(10,2) típusú oszlopa! (Táblanév)

(
    SELECT table_name
    FROM dba_indexes
    WHERE table_owner = 'SH' AND index_type = 'BITMAP'
)
MINUS
(
    SELECT table_name
    FROM dba_tab_columns
    WHERE owner = 'SH' AND data_type = 'NUMBER' AND data_precision = 10 AND data_scale = 2
);

---=== 6. feladat (10 pont) ===---
--Adjuk meg a NIKOVITS felhasználó tulajdonában lévő cluster indexek (clusterre létrehozott
--indexek) nevét és méretét. (Név, Méret)

SELECT cluster_name nev, key_size meret 
FROM dba_clusters 
WHERE owner = 'NIKOVITS' AND cluster_type = 'INDEX';

---=== 7. feladat (12 pont) ===---
--Írjunk meg egy PL/SQL procedúrát, amelyik kiírja, hogy a NIKOVITS.HALLGATOK táblának
--melyek azok az adatblokkjai, amelyekben nincs egyetlen sor sem (File_id, Block_id)

-- I tried so hard :'( 

/***** Koncepció: *****/

SELECT file_id, block_id AS starting_block_id, blocks AS length_in_blocks
FROM dba_extents
WHERE owner = 'NIKOVITS' AND segment_name = 'HALLGATOK' and segment_type = 'TABLE';
-- Ez a lekérdezés a tábla által lefoglalt extenseket, azon belül a fájlnevet, az extens elejét és hosszát blokkokban
    --> Megállapítható, hogy a 888, 889, ... , 896 valamint a 1503576, 1503577, ... , 1503584 blokkok vannak lefoglalva a tábla által
SELECT DISTINCT base64_string_to_dec(substr(ROWID, 7, 3)) AS file_id, base64_string_to_dec(substr(ROWID, 10, 6)) AS block_id
FROM nikovits.hallgatok
ORDER BY base64_string_to_dec(substr(ROWID, 10, 6));
-- Ez a lekérdezés tartalmazza, hogy mely blokkokban található legalább 1 sor
    --> Lekérdezhető, mely blokkok vannak ténylegesen kihasználva
-- E kettő különbsége a ki nem használt blokkok.

-- Probléma: Hogyan lehet ezt a különbséget értelmesen végrehajtani?

CREATE OR REPLACE PROCEDURE zh7f IS
    is_not_used NUMBER := 1;
BEGIN
    -- for each allocated extent
    FOR extent_row IN (
        SELECT file_id, block_id AS starting_block_id, blocks AS length_in_blocks
        FROM dba_extents
        WHERE owner = 'NIKOVITS' AND segment_name = 'HALLGATOK' and segment_type = 'TABLE'
    ) LOOP
        -- for each allocated block in the allocated extent
        FOR allocated_block IN extent_row.starting_block_id..extent_row.starting_block_id + extent_row.length_in_blocks LOOP
            -- for each block containing at least 1 row
            FOR used_block IN (
                SELECT DISTINCT substr(ROWID, 7, 3), base64_string_to_dec(substr(ROWID, 10, 6))
                FROM nikovits.hallgatok
                ORDER BY base64_string_to_dec(substr(ROWID, 10, 6))
            ) LOOP
                -- i just realized that file names have to match as well, so i'll go and kill myself
                IF allocated_block = used_block THEN
                    is_not_used := 0;
                END IF;
            END LOOP;
            is_not_used := 1;
        END LOOP;
    END LOOP;
END;
/