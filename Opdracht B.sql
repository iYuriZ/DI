/****************************************************************************/
/* 1.	Voor elke passagier zijn het stoelnummer en het						*/
/* inchecktijdstip of beide niet ingevuld of beide wel ingevuld				*/
/****************************************************************************/

-- Constraint
ALTER TABLE PassagierVoorVlucht ADD CONSTRAINT CHK_IncheckTijdStip_Stoel CHECK ((inchecktijdstip IS NULL AND stoel IS NULL) OR 
																				(inchecktijdstip IS NOT NULL AND stoel IS NOT NULL));
-----------------------------------------
-- Werkende test
BEGIN TRANSACTION
INSERT INTO PassagierVoorVlucht (passagiernummer, vluchtnummer, balienummer, inchecktijdstip, stoel)
VALUES (850, 5315, 1, NULL, NULL),
	   (850, 5316, 1, GETDATE(), 20);
ROLLBACK TRANSACTION

-- Niet werkende test
BEGIN TRANSACTION
INSERT INTO PassagierVoorVlucht (passagiernummer, vluchtnummer, balienummer, inchecktijdstip, stoel)
VALUES (850, 5315, 1, GETDATE(), NULL),
	   (850, 5316, 1, NULL, 20);
ROLLBACK TRANSACTION

-----------------------------------------
-- Controle of de populatie niet bestaat uit 'foute' records
SELECT
	*
FROM
	PassagierVoorVlucht
WHERE
	(inchecktijdstip IS NULL AND stoel IS NOT NULL)
OR
	(inchecktijdstip IS NOT NULL AND stoel IS NULL);

/****************************************************************************/
/* 2.	Als er een passagier aan een vlucht is toegevoegd					*/ ----------------------------------------------------------------------------------
/* mogen de gegevens van die vlucht niet meer gewijzigd worden.				*/ -- Read committed
/****************************************************************************/

--Trigger
DROP TRIGGER IF EXISTS dbo.TRG_NO_UPDATE
GO
CREATE TRIGGER TRG_NO_UPDATE ON Vlucht 
AFTER UPDATE
AS
BEGIN
	IF @@ROWCOUNT = 0
		RETURN
	SET NOCOUNT ON
    BEGIN TRY
		IF EXISTS (SELECT pv.*
				   FROM vlucht v INNER JOIN PassagierVoorVlucht pv
				   ON v.vluchtnummer = pv.vluchtnummer
				   WHERE v.vluchtnummer = (SELECT vluchtnummer
										   FROM inserted))
		THROW 50001, 'No update allowed when the flight has passengers', 1
    END TRY
    BEGIN CATCH
        ;THROW
    END CATCH
END
GO

-------------------------------------
-- Werkende test
BEGIN TRAN
UPDATE vlucht
SET max_aantal_psgrs = 110 WHERE vluchtnummer = 5314
ROLLBACK TRAN

-- Niet werkende test
UPDATE vlucht
SET max_aantal_psgrs = 110 WHERE vluchtnummer = 5317

-- SELECT statements voor controle
SELECT * FROM PassagierVoorVlucht

SELECT pv.*
FROM vlucht v INNER JOIN PassagierVoorVlucht pv
ON v.vluchtnummer = pv.vluchtnummer
WHERE v.vluchtnummer = 5314

/****************************************************************************/
/* 3.	Het inchecktijdstip van een passagier moet							*/
/* voor het vertrektijdstip van een vlucht liggen.							*/
/****************************************************************************/

-- Trigger
CREATE TRIGGER trgPassagierVoorVlucht_inchecktijdstip_IU
ON
	PassagierVoorVlucht
AFTER INSERT, UPDATE
AS
BEGIN
	IF @@ROWCOUNT = 0
		RETURN
	SET NOCOUNT ON
	
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

-----------------------------------------
-- Werkende test
BEGIN TRANSACTION
UPDATE PassagierVoorVlucht SET incheckTijdstip = '2004-02-05 22:00' WHERE vluchtnummer = 5317; -- 5 records
INSERT INTO PassagierVoorVlucht (passagiernummer, vluchtnummer, balienummer, inchecktijdstip, stoel)
VALUES (1002, 5317, 1, '2004-02-05 22:00', 1); -- 1 record
ROLLBACK TRANSACTION

