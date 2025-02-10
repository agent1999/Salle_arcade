-- Créer les séquences
CREATE SEQUENCE addr_seq
    START 1
    INCREMENT 1
    MINVALUE 1
    MAXVALUE 999999
    CACHE 1;

CREATE SEQUENCE tran_seq
    START 1
    INCREMENT 1
    MINVALUE 1
    MAXVALUE 999999
    CACHE 1;

CREATE SEQUENCE cons_seq
    START 1
    INCREMENT 1
    MINVALUE 1
    MAXVALUE 999999
    CACHE 1;

CREATE SEQUENCE res_seq
    START 1
    INCREMENT 1
    MINVALUE 1
    MAXVALUE 999999
    CACHE 1;

CREATE SEQUENCE mach_seq
    START 1
    INCREMENT 1
    MINVALUE 1
    MAXVALUE 999999
    CACHE 1;

CREATE SEQUENCE jeu_seq
    START 1
    INCREMENT 1
    MINVALUE 1
    MAXVALUE 999999
    CACHE 1;

CREATE SEQUENCE sess_seq
    START 1
    INCREMENT 1
    MINVALUE 1
    MAXVALUE 999999
    CACHE 1;

-- Table Adresse
CREATE TABLE adresse (
    id_adresse VARCHAR(6) PRIMARY KEY DEFAULT 'Addr' || nextval('addr_seq'),
    numero_et_voie VARCHAR(100) NOT NULL CHECK (numero_et_voie ~ '^[0-9]+[a-zA-Z\s]+$'),
    code_postal VARCHAR(5) NOT NULL CHECK (code_postal ~ '^[0-9]{5}$'),
    commune VARCHAR(50) NOT NULL CHECK (commune ~ '^[a-zA-Z\s]+$')
);

-- Table Identite
CREATE TABLE identite (
    pseudo VARCHAR(27) PRIMARY KEY,
    nom VARCHAR(50) NOT NULL CHECK (nom ~ '^[A-Za-z]+$'),
    prenom VARCHAR(50) NOT NULL CHECK (prenom ~ '^[A-Za-z]+$'),
    id_adresse VARCHAR(6) NOT NULL,
    telephone VARCHAR(15) UNIQUE NOT NULL CHECK (telephone ~ '^\+?[0-9]+$'),  -- Téléphone avec format spécifique
    email VARCHAR(255) UNIQUE NOT NULL CHECK (email ~* '^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}$'),  -- Format email valide
    date_naissance DATE NOT NULL CHECK (date_naissance < CURRENT_DATE),
    FOREIGN KEY (id_adresse) REFERENCES adresse(id_adresse)
);

-- Table Utilisateurs
CREATE TABLE utilisateurs (
    pseudo VARCHAR(27) PRIMARY KEY UNIQUE NOT NULL,
    mot_de_passe VARCHAR(255) NOT NULL,
    date_inscription TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (pseudo) REFERENCES identite(pseudo) ON DELETE CASCADE
);

-- Table Personnel
CREATE TABLE personnel (
    pseudo_personnel VARCHAR(27) PRIMARY KEY,
    date_embauche_personnel DATE NOT NULL CHECK (date_embauche_personnel <= CURRENT_DATE), -- Date d'embauche <= TODAY()
    role_personnel VARCHAR(27) NOT NULL CHECK (role_personnel IN ('gestionnaire', 'technicien', 'caissier')),
    salaire FLOAT NOT NULL CHECK (salaire >= 0),
    status_personnel VARCHAR(27) NOT NULL CHECK (status_personnel IN ('actif', 'congé', 'démission')),
    conge_date_debut DATE,
    conge_date_fin DATE,
    FOREIGN KEY (pseudo_personnel) REFERENCES identite(pseudo) ON DELETE CASCADE
);

-- Table Joueur
CREATE TABLE joueur (
    pseudo_joueur VARCHAR(27) PRIMARY KEY UNIQUE NOT NULL,
    date_inscription_joueur DATE NOT NULL DEFAULT CURRENT_DATE, -- Valeur par défaut = today()
    carte_fidelite_id_joueur VARCHAR(20) UNIQUE,
    points_fidelite_joueur INT NOT NULL DEFAULT 0 CHECK (points_fidelite_joueur >= 0),
    solde_joueur FLOAT NOT NULL DEFAULT 0.00 CHECK (solde_joueur >= 0),
    pseudo_personnel VARCHAR(27) NOT NULL,
    FOREIGN KEY (pseudo_personnel) REFERENCES personnel(pseudo_personnel) ON DELETE CASCADE,
    FOREIGN KEY (pseudo_joueur) REFERENCES identite(pseudo) ON DELETE CASCADE
);

