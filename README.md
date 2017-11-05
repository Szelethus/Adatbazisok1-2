# Adatbázisok 1-2

## Konvenciók

* Minden feladatsorhoz tartozó megoldás külön `.sql` fájlba kerüljön!
* A feladatok megoldása felett szerepeljen a leírásuk!
* Amennyiben egy feladat megoldása nem jó vagy nem biztos hogy jó, az legyen jól láthatóan felűntetve!
* Halmazműveletek esetén legyenek jól elkülíthetőek a lekérdezések!
* Hosszabb lekérdezések esetén több sorba legyen tördeljünk!
* A kulcsszavak nagybetűvel legyenek írva!

NEM OK:
```SQL
SELECT looooooooooooong_id, looongeeeeeeeeeeeeeeeeeeeeer_id FROM table1, looooong_table, table2, WHERE a = 10 AND b > 900 GROUP BY owner HAVING count(*) < 10;
```
Ehelyett:
```SQL
SELECT looooooooooooong_id, looongeeeeeeeeeeeeeeeeeeeeer_id 
FROM table1, looooong_table, table2, 
WHERE a = 10 AND b > 900 
GROUP BY owner HAVING count(*) < 10;
```

## Issues

* Amennyiben hibásan jelennek 
