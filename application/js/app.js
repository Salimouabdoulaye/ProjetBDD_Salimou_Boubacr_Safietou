/**
 * ============================================================================
 * Projet: Gestion des Réservations de Salles
 * Fichier: js/app.js
 * Description: Application principale JavaScript
 * Date: 25 juin 2025
 * ============================================================================
 */

class ReservationApp {
    constructor() {
        this.currentUser = { id: 1, name: 'Amadou Diop', role: 'Admin' };
        this.reservations = [];
        this.salles = [];
        this.typesEvenements = [];
        this.filteredReservations = [];
        this.currentSection = 'dashboard';
        this.refreshTimer = null;
        
        this.init();
    }

    /**
     * Initialisation de l'application
     */
    init() {
        console.log('🚀 Initialisation de l\'application de réservation...');
        
        // Chargement des données
        this.loadSampleData();
        
        // Configuration des événements
        this.setupEventListeners();
        
        // Initialisation de l'interface
        this.updateDashboard();
        this.populateSelects();
        this.loadRecentReservations();
        this.setMinDate();
        
        // Configuration des tooltips Bootstrap
        this.initializeTooltips();
        
        // Configuration des raccourcis clavier
        this.setupKeyboardShortcuts();
        
        console.log('✅ Application initialisée avec succès');
    }

    /**
     * Chargement des données d'exemple
     */
    loadSampleData() {
        // Données de test - en production, ces données viendraient d'une API
        this.salles = [
            { id: 1, nom: 'Salle Baobab', capacite: 25, equipements: 'Projecteur, Tableau, Climatisation, Wifi', localisation: 'Rez-de-chaussée - Aile Est', disponible: true, tarif: 15000 },
            { id: 2, nom: 'Salle Fromager', capacite: 12, equipements: 'Écran TV, Tableau blanc, Climatisation', localisation: '1er étage - Aile Nord', disponible: true, tarif: 8000 },
            { id: 3, nom: 'Salle Acacia', capacite: 50, equipements: 'Vidéoprojecteur, Sonorisation, Micros, Climatisation', localisation: 'Rez-de-chaussée - Aile Ouest', disponible: true, tarif: 25000 },
            { id: 4, nom: 'Salle Caïlcédrat', capacite: 8, equipements: 'Écran TV, Tableau, Wifi', localisation: '2ème étage - Aile Sud', disponible: true, tarif: 5000 },
            { id: 5, nom: 'Salle Palmier', capacite: 30, equipements: 'Projecteur, Sonorisation, Climatisation, Wifi', localisation: '1er étage - Aile Est', disponible: true, tarif: 18000 }
        ];

        this.typesEvenements = [
            { id: 1, nom: 'Réunion équipe', description: 'Réunion interne d\'équipe', dureeMin: 30, dureeMax: 180, validation: false },
            { id: 2, nom: 'Formation', description: 'Session de formation professionnelle', dureeMin: 120, dureeMax: 480, validation: true },
            { id: 3, nom: 'Conférence', description: 'Présentation ou conférence', dureeMin: 60, dureeMax: 240, validation: true },
            { id: 4, nom: 'Séminaire', description: 'Séminaire de travail', dureeMin: 240, dureeMax: 480, validation: true },
            { id: 5, nom: 'Entretien', description: 'Entretien individuel ou collectif', dureeMin: 30, dureeMax: 120, validation: false }
        ];

        this.reservations = [
            {
                id: 1, userId: 4, userName: 'Aissatou Fall', salleId: 1, salleName: 'Salle Baobab',
                typeEventId: 1, typeEventName: 'Réunion équipe', objet: 'Réunion équipe marketing',
                date: '2025-06-26', heureDebut: '09:00', heureFin: '10:30', statut: 'Validee',
                dateDemande: '2025-06-21 08:00:00', dateValidation: '2025-06-21 10:00:00',
                validePar: 'Fatou Ndiaye', commentaires: 'Préparation campagne été'
            },
            {
                id: 2, userId: 5, userName: 'Moussa Ba', salleId: 3, salleName: 'Salle Acacia',
                typeEventId: 3, typeEventName: 'Conférence', objet: 'Conférence sur l\'IA',
                date: '2025-06-27', heureDebut: '14:00', heureFin: '16:00', statut: 'Validee',
                dateDemande: '2025-06-20 15:30:00', dateValidation: '2025-06-21 09:00:00',
                validePar: 'Fatou Ndiaye', commentaires: 'Événement ouvert au public'
            },
            {
                id: 3, userId: 7, userName: 'Ibrahima Gueye', salleId: 5, salleName: 'Salle Palmier',
                typeEventId: 2, typeEventName: 'Formation', objet: 'Formation sécurité informatique',
                date: '2025-06-28', heureDebut: '09:00', heureFin: '12:00', statut: 'En_Attente',
                dateDemande: '2025-06-21 12:00:00', dateValidation: null,
                validePar: null, commentaires: 'Formation obligatoire pour tous'
            },
            {
                id: 4, userId: 8, userName: 'Khadija Diouf', salleId: 2, salleName: 'Salle Fromager',
                typeEventId: 4, typeEventName: 'Séminaire', objet: 'Séminaire innovation',
                date: '2025-06-30', heureDebut: '08:00', heureFin: '17:00', statut: 'En_Attente',
                dateDemande: '2025-06-21 14:30:00', dateValidation: null,
                validePar: null, commentaires: 'Journée complète avec pauses'
            }
        ];

        this.filteredReservations = [...this.reservations];
    }