-- Table Transaction
CREATE TABLE transaction (
    id_transaction VARCHAR(5) PRIMARY KEY DEFAULT 'Tran' || nextval('tran_seq'),
    date_transaction DATE NOT NULL DEFAULT CURRENT_DATE,
    montant_transaction FLOAT NOT NULL CHECK (montant_transaction > 0),
    type_transaction VARCHAR(25) NOT NULL CHECK (type_transaction IN ('achat_jeton', 'achat_conso')),
    mode_paiement_transaction VARCHAR(25) NOT NULL CHECK (mode_paiement_transaction IN ('carte_bancaire', 'carte_fidelite', 'espece')),
    pseudo_joueur VARCHAR(27) NOT NULL,
    FOREIGN KEY (pseudo_joueur) REFERENCES joueur(pseudo_joueur) ON DELETE CASCADE
);

-- Table Consommable
CREATE TABLE consommable (
    id_consommable VARCHAR(6) PRIMARY KEY DEFAULT 'Cons' || nextval('cons_seq'),
    nom_consommable VARCHAR(50) NOT NULL,
    prix_consommable FLOAT NOT NULL CHECK (prix_consommable >= 0),
    stock_consommable INT NOT NULL CHECK (stock_consommable >= 0),
    pseudo_joueur VARCHAR(27) NOT NULL,
    FOREIGN KEY (pseudo_joueur) REFERENCES joueur(pseudo_joueur) ON DELETE CASCADE
);

-- Table Reservation
CREATE TABLE reservation (
    id_reservation VARCHAR(7) PRIMARY KEY DEFAULT 'Res' || nextval('res_seq'),
    date_debut_reservation DATE NOT NULL,
    date_fin_reservation DATE NOT NULL,
    status_reservation VARCHAR(27) NOT NULL CHECK (status_reservation IN ('a_venir', 'en_cours', 'finie')),
    pseudo_joueur VARCHAR(27) NOT NULL,
    id_machine VARCHAR(8) NOT NULL,
    FOREIGN KEY (pseudo_joueur) REFERENCES joueur(pseudo_joueur) ON DELETE CASCADE
);

-- Table Machine
CREATE TABLE machine (
    id_machine VARCHAR(8) PRIMARY KEY DEFAULT 'Mach' || nextval('mach_seq'),
    nom_machine VARCHAR(100) NOT NULL,
    emplacement_machine VARCHAR(50) NOT NULL,
    date_installation_machine DATE NOT NULL,
    statut_machine VARCHAR(50) NOT NULL CHECK (statut_machine IN ('disponible', 'maintenance', 'hors-service', 'occupee', 'reservee')),
    nom_du_sav_machine VARCHAR(50) NOT NULL,
    numero_du_sav_machine VARCHAR(15) NOT NULL CHECK (numero_du_sav_machine ~ '^\+?[0-9]+$'),
    pseudo_personnel VARCHAR(27) NOT NULL,
    id_reservation VARCHAR(7),
    FOREIGN KEY (pseudo_personnel) REFERENCES personnel(pseudo_personnel) ON DELETE CASCADE,
    FOREIGN KEY (id_reservation) REFERENCES reservation(id_reservation) ON DELETE SET NULL
);

-- Table Jeu
CREATE TABLE jeu (
    id_jeu VARCHAR(9) PRIMARY KEY DEFAULT 'Jeu' || nextval('jeu_seq'),
    nom_jeu VARCHAR(100) NOT NULL,
    categorie_jeu VARCHAR(27) NOT NULL,
    date_creation_jeu DATE NOT NULL CHECK (date_creation_jeu <= CURRENT_DATE),
    meilleur_score INT DEFAULT 0,
    id_machine VARCHAR(8) NOT NULL,
    FOREIGN KEY (id_machine) REFERENCES machine(id_machine) ON DELETE CASCADE
);

-- Table Est_classé
CREATE TABLE est_classe (
    id_jeu VARCHAR(9) NOT NULL,
    pseudo_joueur VARCHAR(27) NOT NULL,
    position INT NOT NULL,
    PRIMARY KEY (id_jeu, pseudo_joueur),
    FOREIGN KEY (id_jeu) REFERENCES jeu(id_jeu) ON DELETE CASCADE,
    FOREIGN KEY (pseudo_joueur) REFERENCES joueur(pseudo_joueur) ON DELETE CASCADE
);

