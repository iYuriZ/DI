/*==============================================================*/
/* Database name:  GELRE_AIRPORT                                */
/* DBMS name:      Microsoft SQL Server 2008-2016               */
/* Created on:     27-1-2016		                            */
/* DDL SCRIPT   												*/
/*==============================================================*/
USE master;
GO

IF DB_ID('gelre_airport') IS NOT NULL
     DROP DATABASE gelre_airport
GO

/*==============================================================*/
/* Database: gelre_airport                                      */
/*==============================================================*/
CREATE DATABASE gelre_airport
GO

USE gelre_airport
GO

/*==============================================================*/
/* Table: Balie                                                 */
/*==============================================================*/
CREATE TABLE Balie (
   balienummer          INT                  NOT NULL,
   CONSTRAINT pk_balie PRIMARY KEY (balienummer)
)
GO

/*==============================================================*/
/* Table: Gate                                                  */
/*==============================================================*/
CREATE TABLE Gate (
   gatecode             CHAR(1)              NOT NULL,
   CONSTRAINT pk_gate PRIMARY KEY (gatecode)
)
GO

/*==============================================================*/
/* Table: Maatschappij                                          */
/*==============================================================*/
CREATE TABLE Maatschappij (
   maatschappijcode     CHAR(2)              NOT NULL,
   naam                 VARCHAR(255)         NOT NULL,
   CONSTRAINT pk_maatschappij PRIMARY KEY (maatschappijcode)
)
GO

/*==============================================================*/
/* Table: IncheckenBijMaatschappij                              */
/*==============================================================*/
CREATE TABLE IncheckenBijMaatschappij (
   balienummer          INT                  NOT NULL,
   maatschappijcode     CHAR(2)              NOT NULL,
   CONSTRAINT pk_incheckenbijmaatschappij PRIMARY KEY (balienummer, maatschappijcode),
   CONSTRAINT fk_inchecken_ref_maatschappij FOREIGN KEY (maatschappijcode)
      REFERENCES Maatschappij (maatschappijcode) ON UPDATE CASCADE ON DELETE CASCADE,
   CONSTRAINT fk_incheckenmaatschappij_ref_balie FOREIGN KEY (balienummer)
      REFERENCES Balie (balienummer) ON UPDATE CASCADE ON DELETE CASCADE
)
GO

/*==============================================================*/
/* Table: Luchthaven                                            */
/*==============================================================*/
CREATE TABLE Luchthaven (
   luchthavencode       CHAR(3)              NOT NULL,
   naam                 VARCHAR(255)         NOT NULL,
   land                 VARCHAR(255)         NULL,
   CONSTRAINT pk_luchthaven PRIMARY KEY (luchthavencode),
)
GO

/*==============================================================*/
/* Table: IncheckenVoorBestemming                               */
/*==============================================================*/
CREATE TABLE IncheckenVoorBestemming (
   balienummer          INT                  NOT NULL,
   luchthavencode       CHAR(3)              NOT NULL,
   CONSTRAINT pk_incheckenvoorbestemming PRIMARY KEY (balienummer, luchthavencode),
   CONSTRAINT fk_incheckenbestemming_ref_luchthaven FOREIGN KEY (luchthavencode)
      REFERENCES Luchthaven (luchthavencode) ON UPDATE CASCADE ON DELETE CASCADE,
   CONSTRAINT fk_incheckenbestemming_ref_balie FOREIGN KEY (balienummer)
      REFERENCES Balie (balienummer) ON UPDATE CASCADE ON DELETE CASCADE
)
GO

/*==============================================================*/
/* Table: Vliegtuig                                             */
/*==============================================================*/
CREATE TABLE Vliegtuig (
   vliegtuigtype        VARCHAR(30)          NOT NULL,
   CONSTRAINT pk_vliegtuig PRIMARY KEY (vliegtuigtype)
)
GO

