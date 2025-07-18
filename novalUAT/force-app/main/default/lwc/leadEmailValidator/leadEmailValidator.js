import { LightningElement, track } from 'lwc';
import checkLeadByEmail from '@salesforce/apex/LeadEmailValidatorController.checkLeadByEmail';

export default class LeadEmailValidator extends LightningElement {
    @track email = '';
    @track resultMessage = '';
    @track isFound = null;

    handleInputChange(event) {
        this.email = event.target.value;
    }

    handleSearch() {
        if (!this.email) {
            this.resultMessage = 'Por favor ingrese un correo electrónico.';
            this.isFound = null;
            return;
        }

        checkLeadByEmail({ email: this.email })
            .then(result => {
                this.isFound = result;
                this.resultMessage = result ? 'Lead encontrado' : 'Lead No encontrado';
            })
            .catch(error => {
                this.resultMessage = 'Error al buscar el Lead.';
                this.isFound = null;
                console.error(error);
            });
    }

    get resultClass() {
        if (this.isFound === null) return '';
        return this.isFound ? 'success' : 'error';
    }
}