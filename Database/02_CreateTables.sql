-- ============================================================================
-- Projet: Gestion des Réservations de Salles
-- Fichier: 02_CreateTables.sql
-- Description: Création des tables avec contraintes d'intégrité
-- Date: 25 juin 2025
-- ============================================================================

USE GestionReservationSalles;

-- Suppression des tables existantes (ordre inverse des dépendances)
IF OBJECT_ID('reservation.HistoriqueReservation', 'U') IS NOT NULL
    DROP TABLE reservation.HistoriqueReservation;
IF OBJECT_ID('reservation.Reservation', 'U') IS NOT NULL
    DROP TABLE reservation.Reservation;
IF OBJECT_ID('reservation.TypeEvenement', 'U') IS NOT NULL
    DROP TABLE reservation.TypeEvenement;
IF OBJECT_ID('reservation.Salle', 'U') IS NOT NULL
    DROP TABLE reservation.Salle;
IF OBJECT_ID('reservation.Utilisateur', 'U') IS NOT NULL
    DROP TABLE reservation.Utilisateur;

-- ============================================================================
-- Table UTILISATEUR
-- ============================================================================
CREATE TABLE reservation.Utilisateur (
    UserID INT IDENTITY(1,1) PRIMARY KEY,
    Nom NVARCHAR(50) NOT NULL,
    Prenom NVARCHAR(50) NOT NULL,
    Email NVARCHAR(100) NOT NULL UNIQUE,
    Role NVARCHAR(20) NOT NULL DEFAULT 'Employe',
    MotDePasse NVARCHAR(255) NOT NULL,
    Actif BIT NOT NULL DEFAULT 1,
    DateCreation DATETIME2 NOT NULL DEFAULT GETDATE(),
    
    -- Contraintes
    CONSTRAINT CK_Utilisateur_Role CHECK (Role IN ('Employe', 'Manager', 'Admin')),
    CONSTRAINT CK_Utilisateur_Email CHECK (Email LIKE '%@%.%')
);

-- Index sur Email pour les recherches
CREATE NONCLUSTERED INDEX IX_Utilisateur_Email ON reservation.Utilisateur(Email);
CREATE NONCLUSTERED INDEX IX_Utilisateur_Role ON reservation.Utilisateur(Role);

-- ============================================================================
-- Table SALLE
-- ============================================================================
CREATE TABLE reservation.Salle (
    SalleID INT IDENTITY(1,1) PRIMARY KEY,
    NomSalle NVARCHAR(50) NOT NULL UNIQUE,
    Capacite INT NOT NULL,
    Equipements NVARCHAR(255),
    Localisation NVARCHAR(100),
    Disponible BIT NOT NULL DEFAULT 1,
    TarifHoraire DECIMAL(10,2) DEFAULT 0.00,
    
    -- Contraintes
    CONSTRAINT CK_Salle_Capacite CHECK (Capacite > 0),
    CONSTRAINT CK_Salle_Tarif CHECK (TarifHoraire >= 0)
);

-- Index sur les critères de recherche
CREATE NONCLUSTERED INDEX IX_Salle_Capacite ON reservation.Salle(Capacite);
CREATE NONCLUSTERED INDEX IX_Salle_Disponible ON reservation.Salle(Disponible);

-- ============================================================================
-- Table TYPE_EVENEMENT
-- ============================================================================
CREATE TABLE reservation.TypeEvenement (
    TypeEventID INT IDENTITY(1,1) PRIMARY KEY,
    NomType NVARCHAR(50) NOT NULL UNIQUE,
    Description NVARCHAR(255),
    DureeMinimale INT NOT NULL DEFAULT 30, -- en minutes
    DureeMaximale INT NOT NULL DEFAULT 480, -- 8 heures max
    NecessiteValidation BIT NOT NULL DEFAULT 0,
    
    -- Contraintes
    CONSTRAINT CK_TypeEvenement_Duree CHECK (DureeMinimale <= DureeMaximale),
    CONSTRAINT CK_TypeEvenement_DureeMin CHECK (DureeMinimale > 0)
);

