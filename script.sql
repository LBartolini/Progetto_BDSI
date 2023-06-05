##################### CREAZIONE BASE DI DATI #############################

DROP DATABASE IF EXISTS ProgettoBarScuola;
CREATE DATABASE IF NOT EXISTS ProgettoBarScuola;
USE ProgettoBarScuola;

##################### CREAZIONE TABELLE #############################

DROP TABLE IF EXISTS Allergene;
CREATE TABLE IF NOT EXISTS Allergene (
  Id int(11) NOT NULL AUTO_INCREMENT,
  Nome VARCHAR(32) NOT NULL,
  PRIMARY KEY (Id)
) ENGINE=InnoDB;

DROP TABLE IF EXISTS Scuola;
CREATE TABLE IF NOT EXISTS Scuola (
  CodMeccanografico varchar(10) NOT NULL,
  Nome varchar(25) NOT NULL,
  Citta varchar(25) NOT NULL,
  FineRicreazione time NOT NULL,
  PRIMARY KEY (CodMeccanografico)
) ENGINE=InnoDB;

DROP TABLE IF EXISTS Categoria;
CREATE TABLE IF NOT EXISTS Categoria (
  Id int(11) NOT NULL AUTO_INCREMENT,
  Scuola varchar(10) NOT NULL,
  Nome varchar(32) NOT NULL,
  PRIMARY KEY (Id),
  FOREIGN KEY (Scuola) REFERENCES Scuola (CodMeccanografico) ON UPDATE CASCADE
) ENGINE=InnoDB;

DROP TABLE IF EXISTS Utente;
CREATE TABLE IF NOT EXISTS Utente (
  Email varchar(50) NOT NULL,
  Nome varchar(25) NOT NULL,
  Cognome varchar(25) NOT NULL,
  Categoria int(11) NOT NULL,
  PRIMARY KEY (Email),
  FOREIGN KEY (Categoria) REFERENCES Categoria(Id) ON UPDATE CASCADE
) ENGINE=InnoDB;

DROP TABLE IF EXISTS Bar;
CREATE TABLE IF NOT EXISTS Bar (
  PIva varchar(11) NOT NULL,
  Email varchar(50) NOT NULL,
  Telefono varchar(25) NOT NULL,
  Scuola varchar(10) NOT NULL,
  PRIMARY KEY (pIva),
  FOREIGN KEY (Scuola) REFERENCES Scuola (CodMeccanografico) ON UPDATE CASCADE
) ENGINE=InnoDB;

DROP TABLE IF EXISTS Prodotto;
CREATE TABLE IF NOT EXISTS Prodotto (
  Id int(11) NOT NULL AUTO_INCREMENT,
  Bar varchar(11) NOT NULL,
  Nome varchar(25) NOT NULL,
  Prezzo float NOT NULL,
  Tipo ENUM('Dolce', 'Salato', 'Bevanda', 'Altro'),
  PRIMARY KEY (Id, Bar),
  FOREIGN KEY (Bar) REFERENCES Bar (PIva) ON UPDATE CASCADE
) ENGINE=InnoDB;

DROP TABLE IF EXISTS PresenzaAllergeneProdotto;
CREATE TABLE IF NOT EXISTS PresenzaAllergeneProdotto (
  Allergene int(11) NOT NULL,
  Prodotto int(11) NOT NULL,
  Bar varchar(11) NOT NULL,
  PRIMARY KEY (Allergene, Prodotto, Bar),
  FOREIGN KEY (Allergene) REFERENCES Allergene (Id) ON UPDATE CASCADE,
  FOREIGN KEY (Prodotto, Bar) REFERENCES Prodotto (Id, Bar)  ON UPDATE CASCADE
) ENGINE=InnoDB;

DROP TABLE IF EXISTS Ordini;
CREATE TABLE IF NOT EXISTS Ordini (
  Id int(11) NOT NULL AUTO_INCREMENT,
  Utente varchar(50) NOT NULL,
  Prodotto int(11) NOT NULL,
  Bar varchar(11) NOT NULL,
  Quantita int(11) NOT NULL,
  Importo float NOT NULL DEFAULT 0,
  Data datetime NOT NULL DEFAULT current_timestamp(),
  PRIMARY KEY (Id, Bar),
  FOREIGN KEY (Prodotto, Bar) REFERENCES Prodotto (Id, Bar) ON UPDATE CASCADE,
  FOREIGN KEY (Utente) REFERENCES Utente (Email) ON UPDATE CASCADE
) ENGINE=InnoDB;

