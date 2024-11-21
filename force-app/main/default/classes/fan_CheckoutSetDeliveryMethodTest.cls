@isTest
public with sharing class fan_CheckoutSetDeliveryMethodTest {
    @testSetup 
    static void makeData() {
        Account testAccount = new Account(
            Name = 'TestAccount',
            AccountNumber = '123456789',
            AM_Numero_de_documento__c = '123456789',
            AM_Tipo_de_documento__c = 'NIT'
          );
        insert testAccount;
        
        WebStore testWebStore = new WebStore(Name='TestWebStore');
        insert testWebStore;
        
        WebCart cart = new WebCart(Name='Cart', WebStoreId=testWebStore.Id, AccountId=testAccount.Id);
        insert cart;

        OrderDeliveryMethod orderDeliveryMethodTest = new OrderDeliveryMethod(Name='Delivery Method Test');
        insert orderDeliveryMethodTest;
        
        CartDeliveryGroup cartDeliveryGroupTest = new CartDeliveryGroup(CartId=cart.Id, Name='Default Delivery', DeliveryMethodId=orderDeliveryMethodTest.Id);
        insert cartDeliveryGroupTest;
        
        CartDeliveryGroupMethod cartDeliveryGroupMethodTest = new CartDeliveryGroupMethod(Name='Default Delivery Group', ShippingFee=85, WebCartId=cart.Id, DeliveryMethodId=orderDeliveryMethodTest.Id, CartDeliveryGroupId=cartDeliveryGroupTest.Id);
        insert cartDeliveryGroupMethodTest;
    }


    @IsTest
    static void setDeliveryMethodsTest(){
        Test.startTest();
        List<string> lstCartId = new List<string>();
        for (WebCart cart :  [SELECT Id FROM WebCart]) {
            lstCartId.add(cart.Id);
        }
        fan_CheckoutSetDeliveryMethod.setDeliveryMethods(lstCartId);
        Test.stopTest();
    }

    @IsTest
    static void setDeliveryMethodsWithDifferentOrderDeliveryMethodTest(){
        Test.startTest();
        
        List<string> lstCartId = new List<string>();
        for (WebCart cart :  [SELECT Id FROM WebCart]) {
            lstCartId.add(cart.Id);
        }

        OrderDeliveryMethod orderDeliveryMethod2Test = new OrderDeliveryMethod(Name='Delivery Method Test 2');
        insert orderDeliveryMethod2Test;

        CartDeliveryGroupMethod cartDeliveryGroupMethodTest = [SELECT Id FROM CartDeliveryGroupMethod LIMIT 1];
        cartDeliveryGroupMethodTest.DeliveryMethodId = orderDeliveryMethod2Test.Id;
        update cartDeliveryGroupMethodTest;

        fan_CheckoutSetDeliveryMethod.setDeliveryMethods(lstCartId);
        Test.stopTest();
    }
}