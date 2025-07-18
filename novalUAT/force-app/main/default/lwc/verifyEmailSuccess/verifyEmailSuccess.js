import { LightningElement, wire, api } from 'lwc';
import { CurrentPageReference } from 'lightning/navigation';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import verifyEmail from '@salesforce/apex/PSG_VerifyEmailController.verifyLeadEmail';

export default class VerifyEmailSuccess extends LightningElement {
    @api recordId;

    @wire(CurrentPageReference)
    currentPageReference;
    
    async connectedCallback() {
        this.recordId = this.currentPageReference.state.c__recordId;
        if (this.recordId) {
            console.log('Record ID:', this.recordId);
        } else {
            console.error('No se encontró el recordId en la URL');
        }
        if (this.recordId) {
            this.verifyEmail();
        }
    }

    async verifyEmail() {
        if (!this.recordId) return;

        try {
            console.log('Invoking class Record ID:', this.recordId);
            await verifyEmail({ leadId: this.recordId });
            console.log('✅ Campo psg_VerifiedEmail__c actualizado correctamente a TRUE');
        } catch(error) {
            console.error('❌ Error al actualizar:', error);
            // this.dispatchEvent(
            //     new ShowToastEvent({
            //         title: 'Error',
            //         message: 'No se pudo verificar el correo: ' + error.body.message,
            //         variant: 'error'
            //     })
            // );
        }
    }
}