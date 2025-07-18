public class PaymentPlanController extends VF_Messages_Abstract {
	
   public psg_Payment_Plan__c PaymentPlan { get; set; }
    public List<psg_Payment__c > Payments { get; set; }
    public Boolean Calculated { get; set; }
    private Opportunity currentOpportunity { get; set; }
    ApexPages.StandardController standardController;
    public String total { get; set; }
    public Boolean IsDataChanged { get; set; }
    public Boolean IsPagosChanged { get; set; }
    public Boolean IsSaved { get; set; }
    private psg_Project__c project;

    
   public PaymentPlanController(ApexPages.StandardController stdCtrl) {
        standardController = stdCtrl;
        Calculated = false;
        IsDataChanged = false;
        IsSaved = true;
        Payments = new List<psg_Payment__c>();
        

         if (stdCtrl.getId() != null) {
    
            currentOpportunity = [SELECT Id, psg_Delivery_Date__c, CloseDate, Amount, psg_Payment_Plan__c , psg_Related_Project__c
                                   FROM Opportunity 
                                   WHERE Id = :stdCtrl.getId()];   
          //  formatTotal(); 
          if (currentOpportunity.Amount != null) {
  			formatTotal();
            } else { total = '0.00';}
   
            if (currentOpportunity.psg_Payment_Plan__c != null) {
                // Consultar solo si existe relación
                PaymentPlan = [ SELECT Id, psg_Initial__c, psg_Opportunity__c, psg_Reservation__c, 
                               psg_Initial_Divided__c, psg_Days_to_Complete_Initial_Payment__c, psg_Intermediate__c, 
                               psg_Number_of_Payments_During_Constructi__c, psg_First_Payment_Date__c,psg_Months_Interval_for_Construction_Pay__c,
                               psg_Final__c, psg_Initial_Payment_Installments__c, psg_Notes__c 
                               FROM psg_Payment_Plan__c WHERE Id = :currentOpportunity.psg_Payment_Plan__c];
               
        
                if (PaymentPlan.Id != null) {
                    System.debug('ID de PlanDePagos antes de consultar pagos: ' + PaymentPlan.Id);
                    Payments = [SELECT Id, psg_Description__c, psg_Payment__c, psg_Percentages__c, psg_Payment_Date__c, 
                                     psg_Payment_Plan__c, psg_Sort__c 
                              FROM psg_Payment__c  
                              WHERE psg_Payment_Plan__c = :PaymentPlan.Id 
                              ORDER BY psg_Sort__c ASC];
    
                    Calculated = Payments.size() > 0;
                }
              } else {
        
                    PaymentPlan = new psg_Payment_Plan__c();
                    PaymentPlan.psg_Opportunity__c = currentOpportunity.Id;
                    
                    // nuevo codigo
                    if (currentOpportunity.psg_Related_Project__c != null) {
                        project = [
                            SELECT Inicial_Predeterminado__c, Intermedio_Predeterminado__c, Contra_Entrega_Pred__c, psg_Delivery_Date__c, psg_Reservation__c, psg_Number_of_Payments_During_Constructi__c
                            FROM psg_Project__c
                            WHERE Id = :currentOpportunity.psg_Related_Project__c
                            LIMIT 1
                        ];
                        PaymentPlan.psg_Initial__c = project.Inicial_Predeterminado__c;
                        PaymentPlan.psg_Intermediate__c = project.Intermedio_Predeterminado__c;
                        PaymentPlan.psg_Final__c = project.Contra_Entrega_Pred__c;
                        
                        PaymentPlan.psg_Reservation__c = project.psg_Reservation__c;
                        PaymentPlan.psg_Number_of_Payments_During_Constructi__c = project.psg_Number_of_Payments_During_Constructi__c;
                    }
    
                   // From here
                   //                 
                    PaymentPlan.psg_Months_Interval_for_Construction_Pay__c = 1;
                     PaymentPlan.psg_Days_to_Complete_Initial_Payment__c = 21;
    
            
                    if (currentOpportunity.CloseDate != null) {
                        PaymentPlan.psg_First_Payment_Date__c = currentOpportunity.CloseDate.addDays(60);
                    }
                }
        }     
       
    } 

  	private void formatTotal() {
        if (currentOpportunity.Amount != null) {
            Decimal amount = currentOpportunity.Amount.setScale(2);
            total = 'USD ' + String.valueOf(amount).replaceAll('\\B(?=(\\d{3})+(?!\\d))', ',');
        } else {
            total = 'USD 0.00';
        }
    }
        
       public String formatAmountAsUSD(Decimal amount) {
            if (amount == null) return 'USD 0,00';
            String value = String.valueOf(amount.setScale(2)).replace('.', ',');
            value = value.replaceAll('\\B(?=(\\d{3})+(?!\\d))', '.');
            return 'USD ' + value;
        }

    
    Public PageReference calculate() {
        Payments.clear();
        
        Calculated = false;
        

        
        if (project == null || project.psg_Delivery_Date__c == null) {
            showError('Debe completar la fecha de entrega en el Proyecto.');
            return null;
        }


        // El monto de reserva no puede ser nulo
        if (PaymentPlan.psg_Reservation__c == null) {
            showError('Debe completar el monto de reserva.');
            return null;
        }
        
        // El monto de reserva no puede superar el precio de compra final
        if (PaymentPlan.psg_Reservation__c > currentOpportunity.Amount) {
            showError('El monto de reserva no puede superar el precio de compra final.');
            return null;
        }
        
        if (PaymentPlan.psg_Reservation__c != currentOpportunity.Amount) {
            // Los porcentajes deben sumar 100% (ni mas ni menos)
            if (((PaymentPlan.psg_Initial__c == null ? 0 : PaymentPlan.psg_Initial__c) + (PaymentPlan.psg_Intermediate__c == null ? 0: PaymentPlan.psg_Intermediate__c) + (PaymentPlan.psg_Final__c == null ? 0 : PaymentPlan.psg_Final__c)) != 100) {
                showError('Los porcentajes deben sumar 100%.');
                return null;
            }
        }
        
        if (PaymentPlan.psg_Initial_Divided__c != null) { //----------------------------> 2
            PaymentPlan.psg_Initial_Divided__c = PaymentPlan.psg_Initial_Divided__c;
        }
        
        // Fecha del primer pago debe ser mayor a la fecha de compra
        if (PaymentPlan.psg_First_Payment_Date__c <= currentOpportunity.CloseDate) {
            showError('Fecha del primer pago debe ser mayor a la fecha de compra.');
            return null;
        }
        
       
        if (PaymentPlan.psg_Reservation__c != currentOpportunity.Amount) {
    
            if (currentOpportunity.Amount == null) {
                showError('Debe completar el campo Monto (Amount) en la Oportunidad.');
                return null;
            }
            
            // Los porcentajes deben sumar 100%
            if (((PaymentPlan.psg_Initial__c == null ? 0 : PaymentPlan.psg_Initial__c) 
                + (PaymentPlan.psg_Intermediate__c == null ? 0 : PaymentPlan.psg_Intermediate__c) 
                + (PaymentPlan.psg_Final__c == null ? 0 : PaymentPlan.psg_Final__c)) != 100) {
                showError('Los porcentajes deben sumar 100%.');
                return null;
            }
        }
		
        // Verificar que el inicial sume al menos el 20%
       Decimal porcentajeDeReserva = (PaymentPlan.psg_Reservation__c / currentOpportunity.Amount) * 100.0;
           if ((PaymentPlan.psg_Initial__c == null || PaymentPlan.psg_Initial__c == 0) && porcentajeDeReserva < 20 || (PaymentPlan.psg_Initial__c != null && PaymentPlan.psg_Initial__c < 20)) {
                showError('El total del inicial debe ser un minimo del 20%.');
                return null;
        }
        
        // Pagos intermedios máximo sea 50
        if (PaymentPlan.psg_Number_of_Payments_During_Constructi__c != null && PaymentPlan.psg_Number_of_Payments_During_Constructi__c > 50) {
            showError('El numero de pagos intermedios no puede ser mayor a 50.');
            return null;        
        }
        
        // La cantidad de cuotas del inicial no puede exeder de 10
        if (PaymentPlan.psg_Initial_Payment_Installments__c > 10) {
            showError('La cantidad de cuotas del inicial es maximo 10.');
            return null;
        } else if (PaymentPlan.psg_Initial_Payment_Installments__c <= 0) {
            showError('Cantidad de cuotas del inicial fuera del rango permitido.');
            return null;
        }
        
        // Si se define un valor para el porcentaje de inicial debe indicar los dias para completar dicho pago
        if (PaymentPlan.psg_Days_to_Complete_Initial_Payment__c == null && PaymentPlan.psg_Initial__c != null) {
            showError('Debe definir la cantidad de dias para completar el pago del inicial.');
            return null;
        }
        
        // Si se define un valor para el porcentaje de inicial debe indicar la cantidad de cuotas del inicial
        if (PaymentPlan.psg_Initial_Payment_Installments__c == null && PaymentPlan.psg_Initial__c != null) {
            PaymentPlan.psg_Initial_Payment_Installments__c = 1;
        }
        
        Decimal remainingPercentage  = PaymentPlan.psg_Reservation__c >= currentOpportunity.Amount ? 0 : 100;
        
        // Reserva
        psg_Payment__c  reservation = new psg_Payment__c();
        reservation.psg_Payment__c = PaymentPlan.psg_Reservation__c;
        reservation.psg_Percentages__c = (PaymentPlan.psg_Reservation__c / currentOpportunity.Amount) * 100;
        reservation.psg_Payment_Date__c = currentOpportunity.CloseDate;
        reservation.psg_Description__c = 'Reserva';
        Payments.add(reservation);
        
        remainingPercentage  -= reservation.psg_Percentages__c;
        
        //if (PlanDePagos.Dias_para_completar_el_pago_inicial__c == null) PlanDePagos.Inicial_1__c = PlanDePagos.Inicial_2__c = PlanDePagos.Inicial_3__c = null;
        
        if (remainingPercentage  > 0 && PaymentPlan.psg_Initial_Payment_Installments__c != null && PaymentPlan.psg_Initial__c != null) {
            // Inicial
            for (Integer i = 0; i < PaymentPlan.psg_Initial_Payment_Installments__c; i++) {
                psg_Payment__c pagoDeInicial = new psg_Payment__c();
                pagoDeInicial.psg_Percentages__c = PaymentPlan.psg_Initial__c / PaymentPlan.psg_Initial_Payment_Installments__c;
                pagoDeInicial.psg_Payment__c = Math.round((currentOpportunity.Amount * (pagoDeInicial.psg_Percentages__c / 100)) - (PaymentPlan.psg_Reservation__c / PaymentPlan.psg_Initial_Payment_Installments__c));
                pagoDeInicial.psg_Percentages__c = (pagoDeInicial.psg_Payment__c / currentOpportunity.Amount) * 100;
                pagoDeInicial.psg_Payment_Date__c = 
                    i == 0 ? currentOpportunity.CloseDate.addDays(Integer.valueOf(PaymentPlan.psg_Days_to_Complete_Initial_Payment__c / PaymentPlan.psg_Initial_Payment_Installments__c))
                    : Payments[Payments.size()-1].psg_Payment_Date__c.addDays(Integer.valueOf(PaymentPlan.psg_Days_to_Complete_Initial_Payment__c / PaymentPlan.psg_Initial_Payment_Installments__c));
                pagoDeInicial.psg_Description__c = PaymentPlan.psg_Initial_Payment_Installments__c == 1 ? 'Resto del inicial' : 'Resto del inicial ' + (i+1);
                if (pagoDeInicial.psg_Payment_Date__c > PaymentPlan.psg_First_Payment_Date__c) {
                    showError('Se supera fecha del primer pago en los pagos del inicial.');
                    return null;
                }
                Payments.add(pagoDeInicial);
            }
            remainingPercentage  -= PaymentPlan.psg_Initial__c;
        }
        
        // Intermedios
        if (remainingPercentage  > 0 && PaymentPlan.psg_Intermediate__c != null) {
            if (PaymentPlan.psg_Number_of_Payments_During_Constructi__c == null) {
                showError('Debe especificar el numero de pagos durante la construcci&oacute;n.');
                return null;
            }
            if (PaymentPlan.psg_Months_Interval_for_Construction_Pay__c == null) {
                showError('Debe especificar el intervalo de los pagos durante la construcci&oacute;n (en meses).');
                return null;
            }
            if (PaymentPlan.psg_Intermediate__c > remainingPercentage ) PaymentPlan.psg_Intermediate__c = remainingPercentage ;
        	if (PaymentPlan.psg_Intermediate__c <= 0 || PaymentPlan.psg_Intermediate__c >= 100) PaymentPlan.psg_Intermediate__c = null;
            if (PaymentPlan.psg_Intermediate__c != null) {
                for (Integer i = 1; i <= PaymentPlan.psg_Number_of_Payments_During_Constructi__c; i++) {
                    psg_Payment__c  intermediatePayment  = new psg_Payment__c();
                    intermediatePayment.psg_Percentages__c = PaymentPlan.psg_Intermediate__c / PaymentPlan.psg_Number_of_Payments_During_Constructi__c;
                    intermediatePayment.psg_Payment__c = Math.round(currentOpportunity.Amount * (intermediatePayment.psg_Percentages__c / 100));
                    intermediatePayment.psg_Payment_Date__c = i == 1 ? PaymentPlan.psg_First_Payment_Date__c : Payments[Payments.size()-1].psg_Payment_Date__c.addMonths(Integer.valueOf(PaymentPlan.psg_Months_Interval_for_Construction_Pay__c));
                    intermediatePayment.psg_Description__c = 'Pago ' + i;
                    Payments.add(intermediatePayment);
                }
            }
            remainingPercentage  -= PaymentPlan.psg_Intermediate__c;
        }
        // Verificar si se supera la fecha de entrega. -------------------------------------------------------------
        for (psg_Payment__c Payment : Payments) {
            if (project.psg_Delivery_Date__c < Payment.psg_Payment_Date__c) {
                showError('Se supera la fecha de entrega.');
        		return null;
            }
        }
       
        if (project != null && project.psg_Delivery_Date__c != null) {
            for (psg_Payment__c Payment : Payments) {
                if (project.psg_Delivery_Date__c.addDays(-120) < Payment.psg_Payment_Date__c) {
                    showError('Diferencia entre el &uacute;ltimo pago y Pago final, no puede ser menor de 120 d&iacute;as.');
                    return null;
                }
            }
        } else {
            showError('Debe completar la fecha de entrega en el Proyecto.');
            return null;
        }

        
        Decimal sumAllPayments  = 0;
        for (psg_Payment__c Payment : Payments) sumAllPayments  += Payment.psg_Payment__c;
        Decimal pendingFinalPayment  = currentOpportunity.Amount - sumAllPayments;
        // Pago final
        if (remainingPercentage  > 0 || pendingFinalPayment  > 0) {
            //PlanDePagos.Final__c = porcentajeRestante == 0 ? null : porcentajeRestante;
            psg_Payment__c finalPayment  = new psg_Payment__c();
            finalPayment.psg_Payment__c = pendingFinalPayment;
            finalPayment.psg_Percentages__c = (finalPayment.psg_Percentages__c = (finalPayment.psg_Payment__c / currentOpportunity.Amount) * 100).setScale(2);
            //PlanDePagos.Final__c = pagoFinal.Porcentajes__c;
            finalPayment.psg_Payment_Date__c = project.psg_Delivery_Date__c;
            finalPayment.psg_Description__c = 'Pago Final';
            Payments.add(finalPayment);
        }
        
        // Sorting
        for (Integer i = 0; i < Payments.size(); i++) Payments[i].psg_Sort__c = i;
        
        Calculated = Payments.size() > 0;
        IsDataChanged = false;
        IsPagosChanged = false;
        IsSaved = false;
        return null;
    }
    
    private PageReference privateSave() {
    beforeSaveValidations();
    if (ApexPages.hasMessages()) return null;
    
    upsert PaymentPlan;
    currentOpportunity.psg_Payment_Plan__c = PaymentPlan.Id;
    update currentOpportunity; // Agregar esta línea para guardar la relación en Opportunity
    
    PageReference pageRef = standardController.save();
    
    if (Payments.size() > 0 && Payments[0].psg_Payment_Plan__c == null) {
        for (psg_Payment__c  Payment : Payments) Payment.psg_Payment_Plan__c = PaymentPlan.Id;
        List<psg_Payment__c> oldPayments = [SELECT Id FROM psg_Payment__c WHERE psg_Payment_Plan__c =: PaymentPlan.Id];
        delete oldPayments;
        insert Payments;
    } else if (Payments.size() > 0 && Payments[0].psg_Payment_Plan__c != null) {
        upsert Payments;
    }   
    IsSaved = true;
    return pageRef;
}
 
    
    public PageReference save() {
       return privateSave();
    }
    
    public PageReference quickSave () {
        privateSave();
        return null;
    }

    public PageReference dataChanged() {
        IsDataChanged = true;
        IsSaved = false;
        Calculated = false;
        return null;
    }
    
    public PageReference paymentsChanged() {
        IsPagosChanged = true;
        IsSaved = false;
        return null;
    }
    
    void beforeSaveValidations() {
        // La fecha de pago de inicial no puede sobrepasar Fecha del primer pago
        for (psg_Payment__c Payment : Payments) {
            if (Payment.psg_Description__c.contains('Resto del inicial') && Payment.psg_Payment_Date__c > PaymentPlan.psg_First_Payment_Date__c) {
                showError('Las fechas de pago de inicial no puede sobrepasar Fecha del primer pago.');
                return;
            }
        }
        if (IsDataChanged)
            showError('Si ha realizado cambios debe primero recalcular.');
    }

    void showError(String strMsg){
        //ApexPages.Message msg = new Apexpages.Message(ApexPages.Severity.ERROR,strMsg);
        //ApexPages.addMessage(msg);
        createError(ApexPages.Severity.ERROR,strMsg);
    }
	   
}