public class psg_OpptyExtension {
	
    private ApexPages.StandardController stdController;
    private final Opportunity oppty;

    public List<psg_Commission__c> comisiones { get; set; }
    
    public psg_OpptyExtension(ApexPages.StandardController controller) {
        this.stdController = controller;
        this.oppty = (Opportunity)controller.getRecord();
    }
    
    public PageReference getCommissions() {
        if (oppty != null && oppty.Id != null) {
            comisiones = [
                SELECT Id, Name 
                FROM psg_Commission__c 
                WHERE psg_Opportunity__c = :oppty.Id
            ];
        }
        return null;
    }
}