-- Niet werkende test
BEGIN TRANSACTION
UPDATE PassagierVoorVlucht SET incheckTijdstip = '2004-02-05 23:45' WHERE vluchtnummer = 5317; -- 5 records
INSERT INTO PassagierVoorVlucht (passagiernummer, vluchtnummer, balienummer, inchecktijdstip, stoel)
VALUES (1002, 5317, 1, '2004-02-05 23:45', 1); -- 1 record
ROLLBACK TRANSACTION

-----------------------------------------
-- Controle of de populatie niet bestaat uit 'foute' records
SELECT
	p.passagiernummer,
	p.vluchtnummer
FROM
	PassagierVoorVlucht p
	INNER JOIN Vlucht v ON v.vluchtnummer = p.vluchtnummer
WHERE
	p.inchecktijdstip < v.vertrektijdstip;

/****************************************************************************/
/* 4.	Elke vlucht heeft volgens de specs een toegestaan maximum aantal 	*/ ----------------------------------------------------------------------
/* passagiers. Zorg ervoor dat deze regel niet overschreden kan worden.		*/ -- Isolation level ophogen
/****************************************************************************/ -- Index passagiervoorvlucht

DROP PROCEDURE IF EXISTS dbo.PROC_COUNT_PASSENGERS
GO
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
		THROW 50001, 'Passenger limit exceeded for that flight', 1

		ELSE 
			INSERT INTO PassagierVoorVlucht
			 VALUES (@vluchtnr, @passagiernr, @balienr, @inchecktijd, @stoel)
	END TRY
	BEGIN CATCH
		THROW;
	END CATCH
END

-----------------------------------
-- test setup om de trigger (opgave 2.) te vermijden
BEGIN TRANSACTION
DROP TRIGGER IF EXISTS dbo.TRG_NO_UPDATE
GO
UPDATE vlucht SET max_aantal_psgrs = 10 WHERE vluchtnummer = 5317
ROLLBACK TRANSACTION

-- er is nog plek in de vlucht
BEGIN TRAN
EXEC dbo.PROC_COUNT_PASSENGERS 850,  5316, 1, '2004-02-05 22:25', 97
ROLLBACK TRAN

-- de vlucht is al vol
EXEC dbo.PROC_COUNT_PASSENGERS 855,  5320, 3, '2004-02-05 22:25', 80

-- SELECT statements voor controle
SELECT * 
FROM PassagierVoorVlucht
WHERE vluchtnummer = 5316

SELECT max_aantal_psgrs
FROM vlucht
WHERE vluchtnummer = 5317

SELECT COUNT(passagiernummer), vluchtnummer
FROM PassagierVoorVlucht
GROUP BY vluchtnummer

/****************************************************************************/
/* 5.	Per passagier mogen maximaal 3 objecten worden ingecheckt. 			*/
/* Tevens geldt: het totaalgewicht van de bagage van een passagier mag 		*/
/* het maximaal per persoon toegestane gewicht op een vlucht niet			*/
/* overschrijden. Mocht de datapopulatie het aanbrengen van de constraint	*/
/* niet toestaan, neem dan maatregelen in uw uitwerkingsdocument.			*/
/****************************************************************************/	 

-- Trigger
CREATE TRIGGER trgObject_aantal_gewicht_I
ON
	Object
AFTER INSERT
AS
BEGIN
	IF @@ROWCOUNT = 0
		RETURN
	SET NOCOUNT ON
	
	BEGIN TRY
		-- Aantal objecten > 3
		IF EXISTS (SELECT passagiernummer, vluchtnummer
				   FROM inserted
				   GROUP BY passagiernummer, vluchtnummer
				   HAVING COUNT(*) > 3)
		BEGIN
			;THROW 50000, 'Een passagier mag niet meer dan 3 objecten inchecken', 1
		END
		-- Totaal gewicht meer dan toegestaan op een vlucht
		ELSE IF EXISTS (SELECT i.passagiernummer, i.vluchtnummer, SUM(i.gewicht)
						FROM Inserted i INNER JOIN Vlucht v ON v.vluchtnummer = i.vluchtnummer
						GROUP BY i.passagiernummer, i.vluchtnummer, v.max_ppgewicht
						HAVING SUM(i.gewicht) > v.max_ppgewicht)
		BEGIN
			;THROW 50000, 'Het gewicht van de objecten mag niet hoger zijn dan het maximaal toegestane gewicht op een vlucht', 1
		END
	END TRY
	BEGIN CATCH
		;THROW
	END CATCH
