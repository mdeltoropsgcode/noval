@isTest
public class LeadEmailValidatorControllerTest {
   
    @isTest
    static void testCheckLeadNotFound() {
        // Act
        Test.startTest();
        Boolean result = LeadEmailValidatorController.checkLeadByEmail('notfound@example.com');
        Test.stopTest();
        
        // Assert
        System.assertEquals(false, result, 'The lead should not be found');
    }
}