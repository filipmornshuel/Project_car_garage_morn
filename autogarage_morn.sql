/*
- Autor: Filip Slavkovic
- Datum: 17.10.2021
- Version: 0.2 
*/

DROP DATABASE if EXISTS autogarage_morn;
CREATE DATABASE autogarage_morn;
USE autogarage_morn;

/*
Diese Datenbank wurde mit dem Editor von HeidiSQL gemacht und über MYSQL MariaDB geschrieben.
*/
-- Erstellung der Tabelle Postleitzahl für eindeutige Übereinstimmung und Sicherung der Datenkonsistenz
CREATE TABLE plz(
	id SERIAL,
	plz SMALLINT(4) UNSIGNED NOT NULL CHECK (plz<10000) AND CHECK(plz>0), 
	-- Hier wurde Check gemacht, um sicherzustellen, dass keine PLZ grösser als 10000 und kleiner als 0 ist.
	ort VARCHAR(255) NOT NULL, -- Ort = z.B. Zürich, Basel, Wettingen usw...
	
	PRIMARY KEY(id),
	UNIQUE(plz, ort) -- Unique steht für einmalig... darf nicht mehrmals vorkommmen
	
);

-- Erstellung der Tabelle Kunden mit allen relevanten Informationen, die gebraucht sind.
CREATE TABLE kunde (
	id SERIAL,
	vorname VARCHAR(255) NOT NULL,
	nachname VARCHAR(255) NOT NULL,
	email VARCHAR(380) NOT NULL UNIQUE, -- Auch hier unique für einmalige E-Mail-Adresse
	telefon VARCHAR(255) NOT NULL UNIQUE, -- Einmalige Telefonnummer
	adresse VARCHAR(255) NOT null,
	zusatzadresse VARCHAR(255),
	plz_id BIGINT UNSIGNED NOT NULL CHECK (plz_id >0), -- Fremdschlüssel plz_id 
	
	
	PRIMARY KEY (id),
	FOREIGN KEY(plz_id) REFERENCES plz(id) ON UPDATE CASCADE ON DELETE CASCADE
);

-- Alle Kategorien der Autos werden hier gespeichert.
CREATE TABLE autokategorie(
	id SERIAL,
	kategorie VARCHAR(255) NOT NULL,
	PRIMARY KEY(id)
);


CREATE TABLE auto(
	id SERIAL,
	autokategorie_id BIGINT UNSIGNED NOT NULL CHECK(autokategorie_id > 0), -- Darf nicht 0 sein auch Fremdschlüssel
	marke VARCHAR(255) NOT NULL,
	model VARCHAR(255) NOT NULL,
	baujahr DATE NOT NULL, 
	leistung INT(5) NOT NULL CHECK (leistung > 0), -- Darf nicht 0 sein
	hubraum INT(5) NOT NULL CHECK (hubraum >0), -- //
	preis DECIMAL(10,2) NOT NULL CHECK(preis>0), -- //
	gänge INT(2) NOT NULL CHECK(gänge >0), -- //
	beschreibung TEXT,
	
	PRIMARY KEY(id),
	FOREIGN KEY(autokategorie_id) REFERENCES autokategorie(id) ON UPDATE CASCADE ON DELETE CASCADE
);


-- Leiter eines Ladens ist hiermit gemeint + Fremdschlüssel plz_id.
CREATE TABLE leiter(
	id SERIAL,
	vorname VARCHAR(255) NOT NULL,
	nachname VARCHAR(255) NOT NULL,
	email VARCHAR(380) not null UNIQUE,
	telefon VARCHAR(255) NOT NULL UNIQUE,
	adresse VARCHAR(255) NOT null,
	zusatzadresse VARCHAR(255),
	plz_id BIGINT UNSIGNED NOT NULL CHECK(plz_id >0), -- Darf nicht 0 sein
	beitrittsdatum DATETIME,
	bild BLOB,
	
	PRIMARY KEY (id),
	FOREIGN KEY(plz_id) REFERENCES plz(id) ON UPDATE CASCADE ON DELETE CASCADE
);

