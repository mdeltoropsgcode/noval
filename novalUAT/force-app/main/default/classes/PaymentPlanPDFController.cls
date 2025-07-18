public class PaymentPlanPDFController {
   
  private final psg_Payment_Plan__c PaymentPlan;
    private ApexPages.StandardController stdCtrl;
    public class Pago {
        public psg_Payment__c Pago1 { get; set; }
        public psg_Payment__c Pago2 { get; set; }
    }
    public List<Pago> Pagos { get; set; }
    public psg_Payment__c PagoFinal { get; set; }
    
    public Boolean OneDataColumn { get; set; }
    
    public List<psg_Payment__c> TodosLosPagos { get; set; }
    
	public PaymentPlanPDFController(ApexPages.StandardController controller) {
        this.PaymentPlan = (psg_Payment_Plan__c)controller.getRecord();
        this.stdCtrl=controller;
        List<psg_Payment__c> qPagosList = [SELECT Id, psg_Description__c, psg_Payment__c, psg_Percentages__c, psg_Payment_Date__c, psg_Payment_Plan__c, psg_Sort__c FROM psg_Payment__c WHERE psg_Payment_Plan__c =:PaymentPlan.Id ORDER BY psg_Sort__c ASC];
        
        OneDataColumn = qPagosList.size() <= 21; // 21 es el maximo de lineas que se pueden mostrar con una sola columna de datos.
        
        if (OneDataColumn) TodosLosPagos = qPagosList;
        else {
            //PagoFinal = qPagosList.remove(qPagosList.size()-1);
            Pagos = new List<Pago>();
            Integer sizeFirst = (qPagosList.size() / 2) + Math.mod(qPagosList.size(), 2);
            for (Integer i = 0; i < sizeFirst; i++) {
                Pago p = new Pago();
                p.Pago1 = qPagosList[i];
                Integer secondListIndex = i+sizeFirst;
                if (secondListIndex < qPagosList.size()) p.Pago2 = qPagosList[secondListIndex];
                Pagos.add(p);
            }
            qPagosList.clear();
        }
    }


}