DROP TABLE IF EXISTS Transazione;
CREATE TABLE IF NOT EXISTS Transazione (
  Id int(11) NOT NULL AUTO_INCREMENT,
  Bar varchar(11) NOT NULL,
  Utente varchar(50) NOT NULL,
  Data datetime NOT NULL DEFAULT current_timestamp(),
  Importo float NOT NULL,
  PRIMARY KEY (Id, Bar),
  FOREIGN KEY (Bar) REFERENCES Bar (PIva) ON UPDATE CASCADE,
  FOREIGN KEY (Utente) REFERENCES Utente (Email) ON UPDATE CASCADE
) ENGINE=InnoDB;

DROP TABLE IF EXISTS StoricoAcquisti;
CREATE TABLE IF NOT EXISTS StoricoAcquisti (
  Transazione int(11) NOT NULL,
  Bar varchar(11) NOT NULL,
  Prodotto int(11) NOT NULL,
  Quantita int(11) NOT NULL,
  PRIMARY KEY (Transazione, Bar),
  FOREIGN KEY (Transazione, Bar) REFERENCES Transazione (Id, Bar) ON UPDATE CASCADE,
  FOREIGN KEY (Prodotto, Bar) REFERENCES Prodotto (Id, Bar) ON UPDATE CASCADE
) ENGINE=InnoDB;

DROP TABLE IF EXISTS Ricarica;
CREATE TABLE IF NOT EXISTS Ricarica (
  Transazione int(11) NOT NULL,
  Bar varchar(11) NOT NULL,
  PRIMARY KEY (Transazione, Bar),
  FOREIGN KEY (Transazione, Bar) REFERENCES Transazione (Id, Bar) ON UPDATE CASCADE
) ENGINE=InnoDB;

###################### FUNZIONI E PROCEDURE #####################

DROP FUNCTION IF EXISTS BarAccessibileDaUtente;
DELIMITER $$
CREATE FUNCTION BarAccessibileDaUtente(Email VARCHAR(50), Bar VARCHAR(11)) 
RETURNS BOOLEAN
DETERMINISTIC
BEGIN
	IF(Bar IN (SELECT Bar.PIva
				FROM Bar
                JOIN Categoria ON Bar.Scuola=Categoria.Scuola
                JOIN Utente ON Categoria.Id=Utente.Categoria
                WHERE Utente.Email = Email)) 
		THEN 
			RETURN TRUE;
    ELSE 
			RETURN FALSE;
    END IF;
END $$
DELIMITER ;

DROP FUNCTION IF EXISTS GetSaldoUtente;
DELIMITER $$
CREATE FUNCTION GetSaldoUtente(Email VARCHAR(50), Bar VARCHAR(11), FlagSaldoDefinitivo BOOLEAN) 
RETURNS float
DETERMINISTIC
BEGIN
	DECLARE ricariche float DEFAULT 0;
    DECLARE spese float DEFAULT 0;
    DECLARE ordini float DEFAULT 0;
    DECLARE saldo float DEFAULT 0;
    
    SELECT SUM(Transazione.Importo)
    INTO ricariche
    FROM Transazione
    JOIN Ricarica ON Ricarica.Transazione=Transazione.Id AND Ricarica.Bar=Transazione.Bar
    WHERE Transazione.Utente=Email AND Transazione.Bar=Bar;
    
    SELECT SUM(Transazione.Importo)
    INTO spese
    FROM Transazione
    JOIN StoricoAcquisti ON StoricoAcquisti.Transazione=Transazione.Id AND StoricoAcquisti.Bar=Transazione.Bar
    WHERE Transazione.Utente=Email AND Transazione.Bar=Bar;
    
    IF NOT FlagSaldoDefinitivo
    THEN 
		SELECT SUM(Ordini.Importo)
		INTO ordini
		FROM Ordini
		WHERE Ordini.Utente=Email AND Ordini.Bar=Bar;
    END IF;
    
    SET saldo = ricariche - spese - ordini;
    RETURN saldo;
END $$
DELIMITER ;

DROP FUNCTION IF EXISTS GetSaldoDefinitivoUtente;
DELIMITER $$
CREATE FUNCTION GetSaldoDefinitivoUtente(Email VARCHAR(50), Bar VARCHAR(11)) 
RETURNS float
DETERMINISTIC
BEGIN
	RETURN GetSaldoUtente(Email, Bar, TRUE);
END $$
DELIMITER ;

DROP FUNCTION IF EXISTS GetSaldoProvvisorioUtente;
DELIMITER $$
CREATE FUNCTION GetSaldoProvvisorioUtente(Email VARCHAR(50), Bar VARCHAR(11)) 
RETURNS float
DETERMINISTIC
BEGIN
	RETURN GetSaldoUtente(Email, Bar, FALSE);
