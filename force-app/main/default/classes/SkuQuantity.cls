public with sharing class SkuQuantity {

    public SkuQuantity(){
        
    }
    
    @AuraEnabled
    @InvocableVariable(label='SKU' description='SKU' required=true)
    public String SKU;   
    
    @AuraEnabled
    @InvocableVariable(label='Quantity' description='Quantity' required=true)
    public Decimal Quantity;
}