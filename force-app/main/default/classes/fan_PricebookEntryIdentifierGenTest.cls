@IsTest
class fan_PricebookEntryIdentifierGenTest {

    @TestSetup
    static void makeData() {
        Pricebook2 pricebook = new Pricebook2(Name = 'RMT');

        Product2 product = new Product2(
            Name = 'Product',
            ProductCode = 'SKU-1',
            IdProductoUNOEE__c = 'SKU-1'
        );
        INSERT pricebook;
        INSERT product;

        fan_B2BTestDataFactory.createPricebookEntry(Test.getStandardPricebookId(), product.Id, 10000);
        fan_B2BTestDataFactory.createPricebookEntry(pricebook.Id, product.Id, 10000);
    }

    @IsTest
    static void execute() {
        Test.startTest();
        Database.executeBatch(new fan_PricebookEntryIdentifierGen());
        Test.stopTest();

        PricebookEntry pricebookEntry = [SELECT fan_ExternalId__c FROM PricebookEntry WHERE Pricebook2.Name = 'RMT'];
        Assert.areEqual('SKU-1-RMT', pricebookEntry.fan_ExternalId__c, 'The fan_ExternalId__c of the pricebookEntry is not as expected.');
    }
}