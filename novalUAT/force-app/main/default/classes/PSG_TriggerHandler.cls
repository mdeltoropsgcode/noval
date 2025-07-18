/**
* ─────────────────────────────────────────────────────────────────────────────────────────────────┐
* Trigger framework Base Class inspired in https://github.com/kevinohara80/sfdc-trigger-framework
* All trigger handler should extend this class and implement the trigger logic.
* All the trigger should call the run method of the handler class.
* All trigger handler should be included in the Triggers_Configuration__mdt custom metadata type.
* The base class includes context-specific methods that are automatically called when a trigger is executed.
* The base class also provides a secondary role as a supervisor for Trigger execution.
* ──────────────────────────────────────────────────────────────────────────────────────────────────
* @author         Jose Alberto Nunez  
* @modifiedBy     Jonatan Beleno
* @version        1.0
* @created        2025-03-20
* @modified       2025-03-
* ──────────────────────────────────────────────────────────────────────────────────────────────────
* @changes
* vX.X            Name
* YYYY-MM-DD      Explanation of the change.  Multiple lines can be used to explain the change, but
*                 each line should be indented till left aligned with the previous description text.
*
* ─────────────────────────────────────────────────────────────────────────────────────────────────┘
*/
public virtual class PSG_TriggerHandler {
    
    // static map of handlername, times run() was invoked
    private static Map<String, LoopCount> loopCountMap;
    private static Set<String> bypassedHandlers;
    private static Set<String> bypassedValidations;
    // static map of handlername, configuration metadata
    private static Map<String, PSG_Trigger_Configuration__mdt> triggerConfigurationMap;
    
    // the current context of the trigger, overridable in tests
    @TestVisible
    private TriggerContext context;
    
    @TestVisible
    private Boolean isTriggerExecuting;
    
    // static initialization
    static {
        loopCountMap = new Map<String, LoopCount>();
        bypassedHandlers = new Set<String>();
        bypassedValidations = new Set<String>();
        triggerConfigurationMap = new Map<String, PSG_Trigger_Configuration__mdt>();
    }
    
    // constructor
    public PSG_TriggerHandler() {
        this.setTriggerContext();
    }
    
    /***************************************
	* public instance methods
	***************************************/
    
    // main method that will be called during execution
    public void run() {
 
        if(!validateRun()) {
            return;
        }
 
        addToLoopCount();
        
        //Triggers_Configuration__mdt triggerConfiguration;
        string handlerName = getHandlerName();
        PSG_Trigger_Configuration__mdt triggerConfiguration = getTriggerConfigurationMdt(handlerName);
        
        // dispatch to the correct handler method
        if(this.context == TriggerContext.BEFORE_INSERT && triggerConfiguration.Before_Insert__c) {
            this.beforeInsert();
        } else if(this.context == TriggerContext.BEFORE_UPDATE && triggerConfiguration.Before_Update__c) {
            this.beforeUpdate();
        } else if(this.context == TriggerContext.BEFORE_DELETE && triggerConfiguration.Before_Delete__c) {
            this.beforeDelete();
        } else if(this.context == TriggerContext.AFTER_INSERT && triggerConfiguration.After_Insert__c) {
            this.afterInsert();
        } else if(this.context == TriggerContext.AFTER_UPDATE && triggerConfiguration.After_Update__c) {
            this.afterUpdate();
        } else if(this.context == TriggerContext.AFTER_DELETE && triggerConfiguration.After_Delete__c) {
            this.afterDelete();
        } else if(this.context == TriggerContext.AFTER_UNDELETE && triggerConfiguration.After_Undelete__c) {
            this.afterUndelete();
        }
    }
    
    private PSG_Trigger_Configuration__mdt getTriggerConfigurationMdt(string handlerName){
        
        if(PSG_TriggerHandler.triggerConfigurationMap.containsKey(handlerName)){
            return PSG_TriggerHandler.triggerConfigurationMap.get(handlerName);
        }
        
        List<PSG_Trigger_Configuration__mdt> triggerConfigurations = [
            SELECT Before_Insert__c
            , Before_Update__c
            , Before_Delete__c
            , After_Insert__c
            , After_Update__c
            , After_Delete__c
            , After_Undelete__c
            FROM PSG_Trigger_Configuration__mdt
            WHERE Trigger_Handler_API_Name__c = :handlerName
        ];
        
        if(triggerConfigurations.size() > 0){
            PSG_TriggerHandler.triggerConfigurationMap.put(handlerName, triggerConfigurations[0]);
            return triggerConfigurations[0];
        }
        else{
            throw new TriggerHandlerException('No trigger configuration found for ' + handlerName); 
        }
    }
    
    @TestVisible
    private void setTriggerConfigurationMdt(string handlerName, PSG_Trigger_Configuration__mdt triggerConfigurationMdt){
        if(!PSG_TriggerHandler.triggerConfigurationMap.containsKey(handlerName)){
            PSG_TriggerHandler.triggerConfigurationMap.put(handlerName, triggerConfigurationMdt);
        }
    }
        
    public void setMaxLoopCount(Integer max) {
        String handlerName = getHandlerName();
        if(!PSG_TriggerHandler.loopCountMap.containsKey(handlerName)) {
            PSG_TriggerHandler.loopCountMap.put(handlerName, new LoopCount(max));
        } else {
            PSG_TriggerHandler.loopCountMap.get(handlerName).setMax(max);
        }
    }
    
    public void clearMaxLoopCount() {
        this.setMaxLoopCount(-1);
    }
    
    /***************************************
	* public static methods
	***************************************/
    
    public static void bypass(String handlerName) {
        PSG_TriggerHandler.bypassedHandlers.add(handlerName);
    }
    
    public static void clearBypass(String handlerName) {
        PSG_TriggerHandler.bypassedHandlers.remove(handlerName);
    }
    
    public static Boolean isBypassed(String handlerName) {
        return PSG_TriggerHandler.bypassedHandlers.contains(handlerName);
    }
    
    public static void clearAllBypasses() {
        PSG_TriggerHandler.bypassedHandlers.clear();
    }
    
    public static void bypassValidations(String handlerName) {
        PSG_TriggerHandler.bypassedValidations.add(handlerName);
    }
    
    public static void clearBypassValidations(String handlerName) {
        PSG_TriggerHandler.bypassedValidations.remove(handlerName);
    }
    
    public static Boolean isBypassedValidations(String handlerName) {
        return PSG_TriggerHandler.bypassedValidations.contains(handlerName);
    }
    
    public static void clearAllBypassesValidations() {
        PSG_TriggerHandler.bypassedValidations.clear();
    }
    
    /***************************************
	* private instancemethods
	***************************************/
    
    @TestVisible
    private void setTriggerContext() {
        this.setTriggerContext(null, false);
    }
    
    @TestVisible
    private void setTriggerContext(String ctx, Boolean testMode) {
        if(!Trigger.isExecuting && !testMode) {
            this.isTriggerExecuting = false;
            return;
        } 
        else {
            this.isTriggerExecuting = true;
        }
        
        if((Trigger.isExecuting && Trigger.isBefore && Trigger.isInsert) || (ctx != null && ctx == 'before insert')) {
            this.context = TriggerContext.BEFORE_INSERT;
        } 
        else if((Trigger.isExecuting && Trigger.isBefore && Trigger.isUpdate) || (ctx != null && ctx == 'before update')){
            this.context = TriggerContext.BEFORE_UPDATE;
        }
        else if((Trigger.isExecuting && Trigger.isBefore && Trigger.isDelete) || (ctx != null && ctx == 'before delete')) {
            this.context = TriggerContext.BEFORE_DELETE;
        } 
        else if((Trigger.isExecuting && Trigger.isAfter && Trigger.isInsert) || (ctx != null && ctx == 'after insert')) {
            this.context = TriggerContext.AFTER_INSERT;
        } 
        else if((Trigger.isExecuting && Trigger.isAfter && Trigger.isUpdate) || (ctx != null && ctx == 'after update')) {
            this.context = TriggerContext.AFTER_UPDATE;
        } 
        else if((Trigger.isExecuting && Trigger.isAfter && Trigger.isDelete) || (ctx != null && ctx == 'after delete')) {
            this.context = TriggerContext.AFTER_DELETE;
        } 
        else if((Trigger.isExecuting && Trigger.isAfter && Trigger.isUndelete) || (ctx != null && ctx == 'after undelete')) {
            this.context = TriggerContext.AFTER_UNDELETE;
        }
    }
    
    // increment the loop count
    @TestVisible
    private void addToLoopCount() {
        String handlerName = getHandlerName();
        if(PSG_TriggerHandler.loopCountMap.containsKey(handlerName)) {
            Boolean exceeded = PSG_TriggerHandler.loopCountMap.get(handlerName).increment();
            if(exceeded) {
                Integer max = PSG_TriggerHandler.loopCountMap.get(handlerName).max;
                throw new TriggerHandlerException('Maximum loop count of ' + String.valueOf(max) + ' reached in ' + handlerName);
            }
        }
    }
    
    // make sure this trigger should continue to run
    @TestVisible
    private Boolean validateRun() {
        if(!this.isTriggerExecuting || this.context == null) {
            throw new TriggerHandlerException('Trigger handler called outside of Trigger execution');
        }
        return !PSG_TriggerHandler.bypassedHandlers.contains(getHandlerName());
    }
    
    @TestVisible
    private String getHandlerName() {
        return String.valueOf(this).substring(0,String.valueOf(this).indexOf(':'));
    }
    
    /***************************************
	* context methods
	***************************************/
    
    // context-specific methods for override
    @TestVisible
    protected virtual void beforeInsert(){}
    @TestVisible
    protected virtual void beforeUpdate(){}
    @TestVisible
    protected virtual void beforeDelete(){}
    @TestVisible
    protected virtual void afterInsert(){}
    @TestVisible
    protected virtual void afterUpdate(){}
    @TestVisible
    protected virtual void afterDelete(){}
    @TestVisible
    protected virtual void afterUndelete(){}
    
    /***************************************
	* inner classes
	***************************************/
    
    // inner class for managing the loop count per handler
    @TestVisible
    private class LoopCount {
        private Integer max;
        private Integer count;
        
        public LoopCount() {
            this.max = 5;
            this.count = 0;
        }
        
        public LoopCount(Integer max) {
            this.max = max;
            this.count = 0;
        }
        
        public Boolean increment() {
            this.count++;
            return this.exceeded();
        }
        
        public Boolean exceeded() {
            return this.max >= 0 && this.count > this.max;
        }
        
        public Integer getMax() {
            return this.max;
        }
        
        public Integer getCount() {
            return this.count;
        }
        
        public void setMax(Integer max) {
            this.max = max;
        }
    }
    
    // possible trigger contexts
    @TestVisible
    private enum TriggerContext {
        	BEFORE_INSERT,
            BEFORE_UPDATE, 
            BEFORE_DELETE,
            AFTER_INSERT, 
            AFTER_UPDATE, 
            AFTER_DELETE,
            AFTER_UNDELETE
    }
    
    // exception class
    public class TriggerHandlerException extends Exception {}

}