/**
 * ============================================================================
 * Projet: Gestion des Réservations de Salles
 * Fichier: js/calendar.js
 * Description: Gestionnaire du calendrier FullCalendar
 * Date: 25 juin 2025
 * ============================================================================
 */

class CalendarManager {
    constructor() {
        this.calendar = null;
        this.calendarEl = null;
        this.events = [];
        this.currentView = 'dayGridMonth';
        this.isInitialized = false;
        
        this.init();
    }

    /**
     * Initialisation du gestionnaire de calendrier
     */
    init() {
        console.log('📅 Initialisation du gestionnaire de calendrier...');
        
        // Attendre que FullCalendar soit chargé
        this.waitForFullCalendar().then(() => {
            this.setupCalendar();
        }).catch(error => {
            console.error('Erreur lors du chargement de FullCalendar:', error);
        });
    }

    /**
     * Attend que FullCalendar soit disponible
     */
    waitForFullCalendar() {
        return new Promise((resolve, reject) => {
            let attempts = 0;
            const maxAttempts = 50;
            
            const checkFullCalendar = () => {
                if (window.FullCalendar) {
                    resolve();
                } else if (attempts < maxAttempts) {
                    attempts++;
                    setTimeout(checkFullCalendar, 100);
                } else {
                    reject(new Error('FullCalendar non disponible'));
                }
            };
            
            checkFullCalendar();
        });
    }

    /**
     * Configuration du calendrier
     */
    setupCalendar() {
        this.calendarEl = document.getElementById('calendar');
        if (!this.calendarEl) {
            console.warn('Élément calendrier non trouvé');
            return;
        }

        // Configuration du calendrier
        this.calendar = new FullCalendar.Calendar(this.calendarEl, {
            // Vue et navigation
            initialView: this.currentView,
            locale: 'fr',
            firstDay: 1, // Commencer par lundi
            
            // En-tête et navigation
            headerToolbar: {
                left: 'prev,next today',
                center: 'title',
                right: 'dayGridMonth,timeGridWeek,timeGridDay,listWeek'
            },
            
            // Boutons personnalisés
            customButtons: {
                exportButton: {
                    text: 'Export',
                    click: () => this.exportCalendar()
                },
                refreshButton: {
                    text: 'Actualiser',
                    click: () => this.refreshEvents()
                }
            },
            
            // Hauteur et style
            height: 'auto',
            aspectRatio: 1.8,
            
            // Gestion des événements
            events: (info, successCallback, failureCallback) => {
                try {
                    const events = this.getEventsForRange(info.start, info.end);
                    successCallback(events);
                } catch (error) {
                    console.error('Erreur lors du chargement des événements:', error);
                    failureCallback(error);
                }
            },
            
            // Interactions
            eventClick: (info) => this.handleEventClick(info),
            dateClick: (info) => this.handleDateClick(info),
            eventDidMount: (info) => this.handleEventMount(info),
            
            // Configuration des vues
            views: {
                dayGridMonth: {
                    titleFormat: { year: 'numeric', month: 'long' }
                },
                timeGridWeek: {
                    titleFormat: { week: 'long' },
                    slotMinTime: '06:00:00',
                    slotMaxTime: '22:00:00',
                    allDaySlot: false
                },
                timeGridDay: {
                    titleFormat: { weekday: 'long', month: 'long', day: 'numeric' },
                    slotMinTime: '06:00:00',
                    slotMaxTime: '22:00:00',
                    allDaySlot: false
                },
                listWeek: {
                    titleFormat: { week: 'long' }
                }
            },
            
            // Configuration de l'affichage des événements
            eventDisplay: 'block',
            dayMaxEvents: 3,
            moreLinkClick: 'popover',
            
            // Drag & Drop (désactivé pour cette version)
            editable: false,
            droppable: false,
            
            // Style des événements
            eventClassNames: (arg) => this.getEventClasses(arg.event),
            
            // Gestion des créneaux horaires
            slotDuration: '00:30:00',
            slotLabelInterval: '01:00:00',
            snapDuration: '00:15:00',
            
            // Textes en français
            buttonText: {
                today: 'Aujourd\'hui',
                month: 'Mois',
                week: 'Semaine',
                day: 'Jour',
                list: 'Liste'
            },
            
            // Format des heures
            slotLabelFormat: {
                hour: '2-digit',
                minute: '2-digit',
                hour12: false
            },
            
            // Loading
            loading: (isLoading) => this.handleLoading(isLoading),
            
            // Gestion des erreurs
            eventSourceFailure: (error) => this.handleError(error)
        });

        // Rendu initial
        this.calendar.render();
        this.isInitialized = true;
        
        console.log('✅ Calendrier initialisé avec succès');
    }

