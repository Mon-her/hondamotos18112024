public with sharing class fan_CheckoutButtonController {

    @AuraEnabled
    public static fan_CheckOutValidation__mdt[] fetchCheckOutValidation() {
        fan_CheckOutValidation__mdt[] checkoutValidation = [
        SELECT DeveloperName,
            fan_Component__c,
            fan_Price__c, fan_Order_Type__c,
            fan_Payment_Condition__c,
            fan_Operator__c
        FROM fan_CheckOutValidation__mdt 
        WHERE fan_Component__c='Checkout Button'];
        return checkoutValidation;
    }
}