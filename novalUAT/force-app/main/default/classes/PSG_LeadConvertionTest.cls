@isTest
private class PSG_LeadConvertionTest {

    @testSetup
    static void setupTestData() {
        Id householdRT = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Household').getRecordTypeId();
        Id companyRT = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Company').getRecordTypeId();
        Id clientContactRT = Schema.SObjectType.Contact.getRecordTypeInfosByName().get('Client').getRecordTypeId();
        Id brokerContactRT = Schema.SObjectType.Contact.getRecordTypeInfosByName().get('Broker').getRecordTypeId();

        Account acc = new Account(Name = 'ExistingBrokerCo', Type = 'Broker', RecordTypeId = companyRT);
        insert acc;
        
        Account acc2 = new Account(Name = 'ExistingHousehold', Type = 'Household', RecordTypeId = householdRT);
        insert acc2;
        
        // Existing Contact for duplicate email test
        Contact con = new Contact(FirstName = 'Jane', LastName = 'Doe', Email = 'existing@example.com', RecordTypeId = brokerContactRT, AccountId=acc.Id);
        insert con;   
        
        Contact con2 = new Contact(FirstName = 'John', LastName = 'Doen', Email = 'existingContact@example.com', RecordTypeId = clientContactRT, AccountId=acc2.Id);
        insert con2; 
    }
    
    @isTest
    static void testConvertLead_Broker_NewAccount() {
        Lead brokerLead = new Lead(
            FirstName = 'Charlie',
            LastName = 'Chaplin',
            Email = 'charlie@example.com',
            Company = 'NewBrokerCo',
            Status = 'Open - Not Contacted',
            psg_Contact_Type__c = 'Broker'
        );
        insert brokerLead;

        List<Id> leadIds = new List<Id>();
        leadIds.add(brokerLead.Id);
        
        Test.startTest();
        PSG_LeadConvertion.convertLead(leadIds);
        Test.stopTest();

        Lead updatedLead = [SELECT psg_Contact_Id__c FROM Lead WHERE Id = :brokerLead.Id];
        System.assertNotEquals(null, updatedLead.psg_Contact_Id__c, 'Lead should be converted with new account');
    }

    @isTest
    static void testConvertLead_Broker_DuplicateEmail_NoConversion() {
        Lead brokerLead = new Lead(
            FirstName = 'Bob',
            LastName = 'Builder',
            Email = 'existing@example.com',
            Company = 'ExistingBrokerCo',
            Status = 'Open - Not Contacted',
            psg_Contact_Type__c = 'Broker'
        );
        insert brokerLead;

        Test.startTest();
        PSG_LeadConvertion.convertLead(new List<Id>{brokerLead.Id});
        Test.stopTest();

        Lead updatedLead = [SELECT psg_Contact_Id__c FROM Lead WHERE Id = :brokerLead.Id];
        System.assertNotEquals(null, updatedLead.psg_Contact_Id__c, 'Lead should be converted using existing contact');
    }

    @isTest
    static void testConvertLead_Client_NewAccount() {
        Lead clientLead = new Lead(
            FirstName = 'Alice',
            LastName = 'Smith',
            Email = 'alice@example.com',
            Company = 'Alice Inc.',
            Status = 'Open - Not Contacted',
            psg_Contact_Type__c = 'Client'
        );
        insert clientLead;

        Test.startTest();
        PSG_LeadConvertion.convertLead(new List<Id>{clientLead.Id});
        Test.stopTest();

        Lead updatedLead = [SELECT psg_Contact_Id__c FROM Lead WHERE Id = :clientLead.Id];
        System.assertNotEquals(null, updatedLead.psg_Contact_Id__c, 'Contact should have been created and assigned');
    }

    @isTest
    static void testConvertLead_Client_DuplicateEmail_NoConversion() {
        Lead dupLead = new Lead(
            FirstName = 'Jane',
            LastName = 'Dup',
            Email = 'existingContact@example.com',
            Company = 'Dup Inc.',
            Status = 'Open - Not Contacted',
            psg_Contact_Type__c = 'Client'
        );
        insert dupLead;

        Test.startTest();
        PSG_LeadConvertion.convertLead(new List<Id>{dupLead.Id});
        Test.stopTest();

        Lead updatedLead = [SELECT psg_Contact_Id__c FROM Lead WHERE Id = :dupLead.Id];
        System.assertEquals(
            [SELECT Id FROM Contact WHERE Email = 'existingContact@example.com' LIMIT 1].Id,
            updatedLead.psg_Contact_Id__c,
            'Lead should reference existing contact'
        );
    }
}