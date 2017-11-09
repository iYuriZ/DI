/****************************************************************************/
/*	 							Constraint 4								*/
/****************************************************************************/
DROP PROCEDURE IF EXISTS PROC_COUNT_PASSENGERS
GO
CREATE PROCEDURE PROC_COUNT_PASSENGERS
	@vluchtnr INT,
	@passagiernr INT,
	@balienr INT,
	@inchecktijd DATETIME,
	@stoel CHAR(3)
AS
BEGIN
	BEGIN TRY
		IF NOT EXISTS (SELECT * FROM Vlucht v WHERE
					v.vluchtnummer = @vluchtnr AND
					max_aantal_psgrs > (SELECT COUNT(*) FROM PassagierVoorVlucht WHERE vluchtnummer = v.vluchtnummer))
		BEGIN
			;THROW 50001, 'Passenger limit exceeded for that flight', 1
		END
		ELSE
		BEGIN
			WAITFOR DELAY '00:00:10'
			
			INSERT INTO PassagierVoorVlucht (passagiernummer, vluchtnummer, balienummer, inchecktijdstip, stoel)
			VALUES (@passagiernr, @vluchtnr, @balienr, @inchecktijd, @stoel)
		END
	END TRY
	BEGIN CATCH
		THROW;
	END CATCH
END
GO

DELETE FROM PassagierVoorVlucht WHERE vluchtnummer = 5316;
UPDATE Vlucht SET max_aantal_psgrs = 1 WHERE vluchtnummer = 5316;

----------------------------------------------------------
-- Read uncommitted

-- T1
SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
BEGIN TRANSACTION
	EXEC PROC_COUNT_PASSENGERS
			@passagiernr = 850, 
			@vluchtnr = 5316,
			@balienr = 1,
			@inchecktijd = '2004-01-31 22:25',
			@stoel = 97
COMMIT TRANSACTION

-- T2
SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
BEGIN TRANSACTION
	EXEC PROC_COUNT_PASSENGERS
			@passagiernr = 1002, 
			@vluchtnr = 5316,
			@balienr = 1,
			@inchecktijd = '2004-01-31 22:25',
			@stoel = 3

	SELECT *, (SELECT COUNT(*)
				FROM PassagierVoorVlucht
				WHERE vluchtnummer = v.vluchtnummer)
	FROM Vlucht v
	WHERE v.vluchtnummer = 5316;
ROLLBACK TRANSACTION

----------------------------------------------------------
-- Read committed

-- T1
SET TRANSACTION ISOLATION LEVEL READ COMMITTED
BEGIN TRANSACTION
	EXEC PROC_COUNT_PASSENGERS
			@passagiernr = 850, 
			@vluchtnr = 5316,
			@balienr = 1,
			@inchecktijd = '2004-01-31 22:25',
			@stoel = 97
COMMIT TRANSACTION

-- T2
SET TRANSACTION ISOLATION LEVEL READ COMMITTED
BEGIN TRANSACTION
	EXEC PROC_COUNT_PASSENGERS
			@passagiernr = 1002, 
			@vluchtnr = 5316,
			@balienr = 1,
			@inchecktijd = '2004-01-31 22:25',
			@stoel = 3
ROLLBACK TRANSACTION

----------------------------------------------------------
-- Repeatable read

-- T1
SET TRANSACTION ISOLATION LEVEL REPEATABLE READ
BEGIN TRANSACTION
	EXEC PROC_COUNT_PASSENGERS
			@passagiernr = 850, 
			@vluchtnr = 5316,
			@balienr = 1,
			@inchecktijd = '2004-01-31 22:25',
			@stoel = 97
COMMIT TRANSACTION

-- T2
SET TRANSACTION ISOLATION LEVEL REPEATABLE READ
BEGIN TRANSACTION
	EXEC PROC_COUNT_PASSENGERS
			@passagiernr = 1002, 
			@vluchtnr = 5316,
			@balienr = 1,
			@inchecktijd = '2004-01-31 22:25',
			@stoel = 3
ROLLBACK TRANSACTION

----------------------------------------------------------
-- Serializable

-- T1
SET TRANSACTION ISOLATION LEVEL SERIALIZABLE
BEGIN TRANSACTION
	EXEC PROC_COUNT_PASSENGERS
			@passagiernr = 850, 
			@vluchtnr = 5316,
			@balienr = 1,
			@inchecktijd = '2004-01-31 22:25',
			@stoel = 97
COMMIT TRANSACTION

-- T2
SET TRANSACTION ISOLATION LEVEL SERIALIZABLE
BEGIN TRANSACTION
	EXEC PROC_COUNT_PASSENGERS
			@passagiernr = 1002, 
			@vluchtnr = 5316,
			@balienr = 1,
			@inchecktijd = '2004-01-31 22:25',
			@stoel = 3
ROLLBACK TRANSACTION

/****************************************************************************/
/*	 							Constraint 7								*/
/****************************************************************************/
DROP TRIGGER IF EXISTS trgPassagierVoorVlucht_stoel_IU;
GO
CREATE TRIGGER trgPassagierVoorVlucht_stoel_IU ON PassagierVoorVlucht
AFTER INSERT, UPDATE
AS
BEGIN
	IF @@ROWCOUNT = 0
		RETURN
	SET NOCOUNT ON
	
	DECLARE @transactions AS INT = @@TRANCOUNT

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

		IF EXISTS (SELECT *
				   FROM inserted i
				   WHERE i.stoel IS NOT NULL
				   AND EXISTS (SELECT vluchtnummer, stoel
				   FROM PassagierVoorVlucht
				   GROUP BY vluchtnummer, stoel
				   HAVING COUNT(*) >= 2))
		BEGIN
			;THROW 50000, 'Een vlucht en stoelnummer moeten uniek zijn', 1
		END
		
		WAITFOR DELAY '00:00:10'

		-- Transactie doorvoeren
		IF @transactions = 0
		BEGIN
			COMMIT TRANSACTION
		END
	END TRY
	BEGIN CATCH
		;THROW

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

----------------------------------------------------------
-- Read uncommitted

-- T1
SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
BEGIN TRANSACTION
	INSERT INTO PassagierVoorVlucht (passagiernummer, vluchtnummer, balienummer, inchecktijdstip, stoel)
	VALUES (1555, 5315, 4, '2004-01-31 08:45', 3);
ROLLBACK TRANSACTION

-- T2
SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
BEGIN TRANSACTION
	INSERT INTO PassagierVoorVlucht (passagiernummer, vluchtnummer, balienummer, inchecktijdstip, stoel)
	VALUES (1500, 5315, 4, '2004-01-31 08:45', 3);
ROLLBACK TRANSACTION

----------------------------------------------------------
-- Read committed

-- T1
SET TRANSACTION ISOLATION LEVEL READ COMMITTED
BEGIN TRANSACTION
	INSERT INTO PassagierVoorVlucht (passagiernummer, vluchtnummer, balienummer, inchecktijdstip, stoel)
	VALUES (1555, 5315, 4, '2004-01-31 08:45', 3);
ROLLBACK TRANSACTION

-- T2
SET TRANSACTION ISOLATION LEVEL READ COMMITTED
BEGIN TRANSACTION
	INSERT INTO PassagierVoorVlucht (passagiernummer, vluchtnummer, balienummer, inchecktijdstip, stoel)
	VALUES (1500, 5315, 4, '2004-01-31 08:45', 3);
ROLLBACK TRANSACTION
