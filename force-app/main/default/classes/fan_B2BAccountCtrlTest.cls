@isTest
public with sharing class fan_B2BAccountCtrlTest {
    
    @TestSetup
    static void makeData(){
        Account accountTest = fan_B2BCartCtrlTestUtils.createAccount();
        
        fan_B2BCartCtrlTestUtils.createContactPointAddress(accountTest.Id, 'Shipping', 'envioCodeTest', true);
    }

    @IsTest
    static void getShippingAddressTest(){

        string accountIdTest = [SELECT Id FROM Account LIMIT 1].Id;
        try {
            ContactPointAddress[] cpaAddressTest = [SELECT Name, AddressType, fan_Code__c, IsDefault FROM ContactPointAddress WHERE AddressType = 'Shipping']; 
            ContactPointAddress[] cpaListTest = fan_B2BAccountCtrl.getShippingAddressList(accountIdTest);
            System.assertEquals(cpaAddressTest[0], cpaListTest[0]);
            System.assert(cpaListTest.size() == cpaAddressTest.size());
        } catch (Exception e) {
            System.debug(LoggingLevel.ERROR, 'Error in getShippingAddressTest >>> ' + e.getMessage());
        }

    }

    @IsTest
    static void getAccountNumberTest(){
        String accountIdTest = [SELECT Id FROM Account LIMIT 1].Id;
        Test.startTest();
        try {
            fan_B2BAccountCtrl.getAccountNumber(accountIdTest);
        } catch (Exception e) {
            System.debug(LoggingLevel.ERROR, 'Error in getAccountNumberTest >>> ' + e.getMessage());
        }
        Test.stopTest();
    }

    @IsTest
    static void getAccountNumberWithInvalidAccountId(){
        String accountIdTest = '0';
        try {
            fan_B2BAccountCtrl.getAccountNumber(accountIdTest);
            Assert.fail('Expected an Exception');
        } catch (Exception e) {
           Assert.isInstanceOfType(e, AuraHandledException.class, 'Error expected an AuraHandledException');
        }
    }

    @IsTest
    static void accountOptions() {
        String accountId = [SELECT Id FROM Account].Id;
        Account account = fan_B2BAccountCtrl.accountOptions(accountId);

        Assert.isNotNull(account, 'The account is null.');
    }

    @IsTest
    static void accountOptionsThrowAnException() {
        try {
            fan_B2BAccountCtrl.accountOptions(null);
            Assert.fail('An exception was expected.');
        } catch (Exception e) {
            Assert.isInstanceOfType(e, AuraHandledException.class, 'An AuraHandledException was expected.');
        }
    }
}