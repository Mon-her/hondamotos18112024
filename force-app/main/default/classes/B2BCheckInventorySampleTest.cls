@IsTest
class B2BCheckInventorySampleTest {

    @TestSetup
    static void setup() {
        Account account = fan_B2BTestDataFactory.createAccount('1537786428', 'NIT');
        WebStore webStore = new WebStore(
            Id = fan_IdTienda__mdt.getInstance('posventa').fan_IdTienda__c,
            Name = 'Posventa'
        );
        UPDATE webStore;
        WebCart cart = fan_B2BTestDataFactory.createWebCart( webStore.Id, account.Id, 'CONTADO');
        CartDeliveryGroup cartDeliveryGroup = fan_B2BTestDataFactory.createCartDeliveryGroup('CartDeliveryGroup', cart.Id);

        Product2 product = fan_B2BTestDataFactory.createProduct('SKU-1', 'P1', null);
        fan_B2BTestDataFactory.createCartItem(product, 'Product', 6, 20, cart.Id,  cartDeliveryGroup.Id);
    }
    
    @IsTest
    static void startCartProcessAsync() {
        
        CartItem cartItem = [SELECT Sku, CartId FROM CartItem];

        fan_InventoryHandler.testOutputRepresentation = fan_B2BTestDataFactory.generateOCIGetInventoryAvailability('B2B', '002536', new String[]{ cartItem.Sku });
        sfdc_checkout.IntegrationStatus integrationResult = new B2BCheckInventorySample().startCartProcessAsync(null, cartItem.CartId);

        Assert.areEqual(sfdc_checkout.IntegrationStatus.Status.SUCCESS, integrationResult.status, 'The status of the integrationResult is not as expected.');
    }

    @IsTest
    static void noInventoryData() {
        
        WebCart webCart = [SELECT Id FROM WebCart];

        new B2BCheckInventorySample().startCartProcessAsync(new sfdc_checkout.IntegrationInfo(), webCart.Id);

        CartValidationOutput[] cartValidationOutputs = [SELECT Id FROM CartValidationOutput];
        Assert.isFalse(cartValidationOutputs.isEmpty(), 'There is no cartValidationOutputs.');
    }
    
    @IsTest
    static void emptyCartHasError() {

        WebCart webCart = [SELECT Id FROM WebCart];
        DELETE [SELECT Id FROM CartItem];

        new B2BCheckInventorySample().startCartProcessAsync(new sfdc_checkout.IntegrationInfo(), webCart.Id);

        CartValidationOutput cartValidationOutput = [SELECT Message FROM CartValidationOutput];

        Assert.areEqual('Looks like your cart is empty.', cartValidationOutput.Message, 'The message of the cartValidationOutput is not as expected.');
    }

    @IsTest
    static void productsWithNoSkuHasError() {

        WebCart webCart = [SELECT Id FROM WebCart];
        CartItem cartItem = [SELECT Id FROM CartItem];
        cartItem.Sku = null;
        UPDATE cartItem;

        new B2BCheckInventorySample().startCartProcessAsync(new sfdc_checkout.IntegrationInfo(), webCart.Id);

        CartValidationOutput cartValidationOutput = [SELECT Message FROM CartValidationOutput];

        Assert.areEqual('The SKUs for all products in your cart must be defined.', cartValidationOutput.Message, 'The message of the cartValidationOutput is not as expected.');
    }
}