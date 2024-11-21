@IsTest
class B2BTaxSampleTest {

    @TestSetup
    static void setup() {
        Account account = fan_B2BTestDataFactory.buildAccount('1537786428', 'NIT');
        account.fan_aplicaIVA__c = true;
        account.fan_aplicaIVAC__c = true;
        INSERT account;

        WebStore webStore = fan_B2BTestDataFactory.createWebStore('WebStore');
        WebCart cart = fan_B2BTestDataFactory.createWebCart( webStore.Id, account.Id, null);
        CartDeliveryGroup cartDeliveryGroup = fan_B2BTestDataFactory.createCartDeliveryGroup('CartDeliveryGroup', cart.Id);

        Product2 product = fan_B2BTestDataFactory.buildProduct('SKU-1', 'VariantChild-ProductCode1', null);
        product.fan_aplicaIVA__c = true;
        product.fan_aplicaIVAC__c = true;
        INSERT product;

        String shippingChargeProductCode = fan_InfoFletes__mdt.getInstance('producto').Label;
        Product2 charge = fan_B2BTestDataFactory.buildProduct(shippingChargeProductCode, shippingChargeProductCode, null);
        charge.fan_aplicaIVA__c = true;
        charge.fan_aplicaIVAC__c = true;
        INSERT charge;

        fan_B2BTestDataFactory.createCartItem(product, 'Product', 6, 20, cart.Id,  cartDeliveryGroup.Id);
        fan_B2BTestDataFactory.createCartItem(charge, 'Charge', 1, 20.4, cart.Id,  cartDeliveryGroup.Id);
    }
    
    @IsTest
    static void startCartProcessAsync() {
        Id webCartId = [SELECT Id FROM WebCart].Id;

        new B2BTaxSample().startCartProcessAsync(null, webCartId);
        
        Assert.areEqual(1, [SELECT Id FROM CartTax].size());
    }
    
    @IsTest
    static void startCartProcessAsyncShouldFail() {
        WebCart webCart = [SELECT Id FROM WebCart];
        CartItem cartItem = [SELECT Id FROM CartItem LIMIT 1];
        cartItem.TotalPrice = null;
        UPDATE cartItem;

        B2BTaxSample taxSample = new B2BTaxSample();
        taxSample.throwException = true;
        taxSample.startCartProcessAsync(new sfdc_checkout.IntegrationInfo(), webCart.Id);
        
        CartValidationOutput[] cartValidationOutputs = [SELECT Id FROM CartValidationOutput];
        Assert.isFalse(cartValidationOutputs.isEmpty(), 'There is no cartValidationOutputs.');
    }
}