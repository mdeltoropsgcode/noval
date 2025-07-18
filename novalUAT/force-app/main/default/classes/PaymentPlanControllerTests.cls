@IsTest(SeeAllData=False)
public class PaymentPlanControllerTests {
	
    public static testmethod void PositiveTest1() {
        Test.startTest();
    
    
        psg_Project__c testProject = new psg_Project__c(
            Name                             = 'Proyecto Test',
            Inicial_Predeterminado__c        = 30,
            Intermedio_Predeterminado__c     = 40,
            Contra_Entrega_Pred__c           = 30,
            psg_Reservation__c               = 10000,
            psg_Number_of_Payments_During_Constructi__c = 6,
            psg_Delivery_Date__c             = Date.today().addMonths(13)
        );
        insert testProject;        
     
        Opportunity opp = new Opportunity();
        opp.Name = 'Oportunidad de prueba';  
        //opp.psg_Delivery_Date__c = Date.today().addYears(4);
        opp.psg_Related_Project__c = testProject.Id;
        opp.StageName = 'Prospecting';
        opp.Amount = 300000.80;
        opp.CloseDate = Date.today().addMonths(1); 
        opp.CloseDate = Date.today();

        insert opp;         
 
        ApexPages.StandardController stdCtrl = new ApexPages.StandardController(opp);
        
        PaymentPlanController controller = new PaymentPlanController(stdCtrl);

        controller.PaymentPlan.psg_Reservation__c = 10000;
        controller.PaymentPlan.psg_Initial__c = 20;
        controller.PaymentPlan.psg_Intermediate__c = 40;
        controller.PaymentPlan.psg_Final__c = 40;
        controller.PaymentPlan.psg_Days_to_Complete_Initial_Payment__c = 21;
        controller.PaymentPlan.psg_Number_of_Payments_During_Constructi__c = 6;
        controller.PaymentPlan.psg_Months_Interval_for_Construction_Pay__c = 1;
        controller.PaymentPlan.psg_Initial_Payment_Installments__c = 2;
        controller.PaymentPlan.psg_First_Payment_Date__c = Date.today().addDays(30);
            
        controller.calculate();
        controller.quickSave ();
        controller.dataChanged();
        controller.calculate();
        controller.quickSave ();	
        controller.paymentsChanged();
        controller.save();
        
        
        Test.stopTest();
      
        
    }
           
    public static testmethod void NegativeTest1() {
        Test.startTest();
          
        // 1) Oportunidad sin proyecto
        Opportunity opp = new Opportunity(
            Name      = 'Oportunidad Negativa',
            StageName = 'Prospecting',
            CloseDate = Date.today().addDays(10)
        );
        insert opp;
        
        // 2) Crear un plan de pagos previo y asociarlo a la oportunidad
        psg_Payment_Plan__c existingPlan = new psg_Payment_Plan__c(
            psg_Opportunity__c     = opp.Id,
            psg_Initial__c     = 5,
            psg_Intermediate__c  = 5,
            psg_Final__c    = 5,
            psg_Reservation__c  = 1000,
            psg_Number_of_Payments_During_Constructi__c = 3
        );
        insert existingPlan;
        
        // Asociar el plan a la oportunidad y refrescar
        opp.psg_Payment_Plan__c = existingPlan.Id;
        update opp;
        
        // 3) Instanciar el controller: ahora debe entrar al bloque de carga existente
        ApexPages.StandardController stdCtrl = new ApexPages.StandardController(opp);
        PaymentPlanController controller = new PaymentPlanController(stdCtrl);
    
        // Verificar que cargó el plan existente
        System.assertEquals(existingPlan.Id,
            controller.PaymentPlan.Id,
            'Debe cargar el plan ya creado');
    
        // ---  llamadas a calculate() ---
        controller.PaymentPlan.psg_Initial__c = 20;
        controller.PaymentPlan.psg_Intermediate__c = 60;
        controller.PaymentPlan.psg_Final__c = 20;
        controller.calculate();
        
        controller.PaymentPlan.psg_Number_of_Payments_During_Constructi__c = 20;
        controller.calculate();
        
        controller.PaymentPlan.psg_Months_Interval_for_Construction_Pay__c = 1;
        controller.PaymentPlan.psg_Reservation__c = 205000;
        controller.calculate();
        
        controller.PaymentPlan.psg_Reservation__c = 500;
        controller.PaymentPlan.psg_Initial__c = 25;
        controller.calculate();
        
        controller.PaymentPlan.psg_First_Payment_Date__c = Date.today().addDays(-2);
        controller.calculate();
        
        controller.PaymentPlan.psg_First_Payment_Date__c = Date.today().addDays(1);
        controller.PaymentPlan.psg_Initial__c = 18;
        controller.PaymentPlan.psg_Intermediate__c = 62;
        controller.calculate();
        
        controller.PaymentPlan.psg_Number_of_Payments_During_Constructi__c = 31;
        controller.calculate();
        
        controller.PaymentPlan.psg_Initial_Payment_Installments__c = 11;
        controller.calculate();
        
        controller.PaymentPlan.psg_Initial_Payment_Installments__c = 0;
        controller.calculate();
        
        controller.PaymentPlan.psg_Initial_Payment_Installments__c = null;
        controller.calculate();
        
        controller.PaymentPlan.psg_Days_to_Complete_Initial_Payment__c = 10;
        controller.calculate();
        
        controller.PaymentPlan.psg_First_Payment_Date__c = Date.today().addDays(30);
        controller.calculate();
    
        Test.stopTest();
    } 
    
    @IsTest
	static void testFormatAmountAsUSD() {

        Opportunity opp = new Opportunity(
            Name      = 'Temp',
            StageName = 'Prospecting',
            Amount    = 100,
            CloseDate = Date.today().addDays(1)
        );
        insert opp;
        
        // Instanciamos el controller
        ApexPages.StandardController sc = new ApexPages.StandardController(opp);
        PaymentPlanController ctrl = new PaymentPlanController(sc);
    
        // Caso 1: null
        String s1 = ctrl.formatAmountAsUSD(null);
        System.assertEquals('USD 0,00', s1, 'Debe retornar USD 0,00 para null');
    
        // Caso 2: sin miles
        String s2 = ctrl.formatAmountAsUSD(123.4);
        // 123.40 → "123,40"
        System.assertEquals('USD 123,40', s2);
    
        // Caso 3: con miles
        String s3 = ctrl.formatAmountAsUSD(1234567.89);
        // 1.234.567,89
        System.assertEquals('USD 1.234.567,89', s3);
    }

}