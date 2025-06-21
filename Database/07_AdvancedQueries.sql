-- ============================================================================
-- Projet: Gestion des Réservations de Salles
-- Fichier: 07_AdvancedQueries.sql
-- Description: Requêtes avancées avec fonctions de fenêtrage, PIVOT, etc.
-- Date: 25 juin 2025
-- ============================================================================

USE GestionReservationSalles;
GO

-- ============================================================================
-- 1. RAPPORT JOURNALIER DES RÉSERVATIONS VALIDÉES
-- ============================================================================
PRINT '1. RAPPORT JOURNALIER DES RÉSERVATIONS VALIDÉES';
PRINT '================================================';
GO

-- Création de la vue (doit être dans son propre batch)
CREATE OR ALTER VIEW reservation.vw_RapportJournalier AS
SELECT 
    r.DateReservation,
    COUNT(*) as TotalReservations,
    COUNT(CASE WHEN r.Statut = 'Validee' THEN 1 END) as ReservationsValidees,
    COUNT(CASE WHEN r.Statut = 'En_Attente' THEN 1 END) as ReservationsEnAttente,
    COUNT(CASE WHEN r.Statut = 'Refusee' THEN 1 END) as ReservationsRefusees,
    COUNT(CASE WHEN r.Statut = 'Annulee' THEN 1 END) as ReservationsAnnulees,
    SUM(CASE WHEN r.Statut = 'Validee' THEN DATEDIFF(MINUTE, r.HeureDebut, r.HeureFin) ELSE 0 END) as MinutesOccupees,
    ROUND(
        CAST(COUNT(CASE WHEN r.Statut = 'Validee' THEN 1 END) AS FLOAT) / 
        NULLIF(COUNT(*), 0) * 100, 2
    ) as TauxValidation,
    COUNT(DISTINCT r.SalleID) as SallesUtilisees,
    COUNT(DISTINCT r.UserID) as UtilisateursActifs
FROM reservation.Reservation r
WHERE r.DateReservation >= DATEADD(DAY, -30, GETDATE()) -- 30 derniers jours
GROUP BY r.DateReservation;
GO

-- Exemple d'utilisation du rapport journalier
SELECT 
    FORMAT(DateReservation, 'dd/MM/yyyy', 'fr-FR') as Date,
    TotalReservations as Total,
    ReservationsValidees as Validées,
    ReservationsEnAttente as [En Attente],
    ReservationsRefusees as Refusées,
    ReservationsAnnulees as Annulées,
    CONCAT(TauxValidation, '%') as [Taux Validation],
    CONCAT(FLOOR(MinutesOccupees / 60), 'h', FORMAT(MinutesOccupees % 60, '00'), 'm') as [Temps Occupé],
    SallesUtilisees as [Salles Utilisées]
FROM reservation.vw_RapportJournalier
ORDER BY DateReservation DESC;

-- ============================================================================
-- 2. CLASSEMENT DES SALLES LES PLUS UTILISÉES (RANK)
-- ============================================================================
PRINT CHAR(13) + CHAR(10) + '2. CLASSEMENT DES SALLES LES PLUS UTILISÉES';
PRINT '===========================================';