    /**
     * Configuration des écouteurs d'événements
     */
    setupEventListeners() {
        // Navigation
        document.querySelectorAll('.navbar-nav .nav-link').forEach(link => {
            link.addEventListener('click', (e) => {
                if (link.getAttribute('onclick')) return; // Skip if has onclick
                
                e.preventDefault();
                const section = this.getSectionFromLink(link);
                if (section) {
                    this.showSection(section);
                }
            });
        });

        // Formulaire de nouvelle réservation
        const newReservationForm = document.getElementById('newReservationForm');
        if (newReservationForm) {
            newReservationForm.addEventListener('submit', (e) => {
                e.preventDefault();
                this.submitNewReservation();
            });
        }

        // Filtres de réservations
        ['statusFilter', 'salleFilter', 'dateFilter', 'searchFilter'].forEach(filterId => {
            const element = document.getElementById(filterId);
            if (element) {
                element.addEventListener('change', () => this.applyFilters());
                if (filterId === 'searchFilter') {
                    element.addEventListener('keyup', () => this.applyFilters());
                }
            }
        });

        // Validation des heures dans le formulaire
        const heureDebut = document.getElementById('reservationHeureDebut');
        const heureFin = document.getElementById('reservationHeureFin');
        
        if (heureDebut && heureFin) {
            heureDebut.addEventListener('change', () => {
                this.validateTimeRange(heureDebut.value, heureFin);
            });
        }

        // Changement de type d'événement
        const typeSelect = document.getElementById('reservationTypeEvent');
        if (typeSelect) {
            typeSelect.addEventListener('change', () => {
                this.updateEventTypeInfo(parseInt(typeSelect.value));
            });
        }

        // Auto-refresh périodique (simulation)
        this.refreshTimer = setInterval(() => {
            this.refreshData();
        }, 30000); // 30 secondes
    }

    /**
     * Configuration des raccourcis clavier
     */
    setupKeyboardShortcuts() {
        const handleKeyDown = (e) => {
            if (e.ctrlKey || e.metaKey) {
                switch(e.key) {
                    case 'n':
                        e.preventDefault();
                        this.showNewReservationModal();
                        break;
                    case 'e':
                        e.preventDefault();
                        this.exportData();
                        break;
                    case '1':
                        e.preventDefault();
                        this.showSection('dashboard');
                        break;
                    case '2':
                        e.preventDefault();
                        this.showSection('reservations');
                        break;
                    case '3':
                        e.preventDefault();
                        this.showSection('calendar');
                        break;
                    case '4':
                        e.preventDefault();
                        this.showSection('salles');
                        break;
                }
            }
        };

        document.addEventListener('keydown', handleKeyDown);
        
        // Stocker la référence pour pouvoir la nettoyer plus tard
        this.keydownHandler = handleKeyDown;
    }

    /**
     * Initialise les tooltips Bootstrap
     */
    initializeTooltips() {
        if (typeof bootstrap !== 'undefined' && bootstrap.Tooltip) {
            const tooltipTriggerList = [].slice.call(document.querySelectorAll('[data-bs-toggle="tooltip"]'));
            tooltipTriggerList.map(function (tooltipTriggerEl) {
                return new bootstrap.Tooltip(tooltipTriggerEl);
            });
        }
    }

    /**
     * Affiche une section spécifique
     */
    showSection(sectionName) {
        // Masquer toutes les sections
        document.querySelectorAll('.content-section').forEach(section => {
            section.style.display = 'none';
            section.classList.remove('fade-in');
        });
        
        // Afficher la section sélectionnée
        const targetSection = document.getElementById(`${sectionName}-section`);
        if (targetSection) {
            targetSection.style.display = 'block';
            targetSection.classList.add('fade-in');
        }
        
        // Mettre à jour la navigation
        this.updateNavigation(sectionName);
        
        // Charger les données spécifiques à la section
        this.loadSectionData(sectionName);
        
        this.currentSection = sectionName;
    }

    /**
     * Met à jour l'état de la navigation
     */
    updateNavigation(activeSection) {
        document.querySelectorAll('.navbar-nav .nav-link').forEach(link => {
            link.classList.remove('active');
            const section = this.getSectionFromLink(link);
            if (section === activeSection) {
                link.classList.add('active');
            }
        });
    }

    /**
     * Extrait le nom de section depuis un lien de navigation
     */
    getSectionFromLink(link) {
        const onclick = link.getAttribute('onclick');
        if (onclick) {
            const match = onclick.match(/showSection\('(\w+)'\)/);
            return match ? match[1] : null;
        }
        return null;
    }

    /**
     * Charge les données spécifiques à une section
     */
    loadSectionData(sectionName) {
        switch(sectionName) {
            case 'dashboard':
                this.updateDashboard();
                this.loadRecentReservations();
                break;
            case 'reservations':
                this.loadReservations();
                break;
            case 'calendar':
                // Le calendrier sera géré par calendar.js
                if (window.calendarManager) {
                    window.calendarManager.render();
                }
                break;
            case 'salles':
                this.loadSalles();
                break;
        }
    }

    /**
     * Met à jour le tableau de bord
     */
    updateDashboard() {
        const stats = this.calculateStats();
        
        this.updateElement('totalReservations', stats.total);
        this.updateElement('validatedReservations', stats.validated);
        this.updateElement('pendingReservations', stats.pending);
        this.updateElement('rejectedReservations', stats.rejected);
        this.updateElement('todayReservations', stats.today);
        this.updateElement('validationRate', `${stats.validationRate}%`);
    }

    /**
     * Calcule les statistiques
     */
    calculateStats() {
        const total = this.reservations.length;
        const validated = this.reservations.filter(r => r.statut === 'Validee').length;
        const pending = this.reservations.filter(r => r.statut === 'En_Attente').length;
        const rejected = this.reservations.filter(r => r.statut === 'Refusee').length;
        
        const today = new Date().toISOString().split('T')[0];
        const todayCount = this.reservations.filter(r => r.date === today).length;
        
        const validationRate = total > 0 ? Math.round((validated / total) * 100) : 0;
        
        return { total, validated, pending, rejected, today: todayCount, validationRate };
    }

    /**
     * Met à jour un élément du DOM
     */
    updateElement(id, value) {
        const element = document.getElementById(id);
        if (element) {
            element.textContent = value;
        }
    }

    /**
     * Charge les réservations récentes
     */
    loadRecentReservations() {
        const tableBody = document.getElementById('recentReservationsTable');
        if (!tableBody) return;

        const recent = this.reservations.slice(0, 5);
        tableBody.innerHTML = recent.map(reservation => this.createReservationRow(reservation, true)).join('');
    }

    /**
     * Charge toutes les réservations
     */
    loadReservations() {
        const tableBody = document.getElementById('reservationsTable');
        if (!tableBody) return;

        tableBody.innerHTML = this.filteredReservations.map(reservation => 
            this.createReservationRow(reservation, false)
        ).join('');
    }

