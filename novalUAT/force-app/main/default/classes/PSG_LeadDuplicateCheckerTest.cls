@isTest
public class PSG_LeadDuplicateCheckerTest {
    
    @TestSetup
    static void setupTestData() {
        // Crear un Lead existente para las pruebas de duplicados
        Lead existingLead = new Lead(
            FirstName = 'Juan',
            LastName = 'Perez',
            Email = 'juan.perez@test.com',
            Phone = '1234567890',
            Company = 'Test Company',
            psg_Language__c = 'Spanish'
        );
        insert existingLead;
        
        Contact existingContact = new Contact(
            FirstName = 'Diego',
            LastName = 'Lopez',
            Email = 'john.perez@test.com',
            Phone = '1234567877',
            psg_Language__c = 'Spanish'
        );
        insert existingContact;
        
        // Crear otro Lead con diferente email pero mismo teléfono
        Lead existingLead2 = new Lead(
            FirstName = 'Maria',
            LastName = 'Garcia',
            Email = 'maria.garcia@test.com',
            Phone = '0987654321',
            Company = 'Another Company',
            psg_Language__c = 'English'
        );
        insert existingLead2;
        
        // Crear un Lead con mismo nombre y compañía pero diferente email/teléfono
        Lead existingLead3 = new Lead(
            FirstName = 'Carlos',
            LastName = 'Rodriguez',
            Email = 'carlos.rodriguez@test.com',
            Phone = '5555555555',
            Company = 'Same Name Company',
            psg_Language__c = 'Spanish'
        );
        insert existingLead3;
    }
    
    @isTest
    static void testDuplicateByEmail() {
        // Preparar datos de entrada - mismo email que el Lead existente
        PSG_LeadDuplicateChecker.DuplicateInput input = new PSG_LeadDuplicateChecker.DuplicateInput();
        input.firstName = 'Juan Carlos';
        input.lastName = 'Perez Martinez';
        input.email = 'juan.perez@test.com'; // Mismo email que el Lead existente
        input.phone = '9999999999'; // Teléfono diferente
        input.company = 'Different Company';
        input.language = 'English';
        
        List<PSG_LeadDuplicateChecker.DuplicateInput> inputs = new List<PSG_LeadDuplicateChecker.DuplicateInput>();
        inputs.add(input);
        
        Test.startTest();
        List<PSG_LeadDuplicateChecker.DuplicateInfoWrapper> results = PSG_LeadDuplicateChecker.checkForDuplicate(inputs);
        Test.stopTest();
        
        // Verificar que se detectó el duplicado
        System.assertEquals(1, results.size(), 'Debería devolver un resultado');
        PSG_LeadDuplicateChecker.DuplicateInfoWrapper result = results[0];
        System.assertEquals(true, result.isDuplicate, 'Debería detectar duplicado por email');
        System.assertNotEquals(null, result.existingRecordId, 'Debería tener el ID del registro existente');
        System.assertNotEquals(null, result.message, 'Debería tener un mensaje');
        System.assertEquals('Lead', result.existingRecordType, 'El tipo debe ser Lead');
    }
    
    @isTest
    static void testDuplicateByEmailContact() {
        // Preparar datos de entrada - mismo email que el Lead existente
        PSG_LeadDuplicateChecker.DuplicateInput input = new PSG_LeadDuplicateChecker.DuplicateInput();
        input.firstName = 'Joh Carlos';
        input.lastName = 'Perez Lopez';
        input.email = 'john.perez@test.com'; // Mismo email que el Lead existente
        input.phone = '9999999999'; // Teléfono diferente
        input.company = 'Different Company';
        input.language = 'English';
        
        List<PSG_LeadDuplicateChecker.DuplicateInput> inputs = new List<PSG_LeadDuplicateChecker.DuplicateInput>();
        inputs.add(input);
        
        Test.startTest();
        List<PSG_LeadDuplicateChecker.DuplicateInfoWrapper> results = PSG_LeadDuplicateChecker.checkForDuplicate(inputs);
        Test.stopTest();
        
        // Verificar que se detectó el duplicado
        System.assertEquals(1, results.size(), 'Debería devolver un resultado');
        PSG_LeadDuplicateChecker.DuplicateInfoWrapper result = results[0];
        System.assertEquals(true, result.isDuplicate, 'Debería detectar duplicado por email');
        System.assertNotEquals(null, result.existingRecordId, 'Debería tener el ID del registro existente');
        System.assertNotEquals(null, result.message, 'Debería tener un mensaje');
        System.assertEquals('Contact', result.existingRecordType, 'El tipo debe ser Lead');
    }
    
