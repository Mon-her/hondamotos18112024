public with sharing class fan_BackorderItemsCtrl {

    @TestVisible
    static OrderItemSummary[] testOrderItemSummaries;
    
    @AuraEnabled
    public static List<OrderItemSummary> getBackorderItems(String effectiveAccountId, String storeName){
        String shippingProduct = [SELECT Label FROM fan_InfoFletes__mdt WHERE DeveloperName = 'producto' LIMIT 1].Label;
        List<OrderItemSummary> backorderItems = new List<OrderItemSummary>();
        List<OrderItemSummary> orderItems = Test.isRunningTest() ? testOrderItemSummaries : [SELECT QuantityAllocated, QuantityCanceled, QuantityFulfilled, Quantity, Product2.Name,
                                             Product2.Referencia__c, OrderSummary.OrderNumber, OrderSummary.OrderedDate, OrderDeliveryGroupSummary.DeliverToName, 
                                             OrderSummary.OriginalOrder.fan_TipoPedido__c, Product2.Fecha_Estimada__c 
                                             FROM OrderItemSummary WHERE OrderSummary.AccountId = :effectiveAccountId AND Product2.Referencia__c != :shippingProduct
                                             AND OrderSummary.SalesStore.Name = :storeName AND fan_IsBackorder__c = true ORDER BY OrderSummary.OrderedDate DESC];
        for(OrderItemSummary item : orderItems){
            // If quantity reserved plus quantity canceled is less than total order quantity, then the item has pending quantity to assign
            if ((item.QuantityAllocated + item.QuantityCanceled) < item.Quantity){
                backorderItems.add(item);
            }
            if (item.OrderSummary.OriginalOrder.fan_TipoPedido__c != null && item.OrderSummary.OriginalOrder.fan_TipoPedido__c.contains('_')){
                item.OrderSummary.OriginalOrder.fan_TipoPedido__c = item.OrderSummary.OriginalOrder.fan_TipoPedido__c.split('_')[1];
            }
        }
        return backorderItems;
    }
}