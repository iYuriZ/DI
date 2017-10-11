------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- Opgave 1: Voor elke passagier zijn het stoelnummer en het inchecktijdstip of beide niet ingevuld of beide wel ingevuld

-----------------------------------------
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

-- Opgave 3: Het inchecktijdstip van een passagier moet voor het vertrektijdstip van een vlucht liggen.

-----------------------------------------
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

------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- Opgave 5: Per passagier mogen maximaal 3 objecten worden ingecheckt. Tevens geldt: het totaalgewicht
--			 van de bagage van een passagier mag het maximaal per persoon toegestane gewicht op een vlucht
--			 niet overschrijden. Mocht de datapopulatie het aanbrengen van de constraint niet toestaan, neem
--			 dan maatregelen in uw uitwerkingsdocument.

-----------------------------------------
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

------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- Opgave 7: Voor een passagier is de combinatie (vlucht, stoel) natuurlijk uniek (zie de specs). Maar de
--			 mogelijke stoelnummers zijn op het moment van toevoegen van een passagier vaak nog niet bekend.
--			 Er moeten dus voor passagiers op dezelfde vlucht null-waarden voor hun stoelen in te vullen zijn.
--			 Maak dit mogelijk, zonder de uniciteits-eis voor concrete stoelnummers te schenden (maak geen gebruik
--			 van een zogenaamd filtered index).

-----------------------------------------
-- Trigger
CREATE TRIGGER trgPassagierVoorVlucht_stoel_IU
ON
	PassagierVoorVlucht
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

------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- Opgave 9: Elke maatschappij moet een balie hebben

-----------------------------------------
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


------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

-- Stored Procedures	: 1
-- Triggers				: 3
-- Constraints			: 1

