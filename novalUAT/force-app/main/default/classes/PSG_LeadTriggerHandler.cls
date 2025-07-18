public with sharing class PSG_LeadTriggerHandler extends PSG_TriggerHandler {
    private List<Lead> newLeads;
    
    public PSG_LeadTriggerHandler() {
        System.debug('Estoy en el handler');

        this.newLeads = (List<Lead>)Trigger.new;
    }

    public override void beforeInsert(){
        System.debug('Estoy en el handler en el beforeInsert');
        PSG_LeadHelper.assignLead(this.newLeads);
    }
}