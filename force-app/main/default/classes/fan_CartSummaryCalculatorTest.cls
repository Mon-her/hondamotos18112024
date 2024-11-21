@IsTest
class fan_CartSummaryCalculatorTest {

    @TestSetup
    static void makeData(){
        Account account = fan_B2BTestDataFactory.createAccount('123456789', 'NIT');
        WebStore webStore = new WebStore(
            Id = fan_IdTienda__mdt.getInstance('posventa').fan_IdTienda__c,
            Name = 'Posventa'
        );
        UPDATE webStore;
        WebCart webCart = fan_B2BTestDataFactory.createWebCart(webStore.Id, account.Id, null);

        Product2[] products = new Product2[] {
            fan_B2BTestDataFactory.buildProduct('SKU-1', 'ProductCode-1', null),
            fan_B2BTestDataFactory.buildProduct('SKU-1.1', 'ProductCode-1.1', null),
            fan_B2BTestDataFactory.buildProduct('SKU-2', 'ProductCode-2', null)
        };
        INSERT products;

        fan_RelatedProducts__c relatedProduct = fan_B2BTestDataFactory.createRelatedProduct(products[0].Id, products[1].Id, '3');
        CartDeliveryGroup cartDeliveryGroup = fan_B2BTestDataFactory.createCartDeliveryGroup('CartDeliveryGroup', webCart.Id);

        INSERT new CartItem[] {
            fan_B2BTestDataFactory.buildCartItem(products[0], 'Product', 267, 64, webCart.Id, cartDeliveryGroup.Id),
            fan_B2BTestDataFactory.buildCartItem(products[1], 'Product', 33, 64, webCart.Id, cartDeliveryGroup.Id),
            fan_B2BTestDataFactory.buildCartItem(products[2], 'Product', 116, 64, webCart.Id, cartDeliveryGroup.Id)
        };
    }

    @IsTest
    static void getProductTaxRateShouldReturn0() {
        Decimal taxRate = fan_CartSummaryCalculator.getProductTaxRate(new Product2(), new Account(), fan_Impuesto__mdt.getAll());

        Assert.areEqual(0, taxRate, 'The taxRate is not as expected.');
    }


    @IsTest
    static void getProductTaxRateShouldReturn0point27() {
        Account account = new Account(
            fan_aplicaIVA__c = true,
            fan_aplicaIVAC__c = true
        );
        Product2 product = new Product2(
            fan_aplicaIVA__c = true,
            fan_aplicaIVAC__c = true
        );

        Decimal taxRate = fan_CartSummaryCalculator.getProductTaxRate(product, account, fan_Impuesto__mdt.getAll());

        Assert.areEqual(0.27, taxRate, 'The taxRate is not as expected.');
    }

    @IsTest
    static void getCartSummaryForCashPaymentCondition() {
        WebCart cart = [SELECT
                                TYPEOF Account
                                WHEN Account THEN fan_aplicaIVA__c, fan_aplicaIVAC__c
                                END,
                            WebStore.fan_LocationGroupReference__c 
                            FROM WebCart LIMIT 1];

        Set<String> skus = new Set<String>();
        for (CartItem cartItem : [SELECT Sku FROM CartItem WHERE CartId =: cart.Id]) {
            skus.add(cartItem.Sku);
        }
        fan_InventoryHandler.testOutputRepresentation = fan_B2BTestDataFactory.generateOCIGetInventoryAvailability(cart.WebStore.fan_LocationGroupReference__c, '002536', new List<String>(skus));

        fan_CartSummaryCalculator.CartSummary cartSummary = fan_CartSummaryCalculator.getCartSummaryForCashPaymentCondition(cart);

        Assert.areEqual(19200, cartSummary.grossValue, 'The grossValue of the cartSummary is not as expected.');
        Assert.areEqual(960, cartSummary.discounts, 'The discounts of the cartSummary is not as expected.');
        Assert.areEqual(18240, cartSummary.subtotal, 'The subtotal of the cartSummary is not as expected.');
        Assert.areEqual(0, cartSummary.IVA, 'The IVA of the cartSummary is not as expected.');
        Assert.areEqual(18240, cartSummary.totalToPay, 'The totalToPay of the cartSummary is not as expected.');
    }