/*==============================================================*/
/* Table: Vlucht                                                */
/*==============================================================*/
CREATE TABLE Vlucht (
   vluchtnummer         INT                  NOT NULL,
   gatecode             CHAR(1)              NOT NULL,
   maatschappijcode     CHAR(2)              NOT NULL,
   luchthavencode       CHAR(3)              NOT NULL,
   vliegtuigtype        VARCHAR(30)          NOT NULL,
   max_aantal_psgrs     INT                  NOT NULL,
   max_totaalgewicht    NUMERIC(5)           NOT NULL,
   max_ppgewicht        NUMERIC(5,2)         NOT NULL,
   vertrektijdstip      DATETIME             NULL,
   aankomsttijdstip     DATETIME             NULL,
   CONSTRAINT pk_vlucht PRIMARY KEY (vluchtnummer),
   CONSTRAINT fk_vlucht_ref_gate FOREIGN KEY (gatecode)
      REFERENCES Gate (gatecode) ON UPDATE CASCADE ON DELETE NO ACTION,
   CONSTRAINT fk_vlucht_ref_maatschappij FOREIGN KEY (maatschappijcode)
      REFERENCES Maatschappij (maatschappijcode) ON UPDATE CASCADE ON DELETE NO ACTION,
   CONSTRAINT fk_vlucht_ref_luchthaven FOREIGN KEY (luchthavencode)
      REFERENCES Luchthaven (luchthavencode) ON UPDATE NO ACTION ON DELETE NO ACTION,
   CONSTRAINT fk_vlucht_ref_vliegtuig FOREIGN KEY (vliegtuigtype)
      REFERENCES Vliegtuig (vliegtuigtype) ON UPDATE CASCADE ON DELETE NO ACTION
)
GO

/*==============================================================*/
/* Table: IncheckenVoorVlucht                                   */
/*==============================================================*/
CREATE TABLE IncheckenVoorVlucht (
   balienummer          INT                  NOT NULL,
   vluchtnummer         INT                  NOT NULL,
   CONSTRAINT pk_incheckenvoorvlucht PRIMARY KEY (balienummer, vluchtnummer),
   CONSTRAINT fk_incheckenvlucht_ref_vlucht FOREIGN KEY (vluchtnummer)
      REFERENCES Vlucht (vluchtnummer) ON UPDATE CASCADE ON DELETE CASCADE,
   CONSTRAINT fk_incheckenvlucht_ref_balie FOREIGN KEY (balienummer)
      REFERENCES Balie (balienummer) ON UPDATE CASCADE ON DELETE CASCADE
)
GO

/*==============================================================*/
/* Table: Passagier                                             */
/*==============================================================*/
CREATE TABLE Passagier (
   passagiernummer      INT                  NOT NULL,
   naam                 VARCHAR(255)         NOT NULL,
   geslacht             CHAR(1)              NOT NULL,
   geboortedatum        DATETIME             NOT NULL,
   CONSTRAINT pk_passagier PRIMARY KEY (passagiernummer)
)
GO

/*==============================================================*/
/* Table: PassagierVoorVlucht                                   */
/*==============================================================*/
CREATE TABLE PassagierVoorVlucht (
   passagiernummer      INT                  NOT NULL,
   vluchtnummer         INT                  NOT NULL,
   balienummer          INT                  NULL,
   inchecktijdstip      DATETIME             NULL,
   stoel                CHAR(3)              NULL,
   CONSTRAINT pk_passagiervoorvlucht PRIMARY KEY (passagiernummer, vluchtnummer),
   CONSTRAINT fk_passagiervlucht_ref_balie FOREIGN KEY (balienummer)
      REFERENCES Balie (balienummer) ON UPDATE CASCADE ON DELETE NO ACTION,
   CONSTRAINT fk_passagiervlucht_ref_vlucht FOREIGN KEY (vluchtnummer)
      REFERENCES Vlucht (vluchtnummer) ON UPDATE NO ACTION ON DELETE NO ACTION,
   CONSTRAINT fk_passagiervlucht_ref_passagier FOREIGN KEY (passagiernummer)
      REFERENCES Passagier (passagiernummer) ON UPDATE NO ACTION ON DELETE CASCADE
)
GO

/*==============================================================*/
/* Table: Object                                                */
/*==============================================================*/
CREATE TABLE Object (
   volgnummer           INT                  identity,
   passagiernummer      INT                  NOT NULL,
   vluchtnummer         INT                  NOT NULL,
   gewicht              INT                  NOT NULL,
   CONSTRAINT pk_object PRIMARY KEY (volgnummer),
   CONSTRAINT fk_object_ref_passagier FOREIGN KEY (passagiernummer, vluchtnummer)
      REFERENCES PassagierVoorVlucht (passagiernummer, vluchtnummer) ON UPDATE CASCADE ON DELETE CASCADE
)
GO