END $$
DELIMITER ;

# procedura per trovare i prodotti in base ad un allergene
DROP PROCEDURE IF EXISTS ProdottiSenzaAllergene;
DELIMITER $$
CREATE PROCEDURE ProdottiSenzaAllergene(IN Bar VARCHAR(11), IN Allergene INT(11))
BEGIN
	SELECT *
    FROM Prodotto
    WHERE (Id, Bar) NOT IN (SELECT Prod.Id, Prod.Bar
		FROM Prodotto Prod
		JOIN PresenzaAllergeneProdotto Pres ON Pres.Prodotto=Prod.Id AND Pres.Bar=Prod.Bar
		WHERE Pres.Allergene=Allergene AND Prod.Bar=Bar) AND Prodotto.Bar=Bar;
END $$
DELIMITER ;

DROP PROCEDURE IF EXISTS ConfermaOrdine;
DELIMITER $$
CREATE PROCEDURE ConfermaOrdine(IN Id INT(11), IN Bar VARCHAR(11))
BEGIN
	DECLARE Utente VARCHAR(50);
    DECLARE Prodotto INT(11);
    DECLARE Quantita INT(11);
    DECLARE Importo float;
    DECLARE IDTransazione INT(11);
    
    SELECT O.Utente, O.Prodotto, O.Quantita, O.Importo
	INTO Utente, Prodotto, Quantita, Importo
    FROM Ordini O
    WHERE O.Id=Id AND O.Bar=Bar;
    
    INSERT INTO Transazione(Bar, Utente, Importo)
    VALUES (Bar, Utente, Importo);
    
    SELECT MAX(T.Id)
    INTO IDTransazione
    FROM Transazione T
    WHERE T.Bar=Bar;
    
    INSERT INTO StoricoAcquisti
    VALUES (IDTransazione, Bar, Prodotto, Quantita);
    
    DELETE FROM Ordini
    WHERE Ordini.Id=Id AND Ordini.Bar=Bar;

END $$
DELIMITER ;

###################### TRIGGER #####################

DROP TRIGGER IF EXISTS CalcolaImportoOrdine;
DELIMITER $$
CREATE TRIGGER CalcolaImportoOrdine
BEFORE INSERT ON Ordini
FOR EACH ROW
BEGIN
	IF (NEW.Importo <= 0) 
	THEN SET NEW.Importo = (
		SELECT Prezzo*NEW.Quantita 
        FROM Prodotto
        WHERE Prodotto.Id = NEW.Prodotto AND Prodotto.Bar = NEW.Bar
		);
    END IF;
END $$
DELIMITER ;

DROP TRIGGER IF EXISTS CheckBarInOrdine;
DELIMITER $$
CREATE TRIGGER CheckBarInOrdine
BEFORE INSERT ON Ordini
FOR EACH ROW
BEGIN
	IF NOT BarAccessibileDaUtente(NEW.Utente, NEW.Bar)
		THEN SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Bar non accessibile dall\'utente selezionato';
	END IF;
END $$
DELIMITER ;

DROP TRIGGER IF EXISTS CheckBarInTransazione;
DELIMITER $$
CREATE TRIGGER CheckBarInTransazione
BEFORE INSERT ON Transazione
FOR EACH ROW
BEGIN
	IF NOT BarAccessibileDaUtente(NEW.Utente, NEW.Bar)
		THEN SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Bar non accessibile dall\'utente selezionato';
	END IF;
END $$
DELIMITER ;

DROP TRIGGER IF EXISTS AutoIncrementProdottoBar;
DELIMITER $$
CREATE TRIGGER AutoIncrementProdottoBar
BEFORE INSERT ON Prodotto
FOR EACH ROW
BEGIN
	DECLARE MaxIdPerBar INT;
	SELECT MAX(t.Id)
    INTO MaxIdPerBar
    FROM (SELECT Id
			FROM Prodotto
            WHERE Bar = NEW.Bar) t;
	IF MaxIdPerBar IS NULL
		THEN SET NEW.Id = 1;
	ELSE 
		SET NEW.Id = MaxIdPerBar + 1;
	END IF;
END $$
DELIMITER ;

DROP TRIGGER IF EXISTS AutoIncrementOrdineBar;
DELIMITER $$
CREATE TRIGGER AutoIncrementOrdineBar
BEFORE INSERT ON Ordini
FOR EACH ROW
BEGIN
	DECLARE MaxIdPerBar INT;
	SELECT MAX(t.Id)
    INTO MaxIdPerBar
    FROM (SELECT Id
			FROM Ordini
            WHERE Bar = NEW.Bar) t;
	IF MaxIdPerBar IS NULL
		THEN SET NEW.Id = 1;
	ELSE 
		SET NEW.Id = MaxIdPerBar + 1;
	END IF;
