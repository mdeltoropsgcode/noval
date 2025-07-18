@IsTest(SeeAllData=False)
public class PaymentPlanPDFControllerTest {
  
  public static testmethod void Test1() {
        Test.startTest();

        Opportunity opp = new Opportunity();
        opp.Name = 'Oportunidad de prueba'; 
       // opp.psg_Price__c = 200000.8;
        opp.StageName = 'Prospecting';
        opp.CloseDate = Date.today().addMonths(6);
        opp.psg_Delivery_Date__c = Date.today().addYears(4);
        insert opp;
        
        psg_Payment_Plan__c plan = new psg_Payment_Plan__c();
        plan.psg_Opportunity__c = opp.Id;
        insert plan;
        
        List<psg_Payment__c> Payments = new List<psg_Payment__c>();
        for (Integer i = 0; i < 22;i++) {
            psg_Payment__c Payment = new psg_Payment__c();
            Payment.psg_Payment_Plan__c = plan.Id;
            Payments.add(Payment);
        }
        insert Payments;
        
        ApexPages.StandardController stdCtrl = new ApexPages.StandardController(plan);
        
        PaymentPlanPDFController controller = new PaymentPlanPDFController(stdCtrl);
        System.debug(controller.PagoFinal);
        System.debug(controller.TodosLosPagos);
        
        Test.stopTest();
    }

}