-- ============================================================================
-- Table RESERVATION
-- ============================================================================
CREATE TABLE reservation.Reservation (
    ReservationID INT IDENTITY(1,1) PRIMARY KEY,
    UserID INT NOT NULL,
    SalleID INT NOT NULL,
    TypeEventID INT NOT NULL,
    ObjetReservation NVARCHAR(100) NOT NULL,
    DateReservation DATE NOT NULL,
    HeureDebut TIME NOT NULL,
    HeureFin TIME NOT NULL,
    Statut NVARCHAR(20) NOT NULL DEFAULT 'En_Attente',
    DateDemande DATETIME2 NOT NULL DEFAULT GETDATE(),
    DateValidation DATETIME2 NULL,
    ValidePar INT NULL,
    Commentaires NVARCHAR(500),
    
    -- Clés étrangères
    CONSTRAINT FK_Reservation_Utilisateur FOREIGN KEY (UserID) 
        REFERENCES reservation.Utilisateur(UserID),
    CONSTRAINT FK_Reservation_Salle FOREIGN KEY (SalleID) 
        REFERENCES reservation.Salle(SalleID),
    CONSTRAINT FK_Reservation_TypeEvenement FOREIGN KEY (TypeEventID) 
        REFERENCES reservation.TypeEvenement(TypeEventID),
    CONSTRAINT FK_Reservation_Validateur FOREIGN KEY (ValidePar) 
        REFERENCES reservation.Utilisateur(UserID),
    
    -- Contraintes métier
    CONSTRAINT CK_Reservation_Statut CHECK (Statut IN ('En_Attente', 'Validee', 'Refusee', 'Annulee')),
    CONSTRAINT CK_Reservation_Heures CHECK (HeureDebut < HeureFin),
    CONSTRAINT CK_Reservation_DateFuture CHECK (DateReservation >= CAST(GETDATE() AS DATE)),
    CONSTRAINT CK_Reservation_ValidationLogique CHECK (
        (Statut IN ('Validee', 'Refusee') AND ValidePar IS NOT NULL AND DateValidation IS NOT NULL) OR
        (Statut IN ('En_Attente', 'Annulee'))
    )
);

-- Index pour les recherches fréquentes
CREATE NONCLUSTERED INDEX IX_Reservation_DateSalle ON reservation.Reservation(DateReservation, SalleID);
CREATE NONCLUSTERED INDEX IX_Reservation_UserStatut ON reservation.Reservation(UserID, Statut);
CREATE NONCLUSTERED INDEX IX_Reservation_Statut ON reservation.Reservation(Statut);

-- ============================================================================
-- Table HISTORIQUE_RESERVATION
-- ============================================================================
CREATE TABLE reservation.HistoriqueReservation (
    HistoriqueID INT IDENTITY(1,1) PRIMARY KEY,
    ReservationID INT NOT NULL,
    Action NVARCHAR(50) NOT NULL,
    DateAction DATETIME2 NOT NULL DEFAULT GETDATE(),
    UserID INT NOT NULL,
    Details NVARCHAR(255),
    
    -- Clés étrangères
    CONSTRAINT FK_Historique_Reservation FOREIGN KEY (ReservationID) 
        REFERENCES reservation.Reservation(ReservationID) ON DELETE CASCADE,
    CONSTRAINT FK_Historique_Utilisateur FOREIGN KEY (UserID) 
        REFERENCES reservation.Utilisateur(UserID),
    
    -- Contraintes
    CONSTRAINT CK_Historique_Action CHECK (Action IN ('Creation', 'Modification', 'Validation', 'Refus', 'Annulation'))
);

-- Index pour l'historique
CREATE NONCLUSTERED INDEX IX_Historique_Reservation ON reservation.HistoriqueReservation(ReservationID);
CREATE NONCLUSTERED INDEX IX_Historique_Date ON reservation.HistoriqueReservation(DateAction);

PRINT 'Toutes les tables ont été créées avec succès.';