    @isTest
    static void testDuplicateByPhone() {
        // Preparar datos de entrada - mismo teléfono que el segundo Lead existente
        PSG_LeadDuplicateChecker.DuplicateInput input = new PSG_LeadDuplicateChecker.DuplicateInput();
        input.firstName = 'Maria Elena';
        input.lastName = 'Garcia Lopez';
        input.email = 'maria.elena@different.com'; // Email diferente
        input.phone = '0987654321'; // Mismo teléfono que el Lead existente
        input.company = 'Different Company';
        input.language = 'Spanish';
        
        List<PSG_LeadDuplicateChecker.DuplicateInput> inputs = new List<PSG_LeadDuplicateChecker.DuplicateInput>();
        inputs.add(input);
        
        Test.startTest();
        List<PSG_LeadDuplicateChecker.DuplicateInfoWrapper> results = PSG_LeadDuplicateChecker.checkForDuplicate(inputs);
        Test.stopTest();
        
        // Verificar que se detectó el duplicado
        System.assertEquals(1, results.size(), 'Debería devolver un resultado');
        PSG_LeadDuplicateChecker.DuplicateInfoWrapper result = results[0];
        System.assertEquals(true, result.isDuplicate, 'Debería detectar duplicado por teléfono');
        System.assertNotEquals(null, result.existingRecordId, 'Debería tener el ID del registro existente');
        System.assertNotEquals(null, result.message, 'Debería tener un mensaje');
        System.assertEquals('Lead', result.existingRecordType, 'El tipo debe ser Lead');
    }
    
    @isTest
    static void testDuplicateByNameAndCompany() {
        // Preparar datos de entrada - mismo nombre y compañía que el tercer Lead existente
        PSG_LeadDuplicateChecker.DuplicateInput input = new PSG_LeadDuplicateChecker.DuplicateInput();
        input.firstName = 'Carlos';
        input.lastName = 'Rodriguez';
        input.email = 'different.carlos@test.com'; // Email diferente
        input.phone = '7777777777'; // Teléfono diferente
        input.company = 'Same Name Company'; // Misma compañía
        input.language = 'English';
        
        List<PSG_LeadDuplicateChecker.DuplicateInput> inputs = new List<PSG_LeadDuplicateChecker.DuplicateInput>();
        inputs.add(input);
        
        Test.startTest();
        List<PSG_LeadDuplicateChecker.DuplicateInfoWrapper> results = PSG_LeadDuplicateChecker.checkForDuplicate(inputs);
        Test.stopTest();
        
        // Verificar que se detectó el duplicado
        System.assertEquals(1, results.size(), 'Debería devolver un resultado');
        PSG_LeadDuplicateChecker.DuplicateInfoWrapper result = results[0];
        System.assertEquals(true, result.isDuplicate, 'Debería detectar duplicado por nombre y compañía');
        System.assertNotEquals(null, result.existingRecordId, 'Debería tener el ID del registro existente');
        System.assertNotEquals(null, result.message, 'Debería tener un mensaje');
        System.assertEquals('Lead', result.existingRecordType, 'El tipo debe ser Lead');
    }
    
