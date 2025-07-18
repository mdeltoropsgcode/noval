public without sharing class PSG_ReservationFromWizardController{
    @AuraEnabled(cacheable = true)
    public static string getContactInfo(string recordId){
        try{
            System.debug('Oppty Id: ' + recordId);
            Opportunity opp = [SELECT Id, psg_Contact__c
                               FROM Opportunity
                               WHERE Id = :recordId
                               LIMIT 1];
            System.debug('Oppty : ' + opp);
            Contact contact = [SELECT Id, FirstName, LastName, Email, Phone, MobilePhone, psg_ID_Passport__c, psg_Identification_Type__c, psg_Marital_Status__c, PSG_Global_Nationality__c, Birthdate, psg_Profession__c, psg_Occupation_Details__c, MailingStreet, MailingCity, MailingState, MailingPostalCode, psg_Has_Other_Citizenship__c, psg_Other_Citizenship__c, PSG_Is_owner__c
                               FROM Contact
                               WHERE Id = :opp.psg_Contact__c
                               LIMIT 1];
            System.debug('contact : ' + contact);
            return contact.Id;
        } catch (Exception e){
            throw new AuraHandledException(e.getMessage());
        }
    }

    @AuraEnabled
    public static Product2Wrapper getProduct2(string recordId){
        Product2Wrapper product2Wrapper;
        try{

            Opportunity oportunidad = [SELECT Id, psg_Reservation_Amount__c
                                       FROM Opportunity
                                       WHERE Id = :recordId
                                       LIMIT 1];

            System.debug('Uno 1:' + recordId);
            OpportunityLineitem opptyLineItem = [Select Product2Id
                                                 From OpportunityLineItem
                                                 Where OpportunityId = :recordId
                                                 LIMIT 1];

            System.debug('--dos 2:');
            List<Product2> products = [SELECT Id, Name, Project__c, psg_Building__c, psg_Bedrooms__c, psg_Total_Local_M2__c, psg_Unit_Level__c, psg_Parking_Spaces__c, psg_Price__c, psg_Final_Delivery_Date__c
                                       FROM Product2
                                       WHERE Id = :opptyLineItem.Product2Id];

            System.debug('--tres 3:');
            Product2 product;

            psg_Project__c project;
            if (products.size() > 0){
                product = products[0];
                List<psg_Project__c> projects = [SELECT Id, Name
                                                 FROM psg_Project__c
                                                 WHERE Id = :product.Project__c];
                if (projects.size() > 0){
                    project = projects[0];
                }
            }


            Map<String, Object> jsonMap = new Map<String, Object>();

            // Calcular el monto total de la transacción (sin puntos ni comas, últimos dos dígitos como decimales)
            Decimal reservationAmount = (oportunidad.psg_Reservation_Amount__c != null) ? oportunidad.psg_Reservation_Amount__c : 0;
            Integer totalAmountInCents = (reservationAmount * 100).intValue();
            String formattedAmount = String.valueOf(totalAmountInCents);

            System.debug('Formatted ammount: ' + formattedAmount);

            jsonMap.put('psg_Reservation_Amount__c', formattedAmount);

            if (product != null){
                for (String fieldName : product.getPopulatedFieldsAsMap().keySet()){

                    if (fieldName != 'Project__c'){
                        System.debug(fieldName + ': ' + product.get(fieldName));
                        jsonMap.put(fieldName, product.get(fieldName));
                    }
                }

                if (project != null){
                    jsonMap.put('projectName', project.get('Name'));
                }
                product2Wrapper = new Product2Wrapper(jsonMap);

            }
            return product2Wrapper;
        } catch (Exception e){
            throw new AuraHandledException(e.getMessage());
        }
    }

    @AuraEnabled
    public static void updateContactInfo(string info){
        try{
            ReservationAccount accountInfo = (ReservationAccount)JSON.deserialize(info, ReservationAccount.class);

            Opportunity oppty = [Select Id, AccountId, psg_Contact__c
                                 From Opportunity
                                 Where Id = :accountInfo.opptyId
                                 Limit 1];
            Contact con = [Select Id, FirstName, LastName
                           From Contact
                           Where Id = :oppty.psg_Contact__c
                           Limit 1];

            boolean accountNameChanged = false;
            if (con.FirstName != accountInfo.firstName || con.LastName != accountInfo.lastName){
                accountNameChanged = true;
            }

            Contact contact = new Contact();
            contact.Id = accountInfo.id;
            contact.FirstName = accountInfo.firstName;
            contact.LastName = accountInfo.lastName;
            contact.Email = accountInfo.email;
            contact.Phone = accountInfo.phone;
            contact.MobilePhone = accountInfo.MobilePhone;
            contact.psg_ID_Passport__c = accountInfo.identificationNumber;
            contact.psg_Identification_Type__c = accountInfo.identificationType;
            contact.PSG_Global_Nationality__c = accountInfo.nationality;
            contact.psg_Marital_Status__c = accountInfo.maritalStatus;
            contact.Birthdate = Date.valueOf(accountInfo.birthDate);
            contact.psg_Profession__c = accountInfo.profession;
            contact.psg_Occupation_Details__c = accountInfo.occupationDetails;
            contact.MailingStreet = accountInfo.address;
            contact.MailingCity = accountInfo.city;
            contact.MailingState = accountInfo.state;
            contact.MailingPostalCode = accountInfo.postalCode;
            contact.psg_Another_Nationality__c = accountInfo.hasOtherCitizenship;
            contact.psg_Nationality_2__c = accountInfo.otherCitizenship;

            contact.PSG_Spouse_First_Name__c = accountInfo.spouseName;
            contact.PSG_Spouse_Last_Name__c = accountInfo.spouseLastName;
            contact.PSG_Spouse_Id_Passport__c = accountInfo.spouseIdNumber;
            contact.PSG_Spouse_Birth_Place__c = accountInfo.spouseBirthPlace;
            contact.PSG_Spouse_Nationality__c = accountInfo.spouseNationality;
            contact.PSG_Spouse_Profession__c = accountInfo.spouseProfession;
            contact.Spouse_Profession_Detail__c = accountInfo.spouseProfessionDetail;
            contact.PSG_Is_owner__c = accountInfo.isOwner;

            contact.psg_Business_Name__c = accountInfo.businessName;
            contact.psg_Business_Activity__c = accountInfo.businessActivity;
            contact.psg_Business_Phone__c = accountInfo.businessPhone;
            contact.psg_Ocupation_in_Business__c = accountInfo.businessOcupation;
            contact.psg_Supervisor_in_Business__c = accountInfo.businessSupervisor;
            contact.psg_Source_of_Funds__c = accountInfo.sourceOfFunds;
            contact.psg_Main_Activity__c = accountInfo.mainActivity;
            contact.psg_Last_Occupation__c = accountInfo.lastOcupation;
            contact.psg_Another_Activity__c = accountInfo.anotherActivity;
            
            contact.psg_How_Heard__c = accountInfo.howHeard;
            contact.psg_Specify_Other_How_Heard__c = accountInfo.otherHowHeard;
            contact.psg_Nombre_de_Banco__c = accountInfo.nombreBanco;
            contact.psg_Account_Number__c = accountInfo.accountNo;
            contact.psg_Tipo_de_cuenta__c = accountInfo.tipoCuenta;
            contact.psg_bank_Branch__c = accountInfo.bankBranch;
            contact.psg_Bank_Phone__c = accountInfo.bankPhone;
            contact.psg_Politically_exposed__c = accountInfo.politicallyExposed;
            contact.psg_Link_with_Politician__c = accountInfo.linkWithPolitician;
            contact.psg_Relationship_with_Politician__c = accountInfo.relationshipWithPolitician;
            contact.psg_Other_Link__c = accountInfo.otherLink;
            
            contact.psg_Comercial_Referral_Name__c = accountInfo.comercialReferralName;
            contact.psg_Comercial_Contact_Name__c = accountInfo.comercialContactName;
            contact.psg_Comercial_Referral_Address__c = accountInfo.comercialReferralAddress;
            contact.psg_Comercial_Referral_Phone__c = accountInfo.comercialReferralPhone;
            contact.psg_Laboral_Referral_Name__c = accountInfo.laboralReferralName;
            contact.psg_Laboral_Referral_Ocupation__c = accountInfo.laboralReferralOcupation;
            contact.psg_Laboral_Referral_Phone__c = accountInfo.laboralReferralPhone;
            
            contact.psg_Politician_Parentheses__c = accountInfo.politicianParentheses;
            contact.psg_Politician_Name__c = accountInfo.politicianName;
            contact.psg_Politician_Position__c = accountInfo.politicianPosition;
            contact.psg_Politician_Institution__c = accountInfo.politicianInstitution;


            contact.psg_contactInfoFilled__c = true;

            update contact;

            if (accountNameChanged){
                Account ac = new Account();
                ac.id = oppty.AccountId;
                ac.Name = accountInfo.firstName + ' ' + accountInfo.lastName;

                update ac;
            }
        } catch (Exception e){
            throw new AuraHandledException(e.getMessage());
        }
    }

    @AuraEnabled
    public static Map<String, String> getPaymentFormData(String oppId, String orderNumber, string amount){

        try{
            String merchantId = '39038540035';
            String merchantName = 'Noval Properties';
            String merchantType = 'Inmobiliaria';
            String currencyCode = '$';
            String itbis = '000';
            String approvedUrl = 'https://dream-flow-4690--psguat.sandbox.my.site.com/portal/pago-reserva?c__recordId=' + oppId + '&status=approved';
            String declinedUrl = 'https://dream-flow-4690--psguat.sandbox.my.site.com/portal/pago-reserva?c__recordId=' + oppId + '&status=declined';
            String cancelUrl = 'https://dream-flow-4690--psguat.sandbox.my.site.com/portal/pago-reserva?c__recordId=' + oppId + '&status=cancelled';
            String useCustomField1 = '0';
            String customField1Label = '';
            String customField1Value = '';
            String useCustomField2 = '0';
            String customField2Label = '';
            String customField2Value = '';
            String authKey = 'asdhakjshdkjasdasmndajksdkjaskldga8odya9d8yoasyd98asdyaisdhoaisyd0a8sydoashd8oasydoiahdpiashd09ayusidhaos8dy0a8dya08syd0a8ssdsax';

            String dataToHash = merchantId + merchantName + merchantType + currencyCode + orderNumber + amount + itbis + approvedUrl + declinedUrl + cancelUrl + useCustomField1 + customField1Label + customField1Value + useCustomField2 + customField2Label + customField2Value + authKey;

            Blob key = Blob.valueOf(authKey);
            Blob data = Blob.valueOf(dataToHash);
            Blob hmac = Crypto.generateMac('HmacSHA512', data, key);
            String authHash = EncodingUtil.convertToHex(hmac);

            // Crear un mapa con todos los valores necesarios
            Map<String, String> formData = new Map<String, String>();
            formData.put('MerchantId', merchantId);
            formData.put('MerchantName', merchantName);
            formData.put('MerchantType', merchantType);
            formData.put('CurrencyCode', currencyCode);
            formData.put('OrderNumber', orderNumber);
            formData.put('Amount', amount);
            formData.put('ITBIS', itbis);
            formData.put('ApprovedUrl', approvedUrl);
            formData.put('DeclinedUrl', declinedUrl);
            formData.put('CancelUrl', cancelUrl);
            formData.put('UseCustomField1', useCustomField1);
            formData.put('CustomField1Label', customField1Label);
            formData.put('CustomField1Value', customField1Value);
            formData.put('UseCustomField2', useCustomField2);
            formData.put('CustomField2Label', customField2Label);
            formData.put('CustomField2Value', customField2Value);
            formData.put('AuthHash', authHash);

            return formData;
        } catch (Exception e){
            throw new AuraHandledException('Error al generar los datos del formulario: ' + e.getMessage());
        }
    }

    @AuraEnabled(cacheable = true)
    public static List<string> getNationalities(){
        try{
            //Get global value set picklist values and return as a list
            Schema.DescribeFieldResult fieldResult = Contact.PSG_Global_Nationality__c.getDescribe();
            List<Schema.PicklistEntry> ple = fieldResult.getPicklistValues();
            List<string> picklistValues = new List<string>();
            for (Schema.PicklistEntry entry : ple){
                picklistValues.add(entry.getValue());
            }
            return picklistValues;
        } catch (Exception e){
            throw new AuraHandledException(e.getMessage());
        }
    }
    
    @AuraEnabled(cacheable = true)
    public static List<string> getBankNames(){
        try{
            //Get global value set picklist values and return as a list
            Schema.DescribeFieldResult fieldResult = Contact.psg_Nombre_de_Banco__c.getDescribe();
            List<Schema.PicklistEntry> ple = fieldResult.getPicklistValues();
            List<string> picklistValues = new List<string>();
            for (Schema.PicklistEntry entry : ple){
                picklistValues.add(entry.getValue());
            }
            return picklistValues;
        } catch (Exception e){
            throw new AuraHandledException(e.getMessage());
        }
    }

    @AuraEnabled
    public static PSG_Payment_Validation__c createPaymentValidation(Map<String, Object> paymentValidation, string fileName, string fileType, string fileBase64Body){
        PSG_Payment_Validation__c newPaymentValidation = new PSG_Payment_Validation__c();

        try{
            string customerId = (String) paymentValidation.get('customerId');
            if (customerId == null || customerId == ''){
                throw new AuraHandledException('El cliente no existe.');
            }
            Contact customer = [Select OwnerId
                                From Contact
                                Where Id = :customerId
                                Limit 1];
            newPaymentValidation.PSG_Opportunity__c = (String) paymentValidation.get('recordId');
            newPaymentValidation.PSG_Contact__c = (String) paymentValidation.get('customerId');
            newPaymentValidation.PSG_Amount__c = Decimal.valueOf((string) paymentValidation.get('Amount'));
            newPaymentValidation.psg_Currency__c = (String) paymentValidation.get('Currency');
            newPaymentValidation.psg_Bank_Account_No__c = (String) paymentValidation.get('NoBank');
            newPaymentValidation.psg_Bank__c = (String) paymentValidation.get('Bank');
            newPaymentValidation.psg_No_Reference__c = (String) paymentValidation.get('NoReference');
            newPaymentValidation.PSG_Payment_Date__c = Date.ValueOf((string) paymentValidation.get('Date'));
            newPaymentValidation.psg_Status__c = 'Pendiente';
            newPaymentValidation.PSG_Concept__c = 'Reserva';
            newPaymentValidation.psg_Approver_User__c = customer.OwnerId;

            insert newPaymentValidation;

            Blob fileBody = EncodingUtil.base64Decode(fileBase64Body);

            if (fileBody != null){
                Attachment attachment = new Attachment();
                attachment.ParentId = newPaymentValidation.Id;
                attachment.Name = fileName;
                attachment.Body = fileBody;
                insert attachment;
            }
        } catch (Exception ex){
            System.debug('Error: ' + ex.getMessage());
            throw new AuraHandledException('Error al crear la solicitud de validación de pago: ' + ex.getMessage());
        }


        PSG_Payment_Validation__c createdPaymentValidation = [SELECT Id, Name
                                                              FROM PSG_Payment_Validation__c
                                                              WHERE Id = :newPaymentValidation.Id];


        return createdPaymentValidation;
    }

    public static void updateOpportunity(string recordId){
        Opportunity opp = [SELECT Id, StageName
                           FROM Opportunity
                           WHERE Id = :recordId
                           LIMIT 1];
        opp.psg_AzulValidatedPayment__c = true;
        update opp;
    }

    public class Product2Wrapper{
        //Product2
        @AuraEnabled
        public String project{ get; set; }

        @AuraEnabled
        public String apartment{ get; set; }

        @AuraEnabled
        public String bedroom{ get; set; }

        @AuraEnabled
        public String floorArea{ get; set; }

        @AuraEnabled
        public String floor{ get; set; }

        @AuraEnabled
        public String parking{ get; set; }

        @AuraEnabled
        public String amount{ get; set; }

        @AuraEnabled
        public String reservationAmount{ get; set; }

        @AuraEnabled
        public String deliveryDate{ get; set; }

        @AuraEnabled
        public String paymentMethod{ get; set; }

        public Product2Wrapper(Map<String, Object> jsonMap){
            this.project = getStringValue(jsonMap, 'projectName');
            this.apartment = getStringValue(jsonMap, 'Name');
            this.bedroom = getStringValue(jsonMap, 'psg_Bedrooms__c');
            this.floorArea = getStringValue(jsonMap, 'psg_Total_Local_M2__c');
            this.floor = getStringValue(jsonMap, 'psg_Unit_Level__c');
            this.parking = getStringValue(jsonMap, 'psg_Parking_Spaces__c');
            this.amount = getStringValue(jsonMap, 'psg_Price__c');
            this.deliveryDate = getStringValue(jsonMap, 'psg_Final_Delivery_Date__c');
            this.reservationAmount = getStringValue(jsonMap, 'psg_Reservation_Amount__c');
            this.paymentMethod = getStringValue(jsonMap, 'psg_Payment_Method__c');
        }

        private String getStringValue(Map<String, Object> mapData, String key){
            System.debug('getStringValue: ' + key + ' ' + mapData.get(key));
            return mapData.containsKey(key) ? String.valueOf(mapData.get(key)) : null;
        }

    }

    public class ReservationAccount{
        @AuraEnabled
        public String id{ get; set; }

        @AuraEnabled
        public String opptyId{ get; set; }

        @AuraEnabled
        public String firstName{ get; set; }

        @AuraEnabled
        public String lastName{ get; set; }

        @AuraEnabled
        public String email{ get; set; }

        @AuraEnabled
        public String phone{ get; set; }

        @AuraEnabled
        public String MobilePhone{ get; set; }

        @AuraEnabled
        public String identificationType{ get; set; }

        @AuraEnabled
        public String identificationNumber{ get; set; }

        //Campos Conyuge
        @AuraEnabled
        public String spouseName{ get; set; }

        @AuraEnabled
        public String spouseLastName{ get; set; }

        @AuraEnabled
        public String spouseIdNumber{ get; set; }

        @AuraEnabled
        public String spouseBirthPlace{ get; set; }

        @AuraEnabled
        public String spouseNationality{ get; set; }

        @AuraEnabled
        public String spouseProfession{ get; set; }

        @AuraEnabled
        public String spouseProfessionDetail{ get; set; }

        //REVISAR TODOS LOS CAMPOS
        //Detalles de la ingresos
        @AuraEnabled
        public String businessName{ get; set; }

        @AuraEnabled
        public String businessActivity{ get; set; }

        @AuraEnabled
        public String businessPhone{ get; set; }

        @AuraEnabled
        public String businessAddress{ get; set; }

        @AuraEnabled
        public String businessOcupation{ get; set; }

        @AuraEnabled
        public String businessSupervisor{ get; set; }

        @AuraEnabled
        public String sourceOfFunds{ get; set; }

        @AuraEnabled
        public String mainActivity{ get; set; }
     
        @AuraEnabled
        public String lastOcupation{ get; set; }

        @AuraEnabled
        public String anotherActivity{ get; set; }
        
        @AuraEnabled
        public String howHeard{ get; set; }
       
        @AuraEnabled
        public String otherHowHeard{ get; set; }
       
        @AuraEnabled
        public String nombreBanco{ get; set; }
       
        @AuraEnabled
        public String accountNo{ get; set; }
       
        @AuraEnabled
        public String tipoCuenta{ get; set; }
       
        @AuraEnabled
        public String bankBranch{ get; set; }
 
        @AuraEnabled
        public String bankPhone{ get; set; }
 
        @AuraEnabled
        public String comercialReferralName{ get; set; }
 
        @AuraEnabled
        public String comercialContactName{ get; set; }
 
        @AuraEnabled
        public String comercialReferralAddress{ get; set; }
 
        @AuraEnabled
        public String comercialReferralPhone{ get; set; }
 
        @AuraEnabled
        public String laboralReferralName{ get; set; }
 
        @AuraEnabled
        public String laboralReferralOcupation{ get; set; }
 
        @AuraEnabled
        public String laboralReferralPhone{ get; set; }
        
        @AuraEnabled
        public String politicallyExposed{ get; set; }
        
        @AuraEnabled
        public String linkWithPolitician{ get; set; }
        
        @AuraEnabled
        public String relationshipWithPolitician{ get; set; }
        
        @AuraEnabled
        public String otherLink{ get; set; }
        
        @AuraEnabled
        public String politicianParentheses{ get; set; }
        
        @AuraEnabled
        public String politicianName{ get; set; }
        
        @AuraEnabled
        public String politicianPosition{ get; set; }
        
        @AuraEnabled
        public String politicianInstitution{ get; set; }

        // Campos existentes
        @AuraEnabled
        public String nationality{ get; set; }

        @AuraEnabled
        public String maritalStatus{ get; set; }

        @AuraEnabled
        public String birthDate{ get; set; }

        @AuraEnabled
        public String profession{ get; set; }

        @AuraEnabled
        public Boolean isOwner{ get; set; }

        @AuraEnabled
        public String occupationDetails{ get; set; }

        // Nuevos campos
        @AuraEnabled
        public String hasOtherCitizenship{ get; set; }

        @AuraEnabled
        public String otherCitizenship{ get; set; }

        @AuraEnabled
        public String address{ get; set; }

        @AuraEnabled
        public String city{ get; set; }

        @AuraEnabled
        public String state{ get; set; }

        @AuraEnabled
        public String postalCode{ get; set; }

    }

}