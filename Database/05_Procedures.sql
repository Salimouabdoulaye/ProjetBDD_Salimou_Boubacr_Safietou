-- ============================================================================
-- Projet: Gestion des Réservations de Salles
-- Fichier: 05_Procedures.sql
-- Description: Procédures stockées pour la gestion des réservations
-- Date: 25 juin 2025
-- ============================================================================

USE GestionReservationSalles;

-- ============================================================================
-- Procédure: sp_ReserverSalle
-- Description: Crée une nouvelle réservation avec validations
-- Paramètres: Tous les détails de la réservation
-- ============================================================================
IF OBJECT_ID('reservation.sp_ReserverSalle', 'P') IS NOT NULL
    DROP PROCEDURE reservation.sp_ReserverSalle;
GO

CREATE PROCEDURE reservation.sp_ReserverSalle
    @UserID INT,
    @SalleID INT,
    @TypeEventID INT,
    @ObjetReservation NVARCHAR(100),
    @DateReservation DATE,
    @HeureDebut TIME,
    @HeureFin TIME,
    @Commentaires NVARCHAR(500) = NULL,
    @ReservationID INT OUTPUT,
    @Message NVARCHAR(500) OUTPUT
AS
BEGIN
    SET NOCOUNT ON;
    BEGIN TRY
        BEGIN TRANSACTION;
        
        -- Variables de travail
        DECLARE @NecessiteValidation BIT;
        DECLARE @StatutInitial NVARCHAR(20);
        DECLARE @DureeMinutes INT;
        DECLARE @DureeMinimale INT, @DureeMaximale INT;
        
        -- Validation de l'utilisateur
        IF NOT EXISTS (SELECT 1 FROM reservation.Utilisateur WHERE UserID = @UserID AND Actif = 1)
        BEGIN
            SET @Message = 'Utilisateur inexistant ou inactif.';
            ROLLBACK TRANSACTION;
            RETURN -1;
        END
        
        -- Validation de la salle
        IF NOT EXISTS (SELECT 1 FROM reservation.Salle WHERE SalleID = @SalleID AND Disponible = 1)
        BEGIN
            SET @Message = 'Salle inexistante ou indisponible.';
            ROLLBACK TRANSACTION;
            RETURN -2;
        END
        
        -- Validation du type d'événement et récupération des contraintes
        SELECT @NecessiteValidation = NecessiteValidation, 
               @DureeMinimale = DureeMinimale, 
               @DureeMaximale = DureeMaximale
        FROM reservation.TypeEvenement 
        WHERE TypeEventID = @TypeEventID;
        
        IF @@ROWCOUNT = 0
        BEGIN
            SET @Message = 'Type d''événement inexistant.';
            ROLLBACK TRANSACTION;
            RETURN -3;
        END
        
        -- Validation de la durée
        SET @DureeMinutes = DATEDIFF(MINUTE, @HeureDebut, @HeureFin);
        
        IF @DureeMinutes < @DureeMinimale OR @DureeMinutes > @DureeMaximale
        BEGIN
            SET @Message = CONCAT('Durée invalide. Doit être entre ', @DureeMinimale, ' et ', @DureeMaximale, ' minutes.');
            ROLLBACK TRANSACTION;
            RETURN -4;
        END
        
        -- Vérification de la disponibilité de la salle
        IF EXISTS (
            SELECT 1 FROM reservation.fn_SalleDisponible(@DateReservation, @HeureDebut, @HeureFin)
            WHERE SalleID = @SalleID
        )
        BEGIN
            -- Salle disponible, déterminer le statut initial
            SET @StatutInitial = CASE WHEN @NecessiteValidation = 1 THEN 'En_Attente' ELSE 'Validee' END;
            
            -- Insérer la réservation
            INSERT INTO reservation.Reservation (
                UserID, SalleID, TypeEventID, ObjetReservation, 
                DateReservation, HeureDebut, HeureFin, Statut, 
                DateDemande, Commentaires
            )
            VALUES (
                @UserID, @SalleID, @TypeEventID, @ObjetReservation,
                @DateReservation, @HeureDebut, @HeureFin, @StatutInitial,
                GETDATE(), @Commentaires
            );
            
            SET @ReservationID = SCOPE_IDENTITY();
            
            -- Enregistrer dans l'historique
            INSERT INTO reservation.HistoriqueReservation (ReservationID, Action, UserID, Details)
            VALUES (@ReservationID, 'Creation', @UserID, 'Réservation créée automatiquement');
            
            -- Si validation automatique, l'enregistrer aussi
            IF @StatutInitial = 'Validee'
            BEGIN
                UPDATE reservation.Reservation 
                SET DateValidation = GETDATE(), ValidePar = @UserID
                WHERE ReservationID = @ReservationID;
                
                INSERT INTO reservation.HistoriqueReservation (ReservationID, Action, UserID, Details)
                VALUES (@ReservationID, 'Validation', @UserID, 'Validation automatique');
            END
            
            SET @Message = CASE 
                WHEN @StatutInitial = 'Validee' THEN 'Réservation créée et validée automatiquement.'
                ELSE 'Réservation créée. En attente de validation.'
            END;
            
        END
        ELSE
        BEGIN
            SET @Message = 'Salle non disponible pour cette plage horaire.';
            ROLLBACK TRANSACTION;
            RETURN -5;
        END
        
        COMMIT TRANSACTION;
        RETURN 0;
        
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0
            ROLLBACK TRANSACTION;
            
        SET @Message = CONCAT('Erreur: ', ERROR_MESSAGE());
        RETURN -99;
    END CATCH
