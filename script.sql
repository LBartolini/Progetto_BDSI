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
  FOREIGN KEY (Prodotto) REFERENCES Prodotto (Id) ON UPDATE CASCADE,
  FOREIGN KEY (Bar) REFERENCES Bar (PIva) ON UPDATE CASCADE
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
  FOREIGN KEY (Bar) REFERENCES Bar (PIva) ON UPDATE CASCADE,
  FOREIGN KEY (Utente) REFERENCES Utente (Email) ON UPDATE CASCADE,
  FOREIGN KEY (Prodotto) REFERENCES Prodotto (Id) ON UPDATE CASCADE
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
  FOREIGN KEY (Transazione) REFERENCES Transazione (Id) ON UPDATE CASCADE,
  FOREIGN KEY (Bar) REFERENCES Transazione (Bar) ON UPDATE CASCADE,
  FOREIGN KEY (Prodotto) REFERENCES Prodotto (Id) ON UPDATE CASCADE
) ENGINE=InnoDB;

DROP TABLE IF EXISTS Ricarica;
CREATE TABLE IF NOT EXISTS Ricarica (
  Transazione int(11) NOT NULL,
  Bar varchar(11) NOT NULL,
  PRIMARY KEY (Transazione, Bar),
  FOREIGN KEY (Bar) REFERENCES Transazione (Bar) ON UPDATE CASCADE,
  FOREIGN KEY (Transazione) REFERENCES Transazione (Id) ON UPDATE CASCADE
) ENGINE=InnoDB;

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
    
INSERT INTO Prodotto VALUES 
	(1, "85920475612", "Panino con Salame", 2, "Salato"),
    (2, "85920475612", "Pizza", 1.5, "Salato"),
    (3, "85920475612", "Pepsi", 1, "Bevanda"),
    (4, "85920475612", "Cornetto", 1.1, "Dolce"),
    (5, "85920475612", "Gomme da Masticare", 2, "Altro"),
    
    (1, "32650198347", "Schiacciata con Tonno", 2.5, "Salato"),
    (2, "32650198347", "Caramelle", 0.5, "Altro"),
    (3, "32650198347", "Caffe", 0.6, "Bevanda"),
    
    (1, "71249560382", "Hot Dog", 1.5, "Salato"),
    (2, "71249560382", "Fanta", 1, "Bevanda"),
    (3, "71249560382", "Torta", 1.5, "Dolce"),
    (4, "71249560382", "Panino con Salame", 2, "Salato"),
    
    (1, "49781624053", "Croccantelle", 1, "Salato"),
    (2, "49781624053", "Brioche", 1.1, "Dolce"),
    (3, "49781624053", "Coca Cola", 1, "Bevanda");
    
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

LOAD DATA LOCAL INFILE "C:\\Users\\Stefano\\Desktop\\Informatica\\SQL\\Ricariche.csv" INTO TABLE Transazione  #inserire il proprio filepath
	FIELDS TERMINATED BY ";"
	LINES TERMINATED BY "\r\n"
	IGNORE 1 ROWS;
LOAD DATA LOCAL INFILE "C:\\Users\\Stefano\\Desktop\\Informatica\\SQL\\Ricariche.csv" INTO TABLE Ricarica  #inserire il proprio filepath
	FIELDS TERMINATED BY ";"
	LINES TERMINATED BY "\r\n"
	IGNORE 30 ROWS;
    
LOAD DATA LOCAL INFILE "C:\\Users\\Stefano\\Desktop\\Informatica\\SQL\\StoricoAcquisti.csv" INTO TABLE Transazione  #inserire il proprio filepath
	FIELDS TERMINATED BY ";"
	LINES TERMINATED BY "\r\n"
	IGNORE 1 ROWS;
LOAD DATA LOCAL INFILE "C:\\Users\\Stefano\\Desktop\\Informatica\\SQL\\StoricoAcquisti.csv" INTO TABLE StoricoAcquisti  #inserire il proprio filepath
	FIELDS TERMINATED BY ";"
	LINES TERMINATED BY "\r\n"
	IGNORE 36 ROWS;

###################### INTERROGAZIONI #####################

## Trovare tutti gli Utenti che appartengono al Bar con Partita iva "85920475612"
SELECT Utente.Email 
	FROM Utente
		JOIN Categoria ON Utente.Categoria=Categoria.Id
		JOIN Bar ON Categoria.Scuola=Bar.Scuola
	WHERE Bar.PIva="85920475612";

