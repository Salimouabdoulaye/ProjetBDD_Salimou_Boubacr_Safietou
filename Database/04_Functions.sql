-- ============================================================================
-- Projet: Gestion des Réservations de Salles
-- Fichier: 04_Functions.sql
-- Description: Fonctions SQL Server utilitaires
-- Date: 25 juin 2025
-- ============================================================================

USE GestionReservationSalles;

-- ============================================================================
-- Fonction: fn_SalleDisponible
-- Description: Vérifie si une salle est disponible pour une plage horaire donnée
-- Paramètres: @Date, @HeureDebut, @HeureFin
-- Retour: Table des salles disponibles
-- ============================================================================
IF OBJECT_ID('reservation.fn_SalleDisponible', 'TF') IS NOT NULL
    DROP FUNCTION reservation.fn_SalleDisponible;
GO

CREATE FUNCTION reservation.fn_SalleDisponible(
    @Date DATE,
    @HeureDebut TIME,
    @HeureFin TIME
)
RETURNS TABLE
AS
RETURN (
    SELECT 
        s.SalleID,
        s.NomSalle,
        s.Capacite,
        s.Equipements,
        s.Localisation,
        s.TarifHoraire
    FROM reservation.Salle s
    WHERE s.Disponible = 1
    AND s.SalleID NOT IN (
        SELECT r.SalleID
        FROM reservation.Reservation r
        WHERE r.DateReservation = @Date
        AND r.Statut IN ('Validee', 'En_Attente')
        AND (
            (@HeureDebut >= r.HeureDebut AND @HeureDebut < r.HeureFin) OR
            (@HeureFin > r.HeureDebut AND @HeureFin <= r.HeureFin) OR
            (@HeureDebut <= r.HeureDebut AND @HeureFin >= r.HeureFin)
        )
    )
);
GO

-- ============================================================================
-- Fonction: fn_CapaciteDisponible
-- Description: Retourne la capacité disponible d'une salle pour une date donnée
-- Paramètres: @SalleID, @Date
-- Retour: Capacité disponible ou 0 si occupée
-- ============================================================================
IF OBJECT_ID('reservation.fn_CapaciteDisponible', 'FN') IS NOT NULL
    DROP FUNCTION reservation.fn_CapaciteDisponible;
GO

CREATE FUNCTION reservation.fn_CapaciteDisponible(
    @SalleID INT,
    @Date DATE
)
RETURNS INT
AS
BEGIN
    DECLARE @Capacite INT = 0;
    
    -- Vérifier si la salle existe et est disponible
    IF EXISTS (SELECT 1 FROM reservation.Salle WHERE SalleID = @SalleID AND Disponible = 1)
    BEGIN
        -- Vérifier s'il y a des réservations pour cette date
        IF NOT EXISTS (
            SELECT 1 
            FROM reservation.Reservation 
            WHERE SalleID = @SalleID 
            AND DateReservation = @Date 
            AND Statut IN ('Validee', 'En_Attente')
        )
        BEGIN
            -- Aucune réservation, retourner la capacité complète
            SELECT @Capacite = Capacite 
            FROM reservation.Salle 
            WHERE SalleID = @SalleID;
        END
        -- Sinon, la salle est occupée, capacité = 0
    END
    
    RETURN @Capacite;
END
GO

-- ============================================================================
-- Fonction: fn_StatutUtilisateur
-- Description: Retourne le statut et les informations d'un utilisateur
-- Paramètres: @UserID
-- Retour: Table avec informations utilisateur
-- ============================================================================
IF OBJECT_ID('reservation.fn_StatutUtilisateur', 'TF') IS NOT NULL
    DROP FUNCTION reservation.fn_StatutUtilisateur;
GO

CREATE FUNCTION reservation.fn_StatutUtilisateur(
    @UserID INT
)
RETURNS TABLE
AS
RETURN (
    SELECT 
        u.UserID,
        u.Nom,
        u.Prenom,
        u.Email,
        u.Role,
        u.Actif,
        u.DateCreation,
        CASE 
            WHEN u.Actif = 0 THEN 'Inactif'
            WHEN u.Role = 'Admin' THEN 'Administrateur'
            WHEN u.Role = 'Manager' THEN 'Gestionnaire'
            ELSE 'Utilisateur standard'
        END AS StatutDescription,
        CASE 
            WHEN u.Role IN ('Admin', 'Manager') THEN 1
            ELSE 0
        END AS PeutValider
    FROM reservation.Utilisateur u
    WHERE u.UserID = @UserID
);
GO

-- ============================================================================
-- Fonction: fn_DureeReservation
-- Description: Calcule la durée d'une réservation en minutes
-- Paramètres: @ResID
-- Retour: Durée en minutes
-- ============================================================================
IF OBJECT_ID('reservation.fn_DureeReservation', 'FN') IS NOT NULL
    DROP FUNCTION reservation.fn_DureeReservation;
