trigger PSG_CommissionTrigger on psg_Commission__c (after insert, after update) {
	new PSG_CommissionTriggerHandler().run();
}