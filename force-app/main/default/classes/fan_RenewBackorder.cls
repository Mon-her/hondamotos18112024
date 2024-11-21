public with sharing class fan_RenewBackorder implements Database.batchable<SObject>, Schedulable {

    public Database.QueryLocator start(Database.BatchableContext bc) {
        return Database.getQueryLocator([SELECT OrderDeliveryGroupSummaryId__c FROM OrderSummaryRoutingSchedule
                                            WHERE (OrderSummary.OriginalOrder.fan_FormaPago__c = :fan_Constants.FormaPago.CREDITO.name() OR OrderSummary.OriginalOrder.fan_EsAnticipo__c = true)
                                            AND fan_OrderProcessed__c = true
                                            AND OrderSummary.SalesStore.Name = :fan_Constants.StoreDeveloperName.POSVENTA.name()
                                            AND OrderSummary.Status = :fan_Constants.OrderSummaryStatus.APROBADO.name()
                                            AND ScheduleStatus = 'SCHEDULED'
                                            AND fan_Step__c IN (null, 'Validate Availability', 'Create OCI Interaction Order Summaries')]);
    }

    public void execute(Database.BatchableContext bc, OrderSummaryRoutingSchedule[] orderSummaryRoutingSchedules) {

        for (OrderSummaryRoutingSchedule orderSummaryRoutingSchedule : orderSummaryRoutingSchedules) {
            orderSummaryRoutingSchedule.fan_OrderProcessed__c = false;
        }
        if(!Test.isRunningTest()) UPDATE orderSummaryRoutingSchedules;
    }

    public void finish(Database.BatchableContext bc) {
        if(!Test.isRunningTest()) Database.executeBatch(new fan_PosventaBackorder());
    }

    public void execute(SchedulableContext sc) {
        Database.executeBatch(new fan_RenewBackorder());
    }
}