-- Table Session
CREATE TABLE session (
    id_session VARCHAR(8) PRIMARY KEY DEFAULT 'Sess' || nextval('sess_seq'),
    id_machine VARCHAR(8) NOT NULL,
    pseudo_joueur VARCHAR(27) NOT NULL,
    date_heure_debut TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    date_heure_fin TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    score INT NOT NULL DEFAULT 0 CHECK (score >= 0),
    FOREIGN KEY (id_machine) REFERENCES machine(id_machine) ON DELETE CASCADE,
    FOREIGN KEY (pseudo_joueur) REFERENCES joueur(pseudo_joueur) ON DELETE CASCADE
);

-- Table Adresse
INSERT INTO adresse (numero_et_voie, code_postal, commune)
VALUES 
    ('10 RUE DES ARCADES', '75001', 'PARIS'),
    ('15 AVENUE DES GAMERS', '69007', 'LYON'),
    ('3 PLACE AMUSEMENT', '31000', 'TOULOUSE'),
    ('50 RUE DES JOUEURS', '44000', 'NANTES'),
    ('22 BOULEVARD DES PIXELS', '67000', 'STRASBOURG'),
    ('123 RUE DU GAME', '13001', 'MARSEILLE'),
    ('2 RUE ECRAN', '75002', 'PARIS');

-- Table Identite
INSERT INTO identite (pseudo, nom, prenom, id_adresse, telephone, email, date_naissance)
VALUES 
    ('SuperDad', 'DUPONT', 'JEAN', 'Addr1', '+33678912345', 'jean.dupont@family.com', '1975-06-15'),
    ('CoolMom', 'DUPONT', 'MARIE', 'Addr1', '+33698765432', 'marie.dupont@family.com', '1980-08-20'),
    ('LittleGamer', 'DUPONT', 'PIERRE', 'Addr1', '+33612345678', 'pierre.dupont@family.com', '2005-09-15'),
    ('ArcadePro', 'LEFEBVRE', 'JULIEN', 'Addr2', '+33611223344', 'julien.lefebvre@arcade.com', '1990-03-10'),
    ('RetroFan', 'GROSJEAN', 'EMMA', 'Addr3', '+33744556677', 'emma.grosjean@retro.com', '1995-07-25'),
    ('SpeedyKid', 'MARTIN', 'LUCAS', 'Addr4', '+33699887766', 'lucas.martin@speedy.com', '2010-05-10'),
    ('GamerGirl', 'TULIPE', 'SOPHIE', 'Addr5', '+33655343322', 'sophie.tulipe@girlpower.com', '2007-02-01'),
    ('ArcadeFan', 'GEORGES', 'GUY', 'Addr6', '+33655743323', 'guy.georges@girlpower.com', '2004-06-02'),
    ('ProGamer', 'GEORGES', 'LUCIE', 'Addr6', '+33655143324', 'lucie.georges@girlpower.com', '2009-11-11'),
    ('MegaPlayer', 'DURAND', 'PASCAL', 'Addr7', '+33755443325', 'pascal.durand@girlpower.com', '2002-03-04');

-- Table Personnel
INSERT INTO personnel (pseudo_personnel, date_embauche_personnel, role_personnel, salaire, status_personnel, conge_date_debut, conge_date_fin)
VALUES
    ('SuperDad', '2020-01-15', 'technicien', 2000.00, 'actif', NULL, NULL),
    ('CoolMom', '2021-06-20', 'caissier', 1800.00, 'actif', NULL, NULL),
    ('ArcadePro', '2019-03-10', 'gestionnaire', 3000.00, 'actif', NULL, NULL);

-- Table Joueur
INSERT INTO joueur (pseudo_joueur, date_inscription_joueur, carte_fidelite_id_joueur, points_fidelite_joueur, solde_joueur, pseudo_personnel)
VALUES
    ('LittleGamer', '2023-07-12', 'cf001', 300, 25.00, 'CoolMom'),
    ('RetroFan', '2023-08-15', 'cf002', 450, 50.00, 'SuperDad'),
    ('SpeedyKid', '2023-09-10', 'cf003', 100, 2.00, 'ArcadePro'),
    ('GamerGirl', '2023-09-15', 'cf004', 200, 15.00, 'CoolMom'),
    ('ArcadeFan', '2023-06-25', 'cf005', 500, 75.00, 'ArcadePro'),
    ('ProGamer', '2023-06-30', 'cf006', 600, 80.00, 'SuperDad'),
    ('MegaPlayer', '2023-07-05', 'cf007', 700, 90.00, 'CoolMom');

