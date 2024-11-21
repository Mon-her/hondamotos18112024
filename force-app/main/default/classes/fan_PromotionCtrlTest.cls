@IsTest
class fan_PromotionCtrlTest {

    @TestSetup
    static void makeData(){
        Account account = fan_B2BTestDataFactory.createAccount('1379221357', 'NIT');
        fan_B2BTestDataFactory.createBuyerAccount(account.Id);
        BuyerGroup buyerGroup = fan_B2BTestDataFactory.createBuyerGroup('Test Buyer Group');
        BuyerGroupMember buyerGroupMember = fan_B2BTestDataFactory.createBuyerGroupMember(account.Id, buyerGroup.Id);

        Product2 product = fan_B2BTestDataFactory.buildProduct('SKU-1', 'ProductCode-1', null);
        product.fan_Category__c = 'BUJIAS';
        INSERT product;

        fan_ConfiguracionRangoPrecio__c priceRangeConfiguration = fan_B2BTestDataFactory.buildPriceRangeConfiguration('Summer-Test', true, buyerGroup.Id, product.fan_Category__c);
        priceRangeConfiguration.fan_PaymentCondition__c = 'CON';
        priceRangeConfiguration.fan_Condicion_pago_en_carrito__c = 'contado';
        INSERT priceRangeConfiguration;

        PriceAdjustmentSchedule priceAdjustmentSchedule = fan_B2BTestDataFactory.createPriceAdjustmentSchedule('Summer-Test');
        fan_B2BTestDataFactory.createPriceAdjustmentTier(priceAdjustmentSchedule.Id, 1, 5, 'AdjustmentAmount', 63400.98);
    }

    @IsTest
    static void getPriceAdjustmentTiers() {
        String accountId = [SELECT Id FROM Account].Id;
        String productId = [SELECT Id FROM Product2].Id;

        PriceAdjustmentTier priceAdjustmentTier = fan_PromotionCtrl.getPriceAdjustmentTiers(accountId, productId)[0];

        Assert.areEqual(1, priceAdjustmentTier.LowerBound, 'The LowerBound of the PriceAdjustmentTier is not as expected.');
        Assert.areEqual(5, priceAdjustmentTier.UpperBound, 'The UpperBound of the PriceAdjustmentTier is not as expected.');
        Assert.areEqual('AdjustmentAmount', priceAdjustmentTier.TierType, 'The TierType of the PriceAdjustmentTier is not as expected.');
        Assert.areEqual(63400.98, priceAdjustmentTier.TierValue, 'The TierValue of the PriceAdjustmentTier is not as expected.');
    }

    @IsTest
    static void getPriceAdjustmentTiersShouldThrowAnException() {
        try {
            fan_PromotionCtrl.getPriceAdjustmentTiers(null, null);
            Assert.fail('An AuraHandledException was expected.');
        } catch (Exception e) {
            Assert.isInstanceOfType(e, AuraHandledException.class, 'The exception type is not as expected.');
        }
    }
}