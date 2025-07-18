public class PSG_CommissionHelper { 
    
    public static void ManageSharing(List<psg_Commission__c> newCommissionList, Map<Id, psg_Commission__c> oldCommissionsMap){
        // [Select id, Closing__r.pba__Offer__r.Agent_2__c, Closing__r.OwnerId from Commission__c Where id in :newCommissionList];
        // SELECT Id, psg_Opportunity__r.Psg_Agent_2__c , psg_Opportunity__r.OwnerId FROM psg_Commission__c
       
        List<psg_Commission__c> commissions = [Select id,psg_Opportunity__c,  psg_Opportunity__r.psg_agent_2__c , psg_Opportunity__r.OwnerId from psg_Commission__c Where id in :newCommissionList];
        List<psg_Commission__share> commissionShares = new List<psg_Commission__share>();
        Map<Id, Set<Id>> commisionWithUserGranted = new Map<Id, Set<Id>>();
        for(psg_Commission__Share commisionShared : [Select ParentId, UserOrGroupId From psg_Commission__Share Where ParentId in :newCommissionList]){
            if(commisionWithUserGranted.containsKey(commisionShared.ParentId)){
                commisionWithUserGranted.get(commisionShared.ParentId).add(commisionShared.UserOrGroupId);
            }else{
                commisionWithUserGranted.put(commisionShared.ParentId, new set<Id>{commisionShared.UserOrGroupId});
            }
        }
        
        commissionShares.addAll(getCommissionShareForOwner(commissions,commisionWithUserGranted));
        commissionShares.addAll(getCommissionShareForAgent2(commissions,commisionWithUserGranted));
        if(commissionShares.size()>0){

            Database.insert(commissionShares, false);
        }
    }

     public static List<psg_Commission__share> getCommissionShareForOwner(List<psg_Commission__c> commissions, Map<Id, Set<Id>> commisionWithUserGranted){
        List<psg_Commission__share> commissionShares = new List<psg_Commission__share>();
        for(psg_Commission__c commission : commissions){
            
            if(commisionWithUserGranted.containsKey(commission.Id)){
                if((commisionWithUserGranted.get(commission.Id)).contains(commission.psg_Opportunity__r.OwnerId)){
                    System.debug('Revisando Commission: ' + commission.Id);
					System.debug('Owner en Opportunity: ' + commission.psg_Opportunity__r.OwnerId);
					System.debug('Usuarios ya compartidos: ' + commisionWithUserGranted.get(commission.Id));

                    continue;
                }
            }           
                psg_Commission__share commissionShare = getCommissionShare(commission.Id, commission.psg_Opportunity__r.OwnerId);
                commissionShares.add(commissionShare);
        }
        return commissionShares;       
    }
    
     public static List<psg_Commission__share> getCommissionShareForAgent2(List<psg_Commission__c> commissions,Map<Id, Set<Id>> commisionWithUserGranted){
        List<psg_Commission__share> commissionShares = new List<psg_Commission__share>();
        for(psg_Commission__c commission : commissions){

            if(commisionWithUserGranted.containsKey(commission.Id)){
                if((commisionWithUserGranted.get(commission.Id)).contains(commission.psg_Opportunity__r.psg_agent_2__c)){
                    continue;
                }
            }
            System.debug(commission.psg_Opportunity__r.psg_agent_2__c);
            if(commission.psg_Opportunity__r.psg_agent_2__c != null){
                psg_Commission__share commissionShare = getCommissionShare(commission.Id, commission.psg_Opportunity__r.psg_agent_2__c);
                commissionShares.add(commissionShare);
            }
        }
        return commissionShares;
    }
    
    public static psg_Commission__share getCommissionShare(Id commisionId, Id userId){
        psg_Commission__share commissionShare = new psg_Commission__share();
        commissionShare.ParentId = commisionId;
        commissionShare.UserOrGroupId = userId;
        commissionShare.RowCause = 'Manual';
        commissionShare.AccessLevel = 'Edit';
        return commissionShare;
    }

}