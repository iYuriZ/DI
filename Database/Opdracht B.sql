USE gelre_airport;
GO

-- Voor constraint 6
UPDATE Vlucht SET max_totaalgewicht = 9000 WHERE max_aantal_psgrs * max_ppgewicht > max_totaalgewicht

-- Voor constraint 10
UPDATE Vlucht
SET aankomsttijdstip = vertrektijdstip + 1
WHERE aankomsttijdstip IS NULL;
GO

UPDATE Vlucht
SET vertrektijdstip = GETDATE() - 1
WHERE vertrektijdstip IS NULL
GO

ALTER TABLE Vlucht
ALTER COLUMN vertrektijdstip DATETIME NOT NULL;
ALTER TABLE Vlucht
ALTER COLUMN aankomsttijdstip DATETIME NOT NULL;
GO

/****************************************************************************/
/* 1.	Voor elke passagier zijn het stoelnummer en het						*/
/* inchecktijdstip of beide niet ingevuld of beide wel ingevuld				*/
/****************************************************************************/
ALTER TABLE PassagierVoorVlucht DROP CONSTRAINT IF EXISTS CHK_IncheckTijdStip_Stoel;
GO
ALTER TABLE PassagierVoorVlucht ADD CONSTRAINT CHK_IncheckTijdStip_Stoel CHECK ((inchecktijdstip IS NULL AND stoel IS NULL) OR
																				(inchecktijdstip IS NOT NULL AND stoel IS NOT NULL));
GO

/****************************************************************************/
/* 2.	Als er een passagier aan een vlucht is toegevoegd					*/
/* mogen de gegevens van die vlucht niet meer gewijzigd worden.				*/
/****************************************************************************/
DROP TRIGGER IF EXISTS TRG_NO_UPDATE
GO
CREATE TRIGGER TRG_NO_UPDATE ON Vlucht 
AFTER UPDATE
AS
BEGIN
	IF @@ROWCOUNT = 0
		RETURN
	SET NOCOUNT ON
	SET XACT_ABORT ON

    BEGIN TRY
		IF EXISTS (SELECT pv.*
				   FROM vlucht v INNER JOIN PassagierVoorVlucht pv
				   ON v.vluchtnummer = pv.vluchtnummer
				   WHERE v.vluchtnummer IN (SELECT vluchtnummer
										   FROM inserted))
		BEGIN
			;THROW 50001, 'No update allowed when the flight has passengers', 1
		END
    END TRY
    BEGIN CATCH
        ;THROW
    END CATCH
END
GO

/****************************************************************************/
/* 3.	Het inchecktijdstip van een passagier moet							*/
/* voor het vertrektijdstip van een vlucht liggen.							*/
/****************************************************************************/
DROP TRIGGER IF EXISTS trgPassagierVoorVlucht_inchecktijdstip_IU;
GO
CREATE TRIGGER trgPassagierVoorVlucht_inchecktijdstip_IU
ON
	PassagierVoorVlucht
AFTER INSERT, UPDATE
AS
BEGIN
	IF @@ROWCOUNT = 0
		RETURN
	SET NOCOUNT ON
	SET XACT_ABORT ON

	BEGIN TRY

		-- Alle records van inserted joinen op vlucht en dan controleren of de vertrekTijdstip later is dan het incheckTijdstip
		IF EXISTS(SELECT *
				  FROM inserted i 
				  INNER JOIN Vlucht v ON v.vluchtnummer = i.vluchtnummer
				  WHERE i.inchecktijdstip >= v.vertrekTijdstip)
		BEGIN
			;THROW 50000, 'Het inchecktijdstip mag niet later zijn dan het vertrek tijdstip', 1
		END
	END TRY
	BEGIN CATCH
		;THROW
	END CATCH
END
GO

