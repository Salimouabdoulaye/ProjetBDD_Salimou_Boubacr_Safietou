-- ============================================================================
-- Projet: Gestion des Réservations de Salles
-- Fichier: 01_CreateDatabase.sql
-- Description: Création de la base de données
-- Date: 25 juin 2025
-- ============================================================================

-- Création de la base de données
-- CREATE DATABASE GestionReservationSalles;

-- Utiliser la base de données
USE GestionReservationSalles;

-- Configuration de la base de données
ALTER DATABASE GestionReservationSalles SET RECOVERY SIMPLE;
ALTER DATABASE GestionReservationSalles COLLATE French_CI_AS;

-- Création du schéma pour l'organisation
IF NOT EXISTS (SELECT * FROM sys.schemas WHERE name = 'reservation')
BEGIN
    EXEC('CREATE SCHEMA reservation');
    PRINT 'Schéma reservation créé avec succès.';
END

PRINT 'Configuration de la base de données terminée.';