    /**
     * Récupère les événements pour une plage de dates
     */
    getEventsForRange(start, end) {
        if (!window.app || !window.app.reservations) {
            return [];
        }

        return window.app.reservations
            .filter(reservation => {
                const eventDate = new Date(reservation.date);
                return eventDate >= start && eventDate <= end;
            })
            .map(reservation => this.convertReservationToEvent(reservation));
    }

    /**
     * Convertit une réservation en événement calendrier
     */
    convertReservationToEvent(reservation) {
        return {
            id: `reservation-${reservation.id}`,
            title: this.formatEventTitle(reservation),
            start: `${reservation.date}T${reservation.heureDebut}`,
            end: `${reservation.date}T${reservation.heureFin}`,
            backgroundColor: this.getEventColor(reservation.statut),
            borderColor: this.getEventBorderColor(reservation.statut),
            textColor: this.getEventTextColor(reservation.statut),
            classNames: [`status-${reservation.statut.toLowerCase()}`],
            extendedProps: {
                reservation: reservation,
                type: 'reservation'
            }
        };
    }

    /**
     * Formate le titre de l'événement
     */
    formatEventTitle(reservation) {
        const salleShort = reservation.salleName.replace('Salle ', '');
        return `${salleShort} - ${reservation.objet}`;
    }

    /**
     * Retourne la couleur de l'événement selon le statut
     */
    getEventColor(statut) {
        const colors = {
            'Validee': '#27ae60',      // Vert
            'En_Attente': '#f39c12',   // Orange
            'Refusee': '#e74c3c',      // Rouge
            'Annulee': '#95a5a6'       // Gris
        };
        return colors[statut] || '#3498db';
    }

    /**
     * Retourne la couleur de bordure selon le statut
     */
    getEventBorderColor(statut) {
        const colors = {
            'Validee': '#219a52',
            'En_Attente': '#e67e22',
            'Refusee': '#c0392b',
            'Annulee': '#7f8c8d'
        };
        return colors[statut] || '#2980b9';
    }

    /**
     * Retourne la couleur du texte selon le statut
     */
    getEventTextColor(statut) {
        return '#ffffff'; // Blanc pour tous les statuts
    }

    /**
     * Retourne les classes CSS pour un événement
     */
    getEventClasses(event) {
        const classes = ['reservation-event'];
        
        if (event.extendedProps.reservation) {
            const reservation = event.extendedProps.reservation;
            classes.push(`status-${reservation.statut.toLowerCase()}`);
            classes.push(`type-${reservation.typeEventName.toLowerCase().replace(/\s+/g, '-')}`);
        }
        
        return classes;
    }

    /**
     * Gère le clic sur un événement
     */
    handleEventClick(info) {
        info.jsEvent.preventDefault();
        
        const reservation = info.event.extendedProps.reservation;
        if (reservation && window.app) {
            window.app.showReservationDetails(reservation.id);
        }
    }

    /**
     * Gère le clic sur une date
     */
    handleDateClick(info) {
        // Ouvrir le modal de nouvelle réservation avec la date pré-remplie
        if (window.app) {
            const dateInput = document.getElementById('reservationDate');
            if (dateInput) {
                dateInput.value = info.dateStr;
            }
            window.app.showNewReservationModal();
        }
    }