END $$
DELIMITER ;

DROP TRIGGER IF EXISTS AutoIncrementTransazioneBar;
DELIMITER $$
CREATE TRIGGER AutoIncrementTransazioneBar
BEFORE INSERT ON Transazione
FOR EACH ROW
BEGIN
	DECLARE MaxIdPerBar INT;
	SELECT MAX(t.Id)
    INTO MaxIdPerBar
    FROM (SELECT Id
			FROM Transazione
            WHERE Bar = NEW.Bar) t;
	IF MaxIdPerBar IS NULL
		THEN SET NEW.Id = 1;
	ELSE 
		SET NEW.Id = MaxIdPerBar + 1;
	END IF;
END $$
DELIMITER ;

############### POPOLAMENTO TABELLE #########################

INSERT INTO Allergene VALUES 
	(1, "Glutine"),
    (2, "Lattosio"),
    (3, "Arachidi"),
    (4, "Soia");
    
INSERT INTO Scuola VALUES 
	("ABCD123456", "Giovanni Falcone", "Roma", "10:20:00"),
    ("EFGH789012", "Leonardo da Vinci", "Milano", "10:30:00"),
    ("IJKL345678", "Giuseppe Verdi", "Napoli", "10:15:00");

LOAD DATA LOCAL INFILE "C:\\Users\\Stefano\\Desktop\\Informatica\\SQL\\Categorie.csv" INTO TABLE Categoria  #inserire il proprio filepath
	FIELDS TERMINATED BY ";"
	LINES TERMINATED BY "\r\n"
	IGNORE 1 ROWS;
    
LOAD DATA LOCAL INFILE "C:\\Users\\Stefano\\Desktop\\Informatica\\SQL\\Utenti.txt" INTO TABLE Utente  #inserire il proprio filepath
	FIELDS TERMINATED BY ";"
	LINES TERMINATED BY "\r\n"
	IGNORE 1 ROWS;
	
INSERT INTO Bar VALUES 
	("85920475612", "bar.ventura@email.it", "3459876213", "ABCD123456"),
    ("32650198347", "bar.angolo@email.it", "3896210458", "EFGH789012"),
    ("71249560382", "bar.sorriso@email.it", "3337128945", "IJKL345678"),
    ("49781624053", "bar.sole@email.it", "3465892034", "EFGH789012");

INSERT INTO Prodotto (Bar, Nome, Prezzo, Tipo) VALUES 
	("85920475612", "Panino con Salame", 2, "Salato"),
    ("85920475612", "Pizza", 1.5, "Salato"),
    ("85920475612", "Pepsi", 1, "Bevanda"),
    ("85920475612", "Cornetto", 1.1, "Dolce"),
    ("85920475612", "Gomme da Masticare", 2, "Altro"),
    
    ("32650198347", "Schiacciata con Tonno", 2.5, "Salato"),
    ("32650198347", "Caramelle", 0.5, "Altro"),
    ("32650198347", "Caffe", 0.6, "Bevanda"),
    
    ("71249560382", "Hot Dog", 1.5, "Salato"),
    ("71249560382", "Fanta", 1, "Bevanda"),
    ("71249560382", "Torta", 1.5, "Dolce"),
    ("71249560382", "Panino con Salame", 2, "Salato"),
    
    ("49781624053", "Croccantelle", 1, "Salato"),
    ("49781624053", "Brioche", 1.1, "Dolce"),
    ("49781624053", "Coca Cola", 1, "Bevanda");
    
INSERT INTO PresenzaAllergeneProdotto VALUES
	# Glutine
	(1, 1, "85920475612"),
    (1, 2, "85920475612"),
    (1, 4, "85920475612"),
    (1, 1, "32650198347"),
    (1, 1, "71249560382"),
    (1, 3, "71249560382"),
    (1, 4, "71249560382"),
    (1, 1, "49781624053"),
    (1, 2, "49781624053"),
    # Lattosio
    (2, 4, "85920475612"),
    (2, 3, "71249560382"),
    (2, 2, "49781624053"),
    # Arachidi
    (3, 4, "85920475612"),
    # Soia
    (4, 3, "49781624053");
    
