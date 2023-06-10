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

DROP TABLE IF EXISTS StoricoPrezziProdotto;
CREATE TABLE IF NOT EXISTS StoricoPrezziProdotto ( # contiene solo i prezzi precedenti a quello attuale
  Prodotto int(11) NOT NULL,
  Bar varchar(11) NOT NULL,
  Prezzo float NOT NULL,
  Data datetime NOT NULL DEFAULT current_timestamp(), ## NB: Questa data indica il momento fino al quale il prezzo indicato è da considerarsi valido
  PRIMARY KEY (Prodotto, Bar, Data),
  FOREIGN KEY (Prodotto, Bar) REFERENCES Prodotto (Id, Bar) ON UPDATE CASCADE
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
  Data datetime NOT NULL DEFAULT current_timestamp(),
  PRIMARY KEY (Id, Bar),
  FOREIGN KEY (Prodotto, Bar) REFERENCES Prodotto (Id, Bar) ON UPDATE CASCADE,
  FOREIGN KEY (Utente) REFERENCES Utente (Email) ON UPDATE CASCADE
) ENGINE=InnoDB;

DROP TABLE IF EXISTS Transazione;
CREATE TABLE IF NOT EXISTS Transazione (
  Id int(11) NOT NULL DEFAULT 0,
  Bar varchar(11) NOT NULL,
  Utente varchar(50) NOT NULL,
  Data datetime NOT NULL DEFAULT current_timestamp(),
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
  Importo float NOT NULL,
  PRIMARY KEY (Transazione, Bar),
  FOREIGN KEY (Transazione, Bar) REFERENCES Transazione (Id, Bar) ON UPDATE CASCADE
) ENGINE=InnoDB;

###################### VISTE #####################

DROP FUNCTION IF EXISTS GetPrezzoProdotto;
DELIMITER $$
CREATE FUNCTION GetPrezzoProdotto(Prodotto INT(11), Bar VARCHAR(11), Data datetime) 
RETURNS float
DETERMINISTIC
BEGIN
	DECLARE Prezzo float DEFAULT NULL;
    
    SELECT SPP.Prezzo
    INTO Prezzo
    FROM StoricoPrezziProdotto SPP
    WHERE SPP.Data >= Data AND SPP.Bar = Bar AND SPP.Prodotto = Prodotto
    ORDER BY SPP.Data ASC
    LIMIT 1;
    
    IF Prezzo IS NULL
    THEN SELECT P.Prezzo
		INTO Prezzo
        FROM Prodotto P
        WHERE P.Id = Prodotto AND P.Bar = Bar;
	END IF;
    
    RETURN Prezzo;
END $$
DELIMITER ;
    
DROP VIEW IF EXISTS OrdiniConImporto;
CREATE VIEW OrdiniConImporto AS
	SELECT Id, Utente, Prodotto, Bar, Quantita, Data, ROUND(Quantita*GetPrezzoProdotto(Prodotto, Bar, Data), 2) AS Importo
    FROM Ordini;
    
DROP VIEW IF EXISTS StoricoAcquistiConImporto;
CREATE VIEW StoricoAcquistiConImporto AS
	SELECT SA.Transazione, SA.Bar, SA.Prodotto, SA.Quantita, T.Data, ROUND(SA.Quantita*GetPrezzoProdotto(SA.Prodotto, SA.Bar, T.Data), 2) AS Importo
    FROM StoricoAcquisti SA
    JOIN Transazione T ON SA.Transazione=T.Id AND SA.Bar=T.Bar;

DROP VIEW IF EXISTS TransazioniConImporto;
CREATE VIEW TransazioniConImporto AS
	SELECT *
    FROM ((SELECT T.Id, T.Bar, T.Utente, SA.Importo, T.Data, 'Acquisto' AS Tipo
		FROM Transazione T
		JOIN StoricoAcquistiConImporto SA ON SA.Transazione=T.Id AND SA.Bar=T.Bar)
			UNION
		(SELECT T.Id, T.Bar, T.Utente, R.Importo, T.Data, 'Ricarica' AS Tipo
			FROM Transazione T
			JOIN Ricarica R ON R.Transazione=T.Id AND R.Bar=T.Bar)) t
	ORDER BY t.Data ASC;    

