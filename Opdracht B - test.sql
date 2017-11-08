SET NOCOUNT ON

/****************************************************************************/
/* 1.	Voor elke passagier zijn het stoelnummer en het						*/
/* inchecktijdstip of beide niet ingevuld of beide wel ingevuld				*/
/****************************************************************************/

-- Werkende test
BEGIN TRANSACTION
	BEGIN TRY
		INSERT INTO PassagierVoorVlucht (passagiernummer, vluchtnummer, balienummer, inchecktijdstip, stoel)
		VALUES (850, 5315, 1, NULL, NULL),
		   (850, 5316, 1, '2004-01-31 08:00', 20);
		   
		PRINT 'Constraint 1 - test 1: Geslaagd'
	END TRY
	BEGIN CATCH
		;THROW
		PRINT 'Constraint 1 - test 1: Gefaald'
	END CATCH
ROLLBACK TRANSACTION

-- Niet werkende test
BEGIN TRANSACTION
	BEGIN TRY
			INSERT INTO PassagierVoorVlucht (passagiernummer, vluchtnummer, balienummer, inchecktijdstip, stoel)
			VALUES (850, 5315, 1, GETDATE(), NULL),
				   (850, 5316, 1, NULL, 20);
			
			PRINT 'Constraint 1 - test 2: Gefaald'
	END TRY
	BEGIN CATCH
		PRINT 'Constraint 1 - test 2: Geslaagd'
	END CATCH
ROLLBACK TRANSACTION

/****************************************************************************/
/* 2.	Als er een passagier aan een vlucht is toegevoegd					*/
/* mogen de gegevens van die vlucht niet meer gewijzigd worden.				*/
/****************************************************************************/

-- Werkende test
BEGIN TRANSACTION
	BEGIN TRY
		UPDATE vlucht
		SET max_aantal_psgrs = 110 WHERE vluchtnummer = 5314
		
		PRINT 'Constraint 2 - test 1: Geslaagd'
	END TRY
	BEGIN CATCH
		PRINT 'Constraint 2 - test 1: Gefaald'
	END CATCH
ROLLBACK TRANSACTION

-- Niet werkende test
BEGIN TRANSACTION
	BEGIN TRY
		UPDATE vlucht
		SET max_aantal_psgrs = 110 WHERE vluchtnummer = 5317

		PRINT 'Constraint 2 - test 2: Gefaald'
	END TRY
	BEGIN CATCH
		PRINT 'Constraint 2 - test 2: Geslaagd'
	END CATCH
ROLLBACK TRANSACTION

/****************************************************************************/
/* 3.	Het inchecktijdstip van een passagier moet							*/
/* voor het vertrektijdstip van een vlucht liggen.							*/
/****************************************************************************/

-- Werkende test
BEGIN TRANSACTION
	BEGIN TRY
		UPDATE PassagierVoorVlucht SET incheckTijdstip = '2004-02-05 22:00' WHERE vluchtnummer = 5317; -- 5 records
		INSERT INTO PassagierVoorVlucht (passagiernummer, vluchtnummer, balienummer, inchecktijdstip, stoel)
		VALUES (1002, 5317, 2, '2004-02-05 22:00', 1); -- 1 record
		
		PRINT 'Constraint 3 - test 1: Geslaagd'
	END TRY
	BEGIN CATCH
		;THROW
		PRINT 'Constraint 3 - test 1: Gefaald'
	END CATCH
ROLLBACK TRANSACTION

-- Niet werkende test
BEGIN TRANSACTION
	BEGIN TRY
		UPDATE PassagierVoorVlucht SET incheckTijdstip = '2004-02-05 23:45' WHERE vluchtnummer = 5317; -- 5 records
		INSERT INTO PassagierVoorVlucht (passagiernummer, vluchtnummer, balienummer, inchecktijdstip, stoel)
		VALUES (1002, 5317, 1, '2004-02-05 23:45', 1); -- 1 record
		
		PRINT 'Constraint 3 - test 2: Gefaald'
	END TRY
	BEGIN CATCH
		PRINT 'Constraint 3 - test 2: Geslaagd'
	END CATCH
ROLLBACK TRANSACTION

/****************************************************************************/
/* 4.	Elke vlucht heeft volgens de specs een toegestaan maximum aantal 	*/
/* passagiers. Zorg ervoor dat deze regel niet overschreden kan worden.		*/
/****************************************************************************/

-- Werkende test
BEGIN TRANSACTION
	BEGIN TRY
		EXEC PROC_COUNT_PASSENGERS
			@passagiernr = 850, 
			@vluchtnr = 5316,
			@balienr = 1,
			@inchecktijd = '2004-01-31 22:25',
			@stoel = 97
		
		PRINT 'Constraint 4 - test 1: Geslaagd'
	END TRY
	BEGIN CATCH
		;THROW
		PRINT 'Constraint 4 - test 1: Gefaald'
	END CATCH
ROLLBACK TRANSACTION