/****************************************************************************/
/* 4.	Elke vlucht heeft volgens de specs een toegestaan maximum aantal 	*/ ----------------------------------------------------------------------
/* passagiers. Zorg ervoor dat deze regel niet overschreden kan worden.		*/ -- Isolation level ophogen
/****************************************************************************/ -- Index passagiervoorvlucht
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
	SET NOCOUNT ON
	SET XACT_ABORT OFF
	DECLARE @TranCounter INT= @@TRANCOUNT
	
	IF @TranCounter > 0
		SAVE TRANSACTION procTrans
	ELSE
		BEGIN TRANSACTION

	BEGIN TRY
		IF NOT EXISTS (SELECT * FROM Vlucht v WHERE
					v.vluchtnummer = @vluchtnr AND
					max_aantal_psgrs > (SELECT COUNT(*) FROM PassagierVoorVlucht WHERE vluchtnummer = v.vluchtnummer))
		BEGIN
			;THROW 50001, 'Passenger limit exceeded for that flight', 1
		END
			
			
		IF EXISTS (SELECT * FROM PassagierVoorVlucht WHERE passagiernummer = @passagiernr AND vluchtnummer = @vluchtnr)
		BEGIN
			UPDATE PassagierVoorVlucht
			SET
				balienummer = @balienr,
				inchecktijdstip = @inchecktijd,
				stoel = @stoel
			WHERE
				passagiernummer = @passagiernr
			AND
				vluchtnummer = @vluchtnr
		END
		ELSE
		BEGIN
			INSERT INTO PassagierVoorVlucht (passagiernummer, vluchtnummer, balienummer, inchecktijdstip, stoel)
			VALUES (@passagiernr, @vluchtnr, @balienr, @inchecktijd, @stoel);
		END
		
		IF @TranCounter = 0 AND XACT_STATE() = 1
			COMMIT TRANSACTION
		
	END TRY
	BEGIN CATCH
	
		IF @TranCounter = 0 AND XACT_STATE() = 1
			ROLLBACK TRANSACTION
	
		THROW;
	END CATCH
END
GO

/****************************************************************************/
/* 5.	Per passagier mogen maximaal 3 objecten worden ingecheckt. 			*/
/* Tevens geldt: het totaalgewicht van de bagage van een passagier mag 		*/
/* het maximaal per persoon toegestane gewicht op een vlucht niet			*/
/* overschrijden. Mocht de datapopulatie het aanbrengen van de constraint	*/
/* niet toestaan, neem dan maatregelen in uw uitwerkingsdocument.			*/
/****************************************************************************/

DROP PROCEDURE IF EXISTS proc_InsertObject
GO
CREATE PROCEDURE Proc_InsertObject
	@passagiernummer INT,
	@vluchtnummer INT,
	@balienummer INT,
	@gewicht INT
AS
BEGIN
	SET NOCOUNT ON
	SET XACT_ABORT OFF
	DECLARE @TranCounter INT = @@TRANCOUNT

	IF @TranCounter > 0
		SAVE TRANSACTION procTrans
	ELSE
		BEGIN TRANSACTION

	BEGIN TRY

		IF EXISTS (SELECT 1 FROM Object o
							 WHERE o.vluchtnummer = @vluchtnummer
							 AND o.passagiernummer = @passagiernummer
							 GROUP BY o.passagiernummer, o.vluchtnummer
							 HAVING COUNT(*) > 3
							 OR SUM (o.gewicht) > (SELECT max_ppgewicht FROM Vlucht WHERE vluchtnummer = @vluchtnummer))
			BEGIN
				;THROW 50000, 'Een passagier mag niet meer dan 3 objecten inchecken en het totaalgewicht mag niet hoger liggen dan het toegestaen gewicht', 1
			END
		ELSE BEGIN

			INSERT INTO PassagierVoorVlucht (passagiernummer, vluchtnummer, balienummer)
			VALUES (@passagiernummer, @vluchtnummer, @balienummer);

			INSERT INTO Object (passagiernummer, vluchtnummer, gewicht)
			VALUES (@passagiernummer, @vluchtnummer, @gewicht);

		END

		IF @TranCounter = 0 AND XACT_STATE() = 1
			COMMIT TRANSACTION

	END TRY
	BEGIN CATCH

		IF @TranCounter = 0 AND XACT_STATE() = 1
			ROLLBACK TRANSACTION

    ;THROW

	END CATCH
END