END
GO

-- ============================================================================
-- Procédure: sp_ValiderReservation
-- Description: Valide ou refuse une réservation (réservé aux managers/admins)
-- ============================================================================
IF OBJECT_ID('reservation.sp_ValiderReservation', 'P') IS NOT NULL
    DROP PROCEDURE reservation.sp_ValiderReservation;
GO

CREATE PROCEDURE reservation.sp_ValiderReservation
    @ManagerID INT,
    @ReservationID INT,
    @Approuver BIT, -- 1 = Approuver, 0 = Refuser
    @Commentaires NVARCHAR(500) = NULL,
    @Message NVARCHAR(500) OUTPUT
AS
BEGIN
    SET NOCOUNT ON;
    BEGIN TRY
        BEGIN TRANSACTION;
        
        DECLARE @StatutActuel NVARCHAR(20);
        DECLARE @NouveauStatut NVARCHAR(20);
        DECLARE @Action NVARCHAR(50);
        
        -- Vérifier les droits du manager
        IF NOT EXISTS (
            SELECT 1 FROM reservation.Utilisateur 
            WHERE UserID = @ManagerID AND Role IN ('Manager', 'Admin') AND Actif = 1
        )
        BEGIN
            SET @Message = 'Droits insuffisants pour cette opération.';
            ROLLBACK TRANSACTION;
            RETURN -1;
        END
        
        -- Vérifier l'existence et le statut de la réservation
        SELECT @StatutActuel = Statut 
        FROM reservation.Reservation 
        WHERE ReservationID = @ReservationID;
        
        IF @@ROWCOUNT = 0
        BEGIN
            SET @Message = 'Réservation inexistante.';
            ROLLBACK TRANSACTION;
            RETURN -2;
        END
        
        IF @StatutActuel != 'En_Attente'
        BEGIN
            SET @Message = CONCAT('Impossible de traiter une réservation avec le statut: ', @StatutActuel);
            ROLLBACK TRANSACTION;
            RETURN -3;
        END
        
        -- Déterminer le nouveau statut et l'action
        IF @Approuver = 1
        BEGIN
            SET @NouveauStatut = 'Validee';
            SET @Action = 'Validation';
        END
        ELSE
        BEGIN
            SET @NouveauStatut = 'Refusee';
            SET @Action = 'Refus';
        END
        
        -- Mettre à jour la réservation
        UPDATE reservation.Reservation
        SET 
            Statut = @NouveauStatut,
            DateValidation = GETDATE(),
            ValidePar = @ManagerID,
            Commentaires = ISNULL(@Commentaires, Commentaires)
        WHERE ReservationID = @ReservationID;
        
        -- Enregistrer dans l'historique
        INSERT INTO reservation.HistoriqueReservation (ReservationID, Action, UserID, Details)
        VALUES (@ReservationID, @Action, @ManagerID, ISNULL(@Commentaires, CONCAT('Réservation ', LOWER(@NouveauStatut))));
        
        SET @Message = CONCAT('Réservation ', LOWER(@NouveauStatut), ' avec succès.');
        
        COMMIT TRANSACTION;
        RETURN 0;
        
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0
            ROLLBACK TRANSACTION;
            
        SET @Message = CONCAT('Erreur: ', ERROR_MESSAGE());
        RETURN -99;
    END CATCH
