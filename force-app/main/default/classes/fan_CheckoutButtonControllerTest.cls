@IsTest
private class fan_CheckoutButtonControllerTest {
    @isTest
    static void testFetchCheckOutValidation() {
        List<fan_CheckOutValidation__mdt> result = Fan_CheckoutButtonController.fetchCheckOutValidation();

        System.assertEquals('Checkout Button', result[0].fan_Component__c);
        System.assertEquals('Checkout_Button_1', result[0].DeveloperName);
        System.assertEquals('RMT_Normal', result[0].fan_Order_Type__c);
    }
}