    @isTest
    static void testNoDuplicate() {
        // Preparar datos de entrada completamente únicos
        PSG_LeadDuplicateChecker.DuplicateInput input = new PSG_LeadDuplicateChecker.DuplicateInput();
        input.firstName = 'Unique';
        input.lastName = 'Person';
        input.email = 'unique.person@unique.com';
        input.phone = '1111111111';
        input.company = 'Unique Company';
        input.language = 'Portuguese';
        
        List<PSG_LeadDuplicateChecker.DuplicateInput> inputs = new List<PSG_LeadDuplicateChecker.DuplicateInput>();
        inputs.add(input);
        
        Test.startTest();
        List<PSG_LeadDuplicateChecker.DuplicateInfoWrapper> results = PSG_LeadDuplicateChecker.checkForDuplicate(inputs);
        Test.stopTest();
        
        // Verificar que NO se detectó duplicado
        System.assertEquals(1, results.size(), 'Debería devolver un resultado');
        PSG_LeadDuplicateChecker.DuplicateInfoWrapper result = results[0];
        System.assertEquals(false, result.isDuplicate, 'NO debería detectar duplicado');
        System.assertEquals(null, result.existingRecordId, 'NO debería tener ID de registro existente');
        System.assertEquals('No se encontraron duplicados.', result.message, 'Debería indicar que no hay duplicados');
        System.assertEquals(null, result.existingRecordType, 'NO debería tener tipo de registro');
        System.assertEquals(null, result.ownerName, 'NO debería tener nombre de propietario');
    }
    
    @isTest
    static void testMultipleInputs() {
        // Preparar múltiples datos de entrada
        List<PSG_LeadDuplicateChecker.DuplicateInput> inputs = new List<PSG_LeadDuplicateChecker.DuplicateInput>();
        
        // Primera entrada - duplicado por email
        PSG_LeadDuplicateChecker.DuplicateInput input1 = new PSG_LeadDuplicateChecker.DuplicateInput();
        input1.firstName = 'Test1';
        input1.lastName = 'User1';
        input1.email = 'juan.perez@test.com'; // Email duplicado
        input1.phone = '8888888888';
        input1.company = 'Test Company 1';
        input1.language = 'Spanish';
        inputs.add(input1);
        
        // Segunda entrada - sin duplicado
        PSG_LeadDuplicateChecker.DuplicateInput input2 = new PSG_LeadDuplicateChecker.DuplicateInput();
        input2.firstName = 'Test2';
        input2.lastName = 'User2';
        input2.email = 'unique.test@test.com';
        input2.phone = '2222222222';
        input2.company = 'Test Company 2';
        input2.language = 'English';
        inputs.add(input2);
        
        Test.startTest();
        List<PSG_LeadDuplicateChecker.DuplicateInfoWrapper> results = PSG_LeadDuplicateChecker.checkForDuplicate(inputs);
        Test.stopTest();
        
        // Verificar que se procesaron ambas entradas
        System.assertEquals(2, results.size(), 'Debería devolver dos resultados');
        
        // Primer resultado - debería ser duplicado
        PSG_LeadDuplicateChecker.DuplicateInfoWrapper result1 = results[0];
        System.assertEquals(true, result1.isDuplicate, 'Primera entrada debería ser duplicado');
        
        // Segundo resultado - NO debería ser duplicado
        PSG_LeadDuplicateChecker.DuplicateInfoWrapper result2 = results[1];
        System.assertEquals(false, result2.isDuplicate, 'Segunda entrada NO debería ser duplicado');
    }
    
    @isTest
    static void testMissingRequiredFields() {
        // Preparar datos de entrada con campos faltantes
        PSG_LeadDuplicateChecker.DuplicateInput input = new PSG_LeadDuplicateChecker.DuplicateInput();
        input.firstName = ''; // Campo vacío
        input.lastName = 'Test';
        input.email = 'test@test.com';
        input.phone = '1234567890';
        input.company = 'Test Company';
        input.language = 'Spanish';
        
        List<PSG_LeadDuplicateChecker.DuplicateInput> inputs = new List<PSG_LeadDuplicateChecker.DuplicateInput>();
        inputs.add(input);
        
        Test.startTest();
        try {
            PSG_LeadDuplicateChecker.checkForDuplicate(inputs);
            System.assert(false, 'Debería lanzar una excepción por campos faltantes');
        } catch (IllegalArgumentException e) {
            System.assertEquals('Todos los campos son obligatorios.', e.getMessage(), 'Mensaje de error correcto');
        }
        Test.stopTest();
    }

}