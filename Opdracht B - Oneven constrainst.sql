------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- 
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
/* 2.	Als er een passagier aan een vlucht is toegevoegd					*/
/* mogen de gegevens van die vlucht niet meer gewijzigd worden.				*/
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
		THROW 50001, 'No update allowed when the flight has passangers', 1
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
/* 4.	Elke vlucht heeft volgens de specs een toegestaan maximum aantal 	*/
/* passagiers. Zorg ervoor dat deze regel niet overschreden kan worden.		*/
/****************************************************************************/

DROP PROCEDURE IF EXISTS dbo.PROC_COUNT_PASSANGERS
GO
CREATE PROCEDURE dbo.PROC_COUNT_PASSANGERS
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

		ELSE INSERT INTO PassagierVoorVlucht
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
EXEC dbo.PROC_COUNT_PASSANGERS 850,  5316, 1, '2004-02-05 22:25', 97
ROLLBACK TRAN

-- de vlucht is al vol
EXEC dbo.PROC_COUNT_PASSANGERS 855,  5317, 3, '2004-02-05 22:25', 80

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

DROP TRIGGER IF EXISTS dbo.TRG_MAX_WEIGHT
GO
CREATE TRIGGER TRG_MAX_WEIGHT ON Vlucht 
AFTER INSERT, UPDATE
AS
BEGIN
	IF @@ROWCOUNT = 0
		RETURN
	SET NOCOUNT ON
    BEGIN TRY
		IF (SELECT max_aantal_psgrs
			FROM vlucht
			WHERE vluchtnummer = (SELECT vluchtnummer FROM inserted)) 
		* (SELECT max_ppgewicht 
		   FROM vlucht
		   WHERE vluchtnummer = (SELECT vluchtnummer FROM inserted)) 
		> (SELECT max_totaalgewicht
		   FROM vlucht
		   WHERE vluchtnummer = (SELECT vluchtnummer FROM inserted))
		THROW 50001, 'The maximum total weight is too low', 1
    END TRY
    BEGIN CATCH
        ;THROW
    END CATCH
END
GO

---------------------------------
-- werkende test
BEGIN TRAN
UPDATE vlucht
SET max_aantal_psgrs = 120 WHERE vluchtnummer = 5314
ROLLBACK TRAN

-- niet werkende test
BEGIN TRAN
UPDATE vlucht
SET max_aantal_psgrs = 126 WHERE vluchtnummer = 5314
ROLLBACK TRAN

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
/* een vlucht gekoppeld worden, mogen dat alléén balies zijn die toegestaan */
/* zijn voor de maatschappij en voor de bestemming van de vlucht. Er kunnen */
/* aan één vlucht meerdere balies gekoppeld worden. De passagier checkt		*/
/* uiteindelijk bij één van deze balies in. Let op; dit laatste is dus ook	*/
/* een constraint.															*/
/****************************************************************************/
DROP TRIGGER IF EXISTS dbo.CHECK_BALIE_MAATSCHAPPIJ
GO
CREATE TRIGGER dbo.CHECK_BALIE ON PassagierVoorVlucht
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

--------------------------------
-- werkende test

-- niet werkende test

-- SELECT statements voor controle

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
	@maatschappijCode CHAR(2),
	@naam VARCHAR(255)
AS
BEGIN
	BEGIN TRY
		DECLARE @balienummer INT
		SELECT @balienummer = balienummer + 1 FROM Balie;
		
		INSERT INTO Balie (balienummer)
		VALUES (@balienummer);

		INSERT INTO Maatschappij (maatschappijcode, naam)
		VALUES (@maatschappijcode, @naam);
		
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
EXEC prcMaatschappij_balie @maatschappijCode = 'TT', @naam = 'MaatschappijTest'

SELECT *
FROM Maatschappij m
INNER JOIN IncheckenBijMaatschappij ibm ON ibm.maatschappijcode = m.maatschappijcode
INNER JOIN Balie b ON b.balienummer = ibm.balienummer
WHERE m.maatschappijcode = 'TT';
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
/* NOT NULL	constraint niet overtreden wordt.								*/
/****************************************************************************/

------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- Stored Procedures	: 2
-- Triggers				: 5
-- Constraints			: 1

