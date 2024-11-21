public with sharing class fan_BackorderHandler {
    public static OrderSummaryRoutingSchedule[] getOrderSummaryRoutingSchedules(String storeName, String[] tipoPedido, Boolean isProcessed ) {
        
        final Datetime TWENTY_FOUR_HOURS_AGO = Datetime.now().addHours(-24);

        OrderSummaryRoutingSchedule[] orderSummaryRoutingSchedules = [SELECT fan_OrderProcessed__c FROM OrderSummaryRoutingSchedule
            WHERE (OrderSummary.OriginalOrder.fan_FormaPago__c = :fan_Constants.FormaPago.CREDITO.name() OR OrderSummary.OriginalOrder.fan_EsAnticipo__c = true)
                AND fan_OrderProcessed__c = :isProcessed
                AND OrderSummary.SalesStore.Name = :storeName
                AND  OrderSummary.fan_TipoPedido__c IN :tipoPedido
                AND OrderSummary.Status = :fan_Constants.OrderSummaryStatus.APROBADO.name()
                AND ScheduleStatus = 'SCHEDULED'
                AND fan_Step__c IN (null, 'Validate Availability', 'Create OCI Interaction Order Summaries')
                AND ScheduledDatetime < :TWENTY_FOUR_HOURS_AGO
                AND OrderSummaryId IN (SELECT OrderSummaryId FROM OrderItemSummary WHERE fan_IsBackorder__c = true AND QuantityAvailableToFulfill > 0)
            ORDER BY CreatedDate
            LIMIT 60];

        return orderSummaryRoutingSchedules;
    }

    public static OrderSummaryRoutingSchedule[] getOrderOsrsToProcess(String storeName, Boolean isProcessed ) {
        
        final Datetime TWENTY_FOUR_HOURS_AGO = Datetime.now().addHours(-24);

        OrderSummaryRoutingSchedule[] orderSummaryRoutingSchedules = [SELECT fan_OrderProcessed__c FROM OrderSummaryRoutingSchedule
            WHERE (OrderSummary.OriginalOrder.fan_FormaPago__c = :fan_Constants.FormaPago.CREDITO.name() OR OrderSummary.OriginalOrder.fan_EsAnticipo__c = true)
                AND fan_OrderProcessed__c = :isProcessed
                AND OrderSummary.SalesStore.Name = :storeName
                AND OrderSummary.Status = :fan_Constants.OrderSummaryStatus.APROBADO.name()
                AND ScheduleStatus = 'SCHEDULED'
                AND fan_Step__c IN (null, 'Validate Availability', 'Create OCI Interaction Order Summaries')
                AND ScheduledDatetime < :TWENTY_FOUR_HOURS_AGO
                AND OrderSummaryId IN (SELECT OrderSummaryId FROM OrderItemSummary WHERE fan_IsBackorder__c = true AND QuantityAvailableToFulfill > 0)
            ORDER BY CreatedDate
            LIMIT 60];

        return orderSummaryRoutingSchedules;
    }

    public static OrderSummaryRoutingSchedule[] getOsrsProcessed(String storeName) {
        
        final Datetime TWENTY_FOUR_HOURS_AGO = Datetime.now().addHours(-24);

        OrderSummaryRoutingSchedule[] orderSummaryRoutingSchedules = [SELECT fan_OrderProcessed__c FROM OrderSummaryRoutingSchedule
            WHERE (OrderSummary.OriginalOrder.fan_FormaPago__c = :fan_Constants.FormaPago.CREDITO.name() OR OrderSummary.OriginalOrder.fan_EsAnticipo__c = true)
                AND fan_OrderProcessed__c = true
                AND OrderSummary.SalesStore.Name = :storeName
                AND OrderSummary.Status = :fan_Constants.OrderSummaryStatus.APROBADO.name()
                AND ScheduleStatus = 'SCHEDULED'
                AND fan_Step__c IN (null, 'Validate Availability', 'Create OCI Interaction Order Summaries')
                AND ScheduledDatetime < :TWENTY_FOUR_HOURS_AGO
                AND OrderSummaryId IN (SELECT OrderSummaryId FROM OrderItemSummary WHERE fan_IsBackorder__c = true AND QuantityAvailableToFulfill > 0)
            ORDER BY ScheduledDatetime];

        return orderSummaryRoutingSchedules;
    }
}