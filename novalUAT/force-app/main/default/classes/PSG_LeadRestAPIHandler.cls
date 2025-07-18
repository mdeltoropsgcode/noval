@RestResource(urlMapping = '/leadimport')
global without sharing class PSG_LeadRestAPIHandler {
    @HttpPost
    global static String importLead(){
        RestRequest req = RestContext.request;
        RestResponse res = RestContext.response;
        Map<String, String> params = req.params;
        Map<String, Object> responseMap = new Map<String, Object>();
        
        string errMsg = 'params: '+ params;
        Logger.createLog('Lead Rest API', 'PSG_LeadRestAPIHandler', 'importLead',errMsg, 'Info');
        
        try{
            // Obtener configuración de mapeo
            List<PSG_Object_Mapping__mdt> mappings = [SELECT Id, PSG_RecordTypeName__c
                                                      FROM PSG_Object_Mapping__mdt
                                                      WHERE PSG_ObjectAPIName__c = 'Lead'
                                                      LIMIT 1];
            
            if (mappings.isEmpty()){
                return sendResponse(res, 400, 'No se encontró un mapeo para el objeto Lead');
            }
            
            PSG_Object_Mapping__mdt mapping = mappings[0];
            
            List<PSG_Field_Mapping__mdt> fieldMappings = [SELECT PSG_ApiName__c, PSG_ExternalFieldAPIName__c, PSG_Parent_Object_mdt__c
                                                          FROM PSG_Field_Mapping__mdt
                                                          WHERE PSG_Parent_Object_mdt__c = :mapping.Id];
            
            Map<string, string> fieldsMap = new Map<string, string>();
            string message = '';
            for(PSG_Field_Mapping__mdt fm : fieldMappings){
                if(!string.isBlank(fm.PSG_ExternalFieldAPIName__c) && !string.isBlank(fm.PSG_ApiName__c)){
                    fieldsMap.put(fm.PSG_ExternalFieldAPIName__c.toLowerCase(), fm.PSG_ApiName__c);
                    message += '{External:' + fm.PSG_ExternalFieldAPIName__c + ' | API Name: '+ fm.PSG_ApiName__c + '}, ' ;
                }
            }
            Logger.createLog('Lead Rest API', 'PSG_LeadRestAPIHandler', 'importLead',message, 'Info');
            
            Lead newLead = new Lead();
            
            
            for(string param : params.keySet()){
                string lowerCaseParam = param.toLowerCase();
                
                if(fieldsMap.containsKey(lowerCaseParam)){
                    String apiName = fieldsMap.get(lowerCaseParam);
                    
                    if (!String.isBlank(params.get(param))){
                        try{
                            Schema.DisplayType fieldType = Schema.sObjectType.Lead.fields.getMap().get(apiName).getDescribe().getType();
                            String value = params.get(param);
                            
                            switch on fieldType {
                                when Boolean {
                                    String normalizedValue = value.trim().toLowerCase();
                                    Boolean booleanValue = (normalizedValue == 'true' || normalizedValue == '1');
                                    newLead.put(apiName, booleanValue);
                                }
                                when Currency {
                                    newLead.put(apiName, Decimal.valueOf(value));
                                }
                                when Double {
                                    newLead.put(apiName, Decimal.valueOf(value));
                                }
                                when Integer {
                                    newLead.put(apiName, Integer.valueOf(value));
                                }
                                when else {
                                    newLead.put(apiName, value);
                                }
                            }
                        } catch (Exception e){
                            return sendResponse(res, 400, 'Error al asignar el campo "' + lowerCaseParam + '": ' + params.get(lowerCaseParam) + ' => ' + e.getMessage());
                        }
                    }
                }
                
            }
            
            System.debug('Lead preparado: ' + newLead);
            
            insert newLead;
            
            responseMap.put('message', 'Lead creado correctamente');
            responseMap.put('leadId', newLead.Id);
            res.statusCode = 201;
            res.responseBody = Blob.valueOf(JSON.serialize(responseMap));
            return 'Lead creado correctamente con ID: ' + newLead.Id;
            
        } catch (DmlException e){
            string errorMessage = 'Error al insertar el Lead: ' + e.getMessage() + ' |Line Number:' + e.getLineNumber();
            Logger.createLog('Lead Rest API', 'PSG_LeadRestAPIHandler', 'importLead',errorMessage, 'Error');
            return sendResponse(res, 500, errorMessage);
        } catch (Exception e){
            string errorMessage = 'Error inesperado: ' + e.getMessage() + ' |Line Number:' + e.getLineNumber();
            Logger.createLog('Lead Rest API', 'PSG_LeadRestAPIHandler', 'importLead',errorMessage, 'Error');
            return sendResponse(res, 500, errorMessage);
        }
    }
    
    private static String sendResponse(RestResponse res, Integer statusCode, String message){
        res.statusCode = statusCode;
        Map<String, Object> responseMap = new Map<String, Object>{ 'message' => message };
            res.responseBody = Blob.valueOf(JSON.serialize(responseMap));
        return message;
    }
}