END
GO

-----------------------------------------
-- Werkende test
BEGIN TRANSACTION
INSERT INTO PassagierVoorVlucht (passagiernummer, vluchtnummer, balienummer)
VALUES (850, 5315, 1),
	   (850, 5316, 1);

INSERT INTO Object (passagiernummer, vluchtnummer, gewicht)
VALUES (850, 5315, 5),
	   (850, 5315, 2),
	   (850, 5315, 3); -- Meerdere records
INSERT INTO Object (passagiernummer, vluchtnummer, gewicht)
VALUES (850, 5316, 3); -- 1 record
ROLLBACK TRANSACTION

-- Niet werkende test
-- Te veel gewicht
BEGIN TRANSACTION
INSERT INTO PassagierVoorVlucht (passagiernummer, vluchtnummer, balienummer)
VALUES (850, 5315, 1),
	   (850, 5316, 1),
	   (1337, 5315, 1);

INSERT INTO Object (passagiernummer, vluchtnummer, gewicht)
VALUES (850, 5315, 15),
	   (850, 5315, 6),
	   (1337, 5315, 8); -- Meerdere records
INSERT INTO Object (passagiernummer, vluchtnummer, gewicht)
VALUES (850, 5316, 14); -- 1 record
ROLLBACK TRANSACTION

-- Te veel objecten
BEGIN TRANSACTION
INSERT INTO PassagierVoorVlucht (passagiernummer, vluchtnummer, balienummer)
VALUES (850, 5315, 1);

INSERT INTO Object (passagiernummer, vluchtnummer, gewicht)
VALUES (850, 5315, 1),
	   (850, 5315, 2),
	   (850, 5315, 5),
	   (850, 5315, 2);
ROLLBACK TRANSACTION

-----------------------------------------
-- Controle of de populatie niet bestaat uit 'foute' records
-- Aantal objecten > 3
SELECT
	passagiernummer, vluchtnummer
FROM
	Object
GROUP BY
	passagiernummer, vluchtnummer
HAVING
	COUNT(*) > 3;

-- Totaal gewicht meer dan toegestaan op een vlucht
SELECT
	o.passagiernummer,
	o.vluchtnummer,
	v.max_ppgewicht,
	SUM(o.gewicht)
FROM
	Object o INNER JOIN Vlucht v ON v.vluchtnummer = o.vluchtnummer
GROUP BY
	o.passagiernummer,
	o.vluchtnummer,
	v.max_ppgewicht
HAVING
	SUM(o.gewicht) > v.max_ppgewicht;		 

/****************************************************************************/
/* 6.	Elke vlucht heeft volgens de specs een toegestaan maximum aantal 	*/
/* passagiers (map, een toegestaan maximum totaalgewicht (mt), en een		*/
/* maximum gewicht dat een persoon mee mag nemen (mgp). Zorg ervoor dat		*/
/* altijd geld map*mgp <= mt.												*/
/****************************************************************************/
CREATE PROCEDURE prc_VluchtMaxGewicht
	@vluchtnummer INT,
	@gatecode CHAR(1),
	@maatschappijcode CHAR(2),
	@luchthavencode CHAR(3),
	@vliegtuigtype CHAR(30),
	@max_aantal_psgrs NUMERIC(5,0),
	@max_totaalgewicht NUMERIC(5,0),
	@max_ppgewicht NUMERIC(5,2),
	@vertrektijdstip DATETIME,
	@aankomsttijdstip DATETIME
AS
BEGIN
	IF (@max_aantal_psgrs * @max_ppgewicht > @max_totaalgewicht)
	BEGIN
		;THROW 50000, 'The maximum total weight is too low', 1
	END

	INSERT INTO Vlucht (vluchtnummer, gatecode, maatschappijcode, luchthavencode, vliegtuigtype, max_aantal_psgrs, max_totaalgewicht, max_ppgewicht, vertrektijdstip, aankomsttijdstip)
	VALUES (@vluchtnummer, @gatecode, @maatschappijcode, @luchthavencode, @vliegtuigtype, @max_aantal_psgrs, @max_totaalgewicht, @max_ppgewicht, @vertrektijdstip, @aankomsttijdstip)