WITH StatistiquesUtilisation AS (
    SELECT 
        s.SalleID,
        s.NomSalle,
        s.Capacite,
        s.Localisation,
        COUNT(r.ReservationID) as NombreReservations,
        COUNT(CASE WHEN r.Statut = 'Validee' THEN 1 END) as ReservationsValidees,
        SUM(CASE WHEN r.Statut = 'Validee' THEN DATEDIFF(MINUTE, r.HeureDebut, r.HeureFin) ELSE 0 END) as MinutesOccupees,
        ROUND(AVG(CAST(s.TarifHoraire AS FLOAT)), 2) as TarifMoyen,
        COUNT(DISTINCT r.UserID) as UtilisateursUniques
    FROM reservation.Salle s
    LEFT JOIN reservation.Reservation r ON s.SalleID = r.SalleID
        AND r.DateReservation >= DATEADD(MONTH, -3, GETDATE()) -- 3 derniers mois
    GROUP BY s.SalleID, s.NomSalle, s.Capacite, s.Localisation
),
ClassementSalles AS (
    SELECT 
        *,
        RANK() OVER (ORDER BY ReservationsValidees DESC, MinutesOccupees DESC) as RangUtilisation,
        DENSE_RANK() OVER (ORDER BY UtilisateursUniques DESC) as RangPopularite,
        ROW_NUMBER() OVER (ORDER BY ReservationsValidees DESC, MinutesOccupees DESC, NomSalle) as NumeroLigne,
        ROUND(
            (MinutesOccupees * 100.0) / NULLIF(SUM(MinutesOccupees) OVER(), 0), 2
        ) as PourcentageUtilisation
    FROM StatistiquesUtilisation
)
SELECT 
    RangUtilisation as [Rang],
    NomSalle as [Nom de la Salle],
    Capacite as [Capacité],
    Localisation as [Localisation],
    ReservationsValidees as [Réservations Validées],
    CONCAT(FLOOR(MinutesOccupees / 60), 'h', FORMAT(MinutesOccupees % 60, '00'), 'm') as [Temps d'Occupation],
    CONCAT(PourcentageUtilisation, '%') as [% Utilisation],
    UtilisateursUniques as [Utilisateurs Uniques],
    CONCAT(FORMAT(TarifMoyen, 'N0', 'fr-FR'), ' FCFA') as [Tarif Horaire],
    CASE 
        WHEN RangUtilisation <= 3 THEN '🥇 Top 3'
        WHEN RangUtilisation <= 5 THEN '🥈 Top 5'
        WHEN ReservationsValidees = 0 THEN '⚠️ Jamais utilisée'
        ELSE '✅ Utilisée'
    END as [Statut]
FROM ClassementSalles
ORDER BY RangUtilisation, NomSalle;

-- ============================================================================
-- 3. RÉPARTITION DES ÉVÉNEMENTS PAR JOUR/SEMAINE (PIVOT)
-- ============================================================================
PRINT CHAR(13) + CHAR(10) + '3. RÉPARTITION DES ÉVÉNEMENTS PAR JOUR/SEMAINE';
PRINT '==============================================';

-- Répartition par jour de la semaine
WITH ReservationsParJour AS (
    SELECT 
        te.NomType,
        DATENAME(WEEKDAY, r.DateReservation) as JourSemaine,
        DATEPART(WEEKDAY, r.DateReservation) as NumeroJour,
        COUNT(*) as NombreReservations
    FROM reservation.Reservation r
    INNER JOIN reservation.TypeEvenement te ON r.TypeEventID = te.TypeEventID
    WHERE r.Statut = 'Validee'
    AND r.DateReservation >= DATEADD(MONTH, -2, GETDATE()) -- 2 derniers mois
    GROUP BY te.NomType, DATENAME(WEEKDAY, r.DateReservation), DATEPART(WEEKDAY, r.DateReservation)
)
SELECT 
    NomType as [Type d'Événement],
    ISNULL([Lundi], 0) as Lundi,
    ISNULL([Mardi], 0) as Mardi,
    ISNULL([Mercredi], 0) as Mercredi,
    ISNULL([Jeudi], 0) as Jeudi,
    ISNULL([Vendredi], 0) as Vendredi,
    ISNULL([Samedi], 0) as Samedi,
    ISNULL([Dimanche], 0) as Dimanche,
    (ISNULL([Lundi], 0) + ISNULL([Mardi], 0) + ISNULL([Mercredi], 0) + 
     ISNULL([Jeudi], 0) + ISNULL([Vendredi], 0) + ISNULL([Samedi], 0) + 
     ISNULL([Dimanche], 0)) as Total
FROM (
    SELECT NomType, JourSemaine, NombreReservations
    FROM ReservationsParJour
) AS SourceTable
PIVOT (
    SUM(NombreReservations)
    FOR JourSemaine IN ([Lundi], [Mardi], [Mercredi], [Jeudi], [Vendredi], [Samedi], [Dimanche])
) AS PivotTable
ORDER BY Total DESC;

-- Répartition par tranche horaire
PRINT CHAR(13) + CHAR(10) + 'Répartition par tranche horaire:';

WITH TranchesHoraires AS (
    SELECT 
        r.ReservationID,
        te.NomType,
        CASE 
            WHEN CAST(r.HeureDebut AS TIME) BETWEEN '06:00' AND '08:59' THEN '06h-09h (Matinée tôt)'
            WHEN CAST(r.HeureDebut AS TIME) BETWEEN '09:00' AND '11:59' THEN '09h-12h (Matinée)'
            WHEN CAST(r.HeureDebut AS TIME) BETWEEN '12:00' AND '13:59' THEN '12h-14h (Déjeuner)'
            WHEN CAST(r.HeureDebut AS TIME) BETWEEN '14:00' AND '16:59' THEN '14h-17h (Après-midi)'
            WHEN CAST(r.HeureDebut AS TIME) BETWEEN '17:00' AND '19:59' THEN '17h-20h (Soirée)'
            ELSE '20h+ (Tard)'
        END as TrancheHoraire
    FROM reservation.Reservation r
    INNER JOIN reservation.TypeEvenement te ON r.TypeEventID = te.TypeEventID
    WHERE r.Statut = 'Validee'
    AND r.DateReservation >= DATEADD(MONTH, -2, GETDATE())
)
SELECT 
    NomType as [Type d'Événement],
    ISNULL([06h-09h (Matinée tôt)], 0) as [06h-09h],
    ISNULL([09h-12h (Matinée)], 0) as [09h-12h],
    ISNULL([12h-14h (Déjeuner)], 0) as [12h-14h],
    ISNULL([14h-17h (Après-midi)], 0) as [14h-17h],
    ISNULL([17h-20h (Soirée)], 0) as [17h-20h],
    ISNULL([20h+ (Tard)], 0) as [20h+],
    (ISNULL([06h-09h (Matinée tôt)], 0) + ISNULL([09h-12h (Matinée)], 0) + 
     ISNULL([12h-14h (Déjeuner)], 0) + ISNULL([14h-17h (Après-midi)], 0) + 
     ISNULL([17h-20h (Soirée)], 0) + ISNULL([20h+ (Tard)], 0)) as [Total]
FROM (
    SELECT NomType, TrancheHoraire
    FROM TranchesHoraires
) AS SourceTable
PIVOT (
    COUNT(TrancheHoraire)
    FOR TrancheHoraire IN ([06h-09h (Matinée tôt)], [09h-12h (Matinée)], [12h-14h (Déjeuner)], 
                          [14h-17h (Après-midi)], [17h-20h (Soirée)], [20h+ (Tard)])
) AS PivotTable
ORDER BY [Total] DESC;

-- ============================================================================
-- 4. ANALYSE DES CRÉNEAUX LES PLUS DEMANDÉS (FENÊTRAGE)
-- ============================================================================
PRINT CHAR(13) + CHAR(10) + '4. ANALYSE DES CRÉNEAUX LES PLUS DEMANDÉS';
PRINT '=========================================';

WITH AnalyseCreneaux AS (
    SELECT 
        CAST(r.HeureDebut AS TIME) as HeureDebut,
        CAST(r.HeureFin AS TIME) as HeureFin,
        DATEDIFF(MINUTE, r.HeureDebut, r.HeureFin) as DureeMinutes,
        COUNT(*) as NombreReservations,
        COUNT(*) OVER() as TotalReservations,
        s.NomSalle,
        te.NomType,
        DATENAME(WEEKDAY, r.DateReservation) as JourSemaine
    FROM reservation.Reservation r
    INNER JOIN reservation.Salle s ON r.SalleID = s.SalleID
    INNER JOIN reservation.TypeEvenement te ON r.TypeEventID = te.TypeEventID
    WHERE r.Statut = 'Validee'
    AND r.DateReservation >= DATEADD(MONTH, -3, GETDATE())
    GROUP BY CAST(r.HeureDebut AS TIME), CAST(r.HeureFin AS TIME), 
             DATEDIFF(MINUTE, r.HeureDebut, r.HeureFin), s.NomSalle, 
             te.NomType, DATENAME(WEEKDAY, r.DateReservation)
),
StatistiquesCreneaux AS (
    SELECT 
        HeureDebut,
        HeureFin,
        SUM(NombreReservations) as TotalReservations,
        AVG(CAST(DureeMinutes AS FLOAT)) as DureeMoyenne,
        COUNT(DISTINCT NomSalle) as SallesDifferentes,
        COUNT(DISTINCT NomType) as TypesEvenements,
        ROUND(
            (SUM(NombreReservations) * 100.0) / 
            (SELECT SUM(NombreReservations) FROM AnalyseCreneaux), 2
        ) as PourcentageTotal,
        RANK() OVER (ORDER BY SUM(NombreReservations) DESC) as RangPopularite
    FROM AnalyseCreneaux
    GROUP BY HeureDebut, HeureFin
)
SELECT TOP 15
    CONCAT(FORMAT(HeureDebut, 'HH\:mm'), ' - ', FORMAT(HeureFin, 'HH\:mm')) as [Créneau Horaire],
    TotalReservations as [Nb Réservations],
    RangPopularite as [Rang],
    CONCAT(PourcentageTotal, '%') as [% du Total],
    CONCAT(FLOOR(DureeMoyenne / 60), 'h', FORMAT(CAST(DureeMoyenne AS INT) % 60, '00'), 'm') as [Durée Moyenne],
    SallesDifferentes as [Salles Utilisées],
    TypesEvenements as [Types d'Événements],
    CASE 
        WHEN RangPopularite = 1 THEN '🏆 Le plus demandé'
        WHEN RangPopularite <= 3 THEN '🥇 Très demandé'
        WHEN RangPopularite <= 10 THEN '📈 Populaire'
        ELSE '📊 Normal'
    END as [Popularité]
FROM StatistiquesCreneaux
ORDER BY RangPopularite;

-- ============================================================================
-- 5. ANALYSE DES TENDANCES UTILISATEURS
-- ============================================================================
PRINT CHAR(13) + CHAR(10) + '5. ANALYSE DES TENDANCES UTILISATEURS';
PRINT '=====================================';

WITH TendancesUtilisateurs AS (
    SELECT 
        u.UserID,
        CONCAT(u.Prenom, ' ', u.Nom) as NomComplet,
        u.Role,
        COUNT(r.ReservationID) as TotalReservations,
        COUNT(CASE WHEN r.Statut = 'Validee' THEN 1 END) as ReservationsValidees,
        COUNT(CASE WHEN r.Statut = 'Refusee' THEN 1 END) as ReservationsRefusees,
        COUNT(CASE WHEN r.Statut = 'Annulee' THEN 1 END) as ReservationsAnnulees,
        SUM(CASE WHEN r.Statut = 'Validee' THEN DATEDIFF(MINUTE, r.HeureDebut, r.HeureFin) ELSE 0 END) as MinutesTotales,
        COUNT(DISTINCT r.SalleID) as SallesUtilisees,
        COUNT(DISTINCT r.TypeEventID) as TypesEvenements,
        AVG(CASE WHEN r.Statut = 'Validee' THEN CAST(DATEDIFF(MINUTE, r.HeureDebut, r.HeureFin) AS FLOAT) END) as DureeMoyenne,
        MIN(r.DateReservation) as PremiereReservation,
        MAX(r.DateReservation) as DerniereReservation,
        -- Calcul du taux de validation
        ROUND(
            CAST(COUNT(CASE WHEN r.Statut = 'Validee' THEN 1 END) AS FLOAT) /
            NULLIF(COUNT(r.ReservationID), 0) * 100, 2
        ) as TauxValidation,
        -- Fonctions de fenêtrage pour le classement
        RANK() OVER (ORDER BY COUNT(CASE WHEN r.Statut = 'Validee' THEN 1 END) DESC) as RangActivite,
        PERCENT_RANK() OVER (ORDER BY COUNT(CASE WHEN r.Statut = 'Validee' THEN 1 END)) as PercentileActivite
    FROM reservation.Utilisateur u
    LEFT JOIN reservation.Reservation r ON u.UserID = r.UserID
        AND r.DateReservation >= DATEADD(MONTH, -6, GETDATE()) -- 6 derniers mois
    WHERE u.Actif = 1
    GROUP BY u.UserID, u.Prenom, u.Nom, u.Role
)
SELECT 
    RangActivite as [Rang],
    NomComplet as [Utilisateur],
    Role as [Rôle],
    ReservationsValidees as [Validées],
    ReservationsRefusees as [Refusées], 
    ReservationsAnnulees as [Annulées],
    CONCAT(TauxValidation, '%') as [Taux Validation],
    CONCAT(FLOOR(MinutesTotales / 60), 'h', FORMAT(MinutesTotales % 60, '00'), 'm') as [Temps Total],
    SallesUtilisees as [Salles],
    TypesEvenements as [Types],
    CASE 
        WHEN FLOOR(DureeMoyenne / 60) > 0 
        THEN CONCAT(FLOOR(DureeMoyenne / 60), 'h', FORMAT(CAST(DureeMoyenne AS INT) % 60, '00'), 'm')
        ELSE CONCAT(FORMAT(CAST(DureeMoyenne AS INT), '00'), 'm')
    END as [Durée Moy.],
    CASE 
        WHEN PercentileActivite >= 0.9 THEN '🏆 Top 10%'
        WHEN PercentileActivite >= 0.75 THEN '🥇 Top 25%'
        WHEN PercentileActivite >= 0.5 THEN '📈 Actif'
        WHEN TotalReservations = 0 THEN '😴 Inactif'
        ELSE '📊 Occasionnel'
    END as [Profil]
FROM TendancesUtilisateurs
WHERE TotalReservations > 0 OR Role IN ('Manager', 'Admin')
ORDER BY RangActivite;

-- ============================================================================
-- 6. TABLEAU DE BORD EXÉCUTIF
-- ============================================================================
PRINT CHAR(13) + CHAR(10) + '6. TABLEAU DE BORD EXÉCUTIF';
PRINT '===========================';

DECLARE @DateDebut DATE = DATEADD(MONTH, -1, GETDATE());
DECLARE @DateFin DATE = GETDATE();

-- Métriques générales en plusieurs requêtes pour éviter les conflits
SELECT 
    'MÉTRIQUES GÉNÉRALES' as Catégorie,
    '📊 Nombre total de réservations' as Indicateur,
    CAST(COUNT(*) AS NVARCHAR) as Valeur,
    CONCAT('(', COUNT(CASE WHEN DateReservation >= @DateDebut THEN 1 END), ' ce mois)') as Détail
FROM reservation.Reservation;

SELECT 
    'MÉTRIQUES GÉNÉRALES' as Catégorie,
    '✅ Taux de validation global' as Indicateur,
    CONCAT(
        ROUND(
            CAST(COUNT(CASE WHEN Statut = 'Validee' THEN 1 END) AS FLOAT) /
            NULLIF(COUNT(*), 0) * 100, 1
        ), '%'
    ) as Valeur,
    CONCAT('(', COUNT(CASE WHEN Statut = 'Validee' THEN 1 END), '/', COUNT(*), ')') as Détail
FROM reservation.Reservation;

SELECT 
    'UTILISATION' as Catégorie,
    '⏱️ Heures d''occupation totales' as Indicateur,
    CONCAT(
        FLOOR(SUM(DATEDIFF(MINUTE, HeureDebut, HeureFin)) / 60), 'h',
        FORMAT(SUM(DATEDIFF(MINUTE, HeureDebut, HeureFin)) % 60, '00'), 'm'
    ) as Valeur,
    'Réservations validées uniquement' as Détail
FROM reservation.Reservation
WHERE Statut = 'Validee';

SELECT 
    'UTILISATION' as Catégorie,
    '👥 Utilisateurs actifs' as Indicateur,
    CAST(COUNT(DISTINCT r.UserID) AS NVARCHAR) as Valeur,
    CONCAT('Sur ', (SELECT COUNT(*) FROM reservation.Utilisateur WHERE Actif = 1), ' utilisateurs total') as Détail
FROM reservation.Reservation r
WHERE r.DateReservation >= @DateDebut;

SELECT 
    'FINANCES' as Catégorie,
    '💰 Revenus estimés' as Indicateur,
    CONCAT(
        FORMAT(
            SUM(s.TarifHoraire * CAST(DATEDIFF(MINUTE, r.HeureDebut, r.HeureFin) AS FLOAT) / 60), 
            'N0', 'fr-FR'
        ), ' FCFA'
    ) as Valeur,
    'Basé sur les tarifs des salles' as Détail
FROM reservation.Reservation r
INNER JOIN reservation.Salle s ON r.SalleID = s.SalleID
WHERE r.Statut = 'Validee';

-- ============================================================================
-- 7. REQUÊTES D'ANALYSE PRÉDICTIVE
-- ============================================================================
PRINT CHAR(13) + CHAR(10) + '7. ANALYSE PRÉDICTIVE ET RECOMMANDATIONS';
PRINT '========================================';

-- Prédiction des pics de charge
WITH PicsCharge AS (
    SELECT 
        DATENAME(WEEKDAY, DateReservation) as JourSemaine,
        DATEPART(HOUR, HeureDebut) as HeureDebut,
        COUNT(*) as NombreReservations,
        AVG(COUNT(*)) OVER (PARTITION BY DATENAME(WEEKDAY, DateReservation)) as MoyenneJour,
        STDEV(COUNT(*)) OVER (PARTITION BY DATENAME(WEEKDAY, DateReservation)) as EcartTypeJour
    FROM reservation.Reservation
    WHERE Statut = 'Validee'
    AND DateReservation >= DATEADD(MONTH, -3, GETDATE())
    GROUP BY DATENAME(WEEKDAY, DateReservation), DATEPART(HOUR, HeureDebut)
),
Predictions AS (
    SELECT 
        JourSemaine,
        HeureDebut,
        NombreReservations,
        MoyenneJour,
        CASE 
            WHEN NombreReservations > MoyenneJour + ISNULL(EcartTypeJour, 0) THEN 'Pic élevé'
            WHEN NombreReservations > MoyenneJour THEN 'Pic modéré'
            ELSE 'Normal'
        END as TypePic,
        RANK() OVER (ORDER BY NombreReservations DESC) as RangCharge
    FROM PicsCharge
    WHERE NombreReservations > 0
)
SELECT TOP 10
    JourSemaine as [Jour],
    CONCAT(HeureDebut, 'h') as [Heure],
    NombreReservations as [Réservations],
    TypePic as [Type de Pic],
    RangCharge as [Rang],
    CASE 
        WHEN TypePic = 'Pic élevé' THEN '🔴 Préparer salles supplémentaires'
        WHEN TypePic = 'Pic modéré' THEN '🟡 Surveiller la demande'
        ELSE '🟢 Capacité normale'
    END as [Recommandation]
FROM Predictions
ORDER BY RangCharge;

-- Recommandations d'optimisation
PRINT CHAR(13) + CHAR(10) + 'Recommandations d''optimisation:';

WITH AnalyseOptimisation AS (
    SELECT 
        s.SalleID,
        s.NomSalle,
        s.Capacite,
        COUNT(r.ReservationID) as Utilisation,
        AVG(CAST(te.DureeMinimale AS FLOAT)) as DureeMoyenneRequise,
        COUNT(CASE WHEN r.Statut = 'Refusee' THEN 1 END) as RefusFrequents,
        CASE 
            WHEN COUNT(r.ReservationID) = 0 THEN 'Sous-utilisée'
            WHEN COUNT(CASE WHEN r.Statut = 'Refusee' THEN 1 END) > COUNT(r.ReservationID) * 0.3 THEN 'Surchargée'
            ELSE 'Optimale'
        END as StatutOptimisation
    FROM reservation.Salle s
    LEFT JOIN reservation.Reservation r ON s.SalleID = r.SalleID
        AND r.DateReservation >= DATEADD(MONTH, -2, GETDATE())
    LEFT JOIN reservation.TypeEvenement te ON r.TypeEventID = te.TypeEventID
    GROUP BY s.SalleID, s.NomSalle, s.Capacite
)
SELECT 
    NomSalle as [Salle],
    Capacite as [Capacité],
    Utilisation as [Utilisation],
    StatutOptimisation as [Statut],
    CASE StatutOptimisation
        WHEN 'Sous-utilisée' THEN '💡 Promouvoir cette salle ou réviser les tarifs'
        WHEN 'Surchargée' THEN '⚠️ Augmenter la capacité ou ajouter des créneaux'
        ELSE '✅ Fonctionnement optimal'
    END as [Recommandation],
    CASE 
        WHEN RefusFrequents > 5 THEN CONCAT('🚨 ', RefusFrequents, ' refus fréquents')
        WHEN Utilisation = 0 THEN '😴 Jamais réservée'
        ELSE '👍 Performance normale'
    END as [Alerte]
FROM AnalyseOptimisation
ORDER BY 
    CASE StatutOptimisation 
        WHEN 'Surchargée' THEN 1 
        WHEN 'Sous-utilisée' THEN 2 
        ELSE 3 
    END,
    Utilisation DESC;

PRINT CHAR(13) + CHAR(10) + '================================================';
PRINT 'ANALYSE TERMINÉE - Toutes les requêtes avancées exécutées avec succès!';
PRINT '================================================';