    /**
     * Gère l'affichage d'un événement
     */
    handleEventMount(info) {
        const reservation = info.event.extendedProps.reservation;
        if (!reservation) return;

        // Ajouter un tooltip
        const tooltip = this.createEventTooltip(reservation);
        info.el.setAttribute('title', tooltip);
        info.el.setAttribute('data-bs-toggle', 'tooltip');
        info.el.setAttribute('data-bs-placement', 'top');
        
        // Initialiser le tooltip Bootstrap
        new bootstrap.Tooltip(info.el);

        // Ajouter des classes CSS personnalisées
        info.el.classList.add('reservation-event');
        info.el.classList.add(`priority-${this.getEventPriority(reservation)}`);
        
        // Ajouter un indicateur de statut
        const statusIndicator = document.createElement('span');
        statusIndicator.className = `status-indicator status-${reservation.statut.toLowerCase()}`;
        statusIndicator.textContent = '●';
        info.el.querySelector('.fc-event-title').prepend(statusIndicator);
    }

    /**
     * Crée le tooltip pour un événement
     */
    createEventTooltip(reservation) {
        return `
            📍 ${reservation.salleName}
            👤 ${reservation.userName}
            🕐 ${reservation.heureDebut} - ${reservation.heureFin}
            📝 ${reservation.objet}
            📊 ${window.app.getStatusText(reservation.statut)}
        `.replace(/\s+/g, ' ').trim();
    }

    /**
     * Détermine la priorité d'un événement
     */
    getEventPriority(reservation) {
        if (reservation.statut === 'En_Attente') return 'high';
        if (reservation.statut === 'Validee') return 'medium';
        return 'low';
    }

    /**
     * Gère l'état de chargement
     */
    handleLoading(isLoading) {
        const calendarContainer = this.calendarEl?.closest('.calendar-container');
        if (!calendarContainer) return;

        if (isLoading) {
            calendarContainer.classList.add('loading');
            this.showLoadingSpinner();
        } else {
            calendarContainer.classList.remove('loading');
            this.hideLoadingSpinner();
        }
    }

    /**
     * Affiche le spinner de chargement
     */
    showLoadingSpinner() {
        const existing = document.querySelector('.calendar-loading');
        if (existing) return;

        const spinner = document.createElement('div');
        spinner.className = 'calendar-loading';
        spinner.innerHTML = `
            <div class="d-flex justify-content-center">
                <div class="spinner-border text-primary" role="status">
                    <span class="visually-hidden">Chargement...</span>
                </div>
            </div>
        `;
        
        this.calendarEl.appendChild(spinner);
    }

    /**
     * Masque le spinner de chargement
     */
    hideLoadingSpinner() {
        const spinner = document.querySelector('.calendar-loading');
        if (spinner) {
            spinner.remove();
        }
    }

    /**
     * Gère les erreurs du calendrier
     */
    handleError(error) {
        console.error('Erreur calendrier:', error);
        if (window.app) {
            window.app.showAlert('Erreur lors du chargement du calendrier', 'danger');
        }
    }

    /**
     * Rafraîchit les événements
     */
    refreshEvents() {
        if (this.calendar) {
            this.calendar.refetchEvents();
        }
    }

    /**
     * Ajoute une nouvelle réservation au calendrier
     */
    addReservation(reservation) {
        if (!this.calendar) return;

        const event = this.convertReservationToEvent(reservation);
        this.calendar.addEvent(event);
    }

    /**
     * Met à jour une réservation dans le calendrier
     */
    updateReservation(reservation) {
        if (!this.calendar) return;

        const eventId = `reservation-${reservation.id}`;
        const existingEvent = this.calendar.getEventById(eventId);
        
        if (existingEvent) {
            // Mettre à jour les propriétés de l'événement
            existingEvent.setProp('backgroundColor', this.getEventColor(reservation.statut));
            existingEvent.setProp('borderColor', this.getEventBorderColor(reservation.statut));
            existingEvent.setExtendedProp('reservation', reservation);
        } else {
            // Ajouter l'événement s'il n'existe pas
            this.addReservation(reservation);
        }
    }

