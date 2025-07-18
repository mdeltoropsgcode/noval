@isTest
private class PSG_Product2PathHelperTest {


@IsTest
    static void testGetStatuses() {
        List<PSG_Product2PathHelper.PicklistOption> statuses = PSG_Product2PathHelper.getStatuses();
        System.assert(statuses.size() > 0, 'Expected at least one status');
    }

@IsTest
    static void testGetActualStatus() {
        Product2 product = new Product2(Name = 'Test Product', psg_Status__c = 'Sold');
        insert product;

        Test.startTest();
        String actualStatus = PSG_Product2PathHelper.getActualStatus(product.Id);
        Test.stopTest();

        System.assertEquals('Sold', actualStatus, 'Expected status to be "Sold"');
    }

@IsTest
    static void testGetUserProfile() {
        // Create a test user
        Profile testProfile = [SELECT Id FROM Profile WHERE Name = 'Standard User' LIMIT 1];
        User testUser = new User(
            Alias = 'testU',
            Email = 'testuser@test.com',
            EmailEncodingKey = 'UTF-8',
            LastName = 'Testing',
            LanguageLocaleKey = 'en_US',
            LocaleSidKey = 'en_US',
            ProfileId = testProfile.Id,
            TimeZoneSidKey = 'America/Los_Angeles',
            UserName = 'testuser' + DateTime.now().getTime() + '@test.com'
        );
        insert testUser;

        // Set the test user context
        System.runAs(testUser) {
            Test.startTest();
            String userProfile = PSG_Product2PathHelper.getUserProfile();
            Test.stopTest();

            System.assertEquals('Standard User', userProfile, 'Expected profile name to be "Standard User"');
        }
    }

@IsTest
    static void testSetStatus() {
        Product2 product = new Product2(Name = 'Test Product', psg_Status__c = 'Available');
        insert product;

        Test.startTest();
        String newStatus = PSG_Product2PathHelper.setStatus(product.Id, 'Sold');
        Test.stopTest();

        System.assertEquals('Sold', newStatus, 'Expected status to be updated to "Sold"');
    }
}