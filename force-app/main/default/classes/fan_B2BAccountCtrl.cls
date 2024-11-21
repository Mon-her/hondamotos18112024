public with sharing class fan_B2BAccountCtrl {
    @AuraEnabled(cacheable=true)
    public static ContactPointAddress[] getShippingAddressList(String accountId) {
        ContactPointAddress[] addressList = [SELECT Name, AddressType, IsDefault, City, fan_Code__c FROM ContactPointAddress WHERE ParentId =: accountId AND AddressType = 'Shipping'];
        return addressList;
    }

    @AuraEnabled(cacheable=true)
    public static String getAccountNumber(String accountId) {
        try {
            return fan_B2BUtils.resolveAccountNumber(accountId);
        } catch (Exception e) {
            System.debug(LoggingLevel.ERROR, 'Error in getAccountNumber >>> '+e.getMessage());
            throw new AuraHandledException(e.getMessage());
        }
    }

    @AuraEnabled
    public static Account accountOptions(String accountId){
        try {
            return [SELECT fan_condicionPago__c, fan_plan_CL1__c FROM Account WHERE Id = :accountId LIMIT 1];
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }
}