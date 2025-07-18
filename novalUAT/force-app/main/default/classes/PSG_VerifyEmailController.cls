public without sharing class PSG_VerifyEmailController {
    @AuraEnabled
    public static void verifyLeadEmail(String leadId) {
        try {
            Logger.createLog('Verify Lead Email', 'PSG_VerifyEmailController', 'verifyLeadEmail', leadId, 'info');
            List<Lead> leads = [SELECT Id, psg_VerifiedEmail__c FROM Lead WHERE Id = :leadId];
            if (leads.isEmpty()) {
                throw new AuraHandledException('Lead no encontrado.');
            }
            Lead ld = leads[0];
            ld.psg_VerifiedEmail__c = true;
            update ld;
        } catch(Exception e) {
            Logger.createLog('Verify Lead Email', 'PSG_VerifyEmailController', 'verifyLeadEmail', e.getMessage(), 'error');
            throw new AuraHandledException('Error al verificar el correo: ' + e.getMessage());
        }
    }
}