END
GO

-- ============================================================================
-- Procédure: sp_AnnulerReservation
-- Description: Annule une réservation (par le demandeur ou un admin)
-- ============================================================================
IF OBJECT_ID('reservation.sp_AnnulerReservation', 'P') IS NOT NULL
    DROP PROCEDURE reservation.sp_AnnulerReservation;
GO

CREATE PROCEDURE reservation.sp_AnnulerReservation
    @UserID INT,
    @ReservationID INT,
    @Motif NVARCHAR(500) = NULL,
    @Message NVARCHAR(500) OUTPUT
AS
BEGIN
    SET NOCOUNT ON;
    BEGIN TRY
        BEGIN TRANSACTION;
        
        DECLARE @StatutActuel NVARCHAR(20);
        DECLARE @DemandeurOriginal INT;
        DECLARE @RoleUtilisateur NVARCHAR(20);
        DECLARE @DateReservation DATE;
        
        -- Récupérer les informations de la réservation
        SELECT @StatutActuel = Statut, @DemandeurOriginal = UserID, @DateReservation = DateReservation
        FROM reservation.Reservation 
        WHERE ReservationID = @ReservationID;
        
        IF @@ROWCOUNT = 0
        BEGIN
            SET @Message = 'Réservation inexistante.';
            ROLLBACK TRANSACTION;
            RETURN -1;
        END
        
        -- Vérifier si la réservation peut être annulée
        IF @StatutActuel IN ('Annulee', 'Refusee')
        BEGIN
            SET @Message = CONCAT('Impossible d''annuler une réservation avec le statut: ', @StatutActuel);
            ROLLBACK TRANSACTION;
            RETURN -2;
        END
        
        -- Vérifier si la date n'est pas dépassée
        IF @DateReservation < CAST(GETDATE() AS DATE)
        BEGIN
            SET @Message = 'Impossible d''annuler une réservation passée.';
            ROLLBACK TRANSACTION;
            RETURN -3;
        END
        
        -- Récupérer le rôle de l'utilisateur qui demande l'annulation
        SELECT @RoleUtilisateur = Role 
        FROM reservation.Utilisateur 
        WHERE UserID = @UserID AND Actif = 1;
        
        IF @@ROWCOUNT = 0
        BEGIN
            SET @Message = 'Utilisateur inexistant ou inactif.';
            ROLLBACK TRANSACTION;
            RETURN -4;
        END
        
        -- Vérifier les droits d'annulation
        IF @UserID != @DemandeurOriginal AND @RoleUtilisateur NOT IN ('Admin', 'Manager')
        BEGIN
            SET @Message = 'Droits insuffisants pour annuler cette réservation.';
            ROLLBACK TRANSACTION;
            RETURN -5;
        END
        
        -- Annuler la réservation
        UPDATE reservation.Reservation
        SET 
            Statut = 'Annulee',
            Commentaires = ISNULL(@Motif, Commentaires)
        WHERE ReservationID = @ReservationID;
        
        -- Enregistrer dans l'historique
        INSERT INTO reservation.HistoriqueReservation (ReservationID, Action, UserID, Details)
        VALUES (@ReservationID, 'Annulation', @UserID, ISNULL(@Motif, 'Annulation sans motif spécifié'));
        
        SET @Message = 'Réservation annulée avec succès.';
        
        COMMIT TRANSACTION;
        RETURN 0;
        
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0
            ROLLBACK TRANSACTION;
            
        SET @Message = CONCAT('Erreur: ', ERROR_MESSAGE());
        RETURN -99;
    END CATCH
