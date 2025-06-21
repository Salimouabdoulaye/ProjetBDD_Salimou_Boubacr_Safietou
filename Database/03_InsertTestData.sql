-- ============================================================================
-- Projet: Gestion des Réservations de Salles
-- Fichier: 03_InsertTestData.sql
-- Description: Insertion des données de test réalistes
-- Date: 25 juin 2025
-- ============================================================================

USE GestionReservationSalles;

-- ============================================================================
-- Insertion des UTILISATEURS
-- ============================================================================
INSERT INTO reservation.Utilisateur (Nom, Prenom, Email, Role, MotDePasse, Actif) VALUES
('Diop', 'Amadou', 'amadou.diop@entreprise.sn', 'Admin', 'admin123', 1),
('Ndiaye', 'Fatou', 'fatou.ndiaye@entreprise.sn', 'Manager', 'manager123', 1),
('Sarr', 'Ousmane', 'ousmane.sarr@entreprise.sn', 'Manager', 'manager123', 1),
('Fall', 'Aissatou', 'aissatou.fall@entreprise.sn', 'Employe', 'employe123', 1),
('Ba', 'Moussa', 'moussa.ba@entreprise.sn', 'Employe', 'employe123', 1),
('Cisse', 'Mariama', 'mariama.cisse@entreprise.sn', 'Employe', 'employe123', 1),
('Gueye', 'Ibrahima', 'ibrahima.gueye@entreprise.sn', 'Employe', 'employe123', 1),
('Diouf', 'Khadija', 'khadija.diouf@entreprise.sn', 'Employe', 'employe123', 1),
('Sow', 'Mamadou', 'mamadou.sow@entreprise.sn', 'Employe', 'employe123', 1),
('Thiam', 'Aminata', 'aminata.thiam@entreprise.sn', 'Employe', 'employe123', 1),
('Ndour', 'Alioune', 'alioune.ndour@entreprise.sn', 'Employe', 'employe123', 1),
('Kane', 'Bineta', 'bineta.kane@entreprise.sn', 'Employe', 'employe123', 1),
('Ly', 'Cheikh', 'cheikh.ly@entreprise.sn', 'Employe', 'employe123', 1),
('Mbaye', 'Ndèye', 'ndeye.mbaye@entreprise.sn', 'Employe', 'employe123', 1),
('Faye', 'Abdou', 'abdou.faye@entreprise.sn', 'Employe', 'employe123', 1);

-- ============================================================================
-- Insertion des SALLES
-- ============================================================================
INSERT INTO reservation.Salle (NomSalle, Capacite, Equipements, Localisation, Disponible, TarifHoraire) VALUES
('Salle Baobab', 25, 'Projecteur, Tableau, Climatisation, Wifi', 'Rez-de-chaussée - Aile Est', 1, 15000.00),
('Salle Fromager', 12, 'Écran TV, Tableau blanc, Climatisation', '1er étage - Aile Nord', 1, 8000.00),
('Salle Acacia', 50, 'Vidéoprojecteur, Sonorisation, Micros, Climatisation', 'Rez-de-chaussée - Aile Ouest', 1, 25000.00),
('Salle Caïlcédrat', 8, 'Écran TV, Tableau, Wifi', '2ème étage - Aile Sud', 1, 5000.00),
('Salle Palmier', 30, 'Projecteur, Sonorisation, Climatisation, Wifi', '1er étage - Aile Est', 1, 18000.00),
('Salle Karité', 15, 'Tableau blanc, Écran TV, Climatisation', '2ème étage - Aile Nord', 1, 10000.00),
('Salle Balanzan', 100, 'Scène, Sonorisation complète, Éclairage, Climatisation', 'Rez-de-chaussée - Hall principal', 1, 40000.00),
('Salle Néré', 6, 'Tableau, Wifi, Climatisation', '3ème étage - Aile Sud', 1, 4000.00),
('Salle Rônier', 20, 'Projecteur, Tableau blanc, Wifi', '1er étage - Aile Ouest', 1, 12000.00),
('Salle Tamarinier', 35, 'Vidéoprojecteur, Sonorisation, Micros sans fil', '2ème étage - Aile Est', 1, 20000.00);

-- ============================================================================
-- Insertion des TYPES D'ÉVÉNEMENTS
-- ============================================================================
INSERT INTO reservation.TypeEvenement (NomType, Description, DureeMinimale, DureeMaximale, NecessiteValidation) VALUES
('Réunion équipe', 'Réunion interne d''équipe', 30, 180, 0),
('Formation', 'Session de formation professionnelle', 120, 480, 1),
('Conférence', 'Présentation ou conférence', 60, 240, 1),
('Séminaire', 'Séminaire de travail', 240, 480, 1),
('Entretien', 'Entretien individuel ou collectif', 30, 120, 0),
('Présentation client', 'Présentation pour clients externes', 60, 180, 1),
('Réunion direction', 'Réunion de direction', 60, 240, 1),
('Brainstorming', 'Session de créativité collective', 60, 180, 0),
('Visioconférence', 'Réunion à distance', 30, 240, 0),
('Formation interne', 'Formation du personnel interne', 120, 360, 0);

