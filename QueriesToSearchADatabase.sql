/*
	The purpose of this file is to aggregate scripts that are useful
	for searching a database. Some scripts will aid in looking for
	columns with a certain name and others have their purpose as well.

	06/15/17 Tim Lansing
	Initial compilation of the scripts.
*/

/*
	The purpose of this script is to find columns within a database
	containing some portion of a provided string. Replace 'ID' in
	the script below for whatever you are searching for.
*/
SELECT COLUMN_NAME, TABLE_NAME
FROM INFORMATION_SCHEMA.COLUMNS
WHERE COLUMN_NAME LIKE '%ID%'
ORDER BY TABLE_NAME

/*
	This script searches through stored procedures looking for the
	requested string. Replace ID in the query below with the string
	being searched for. This query returns the stored procedures
	name and the definition.
	
	Note: The text being searched is case sensitive.
*/
SELECT ROUTINE_NAME, ROUTINE_DEFINITION
FROM INFORMATION_SCHEMA.ROUTINES
WHERE ROUTINE_DEFINITION LIKE '%ID%'
AND ROUTINE_TYPE = 'PROCEDURE'
ORDER BY ROUTINE_NAME

/*
	This script also searches through stored procedures looking for the
	requested string. Replace ID in the query below with the string
	being searched for. This query returns the stored procedures
	name.
	
	Note: The text being searched is case sensitive.
*/
select name 
FROM sys.procedures
where OBJECT_DEFINITION(object_id) LIKE '%name%'
/*
	This query's results provide information about the table being
	searched.
*/
exec sp_columns TableName

/*
	The below query displays primary / foreign key relationships which
	exist in a database. Nothing needs to be changed. It only needs to
	be ran.
*/
SELECT fk.Name AS 'FKName'
          ,OBJECT_NAME(fk.parent_object_id) 'ParentTable'
          ,cpa.name 'ParentColumnName'
          ,OBJECT_NAME(fk.referenced_object_id) 'ReferencedTable'
          ,cref.name 'ReferencedColumnName'
    FROM   sys.foreign_keys fk
           INNER JOIN sys.foreign_key_columns fkc
                ON  fkc.constraint_object_id = fk.object_id
           INNER JOIN sys.columns cpa
                ON  fkc.parent_object_id = cpa.object_id
                AND fkc.parent_column_id = cpa.column_id
           INNER JOIN sys.columns cref
                ON  fkc.referenced_object_id = cref.object_id
                AND fkc.referenced_column_id = cref.column_id

				