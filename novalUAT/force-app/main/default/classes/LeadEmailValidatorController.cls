public without sharing class LeadEmailValidatorController {
    @AuraEnabled(cacheable=true)
    public static Boolean checkLeadByEmail(String email) {
        List<Lead> leads = [SELECT Id FROM Lead WHERE Email = :email LIMIT 1];
        return !leads.isEmpty();
    }
}