public class PSG_CommissionTriggerHandler extends PSG_TriggerHandler{
  
    private Map<Id, psg_Commission__c> oldCommissionsMap;
    private List<psg_Commission__c> newCommissionList; 
    
    public PSG_CommissionTriggerHandler(){
        this.oldCommissionsMap = (Map<Id, psg_Commission__c> )Trigger.oldMap;
        this.newCommissionList = (List<psg_Commission__c> )Trigger.new;
    }
    
    public override void afterInsert(){
        PSG_CommissionHelper.ManageSharing(this.newCommissionList, null);
    }
    
    public override void afterUpdate(){
        PSG_CommissionHelper.ManageSharing(this.newCommissionList, this.oldCommissionsMap);
    }
}