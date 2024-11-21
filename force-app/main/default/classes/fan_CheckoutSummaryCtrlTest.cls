@IsTest
class fan_CheckoutSummaryCtrlTest {

    @TestSetup
    static void makeData(){
        Account account = fan_B2BTestDataFactory.createAccount('5311581', 'NIT');
        WebStore webStore = fan_B2BTestDataFactory.createWebStore('Test WebStore');
        WebCart webCart = fan_B2BTestDataFactory.createWebCart(webStore.Id, account.Id, null);

        Product2 product = fan_B2BTestDataFactory.createProduct('SKU-1', account.Id, null);
        String cartDeliveryGroupId = fan_B2BTestDataFactory.createCartDeliveryGroup('Test CartDeliveryGroup', webCart.Id).Id;
        CartItem cartItem = fan_B2BTestDataFactory.createCartItem(product, 'Product', 3, 42, webCart.Id, cartDeliveryGroupId);
        cartItem.fan_QuantityOrdered__c = 3;
        UPDATE cartItem;
    }

    @IsTest
    static void getCheckoutSummaryForWebCart() {
        Id cartId = [SELECT Id FROM WebCart].Id;
        Map<String, Decimal> checkoutSummary = fan_CheckoutSummaryCtrl.getCheckoutSummary(cartId);

        Assert.areEqual(119.7, checkoutSummary.get('subtotal'), 'The subtotal is not as expected.');
        Assert.areEqual(0, checkoutSummary.get('freight'), 'The freight is not as expected.');
        Assert.areEqual(0, checkoutSummary.get('estimatedTaxes'), 'The estimatedTaxes is not as expected.');
        Assert.areEqual(119.7, checkoutSummary.get('total'), 'The total is not as expected.');
    }

    @IsTest
    static void getCheckoutSummaryForOrderSummary() {
        OrderSummary orderSummary = fan_B2BTestDataFactory.generateOrderSummary();

        fan_CheckoutSummaryCtrl.testOrderSummary = orderSummary;
        Map<String, Decimal> checkoutSummary = fan_CheckoutSummaryCtrl.getCheckoutSummary(orderSummary.Id);

        Assert.areEqual(50, checkoutSummary.get('subtotal'), 'The subtotal is not as expected.');
        Assert.areEqual(8, checkoutSummary.get('freight'), 'The freight is not as expected.');
        Assert.areEqual(3, checkoutSummary.get('estimatedTaxes'), 'The estimatedTaxes is not as expected.');
        Assert.areEqual(61, checkoutSummary.get('total'), 'The total is not as expected.');
    }

    @IsTest
    static void getCheckoutSummaryShouldThrowAnException() {
        try {
            fan_CheckoutSummaryCtrl.getCheckoutSummary(null);
            Assert.fail('An exception was expected.');
        } catch (Exception e) {
            Assert.isInstanceOfType(e, AuraHandledException.class, 'An Aura handled exception is not as expected.');
        }
    }

    @IsTest
    static void getWebCartTotals() {
        Id cartId = [SELECT Id FROM WebCart].Id;
        Map<String, Decimal> totals = fan_CheckoutSummaryCtrl.getWebCartTotals(cartId);

        Assert.areEqual(119.7, totals.get('subtotal'), 'The subtotal is not as expected.');
        Assert.areEqual(0, totals.get('freight'), 'The freight is not as expected.');
        Assert.areEqual(0, totals.get('estimatedTaxes'), 'The estimatedTaxes is not as expected.');
        Assert.areEqual(119.7, totals.get('total'), 'The total is not as expected.');
    }

    @IsTest
    static void getOrderSummaryTotals() {
        fan_CheckoutSummaryCtrl.testOrderSummary = fan_B2BTestDataFactory.generateOrderSummary();
        Map<String, Decimal> totals = fan_CheckoutSummaryCtrl.getOrderSummaryTotals(null);

        Assert.areEqual(50, totals.get('subtotal'), 'The subtotal is not as expected.');
        Assert.areEqual(8, totals.get('freight'), 'The freight is not as expected.');
        Assert.areEqual(3, totals.get('estimatedTaxes'), 'The estimatedTaxes is not as expected.');
        Assert.areEqual(61, totals.get('total'), 'The total is not as expected.');
    }
    @IsTest
    static void isCartAnticipoTest() {
        // Crear datos de prueba
        WebCart cart = [SELECT Id FROM WebCart WHERE WebStore.Name = 'Test WebStore' LIMIT 1][0];
        cart.fan_EsAnticipo__c = true; // Puedes ajustar el valor según tu lógica
        upsert cart;

        Test.startTest();

        // Llamar al método isCartAnticipo
        Boolean result = fan_CheckoutSummaryCtrl.isCartAnticipo(cart.Id);

        // Verificar que el resultado sea el esperado
        System.assertEquals(true, result, 'El método isCartAnticipo no devolvió el valor correcto');

        Test.stopTest();
    }
}