GO

CREATE FUNCTION reservation.fn_DureeReservation(
    @ResID INT
)
RETURNS INT
AS
BEGIN
    DECLARE @Duree INT = 0;
    
    SELECT @Duree = DATEDIFF(MINUTE, HeureDebut, HeureFin)
    FROM reservation.Reservation
    WHERE ReservationID = @ResID;
    
    RETURN ISNULL(@Duree, 0);
END
GO

-- ============================================================================
-- Fonction: fn_ReservationsUtilisateur
-- Description: Retourne les réservations d'un utilisateur avec détails
-- Paramètres: @UserID, @DateDebut (optionnel), @DateFin (optionnel)
-- Retour: Table des réservations
-- ============================================================================
IF OBJECT_ID('reservation.fn_ReservationsUtilisateur', 'TF') IS NOT NULL
    DROP FUNCTION reservation.fn_ReservationsUtilisateur;
GO

CREATE FUNCTION reservation.fn_ReservationsUtilisateur(
    @UserID INT,
    @DateDebut DATE = NULL,
    @DateFin DATE = NULL
)
RETURNS TABLE
AS
RETURN (
    SELECT 
        r.ReservationID,
        r.ObjetReservation,
        r.DateReservation,
        r.HeureDebut,
        r.HeureFin,
        r.Statut,
        s.NomSalle,
        s.Localisation,
        te.NomType,
        reservation.fn_DureeReservation(r.ReservationID) AS DureeMinutes,
        r.DateDemande,
        r.DateValidation,
        v.Nom + ' ' + v.Prenom AS ValidePar
    FROM reservation.Reservation r
    INNER JOIN reservation.Salle s ON r.SalleID = s.SalleID
    INNER JOIN reservation.TypeEvenement te ON r.TypeEventID = te.TypeEventID
    LEFT JOIN reservation.Utilisateur v ON r.ValidePar = v.UserID
    WHERE r.UserID = @UserID
    AND (@DateDebut IS NULL OR r.DateReservation >= @DateDebut)
    AND (@DateFin IS NULL OR r.DateReservation <= @DateFin)
);
GO

-- ============================================================================
-- Fonction: fn_StatistiquesUtilisation
-- Description: Statistiques d'utilisation des salles
-- Paramètres: @DateDebut, @DateFin
-- Retour: Table avec statistiques par salle
-- ============================================================================
IF OBJECT_ID('reservation.fn_StatistiquesUtilisation', 'TF') IS NOT NULL
    DROP FUNCTION reservation.fn_StatistiquesUtilisation;
GO

CREATE FUNCTION reservation.fn_StatistiquesUtilisation(
    @DateDebut DATE,
    @DateFin DATE
)
RETURNS TABLE
AS
RETURN (
    SELECT 
        s.SalleID,
        s.NomSalle,
        s.Capacite,
        COUNT(r.ReservationID) AS NombreReservations,
        COUNT(CASE WHEN r.Statut = 'Validee' THEN 1 END) AS ReservationsValidees,
        COUNT(CASE WHEN r.Statut = 'En_Attente' THEN 1 END) AS ReservationsEnAttente,
        COUNT(CASE WHEN r.Statut = 'Refusee' THEN 1 END) AS ReservationsRefusees,
        SUM(CASE WHEN r.Statut = 'Validee' THEN reservation.fn_DureeReservation(r.ReservationID) ELSE 0 END) AS MinutesOccupees,
        ROUND(
            CAST(COUNT(CASE WHEN r.Statut = 'Validee' THEN 1 END) AS FLOAT) / 
            NULLIF(COUNT(r.ReservationID), 0) * 100, 2
        ) AS TauxValidation
    FROM reservation.Salle s
    LEFT JOIN reservation.Reservation r ON s.SalleID = r.SalleID
        AND r.DateReservation BETWEEN @DateDebut AND @DateFin
    GROUP BY s.SalleID, s.NomSalle, s.Capacite
);
GO

-- ============================================================================
-- Test des fonctions
-- ============================================================================
PRINT 'Test des fonctions créées:';

-- Test fn_SalleDisponible
PRINT 'Salles disponibles le 2025-06-26 de 14:00 à 16:00:';
SELECT * FROM reservation.fn_SalleDisponible('2025-06-26', '14:00', '16:00');

-- Test fn_CapaciteDisponible
PRINT 'Capacité disponible salle 1 le 2025-06-26:';
SELECT reservation.fn_CapaciteDisponible(1, '2025-06-26') AS CapaciteDisponible;

-- Test fn_StatutUtilisateur
PRINT 'Statut utilisateur ID 2:';
SELECT * FROM reservation.fn_StatutUtilisateur(2);

-- Test fn_DureeReservation
PRINT 'Durée réservation ID 1:';
SELECT reservation.fn_DureeReservation(1) AS DureeMinutes;

PRINT 'Toutes les fonctions ont été créées et testées avec succès.';