DROP VIEW IF EXISTS OrdiniBarAngolo; # PIva = 32650198347
CREATE VIEW OrdiniBarAngolo AS
	SELECT O.Id, O.Utente, O.Prodotto, O.Quantita, O.Data, O.Importo
	FROM OrdiniConImporto O
	WHERE O.Bar="32650198347";

###################### FUNZIONI E PROCEDURE #####################

##
## NB: La funzione GetPrezzoProdotto è stata definita sopra per necessità durante la creazione delle viste
##

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
    
    SELECT IFNULL(SUM(R.Importo), 0)
    INTO ricariche
    FROM Transazione T
    JOIN Ricarica R ON R.Transazione=T.Id AND R.Bar=T.Bar
    WHERE T.Utente=Email AND T.Bar=Bar;
    
    SELECT IFNULL(SUM(SA.Importo), 0)
    INTO spese
    FROM Transazione T
    JOIN StoricoAcquistiConImporto SA ON SA.Transazione=T.Id AND SA.Bar=T.Bar
    WHERE T.Utente=Email AND T.Bar=Bar;
    
    IF NOT FlagSaldoDefinitivo
    THEN 
		SELECT IFNULL(SUM(O.Importo), 0)
		INTO ordini
		FROM OrdiniConImporto O
		WHERE O.Utente=Email AND O.Bar=Bar;
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

# procedura per trovare i prodotti senza un determinato allergene
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

DROP FUNCTION IF EXISTS GetPrezzoProdottoOdierno;
DELIMITER $$
CREATE FUNCTION GetPrezzoProdottoOdierno(Prodotto INT(11), Bar VARCHAR(11)) 
RETURNS float
DETERMINISTIC
BEGIN
    RETURN GetPrezzoProdotto(Prodotto, Bar, current_timestamp());
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

DROP PROCEDURE IF EXISTS EseguiRicarica;
DELIMITER $$
CREATE PROCEDURE EseguiRicarica(IN Utente VARCHAR(50), IN Bar VARCHAR(11), IN Importo float)
BEGIN
	DECLARE IDTransazione INT(11);
    
	INSERT INTO Transazione(Bar, Utente)
    VALUES (Bar, Utente);
    
    SELECT MAX(T.Id)
    INTO IDTransazione
    FROM Transazione T
    WHERE T.Bar=Bar;
    
    INSERT INTO Ricarica
    VALUES (IDTransazione, Bar, Importo);

END $$
DELIMITER ;

DROP PROCEDURE IF EXISTS EseguiAcquisto;
DELIMITER $$
CREATE PROCEDURE EseguiAcquisto(IN Utente VARCHAR(50), IN Bar VARCHAR(11), IN Prodotto INT(11), IN Quantita INT(11), IN Data datetime)
BEGIN
	DECLARE IDTransazione INT(11);
    
	INSERT INTO Transazione(Bar, Utente, Data)
    VALUES (Bar, Utente, Data);
    
    SELECT MAX(T.Id)
    INTO IDTransazione
    FROM Transazione T
    WHERE T.Bar=Bar;
    
    INSERT INTO StoricoAcquisti
    VALUES (IDTransazione, Bar, Prodotto, Quantita);

END $$
DELIMITER ;

DROP PROCEDURE IF EXISTS ConfermaOrdine;
DELIMITER $$
CREATE PROCEDURE ConfermaOrdine(IN Id INT(11), IN Bar VARCHAR(11))
BEGIN
	DECLARE Utente VARCHAR(50);
    DECLARE Prodotto INT(11);
    DECLARE Quantita INT(11);
    DECLARE Data datetime;
    
    SELECT O.Utente, O.Prodotto, O.Quantita, O.Data
	INTO Utente, Prodotto, Quantita, Data
    FROM Ordini O
    WHERE O.Id=Id AND O.Bar=Bar;
    
    CALL EseguiAcquisto(Utente, Bar, Prodotto, Quantita, Data);
    
    DELETE FROM Ordini
    WHERE Ordini.Id=Id AND Ordini.Bar=Bar;

END $$
DELIMITER ;

###################### TRIGGER #####################

