@IsTest 
 class fan_PricebookJobTest {

    @TestSetup
    static void makeData(){

        fan_B2BTestDataFactory.createServiceEndpoint('fanalca', 'https://fanalca.com');

        Pricebook2 pricebook = new Pricebook2(Name = 'RMT');
        INSERT new Pricebook2(Name = 'RMT DISTRIBUIDOR');

        Product2 product = new Product2(
            Name = 'Product',
            ProductCode = 'SKU-1',
            IdProductoUNOEE__c = 'SKU-1'
        );
        INSERT pricebook;
        INSERT product;

        fan_B2BTestDataFactory.createPricebookEntry(Test.getStandardPricebookId(), product.Id, 10000);

        PricebookEntry pricebookEntry = fan_B2BTestDataFactory.buildPricebookEntry(pricebook.Id, product.Id, 10000);
        pricebookEntry.fan_ExternalId__c = product.IdProductoUNOEE__c + '-' + pricebook.Name;
        INSERT pricebookEntry;
    }

    @IsTest
    static void executeBatch() {

        Test.setMock(WebServiceMock.class, new fan_PricebookMock());
        Test.startTest();
        Integer batchSize = 200;
        DataBase.executeBatch(new fan_PricebookJob(batchSize), batchSize); 
        Test.stopTest();

        PricebookEntry[] pricebookEntries = [SELECT UnitPrice FROM PricebookEntry WHERE Pricebook2.Name LIKE 'RMT%' ORDER BY Pricebook2.Name];
        Assert.areEqual(12312, pricebookEntries[0].UnitPrice, 'The UnitPrice of the RMT pricebookEntry is not as expected.');
        Assert.areEqual(8618.4, pricebookEntries[1].UnitPrice, 'The UnitPrice of the RMT DISTRIBUIDOR pricebookEntry is not as expected.');
    }
}