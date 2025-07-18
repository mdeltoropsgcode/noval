import { LightningElement, api } from 'lwc';
import convertLeadToContact from '@salesforce/apex/PSG_ConvertLeadController.convertLeadToContact';
import moveLeadStage from '@salesforce/apex/PSG_ConvertLeadController.moveLeadStage';
import { NavigationMixin } from 'lightning/navigation';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';

export default class PsgConvertLeadFromRecordPage extends NavigationMixin(LightningElement) {
    @api recordId;
    isLoading = false;
    errorMessage;

    handleConvertLead() {
        this.isLoading = true;
        convertLeadToContact({ leadId: this.recordId })
            .then(contactId => {
                this.isLoading = false;
                this[NavigationMixin.Navigate]({
                    type: 'standard__recordPage',
                    attributes: {
                        recordId: contactId,
                        objectApiName: 'Contact',
                        actionName: 'view'
                    }
                });
            })
            .catch(error => {
                this.isLoading = false;
                this.errorMessage = error.body.message;
                const evt = new ShowToastEvent({
                    title: 'Error',
                    message: error.body.message,
                    variant: 'error'
                });
                this.dispatchEvent(evt);
            });
    }

    handleNextStage() {
        this.isLoading = true;
        moveLeadStage({ leadId: this.recordId })
            .then(() => {
                this.isLoading = false;
                const evt = new ShowToastEvent({
                    title: 'Success',
                    message: 'Etapa avanzada exitosamente.',
                    variant: 'success'
                });
                this.dispatchEvent(evt);
                //Reload page to reflect changes
                this[NavigationMixin.Navigate]({
                    type: 'standard__recordPage',
                    attributes: {
                        recordId: this.recordId,
                        objectApiName: 'Lead',
                        actionName: 'view'
                    }
                });
            })
            .catch(error => {
                this.isLoading = false;
                this.errorMessage = error.body.message;
                const evt = new ShowToastEvent({
                    title: 'Error',
                    message: error.body.message,
                    variant: 'error'
                });
                this.dispatchEvent(evt);
            }); 
    }
}