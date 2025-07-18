/*  Logica en caso de Broker
- Si es un broker y existe, asignamos el Id de la cuenta existente al lead.
    - Si es un broker y no existe, buscar si existe una cuenta con el mismo Company name del lead.
    - Si encuentra la cuenta, entonces convierte el broker asignando esa cuenta.
    - Si no encuentra la cuenta, entonces crea una nueva cuenta y convierte el broker asignando esa cuenta.
    
Logica en caso de Cliente
    - Si es un cliente y existe, asignamos el Id de la cuenta existente al lead.
    - Si es un cliente y no existe, crear una nueva cuenta tipo Household y convertir el cliente asignando esa cuenta.
    
 **Decidimos no convertir los leads si ya existen, para evitar mergiar leads basuras a una cuenta existente y depurada.
 ** Si se invoca esta clase de manera masiva, entonces debido al uso de Database.LeadConvert los chunk deben ser de un maximo de 50 registros
 */

public without sharing class PSG_LeadConvertion{
    
    @InvocableMethod(label = 'Convert Lead'description = 'Convierte Leads en Contacto y le asocia una cuenta')
    public static void convertLead(List<Id> leadIds){
        if (leadIds == null || leadIds.isEmpty()){
            return;
        }
        
        List<Lead> leads =[Select Id, FirstName, LastName, Email, PSG_Contact_Type__c, Company, Phone From Lead where id in :leadIds];
        
        List<Lead> LeadsToConvert = new List<Lead>();
        List<Lead> LeadsToUpdate = new List<Lead>();
        Map<Id, Id> leadIdWithContactIdMap = getExistingContactIdByEmail(leads);
        
        for (Lead lead : leads){
            if (String.isNotBlank(lead.Email)){
                if(leadIdWithContactIdMap.containsKey(lead.Id)){
                    Id contactId = leadIdWithContactIdMap.get(lead.Id);
                    lead.psg_Contact_Id__c = contactId;
                    LeadsToUpdate.add(lead);
                } else{
                    LeadsToConvert.add(lead);
                }
            }
        }
        
        if (!LeadsToConvert.isEmpty()){
            manageLeadConversion(LeadsToConvert);
        }
        
        if(!LeadsToUpdate.isEmpty()){
            update LeadsToUpdate;
        }
    }
    
    private static Map<Id, Id> getExistingContactIdByEmail(List<Lead> leads){
        Map<Id, Id> leadWithContactMap = new Map<Id, Id>();
        Map<String, Id> leadEmailsMap = new Map<String, Id>();
        Map<String, Id> leadPhoneMap = new Map<String, Id>();
        for (Lead lead : leads){
            if (String.isNotBlank(lead.Email)){
                leadEmailsMap.put(lead.Email, lead.Id);
            }
            if(String.isNotBlank(lead.Phone)){
                leadPhoneMap.put(lead.Phone, lead.Id);
            }
        }
        For(Contact con : [SELECT Id, Email, Name, Phone  FROM Contact WHERE Email IN :leadEmailsMap.keySet() or Phone IN :leadPhoneMap.keySet()]){
            Id leadId = leadEmailsMap.get(con.Email);
            if (leadId == null) {
                leadId = leadPhoneMap.get(con.Phone);
            }
            leadWithContactMap.put(leadId, con.Id);
        }
        
        return leadWithContactMap;
    }
    
    private static void manageLeadConversion(List<Lead> leads){
        List<Lead> brokerLeads = new List<Lead>();
        List<Lead> clientLeads = new List<Lead>();
        Id householdRecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Household').getRecordTypeId();
        Id businessRecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Company').getRecordTypeId();
        Id customerRecordTypeId = Schema.SObjectType.Contact.getRecordTypeInfosByName().get('Client').getRecordTypeId();
        Id brokerRecordTypeId = Schema.SObjectType.Contact.getRecordTypeInfosByName().get('Broker').getRecordTypeId();
        
        for(Lead lead : leads){
            If(lead.psg_Contact_Type__c.Contains('Broker')){
                brokerLeads.add(lead);
            } else if (lead.psg_Contact_Type__c.Contains('Client')){
                clientLeads.add(lead);
            }
        }
        
        manageBrokerConversion(brokerLeads, businessRecordTypeId, brokerRecordTypeId);
        manageClientConversion(clientLeads, householdRecordTypeId, customerRecordTypeId);
    }
    
    /*  Dado que ya sabemos que este lead no existe como contacto,
    buscamos si existe una cuenta con el mismo nombre de su compañía
        - Si existe, convertimos el lead asignando esa cuenta
        - Si no existe, creamos una nueva cuenta y convertimos el lead asignando esa cuenta
         */
    private static void manageBrokerConversion(List<Lead> brokerLeads, Id businessRecordTypeId, Id brokerRecordTypeId){
        Map<Id, Account> accountsToInsertMap = new Map<Id, Account>();
        List<Lead> leadsToConvert = new List<Lead>();
        Set<Id> contactIds = new Set<Id>();
        List<Contact> contactToUpdateRecordType = new List<Contact>();
        
        if(brokerLeads.isEmpty()){
            return;
        }
        
        Map<string, Account> accountsMap = getAccountsByLead(brokerLeads);
        for(Lead lead : brokerLeads){
            if(accountsMap.containsKey(lead.Company)){
                Id accountId = accountsMap.get(lead.Company).Id;
                Id contactId = convertLead(lead, accountId);
                if(contactId != null){
                    contactIds.add(contactId);
                    lead.psg_Contact_Id__c = contactId;
                }
            } else{
                Account newAccount = new Account(Name = lead.Company, Type = 'Broker', RecordTypeId = businessRecordTypeId);
                //Avoiding DML in loop
                accountsToInsertMap.put(lead.Id, newAccount);
                leadsToConvert.add(lead);
            }
        }
        
        if(!accountsToInsertMap.isEmpty()){
            insert accountsToInsertMap.values();
            for(Lead lead : leadsToConvert){
                Id accountId = accountsToInsertMap.get(lead.Id).Id;
                Id contactId = convertLead(lead, accountId);
                if(contactId != null){
                    contactIds.add(contactId);
                    lead.psg_Contact_Id__c = contactId;
                }
            }
        }
        
        if(!contactIds.isEmpty()){
            reAssignRecordType(contactIds, brokerRecordTypeId);
            update brokerLeads;
        }
        
    }
    
    /** Dado que ya sabemos que este lead no existe como contacto,
     *   creamos una nueva cuenta y convertimos el lead asignando esa cuenta
     *   creamos una opportunidad nueva si es necesario
     */
    private static void manageClientConversion(List<Lead> clientLeads, Id householdRecordTypeId, Id customerRecordTypeId){
        Map<Id, Account> accountsToInsertMap = new Map<Id, Account>();
        List<Lead> leadsToConvert = new List<Lead>();
        Set<Id> contactIds = new Set<Id>();
        List<Contact> contactToUpdateRecordType = new List<Contact>();
        List<Opportunity> opportunitiesToInsert = new List<Opportunity>();
        
        if(clientLeads.isEmpty()){
            return;
        }
        
        for(Lead lead : clientLeads){
            string accountName = lead.FirstName + lead.LastName;
            Account newAccount = new Account(Name = accountName, Type = 'Client', RecordTypeId = householdRecordTypeId);
            //Avoiding DML in loop
            accountsToInsertMap.put(lead.Id, newAccount);
            leadsToConvert.add(lead);
        }
        
        if(!accountsToInsertMap.isEmpty()){
            insert accountsToInsertMap.values();
            for(Lead lead : leadsToConvert){
                Id accountId = accountsToInsertMap.get(lead.Id).Id;
                Id contactId = convertLead(lead, accountId);
                if(contactId != null){
                    Opportunity newOpportunity = new Opportunity(
                        Name = lead.FirstName + ' ' + lead.LastName,
                    StageName = 'Interesado',
                    CloseDate = System.today().addDays(30),
                    AccountId = accountId,
                    psg_Contact__c = contactId
                        );
                    opportunitiesToInsert.add(newOpportunity);
                    contactIds.add(contactId);
                    lead.psg_Contact_Id__c = contactId;
                }
            }
        }
        
        if(!contactIds.isEmpty()){
            reAssignRecordType(contactIds, customerRecordTypeId);
            update clientLeads;
        }
        if(!opportunitiesToInsert.isEmpty()){
            insert opportunitiesToInsert;
        }
    }
    
    private static void reAssignRecordType(Set<Id> contactIds, Id recordType){
        List<Contact> contactsToUpdate = new List<Contact>();
        for (Contact c : [SELECT Id, RecordTypeId FROM Contact WHERE Id IN :contactIds]){
            if (c.RecordTypeId != recordType){
                c.RecordTypeId = recordType;
                contactsToUpdate.add(c);
            }
        }
        if (!contactsToUpdate.isEmpty()){
            update contactsToUpdate;
        }
    }
    
    private static Id convertLead(Lead lead, Id accountId){
        try{
            Database.LeadConvert lc = new Database.LeadConvert();
            lc.setLeadId(lead.Id);
            lc.setAccountId(accountId);
            lc.setDoNotCreateOpportunity(true);
            lc.setConvertedStatus('Qualified'); // Asegúrate de que este status exista
            //lc.setOpportunityName(lead.Company != null ? lead.Company : lead.Name);
            
            Database.LeadConvertResult lcr = Database.convertLead(lc);
            
            if (lcr.isSuccess()){
                return lcr.getContactId();
            } else{
                System.debug('Falló la conversión para Lead ' + lead.Id + ': ' + lcr.getErrors());
            }
        } catch (Exception e){
            System.debug('Excepción al convertir Lead ' + lead.Id + ': ' + e.getMessage());
        }
        return null;
    }
    
    private static Map<string, Account> getAccountsByLead(List<Lead> leads){
        Set<String> companyNames = new Set<String>();
        for (Lead lead : leads){
            if (String.isNotBlank(lead.Company)){
                companyNames.add(lead.Company);
            }
        }
        
        Map<string, Account> accountsMap = new Map<string, Account>();
        if (!companyNames.isEmpty()){
            List<Account> accounts = [SELECT Id, Name
                                      FROM Account
                                      WHERE Name IN :companyNames];
            for (Account acc : accounts){
                accountsMap.put(acc.Name, acc);
            }
        }
        return accountsMap;
    }
    
}