INSERT INTO Ordini (Utente, Prodotto, Bar, Quantita) VALUES
	("elena.romano112@email.it", 1, "85920475612", 1),
    ("elena.romano112@email.it", 3, "85920475612", 2),
    ("chiara.russo54@email.it", 5, "85920475612", 1),
    ("francesca.romano12@email.it", 2, "85920475612", 3),
    ("claudia.parisi118@email.it", 1, "85920475612", 4),
    ("elena.romano84@email.it", 3, "85920475612", 1),
    
    ("elisa.monti28@email.it", 1, "32650198347", 1),
    ("elisa.monti28@email.it", 3, "32650198347", 2),
    ("francesca.rossi100@email.it", 2, "32650198347", 1),
    ("matteo.monti103@email.it", 2, "32650198347", 3),
    ("matteo.monti103@email.it", 1, "32650198347", 2),
    ("elisa.russo18@email.it", 3, "32650198347", 1),
    ("chiara.rizzo20@email.it", 2, "32650198347", 6),
    ("lorenzo.bianchi77@email.it", 1, "32650198347", 1),
    
	("matteo.monti47@email.it", 1, "71249560382", 1),
    ("sofia.ferrari134@email.it", 3, "71249560382", 2),
    ("alessia.gallo94@email.it", 4, "71249560382", 1),
    ("claudia.parisi48@email.it", 2, "71249560382", 3),
    ("sara.santoro32@email.it", 4, "71249560382", 2),
    ("sofia.ferrari106@email.it", 3, "71249560382", 1),
    
    ("francesca.rossi100@email.it", 1, "49781624053", 5),
    ("francesca.rossi100@email.it", 3, "49781624053", 3),
    ("lorenzo.bianchi49@email.it", 2, "49781624053", 2),
    ("laura.bianchi10@email.it", 2, "49781624053", 3),
    ("matteo.monti103@email.it", 1, "49781624053", 2),
    ("sara.santoro60@email.it", 3, "49781624053", 1),
    ("sara.santoro60@email.it", 2, "49781624053", 2),
    ("alessia.gallo136@email.it", 1, "49781624053", 1);

LOAD DATA LOCAL INFILE "C:\\Users\\Stefano\\Desktop\\Informatica\\SQL\\Transazione.csv" INTO TABLE Transazione  #inserire il proprio filepath
	FIELDS TERMINATED BY ";"
	LINES TERMINATED BY "\r\n"
	IGNORE 1 ROWS;
    
LOAD DATA LOCAL INFILE "C:\\Users\\Stefano\\Desktop\\Informatica\\SQL\\Ricariche.csv" INTO TABLE Ricarica  #inserire il proprio filepath
	FIELDS TERMINATED BY ";"
	LINES TERMINATED BY "\r\n"
	IGNORE 1 ROWS;

LOAD DATA LOCAL INFILE "C:\\Users\\Stefano\\Desktop\\Informatica\\SQL\\StoricoAcquisti.csv" INTO TABLE StoricoAcquisti  #inserire il proprio filepath
	FIELDS TERMINATED BY ";"
	LINES TERMINATED BY "\r\n"
	IGNORE 1 ROWS;

###################### INTERROGAZIONI #####################

## Trovare tutti gli Utenti che appartengono al Bar con Partita iva "85920475612"
SELECT Utente.Email 
	FROM Utente
		JOIN Categoria ON Utente.Categoria=Categoria.Id
		JOIN Bar ON Categoria.Scuola=Bar.Scuola
	WHERE Bar.PIva="85920475612";

## Trovare tutti gli omonimi in una scuola
## TODO

###################### VISTE #####################

DROP VIEW IF EXISTS DipendentiMatematica;
CREATE VIEW DipendentiMatematica AS
	SELECT *
		FROM Dipendente D
		WHERE D.Impiego="DIMAI-Ulisse DINI"
	WITH LOCAL CHECK OPTION;
SELECT * FROM DipendentiMatematica;

# INSERT INTO DipendentiMatematica VALUES (999, "A", "B", "C", "DIMAI"); errore per la local check option
INSERT INTO DipendentiMatematica VALUES (999, "Prova", "", "", "DIMAI-Ulisse DINI");
SELECT * FROM DipendentiMatematica;
SELECT * FROM Dipendente WHERE Impiego="DIMAI-Ulisse DINI";

DROP VIEW IF EXISTS AttivitaDipendentiMatematica;
CREATE VIEW AttivitaDipendentiMatematica AS
	SELECT DM.ID, DM.Nome AS NomeDipendente, DM.Cognome, A.Nome AS NomeAttivita, A.Data_inizio, A.scadenza_prevista, A.data_fine
		FROM DipendentiMatematica DM JOIN Partecipazione P ON P.Dipendente=DM.ID
			JOIN Attivita A ON P.Attivita=A.Nome AND P.Data_inizio_attivita=A.Data_inizio;
SELECT * FROM AttivitaDipendentiMatematica;