/****************************************************************************/
/* 6.	Elke vlucht heeft volgens de specs een toegestaan maximum aantal 	*/
/* passagiers (map, een toegestaan maximum totaalgewicht (mt), en een		*/
/* maximum gewicht dat een persoon mee mag nemen (mgp). Zorg ervoor dat		*/
/* altijd geld map*mgp <= mt.												*/
/****************************************************************************/

ALTER TABLE Vlucht DROP CONSTRAINT IF EXISTS CHK_MaxAantalGewicht;
GO
ALTER TABLE Vlucht ADD CONSTRAINT CHK_MaxAantalGewicht CHECK (max_aantal_psgrs * max_ppgewicht < max_totaalgewicht);
GO

/****************************************************************************/
/* 7.	Voor een passagier is de combinatie (vlucht, stoel) natuurlijk		*/
/* uniek (zie de specs). Maar de mogelijke stoelnummers zijn op het moment	*/
/* van toevoegen van een passagier vaak nog niet bekend. Er moeten dus voor	*/
/* passagiers op dezelfde vlucht null-waarden voor hun stoelen in te vullen	*/
/* zijn. Maak dit mogelijk, zonder uniciteits-eis voor concrete stoelnummers*/
/* te schenden (maak geen gebruik van een zogenaamd filtered index).		*/ -- Read committed
/****************************************************************************/

-- Trigger
DROP TRIGGER IF EXISTS trgPassagierVoorVlucht_stoel_IU;
GO
CREATE TRIGGER trgPassagierVoorVlucht_stoel_IU ON PassagierVoorVlucht
AFTER INSERT, UPDATE
AS
BEGIN
	IF @@ROWCOUNT = 0
		RETURN
	SET NOCOUNT ON
	SET XACT_ABORT ON

	BEGIN TRY
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
	END TRY
	BEGIN CATCH
		;THROW
	END CATCH
END
GO

/****************************************************************************/
/* 8.	De lijst met balies waar kan worden ingecheckt voor een vlucht is	*/
/* beperkt. Niet alle balies zijn bruikbaar voor iedere bestemming, en niet */
/* alle balies zijn te gebruiken door iedere maatschappij. Als er balies aan*/
/* een vlucht gekoppeld worden, mogen dat alleen balies zijn die toegestaan */
/* zijn voor de maatschappij en voor de bestemming van de vlucht. Er kunnen */
/* aan een vlucht meerdere balies gekoppeld worden. De passagier checkt		*/
/* uiteindelijk bij een van deze balies in. Let op; dit laatste is dus ook	*/
/* een constraint.															*/
/****************************************************************************/
DROP TRIGGER IF EXISTS trg_IncheckenVoorVlucht_IU
GO
CREATE TRIGGER trg_IncheckenVoorVlucht_IU ON IncheckenVoorVlucht
AFTER INSERT, UPDATE
AS
BEGIN
	IF @@ROWCOUNT = 0
		RETURN
	SET NOCOUNT ON
	SET XACT_ABORT ON

	BEGIN TRY

		IF EXISTS(SELECT * FROM inserted i
				  -- Controleren of de vlucht de juiste maatschappij heeft
				  WHERE balienummer NOT IN (SELECT ibm.balienummer FROM Vlucht v
				  						INNER JOIN Maatschappij m
				  						ON m.maatschappijcode = v.maatschappijcode
				  						INNER JOIN IncheckenBijMaatschappij ibm
				  						ON ibm.maatschappijcode = m.maatschappijcode
										WHERE v.vluchtnummer = i.vluchtnummer)
				  -- Controleren of de vlucht de juiste bestemming heeft
				  OR balienummer NOT IN (SELECT ivb.balienummer FROM Vlucht v
				  					  INNER JOIN Luchthaven lh
				  					  ON lh.luchthavencode = v.luchthavencode
				  					  INNER JOIN IncheckenVoorBestemming ivb
				  					  ON ivb.luchthavencode = lh.luchthavencode
									  WHERE v.vluchtnummer = i.vluchtnummer))
		BEGIN
			;THROW 50000, 'Not allowed to add this booth to this flight', 1
		END 						
	END TRY
	BEGIN CATCH
		;THROW
	END CATCH
