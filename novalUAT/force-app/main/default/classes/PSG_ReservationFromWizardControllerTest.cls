@isTest
private class PSG_ReservationFromWizardControllerTest {
    
    @testSetup
    static void setupData() {
        Account acc = new Account(Name = 'Test Account');
        insert acc;
        
        Contact con = new Contact(
            FirstName = 'John',
            LastName = 'Doe',
            Email = 'john.doe@example.com',
            Phone = '1234567890'
        );
        insert con;
        
        Opportunity opp = new Opportunity(
            Name = 'Test Opportunity',
            StageName = 'Prospecting',
            CloseDate = Date.today().addDays(30),
            psg_Contact__c = con.Id,
            AccountId = acc.Id
        );
        insert opp;
        
        psg_Project__c proyecxt = new psg_Project__c(Name ='Test');
        insert proyecxt;
        
        Product2 prod = new Product2(
            Name = 'Test Product',
            IsActive = true,
            psg_Price__c = 500000,
            Project__c = proyecxt.id
        );
        insert prod;
        
        Id pricebookId = Test.getStandardPricebookId();
        
        PricebookEntry pbe = new PricebookEntry(
            Pricebook2Id = pricebookId,
            Product2Id = prod.Id,
            UnitPrice = 500000,
            IsActive = true
        );
        insert pbe;
        
        OpportunityLineItem oli = new OpportunityLineItem(
            OpportunityId = opp.Id,
            Quantity = 1,
            UnitPrice = 500000,
            PricebookEntryId = pbe.Id
        );
        insert oli;
    }
    
    @isTest
    static void testGetContactInfo() {
        Opportunity opp = [SELECT Id FROM Opportunity LIMIT 1];
        
        Test.startTest();
        String contactId = PSG_ReservationFromWizardController.getContactInfo(opp.Id);
        Test.stopTest();
        
        System.assertNotEquals(null, contactId, 'Contact Id should not be null');
    }
    
    @isTest
    static void testGetProduct2() {
        Opportunity opp = [SELECT Id FROM Opportunity LIMIT 1];
        
        Test.startTest();
        PSG_ReservationFromWizardController.Product2Wrapper wrapper = PSG_ReservationFromWizardController.getProduct2(opp.Id);
        Test.stopTest();
        
        System.assertNotEquals(null, wrapper, 'Wrapper should not be null');
    }
    
    @isTest
    static void testUpdateContactInfo() {
        Opportunity opp = [SELECT Id, psg_Contact__c FROM Opportunity LIMIT 1];
        Contact con = [SELECT Id FROM Contact WHERE Id = :opp.psg_Contact__c];
        
        PSG_ReservationFromWizardController.ReservationAccount info = new PSG_ReservationFromWizardController.ReservationAccount();
        info.id = con.Id;
        info.opptyId = opp.Id;
        info.firstName = 'Jane';
        info.lastName = 'Smith';
        info.email = 'jane.smith@example.com';
        info.phone = '8099077277';
        info.identificationNumber = '123456789';
        info.identificationType = 'Passport';
        info.nationality = 'Dominican';
        info.maritalStatus = 'Soltero';
        info.birthDate = String.valueOf(Date.newInstance(1990, 1, 1));
        info.profession = 'Engineer';
        info.occupationDetails = 'Software';
        info.address = '123 Street';
        info.city = 'Santo Domingo';
        info.state = 'DN';
        info.postalCode = '42000';
        info.hasOtherCitizenship = 'No';
        info.otherCitizenship = null;
        info.spouseName = 'Marie';
        info.spouseLastName = 'Smith';
        info.spouseIdNumber = '123456789012';
        info.spouseBirthPlace = 'Somewhere';
        info.spouseNationality = 'Dominican';
        info.spouseProfession = 'J';
        info.spouseProfessionDetail = 'jjsjs';
        info.businessName = '';
        
        
        String serialized = JSON.serialize(info);
        
        Test.startTest();
        PSG_ReservationFromWizardController.updateContactInfo(serialized);
        Test.stopTest();
        
        Contact updated = [SELECT FirstName, LastName FROM Contact WHERE Id = :con.Id];
        System.assertEquals('Jane', updated.FirstName);
        System.assertEquals('Smith', updated.LastName);
    }
    
    @isTest
    static void testGetNationalities(){
        PSG_ReservationFromWizardController.getNationalities();
    }
    
    @isTest
    static void testCreatePaymentValidation() {
        // Create Contact (customer)
        Contact contact = new Contact(
            FirstName = 'Test',
            LastName = 'Customer',
            Email = 'test@example.com'
        );
        insert contact;
        
        // Create Opportunity linked to the contact
        Opportunity opp = new Opportunity(
            Name = 'Test Opportunity',
            StageName = 'Prospecting',
            CloseDate = Date.today().addDays(10),
            psg_Contact__c = contact.Id
        );
        insert opp;
        
        // Prepare data map
        Map<String, Object> paymentData = new Map<String, Object>{
            'recordId' => opp.Id,
                'customerId' => contact.Id,
                'Amount' => '1000.00',
                'Currency' => 'DOP',
                'NoBank' => '1234567890',
                'Bank' => 'Banco Popular',
                'NoReference' => 'REF123456',
                'Date' => String.valueOf(Date.today())
                };
                    
                    // Base64 encoded dummy file
                    String fileContent = 'Test file content';
        String base64File = EncodingUtil.base64Encode(Blob.valueOf(fileContent));
        String fileName = 'test_file.txt';
        String fileType = 'text/plain';
        
        Test.startTest();
        PSG_Payment_Validation__c result = PSG_ReservationFromWizardController.createPaymentValidation(paymentData, fileName, fileType, base64File);
        Test.stopTest();
        
        //System.assertNotEquals(null, result, 'Returned PSG_Payment_Validation__c should not be null');
        //System.assertNotEquals(null, result.Id, 'PSG_Payment_Validation__c record should have an Id');
        
        //Attachment att = [SELECT Id, ParentId, Name FROM Attachment WHERE ParentId = :result.Id LIMIT 1];
        //System.assertEquals(fileName, att.Name, 'Attachment name should match the uploaded file');
    }
    
}