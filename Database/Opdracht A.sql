-- Deze kan niet worden toegepast omdat een stoel NULL en een vluchtnummer NULL kunnen zijn
--ALTER TABLE PassagierVoorVlucht ADD CONSTRAINT AK_PassagierVoorVlucht_vluchtnummer_stoel UNIQUE(vluchtnummer, stoel);

ALTER TABLE LuchtHaven ADD CONSTRAINT AK_Luchthaven_naam UNIQUE(naam);
ALTER TABLE Maatschappij ADD CONSTRAINT AK_Maatschappij_naam UNIQUE(naam);