    /**
     * Crée une ligne de tableau pour une réservation
     */
    createReservationRow(reservation, isRecent = false) {
        const columns = isRecent ? [
            this.formatDate(reservation.date),
            reservation.salleName,
            `${reservation.heureDebut} - ${reservation.heureFin}`,
            reservation.objet,
            this.createStatusBadge(reservation.statut),
            this.createActionButtons(reservation)
        ] : [
            `#${reservation.id}`,
            reservation.userName,
            this.formatDate(reservation.date),
            `${reservation.heureDebut} - ${reservation.heureFin}`,
            reservation.salleName,
            reservation.objet,
            reservation.typeEventName,
            this.createStatusBadge(reservation.statut),
            this.createActionButtons(reservation)
        ];

        return `<tr>${columns.map(col => `<td>${col}</td>`).join('')}</tr>`;
    }

    /**
     * Crée un badge de statut
     */
    createStatusBadge(statut) {
        const statusClass = `status-${statut.toLowerCase().replace('_', '')}`;
        const statusText = this.getStatusText(statut);
        return `<span class="status-badge ${statusClass}">${statusText}</span>`;
    }

    /**
     * Obtient le texte d'affichage pour un statut
     */
    getStatusText(statut) {
        const statusMap = {
            'En_Attente': 'En attente',
            'Validee': 'Validée',
            'Refusee': 'Refusée',
            'Annulee': 'Annulée'
        };
        return statusMap[statut] || statut;
    }

    /**
     * Crée les boutons d'action pour une réservation
     */
    createActionButtons(reservation) {
        let buttons = '';
        
        // Bouton de validation pour managers/admins
        if (this.canValidate() && reservation.statut === 'En_Attente') {
            buttons += `<button class="btn btn-sm btn-success me-1" onclick="app.showValidationModal(${reservation.id})" data-bs-toggle="tooltip" title="Valider">
                <i class="fas fa-check"></i>
            </button>`;
        }
        
        // Bouton d'annulation
        if (this.canCancel(reservation)) {
            buttons += `<button class="btn btn-sm btn-warning me-1" onclick="app.cancelReservation(${reservation.id})" data-bs-toggle="tooltip" title="Annuler">
                <i class="fas fa-times"></i>
            </button>`;
        }
        
        // Bouton de détails
        buttons += `<button class="btn btn-sm btn-info" onclick="app.showReservationDetails(${reservation.id})" data-bs-toggle="tooltip" title="Détails">
            <i class="fas fa-eye"></i>
        </button>`;
        
        return buttons;
    }

    /**
     * Vérifie si l'utilisateur peut valider
     */
    canValidate() {
        return ['Admin', 'Manager'].includes(this.currentUser.role);
    }

    /**
     * Vérifie si l'utilisateur peut annuler une réservation
     */
    canCancel(reservation) {
        return (reservation.userId === this.currentUser.id || this.currentUser.role === 'Admin') 
               && reservation.statut !== 'Annulee';
    }

    /**
     * Charge les salles
     */
    loadSalles() {
        const sallesGrid = document.getElementById('sallesGrid');
        if (!sallesGrid) return;

        sallesGrid.innerHTML = this.salles.map(salle => this.createSalleCard(salle)).join('');
    }

    /**
     * Crée une carte pour une salle
     */
    createSalleCard(salle) {
        return `
            <div class="col-md-6 col-lg-4 mb-4">
                <div class="card h-100">
                    <div class="card-body">
                        <h5 class="card-title">${salle.nom}</h5>
                        <p class="card-text">
                            <i class="fas fa-users"></i> Capacité: ${salle.capacite} personnes<br>
                            <i class="fas fa-map-marker-alt"></i> ${salle.localisation}<br>
                            <i class="fas fa-money-bill-wave"></i> ${salle.tarif.toLocaleString()} FCFA/heure
                        </p>
                        <div class="mb-2">
                            <small class="text-muted">Équipements:</small><br>
                            <small>${salle.equipements}</small>
                        </div>
                        <div class="d-flex justify-content-between align-items-center">
                            <span class="badge ${salle.disponible ? 'bg-success' : 'bg-danger'}">
                                ${salle.disponible ? 'Disponible' : 'Indisponible'}
                            </span>
                            <button class="btn btn-sm btn-primary" onclick="app.reserveSalle(${salle.id})">
                                <i class="fas fa-calendar-plus"></i> Réserver
                            </button>
                        </div>
                    </div>
                </div>
            </div>
        `;
    }

    /**
     * Peuple les listes déroulantes
     */
    populateSelects() {
        this.populateSallesSelect();
        this.populateTypesEvenementsSelect();
    }

    /**
     * Peuple les sélecteurs de salles
     */
    populateSallesSelect() {
        const selects = ['reservationSalle', 'salleFilter'];
        
        selects.forEach(selectId => {
            const select = document.getElementById(selectId);
            if (!select) return;

            const isFilter = selectId.includes('Filter');
            const defaultOption = isFilter ? 'Toutes les salles' : 'Sélectionner une salle';
            
            select.innerHTML = `<option value="">${defaultOption}</option>`;
            
            this.salles.forEach(salle => {
                select.innerHTML += `<option value="${salle.id}">${salle.nom} (${salle.capacite} pers.)</option>`;
            });
        });
    }

    /**
     * Peuple le sélecteur de types d'événements
     */
    populateTypesEvenementsSelect() {
        const select = document.getElementById('reservationTypeEvent');
        if (!select) return;

        select.innerHTML = '<option value="">Sélectionner un type</option>';
        
        this.typesEvenements.forEach(type => {
            select.innerHTML += `<option value="${type.id}">${type.nom}</option>`;
        });
    }

    /**
     * Définit la date minimale pour les réservations
     */
    setMinDate() {
        const dateInput = document.getElementById('reservationDate');
        if (dateInput) {
            const today = new Date().toISOString().split('T')[0];
            dateInput.min = today;
        }
    }

    /**
     * Valide la plage horaire
     */
    validateTimeRange(heureDebut, heureFin) {
        if (heureDebut && heureFin.value) {
            const [hours, minutes] = heureDebut.split(':');
            const newHours = parseInt(hours) + 1;
            heureFin.min = `${newHours.toString().padStart(2, '0')}:${minutes}`;
            
            if (heureFin.value && heureFin.value <= heureDebut) {
                heureFin.value = `${newHours.toString().padStart(2, '0')}:${minutes}`;
            }
        }
    }

