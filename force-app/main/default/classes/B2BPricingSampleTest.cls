@IsTest
class B2BPricingSampleTest {

    @TestSetup
    static void setup() {
        Account account = fan_B2BTestDataFactory.createAccount('1537786428', 'NIT');
        WebStore webStore = fan_B2BTestDataFactory.createWebStore('WebStore');
        WebCart cart = fan_B2BTestDataFactory.createWebCart( webStore.Id, account.Id, 'CONTADO');
        CartDeliveryGroup cartDeliveryGroup = fan_B2BTestDataFactory.createCartDeliveryGroup('CartDeliveryGroup', cart.Id);

        Product2 product = fan_B2BTestDataFactory.createProduct('SKU-1', 'P1', null);
        fan_B2BTestDataFactory.createCartItem(product, 'Product', 6, 20, cart.Id,  cartDeliveryGroup.Id);
    }
    
    @IsTest
    static void startCartProcessAsync() {

        WebCart webCart = [SELECT Id FROM WebCart];

        sfdc_checkout.IntegrationStatus integrationResult = new B2BPricingSample().startCartProcessAsync(null, webCart.Id);

        Assert.areEqual(sfdc_checkout.IntegrationStatus.Status.SUCCESS, integrationResult.status, 'The status of the integrationResult is not as expected.');
    }

    @IsTest
    static void productsWithNoSkuHasError() {

        WebCart webCart = [SELECT Id FROM WebCart];
        CartItem cartItem = [SELECT Id FROM CartItem];
        cartItem.Sku = null;
        UPDATE cartItem;

        new B2BPricingSample().startCartProcessAsync(new sfdc_checkout.IntegrationInfo(), webCart.Id);

        CartValidationOutput cartValidationOutput = [SELECT Message FROM CartValidationOutput];
        
        Assert.areEqual('The SKUs for all products in your cart must be defined.', cartValidationOutput.Message, 'The message of the cartValidationOutput is not as expected.');
    }
}