-- beinhaltet alle relevanten Informationen zum Laden + den Leiter des Ladens als Fremdsdchlüssel.
CREATE TABLE laden(
	id SERIAL,
	ladenname VARCHAR(255) NOT NULL,
	email VARCHAR(380) not null UNIQUE,
	telefon VARCHAR(255) NOT NULL UNIQUE,
	adresse VARCHAR(255) NOT null,
	zusatzadresse VARCHAR(255),
	plz_id BIGINT UNSIGNED NOT NULL CHECK(plz_id >0), -- Darf nicht 0 sein
	leiter_id BIGINT UNSIGNED NOT NULL CHECK(leiter_id >0), -- Darf nicht 0 sein 
	PRIMARY KEY (id),
	FOREIGN KEY(plz_id) REFERENCES plz(id) ON UPDATE CASCADE ON DELETE CASCADE,
	FOREIGN KEY(leiter_id) REFERENCES leiter(id) ON UPDATE CASCADE ON DELETE CASCADE
	
);

-- Alle relevanten Informationen zum Mitarbeiter + Fremdschlüssel von laden_id und plz_id 
CREATE TABLE mitarbeiter(
	id SERIAL,
	vorname VARCHAR(255) NOT NULL,
	nachname VARCHAR(255) NOT NULL,
	email VARCHAR(380) not null UNIQUE, -- hier und einen weiter unten unique, da beide einmalig sein sollen. 
	telefon VARCHAR(255) NOT NULL UNIQUE,
	adresse VARCHAR(255) NOT null,
	zusatzadresse VARCHAR(255),
	plz_id BIGINT UNSIGNED NOT NULL CHECK(plz_id >0), -- Darf nicht 0 sein
	beitrittsdatum DATETIME,
	bild BLOB,  -- Kann Bild eingefügt werden.
	laden_id BIGINT UNSIGNED NOT NULL CHECK(laden_id >0), -- Darf nicht 0 sein
	
	
	PRIMARY KEY (id),
	FOREIGN KEY(plz_id) REFERENCES plz(id) ON UPDATE CASCADE ON DELETE CASCADE,
	FOREIGN KEY(laden_id) REFERENCES laden(id) ON UPDATE CASCADE ON DELETE CASCADE
);

-- Tabelle Autoinventar, in der alle verfügbaren Autos gespeichert werden und in welchem Laden sie sich befinden.
CREATE TABLE autoinventar(
	id SERIAL,
	auto_id BIGINT UNSIGNED NOT NULL CHECK(auto_id >0), -- Darf nicht 0 sein
	laden_id BIGINT UNSIGNED NOT NULL CHECK(laden_id >0), -- Darf nicht 0 sein
	letzesUpdate TIMESTAMP, -- Mit letztes Update ist gemeint, wann zuletzt die Autoinventar-Tabelle akualisiert wurde. 
	
	PRIMARY KEY(id),
	FOREIGN KEY(laden_id) REFERENCES laden(id) ON UPDATE CASCADE ON DELETE CASCADE,
	FOREIGN KEY(auto_id) REFERENCES auto(id) ON UPDATE CASCADE ON DELETE CASCADE

);

