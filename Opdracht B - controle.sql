/****************************************************************************/
/* 1.	Voor elke passagier zijn het stoelnummer en het						*/
/* inchecktijdstip of beide niet ingevuld of beide wel ingevuld				*/
/****************************************************************************/
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
SELECT * FROM PassagierVoorVlucht

SELECT pv.*
FROM vlucht v INNER JOIN PassagierVoorVlucht pv
ON v.vluchtnummer = pv.vluchtnummer
WHERE v.vluchtnummer = 5314

/****************************************************************************/
/* 3.	Het inchecktijdstip van een passagier moet							*/
/* voor het vertrektijdstip van een vlucht liggen.							*/
/****************************************************************************/
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
SELECT
	v.vluchtnummer,
	v.max_aantal_psgrs,
	COUNT (*) as [Daadwerkelijke aantal passagiers]
FROM
	Vlucht v INNER JOIN PassagierVoorVlucht pvv
	ON pvv.vluchtnummer = v.vluchtnummer
GROUP BY
	v.vluchtnummer,
	v.max_aantal_psgrs;

/****************************************************************************/
/* 5.	Per passagier mogen maximaal 3 objecten worden ingecheckt. 			*/
/* Tevens geldt: het totaalgewicht van de bagage van een passagier mag 		*/
/* het maximaal per persoon toegestane gewicht op een vlucht niet			*/
/* overschrijden. Mocht de datapopulatie het aanbrengen van de constraint	*/
/* niet toestaan, neem dan maatregelen in uw uitwerkingsdocument.			*/
/****************************************************************************/	
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
SELECT *
FROM PassagierVoorVlucht pvv INNER JOIN Vlucht original_v
ON original_v.vluchtnummer = pvv.vluchtnummer
WHERE pvv.passagiernummer IN (SELECT passagiernummer
							FROM PassagierVoorVlucht pvv INNER JOIN Vlucht v
							ON v.vluchtnummer = pvv.vluchtnummer
							WHERE original_v.vertrektijdstip BETWEEN v.vertrektijdstip AND v.aankomsttijdstip
							AND v.vluchtnummer != original_v.vluchtnummer)