    /**
     * Supprime une réservation du calendrier
     */
    removeReservation(reservationId) {
        if (!this.calendar) return;

        const eventId = `reservation-${reservationId}`;
        const event = this.calendar.getEventById(eventId);
        
        if (event) {
            event.remove();
        }
    }

    /**
     * Change la vue du calendrier
     */
    changeView(viewName) {
        if (!this.calendar) return;

        this.calendar.changeView(viewName);
        this.currentView = viewName;
    }

    /**
     * Navigue vers une date spécifique
     */
    goToDate(date) {
        if (!this.calendar) return;

        this.calendar.gotoDate(date);
    }

    /**
     * Navigue vers aujourd'hui
     */
    goToToday() {
        if (!this.calendar) return;

        this.calendar.today();
    }

    /**
     * Navigue vers le mois précédent
     */
    goToPrevious() {
        if (!this.calendar) return;

        this.calendar.prev();
    }

    /**
     * Navigue vers le mois suivant
     */
    goToNext() {
        if (!this.calendar) return;

        this.calendar.next();
    }

    /**
     * Exporte le calendrier en PDF
     */
    exportCalendar() {
        try {
            const { jsPDF } = window.jspdf;
            const doc = new jsPDF();

            // Configuration
            doc.setFontSize(16);
            doc.text('Calendrier des Réservations', 20, 20);
            
            doc.setFontSize(12);
            const currentDate = new Date().toLocaleDateString('fr-FR');
            doc.text(`Généré le: ${currentDate}`, 20, 35);

            // Vue actuelle
            const viewTitle = this.calendar.view.title;
            doc.text(`Période: ${viewTitle}`, 20, 50);

            // Liste des événements visibles
            const events = this.calendar.getEvents();
            let yPosition = 70;

            doc.setFontSize(14);
            doc.text('Réservations:', 20, yPosition);
            yPosition += 15;

            doc.setFontSize(10);
            events.forEach(event => {
                if (yPosition > 270) {
                    doc.addPage();
                    yPosition = 20;
                }

                const startDate = event.start.toLocaleDateString('fr-FR');
                const startTime = event.start.toLocaleTimeString('fr-FR', { hour: '2-digit', minute: '2-digit' });
                const endTime = event.end ? event.end.toLocaleTimeString('fr-FR', { hour: '2-digit', minute: '2-digit' }) : '';
                
                doc.text(`${startDate} ${startTime}-${endTime}: ${event.title}`, 25, yPosition);
                yPosition += 10;
            });

            doc.save('calendrier-reservations.pdf');
            
            if (window.app) {
                window.app.showAlert('Calendrier exporté en PDF', 'success');
            }
        } catch (error) {
            console.error('Erreur export calendrier:', error);
            if (window.app) {
                window.app.showAlert('Erreur lors de l\'export du calendrier', 'danger');
            }
        }
    }

    /**
     * Filtre les événements par statut
     */
    filterByStatus(status) {
        if (!this.calendar) return;

        const events = this.calendar.getEvents();
        
        events.forEach(event => {
            const reservation = event.extendedProps.reservation;
            if (reservation) {
                if (!status || reservation.statut === status) {
                    event.setProp('display', 'auto');
                } else {
                    event.setProp('display', 'none');
                }
            }
        });
    }

    /**
     * Filtre les événements par salle
     */
    filterBySalle(salleId) {
        if (!this.calendar) return;

        const events = this.calendar.getEvents();
        
        events.forEach(event => {
            const reservation = event.extendedProps.reservation;
            if (reservation) {
                if (!salleId || reservation.salleId.toString() === salleId) {
                    event.setProp('display', 'auto');
                } else {
                    event.setProp('display', 'none');
                }
            }
        });
    }

