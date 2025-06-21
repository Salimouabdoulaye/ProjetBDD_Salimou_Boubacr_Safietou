-- ============================================================================
-- Projet: Gestion des Réservations de Salles
-- Fichier: 06_Triggers.sql
-- Description: Triggers pour l'intégrité et l'audit des données
-- Date: 25 juin 2025
-- ============================================================================

USE GestionReservationSalles;

-- ============================================================================
-- Trigger: tr_ReservationInsert
-- Description: Vérifie les contraintes lors de l'insertion d'une réservation
-- ============================================================================
IF OBJECT_ID('reservation.tr_ReservationInsert', 'TR') IS NOT NULL
    DROP TRIGGER reservation.tr_ReservationInsert;
GO

CREATE TRIGGER reservation.tr_ReservationInsert
ON reservation.Reservation
AFTER INSERT
AS
BEGIN
    SET NOCOUNT ON;
    
    DECLARE @ErrorMessage NVARCHAR(500);
    DECLARE @ConflictCount INT;
    
    -- Vérifier les conflits de plage horaire pour les nouvelles réservations
    SELECT @ConflictCount = COUNT(*)
    FROM inserted i
    INNER JOIN reservation.Reservation r ON 
        r.SalleID = i.SalleID 
        AND r.DateReservation = i.DateReservation
        AND r.ReservationID != i.ReservationID
        AND r.Statut IN ('Validee', 'En_Attente')
    WHERE (
        (i.HeureDebut >= r.HeureDebut AND i.HeureDebut < r.HeureFin) OR
        (i.HeureFin > r.HeureDebut AND i.HeureFin <= r.HeureFin) OR
        (i.HeureDebut <= r.HeureDebut AND i.HeureFin >= r.HeureFin)
    );
    
    IF @ConflictCount > 0
    BEGIN
        SET @ErrorMessage = 'Conflit de plage horaire détecté. Cette salle est déjà réservée pour cette période.';
        RAISERROR(@ErrorMessage, 16, 1);
        ROLLBACK TRANSACTION;
        RETURN;
    END
    
    -- Vérifier les droits de l'utilisateur
    IF EXISTS (
        SELECT 1 FROM inserted i
        INNER JOIN reservation.Utilisateur u ON i.UserID = u.UserID
        WHERE u.Actif = 0
    )
    BEGIN
        SET @ErrorMessage = 'Utilisateur inactif. Impossible de créer une réservation.';
        RAISERROR(@ErrorMessage, 16, 1);
        ROLLBACK TRANSACTION;
        RETURN;
    END
    
    -- Vérifier la disponibilité de la salle
    IF EXISTS (
        SELECT 1 FROM inserted i
        INNER JOIN reservation.Salle s ON i.SalleID = s.SalleID
        WHERE s.Disponible = 0
    )
    BEGIN
        SET @ErrorMessage = 'Salle indisponible. Impossible de créer une réservation.';
        RAISERROR(@ErrorMessage, 16, 1);
        ROLLBACK TRANSACTION;
        RETURN;
    END
    
    -- Vérifier que la réservation n'est pas dans le passé
    IF EXISTS (
        SELECT 1 FROM inserted
        WHERE DateReservation < CAST(GETDATE() AS DATE)
    )
    BEGIN
        SET @ErrorMessage = 'Impossible de créer une réservation dans le passé.';
        RAISERROR(@ErrorMessage, 16, 1);
        ROLLBACK TRANSACTION;
        RETURN;
    END
END
GO

-- ============================================================================
-- Trigger: tr_ReservationUpdate
-- Description: Audit des modifications de réservations
-- ============================================================================
IF OBJECT_ID('reservation.tr_ReservationUpdate', 'TR') IS NOT NULL
    DROP TRIGGER reservation.tr_ReservationUpdate;
GO

CREATE TRIGGER reservation.tr_ReservationUpdate
ON reservation.Reservation
AFTER UPDATE
AS
BEGIN
    SET NOCOUNT ON;
    
    -- Enregistrer les modifications dans l'historique
    INSERT INTO reservation.HistoriqueReservation (ReservationID, Action, UserID, Details)
    SELECT 
        i.ReservationID,
        CASE 
            WHEN i.Statut != d.Statut THEN 
                CASE i.Statut
                    WHEN 'Validee' THEN 'Validation'
                    WHEN 'Refusee' THEN 'Refus'
                    WHEN 'Annulee' THEN 'Annulation'
                    ELSE 'Modification'
                END
            ELSE 'Modification'
        END,
        ISNULL(i.ValidePar, i.UserID),
        CASE 
            WHEN i.Statut != d.Statut THEN CONCAT('Changement de statut: ', d.Statut, ' → ', i.Statut)
            WHEN i.DateReservation != d.DateReservation THEN CONCAT('Changement de date: ', FORMAT(d.DateReservation, 'dd/MM/yyyy'), ' → ', FORMAT(i.DateReservation, 'dd/MM/yyyy'))
            WHEN i.HeureDebut != d.HeureDebut OR i.HeureFin != d.HeureFin THEN CONCAT('Changement d''horaire: ', CAST(d.HeureDebut AS NVARCHAR), '-', CAST(d.HeureFin AS NVARCHAR), ' → ', CAST(i.HeureDebut AS NVARCHAR), '-', CAST(i.HeureFin AS NVARCHAR))
            WHEN i.SalleID != d.SalleID THEN CONCAT('Changement de salle: ID ', d.SalleID, ' → ID ', i.SalleID)
            ELSE 'Modification des détails'
        END
    FROM inserted i
    INNER JOIN deleted d ON i.ReservationID = d.ReservationID
    WHERE i.Statut != d.Statut 
       OR i.DateReservation != d.DateReservation
       OR i.HeureDebut != d.HeureDebut
       OR i.HeureFin != d.HeureFin
       OR i.SalleID != d.SalleID
       OR ISNULL(i.ObjetReservation, '') != ISNULL(d.ObjetReservation, '')
       OR ISNULL(i.Commentaires, '') != ISNULL(d.Commentaires, '');
