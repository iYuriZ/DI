/****************************************************************************/
/*	 							Constraint 2								*/
/****************************************************************************/

-- Read uncommitted
SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED

-- Read committed
SET TRANSACTION ISOLATION LEVEL READ COMMITTED

CREATE TRIGGER TRG_NO_UPDATE ON Vlucht 
AFTER UPDATE
AS
BEGIN
	IF @@ROWCOUNT = 0
		RETURN
	SET NOCOUNT ON
	SET XACT_ABORT ON

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

		IF EXISTS (SELECT pv.*
				   FROM vlucht v INNER JOIN PassagierVoorVlucht pv
				   ON v.vluchtnummer = pv.vluchtnummer
				   WHERE v.vluchtnummer = (SELECT vluchtnummer
										   FROM inserted))
		BEGIN
			;THROW 50001, 'No update allowed when the flight has passengers', 1
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

/****************************************************************************/
/*	 							Constraint 4								*/
/****************************************************************************/

-- Read uncommitted
SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED

-- Read committed
SET TRANSACTION ISOLATION LEVEL READ COMMITTED

-- Repeatable read
SET TRANSACTION ISOLATION LEVEL REPEATABLE READ

-- Serializable
SET TRANSACTION ISOLATION LEVEL SERIALIZABLE

CREATE PROCEDURE dbo.PROC_COUNT_PASSENGERS
	@vluchtnr INT,
	@passagiernr INT,
	@balienr INT,
	@inchecktijd DATETIME,
	@stoel CHAR(3)
AS
BEGIN
	BEGIN TRY
		IF (SELECT COUNT(*)
			FROM PassagierVoorVlucht
			WHERE vluchtnummer = @vluchtnr)
		> (SELECT max_aantal_psgrs
		   FROM vlucht
		   WHERE vluchtnummer = @vluchtnr)
		BEGIN
			;THROW 50001, 'Passenger limit exceeded for that flight', 1
		END
		ELSE
		BEGIN 
			WAITFOR DELAY '00:00:10'
			
			INSERT INTO PassagierVoorVlucht
			 VALUES (@vluchtnr, @passagiernr, @balienr, @inchecktijd, @stoel)
		END
	END TRY
	BEGIN CATCH
		THROW;
	END CATCH
END