END
GO

---------------------------------
-- werkende test
BEGIN TRANSACTION
DECLARE @vertrek DATETIME = GETDATE() -2
DECLARE @aankomst DATETIME = GETDATE() + 1

EXEC prc_VluchtMaxGewicht
	@vluchtnummer = 5319,
	@gatecode = 'C',
	@maatschappijcode = 'KL',
	@luchthavencode = 'DUB',
	@vliegtuigtype = 'Boeing 747',
	@max_aantal_psgrs = 120,
	@max_totaalgewicht = 2500,
	@max_ppgewicht = 20,
	@vertrektijdstip = @vertrek,
	@aankomsttijdstip = @aankomst;
ROLLBACK TRANSACTION

-- niet werkende test
BEGIN TRANSACTION
DECLARE @vertrek DATETIME = GETDATE() -2
DECLARE @aankomst DATETIME = GETDATE() + 1

EXEC prc_VluchtMaxGewicht
	@vluchtnummer = 5319,
	@gatecode = 'C',
	@maatschappijcode = 'KL',
	@luchthavencode = 'DUB',
	@vliegtuigtype = 'Boeing 747',
	@max_aantal_psgrs = 120,
	@max_totaalgewicht = 20,
	@max_ppgewicht = 20,
	@vertrektijdstip = @vertrek,
	@aankomsttijdstip = @aankomst;
ROLLBACK TRANSACTION

-- SELECT statements voor controle
SELECT *
FROM vlucht

/****************************************************************************/
/* 7.	Voor een passagier is de combinatie (vlucht, stoel) natuurlijk		*/
/* uniek (zie de specs). Maar de mogelijke stoelnummers zijn op het moment	*/
/* van toevoegen van een passagier vaak nog niet bekend. Er moeten dus voor	*/
/* passagiers op dezelfde vlucht null-waarden voor hun stoelen in te vullen	*/
/* zijn. Maak dit mogelijk, zonder uniciteits-eis voor concrete stoelnummers*/
/* te schenden (maak geen gebruik van een zogenaamd filtered index).		*/
/****************************************************************************/

-- Trigger
CREATE TRIGGER trgPassagierVoorVlucht_stoel_IU ON PassagierVoorVlucht
AFTER INSERT, UPDATE
AS
BEGIN
	IF @@ROWCOUNT = 0
		RETURN
	SET NOCOUNT ON
	
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

-----------------------------------------
-- Werkende test
BEGIN TRANSACTION
INSERT INTO PassagierVoorVlucht (passagiernummer, vluchtnummer, balienummer, inchecktijdstip, stoel)
VALUES (1002, 5317, 1, '2004-02-05 22:00', 20);
ROLLBACK TRANSACTION

-- Niet werkende test
BEGIN TRANSACTION
INSERT INTO PassagierVoorVlucht (passagiernummer, vluchtnummer, balienummer, inchecktijdstip, stoel)
VALUES (1002, 5317, 1, '2004-02-05 22:00', 75);
ROLLBACK TRANSACTION

-----------------------------------------
-- Controle of de populatie niet bestaat uit 'foute' records
SELECT
	vluchtnummer,
	stoel,
	COUNT(*) as [Aantal dubbele stoelen]
FROM
	PassagierVoorVlucht
GROUP BY
	vluchtnummer,
	stoel
HAVING
	COUNT(*) >= 2;

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
DROP TRIGGER IF EXISTS dbo.trg_IncheckenVoorVlucht_IU
GO
CREATE TRIGGER dbo.trg_IncheckenVoorVlucht_IU ON IncheckenVoorVlucht
AFTER INSERT, UPDATE
AS
BEGIN
	IF @@ROWCOUNT = 0
		RETURN
	SET NOCOUNT ON	
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

DROP TRIGGER IF EXISTS dbo.trg_PassagierVoorVlucht_IU
GO
CREATE TRIGGER dbo.trg_PassagierVoorVlucht_IU ON PassagierVoorVlucht
AFTER INSERT, UPDATE
AS
BEGIN
	IF @@ROWCOUNT = 0
		RETURN
	SET NOCOUNT ON	
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

