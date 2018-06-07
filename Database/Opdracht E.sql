USE gelre_airport;go

DROP PROCEDURE IF EXISTS prcCreateHistoryTable
GO
CREATE PROCEDURE prcCreateHistoryTable
	@databaseName VARCHAR(100),
	@tableName VARCHAR (100)
AS
BEGIN
	SET NOCOUNT ON
	SET XACT_ABORT ON
	
	-- Variabelen initialiseren
	DECLARE @transactions AS INT = @@TRANCOUNT
	DECLARE @columns AS VARCHAR (MAX) = ''
	DECLARE @sqlQuery AS VARCHAR (MAX) = ''

	BEGIN TRY
		-- Transactie beginnen / opslaan
		IF @transactions > 0
		BEGIN
			SAVE TRANSACTION procTransaction
		END
		ELSE
		BEGIN
			BEGIN TRANSACTION
		END
		
		-- Kolommen van tabel verkrijgen
		SELECT
			 @columns += COLUMN_NAME + ' ' + DATA_TYPE +

			-- Datatype lengte
			CASE
				-- Integers met decimalen
				WHEN NUMERIC_PRECISION IS NOT NULL AND NUMERIC_SCALE > 0 AND NUMERIC_SCALE IS NOT NULL
					THEN '(' + CAST(NUMERIC_PRECISION AS VARCHAR) + ', ' + CAST(NUMERIC_SCALE AS VARCHAR) + ')'
				-- Waardes zonder lengte
				WHEN CHARACTER_MAXIMUM_LENGTH IS NULL
					THEN ''
				-- Waardes met lengte
				ELSE
					'(' + CAST(CHARACTER_MAXIMUM_LENGTH AS VARCHAR) + ')'
			END +

			-- DEFAULT
			CASE
				-- Waardes met DEFAULT
				WHEN COLUMN_DEFAULT IS NOT NULL
					THEN ' DEFAULT ' + COLUMN_DEFAULT
				ELSE
					''
			END +
	
			-- NULL / NOT NULL
			CASE
				WHEN IS_NULLABLE = 'NO'
					THEN ' NOT NULL'
				ELSE
					' NULL'
			END + ', '
		FROM INFORMATION_SCHEMA.COLUMNS
		WHERE TABLE_NAME = @tableName;

		-- Extra kolommen toevoegen aan query
		SET @sqlQuery = 'DROP TABLE IF EXISTS ' + @databaseName + '.dbo.' + @tableName +'History;
		 CREATE TABLE ' + @databaseName + '.dbo.' + @tableName + 'History (' + @columns +
		'timestamp datetime NOT NULL DEFAULT GETDATE(),
		 actie CHAR(6) NOT NULL,
		 
		 CONSTRAINT chk_' + @tableName + '_actie CHECK (actie IN (''update'', ''delete'')));'
	
		PRINT @sqlQuery
		EXEC (@sqlQuery)
		
		-- Transactie doorvoeren
		IF @transactions = 0
		BEGIN
			COMMIT TRANSACTION
		END
	END TRY
	BEGIN CATCH
		;THROW
		--RAISERROR ('Something went wrong creating the history table', 16, 1)
		
		-- Transactie terugdraaien
		IF @transactions > 0
		BEGIN
			ROLLBACK TRANSACTION procTransaction
		END
		ELSE
		BEGIN
			ROLLBACK TRANSACTION
		END
	END CATCH
END
GO


--
-- Create a history table for each table in the given database
--
DROP PROCEDURE IF EXISTS prcCreateHistoryTablesForDatabase
GO
CREATE PROCEDURE prcCreateHistoryTablesForDatabase
	@databaseName VARCHAR (100)
AS
BEGIN
	SET NOCOUNT ON
	SET XACT_ABORT ON
	
	-- Variabelen initialiseren
	DECLARE @transactions AS INT = @@TRANCOUNT
	DECLARE @query AS VARCHAR(MAX)

	BEGIN TRY
		-- Transactie beginnen / opslaan
		IF @transactions > 0
		BEGIN
			SAVE TRANSACTION procTransaction
		END
		ELSE
		BEGIN
			BEGIN TRANSACTION
		END

		SET @query = '
	  DECLARE @tableName AS VARCHAR(100)
		DECLARE db_cursor CURSOR LOCAL FOR

	  SELECT TABLE_NAME
		FROM ' + @databaseName + '.INFORMATION_SCHEMA.TABLES
		WHERE TABLE_TYPE = ''BASE TABLE''

		OPEN db_cursor
	  FETCH NEXT FROM db_cursor INTO @tableName

		WHILE @@FETCH_STATUS = 0
		BEGIN
			EXEC prcCreateHistoryTable @databaseName = '+@databaseName+', @tableName=@tableName
			FETCH NEXT FROM db_cursor INTO @tableName
		END

		CLOSE db_cursor
		DEALLOCATE db_cursor'

		EXEC (@query)

		-- Transactie doorvoeren
		IF @transactions = 0
		BEGIN
			COMMIT TRANSACTION
		END
	END TRY
	BEGIN CATCH
		;THROW
		--RAISERROR ('Something went wrong creating the history database', 16, 1)
		
		-- Transactie terugdraaien
		IF @transactions > 0
		BEGIN
			ROLLBACK TRANSACTION procTransaction
		END
		ELSE
		BEGIN
			ROLLBACK TRANSACTION
		END
	END CATCH
END
GO

-- 'Normale' test
EXEC prcCreateHistoryTablesForDatabase @databaseName = 'gelre_airport'

-- Nested transactie test
BEGIN TRANSACTION
	EXEC prcCreateHistoryTablesForDatabase @databaseName = 'gelre_airport'
COMMIT TRANSACTION