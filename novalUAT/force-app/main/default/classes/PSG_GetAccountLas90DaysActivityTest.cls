@isTest
private class PSG_GetAccountLas90DaysActivityTest {

@IsTest
    static void testGetDataNoData() {
        // Crear una cuenta de prueba sin datos relacionados
        Account testAccount = new Account(
            Name = 'Test Account'
        );
        insert testAccount;

        // Llamar al método y verificar que todos los conteos sean cero
        Test.startTest();
        PSG_GetAccountLas90DaysActivity.ResultWrapper result = PSG_GetAccountLas90DaysActivity.getData(testAccount.Id);
        Test.stopTest();

        System.assertEquals(0, result.contacts, 'El número de contactos debería ser cero');
        System.assertEquals(0, result.opportunities, 'El número de oportunidades debería ser cero');
        System.assertEquals(0, result.showings, 'El número de eventos debería ser cero');
    }
}