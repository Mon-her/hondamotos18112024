public with sharing class OrderItemSustituteQty {

    public OrderItemSustituteQty() {

    }
    
    @AuraEnabled
    @InvocableVariable(label='OrderItemSummaryId' description='OrderItemSummaryId' required=true)
    public Id OrderItemSummaryId;
    
    @AuraEnabled
    @InvocableVariable(label='OrderItemSummary' description='OrderItemSummary' required=true)
    public OrderItemSummary OrderItemSummary;
    
    @AuraEnabled
    @InvocableVariable(label='OrderItemQty' description='OrderItemQty' required=true)
    public Decimal OrderItemQty;
    
    @AuraEnabled
    @InvocableVariable(label='OrderItemQtyATF' description='OrderItemQtyATF' required=true)
    public Decimal OrderItemQtyATF;
    
    @AuraEnabled
    @InvocableVariable(label='SustituteId' description='SustituteId' required=true)
    public String SustituteId;
    
    @AuraEnabled
    @InvocableVariable(label='SustituteName' description='SustituteName' required=true)
    public String SustituteName;
    
    @AuraEnabled
    @InvocableVariable(label='SustituteSKU' description='SustituteSKU' required=true)
    public String SustituteSKU;   
    
    @AuraEnabled
    @InvocableVariable(label='SKUSustituteQty' description='SKUSustituteQty' required=true)
    public Decimal SKUSustituteQty;
}