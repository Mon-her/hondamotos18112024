@IsTest
class fan_BackorderItemsCtrlTest {

    @IsTest
    static void getBackorderItems() {
        fan_BackorderItemsCtrl.testOrderItemSummaries =  new OrderItemSummary[] {
            new OrderItemSummary(
                Quantity = 10,
                QuantityAllocated = 5,
                QuantityCanceled = 3,
                OrderSummary = (OrderSummary) JSON.deserialize('{"OriginalOrder":{"fan_TipoPedido__c":"RMT_Normal"}}', OrderSummary.class)
            )
        };
        fan_BackorderItemsCtrl.getBackorderItems(null, null);
    }
}