    /**
     * Met à jour les informations du type d'événement
     */
    updateEventTypeInfo(typeId) {
        const type = this.typesEvenements.find(t => t.id === typeId);
        const infoDiv = document.querySelector('.alert-info');
        
        if (type && infoDiv) {
            if (type.validation) {
                infoDiv.innerHTML = '<i class="fas fa-info-circle"></i> Ce type d\'événement nécessite une validation managériale.';
                infoDiv.className = 'alert alert-warning';
            } else {
                infoDiv.innerHTML = '<i class="fas fa-check-circle"></i> Ce type d\'événement sera validé automatiquement.';
                infoDiv.className = 'alert alert-success';
            }
            
            const durationHint = `Durée recommandée: ${type.dureeMin}-${type.dureeMax} minutes`;
            if (!document.querySelector('.duration-hint')) {
                infoDiv.innerHTML += `<br><small class="duration-hint">${durationHint}</small>`;
            }
        }
    }

    /**
     * Affiche le modal de nouvelle réservation
     */
    showNewReservationModal() {
        const form = document.getElementById('newReservationForm');
        if (form) {
            form.reset();
        }
        
        this.setMinDate();
        
        const modal = document.getElementById('newReservationModal');
        if (modal) {
            if (typeof bootstrap !== 'undefined' && bootstrap.Modal) {
                new bootstrap.Modal(modal).show();
            }
        }
    }

    /**
     * Soumet une nouvelle réservation
     */
    submitNewReservation() {
        const form = document.getElementById('newReservationForm');
        if (!form || !form.checkValidity()) {
            if (form) form.reportValidity();
            return;
        }

        const formData = this.getFormData();
        
        if (!this.validateReservationData(formData)) {
            return;
        }

        const newReservation = this.createNewReservation(formData);
        this.reservations.unshift(newReservation);
        this.filteredReservations = [...this.reservations];

        // Fermer le modal
        const modal = document.getElementById('newReservationModal');
        if (modal && typeof bootstrap !== 'undefined' && bootstrap.Modal) {
            const modalInstance = bootstrap.Modal.getInstance(modal);
            if (modalInstance) modalInstance.hide();
        }

        // Mettre à jour l'interface
        this.updateDashboard();
        this.loadRecentReservations();
        if (this.currentSection === 'reservations') {
            this.loadReservations();
        }

        // Notification
        this.showAlert('Réservation créée avec succès!', 'success');

        // Notifier le calendrier s'il existe
        if (window.calendarManager) {
            window.calendarManager.addReservation(newReservation);
        }
    }

    /**
     * Récupère les données du formulaire
     */
    getFormData() {
        return {
            salleId: parseInt(document.getElementById('reservationSalle')?.value) || 0,
            typeEventId: parseInt(document.getElementById('reservationTypeEvent')?.value) || 0,
            date: document.getElementById('reservationDate')?.value || '',
            heureDebut: document.getElementById('reservationHeureDebut')?.value || '',
            heureFin: document.getElementById('reservationHeureFin')?.value || '',
            objet: document.getElementById('reservationObjet')?.value || '',
            commentaires: document.getElementById('reservationCommentaires')?.value || ''
        };
    }

    /**
     * Valide les données de réservation
     */
    validateReservationData(formData) {
        if (formData.heureDebut >= formData.heureFin) {
            this.showAlert('Erreur: L\'heure de fin doit être après l\'heure de début.', 'danger');
            return false;
        }

        // Vérifier les conflits horaires
        const conflicts = this.checkTimeConflicts(formData);
        if (conflicts.length > 0) {
            this.showAlert('Conflit horaire détecté avec une autre réservation.', 'danger');
            return false;
        }

        return true;
    }

    /**
     * Vérifie les conflits horaires
     */
    checkTimeConflicts(formData) {
        return this.reservations.filter(r => 
            r.salleId === formData.salleId &&
            r.date === formData.date &&
            r.statut !== 'Annulee' &&
            r.statut !== 'Refusee' &&
            this.timeRangesOverlap(
                formData.heureDebut, formData.heureFin,
                r.heureDebut, r.heureFin
            )
        );
    }

    /**
     * Vérifie si deux plages horaires se chevauchent
     */
    timeRangesOverlap(start1, end1, start2, end2) {
        return (start1 < end2) && (end1 > start2);
    }

    /**
     * Crée une nouvelle réservation
     */
    createNewReservation(formData) {
        const newId = Math.max(...this.reservations.map(r => r.id), 0) + 1;
        const salle = this.salles.find(s => s.id === formData.salleId);
        const typeEvent = this.typesEvenements.find(t => t.id === formData.typeEventId);
        
        return {
            id: newId,
            userId: this.currentUser.id,
            userName: this.currentUser.name,
            salleId: formData.salleId,
            salleName: salle?.nom || '',
            typeEventId: formData.typeEventId,
            typeEventName: typeEvent?.nom || '',
            objet: formData.objet,
            date: formData.date,
            heureDebut: formData.heureDebut,
            heureFin: formData.heureFin,
            statut: typeEvent?.validation ? 'En_Attente' : 'Validee',
            dateDemande: new Date().toISOString(),
            dateValidation: typeEvent?.validation ? null : new Date().toISOString(),
            validePar: typeEvent?.validation ? null : this.currentUser.name,
            commentaires: formData.commentaires
        };
    }

    /**
     * Applique les filtres aux réservations
     */
    applyFilters() {
        const filters = {
            status: document.getElementById('statusFilter')?.value || '',
            salle: document.getElementById('salleFilter')?.value || '',
            date: document.getElementById('dateFilter')?.value || '',
            search: document.getElementById('searchFilter')?.value?.toLowerCase() || ''
        };

        this.filteredReservations = this.reservations.filter(reservation => {
            const matchesStatus = !filters.status || reservation.statut === filters.status;
            const matchesSalle = !filters.salle || reservation.salleId.toString() === filters.salle;
            const matchesDate = !filters.date || reservation.date === filters.date;
            const matchesSearch = !filters.search || 
                reservation.objet.toLowerCase().includes(filters.search) ||
                reservation.userName.toLowerCase().includes(filters.search) ||
                reservation.salleName.toLowerCase().includes(filters.search);

            return matchesStatus && matchesSalle && matchesDate && matchesSearch;
        });

        if (this.currentSection === 'reservations') {
            this.loadReservations();
        }
    }

