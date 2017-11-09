/****************************************************************************/
/* 4.	Elke vlucht heeft volgens de specs een toegestaan maximum aantal 	*/
/* passagiers. Zorg ervoor dat deze regel niet overschreden kan worden.		*/
/****************************************************************************/

-- Index op: PassagierVoorVlucht

/****************************************************************************/
/* 10.	Een passagier mag niet boeken op  vluchten in overlappende			*/
/* periodes. Verander de kolommen vertrektijdstip en aankomsttijdstip van	*/ 
/* table Vlucht in NOT NULL. Update eventueel vooraf de data zodat de 		*/
/* NOT NULL	constraint niet overtreden wordt.								*/
/****************************************************************************/

-- Index op: passagierVoorVlucht (tijdstippen OF stoel (constraint 7))