DROP TRIGGER IF EXISTS MemorizzaNuovoPrezzoProdotto;
DELIMITER $$
CREATE TRIGGER MemorizzaNuovoPrezzoProdotto
AFTER UPDATE ON Prodotto
FOR EACH ROW
BEGIN
	IF (OLD.Prezzo <> NEW.Prezzo) 
	THEN 
		INSERT INTO StoricoPrezziProdotto (Prodotto, Bar, Prezzo)
        VALUES (OLD.Id, OLD.Bar, OLD.Prezzo);
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

###### inserire il proprio filepath
LOAD DATA LOCAL INFILE "C:\\Users\\Stefano\\Desktop\\Informatica\\Progetto_BDSI\\Categorie.csv" INTO TABLE Categoria
	FIELDS TERMINATED BY ";"
	LINES TERMINATED BY "\r\n"
	IGNORE 1 ROWS;
    
###### inserire il proprio filepath
LOAD DATA LOCAL INFILE "C:\\Users\\Stefano\\Desktop\\Informatica\\Progetto_BDSI\\Utenti.txt" INTO TABLE Utente
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
    
INSERT INTO StoricoPrezziProdotto VALUES
	(1, "85920475612", 1.5, "2023-05-10 10:00:00"),
    (2, "32650198347", 0.4, "2023-05-11 10:00:00"),
    (4, "71249560382", 2.5, "2023-06-01 12:00:00"),
    (2, "49781624053", 1, "2023-05-02 10:00:00"),
    (2, "49781624053", 1.5, "2023-05-10 10:00:00"),
    (1, "32650198347", 3, "2023-06-06 14:00:00"),
    (2, "85920475612", 2, "2023-05-16 10:00:00"),
    (1, "85920475612", 1.25, "2023-05-20 10:00:00"),
    (3, "49781624053", 0.8, "2023-05-24 18:00:00");
    
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

###### inserire il proprio filepath
LOAD DATA LOCAL INFILE "C:\\Users\\Stefano\\Desktop\\Informatica\\Progetto_BDSI\\Transazione.csv" INTO TABLE Transazione  
	FIELDS TERMINATED BY ";"
	LINES TERMINATED BY "\r\n"
	IGNORE 1 ROWS
    (Bar, Utente);

###### inserire il proprio filepath
LOAD DATA LOCAL INFILE "C:\\Users\\Stefano\\Desktop\\Informatica\\Progetto_BDSI\\Ricariche.csv" INTO TABLE Ricarica 
	FIELDS TERMINATED BY ";"
	LINES TERMINATED BY "\r\n"
	IGNORE 1 ROWS;

LOAD DATA LOCAL INFILE "C:\\Users\\Stefano\\Desktop\\Informatica\\Progetto_BDSI\\StoricoAcquisti.csv" INTO TABLE StoricoAcquisti  #inserire il proprio filepath
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

## Trovare tutti gli omonimi nella scuola 'EFGH789012'
SELECT *
FROM Utente
WHERE Nome IN (SELECT DISTINCT(U.Nome)
                FROM Utente U
					JOIN Categoria C ON C.Id=U.Categoria
                WHERE C.Scuola='EFGH789012'
                GROUP BY U.Nome
                HAVING COUNT(U.Nome)>1);

## Trovare tutti gli Utenti con saldo provvisorio positivo(>= 0) per ogni Bar a cui possono accedere      
SELECT U.Email, U.Nome, U.Cognome
FROM Utente U
	JOIN Categoria C ON U.Categoria=C.Id
	JOIN Bar B ON C.Scuola=B.Scuola  
GROUP BY U.Email
HAVING MIN(GetSaldoProvvisorioUtente(U.Email, B.PIva)) >= 0;

###################### TEST VISTE #####################

SELECT * FROM OrdiniBarAngolo;
INSERT INTO Ordini(Utente, Prodotto, Bar, Quantita) VALUES ('elisa.monti28@email.it', 1, "32650198347", 2);
SELECT * FROM OrdiniBarAngolo WHERE Utente='elisa.monti28@email.it';

SELECT * FROM TransazioniConImporto;
CALL EseguiRicarica('matteo.marchetti55@email.it', '71249560382', 50);
CALL EseguiAcquisto('matteo.marchetti55@email.it', '71249560382', 4, 4, current_timestamp());
SELECT * FROM TransazioniConImporto WHERE Utente='matteo.marchetti55@email.it';
    