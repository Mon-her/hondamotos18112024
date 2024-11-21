public with sharing class fan_ConsultaCupoControllerFlow {

    @TestVisible
    static OrderSummary[] testOrderSummaries;

    // When there is no quota available the status of the order will be "Pending",
    // when there are overdue invoices it will be blocked. /*
    @TestVisible
    static void resolveOrderSummaryCycle(OrderSummary orderSummary, fan_ConsultaCupo.row_element[] response) {

        if(orderSummary.fan_OutboundConnectionFailedAttempts__c == 50){
            orderSummary.fan_ScheduleStatus__c = fan_Constants.OrderSummaryScheduleStatus.ABANDONED.name();
            return;
        }
        fan_ConsultaCupoHandler.Order order = new fan_ConsultaCupoHandler.Order(orderSummary);
        String status = fan_ConsultaCupoHandler.resolveOrderSummaryStatus(null, response, order);

        if(status == fan_Constants.OrderSummaryStatus.APROBADO.name()) {
            orderSummary.fan_ScheduleStatus__c = fan_Constants.OrderSummaryScheduleStatus.COMPLETED.name();
        } else {
            orderSummary.fan_ScheduleStatus__c = fan_Constants.OrderSummaryScheduleStatus.SCHEDULE.name();
            orderSummary.fan_ScheduledDatetime__c = datetime.now().addHours(2);
            orderSummary.fan_OutboundConnectionFailedAttempts__c++;
        }
        orderSummary.Status = status;
    }
    
    @InvocableMethod(
        label = 'Validar Línea de Crédito por Cuenta'
        description = 'Se actualizará el estado de la orden de acuerdo a (Cupo disponible insuficiente) -> Pendiente de pago; (Clientes con facturas vencidas, sin Pagar) -> Bloqueado por mora.'
        callout = true
        Category = 'B2B Commerce'
    )
    public static void validateCreditLine(String[] orderSummaryIds) {
        OrderSummary[] orderSummaries = [SELECT Account.AccountNumber, Account.Parent.AccountNumber, OriginalOrder.GrandTotalAmount, fan_TipoPedido__c, Total_Valor_Pendiente_Impuestos__c,
                                        fan_OutboundConnectionFailedAttempts__c FROM OrderSummary WHERE Id =: orderSummaryIds];
            
        for(OrderSummary orderSummary : Test.isRunningTest() ? testOrderSummaries : orderSummaries){

            Account account = orderSummary.Account;
            String nitCliente = account.ParentId == null ? account.AccountNumber : account.Parent.AccountNumber;
                
            fan_ConsultaCupo.row_element[] response = fan_ConsultaCupoHandler.getData(nitCliente);
            resolveOrderSummaryCycle(orderSummary, response);
        }
        System.debug('>>>>>>>>>>>>> ' + orderSummaries);
        if(!Test.isRunningTest()) UPDATE orderSummaries;
    }
}