END
GO

DROP TRIGGER IF EXISTS trg_PassagierVoorVlucht_IU
GO
CREATE TRIGGER trg_PassagierVoorVlucht_IU ON PassagierVoorVlucht
AFTER INSERT, UPDATE
AS
BEGIN
	IF @@ROWCOUNT = 0
		RETURN
	SET NOCOUNT ON
	SET XACT_ABORT ON

	BEGIN TRY

		IF NOT EXISTS (SELECT * FROM inserted i WHERE balienummer IN (SELECT balienummer FROM IncheckenVoorVlucht ivv
																	  INNER JOIN Vlucht v ON v.vluchtnummer = ivv.vluchtnummer
																	  WHERE v.vluchtnummer = i.vluchtnummer))
		BEGIN
			;THROW 50000, 'Cannot check in on that booth', 1
		END
			  						
	END TRY
	BEGIN CATCH
		;THROW
	END CATCH
END
GO

/****************************************************************************/
/* 9.	Elke maatschappij moet een balie hebben								*/
/****************************************************************************/
DROP PROCEDURE IF EXISTS prcMaatschappij_balie;
GO
CREATE PROCEDURE prcMaatschappij_balie
	@balieNummer INT,
	@maatschappijCode CHAR(2),
	@maatschappijNaam VARCHAR(255)
AS
BEGIN
	SET NOCOUNT ON
	SET XACT_ABORT OFF
	DECLARE @TranCounter INT= @@TRANCOUNT
	
	IF @TranCounter > 0
		SAVE TRANSACTION procTrans
	ELSE
		BEGIN TRANSACTION
		
	BEGIN TRY
		IF NOT EXISTS (SELECT balienummer FROM Balie WHERE balienummer = @balienummer)
		BEGIN
			;THROW 50000, 'Deze balie bestaat niet', 1
		END
		
		INSERT INTO Maatschappij (maatschappijcode, naam)
		VALUES (@maatschappijcode, @maatschappijNaam);
		
		INSERT INTO IncheckenBijMaatschappij (balienummer, maatschappijcode)
		VALUES (@balienummer, @maatschappijcode);
	END TRY
	BEGIN CATCH
	
		IF @TranCounter = 0 AND XACT_STATE() = 1
			ROLLBACK TRANSACTION
	
		THROW;
	END CATCH
END
GO

/****************************************************************************/
/* 10.	Een passagier mag niet boeken op  vluchten in overlappende			*/
/* periodes. Verander de kolommen vertrektijdstip en aankomsttijdstip van	*/ 
/* table Vlucht in NOT NULL. Update eventueel vooraf de data zodat de 		*/
/* NOT NULL	constraint niet overtreden wordt.								*/ -- Index passagierVoorVlucht (tijdstippen OF stoel (constraint 7))
/****************************************************************************/
DROP TRIGGER IF EXISTS trg_PassagierVoorVlucht_overlapping_IU;
GO
CREATE TRIGGER trg_PassagierVoorVlucht_overlapping_IU
ON
	PassagierVoorVlucht
AFTER INSERT, UPDATE
AS
BEGIN
	IF @@ROWCOUNT = 0
		RETURN
	SET NOCOUNT ON
	SET XACT_ABORT ON

	BEGIN TRY

		-- Controleren of de passagier geen vlucht wil boeken die overlapt in een vlucht waar hij al in zit
		IF EXISTS (SELECT *
				   FROM inserted i INNER JOIN Vlucht original_v
				   ON original_v.vluchtnummer = i.vluchtnummer
				   WHERE i.passagiernummer IN (SELECT passagiernummer
											   FROM PassagierVoorVlucht pvv INNER JOIN Vlucht v
											   ON v.vluchtnummer = pvv.vluchtnummer
											   WHERE original_v.vertrektijdstip BETWEEN v.vertrektijdstip AND v.aankomsttijdstip
											   AND v.vluchtnummer != original_v.vluchtnummer))
		BEGIN
			;THROW 50000, 'Cannot book an overlapping flight', 1
		END
	END TRY
	BEGIN CATCH
		;THROW
	END CATCH
END
GO