    /**
     * Filtre les réservations par statut
     */
    filterReservations(status) {
        const statusFilter = document.getElementById('statusFilter');
        if (statusFilter) {
            statusFilter.value = status;
            this.applyFilters();
        }
        this.showSection('reservations');
    }

    /**
     * Affiche le modal de validation
     */
    showValidationModal(reservationId) {
        const reservation = this.reservations.find(r => r.id === reservationId);
        if (!reservation) return;

        const detailsDiv = document.getElementById('validationDetails');
        if (detailsDiv) {
            detailsDiv.innerHTML = this.createValidationDetails(reservation);
        }

        const modal = document.getElementById('validationModal');
        if (modal) {
            modal.dataset.reservationId = reservationId;
            
            // Réinitialiser le champ commentaires
            const commentsField = document.getElementById('validationComments');
            if (commentsField) {
                commentsField.value = '';
            }
            
            // Afficher le modal
            if (typeof bootstrap !== 'undefined' && bootstrap.Modal) {
                new bootstrap.Modal(modal).show();
            }
        }
    }

    /**
     * Crée les détails pour la validation
     */
    createValidationDetails(reservation) {
        return `
            <div class="mb-3">
                <strong>Réservation #${reservation.id}</strong><br>
                <strong>Utilisateur:</strong> ${reservation.userName}<br>
                <strong>Salle:</strong> ${reservation.salleName}<br>
                <strong>Date:</strong> ${this.formatDate(reservation.date)}<br>
                <strong>Horaire:</strong> ${reservation.heureDebut} - ${reservation.heureFin}<br>
                <strong>Objet:</strong> ${reservation.objet}<br>
                <strong>Type:</strong> ${reservation.typeEventName}
            </div>
        `;
    }

    /**
     * Traite la validation d'une réservation
     */
    processValidation(approve) {
        const modal = document.getElementById('validationModal');
        if (!modal) return;

        const reservationId = parseInt(modal.dataset.reservationId);
        const comments = document.getElementById('validationComments')?.value || '';
        
        const reservation = this.reservations.find(r => r.id === reservationId);
        if (!reservation) return;

        reservation.statut = approve ? 'Validee' : 'Refusee';
        reservation.dateValidation = new Date().toISOString();
        reservation.validePar = this.currentUser.name;
        if (comments) {
            reservation.commentaires = comments;
        }

        // Fermer le modal
        if (typeof bootstrap !== 'undefined' && bootstrap.Modal) {
            const modalInstance = bootstrap.Modal.getInstance(modal);
            if (modalInstance) modalInstance.hide();
        }

        // Mettre à jour l'interface
        this.updateDashboard();
        this.loadRecentReservations();
        if (this.currentSection === 'reservations') {
            this.loadReservations();
        }

        // Notification
        const message = `Réservation ${approve ? 'approuvée' : 'refusée'} avec succès!`;
        this.showAlert(message, approve ? 'success' : 'warning');

        // Notifier le calendrier
        if (window.calendarManager) {
            window.calendarManager.updateReservation(reservation);
        }
    }

    /**
     * Annule une réservation
     */
    cancelReservation(reservationId) {
        if (!confirm('Êtes-vous sûr de vouloir annuler cette réservation ?')) {
            return;
        }
        
        const reservation = this.reservations.find(r => r.id === reservationId);
        if (!reservation) return;

        reservation.statut = 'Annulee';
        
        // Mettre à jour l'interface
        this.updateDashboard();
        this.loadRecentReservations();
        if (this.currentSection === 'reservations') {
            this.loadReservations();
        }

        this.showAlert('Réservation annulée avec succès!', 'info');

        // Notifier le calendrier
        if (window.calendarManager) {
            window.calendarManager.updateReservation(reservation);
        }
    }

    /**
     * Réserve une salle spécifique
     */
    reserveSalle(salleId) {
        const salleSelect = document.getElementById('reservationSalle');
        if (salleSelect) {
            salleSelect.value = salleId;
        }
        this.showNewReservationModal();
    }

    /**
     * Affiche les détails d'une réservation
     */
    showReservationDetails(reservationId) {
        const reservation = this.reservations.find(r => r.id === reservationId);
        if (!reservation) return;

        const details = this.createReservationDetailsHTML(reservation);
        this.showAlert(details, 'info', 8000);
    }

    /**
     * Crée le HTML des détails d'une réservation
     */
    createReservationDetailsHTML(reservation) {
        return `
            <div class="row">
                <div class="col-md-6">
                    <strong>ID:</strong> #${reservation.id}<br>
                    <strong>Utilisateur:</strong> ${reservation.userName}<br>
                    <strong>Salle:</strong> ${reservation.salleName}<br>
                    <strong>Date:</strong> ${this.formatDate(reservation.date)}<br>
                    <strong>Horaire:</strong> ${reservation.heureDebut} - ${reservation.heureFin}
                </div>
                <div class="col-md-6">
                    <strong>Type:</strong> ${reservation.typeEventName}<br>
                    <strong>Statut:</strong> ${this.createStatusBadge(reservation.statut)}<br>
                    <strong>Demande:</strong> ${this.formatDateTime(reservation.dateDemande)}<br>
                    ${reservation.dateValidation ? `<strong>Validation:</strong> ${this.formatDateTime(reservation.dateValidation)}<br>` : ''}
                    ${reservation.validePar ? `<strong>Validé par:</strong> ${reservation.validePar}` : ''}
                </div>
            </div>
            <hr>
            <strong>Objet:</strong> ${reservation.objet}<br>
            ${reservation.commentaires ? `<strong>Commentaires:</strong> ${reservation.commentaires}` : ''}
        `;
    }

