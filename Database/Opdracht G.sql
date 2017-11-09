CREATE LOGIN bm
WITH PASSWORD = '1234';
GO

CREATE USER baliemedewerker
FOR LOGIN bm;
GO

GRANT SELECT, INSERT, UPDATE ,DELETE ON Object TO baliemedewerker
GO
GRANT SELECT, UPDATE ON PassagierVoorVlucht TO baliemedewerker
GO
GRANT SELECT ON vlucht TO baliemedewerker
GO
GRANT SELECT ON passagier TO baliemedewerker
GO
GRANT SELECT ON balie TO baliemedewerker

EXECUTE AS USER = 'baliemedewerker'
GO

-- werkt niet
SELECT * FROM Gate

-- werkt wel
SELECT * FROM Balie

-- stop met gebruiken van user.
REVERT
GO