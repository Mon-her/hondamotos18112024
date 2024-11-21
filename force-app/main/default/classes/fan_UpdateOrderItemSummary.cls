public with sharing class fan_UpdateOrderItemSummary {

    public class updateItemRequest {
        @InvocableVariable(required=true)
        public Id orderId;
        
        @InvocableVariable(required=true)
        public Id orderSummaryId;
    }
    
    @InvocableMethod
    public static void updateItemSummary(List<updateItemRequest> requestData) {
        Map<String,Boolean> itemIdBackorder = new Map<String,Boolean>();
        List<OrderItem> orderItemsList = [SELECT Id, fan_isBackorder__c FROM OrderItem WHERE OrderId = :requestData[0].orderId];
        for (OrderItem item : orderItemsList) {
            itemIdBackorder.put(item.Id, item.fan_isBackorder__c);
        }
        List<OrderItemSummary> summaryItemsList = [SELECT Id, fan_isBackorder__c, OriginalOrderItemId FROM OrderItemSummary WHERE OrderSummaryId = :requestData[0].orderSummaryId];
        for (OrderItemSummary item : summaryItemsList) {
            item.fan_IsBackorder__c = itemIdBackorder.get(item.OriginalOrderItemId);
        }
        UPDATE summaryItemsList;
    }
}