@IsTest
public without sharing class fan_OrderStatusCtrlTest {
    @TestSetup
    static void makeData(){
        fan_ServiceEndpoint__c serviceTest = new fan_ServiceEndpoint__c(
            Nombre__c = 'Fanalca',
            usuario__c = 'test user',
            contrasena__c = 'test password',
            url__c = 'http://example.com'
        );
        INSERT serviceTest;

        Account accountTest = new Account(
            Name = 'Test Account',
            AccountNumber = '123456789',
            AM_Numero_de_documento__c = '123456789',
            AM_Tipo_de_documento__c = 'NIT'
        );
        INSERT accountTest;
    }

    @IsTest 
    static void getStatusF0sTest() {
        Test.setMock(WebServiceMock.class, new fan_OrderStatusFOsMock());
        String accountId = [SELECT Id FROM Account LIMIT 1].Id;
        FulfillmentOrder orderTest = new FulfillmentOrder(
            FulfilledToName = 'TEST',
            Status = 'TEST',
            AccountId = accountId
        );
        String[] numbersForServiceTest = new String[]{'F0-0123'};
        List<FulfillmentOrder> ordersTests = new List<FulfillmentOrder>{orderTest};
        
        Test.startTest();
        fan_OrderStatusCtrl.ordersTests = ordersTests;
        fan_OrderStatusCtrl.numbersForServiceTest = numbersForServiceTest;
        List<fan_OrderStatusCtrl.FulfillmentOrder> orders = fan_OrderStatusCtrl.getStatusF0s(accountId, '');
        Test.stopTest();
    }
}