-- ============================================================================
-- Insertion des RÉSERVATIONS (données de test variées)
-- ============================================================================
INSERT INTO reservation.Reservation (UserID, SalleID, TypeEventID, ObjetReservation, DateReservation, HeureDebut, HeureFin, Statut, DateDemande, DateValidation, ValidePar, Commentaires) VALUES
-- Réservations validées
(4, 1, 1, 'Réunion équipe marketing', '2025-06-26', '09:00', '10:30', 'Validee', '2025-06-21 08:00:00', '2025-06-21 10:00:00', 2, 'Préparation campagne été'),
(5, 3, 3, 'Conférence sur l''IA', '2025-06-27', '14:00', '16:00', 'Validee', '2025-06-20 15:30:00', '2025-06-21 09:00:00', 2, 'Événement ouvert au public'),
(6, 2, 5, 'Entretien candidat développeur', '2025-06-26', '11:00', '12:00', 'Validee', '2025-06-21 07:45:00', '2025-06-21 08:30:00', 3, NULL),

-- Réservations en attente
(7, 5, 2, 'Formation sécurité informatique', '2025-06-28', '09:00', '12:00', 'En_Attente', '2025-06-21 12:00:00', NULL, NULL, 'Formation obligatoire pour tous'),
(8, 7, 4, 'Séminaire innovation', '2025-06-30', '08:00', '17:00', 'En_Attente', '2025-06-21 14:30:00', NULL, NULL, 'Journée complète avec pauses'),
(9, 4, 8, 'Brainstorming nouveau produit', '2025-06-27', '10:00', '12:00', 'En_Attente', '2025-06-21 16:00:00', NULL, NULL, NULL),

-- Réservations refusées
(10, 1, 6, 'Présentation client important', '2025-06-26', '09:30', '11:00', 'Refusee', '2025-06-21 11:00:00', '2025-06-21 13:00:00', 2, 'Conflit horaire avec réunion marketing'),

-- Réservations annulées
(11, 6, 1, 'Réunion projet annulée', '2025-06-25', '15:00', '16:30', 'Annulee', '2025-06-20 10:00:00', NULL, NULL, 'Projet reporté'),

-- Autres réservations pour les tests
(12, 9, 9, 'Visioconférence partenaires', '2025-06-29', '16:00', '17:30', 'Validee', '2025-06-21 09:30:00', '2025-06-21 11:00:00', 3, 'Réunion trimestrielle'),
(13, 10, 7, 'Réunion comité direction', '2025-07-01', '14:00', '16:00', 'En_Attente', '2025-06-21 17:00:00', NULL, NULL, 'Ordre du jour à confirmer'),
(14, 8, 10, 'Formation nouveaux arrivants', '2025-06-28', '14:00', '17:00', 'Validee', '2025-06-21 08:15:00', '2025-06-21 09:45:00', 2, 'Intégration équipe'),
(15, 3, 3, 'Conférence développement durable', '2025-07-02', '10:00', '12:00', 'En_Attente', '2025-06-21 18:30:00', NULL, NULL, 'Sensibilisation environnementale');

-- ============================================================================
-- Insertion de l'HISTORIQUE
-- ============================================================================
INSERT INTO reservation.HistoriqueReservation (ReservationID, Action, DateAction, UserID, Details) VALUES
(1, 'Creation', '2025-06-21 08:00:00', 4, 'Demande de réservation créée'),
(1, 'Validation', '2025-06-21 10:00:00', 2, 'Réservation validée par manager'),

(2, 'Creation', '2025-06-20 15:30:00', 5, 'Demande de réservation créée'),
(2, 'Validation', '2025-06-21 09:00:00', 2, 'Réservation validée pour événement public'),

(3, 'Creation', '2025-06-21 07:45:00', 6, 'Demande de réservation créée'),
(3, 'Validation', '2025-06-21 08:30:00', 3, 'Réservation validée pour entretien'),

(4, 'Creation', '2025-06-21 12:00:00', 7, 'Demande de réservation créée'),

(5, 'Creation', '2025-06-21 14:30:00', 8, 'Demande de réservation créée'),

(6, 'Creation', '2025-06-21 16:00:00', 9, 'Demande de réservation créée'),

(7, 'Creation', '2025-06-21 11:00:00', 10, 'Demande de réservation créée'),
(7, 'Refus', '2025-06-21 13:00:00', 2, 'Réservation refusée - conflit horaire'),

(8, 'Creation', '2025-06-20 10:00:00', 11, 'Demande de réservation créée'),
(8, 'Annulation', '2025-06-21 14:00:00', 11, 'Réservation annulée par demandeur'),

(9, 'Creation', '2025-06-21 09:30:00', 12, 'Demande de réservation créée'),
(9, 'Validation', '2025-06-21 11:00:00', 3, 'Réservation validée pour visioconférence'),

(10, 'Creation', '2025-06-21 17:00:00', 13, 'Demande de réservation créée'),

(11, 'Creation', '2025-06-21 08:15:00', 14, 'Demande de réservation créée'),
(11, 'Validation', '2025-06-21 09:45:00', 2, 'Réservation validée pour formation'),

(12, 'Creation', '2025-06-21 18:30:00', 15, 'Demande de réservation créée');

PRINT 'Données de test insérées avec succès.';
PRINT 'Utilisateurs créés: 15 (1 Admin, 2 Managers, 12 Employés)';
PRINT 'Salles créées: 10';
PRINT 'Types d''événements: 10';
PRINT 'Réservations: 12 avec différents statuts';
PRINT 'Historique: 17 entrées d''audit';