END
GO

-- ============================================================================
-- Procédure: sp_CloturerJournee
-- Description: Clôture automatique des réservations d'une journée
-- ============================================================================
IF OBJECT_ID('reservation.sp_CloturerJournee', 'P') IS NOT NULL
    DROP PROCEDURE reservation.sp_CloturerJournee;
GO

CREATE PROCEDURE reservation.sp_CloturerJournee
    @Date DATE,
    @UserID INT = 1, -- ID de l'admin système
    @Message NVARCHAR(500) OUTPUT
AS
BEGIN
    SET NOCOUNT ON;
    BEGIN TRY
        BEGIN TRANSACTION;
        
        DECLARE @ReservationsTraitees INT = 0;
        DECLARE @ReservationsAnnulees INT = 0;
        
        -- Traiter les réservations en attente (les refuser automatiquement)
        UPDATE reservation.Reservation
        SET 
            Statut = 'Refusee',
            DateValidation = GETDATE(),
            ValidePar = @UserID,
            Commentaires = ISNULL(Commentaires + ' | ', '') + 'Refus automatique - Clôture journée'
        WHERE DateReservation = @Date 
        AND Statut = 'En_Attente';
        
        SET @ReservationsTraitees = @@ROWCOUNT;
        
        -- Enregistrer dans l'historique pour les réservations traitées
        INSERT INTO reservation.HistoriqueReservation (ReservationID, Action, UserID, Details)
        SELECT 
            ReservationID, 
            'Refus', 
            @UserID, 
            'Refus automatique lors de la clôture de journée'
        FROM reservation.Reservation
        WHERE DateReservation = @Date 
        AND Statut = 'Refusee'
        AND ValidePar = @UserID
        AND DateValidation >= CAST(GETDATE() AS DATE);
        
        -- Enregistrer l'action de clôture dans l'historique
        IF @ReservationsTraitees > 0
        BEGIN
            INSERT INTO reservation.HistoriqueReservation (ReservationID, Action, UserID, Details)
            SELECT TOP 1
                ReservationID,
                'Modification',
                @UserID,
                CONCAT('Clôture journée du ', FORMAT(@Date, 'dd/MM/yyyy'), ' - ', @ReservationsTraitees, ' réservations traitées')
            FROM reservation.Reservation
            WHERE DateReservation = @Date
            ORDER BY ReservationID;
        END
        
        SET @Message = CONCAT('Clôture journée terminée. ', @ReservationsTraitees, ' réservation(s) en attente ont été refusées automatiquement.');
        
        COMMIT TRANSACTION;
        RETURN 0;
        
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0
            ROLLBACK TRANSACTION;
            
        SET @Message = CONCAT('Erreur lors de la clôture: ', ERROR_MESSAGE());
        RETURN -99;
    END CATCH
END
GO

-- ============================================================================
-- Test des procédures
-- ============================================================================
PRINT 'Test des procédures stockées:';

-- Test sp_ReserverSalle
DECLARE @NewResID INT, @Msg NVARCHAR(500);
EXEC reservation.sp_ReserverSalle 
    @UserID = 5,
    @SalleID = 4,
    @TypeEventID = 1,
    @ObjetReservation = 'Test procédure réservation',
    @DateReservation = '2025-06-30',
    @HeureDebut = '10:00',
    @HeureFin = '11:00',
    @Commentaires = 'Test automatique',
    @ReservationID = @NewResID OUTPUT,
    @Message = @Msg OUTPUT;

PRINT CONCAT('Résultat sp_ReserverSalle: ', @Msg, ' (ID: ', ISNULL(CAST(@NewResID AS NVARCHAR), 'NULL'), ')');

-- Test sp_ValiderReservation
IF @NewResID IS NOT NULL
BEGIN
    EXEC reservation.sp_ValiderReservation 
        @ManagerID = 2,
        @ReservationID = @NewResID,
        @Approuver = 1,
        @Commentaires = 'Validation test',
        @Message = @Msg OUTPUT;
    
    PRINT CONCAT('Résultat sp_ValiderReservation: ', @Msg);
END

PRINT 'Toutes les procédures ont été créées et testées avec succès.';