-- Table Transaction
INSERT INTO transaction (date_transaction, montant_transaction, type_transaction, mode_paiement_transaction, pseudo_joueur)
VALUES
    ('2024-02-22', 20.00, 'achat_jeton', 'carte_bancaire', 'GamerGirl'),
    ('2024-02-23', 5.00, 'achat_conso', 'carte_fidelite', 'SpeedyKid'),
    ('2024-03-01', 15.00, 'achat_jeton', 'carte_bancaire', 'MegaPlayer'),
    ('2024-03-02', 8.00, 'achat_conso', 'espece', 'ArcadeFan');

-- Table Consommable
INSERT INTO consommable (nom_consommable, prix_consommable, stock_consommable, pseudo_joueur)
VALUES
    ('Eau Minerale', 5.00, 50, 'SpeedyKid'),
    ('Chips', 8.00, 30, 'ArcadeFan');

-- Table Machine
INSERT INTO machine (nom_machine, emplacement_machine, date_installation_machine, statut_machine, nom_du_sav_machine, numero_du_sav_machine, pseudo_personnel)
VALUES
    ('Nintendo Wii', 'Zone 1', '2022-05-01', 'disponible', 'TechSav', '+33678912345', 'SuperDad'),
    ('Playstation 5', 'Zone 2', '2022-06-01', 'reservee', 'VRFix', '+33798765432', 'CoolMom'),
    ('Xbox Series X', 'Zone 3', '2022-07-01', 'disponible', 'RetroRepair', '+33654321098', 'ArcadePro'),
    ('PC Gaming', 'Zone 4', '2022-08-01', 'occupee', 'BlockFix', '+33611122233', 'SuperDad'),
    ('Nintendo Switch', 'Zone 5', '2022-09-01', 'occupee', 'KingFix', '+33765432109', 'CoolMom'),
    ('Nintendo DS', 'Zone 6', '2022-10-01', 'disponible', 'FightFix', '+33655566677', 'ArcadePro'),
    ('Sony VR', 'Zone 7', '2022-11-01', 'disponible', 'DanceFix', '+33712345678', 'SuperDad');

-- Table Reservation
INSERT INTO reservation (date_debut_reservation, date_fin_reservation, status_reservation, pseudo_joueur, id_machine)
VALUES
    ('2024-12-09 09:00:00', '2024-12-09 10:00:00', 'finie', 'SpeedyKid', 'Mach2'),
    ('2024-12-12 10:00:00', '2024-12-12 11:00:00', 'en_cours', 'RetroFan', 'Mach2'),
    ('2024-12-14 11:30:00', '2024-12-14 12:30:00', 'a_venir', 'GamerGirl', 'Mach6');

-- Table Jeu
INSERT INTO jeu (nom_jeu, categorie_jeu, date_creation_jeu, id_machine)
VALUES
    ('Super Mario Bros', 'arcade', '1985-09-13', 'Mach1'),
    ('The Last of Us', 'jeu vidéo', '2013-06-14', 'Mach2'),
    ('Fortnite VR', 'vr', '2018-09-26', 'Mach3'),
    ('Minecraft', 'jeu vidéo', '2009-11-18', 'Mach4'),
    ('FIFA 21', 'jeu vidéo', '2020-10-09', 'Mach5'),
    ('Street Fighter V', 'arcade', '2016-02-16', 'Mach6'),
    ('Beat Saber', 'rhythm', '2018-05-01', 'Mach7');

-- Table Session
INSERT INTO session (id_machine, pseudo_joueur, date_heure_debut, date_heure_fin, score)
VALUES
    ('Mach4', 'LittleGamer', '2024-12-12 10:00:00', '2024-12-12 11:00:00', 450),
    ('Mach5', 'RetroFan', '2024-12-12 10:00:00', '2024-12-12 11:00:00', 500),
    ('Mach7', 'MegaPlayer', '2024-02-25 14:00:00', '2024-02-25 15:00:00', 250),
    ('Mach1', 'ArcadeFan', '2024-02-26 16:00:00', '2024-02-26 17:00:00', 400);