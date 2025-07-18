public with sharing class PSG_Product2PathHelper{
    public class PicklistOption{
        @AuraEnabled
        public String value{ get; set; }

        @AuraEnabled
        public String label{ get; set; }

        public PicklistOption(String value, String label){
            this.value = value;
            this.label = label;
        }

    }

    @AuraEnabled(cacheable = false)
    public static List<PicklistOption> getStatuses(){
        Schema.DescribeFieldResult field = Product2.psg_Status__c.getDescribe();
        List<Schema.PicklistEntry> picklist = field.getPicklistValues();

        List<PicklistOption> picklistOptions = new List<PicklistOption>();
        for (Schema.PicklistEntry entry : picklist){
            picklistOptions.add(new PicklistOption(entry.getValue(), entry.getLabel()));
        }

        return picklistOptions;
    }

    @AuraEnabled(cacheable = false)
    public static String getActualStatus(Id recordId){
        Product2 product = [SELECT Id, psg_Status__c
                            FROM Product2
                            WHERE Id = :recordId
                            Limit 1];
        System.debug(product.psg_Status__c);
        return product.psg_Status__c;
    }

    @AuraEnabled(cacheable = true)
    public static String getUserProfile(){
        return [SELECT Profile.Name
                FROM User
                WHERE Id = :UserInfo.getUserId()].Profile.Name;
    }

    @AuraEnabled
    public static String setStatus(Id recordId, String newStatus){
        // Validar si el usuario actual tiene el perfil de System Administrator
        String userProfileName = getUserProfile();
        if (userProfileName != 'System Administrator'){
            throw new AuraHandledException('No tienes permisos para modificar el estado.');
        }

        Product2 product = [SELECT Id, psg_Status__c
                            FROM Product2
                            WHERE Id = :recordId
                            Limit 1];
        product.psg_Status__c = newStatus;

        try{
            update product;
            return product.psg_Status__c;
        } catch (Exception e){
            throw new AuraHandledException('An error occurred: ' + e.getMessage());
        }
    }

}