    /**
     * Exporte les données en PDF
     */
    exportData() {
        try {
            if (typeof window.jspdf === 'undefined') {
                this.showAlert('Erreur: Bibliothèque jsPDF non disponible', 'danger');
                return;
            }

            const { jsPDF } = window.jspdf;
            const doc = new jsPDF();

            // Configuration du document
            this.setupPDFDocument(doc);
            
            // Contenu du rapport
            this.addPDFContent(doc);
            
            // Téléchargement
            doc.save('reservations-rapport.pdf');
            this.showAlert('Rapport PDF exporté avec succès!', 'success');
        } catch (error) {
            console.error('Erreur lors de l\'export PDF:', error);
            this.showAlert('Erreur lors de l\'export PDF. Vérifiez que jsPDF est chargé.', 'danger');
        }
    }

    /**
     * Configure le document PDF
     */
    setupPDFDocument(doc) {
        doc.setFontSize(20);
        doc.text('Rapport des Réservations', 20, 20);
        
        doc.setFontSize(12);
        doc.text(`Généré le: ${new Date().toLocaleDateString('fr-FR')}`, 20, 35);
    }

    /**
     * Ajoute le contenu au PDF
     */
    addPDFContent(doc) {
        const stats = this.calculateStats();
        
        // Statistiques
        doc.setFontSize(14);
        doc.text('Statistiques:', 20, 50);
        doc.setFontSize(12);
        doc.text(`Total des réservations: ${stats.total}`, 25, 60);
        doc.text(`Validées: ${stats.validated}`, 25, 70);
        doc.text(`En attente: ${stats.pending}`, 25, 80);
        doc.text(`Refusées: ${stats.rejected}`, 25, 90);

        // Liste des réservations
        doc.setFontSize(14);
        doc.text('Liste des réservations:', 20, 110);
        
        let yPosition = 120;
        doc.setFontSize(10);
        
        this.reservations.slice(0, 15).forEach((reservation) => {
            if (yPosition > 270) {
                doc.addPage();
                yPosition = 20;
            }
            
            doc.text(`${reservation.id}. ${reservation.salleName} - ${this.formatDate(reservation.date)} ${reservation.heureDebut}-${reservation.heureFin}`, 25, yPosition);
            doc.text(`   ${reservation.objet} (${this.getStatusText(reservation.statut)})`, 25, yPosition + 10);
            yPosition += 20;
        });
    }

    /**
     * Rafraîchit les données (simulation)
     */
    refreshData() {
        // En production, ceci ferait un appel API
        console.log('🔄 Rafraîchissement automatique des données...');
        
        // Simulation de nouvelles données
        // this.loadDataFromAPI();
    }

    /**
     * Affiche une alerte
     */
    showAlert(message, type = 'info', duration = 5000) {
        const alertContainer = document.getElementById('alertContainer');
        if (!alertContainer) {
            console.warn('Container d\'alertes introuvable');
            return;
        }

        const alertId = 'alert-' + Date.now();
        
        const alertHtml = `
            <div id="${alertId}" class="alert alert-${type} alert-dismissible fade show" role="alert">
                ${message}
                <button type="button" class="btn-close" data-bs-dismiss="alert"></button>
            </div>
        `;
        
        alertContainer.insertAdjacentHTML('beforeend', alertHtml);
        
        setTimeout(() => {
            const alertElement = document.getElementById(alertId);
            if (alertElement) {
                if (typeof bootstrap !== 'undefined' && bootstrap.Alert) {
                    bootstrap.Alert.getOrCreateInstance(alertElement).close();
                } else {
                    alertElement.remove();
                }
            }
        }, duration);
    }

    /**
     * Formate une date
     */
    formatDate(dateString) {
        try {
            return new Date(dateString).toLocaleDateString('fr-FR');
        } catch (error) {
            return dateString;
        }
    }

    /**
     * Formate une date et heure
     */
    formatDateTime(dateTimeString) {
        try {
            return new Date(dateTimeString).toLocaleString('fr-FR');
        } catch (error) {
            return dateTimeString;
        }
    }

    /**
     * Déconnexion
     */
    logout() {
        if (confirm('Êtes-vous sûr de vouloir vous déconnecter ?')) {
            this.showAlert('Déconnexion réussie. Redirection...', 'success');
            setTimeout(() => {
                // En production, rediriger vers la page de connexion
                location.reload();
            }, 2000);
        }
    }

    /**
     * Impression des réservations
     */
    printReservations() {
        try {
            const printWindow = window.open('', '_blank');
            const printContent = this.generatePrintContent();
            
            printWindow.document.write(printContent);
            printWindow.document.close();
            printWindow.print();
        } catch (error) {
            console.error('Erreur lors de l\'impression:', error);
            this.showAlert('Erreur lors de l\'impression', 'danger');
        }
    }

    /**
     * Génère le contenu pour l'impression
     */
    generatePrintContent() {
        const stats = this.calculateStats();
        
        return `
            <html>
            <head>
                <title>Rapport des Réservations</title>
                <style>
                    body { font-family: Arial, sans-serif; margin: 20px; }
                    table { width: 100%; border-collapse: collapse; margin-top: 20px; }
                    th, td { border: 1px solid #ddd; padding: 8px; text-align: left; }
                    th { background-color: #f2f2f2; }
                    .header { text-align: center; margin-bottom: 30px; }
                    .stats { margin: 20px 0; }
                </style>
            </head>
            <body>
                <div class="header">
                    <h1>Rapport des Réservations de Salles</h1>
                    <p>Généré le: ${new Date().toLocaleString('fr-FR')}</p>
                </div>
                <div class="stats">
                    <h2>Statistiques</h2>
                    <p>Total: ${stats.total} | Validées: ${stats.validated} | En attente: ${stats.pending}</p>
                </div>
                <table>
                    <thead>
                        <tr>
                            <th>ID</th>
                            <th>Utilisateur</th>
                            <th>Date</th>
                            <th>Horaire</th>
                            <th>Salle</th>
                            <th>Objet</th>
                            <th>Statut</th>
                        </tr>
                    </thead>
                    <tbody>
                        ${this.reservations.map(r => `
                            <tr>
                                <td>#${r.id}</td>
                                <td>${r.userName}</td>
                                <td>${this.formatDate(r.date)}</td>
                                <td>${r.heureDebut} - ${r.heureFin}</td>
                                <td>${r.salleName}</td>
                                <td>${r.objet}</td>
                                <td>${this.getStatusText(r.statut)}</td>
                            </tr>
                        `).join('')}
                    </tbody>
                </table>
            </body>
            </html>
        `;
    }

