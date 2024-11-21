@IsTest
private class fan_PosventaBackorderTest {

    @TestSetup
    static void makeData(){
        Product2[] products = new Product2[] {
            fan_B2BTestDataFactory.buildProduct('SKU-1', 'ProductCode-1', null),
            fan_B2BTestDataFactory.buildProduct('SKU-1.1', 'ProductCode-1.1', null)
        };
        INSERT products;

        fan_B2BTestDataFactory.createRelatedProduct(products[0].Id, products[1].Id, '3');
    }

    @isTest
    static void testPosventaBatchExecution() {

        String keyPrefix = OrderDeliveryGroupSummary.getSobjectType().getDescribe().getKeyPrefix();
        String orderDeliveryGroupSummaryId = Id.valueOf(keyPrefix + '0'.repeat(12)); // 12 is to complete the 15 characters of the Id.

        OrderItemSummary[] orderItemSummaries = new OrderItemSummary[] {
            buildOrderItemSummary('SKU-1', 1)
        };
        OrderSummaryRoutingSchedule[] orderSummaryRoutingSchedules = new OrderSummaryRoutingSchedule[]{
            buildOrderSummaryRoutingSchedule(orderDeliveryGroupSummaryId)
        };
        OrderDeliveryGroupSummary[] orderDeliveryGroupSummaries = new OrderDeliveryGroupSummary[] {
            buildOrderDeliveryGroupSummary(orderDeliveryGroupSummaryId, orderItemSummaries)
        };

        Test.startTest();
        fan_PosventaBackorder.testOrderSummaryRoutingSchedules = orderSummaryRoutingSchedules;
        fan_PosventaBackorder.testOrderDeliveryGroupSummaries = orderDeliveryGroupSummaries;
        fan_InventoryHandler.testOutputRepresentation = fan_B2BTestDataFactory.generateOCIGetInventoryAvailability('B2B_Posventa', '11005', new String[] { 'SKU-1', 'SKU-1.1' });

        Database.executeBatch(new fan_PosventaBackorder()); // Schedule to run every hour
        Test.stopTest();
    }

    static OrderDeliveryGroupSummary buildOrderDeliveryGroupSummary(String orderDeliveryGroupSummaryId, OrderItemSummary[] orderItemSummaries) {
        Map<String, Object> orderDeliveryGroupSummary = new Map<String, Object> {
            'Id' => orderDeliveryGroupSummaryId,
            'OrderItemSummaries' => new Map<String, Object> {
                'totalSize' => 1,
                'done' => true,
                'records' => orderItemSummaries
            }
        };
        return (OrderDeliveryGroupSummary) JSON.deserialize(JSON.serialize(orderDeliveryGroupSummary), OrderDeliveryGroupSummary.class);
    }

    static OrderItemSummary buildOrderItemSummary(String stockKeepingUnit, Decimal quantityAvailableToFulfill) {
        Map<String, Object> orderItemSummary = new Map<String, Object> {
            'StockKeepingUnit' => stockKeepingUnit,
            'QuantityAvailableToFulfill' => quantityAvailableToFulfill
        };
        return (OrderItemSummary) JSON.deserialize(JSON.serialize(orderItemSummary), OrderItemSummary.class);
    }

    static OrderSummaryRoutingSchedule buildOrderSummaryRoutingSchedule(String orderDeliveryGroupSummaryId) {
        Map<String, String> orderSummaryRoutingSchedule = new Map<String, String> {
            'OrderDeliveryGroupSummaryId__c' => orderDeliveryGroupSummaryId
        };
        return (OrderSummaryRoutingSchedule) JSON.deserialize(JSON.serialize(orderSummaryRoutingSchedule), OrderSummaryRoutingSchedule.class);
    }
}