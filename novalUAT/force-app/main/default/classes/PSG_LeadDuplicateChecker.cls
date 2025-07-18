public without sharing class PSG_LeadDuplicateChecker{
    public class DuplicateInfoWrapper{
        @InvocableVariable
        public Boolean isDuplicate;
        @InvocableVariable
        public String message;
        @InvocableVariable
        public Id existingRecordId;
        @InvocableVariable
        public String ownerName;
        @InvocableVariable
        public String existingRecordType;
        public DuplicateInfoWrapper(DuplicateInfo info){
            this.isDuplicate = info.isDuplicate;
            this.message = info.message;
            this.existingRecordId = info.existingRecordId;
            this.ownerName = info.ownerName;
            this.existingRecordType = info.existingRecordType;
        }

    }

    public class DuplicateInfo{
        @AuraEnabled
        public Boolean isDuplicate;
        @AuraEnabled
        public String message;
        @AuraEnabled
        public Id existingRecordId;
        @AuraEnabled
        public String ownerName;
        @AuraEnabled
        public String existingRecordType;

        public DuplicateInfo(){
            this.isDuplicate = false;
        }

    }

    public class DuplicateInput{
        @InvocableVariable(required = true)
        public String firstName;
        @InvocableVariable(required = true)
        public String lastName;
        @InvocableVariable(required = true)
        public String email;
        @InvocableVariable(required = true)
        public String phone;
        @InvocableVariable(required = true)
        public String company;
        @InvocableVariable(required = true)
        public String language;
    }

    // MÉTODO ORIGINAL PARA FLOW
    @InvocableMethod(label = 'Check for Duplicate Lead'description = 'Verifica si existe un duplicado para un Lead.')
    public static List<DuplicateInfoWrapper> checkForDuplicate(List<DuplicateInput> inputs){
        List<DuplicateInfoWrapper> results = new List<DuplicateInfoWrapper>();

        for (DuplicateInput input : inputs){
            if (String.isBlank(input.firstName) || String.isBlank(input.lastName) || String.isBlank(input.email) || String.isBlank(input.phone) || String.isBlank(input.language)){
                throw new IllegalArgumentException('Todos los campos son obligatorios.');
            }

            DuplicateInfo result = checkLeadForDuplicates(input.firstName, input.lastName, input.email, input.phone, input.company, input.language);

            results.add(new DuplicateInfoWrapper(result));
        }

        return results;
    }

    // NUEVO MÉTODO PARA USAR DESDE OTRAS CLASES APEX
    public static List<DuplicateInfo> checkForDuplicateLeads(List<Lead> leads){
        List<DuplicateInfo> results = new List<DuplicateInfo>();

        for (Lead lead : leads){
            // Validación de campos requeridos
            if (String.isBlank(lead.FirstName) || String.isBlank(lead.LastName) || String.isBlank(lead.Email) || String.isBlank(lead.Phone)){
                throw new IllegalArgumentException('Los campos FirstName, LastName, Email y Phone son obligatorios.');
            }

            DuplicateInfo result = checkLeadForDuplicates(lead.FirstName, lead.LastName, lead.Email, lead.Phone, lead.Company, lead.psg_Language__c);

            results.add(result);
        }

        return results;
    }

    // MÉTODO AUXILIAR COMPARTIDO (lógica centralizada)
    private static DuplicateInfo checkLeadForDuplicates(String firstName, String lastName, String email, String phone, String company, String language){
        DuplicateInfo result = new DuplicateInfo();

        // Crear un Lead temporal para verificar duplicados
        Lead tempLead = new Lead(
            FirstName = firstName, 
            LastName = lastName, 
            Email = email, 
            Phone = phone, 
            Company = company, 
            psg_Language__c = language
        );

        List<Lead> leadList = new List<Lead>();
        leadList.add(tempLead);

        try{
            List<Datacloud.FindDuplicatesResult> findDuplicatesResults = Datacloud.FindDuplicates.findDuplicates(leadList);

            if (!findDuplicatesResults.isEmpty()){
                Datacloud.FindDuplicatesResult duplicateResult = findDuplicatesResults[0];
                List<Datacloud.DuplicateResult> duplicateResults = duplicateResult.getDuplicateResults();

                if (!duplicateResults.isEmpty()){
                    for (Datacloud.DuplicateResult dr : duplicateResults){
                        System.debug(dr);
                        for (Datacloud.MatchResult matchResult : dr.getMatchResults()){
                            if (matchResult.matchRecords.size() > 0){
                                Datacloud.MatchRecord matchRecord = matchResult.matchRecords[0];
                                SObject matchedRecord = matchRecord.getRecord();

                                System.debug('El resultado es: ' + matchedRecord);

                                if (matchedRecord != null){
                                    if (matchedRecord instanceof Lead){
                                        Lead matchedLead = (Lead) matchedRecord;
                                        result.isDuplicate = true;
                                        result.message = 'Se encontró un duplicado via Data Cloud en Lead.';
                                        result.existingRecordId = matchedLead.Id;
                                        result.ownerName = [SELECT Owner.Name
                                                            FROM Lead
                                                            WHERE Id = :matchedLead.Id
                                                            LIMIT 1].Owner.Name;
                                        result.existingRecordType = 'Lead';
                                        break;
                                    } else if (matchedRecord instanceof Contact){
                                        Contact matchedContact = (Contact) matchedRecord;
                                        result.isDuplicate = true;
                                        result.message = 'Se encontró un duplicado via Data Cloud en Contact.';
                                        result.existingRecordId = matchedContact.Id;
                                        result.ownerName = [SELECT Owner.Name
                                                            FROM Contact
                                                            WHERE Id = :matchedContact.Id
                                                            LIMIT 1].Owner.Name;
                                        result.existingRecordType = 'Contact';
                                        break;
                                    }
                                }
                            }
                        }
                    }
                }
            }
        } catch (Exception e){
            System.debug('Error en Data Cloud API: ' + e.getMessage());
        }

        // Si Data Cloud no encontró duplicados, hacer verificación manual como respaldo
        if (!result.isDuplicate){
            performManualDuplicateCheck(result, firstName, lastName, email, phone, company);
        }

        // Si no se encontraron duplicados por ningún método
        if (!result.isDuplicate){
            result.message = 'No se encontraron duplicados.';
        }

        return result;
    }

    // MÉTODO AUXILIAR PARA VERIFICACIÓN MANUAL
    private static void performManualDuplicateCheck(DuplicateInfo result, String firstName, String lastName, String email, String phone, String company){
        List<Lead> existingLeads = new List<Lead>();

        // Buscar por email (más común para duplicados)
        existingLeads = [SELECT Id, FirstName, LastName, Email, Phone, Company, Owner.Name
                         FROM Lead
                         WHERE Email = :email AND IsConverted = false
                         LIMIT 1];

        // Si no hay duplicados por email, buscar por teléfono
        if (existingLeads.isEmpty() && String.isNotBlank(phone)){
            existingLeads = [SELECT Id, FirstName, LastName, Email, Phone, Company, Owner.Name
                             FROM Lead
                             WHERE Phone = :phone AND IsConverted = false
                             LIMIT 1];
        }

        if (!existingLeads.isEmpty()){
            Lead existingLead = existingLeads[0];
            result.isDuplicate = true;
            result.message = 'Se encontró un duplicado via verificación manual.';
            result.existingRecordId = existingLead.Id;
            result.ownerName = existingLead.Owner.Name;
            result.existingRecordType = 'Lead';
        }
    }

}