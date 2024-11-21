global with sharing class fan_PricebookEntryIdentifierGen implements Database.Batchable<SObject> {

    static String[] pricebookNames = new String[] { 'RMT', 'REM', 'EMM', 'COU', 'AIR', 'RMT DISTRIBUIDOR', 'REM DISTRIBUIDOR', 'EMM DISTRIBUIDOR', 'COU DISTRIBUIDOR', 'AIR DISTRIBUIDOR' };

    global Database.QueryLocator start( Database.BatchableContext BC ) {
        return Database.getQueryLocator('SELECT Pricebook2.Name, Product2.IdProductoUNOEE__c FROM PricebookEntry WHERE Pricebook2.Name = :pricebookNames AND Product2.IdProductoUNOEE__c <> null');
    }
        
    global void execute(Database.BatchableContext bc, PricebookEntry[] pricebookEntries) {
        
        for (PricebookEntry pricebookEntry : pricebookEntries) {
            pricebookEntry.fan_ExternalId__c = pricebookEntry.Product2.IdProductoUNOEE__c + '-' + pricebookEntry.Pricebook2.Name;
        }
        UPDATE pricebookEntries;
    }
        
    global void finish( Database.BatchableContext bc) {}
}