    /**
     * Filtre les événements par utilisateur
     */
    filterByUser(userId) {
        if (!this.calendar) return;

        const events = this.calendar.getEvents();
        
        events.forEach(event => {
            const reservation = event.extendedProps.reservation;
            if (reservation) {
                if (!userId || reservation.userId.toString() === userId) {
                    event.setProp('display', 'auto');
                } else {
                    event.setProp('display', 'none');
                }
            }
        });
    }

    /**
     * Efface tous les filtres
     */
    clearFilters() {
        if (!this.calendar) return;

        const events = this.calendar.getEvents();
        events.forEach(event => {
            event.setProp('display', 'auto');
        });
    }

    /**
     * Recherche d'événements
     */
    searchEvents(query) {
        if (!this.calendar) return;

        const searchTerms = query.toLowerCase().split(' ');
        const events = this.calendar.getEvents();
        
        events.forEach(event => {
            const reservation = event.extendedProps.reservation;
            if (reservation) {
                const searchableText = [
                    reservation.objet,
                    reservation.userName,
                    reservation.salleName,
                    reservation.typeEventName
                ].join(' ').toLowerCase();
                
                const matches = searchTerms.every(term => searchableText.includes(term));
                event.setProp('display', matches ? 'auto' : 'none');
            }
        });
    }

    /**
     * Obtient les statistiques des événements visibles
     */
    getVisibleEventsStats() {
        if (!this.calendar) return null;

        const events = this.calendar.getEvents();
        const visibleEvents = events.filter(event => 
            event.display !== 'none' && event.extendedProps.reservation
        );

        const stats = {
            total: visibleEvents.length,
            validee: 0,
            en_attente: 0,
            refusee: 0,
            annulee: 0
        };

        visibleEvents.forEach(event => {
            const statut = event.extendedProps.reservation.statut;
            stats[statut.toLowerCase()] = (stats[statut.toLowerCase()] || 0) + 1;
        });

        return stats;
    }

    /**
     * Obtient les créneaux libres pour une date
     */
    getAvailableSlots(date, salleId = null) {
        if (!this.calendar || !window.app) return [];

        const targetDate = new Date(date);
        const dayEvents = this.calendar.getEvents().filter(event => {
            const eventDate = new Date(event.start);
            const reservation = event.extendedProps.reservation;
            
            return eventDate.toDateString() === targetDate.toDateString() &&
                   reservation &&
                   reservation.statut !== 'Annulee' &&
                   reservation.statut !== 'Refusee' &&
                   (!salleId || reservation.salleId.toString() === salleId);
        });

        // Génération des créneaux disponibles (logique simplifiée)
        const workingHours = [];
        for (let hour = 8; hour < 18; hour++) {
            for (let minute = 0; minute < 60; minute += 30) {
                const timeSlot = `${hour.toString().padStart(2, '0')}:${minute.toString().padStart(2, '0')}`;
                
                const isOccupied = dayEvents.some(event => {
                    const startTime = event.start.toTimeString().substring(0, 5);
                    const endTime = event.end ? event.end.toTimeString().substring(0, 5) : startTime;
                    return timeSlot >= startTime && timeSlot < endTime;
                });

                if (!isOccupied) {
                    workingHours.push(timeSlot);
                }
            }
        }

        return workingHours;
    }

    /**
     * Suggère des créneaux optimaux
     */
    suggestOptimalSlots(duration = 60, salleId = null) {
        const today = new Date();
        const suggestions = [];

        // Chercher les 7 prochains jours
        for (let day = 0; day < 7; day++) {
            const checkDate = new Date(today);
            checkDate.setDate(today.getDate() + day);
            
            const availableSlots = this.getAvailableSlots(checkDate, salleId);
            
            // Grouper les créneaux consécutifs
            const consecutiveSlots = this.findConsecutiveSlots(availableSlots, duration);
            
            consecutiveSlots.forEach(slot => {
                suggestions.push({
                    date: checkDate.toISOString().split('T')[0],
                    startTime: slot.start,
                    endTime: slot.end,
                    duration: slot.duration,
                    score: this.calculateSlotScore(checkDate, slot.start)
                });
            });
        }

        // Trier par score (meilleurs créneaux en premier)
        return suggestions.sort((a, b) => b.score - a.score).slice(0, 5);
    }