--------------------------------
-- werkende test
BEGIN TRANSACTION
DELETE FROM IncheckenVoorVlucht WHERE vluchtnummer = 5314;

INSERT INTO IncheckenVoorVlucht
VALUES (3, 5314);
ROLLBACK TRANSACTION

BEGIN TRANSACTION
	INSERT INTO PassagierVoorVlucht
	VALUES (850, 5314, 3, DATEDIFF(year, -10, GETDATE()), 4);
ROLLBACK TRANSACTION

-- niet werkende test
INSERT INTO IncheckenVoorVlucht
VALUES (2, 5314);

INSERT INTO PassagierVoorVlucht
VALUES (850, 5314, 2, GETDATE(), 4);

-- SELECT statements voor controle
SELECT *
FROM IncheckenVoorBestemming

SELECT * FROM
Balie;

SELECT *
FROM IncheckenVoorVlucht

SELECT *
FROM IncheckenBijMaatschappij

SELECT *
FROM vlucht

SELECT *
FROM PassagierVoorVlucht

/****************************************************************************/
/* 9.	Elke maatschappij moet een balie hebben								*/
/****************************************************************************/

-- Stored Procedure
CREATE PROCEDURE prcMaatschappij_balie
	@balieNummer INT,
	@maatschappijCode CHAR(2),
	@maatschappijNaam VARCHAR(255)
AS
BEGIN
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
		;THROW
	END CATCH
END
GO

-----------------------------------------
-- Werkende test
BEGIN TRANSACTION
EXEC prcMaatschappij_balie @balieNummer = 1, @maatschappijCode = 'TT', @maatschappijNaam = 'MaatschappijTest'

SELECT *
FROM Maatschappij m
INNER JOIN IncheckenBijMaatschappij ibm ON ibm.maatschappijcode = m.maatschappijcode
INNER JOIN Balie b ON b.balienummer = ibm.balienummer
WHERE m.maatschappijcode = 'TT';
ROLLBACK TRANSACTION

-- Niet werkende test
BEGIN TRANSACTION
	EXEC prcMaatschappij_balie @balieNummer = 999, @maatschappijCode = 'tt', @maatschappijNaam = 'MaatschappijTest'
ROLLBACK TRANSACTION

-----------------------------------------
-- Controle of de populatie niet bestaat uit 'foute' records
SELECT
	m.maatschappijcode,
	m.naam,
	ISNULL((SELECT COUNT(*)
	 FROM IncheckenBijMaatschappij
	 WHERE maatschappijcode = m.maatschappijcode
	 GROUP BY maatschappijcode), 0) as [Aantal Balies]
FROM
	Maatschappij m;

/****************************************************************************/
/* 10.	Een passagier mag niet boeken op  vluchten in overlappende			*/
/* periodes. Verander de kolommen vertrektijdstip en aankomsttijdstip van	*/ 
/* table Vlucht in NOT NULL. Update eventueel vooraf de data zodat de 		*/
/* NOT NULL	constraint niet overtreden wordt.								*/ -- Index passagierVoorVlucht (tijdstippen OF stoel (constraint 7))
/****************************************************************************/
UPDATE Vlucht
SET aankomsttijdstip = DATEDIFF(year, 1, GETDATE())
WHERE aankomsttijdstip IS NULL;

ALTER TABLE Vlucht
ALTER COLUMN vertrektijdstip DATETIME NOT NULL;
ALTER TABLE Vlucht
ALTER COLUMN aankomsttijdstip DATETIME NOT NULL;

CREATE TRIGGER trg_PassagierVoorVlucht_overlapping_IU
ON
	PassagierVoorVlucht
AFTER INSERT, UPDATE
AS
BEGIN
	IF @@ROWCOUNT = 0
		RETURN
	SET NOCOUNT ON

	BEGIN TRY
		IF EXISTS (SELECT * FROM inserted WHERE 
	END TRY
	BEGIN CATCH
		;THROW
	END CATCH
END

------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- Stored Procedures	: 3
-- Triggers				: 5
-- Constraints			: 1