## Trovare tutti gli omonimi in una scuola
## TODO
        
###################### PROCEDURE E FUNZIONI #####################

# funzione per calcolare il saldo di un utente (saldo provvisorio o definitivo) (provvisorio tiene conto degli ordini in sospeso, definitivo solo delle ricariche ed acquisti passati)
# funzione per trovare i prodotti in base ad un allergene
# funzione per trovare tutti gli ordini di una stessa categoria di utenti e in base a un bar
# conferma di un ordine e quindi viene cancellato dalla tabella ordini e messo nella tabella StoricoAcquisti

## Operazione 2: ricercare la disponibilità e la collocazione di una risorsa

DROP PROCEDURE IF EXISTS RicercaTitolo;

DELIMITER $$
CREATE PROCEDURE RicercaTitolo(Titolo VARCHAR(70))
BEGIN
	SELECT DISTINCT Biblioteca, Sala, Disponibilita
		FROM Risorsa_Astratta RA JOIN Risorsa_Fisica RF ON RA.ID=RF.Risorsa_Astratta
		WHERE RA.Titolo=Titolo;
END $$
DELIMITER ;

CALL RicercaTitolo("La via della schiavitu");

## Ricerca del responsabile della biblioteca in cui lavora un dato dipendente

DROP PROCEDURE IF EXISTS ResponsabileDipendente;
DELIMITER $$
CREATE PROCEDURE ResponsabileDipendente(ID INT)
BEGIN
	DECLARE bib VARCHAR(20);
    SELECT Impiego INTO bib FROM Dipendente D WHERE D.ID=ID;
    SELECT D.ID, D.Nome, D.Cognome, D.Impiego
		FROM Biblioteca B JOIN Dipendente D ON B.Nome=D.Impiego
		WHERE D.ID=B.ID_Responsabile AND B.Nome=bib;
END $$
DELIMITER ;

CALL ResponsabileDipendente(410);

## Funzione che restituisce il numero di volte in cui una risorsa astratta è stata usata in un'attività iniziata un certo anno

DROP FUNCTION IF EXISTS NumeroRisorseAstratteAttivita;

# SET GLOBAL log_bin_trust_function_creators=TRUE;
DELIMITER $$
CREATE FUNCTION NumeroRisorseAstratteAttivita(IDRisorsa VARCHAR(30), Anno YEAR) 
RETURNS INT
DETERMINISTIC
BEGIN
	DECLARE n INT DEFAULT 0;
	IF Anno>YEAR(NOW())
		THEN RETURN NULL;
	ELSE
		SELECT COUNT(*) INTO n 
			FROM Contributo C JOIN Risorsa_Astratta RA ON C.ID_Risorsa=RA.ID
			WHERE RA.ID=IDRisorsa AND YEAR(C.Data_inizio_attivita)<Anno<YEAR(NOW())
			GROUP BY RA.ID;
		RETURN n;
	END IF;
END $$
DELIMITER ;
# SET GLOBAL log_bin_trust_function_creators=FALSE;

SELECT NumeroRisorseAstratteAttivita('8838694451-978-8838694455', '2022');
SELECT NumeroRisorseAstratteAttivita('8838694451-978-8838694455', '2017');

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

###################### TRIGGER #####################

# calcolare l'importo durante la creazione di un ordine (in base al prodotto e alla quantità)
# autoincrement per il prodotto in base al bar
# autoincrement per l'ordine in base al bar
# autoincrement per le transazioni in base al bar
# controllo durante l'inserimento di un ordine, il bar deve essere legato alla scuola di appartenenza dell'utente
# controllo durante l'inserimento di una transazione, il bar deve essere legato alla scuola di appartenenza dell'utente

DELIMITER $$
CREATE TRIGGER CheckEsistenzaRisorsaAstratta
BEFORE INSERT ON Risorsa_Fisica
FOR EACH ROW
BEGIN
	IF (SELECT COUNT(*) FROM Risorsa_Astratta RA WHERE RA.ID=NEW.Risorsa_Astratta = 0)
		THEN INSERT INTO Risorsa_Astratta(ID) VALUES (NEW.Risorsa_Astratta);
	END IF;
END $$
DELIMITER ;

SELECT * FROM Risorsa_Astratta;
INSERT INTO Risorsa_Fisica VALUES ("978-88-919-0455-3",42,"SI","DIMAI-Ulisse Dini","Lettura");
SELECT * FROM Risorsa_Astratta;
SELECT * FROM Risorsa_Fisica;