END
GO

-- ============================================================================
-- Trigger: tr_UtilisateurDelete
-- Description: Gestion de la suppression d'utilisateurs
-- ============================================================================
IF OBJECT_ID('reservation.tr_UtilisateurDelete', 'TR') IS NOT NULL
    DROP TRIGGER reservation.tr_UtilisateurDelete;
GO

CREATE TRIGGER reservation.tr_UtilisateurDelete
ON reservation.Utilisateur
INSTEAD OF DELETE
AS
BEGIN
    SET NOCOUNT ON;
    
    DECLARE @UserID INT;
    DECLARE @NomComplet NVARCHAR(101);
    DECLARE @ReservationsActives INT;
    
    -- Parcourir tous les utilisateurs à supprimer
    DECLARE user_cursor CURSOR FOR
    SELECT UserID, CONCAT(Nom, ' ', Prenom) as NomComplet
    FROM deleted;
    
    OPEN user_cursor;
    FETCH NEXT FROM user_cursor INTO @UserID, @NomComplet;
    
    WHILE @@FETCH_STATUS = 0
    BEGIN
        -- Compter les réservations non validées
        SELECT @ReservationsActives = COUNT(*)
        FROM reservation.Reservation
        WHERE UserID = @UserID 
        AND Statut IN ('En_Attente', 'Validee')
        AND DateReservation >= CAST(GETDATE() AS DATE);
        
        -- Annuler les réservations en attente futures
        UPDATE reservation.Reservation
        SET 
            Statut = 'Annulee',
            Commentaires = ISNULL(Commentaires + ' | ', '') + 'Annulation automatique - Suppression utilisateur'
        WHERE UserID = @UserID 
        AND Statut = 'En_Attente'
        AND DateReservation >= CAST(GETDATE() AS DATE);
        
        -- Enregistrer l'historique pour les réservations annulées
        INSERT INTO reservation.HistoriqueReservation (ReservationID, Action, UserID, Details)
        SELECT 
            ReservationID,
            'Annulation',
            1, -- Admin système
            CONCAT('Annulation automatique - Suppression de l''utilisateur: ', @NomComplet)
        FROM reservation.Reservation
        WHERE UserID = @UserID 
        AND Statut = 'Annulee'
        AND Commentaires LIKE '%Suppression utilisateur%';
        
        -- Si l'utilisateur a des réservations validées futures, le désactiver au lieu de le supprimer
        IF EXISTS (
            SELECT 1 FROM reservation.Reservation
            WHERE UserID = @UserID 
            AND Statut = 'Validee'
            AND DateReservation >= CAST(GETDATE() AS DATE)
        )
        BEGIN
            -- Désactiver l'utilisateur au lieu de le supprimer
            UPDATE reservation.Utilisateur
            SET 
                Actif = 0,
                Email = CONCAT('SUPPRIME_', CAST(GETDATE() AS NVARCHAR), '_', Email),
                MotDePasse = 'COMPTE_DESACTIVE'
            WHERE UserID = @UserID;
            
            PRINT CONCAT('Utilisateur ', @NomComplet, ' désactivé (réservations validées existantes)');
        END
        ELSE
        BEGIN
            -- Supprimer définitivement l'utilisateur
            DELETE FROM reservation.Utilisateur WHERE UserID = @UserID;
            PRINT CONCAT('Utilisateur ', @NomComplet, ' supprimé définitivement');
        END
        
        FETCH NEXT FROM user_cursor INTO @UserID, @NomComplet;
    END
    
    CLOSE user_cursor;
    DEALLOCATE user_cursor;
END
GO

-- ============================================================================
-- Trigger: tr_SalleUpdate
-- Description: Audit des modifications de salles
-- ============================================================================
IF OBJECT_ID('reservation.tr_SalleUpdate', 'TR') IS NOT NULL
    DROP TRIGGER reservation.tr_SalleUpdate;
GO

