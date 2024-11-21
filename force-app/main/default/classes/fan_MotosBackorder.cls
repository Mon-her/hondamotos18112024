public with sharing class fan_MotosBackorder implements Database.batchable<OrderSummaryRoutingSchedule>, Schedulable{
    
    @TestVisible
    static OrderSummaryRoutingSchedule[] testOrderSummaryRoutingSchedules;

    public Iterable<OrderSummaryRoutingSchedule> start(Database.BatchableContext BC) {

        final Datetime TWELVE_HOURS_AGO = Datetime.now().addHours(-12); // Inventory updates occur every 12 hours. 
        final Integer GAP = 7; // Number of minutes between OSRS of the same Order Summary.
        final Integer RECORDS_LIMIT = 60; // Number of records to schedule.

        OrderSummaryRoutingSchedule[] orderSummaryRoutingSchedules = [SELECT OrderSummaryId FROM OrderSummaryRoutingSchedule
                                                                        WHERE OrderSummary.SalesStore.Name = :fan_Constants.StoreDeveloperName.MOTOS.name()
                                                                        AND (OrderSummary.OriginalOrder.fan_FormaPago__c = :fan_Constants.FormaPago.CREDITO.name() OR OrderSummary.OriginalOrder.fan_EsAnticipo__c = true)
                                                                        AND OrderSummary.Status = :fan_Constants.OrderSummaryStatus.APROBADO.name()
                                                                        AND ScheduleStatus = 'SCHEDULED'
                                                                        AND fan_Step__c IN (null, 'Validate Availability', 'Create OCI Interaction Order Summaries')
                                                                        AND ScheduledDatetime < :TWELVE_HOURS_AGO
                                                                        AND OrderSummaryId IN (SELECT OrderSummaryId FROM OrderItemSummary WHERE fan_IsBackorder__c = true AND QuantityAvailableToFulfill > 0)
                                                                        ORDER BY ScheduledDatetime LIMIT 200];
        return sortOrderSummaryRoutingSchedulesByGaps(RECORDS_LIMIT, GAP, Test.isRunningTest() ? testOrderSummaryRoutingSchedules : orderSummaryRoutingSchedules);
    }

    public void execute(Database.BatchableContext bc, OrderSummaryRoutingSchedule[] orderSummaryRoutingSchedules) {
        Datetime now = Datetime.now();
        OrderSummaryRoutingSchedule[] orderSummaryRoutingSchedulesToUpdate = new List<OrderSummaryRoutingSchedule>();

        for (OrderSummaryRoutingSchedule orderSummaryRoutingSchedule : orderSummaryRoutingSchedules) {
            now = now.addMinutes(1);

            // Only update objects which are not empty.
            if(orderSummaryRoutingSchedule.Id != null) {
                orderSummaryRoutingSchedule.fan_Step__c = 'Validate Availability';
                orderSummaryRoutingSchedule.ScheduledDatetime = now; 
                orderSummaryRoutingSchedulesToUpdate.add(orderSummaryRoutingSchedule);
            }
        }
        if(!Test.isRunningTest()) UPDATE orderSummaryRoutingSchedulesToUpdate;
    }

    public void finish(Database.BatchableContext bc) {}

    public void execute(SchedulableContext sc) {
        Database.executeBatch(new fan_MotosBackorder());
    }

    /**
     * Order summary routing schedules sharing the same order summary id will have a gap in the scheduling
     */
    OrderSummaryRoutingSchedule[] sortOrderSummaryRoutingSchedulesByGaps(final Integer RECORDS_LIMIT, final Integer GAP, OrderSummaryRoutingSchedule[] orderSummaryRoutingSchedules) {

        Integer queueIndex = 0;
        Map<String, Integer> previousIndex = new Map<String, Integer>();
        OrderSummaryRoutingSchedule[] sortedOrderSummaryRoutingSchedules = new List<OrderSummaryRoutingSchedule>(RECORDS_LIMIT);

        for (OrderSummaryRoutingSchedule orderSummaryRoutingSchedule : orderSummaryRoutingSchedules) {

            String orderSummaryId = orderSummaryRoutingSchedule.OrderSummaryId;
            Integer position = queueIndex;

            // Routing schedules in the same order summary need a gap to avoid UNABLE_TO_LOCK_ROW exception and inconsistency  of reserves.
            if(previousIndex.containsKey(orderSummaryId)) {
                position = previousIndex.get(orderSummaryId) + GAP;
            } else {
                queueIndex++;
            }

            // Skip busy positions.
            while (position < sortedOrderSummaryRoutingSchedules.size() && sortedOrderSummaryRoutingSchedules[position] != null) {
                if(queueIndex == position++) {
                    queueIndex++;
                }
            }

            if(position < sortedOrderSummaryRoutingSchedules.size()) {
                previousIndex.put(orderSummaryId, position);
                sortedOrderSummaryRoutingSchedules.set(position, orderSummaryRoutingSchedule);
            }
        }
        return fillEmptyPositions(sortedOrderSummaryRoutingSchedules);
    }

    /**
     * Database.Batchable.execute method does not take into account empty positions.
    */
    OrderSummaryRoutingSchedule[] fillEmptyPositions(OrderSummaryRoutingSchedule[] orderSummaryRoutingSchedules) {

        for (Integer i = 0; i < orderSummaryRoutingSchedules.size(); i++) {
            // Set empty object.
            if(orderSummaryRoutingSchedules[i] == null) {
                orderSummaryRoutingSchedules.set(i, new OrderSummaryRoutingSchedule());
            }
        }
        return orderSummaryRoutingSchedules;
    }
}