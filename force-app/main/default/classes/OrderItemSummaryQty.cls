public with sharing class OrderItemSummaryQty {

    public OrderItemSummaryQty() {

    }
    
    @AuraEnabled
    @InvocableVariable(label='OrderSummaryId' description='OrderSummaryId' required=true)
    public Id OrderSummaryId;
    
    @AuraEnabled
    @InvocableVariable(label='OrderItemSummaryId' description='OrderItemSummaryId' required=true)
    public Id OrderItemSummaryId;
    
    @AuraEnabled
    @InvocableVariable(label='OrderItemQuantity' description='OrderItemQuantity' required=true)
    public Decimal OrderItemQuantity;
    
    @AuraEnabled
    @InvocableVariable(label='Quantity' description='Quantity' required=true)
    public Decimal Quantity;
    
    @AuraEnabled
    @InvocableVariable(label='QuantityToCancel' description='QuantityToCancel' required=true)
    public Decimal QuantityToCancel;

    @AuraEnabled
    @InvocableVariable(label='Backorder' description='Has backorder' required=true)
    public Boolean HasBackorder;
}