    /**
     * Export des données en JSON
     */
    exportToJSON() {
        try {
            const data = {
                reservations: this.reservations,
                salles: this.salles,
                typesEvenements: this.typesEvenements,
                exportedAt: new Date().toISOString()
            };

            const blob = new Blob([JSON.stringify(data, null, 2)], { type: 'application/json' });
            const url = URL.createObjectURL(blob);
            
            const a = document.createElement('a');
            a.href = url;
            a.download = 'reservations-data.json';
            document.body.appendChild(a);
            a.click();
            document.body.removeChild(a);
            URL.revokeObjectURL(url);

            this.showAlert('Données exportées en JSON', 'success');
        } catch (error) {
            console.error('Erreur lors de l\'export JSON:', error);
            this.showAlert('Erreur lors de l\'export JSON', 'danger');
        }
    }

    /**
     * Import des données depuis JSON
     */
    importFromJSON(file) {
        const reader = new FileReader();
        reader.onload = (e) => {
            try {
                const data = JSON.parse(e.target.result);
                
                if (data.reservations) this.reservations = data.reservations;
                if (data.salles) this.salles = data.salles;
                if (data.typesEvenements) this.typesEvenements = data.typesEvenements;
                
                this.filteredReservations = [...this.reservations];
                this.updateDashboard();
                this.populateSelects();
                this.loadRecentReservations();
                
                this.showAlert('Données importées avec succès', 'success');
            } catch (error) {
                this.showAlert('Erreur lors de l\'import: fichier invalide', 'danger');
            }
        };
        reader.onerror = () => {
            this.showAlert('Erreur lors de la lecture du fichier', 'danger');
        };
        reader.readAsText(file);
    }

    /**
     * Recherche intelligente
     */
    performIntelligentSearch(query) {
        const searchTerms = query.toLowerCase().split(' ');
        
        return this.reservations.filter(reservation => {
            const searchableText = [
                reservation.objet,
                reservation.userName,
                reservation.salleName,
                reservation.typeEventName,
                this.getStatusText(reservation.statut),
                this.formatDate(reservation.date)
            ].join(' ').toLowerCase();
            
            return searchTerms.every(term => searchableText.includes(term));
        });
    }

    /**
     * Gestion des erreurs globales
     */
    handleError(error, context = '') {
        console.error(`Erreur dans ${context}:`, error);
        this.showAlert(`Une erreur est survenue: ${error.message}`, 'danger');
    }

    /**
     * Validation des formulaires côté client
     */
    validateForm(formId) {
        const form = document.getElementById(formId);
        if (!form) return false;

        const inputs = form.querySelectorAll('input[required], select[required], textarea[required]');
        let isValid = true;

        inputs.forEach(input => {
            if (!input.value.trim()) {
                this.highlightError(input);
                isValid = false;
            } else {
                this.clearError(input);
            }
        });

        return isValid;
    }

    /**
     * Met en évidence les erreurs de formulaire
     */
    highlightError(input) {
        input.classList.add('is-invalid');
        
        setTimeout(() => {
            input.classList.remove('is-invalid');
        }, 3000);
    }

    /**
     * Efface les erreurs de formulaire
     */
    clearError(input) {
        input.classList.remove('is-invalid');
    }

    /**
     * Sauvegarde locale des données (simulation)
     */
    saveToLocalStorage() {
        try {
            const data = {
                reservations: this.reservations,
                lastUpdate: new Date().toISOString()
            };
            localStorage.setItem('reservationsApp', JSON.stringify(data));
        } catch (error) {
            console.warn('Impossible de sauvegarder en local:', error);
        }
    }

    /**
     * Chargement depuis le stockage local
     */
    loadFromLocalStorage() {
        try {
            const data = localStorage.getItem('reservationsApp');
            if (data) {
                const parsed = JSON.parse(data);
                if (parsed.reservations) {
                    this.reservations = parsed.reservations;
                    this.filteredReservations = [...this.reservations];
                    return true;
                }
            }
        } catch (error) {
            console.warn('Impossible de charger depuis le local:', error);
        }
        return false;
    }

    /**
     * Gestion du mode hors ligne
     */
    handleOfflineMode() {
        window.addEventListener('online', () => {
            this.showAlert('Connexion rétablie', 'success');
            this.refreshData();
        });

        window.addEventListener('offline', () => {
            this.showAlert('Mode hors ligne activé', 'warning');
        });
    }

    /**
     * Optimisation des performances
     */
    debounce(func, wait) {
        let timeout;
        return function executedFunction(...args) {
            const later = () => {
                clearTimeout(timeout);
                func(...args);
            };
            clearTimeout(timeout);
            timeout = setTimeout(later, wait);
        };
    }

    /**
     * Initialisation des animations
     */
    initializeAnimations() {
        // Animation d'apparition pour les nouvelles données
        const observer = new IntersectionObserver((entries) => {
            entries.forEach(entry => {
                if (entry.isIntersecting) {
                    entry.target.classList.add('fade-in');
                }
            });
        });

        // Observer les éléments animables
        document.querySelectorAll('.card, .table-responsive').forEach(el => {
            observer.observe(el);
        });
    }

    /**
     * Gestion des thèmes (clair/sombre)
     */
    toggleTheme() {
        const body = document.body;
        const isDark = body.classList.contains('dark-theme');
        
        if (isDark) {
            body.classList.remove('dark-theme');
            localStorage.setItem('theme', 'light');
        } else {
            body.classList.add('dark-theme');
            localStorage.setItem('theme', 'dark');
        }
    }

    /**
     * Application du thème sauvegardé
     */
    applyStoredTheme() {
        const storedTheme = localStorage.getItem('theme');
        if (storedTheme === 'dark') {
            document.body.classList.add('dark-theme');
        }
    }

    /**
     * Configuration des notifications push (simulation)
     */
    setupNotifications() {
        if ('Notification' in window) {
            Notification.requestPermission().then(permission => {
                if (permission === 'granted') {
                    console.log('Notifications activées');
                }
            });
        }
    }

