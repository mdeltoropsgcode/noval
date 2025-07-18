@isTest
private class PSG_VerifyEmailControllerTest {

    @isTest
    static void testVerifyLeadEmail_success() {
        // Crear un Lead de prueba
        Lead testLead = new Lead(
            FirstName = 'Test',
            LastName = 'Lead',
            Company = 'Test Company',
            Email = 'test@example.com'
        );
        insert testLead;

        // Llamar al método que se prueba
        Test.startTest();
        PSG_VerifyEmailController.verifyLeadEmail(testLead.Id);
        Test.stopTest();

        // Verificar que el campo fue actualizado
        Lead updatedLead = [SELECT psg_VerifiedEmail__c FROM Lead WHERE Id = :testLead.Id];
        System.assertEquals(true, updatedLead.psg_VerifiedEmail__c, 'El campo psg_VerifiedEmail__c debe estar en true');
       
        
    }
	
    @isTest
    static void testVerifyLeadEmail_notFound() {
        // Crear y eliminar un lead para usar un ID válido pero inexistente
        Lead tempLead = new Lead(
            FirstName = 'ToDelete',
            LastName = 'Lead',
            Company = 'Delete Inc.',
            Email = 'delete@example.com'
        );
        
        insert tempLead;
        Id deletedId = tempLead.Id;
        delete tempLead;

        Test.startTest();
        try {
            PSG_VerifyEmailController.verifyLeadEmail(deletedId);
            System.assert(false, 'Debe lanzar una excepción si el Lead no existe');
        } catch (AuraHandledException e) {
            // Asegúrate de que el mensaje de la excepción contenga "Lead no encontrado"
            //System.assert(e.getMessage().contains('Lead no encontrado.'), 'Lead no encontrado.');
        }
        Test.stopTest();
    }
    
}