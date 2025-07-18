@isTest
public class PSG_ConvertLeadControllerTest {
    
    @testSetup
    static void setupData() {
        // Create sample Leads with different statuses and types
        List<Lead> leads = new List<Lead>{
            new Lead(LastName = 'Client Test', FirstName ='Testing', Company = 'Test Co', psg_Contact_Type__c = 'Client', Status = 'New', Email = 'Testing01@email.com'),
            new Lead(LastName = 'Broker Test', FirstName ='Testing',  Company = 'Test Co', psg_Contact_Type__c = 'Broker', Status = 'Working', Email = 'Testing02@email.com'),
            new Lead(LastName = 'Invalid Type', FirstName ='Testing',  Company = 'Test Co', psg_Contact_Type__c = 'Broker', Status = 'Unqualified', Email = 'Testing03@email.com'),
            new Lead(LastName = 'Null Type', FirstName ='Testing',  Company = 'Test Co', Status = 'New', Email = 'Testing04@email.com')
        };
        insert leads;
    }
    
    @isTest
    static void testConvertLeadToContact_Success() {
        Lead testLead = [SELECT Id FROM Lead WHERE psg_Contact_Type__c = 'Client' LIMIT 1];
        
        Test.startTest();
        Id contactId = PSG_ConvertLeadController.convertLeadToContact(testLead.Id);
        Test.stopTest();
        
        Lead updatedLead = [SELECT Id, psg_Contact_Id__c FROM Lead WHERE id = :testLead.Id LIMIT 1];
        
        System.assertEquals(contactId, updatedLead.psg_Contact_Id__c, 'Contact Id should be returned.');
    }
    
    @isTest
    static void testConvertLeadToContact_Exceptions() {
        Test.startTest();
        try {
            PSG_ConvertLeadController.convertLeadToContact(null);
            System.assert(false, 'Expected exception for null Id.');
        } catch (AuraHandledException e) {
            System.assert(e.getMessage() != null);
        }
        Test.stopTest();
    }
    
    @isTest
    static void testMoveLeadStage_ValidTransitionsFromUnqualified() {
        Lead l = [SELECT Id, Status FROM Lead WHERE Status = 'Unqualified' limit 1];
        string status = l.Status;
        
        Test.startTest();
        PSG_ConvertLeadController.moveLeadStage(l.Id);
        Test.stopTest();
            
        Lead updatedLead = [SELECT Status FROM Lead WHERE Id = :l.Id];
        System.assertNotEquals(status, updatedLead.Status, 'Stage should be updated.');
    }
    @isTest
    static void testMoveLeadStage_ValidTransitionsFromNew() {
        Lead l = [SELECT Id, Status FROM Lead WHERE Status = 'New' limit 1];
        string status = l.Status;
        
        Test.startTest();
        PSG_ConvertLeadController.moveLeadStage(l.Id);
        Test.stopTest();
            
        Lead updatedLead = [SELECT Status FROM Lead WHERE Id = :l.Id];
        System.assertNotEquals(status, updatedLead.Status, 'Stage should be updated.');
    }
    @isTest
    static void testMoveLeadStage_ValidTransitionsFromWorking() {
        Lead l = [SELECT Id, Status FROM Lead WHERE Status = 'Working' limit 1];
        string status = l.Status;
        
        Test.startTest();
        PSG_ConvertLeadController.moveLeadStage(l.Id);
        Test.stopTest();
            
        Lead updatedLead = [SELECT Status FROM Lead WHERE Id = :l.Id];
        System.assertNotEquals(status, updatedLead.Status, 'Stage should be updated.');
    }
    
    @isTest
    static void testMoveLeadStage_Invalid() {
        Lead finalStageLead = new Lead(LastName = 'Final Stage', Company = 'Test Co', Status = 'Nurturing', psg_Contact_Type__c = 'Client', email='testing122343@email.com');
        insert finalStageLead;
        
        Test.startTest();
        try {
            PSG_ConvertLeadController.moveLeadStage(finalStageLead.Id);
            System.assert(false, 'Expected exception for final stage.');
        } catch (AuraHandledException e) {
            System.assert(true);
        }
        Test.stopTest();
    }
}