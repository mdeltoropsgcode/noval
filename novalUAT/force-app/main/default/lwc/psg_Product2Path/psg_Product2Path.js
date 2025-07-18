import { api, LightningElement, track } from 'lwc';
import { notifyRecordUpdateAvailable } from 'lightning/uiRecordApi';
import getStatuses from '@salesforce/apex/PSG_Product2PathHelper.getStatuses';
import getActualStatus from '@salesforce/apex/PSG_Product2PathHelper.getActualStatus';
import setStatus from '@salesforce/apex/PSG_Product2PathHelper.setStatus';
import getUserProfile from '@salesforce/apex/PSG_Product2PathHelper.getUserProfile'; // Nuevo método Apex

export default class Psg_Product2Path extends LightningElement {
    @api recordId
    @track actualStatus // Estado actual del backend (inmutable) - API Name
    @track selectedStatus // Estado seleccionado en el frontend (modificable) - API Name
    @track isLoading = false // Estado para mostrar el spinner
    @track isButtonDisabled = true; // Inicialmente deshabilitado
    statuses = [] // Array con objetos {value, label, index, className, etc.}

    // Método helper para obtener el label basado en el API name
    getStatusLabel(apiName) {
        const status = this.statuses.find(s => s.value === apiName);
        return status ? status.label : apiName;
    }

    // Getter para el texto del botón
    get buttonText() {
        // Si el actualStatus es null o undefined, mostrar texto para iniciar
        if (!this.actualStatus) {
            return 'Mark Status as Complete';
        }

        if (this.selectedStatus && this.selectedStatus !== this.actualStatus) {
            return `Mark as Current Status`;
        }

        // Si está en la etapa del backend, verificar si puede avanzar
        if (this.selectedStatus === this.actualStatus && this.statuses.length > 0) {
            const currentIndex = this.statuses.findIndex(s => s.value === this.actualStatus);
            if (currentIndex >= 0 && currentIndex < this.statuses.length - 1) {
                return 'Mark Status as Complete';
            } else {
                return 'Already at Final Stage';
            }
        }

        return 'Mark Status as Complete';
    }

    // Getter para habilitar/deshabilitar el botón
    get isButtonDisabled() {
        if (this.isLoading) return true;

        // Si el actualStatus es null, permitir que funcione el botón
        if (!this.actualStatus) {
            return false;
        }

        // Si está en la etapa del backend, verificar si es la última
        if (this.selectedStatus === this.actualStatus && this.statuses.length > 0) {
            const currentIndex = this.statuses.findIndex(s => s.value === this.actualStatus);
            return currentIndex >= this.statuses.length - 1; // Deshabilitar si es la última etapa
        }

        return false;
    }

    // Getter para mostrar/ocultar el spinner
    get showSpinner() {
        return this.isLoading;
    }

    // Método para determinar si mostrar el ícono de check
    showCheckIcon(status, index) {
        const actualIndex = this.statuses.findIndex(s => s.value === this.actualStatus);

        // No mostrar check si es la última etapa y es la etapa del backend
        if (index === actualIndex && index === this.statuses.length - 1) {
            return false;
        }

        // Mostrar check solo si tiene la clase slds-is-complete
        return status.isComplete;
    }

    connectedCallback() {
        Promise.all([this.fetchActualStatus(), this.fetchStatuses(), this.checkUserProfile()])
            .then(() => {
                // Inicializar selectedStatus con el valor del backend
                this.selectedStatus = this.actualStatus;

                this.statuses = this.statuses.map((status, index) => {
                    const className = this.getClassName(status.value, index);
                    const isComplete = className.includes('slds-is-complete');
                    const showCheck = this.shouldShowCheckIcon(index, isComplete);

                    return {
                        ...status, // Mantiene value y label
                        index: index,
                        className: className,
                        isComplete: isComplete,
                        showCheckIcon: showCheck
                    };
                });
                console.log('Statuses with classes:', JSON.stringify(this.statuses));
            })
            .catch(error => {
                console.error('Error initializing component:', error);
            });
    }

    checkUserProfile() {
        return getUserProfile()
            .then(profileName => {
                if (profileName === 'System Administrator') {
                    this.isButtonDisabled = false; // Habilitar el botón si es admin
                } else {
                    this.isButtonDisabled = true; // Deshabilitar el botón si no es admin
                }
            })
            .catch(error => {
                console.error('Error checking user profile:', error);
                this.isButtonDisabled = true; // Deshabilitar en caso de error
            });
    }

    // Método para determinar si mostrar el ícono de check
    shouldShowCheckIcon(index, isComplete) {
        const actualIndex = this.statuses.findIndex(s => s.value === this.actualStatus);

        // No mostrar check si es la última etapa y es la etapa del backend
        if (index === actualIndex && index === this.statuses.length - 1) {
            return false;
        }

        return isComplete;
    }

    fetchActualStatus() {
        return getActualStatus({ recordId: this.recordId })
            .then(result => {
                this.actualStatus = result;
            })
            .catch(error => {
                console.error('Error fetching actual status: ', error);
            });
    }

    fetchStatuses() {
        return getStatuses()
            .then(result => {
                // Ahora result es un array de objetos con {value, label}
                this.statuses = result.map((status, index) => {
                    return {
                        value: status.value,  // API Name
                        label: status.label,  // Label para mostrar
                        index: index
                    };
                });
            })
            .catch(error => {
                console.error('Error fetching statuses field options: ', error);
            });
    }

