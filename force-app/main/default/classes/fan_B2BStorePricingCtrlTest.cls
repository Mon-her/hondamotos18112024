@IsTest
class fan_B2BStorePricingCtrlTest {

    @IsTest
    static void getProductPrices() {

        ConnectApi.PricingResultLineItem testPricingResultLineItem = new ConnectApi.PricingResultLineItem();
        testPricingResultLineItem.productId = 'productId';
        testPricingResultLineItem.pricebookEntryId = 'pricebookEntryId';
        testPricingResultLineItem.listPrice = '53';
        testPricingResultLineItem.unitPrice = '48';
        testPricingResultLineItem.success = true;

        ConnectApi.PricingResult testPricingResult = new ConnectApi.PricingResult();
        testPricingResult.pricingLineItemResults = new ConnectApi.PricingResultLineItem[] { testPricingResultLineItem };

        fan_B2BStorePricingCtrl.testPricingResult = testPricingResult;
        ConnectApi.PricingResult pricingResult =  fan_B2BStorePricingCtrl.getProductPrices('communityId', 'effectiveAccountId', new String[] { 'ProductId' });

        ConnectApi.PricingResultLineItem pricingResultLineItem = pricingResult.pricingLineItemResults[0];

        Assert.areEqual(testPricingResultLineItem.productId, pricingResultLineItem.productId, 'The productId of the PricingResultLineItem is not as expected.');
        Assert.areEqual(testPricingResultLineItem.pricebookEntryId, pricingResultLineItem.pricebookEntryId, 'The pricebookEntryId of the PricingResultLineItem is not as expected.');
        Assert.areEqual(testPricingResultLineItem.listPrice, pricingResultLineItem.listPrice, 'The listPrice of the PricingResultLineItem is not as expected.');
        Assert.areEqual(testPricingResultLineItem.unitPrice, pricingResultLineItem.unitPrice, 'The unitPrice of the PricingResultLineItem is not as expected.');
        Assert.areEqual(testPricingResultLineItem.success, pricingResultLineItem.success, 'The success of the PricingResultLineItem is not as expected.');
    }

	@IsTest
	static void getProductPricesShouldThrowAnException() {
		try {
            fan_B2BStorePricingCtrl.getProductPrices('', '', null );
			Assert.fail('An AuraHandledException was expected.');
		} catch (Exception e) {
			Assert.isInstanceOfType(e, AuraHandledException.class, 'An exception was expected.');
		}
	}
}