    /**
     * Trouve les créneaux consécutifs
     */
    findConsecutiveSlots(slots, requiredDuration) {
        const consecutive = [];
        
        for (let i = 0; i < slots.length; i++) {
            const startSlot = slots[i];
            let duration = 30; // Durée de base d'un créneau
            let endSlot = startSlot;
            
            // Chercher les créneaux consécutifs
            for (let j = i + 1; j < slots.length; j++) {
                const nextSlot = slots[j];
                const currentEnd = this.addMinutesToTime(endSlot, 30);
                
                if (nextSlot === currentEnd) {
                    duration += 30;
                    endSlot = nextSlot;
                } else {
                    break;
                }
            }
            
            // Ajouter si la durée est suffisante
            if (duration >= requiredDuration) {
                consecutive.push({
                    start: startSlot,
                    end: this.addMinutesToTime(startSlot, requiredDuration),
                    duration: requiredDuration
                });
            }
        }
        
        return consecutive;
    }

    /**
     * Ajoute des minutes à une heure
     */
    addMinutesToTime(timeString, minutes) {
        const [hours, mins] = timeString.split(':').map(Number);
        const totalMinutes = hours * 60 + mins + minutes;
        const newHours = Math.floor(totalMinutes / 60);
        const newMinutes = totalMinutes % 60;
        
        return `${newHours.toString().padStart(2, '0')}:${newMinutes.toString().padStart(2, '0')}`;
    }

    /**
     * Calcule le score d'un créneau
     */
    calculateSlotScore(date, startTime) {
        let score = 0;
        
        // Préférer les jours de semaine
        const dayOfWeek = date.getDay();
        if (dayOfWeek >= 1 && dayOfWeek <= 5) {
            score += 10;
        }
        
        // Préférer les heures ouvrables
        const hour = parseInt(startTime.split(':')[0]);
        if (hour >= 9 && hour <= 16) {
            score += 15;
        } else if (hour >= 8 && hour <= 17) {
            score += 10;
        }
        
        // Préférer les créneaux plus proches
        const daysDiff = Math.ceil((date - new Date()) / (1000 * 60 * 60 * 24));
        score += Math.max(0, 10 - daysDiff);
        
        return score;
    }

    /**
     * Génère une vue miniature du calendrier
     */
    generateMiniCalendar(containerId) {
        const container = document.getElementById(containerId);
        if (!container) return;

        const miniCalendar = new FullCalendar.Calendar(container, {
            initialView: 'dayGridMonth',
            height: 300,
            headerToolbar: {
                left: 'prev,next',
                center: 'title',
                right: ''
            },
            events: this.getEventsForRange.bind(this),
            eventClick: this.handleEventClick.bind(this),
            dateClick: this.handleDateClick.bind(this),
            locale: 'fr'
        });

        miniCalendar.render();
        return miniCalendar;
    }

    /**
     * Synchronise avec un calendrier externe (simulation)
     */
    syncWithExternalCalendar(provider = 'google') {
        console.log(`🔄 Synchronisation avec ${provider} Calendar...`);
        
        // Simulation de synchronisation
        setTimeout(() => {
            if (window.app) {
                window.app.showAlert(`Synchronisation avec ${provider} Calendar terminée`, 'success');
            }
            this.refreshEvents();
        }, 2000);
    }