    updateStatus() {
        // Mostrar spinner
        this.isLoading = true;

        // Determinar el status a actualizar
        let statusToUpdate;
        if (this.selectedStatus === this.actualStatus) {
            // Si está en la etapa del backend, avanzar a la siguiente
            const currentIndex = this.statuses.findIndex(s => s.value === this.actualStatus);
            const nextIndex = currentIndex + 1;

            if (nextIndex < this.statuses.length) {
                statusToUpdate = this.statuses[nextIndex].value; // Usar API name
            } else {
                // Ya está en la última etapa
                console.warn('Already at the last stage');
                this.isLoading = false;
                return;
            }
        } else {
            // Si seleccionó una etapa diferente, usar esa
            statusToUpdate = this.selectedStatus;
        }

        setStatus({ recordId: this.recordId, newStatus: statusToUpdate })
            .then(() => {
                console.log('Status updated successfully to:', statusToUpdate);

                // Notificar al Lightning Data Service que el registro cambió
                notifyRecordUpdateAvailable([{ recordId: this.recordId }]);

                // Actualizar los datos locales
                this.actualStatus = statusToUpdate;
                this.selectedStatus = statusToUpdate;

                // Refrescar el componente
                this.refreshComponent();
            })
            .catch(error => {
                console.error('Error updating status:', error);
            })
            .finally(() => {
                // Ocultar spinner
                this.isLoading = false;
            });
    }

    // Método para refrescar el componente completo
    refreshComponent() {
        Promise.all([this.fetchActualStatus(), this.fetchStatuses()])
            .then(() => {
                this.selectedStatus = this.actualStatus;

                this.statuses = this.statuses.map((status, index) => {
                    const className = this.getClassName(status.value, index);
                    const isComplete = className.includes('slds-is-complete');
                    const showCheck = this.shouldShowCheckIcon(index, isComplete);

                    return {
                        ...status,
                        index: index,
                        className: className,
                        isComplete: isComplete,
                        showCheckIcon: showCheck
                    };
                });
            })
            .catch(error => {
                console.error('Error refreshing component:', error);
            });
    }

    // Método para refrescar las clases CSS
    refreshStatusClasses() {
        this.statuses = this.statuses.map((status, index) => {
            return {
                ...status,
                className: this.getClassName(status.value, index),
                isComplete: (this.getClassName(status.value, index)).includes('slds-is-complete')
            };
        });
    }

    getClassName(statusValue, index) {
        const actualIndex = this.statuses.findIndex(s => s.value === this.actualStatus);
        const selectedIndex = this.statuses.findIndex(s => s.value === this.selectedStatus);

        if (actualIndex === -1) {
            console.warn('Actual status not found in statuses:', this.actualStatus);
            return 'slds-path__item slds-is-incomplete';
        }

        // Si es la última etapa y es la etapa del backend, mantener sus clases fijas
        if (index === actualIndex && index === this.statuses.length - 1) {
            return 'slds-is-current slds-is-won slds-is-active slds-path__item runtime_sales_pathassistantPathAssistantTab';
        }

        // Si es la última etapa y está seleccionada (pero no es la etapa del backend)
        if (index === this.statuses.length - 1 && index === selectedIndex && this.selectedStatus !== this.actualStatus) {
            return 'slds-path__item slds-is-active';
        }

        // Si es el estado seleccionado (diferente al del backend) y NO es la última etapa
        if (index === selectedIndex && this.selectedStatus !== this.actualStatus && index !== this.statuses.length - 1) {
            return 'slds-path__item slds-is-active';
        }

        // Si es el estado actual del backend y es diferente al seleccionado y NO es la última etapa
        if (index === actualIndex && this.selectedStatus !== this.actualStatus && index !== this.statuses.length - 1) {
            return 'slds-path__item slds-is-current';
        }

        // Lógica normal: el estado del backend es el activo cuando no hay cambios y NO es la última etapa
        if (index === actualIndex && this.selectedStatus === this.actualStatus && index !== this.statuses.length - 1) {
            return 'slds-path__item slds-is-active';
        }

        // Estados completados (anteriores al estado del backend)
        if (index < actualIndex) {
            return 'slds-path__item slds-is-complete';
        }

        return 'slds-path__item slds-is-incomplete';
    }

    handleStatusClick(event) {
        const clickedStatusIndex = event.currentTarget.dataset.index;
        const clickedStatus = this.statuses.find(status => status.index === parseInt(clickedStatusIndex, 10));
        const actualIndex = this.statuses.findIndex(s => s.value === this.actualStatus);

        if (clickedStatus) {
            // Si se está en la última etapa y se intenta hacer click en la última etapa, no hacer nada
            if (actualIndex === this.statuses.length - 1 && parseInt(clickedStatusIndex, 10) === this.statuses.length - 1) {
                console.log('Cannot select the final stage when already at the final stage');
                return;
            }

            console.log('Estado seleccionado:', clickedStatus.label);
            // Actualizar solo el estado seleccionado (frontend) - usar API name
            this.selectedStatus = clickedStatus.value;

            // Refrescar las clases CSS
            this.refreshStatusClasses();
        } else {
            console.error('No se encontró el estado correspondiente al índice:', clickedStatusIndex);
        }
    }
}