-- Tabelle Probefahrt zur Probefahrt mit Fremdschlüssen von Mitarbeiter, Kunde und Laden
CREATE TABLE probefahrt(
	id SERIAL,
	mitarbeiter_id BIGINT UNSIGNED NOT NULL CHECK(mitarbeiter_id >0), -- Darf nicht 0 sein
	kunde_id BIGINT unsigned NOT NULL CHECK(kunde_id >0), -- Darf nicht 0 sein
	laden_id BIGINT UNSIGNED NOT NULL CHECK(laden_id >0), -- Darf nicht 0 sein
	probefahrtDatum DATETIME NOT NULL, -- Das Datum, wann der Kunde das Auto erhalten hat.
	rückgabeDatum DATETIME, -- Das Datum, wann der Kunde das Auto zurückgegeben hat.
	letzesUpdate TIMESTAMP, -- Letztes Update, um zu überprüfen, ob sich etwas geändert hat.
	
	PRIMARY KEY(id),
	FOREIGN KEY(kunde_id) REFERENCES kunde(id) ON UPDATE CASCADE ON DELETE CASCADE,
	FOREIGN KEY(laden_id) REFERENCES laden(id) ON UPDATE CASCADE ON DELETE CASCADE,
	FOREIGN KEY (mitarbeiter_id) REFERENCES mitarbeiter(id) ON UPDATE CASCADE ON DELETE CASCADE
);


-- Eine "zwischen" Tabelle wurde gemacht, damit die Datenkonsistenz gewährleistet bleibt. 
CREATE TABLE probefahrt_autoinventar(
	probefahrt_id BIGINT UNSIGNED NOT NULL CHECK(probefahrt_id >0), -- Fremdschlüssel von Probefahrt
	autoinventar_id BIGINT UNSIGNED NOT NULL CHECK(autoinventar_id >0), -- Fremdschlüssel von Autoinventar
	FOREIGN KEY(probefahrt_id) REFERENCES probefahrt(id) ON UPDATE CASCADE ON DELETE CASCADE,
	FOREIGN KEY(autoinventar_id) REFERENCES autoinventar(id) ON UPDATE CASCADE ON DELETE CASCADE

);



-- Verkaufstabelle mit allen relevanten Informationen zur Kaufabwicklung des.
CREATE TABLE verkauf(
	id SERIAL,
	kunde_id BIGINT UNSIGNED NOT NULL CHECK(kunde_id >0), -- Darf nicht 0 sein + Fremdschlüssel von Kunde
	laden_id BIGINT UNSIGNED NOT NULL CHECK(laden_id >0), -- Darf nicht 0 sein + Fremdschlüssel von Laden
	mitarbeiter_id BIGINT UNSIGNED NOT NULL CHECK(mitarbeiter_id >0), -- Darf nicht 0 sein
	betrag DECIMAL(10,2) NOT NULL,
	kaufdatum DATETIME NOT NULL, 
	zahlungseingang BOOLEAN NOT NULL, -- Bollean zum überprüfen, ob der Kunde bezahlt hat oder noch nicht.
	letzesUpdate TIMESTAMP, -- Letztes Update, um zu überprüfen, ob sich etwas geändert hat.
	
	PRIMARY KEY(id),
	FOREIGN KEY(kunde_id) REFERENCES kunde(id) ON UPDATE CASCADE ON DELETE CASCADE,
	FOREIGN KEY(laden_id) REFERENCES laden(id) ON UPDATE CASCADE ON DELETE CASCADE,
	FOREIGN KEY (mitarbeiter_id) REFERENCES mitarbeiter(id) ON UPDATE CASCADE ON DELETE CASCADE

);

-- Wieder eine "zwischen" Tabelle zur Sicherung der Datenkonsistenz. 
CREATE TABLE verkauf_autoinventar(
	verkauf_id BIGINT UNSIGNED NOT NULL CHECK(verkauf_id >0), -- Darf nicht 0 sein, Fremdschlüssel von Verkauf
	autoinventar_id BIGINT UNSIGNED NOT NULL CHECK(autoinventar_id >0), -- Darf nicht 0 sein, Fremdschlüssel von Inventar
	FOREIGN KEY(autoinventar_id) REFERENCES autoinventar(id) ON UPDATE CASCADE ON DELETE CASCADE,
	FOREIGN KEY(verkauf_id) REFERENCES verkauf(id) ON UPDATE CASCADE ON DELETE CASCADE

);