-- Niet werkende test
BEGIN TRANSACTION
	BEGIN TRY
		EXEC PROC_COUNT_PASSENGERS
			@passagiernr = 855, 
			@vluchtnr = 5320,
			@balienr = 3,
			@inchecktijd = '2004-02-05 22:25',
			@stoel = 80
		
		PRINT 'Constraint 4 - test 2: Gefaald'
	END TRY
	BEGIN CATCH
		PRINT 'Constraint 4 - test 2: Geslaagd'
	END CATCH
ROLLBACK TRANSACTION

/****************************************************************************/
/* 5.	Per passagier mogen maximaal 3 objecten worden ingecheckt. 			*/
/* Tevens geldt: het totaalgewicht van de bagage van een passagier mag 		*/
/* het maximaal per persoon toegestane gewicht op een vlucht niet			*/
/* overschrijden. Mocht de datapopulatie het aanbrengen van de constraint	*/
/* niet toestaan, neem dan maatregelen in uw uitwerkingsdocument.			*/
/****************************************************************************/	

-- Werkende test
BEGIN TRANSACTION
	BEGIN TRY
		INSERT INTO PassagierVoorVlucht (passagiernummer, vluchtnummer, balienummer)
		VALUES (850, 5315, 1),
			   (850, 5316, 1);

		INSERT INTO Object (passagiernummer, vluchtnummer, gewicht)
		VALUES (850, 5315, 5),
			   (850, 5315, 2),
			   (850, 5315, 3); -- Meerdere records
		INSERT INTO Object (passagiernummer, vluchtnummer, gewicht)
		VALUES (850, 5316, 3); -- 1 record
		
		PRINT 'Constraint 5 - test 1: Geslaagd'
	END TRY
	BEGIN CATCH
		PRINT 'Constraint 5 - test 1: Gefaald'
	END CATCH
ROLLBACK TRANSACTION

-- Niet werkende test 1
BEGIN TRANSACTION
	BEGIN TRY
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
		
		PRINT 'Constraint 5 - test 2: Gefaald'
	END TRY
	BEGIN CATCH
		PRINT 'Constraint 5 - test 2: Geslaagd'
	END CATCH
ROLLBACK TRANSACTION

-- Niet werkende test 2
BEGIN TRANSACTION
	BEGIN TRY
		INSERT INTO PassagierVoorVlucht (passagiernummer, vluchtnummer, balienummer)
		VALUES (850, 5315, 1);

		INSERT INTO Object (passagiernummer, vluchtnummer, gewicht)
		VALUES (850, 5315, 1),
			   (850, 5315, 2),
			   (850, 5315, 5),
			   (850, 5315, 2);

		PRINT 'Constraint 5 - test 3: Gefaald'
	END TRY
	BEGIN CATCH
		PRINT 'Constraint 5 - test 3: Geslaagd'
	END CATCH
ROLLBACK TRANSACTION

/****************************************************************************/
/* 6.	Elke vlucht heeft volgens de specs een toegestaan maximum aantal 	*/
/* passagiers (map, een toegestaan maximum totaalgewicht (mt), en een		*/
/* maximum gewicht dat een persoon mee mag nemen (mgp). Zorg ervoor dat		*/
/* altijd geld map*mgp <= mt.												*/
/****************************************************************************/

-- Variabelen initialiseren
DECLARE @vertrek DATETIME = GETDATE() -2
DECLARE @aankomst DATETIME = GETDATE() + 1

-- werkende test
BEGIN TRANSACTION
	BEGIN TRY
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
			
		PRINT 'Constraint 6 - test 1: Geslaagd'
	END TRY
	BEGIN CATCH
		PRINT 'Constraint 6 - test 1: Gefaald'
	END CATCH
ROLLBACK TRANSACTION

-- niet werkende test
BEGIN TRANSACTION
	BEGIN TRY
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
			
		PRINT 'Constraint 6 - test 2: Gefaald'
	END TRY
	BEGIN CATCH
		PRINT 'Constraint 6 - test 2: Geslaagd'
	END CATCH
ROLLBACK TRANSACTION


/****************************************************************************/
/* 7.	Voor een passagier is de combinatie (vlucht, stoel) natuurlijk		*/
/* uniek (zie de specs). Maar de mogelijke stoelnummers zijn op het moment	*/
/* van toevoegen van een passagier vaak nog niet bekend. Er moeten dus voor	*/
/* passagiers op dezelfde vlucht null-waarden voor hun stoelen in te vullen	*/
/* zijn. Maak dit mogelijk, zonder uniciteits-eis voor concrete stoelnummers*/
/* te schenden (maak geen gebruik van een zogenaamd filtered index).		*/
/****************************************************************************/

-- Werkende test
BEGIN TRANSACTION
	BEGIN TRY
		INSERT INTO PassagierVoorVlucht (passagiernummer, vluchtnummer, balienummer, inchecktijdstip, stoel)
		VALUES (1002, 5317, 2, '2004-02-05 22:00', 20);
		
		PRINT 'Constraint 7 - test 1: Geslaagd'
	END TRY
	BEGIN CATCH
		;THROW
		PRINT 'Constraint 7 - test 1: Gefaald'
	END CATCH
ROLLBACK TRANSACTION