    @IsTest
    static void getCartSummaryForCreditPaymentCondition() {
        WebCart cart = [SELECT
                                TYPEOF Account
                                WHEN Account THEN fan_aplicaIVA__c, fan_aplicaIVAC__c
                                END,
                            TotalAdjustmentAmount,
                            TotalListAmount,
                            TotalProductAmount
                            FROM WebCart LIMIT 1];

        Set<String> skus = new Set<String>();
        for (CartItem cartItem : [SELECT Sku FROM CartItem WHERE CartId =: cart.Id]) {
            skus.add(cartItem.Sku);
        }
        fan_CartSummaryCalculator.CartSummary cartSummary = fan_CartSummaryCalculator.getCartSummaryForCreditPaymentCondition(cart);

        Assert.areEqual(26624, cartSummary.grossValue, 'The grossValue of the cartSummary is not as expected.');
        Assert.areEqual(1331.2, cartSummary.discounts, 'The discounts of the cartSummary is not as expected.');
        Assert.areEqual(25292.8, cartSummary.subtotal, 'The subtotal of the cartSummary is not as expected.');
        Assert.areEqual(0, cartSummary.IVA, 'The IVA of the cartSummary is not as expected.');
        Assert.areEqual(25292.8, cartSummary.totalToPay, 'The totalToPay of the cartSummary is not as expected.');
    }

    @IsTest
    static void getCartTotalsForNullPaymentCondition() {
        String cartId = [SELECT Id FROM WebCart LIMIT 1].Id;

        fan_CartSummaryCalculator.CartSummary cartSummary = fan_CartSummaryCalculator.getCartTotals(cartId);

        Assert.areEqual(0, cartSummary.grossValue, 'The grossValue of the cartSummary is not as expected.');
        Assert.areEqual(0, cartSummary.discounts, 'The discounts of the cartSummary is not as expected.');
        Assert.areEqual(0, cartSummary.subtotal, 'The subtotal of the cartSummary is not as expected.');
        Assert.areEqual(0, cartSummary.IVA, 'The IVA of the cartSummary is not as expected.');
        Assert.areEqual(0, cartSummary.totalToPay, 'The totalToPay of the cartSummary is not as expected.');
    }

    @IsTest
    static void getCartTotalsForCashPaymentCondition() {
        WebCart cart = [SELECT WebStore.fan_LocationGroupReference__c FROM WebCart LIMIT 1];
        cart.fan_FormaPago__c = fan_Constants.FormaPago.CONTADO.name();
        UPDATE cart;

        Set<String> skus = new Set<String>();
        for (CartItem cartItem : [SELECT Sku FROM CartItem WHERE CartId =: cart.Id]) {
            skus.add(cartItem.Sku);
        }
        fan_InventoryHandler.testOutputRepresentation = fan_B2BTestDataFactory.generateOCIGetInventoryAvailability(cart.WebStore.fan_LocationGroupReference__c, '002536', new List<String>(skus));

        fan_CartSummaryCalculator.CartSummary cartSummary = fan_CartSummaryCalculator.getCartTotals(cart.Id);

        Assert.areEqual(19200, cartSummary.grossValue, 'The grossValue of the cartSummary is not as expected.');
        Assert.areEqual(960, cartSummary.discounts, 'The discounts of the cartSummary is not as expected.');
        Assert.areEqual(18240, cartSummary.subtotal, 'The subtotal of the cartSummary is not as expected.');
        Assert.areEqual(0, cartSummary.IVA, 'The IVA of the cartSummary is not as expected.');
        Assert.areEqual(18240, cartSummary.totalToPay, 'The totalToPay of the cartSummary is not as expected.');
    }

    @IsTest
    static void getCartTotalsForCreditPaymentCondition() {
        WebCart cart = [SELECT Id FROM WebCart LIMIT 1];
        cart.fan_FormaPago__c = fan_Constants.FormaPago.CREDITO.name();
        UPDATE cart;

        Set<String> skus = new Set<String>();
        for (CartItem cartItem : [SELECT Sku FROM CartItem WHERE CartId =: cart.Id]) {
            skus.add(cartItem.Sku);
        }
        fan_CartSummaryCalculator.CartSummary cartSummary = fan_CartSummaryCalculator.getCartTotals(cart.Id);

        Assert.areEqual(26624, cartSummary.grossValue, 'The grossValue of the cartSummary is not as expected.');
        Assert.areEqual(1331.2, cartSummary.discounts, 'The discounts of the cartSummary is not as expected.');
        Assert.areEqual(25292.8, cartSummary.subtotal, 'The subtotal of the cartSummary is not as expected.');
        Assert.areEqual(0, cartSummary.IVA, 'The IVA of the cartSummary is not as expected.');
        Assert.areEqual(25292.8, cartSummary.totalToPay, 'The totalToPay of the cartSummary is not as expected.');
    }
}