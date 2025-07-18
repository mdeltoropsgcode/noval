trigger PSG_LeadTrigger on Lead (before insert) {
    System.debug('Estoy en el trigger');
    new PSG_LeadTriggerHandler().run();
}