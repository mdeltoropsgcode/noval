public with sharing class PSG_GetAccountLas90DaysActivity{
    public class ResultWrapper{
        @AuraEnabled
        public Integer contacts;
        @AuraEnabled
        public Integer opportunities;
        @AuraEnabled
        public Integer showings;
        
        public ResultWrapper(Integer contacts, Integer opportunities, Integer showings) {
            this.contacts = contacts;
            this.opportunities = opportunities;
            this.showings = showings;
        }
    }

    @AuraEnabled(cacheable=true)
    public static ResultWrapper getData(Id accountId){

        AggregateResult[] contacts = [SELECT COUNT(Id)contacts
                                      FROM Contact
                                      WHERE psg_Referral_Contact__r.AccountId = :accountId AND CreatedDate >= LAST_90_DAYS];

        AggregateResult[] opportunities = [SELECT COUNT(Id)opportunities
                                           FROM Opportunity
                                           WHERE psg_Contact__r.psg_Referral_Contact__r.AccountId  = :accountId AND CreatedDate >= LAST_90_DAYS];

        // showings
        List<Opportunity> oppsIdForShowings = [SELECT Id
                                               FROM Opportunity
                                               WHERE psg_Contact__r.psg_Referral_Contact__r.AccountId  = :accountId];

        AggregateResult[] showings = [SELECT COUNT(Id)showings
                                      FROM Event
                                      WHERE WhatId IN:oppsIdForShowings AND RecordType.Name = 'Showing' AND CreatedDate >= LAST_90_DAYS];

        ResultWrapper results = new ResultWrapper(
            (Integer)contacts[0].get('contacts'), 
            (Integer)opportunities[0].get('opportunities'), 
            (Integer)showings[0].get('showings') );
        System.debug('Resultados:  '+results);
        return results;
    }

}