-- Niet werkende test
BEGIN TRANSACTION
	BEGIN TRY
		INSERT INTO PassagierVoorVlucht (passagiernummer, vluchtnummer, balienummer, inchecktijdstip, stoel)
		VALUES (1002, 5317, 1, '2004-02-05 22:00', 75);
		
		PRINT 'Constraint 7 - test 2: Gefaald'
	END TRY
	BEGIN CATCH
		PRINT 'Constraint 7 - test 2: Geslaagd'
	END CATCH
ROLLBACK TRANSACTION

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

-- werkende test 1
BEGIN TRANSACTION
	BEGIN TRY
		DELETE FROM IncheckenVoorVlucht WHERE vluchtnummer = 5314;

		INSERT INTO IncheckenVoorVlucht
		VALUES (3, 5314);
		
		PRINT 'Constraint 8 - test 1: Geslaagd'
	END TRY
	BEGIN CATCH
		PRINT 'Constraint 8 - test 1: Gefaald'
	END CATCH
ROLLBACK TRANSACTION

-- werkende test 2
BEGIN TRANSACTION
	BEGIN TRY
		INSERT INTO PassagierVoorVlucht
		VALUES (850, 5314, 3, DATEDIFF(year, -10, GETDATE()), 4);
		
		PRINT 'Constraint 8 - test 2: Geslaagd'
	END TRY
	BEGIN CATCH
		PRINT 'Constraint 8 - test 2: Gefaald'
	END CATCH
ROLLBACK TRANSACTION

-- niet werkende test 1
BEGIN TRANSACTION
	BEGIN TRY
		INSERT INTO IncheckenVoorVlucht
		VALUES (2, 5314);

		PRINT 'Constraint 8 - test 3: Gefaald'
	END TRY
	BEGIN CATCH
		PRINT 'Constraint 8 - test 3: Geslaagd'
	END CATCH
ROLLBACK TRANSACTION

-- niet werkende test 2
BEGIN TRANSACTION
	BEGIN TRY
		INSERT INTO PassagierVoorVlucht
		VALUES (850, 5314, 2, GETDATE(), 4);
		
		PRINT 'Constraint 8 - test 4: Gefaald'
	END TRY
	BEGIN CATCH
		PRINT 'Constraint 8 - test 4: Geslaagd'
	END CATCH
ROLLBACK TRANSACTION

/****************************************************************************/
/* 9.	Elke maatschappij moet een balie hebben								*/
/****************************************************************************/

-- Werkende test
BEGIN TRANSACTION
	BEGIN TRY
		EXEC prcMaatschappij_balie @balieNummer = 1, @maatschappijCode = 'TT', @maatschappijNaam = 'MaatschappijTest'
		
		PRINT 'Constraint 9 - test 1: Geslaagd'
	END TRY
	BEGIN CATCH
		PRINT 'Constraint 9 - test 1: Gefaald'
	END CATCH
ROLLBACK TRANSACTION

-- Niet werkende test
BEGIN TRANSACTION
	BEGIN TRY
		EXEC prcMaatschappij_balie @balieNummer = 999, @maatschappijCode = 'tt', @maatschappijNaam = 'MaatschappijTest'
		
		PRINT 'Constraint 9 - test 2: Gefaald'
	END TRY
	BEGIN CATCH
		PRINT 'Constraint 9 - test 2: Geslaagd'
	END CATCH
ROLLBACK TRANSACTION

/****************************************************************************/
/* 10.	Een passagier mag niet boeken op  vluchten in overlappende			*/
/* periodes. Verander de kolommen vertrektijdstip en aankomsttijdstip van	*/ 
/* table Vlucht in NOT NULL. Update eventueel vooraf de data zodat de 		*/
/* NOT NULL	constraint niet overtreden wordt.								*/
/****************************************************************************/


-- Werkende test
BEGIN TRANSACTION
	BEGIN TRY
		INSERT INTO PassagierVoorVlucht (passagiernummer, vluchtnummer, balienummer, inchecktijdstip, stoel)
		VALUES (850, 5316, 1, '2004-02-01 12:00:00', 3);

		PRINT 'Constraint 10 - test 1: Geslaagd'
	END TRY
	BEGIN CATCH
		PRINT 'Constraint 10 - test 1: Gefaald'
	END CATCH
ROLLBACK TRANSACTION

-- Niet werkende test
BEGIN TRANSACTION
	BEGIN TRY
		UPDATE vlucht SET
		vertrektijdstip = '2004-01-31 23:37:00',
		aankomsttijdstip = vertrektijdstip + 100 -- 100 dagen toevoegen aan aankomsttijdstip
		WHERE vluchtnummer = 5317;

		INSERT INTO PassagierVoorVlucht (passagiernummer, vluchtnummer, balienummer, inchecktijdstip, stoel)
		VALUES (1500, 5316, 1, '2004-02-01 12:00:00', 3);

		PRINT 'Constraint 10 - test 2: Gefaald'
	END TRY
	BEGIN CATCH
		PRINT 'Constraint 10 - test 2: Geslaagd'
	END CATCH
ROLLBACK TRANSACTION