    /**
     * Envoi d'une notification
     */
    sendNotification(title, message, type = 'info') {
        if ('Notification' in window && Notification.permission === 'granted') {
            new Notification(title, {
                body: message,
                icon: '/favicon.ico',
                badge: '/favicon.ico'
            });
        }
        
        // Fallback avec alert visuelle
        this.showAlert(`${title}: ${message}`, type);
    }

    /**
     * Méthodes utilitaires pour les développeurs
     */
    getDebugInfo() {
        return {
            version: '1.0.0',
            currentUser: this.currentUser,
            reservations: this.reservations.length,
            salles: this.salles.length,
            currentSection: this.currentSection,
            filters: {
                status: document.getElementById('statusFilter')?.value,
                salle: document.getElementById('salleFilter')?.value,
                date: document.getElementById('dateFilter')?.value,
                search: document.getElementById('searchFilter')?.value
            }
        };
    }

    /**
     * Réinitialisation complète de l'application
     */
    reset() {
        if (confirm('Êtes-vous sûr de vouloir réinitialiser toutes les données ?')) {
            localStorage.removeItem('reservationsApp');
            location.reload();
        }
    }

    /**
     * Statistiques d'utilisation
     */
    getUsageStats() {
        const now = new Date();
        const oneWeekAgo = new Date(now.getTime() - 7 * 24 * 60 * 60 * 1000);
        
        const weeklyReservations = this.reservations.filter(r => 
            new Date(r.dateDemande) >= oneWeekAgo
        );

        return {
            totalReservations: this.reservations.length,
            weeklyReservations: weeklyReservations.length,
            mostUsedRoom: this.getMostUsedRoom(),
            averageDuration: this.getAverageDuration(),
            validationRate: this.getValidationRate()
        };
    }

    /**
     * Salle la plus utilisée
     */
    getMostUsedRoom() {
        const roomUsage = {};
        this.reservations
            .filter(r => r.statut === 'Validee')
            .forEach(r => {
                roomUsage[r.salleName] = (roomUsage[r.salleName] || 0) + 1;
            });

        const mostUsed = Object.entries(roomUsage)
            .sort(([,a], [,b]) => b - a)[0];
        
        return mostUsed ? { name: mostUsed[0], count: mostUsed[1] } : null;
    }

    /**
     * Durée moyenne des réservations
     */
    getAverageDuration() {
        const validReservations = this.reservations.filter(r => r.statut === 'Validee');
        if (validReservations.length === 0) return 0;

        const totalMinutes = validReservations.reduce((sum, r) => {
            const start = new Date(`2000-01-01T${r.heureDebut}`);
            const end = new Date(`2000-01-01T${r.heureFin}`);
            return sum + (end - start) / (1000 * 60);
        }, 0);

        return Math.round(totalMinutes / validReservations.length);
    }

    /**
     * Taux de validation
     */
    getValidationRate() {
        const total = this.reservations.length;
        if (total === 0) return 0;

        const validated = this.reservations.filter(r => r.statut === 'Validee').length;
        return Math.round((validated / total) * 100);
    }

    /**
     * Méthode de nettoyage
     */
    cleanup() {
        // Nettoyer les écouteurs d'événements
        if (this.keydownHandler) {
            document.removeEventListener('keydown', this.keydownHandler);
        }
        
        // Nettoyer les timers
        if (this.refreshTimer) {
            clearInterval(this.refreshTimer);
        }
        
        console.log('Application nettoyée');
    }

    /**
     * Mise à jour de l'application
     */
    update() {
        console.log('🔄 Mise à jour de l\'application...');
        
        // Sauvegarder l'état actuel
        this.saveToLocalStorage();
        
        // Recharger les données
        this.loadSampleData();
        
        // Mettre à jour l'interface
        this.updateDashboard();
        this.loadRecentReservations();
        
        this.showAlert('Application mise à jour', 'success');
    }
}

// Fonctions globales pour la compatibilité avec l'HTML
window.showSection = (section) => window.app?.showSection(section);
window.showNewReservationModal = () => window.app?.showNewReservationModal();
window.filterReservations = (status) => window.app?.filterReservations(status);
window.exportData = () => window.app?.exportData();
window.logout = () => window.app?.logout();
window.processValidation = (approve) => window.app?.processValidation(approve);
window.submitNewReservation = () => window.app?.submitNewReservation();
window.applyFilters = () => window.app?.applyFilters();

// Initialisation de l'application quand le DOM est prêt
document.addEventListener('DOMContentLoaded', () => {
    try {
        window.app = new ReservationApp();
        console.log('🎉 Application de réservation initialisée avec succès');
        
        // Initialiser les fonctionnalités avancées
        window.app.handleOfflineMode();
        window.app.applyStoredTheme();
        window.app.setupNotifications();
        window.app.initializeAnimations();
        
    } catch (error) {
        console.error('❌ Erreur lors de l\'initialisation:', error);
        
        // Affichage d'une erreur utilisateur
        const errorDiv = document.createElement('div');
        errorDiv.className = 'alert alert-danger';
        errorDiv.innerHTML = `
            <h4>Erreur d'initialisation</h4>
            <p>L'application n'a pas pu se charger correctement. Veuillez rafraîchir la page.</p>
            <button class="btn btn-primary" onclick="location.reload()">Rafraîchir</button>
        `;
        document.body.insertBefore(errorDiv, document.body.firstChild);
    }
});

// Nettoyage avant le déchargement de la page
window.addEventListener('beforeunload', () => {
    if (window.app) {
        window.app.saveToLocalStorage();
        window.app.cleanup();
    }
});

// Gestion des erreurs non capturées
window.addEventListener('error', (event) => {
    console.error('Erreur JavaScript non gérée:', event.error);
    if (window.app) {
        window.app.handleError(event.error, 'Global Error Handler');
    }
});

// Gestion des promesses rejetées
window.addEventListener('unhandledrejection', (event) => {
    console.error('Promise rejetée:', event.reason);
    if (window.app) {
        window.app.handleError(new Error(event.reason), 'Unhandled Promise Rejection');
    }
    event.preventDefault();
});

// Export pour les modules ES6 (si nécessaire)
if (typeof module !== 'undefined' && module.exports) {
    module.exports = ReservationApp;
}
