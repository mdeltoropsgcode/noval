public without sharing class PSG_ConvertLeadController {
    
    @AuraEnabled
    public static Id convertLeadToContact(Id leadId) {
        if(leadId == null) {
            throw new AuraHandledException('Lead ID no puede ser nulo.');
        }
        Lead leadBeforeConvertion = [SELECT Id, psg_Contact_Type__c, Owner.Type FROM Lead WHERE Id = :leadId LIMIT 1];
        if(leadBeforeConvertion.psg_Contact_Type__c == null) {
            throw new AuraHandledException('El tipo de contacto del lead no está definido.');
        }
        if(leadBeforeConvertion.psg_Contact_Type__c != 'Client' && leadBeforeConvertion.psg_Contact_Type__c != 'Broker') {
            throw new AuraHandledException('El tipo de contacto del lead debe ser \'Client\' o \'Broker\'.');
        }
        if(leadBeforeConvertion.Owner.Type == 'Queue'){
            Id currentUserId = UserInfo.getUserId ();
            leadBeforeConvertion.OwnerId = currentUserId;
            Update leadBeforeConvertion;
        }
        
        PSG_LeadConvertion.convertLead(new List<Id>{leadId});
        Lead lead = [SELECT Id, psg_Contact_Id__c FROM Lead WHERE Id = :leadId LIMIT 1];
        if (lead.psg_Contact_Id__c != null) {
            return lead.psg_Contact_Id__c;
        } else {
            throw new AuraHandledException('La conversión del lead ha fallado, favor contactar su administrador.');
        }
    }
    
    @AuraEnabled
    public static void moveLeadStage(Id leadId) {
        if(leadId == null) {
            throw new AuraHandledException('Lead ID no puede ser nulo.');
        }
        Lead lead = [SELECT Id, Status FROM Lead WHERE Id = :leadId LIMIT 1];
        if (lead.Status == 'Unqualified') {
            lead.Status = 'New';
        } else if (lead.Status == 'New') {
            lead.Status = 'Working';
        } else if (lead.Status == 'Working') {
            lead.Status = 'Nurturing';
        } else{
            throw new AuraHandledException('El lead ya ha alcanzado la etapa final o no está en una etapa válida para avanzar.');
        }
        update lead;
    }
}