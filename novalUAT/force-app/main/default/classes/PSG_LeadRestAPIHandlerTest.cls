@isTest
public with sharing class PSG_LeadRestAPIHandlerTest {

    @IsTest
    static void TestImportLead(){
        // Simular parámetros de la solicitud
        RestRequest req = new RestRequest();
        RestResponse res = new RestResponse();

        req.requestURI = '/services/apexrest/leadimport';
        req.httpMethod = 'POST';
        req.addHeader('Content-Type', 'application/x-www-form-urlencoded');
        req.params.put('last_name', 'Developer2');
        req.params.put('company', 'Dev2');
        req.params.put('email', 'developer2@dev.com');
        req.params.put('status', 'New');

        RestContext.request = req;
        RestContext.response = res;

        Test.startTest();
        PSG_LeadRestAPIHandler.importLead();
        Test.stopTest();

        List<Lead> leads = [SELECT Id, LastName, Company, Email
                            FROM Lead
                            WHERE LastName = 'Developer2'];
        System.assertEquals(1, leads.size(), 'Debería haberse creado un lead');
        System.assertEquals('Dev2', leads[0].Company, 'La compañía no coincide');
        System.assertEquals('developer2@dev.com', leads[0].Email, 'El email no coincide');
    }

    @IsTest
    static void TestImportLeadMissingField(){
        // Simular parámetros de la solicitud con un campo faltante
        RestRequest req = new RestRequest();
        RestResponse res = new RestResponse();

        req.requestURI = '/services/apexrest/leadimport';
        req.httpMethod = 'POST';
        req.params.put('company', 'Dev2');
        req.params.put('email', 'developer2@dev.com');
        req.params.put('status', 'New');

        RestContext.request = req;
        RestContext.response = res;

        Test.startTest();
        String result = PSG_LeadRestAPIHandler.importLead();
        Test.stopTest();

        System.debug('Resultado con campo faltante: ' + result);

        System.assert(result.contains('REQUIRED_FIELD_MISSING'), 'Debe capturar errores por campo faltante');
    }
}