    /**
     * Exporte les événements au format iCal
     */
    exportToICal() {
        if (!this.calendar) return;

        const events = this.calendar.getEvents();
        let icalContent = [
            'BEGIN:VCALENDAR',
            'VERSION:2.0',
            'PRODID:-//Gestion Reservations//Calendar//FR',
            'CALSCALE:GREGORIAN'
        ];

        events.forEach(event => {
            const reservation = event.extendedProps.reservation;
            if (reservation) {
                const startDate = event.start.toISOString().replace(/[-:]/g, '').split('.')[0] + 'Z';
                const endDate = event.end ? event.end.toISOString().replace(/[-:]/g, '').split('.')[0] + 'Z' : startDate;
                
                icalContent.push(
                    'BEGIN:VEVENT',
                    `UID:reservation-${reservation.id}@reservations.local`,
                    `DTSTART:${startDate}`,
                    `DTEND:${endDate}`,
                    `SUMMARY:${event.title}`,
                    `DESCRIPTION:${reservation.objet} - ${reservation.typeEventName}`,
                    `LOCATION:${reservation.salleName}`,
                    `STATUS:${reservation.statut}`,
                    'END:VEVENT'
                );
            }
        });

        icalContent.push('END:VCALENDAR');

        // Télécharger le fichier
        const blob = new Blob([icalContent.join('\r\n')], { type: 'text/calendar' });
        const url = URL.createObjectURL(blob);
        
        const a = document.createElement('a');
        a.href = url;
        a.download = 'reservations.ics';
        document.body.appendChild(a);
        a.click();
        document.body.removeChild(a);
        URL.revokeObjectURL(url);

        if (window.app) {
            window.app.showAlert('Calendrier exporté au format iCal', 'success');
        }
    }

    /**
     * Configuration des raccourcis clavier pour le calendrier
     */
    setupKeyboardShortcuts() {
        document.addEventListener('keydown', (e) => {
            // Seulement si le calendrier est visible
            if (window.app && window.app.currentSection !== 'calendar') return;

            if (e.ctrlKey || e.metaKey) {
                switch(e.key) {
                    case 'ArrowLeft':
                        e.preventDefault();
                        this.goToPrevious();
                        break;
                    case 'ArrowRight':
                        e.preventDefault();
                        this.goToNext();
                        break;
                    case 'Home':
                        e.preventDefault();
                        this.goToToday();
                        break;
                }
            }

            // Touches simples
            switch(e.key) {
                case 'm':
                    if (document.activeElement.tagName !== 'INPUT') {
                        this.changeView('dayGridMonth');
                    }
                    break;
                case 'w':
                    if (document.activeElement.tagName !== 'INPUT') {
                        this.changeView('timeGridWeek');
                    }
                    break;
                case 'd':
                    if (document.activeElement.tagName !== 'INPUT') {
                        this.changeView('timeGridDay');
                    }
                    break;
            }
        });
    }

    /**
     * Rendu du calendrier
     */
    render() {
        if (this.calendar && this.isInitialized) {
            this.calendar.render();
            this.refreshEvents();
        }
    }

    /**
     * Destruction du calendrier
     */
    destroy() {
        if (this.calendar) {
            this.calendar.destroy();
            this.calendar = null;
            this.isInitialized = false;
        }
    }

    /**
     * Redimensionnement du calendrier
     */
    resize() {
        if (this.calendar) {
            this.calendar.updateSize();
        }
    }

    /**
     * Méthodes de debugging
     */
    getDebugInfo() {
        return {
            isInitialized: this.isInitialized,
            currentView: this.currentView,
            eventsCount: this.calendar ? this.calendar.getEvents().length : 0,
            calendarEl: !!this.calendarEl
        };
    }
}

// Gestion du redimensionnement de la fenêtre
window.addEventListener('resize', () => {
    if (window.calendarManager) {
        window.calendarManager.resize();
    }
});

// Initialisation quand le DOM est prêt
document.addEventListener('DOMContentLoaded', () => {
    // Attendre un peu pour s'assurer que FullCalendar est chargé
    setTimeout(() => {
        try {
            window.calendarManager = new CalendarManager();
            console.log('📅 Gestionnaire de calendrier initialisé');
        } catch (error) {
            console.error('❌ Erreur lors de l\'initialisation du calendrier:', error);
        }
    }, 500);
});

// Export pour les modules ES6
if (typeof module !== 'undefined' && module.exports) {
    module.exports = CalendarManager;
}