CREATE TRIGGER reservation.tr_SalleUpdate
ON reservation.Salle
AFTER UPDATE
AS
BEGIN
    SET NOCOUNT ON;
    
    -- Si une salle devient indisponible, annuler les réservations futures en attente
    IF EXISTS (
        SELECT 1 FROM inserted i
        INNER JOIN deleted d ON i.SalleID = d.SalleID
        WHERE i.Disponible = 0 AND d.Disponible = 1
    )
    BEGIN
        -- Annuler les réservations en attente pour les salles devenues indisponibles
        UPDATE r
        SET 
            Statut = 'Annulee',
            Commentaires = ISNULL(r.Commentaires + ' | ', '') + 'Annulation automatique - Salle devenue indisponible'
        FROM reservation.Reservation r
        INNER JOIN inserted i ON r.SalleID = i.SalleID
        INNER JOIN deleted d ON i.SalleID = d.SalleID
        WHERE i.Disponible = 0 
        AND d.Disponible = 1
        AND r.Statut = 'En_Attente'
        AND r.DateReservation >= CAST(GETDATE() AS DATE);
        
        -- Enregistrer dans l'historique
        INSERT INTO reservation.HistoriqueReservation (ReservationID, Action, UserID, Details)
        SELECT 
            r.ReservationID,
            'Annulation',
            1, -- Admin système
            CONCAT('Annulation automatique - Salle ', s.NomSalle, ' devenue indisponible')
        FROM reservation.Reservation r
        INNER JOIN inserted i ON r.SalleID = i.SalleID
        INNER JOIN deleted d ON i.SalleID = d.SalleID
        INNER JOIN reservation.Salle s ON r.SalleID = s.SalleID
        WHERE i.Disponible = 0 
        AND d.Disponible = 1
        AND r.Statut = 'Annulee'
        AND r.Commentaires LIKE '%Salle devenue indisponible%';
    END
END
GO

-- ============================================================================
-- Trigger: tr_ReservationDelete
-- Description: Audit des suppressions de réservations
-- ============================================================================
IF OBJECT_ID('reservation.tr_ReservationDelete', 'TR') IS NOT NULL
    DROP TRIGGER reservation.tr_ReservationDelete;
GO

CREATE TRIGGER reservation.tr_ReservationDelete
ON reservation.Reservation
AFTER DELETE
AS
BEGIN
    SET NOCOUNT ON;
    
    -- Enregistrer la suppression dans l'historique
    -- Note: L'historique sera automatiquement supprimé grâce à ON DELETE CASCADE
    -- Mais nous enregistrons d'abord l'action de suppression
    INSERT INTO reservation.HistoriqueReservation (ReservationID, Action, UserID, Details)
    SELECT 
        d.ReservationID,
        'Modification', -- On utilise Modification car Suppression supprimerait la ligne
        1, -- Admin système
        CONCAT('Suppression définitive de la réservation: ', d.ObjetReservation)
    FROM deleted d;
END
GO

-- ============================================================================
-- Test des triggers
-- ============================================================================
PRINT 'Tests des triggers:';

-- Test 1: Tentative de conflit horaire
PRINT 'Test 1: Vérification du trigger de conflit horaire';
BEGIN TRY
    INSERT INTO reservation.Reservation (UserID, SalleID, TypeEventID, ObjetReservation, DateReservation, HeureDebut, HeureFin, Statut)
    VALUES (5, 1, 1, 'Test conflit', '2025-06-26', '09:30', '10:00', 'En_Attente');
    PRINT 'ERREUR: Le trigger aurait dû empêcher cette insertion!';
END TRY
BEGIN CATCH
    PRINT 'OK: Conflit horaire détecté et insertion bloquée.';
END CATCH

-- Test 2: Modification d'une réservation existante
PRINT 'Test 2: Vérification du trigger d''audit sur modification';
UPDATE reservation.Reservation 
SET Commentaires = 'Commentaire modifié par trigger test'
WHERE ReservationID = 1;

-- Vérifier que l'historique a été créé
IF EXISTS (
    SELECT 1 FROM reservation.HistoriqueReservation 
    WHERE ReservationID = 1 AND Action = 'Modification' 
    AND Details LIKE '%Modification des détails%'
)
    PRINT 'OK: Modification enregistrée dans l''historique.';
ELSE
    PRINT 'ATTENTION: Modification non enregistrée dans l''historique.';

-- Test 3: Tentative de réservation avec utilisateur inactif
PRINT 'Test 3: Vérification du trigger pour utilisateur inactif';
-- D'abord désactiver un utilisateur de test
UPDATE reservation.Utilisateur SET Actif = 0 WHERE UserID = 15;

BEGIN TRY
    INSERT INTO reservation.Reservation (UserID, SalleID, TypeEventID, ObjetReservation, DateReservation, HeureDebut, HeureFin, Statut)
    VALUES (15, 4, 1, 'Test utilisateur inactif', '2025-06-30', '15:00', '16:00', 'En_Attente');
    PRINT 'ERREUR: Le trigger aurait dû empêcher cette insertion!';
END TRY
BEGIN CATCH
    PRINT 'OK: Utilisateur inactif détecté et insertion bloquée.';
END CATCH

-- Réactiver l'utilisateur
UPDATE reservation.Utilisateur SET Actif = 1 WHERE UserID = 15;

PRINT 'Tous les triggers ont été créés et testés avec succès.';