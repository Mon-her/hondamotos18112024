@IsTest
public class fan_B2BCartCtrlTest {

    @TestSetup
    static void makeData(){

        String normalPricebookId = fan_B2BCartCtrlTestUtils.createPricebook('Motos').Id;
        String dealerPricebookId = fan_B2BCartCtrlTestUtils.createPricebook('Descuentos Credito').Id;

        WebStore webstore = new WebStore(
            Id = fan_IdTienda__mdt.getInstance('motos').fan_IdTienda__c,
            StrikethroughPricebookId = normalPricebookId
        );
        UPDATE webstore;

        Account accountTest = fan_B2BCartCtrlTestUtils.createAccount();
        fan_B2BTestDataFactory.createBuyerAccount(accountTest.Id);
        BuyerGroup buyerGroup = fan_B2BTestDataFactory.createBuyerGroup('Motos BuyerGroup');
        fan_B2BTestDataFactory.createBuyerGroupMember(accountTest.Id, buyerGroup.Id);
        fan_B2BTestDataFactory.createWebStoreBuyerGroup(buyerGroup.Id, webstore.Id);

        fan_B2BTestDataFactory.createBuyerGroupPricebook(buyerGroup.Id, dealerPricebookId, 1, true);

        Product2 productTest = fan_B2BCartCtrlTestUtils.createProduct('SKU-1', 'ProductCode-1');
        fan_B2BCartCtrlTestUtils.createProduct('SKU-2', 'ProductCode-2');

        fan_B2BCartCtrlTestUtils.createStandardPricebookEntry(productTest.Id);
        fan_B2BCartCtrlTestUtils.createPricebookEntry(productTest.Id, normalPricebookId, 23.7);
        fan_B2BCartCtrlTestUtils.createPricebookEntry(productTest.Id, dealerPricebookId, 19.4);

        WebCart cartTest = fan_B2BTestDataFactory.createWebCart(webstore.Id, accountTest.Id, 'credito');

        String cartDeliveryGroupId = fan_B2BCartCtrlTestUtils.createCartDeliveryGroup(cartTest.Id, null);

        fan_B2BCartCtrlTestUtils.createContactPointAddress(accountTest.Id, 'Shipping', 'TEST-CPA-1', false);
        fan_B2BCartCtrlTestUtils.createContactPointAddress(accountTest.Id, 'Shipping', 'TEST-CPA-2', false);

        fan_B2BCartCtrlTestUtils.createContactPointAddress(accountTest.Id, 'Shipping', 'envioCodeTest', true);
        fan_B2BCartCtrlTestUtils.createContactPointAddress(accountTest.Id, 'Facturación', 'facturaCodeTest', true);

        INSERT new CartItem(
            Name = productTest.Name,
            Product2Id = productTest.Id,
            Type = 'Product',
            CartId = cartTest.Id,
            CartDeliveryGroupId = cartDeliveryGroupId,
            Quantity = 5
        );

        fan_B2BTestDataFactory.createPromotion('Descuentos aplicados');
        fan_B2BTestDataFactory.createPromotion('Promoción B2B');
        fan_B2BCartCtrlTestUtils.setCartItemPrices(cartTest.Id, new Set<String> { productTest.Id }, normalPricebookId, dealerPricebookId);
    }

    @Istest
    static void getCartSummaryTest() {
        ConnectApi.CartSummary testCartSummary = new ConnectApi.CartSummary();
        testCartSummary.name = 'Cart';
        testCartSummary.currencyIsoCode = 'COP';
        testCartSummary.isSecondary = false;
        testCartSummary.status = ConnectApi.CartStatus.ACTIVE;
        testCartSummary.type = ConnectApi.CartType.CART;
        testCartSummary.uniqueProductCount = 5;
        testCartSummary.totalProductCount = '23';
        testCartSummary.totalListPrice = '983.00';

        fan_B2BCartCtrlUtils.testCartSummary = testCartSummary;
        ConnectApi.CartSummary cartSummary = fan_B2BCartCtrl.getCartSummary('', '');

        System.assertEquals('Cart', cartSummary.name);
        System.assertEquals('COP', cartSummary.currencyIsoCode);
        System.assertEquals(false, cartSummary.isSecondary);
        System.assertEquals(ConnectApi.CartStatus.ACTIVE, cartSummary.status);
        System.assertEquals(ConnectApi.CartType.CART, cartSummary.type);
        System.assertEquals(5, cartSummary.uniqueProductCount);
        System.assertEquals('23', cartSummary.totalProductCount);
        System.assertEquals('983.00', cartSummary.totalListPrice);
    }

    @Istest
    static void updateCartItemBackorderTest() {
        
        
        // Catch exception
        try {
            // Throw exception   
            fan_B2BCartCtrl.updateCartItemBackorder(new ConnectApi.CartItem(), false);
        } catch (Exception e) {
            System.debug(e.getMessage());
        }
    }

    @Istest
    static void addToCartWithNoContactPointAddressCode() {

        CartItem cartItemRecord = [SELECT Product2Id FROM CartItem WHERE Product2.StockKeepingUnit =: 'SKU-1' LIMIT 1];

        ConnectApi.CartItem cartItem = new ConnectApi.CartItem();
        cartItem.cartItemId = cartItemRecord.Id;
        fan_B2BCartCtrlUtils.testCartItem = cartItem;

        fan_B2BCartCtrl.addToCart('', '', '', new CartItem(
            fan_IsBackorder__c = true,
            Product2Id = cartItemRecord.Product2Id
        ));

        CartItem insertedCartItem = [SELECT fan_IsBackorder__c FROM CartItem WHERE Id =: cartItemRecord.Id];

        Assert.isTrue(insertedCartItem.fan_IsBackOrder__c, 'The fan_IsBackOrder__c is not as expected.');
    }

    @Istest
    static void addToCartWithContactPointAddressCode() {

        CartItem cartItemInput = [SELECT Product2Id, CartId FROM CartItem WHERE Product2.StockKeepingUnit =: 'SKU-1' LIMIT 1];
        String accountId = [SELECT Id FROM Account LIMIT 1].Id;
        String contactPoinAddressCode = 'TEST-CPA-1';
        String webStoreId = [SELECT Id FROM WebStore LIMIT 1].Id;

        fan_B2BUtils.testWebStoreId = webStoreId;

        ConnectApi.CartSummary cartSummaryTest = new ConnectApi.CartSummary();
        cartSummaryTest.cartId = cartItemInput.CartId;
        fan_B2BCartCtrlUtils.testCartSummary = cartSummaryTest;

        fan_B2BCartCtrl.addToCart('', accountId, contactPoinAddressCode, new CartItem(
            Product2Id = cartItemInput.Product2Id,
            fan_IsBackorder__c = false,
            Quantity = 31
        ));

        CartItem insertedCartItem = [SELECT Quantity, fan_IsBackOrder__c FROM CartItem WHERE CartDeliveryGroup.fan_CPACode__c =: contactPoinAddressCode];

        Assert.isFalse(insertedCartItem.fan_IsBackOrder__c, 'The fan_IsBackOrder__c is not as expected.');
        Assert.areEqual(36, insertedCartItem.Quantity, 'The Quantity is not as expected.');
    }

    @Istest
    static void addToCartToADifferenteBranch() {

        CartItem cartItemInput = [SELECT Product2Id, CartId, CartDeliveryGroupId FROM CartItem WHERE Product2.StockKeepingUnit =: 'SKU-1' LIMIT 1];
        String accountId = [SELECT Id FROM Account LIMIT 1].Id;
        String contactPoinAddressCode = 'TEST-CPA-2';
        String webStoreId = [SELECT Id FROM WebStore LIMIT 1].Id;

        // Required to be able to add a new branch. Branch fan_CPACode__c must not be null (Default CartDeliveryGroup).
        CartDeliveryGroup cartDeliveryGroup = new CartDeliveryGroup(
            Id = cartItemInput.CartDeliveryGroupId,
            fan_CPACode__c = 'TEST-CPA-1');
        UPDATE cartDeliveryGroup;

        fan_B2BUtils.testWebStoreId = webStoreId;

        ConnectApi.CartSummary cartSummaryTest = new ConnectApi.CartSummary();
        cartSummaryTest.cartId = cartItemInput.CartId;
        fan_B2BCartCtrlUtils.testCartSummary = cartSummaryTest;

        fan_B2BCartCtrl.addToCart('', accountId, contactPoinAddressCode, new CartItem(
            Product2Id = cartItemInput.Product2Id,
            fan_IsBackorder__c = false,
            Quantity = 31
        ));
        CartItem insertedCartItem = [SELECT Quantity, fan_IsBackOrder__c FROM CartItem WHERE CartDeliveryGroup.fan_CPACode__c =: contactPoinAddressCode];

        Assert.isFalse(insertedCartItem.fan_IsBackOrder__c, 'The fan_IsBackOrder__c is not as expected.');
        Assert.areEqual(31, insertedCartItem.Quantity, 'The Quantity is not as expected.');
    }

    @IsTest
    static void addToCartWithWrongContactPointAddressCode() {

        try {
            CartItem cartItemInput = [SELECT Id, Product2Id, CartId FROM CartItem WHERE Product2.StockKeepingUnit =: 'SKU-1' LIMIT 1];
            String accountId = [SELECT Id FROM Account LIMIT 1].Id;
            String contactPoinAddressCode = 'RANDOM-CPA';

            ConnectApi.CartSummary cartSummaryTest = new ConnectApi.CartSummary();
            cartSummaryTest.cartId = cartItemInput.CartId;
            fan_B2BCartCtrlUtils.testCartSummary = cartSummaryTest;

            fan_B2BCartCtrl.addToCart('', accountId, contactPoinAddressCode, new CartItem(
                Product2Id = cartItemInput.Product2Id,
                fan_IsBackorder__c = false,
                Quantity = 31
            ));
            Assert.fail('An Aura handled exception exception was expected.');
        } catch (Exception e) {
            Assert.isInstanceOfType(e, AuraHandledException.class, 'The exception is not as expected.');
        }
    }

    /**
     * This is just a simulation because the product will not be added with the ConnectApi.
     * An previously added CartItem will be updated.
     */
    @Istest
    static void addToCartUnregisteredProduct() {

        CartItem cartItemInput = [SELECT Id, CartId FROM CartItem WHERE Product2.StockKeepingUnit =: 'SKU-1' LIMIT 1];
        String productId = [SELECT Id FROM Product2 WHERE StockKeepingUnit = 'SKU-2'].Id;
        String accountId = [SELECT Id FROM Account LIMIT 1].Id;
        String contactPoinAddressCode = 'TEST-CPA-1';

        ConnectApi.CartItem cartItem = new ConnectApi.CartItem();
        cartItem.cartItemId = cartItemInput.Id;
        fan_B2BCartCtrlUtils.testCartItem = cartItem;

        ConnectApi.CartSummary cartSummaryTest = new ConnectApi.CartSummary();
        cartSummaryTest.cartId = cartItemInput.CartId;
        fan_B2BCartCtrlUtils.testCartSummary = cartSummaryTest;

        fan_B2BCartCtrl.addToCart('', accountId, contactPoinAddressCode, new CartItem(
            Product2Id = productId,
            fan_IsBackorder__c = true
        ));

        CartItem insertedCartItem = [SELECT fan_IsBackOrder__c, CartDeliveryGroup.fan_CPACode__c  FROM CartItem WHERE Id =: cartItemInput.Id];

        Assert.isTrue(insertedCartItem.fan_IsBackOrder__c, 'The fan_IsBackOrder__c is not as expected.');
        Assert.areEqual(contactPoinAddressCode, insertedCartItem.CartDeliveryGroup.fan_CPACode__c, 'The CartDeliveryGroup fan_CPACode__c is not as expected.');
    }

    @IsTest
    static void createCartTest() {
        ConnectApi.CartSummary testCartSummary = new ConnectApi.CartSummary();
        testCartSummary.name = 'Cart';
        testCartSummary.currencyIsoCode = 'COP';
        testCartSummary.isSecondary = false;
        testCartSummary.status = ConnectApi.CartStatus.ACTIVE;
        testCartSummary.type = ConnectApi.CartType.CART;
        testCartSummary.uniqueProductCount = 5;

        fan_B2BCartCtrl.testCartSummary = testCartSummary;
        ConnectApi.CartSummary cartSummary = fan_B2BCartCtrl.createCart('', '');

        System.assertEquals('Cart', cartSummary.name);
        System.assertEquals('COP', cartSummary.currencyIsoCode);
        System.assert(!cartSummary.isSecondary);
        System.assertEquals(ConnectApi.CartStatus.ACTIVE, cartSummary.status);
        System.assertEquals(ConnectApi.CartType.CART, cartSummary.type);
        System.assertEquals(5, cartSummary.uniqueProductCount);
    }

    @IsTest
    static void deleteCartTest() {
        fan_B2BCartCtrl.deleteCart('', '', '');
    }

    @IsTest
    static void deleteCartItemTest() {

        String cartId = [SELECT Id FROM WebCart LIMIT 1].Id;
        String cartItemId = [SELECT Id FROM CartItem LIMIT 1].Id;

        System.assertEquals('Test CartGroup', [SELECT Name FROM CartDeliveryGroup LIMIT 1].Name);

        fan_B2BCartCtrl.deleteCartItem('', '', cartId, cartItemId);
        System.assertEquals('Test CartGroup', [SELECT Name FROM CartDeliveryGroup LIMIT 1].Name);
    }

    @IsTest
    static void getCartItemsTest() {

        String productSku = 'SKU-1';
        String testWebCartId = [SELECT Id FROM WebCart LIMIT 1].Id;
        CartItem testCartItem = [SELECT Id FROM CartItem LIMIT 1];
        PricebookEntry[] pricebookEntry = [SELECT UnitPrice, Product2Id FROM PricebookEntry WHERE Pricebook2.Name IN :(new String[]{ 'Motos', 'Descuentos Credito' }) AND Product2.StockKeepingUnit = :productSku ORDER BY Pricebook2.Name ASC];
        Decimal unitPrice = pricebookEntry[0].UnitPrice;
        Decimal listPrice = pricebookEntry[1].UnitPrice;

        ConnectApi.CartItemResult testCartItemResult = new ConnectApi.CartItemResult();
        testCartItemResult.cartItem = new ConnectApi.CartItem();
        testCartItemResult.cartItem.cartItemId = testCartItem.Id;

        ConnectApi.CartItemCollection testCartItemCollection = new ConnectApi.CartItemCollection();
        testCartItemCollection.cartItems = new List<ConnectApi.CartItemResult> {
            testCartItemResult
        };

        fan_B2BCartCtrl.testCartItemCollection = testCartItemCollection;

        fan_B2BCartCtrlUtils.CartItemCollectionWrapper cartItemCollectionWrapper = fan_B2BCartCtrl.getCartItems('', '', testWebCartId, '', 0, '');
        System.assertEquals(testCartItem.Id, cartItemCollectionWrapper.cartItems[0].cartItem.cartItemId, 'The CartItem Id is not as expected.');
    }

    @IsTest
    static void updateCartItemsBackorderTest() {

        // Update null cart items list 
        try {
            fan_B2BCartCtrl.updateCartItemsBackorder(null);
        } catch (Exception e) {
            System.assert(e instanceof AuraHandledException);
        }

        CartItem testCartItem = [SELECT fan_IsBackOrder__c FROM CartItem LIMIT 1];

        System.assert(!testCartItem.fan_IsBackOrder__c);

        // Update cart items list 
        testCartItem.fan_IsBackOrder__c = true;
        fan_B2BCartCtrl.updateCartItemsBackorder(new List<CartItem>{
            testCartItem
        });

        System.assert([SELECT fan_IsBackOrder__c FROM CartItem LIMIT 1].fan_IsBackOrder__c);
    }

    @IsTest
    static void updateCartItemQuantity() {

        String productSku = 'SKU-1';
        String cartId = [SELECT Id FROM WebCart LIMIT 1].Id;
        CartItem cartItem = [SELECT UnitAdjustedPrice, ListPrice, TotalListPrice, TotalPrice FROM CartItem WHERE Product2.StockKeepingUnit =: productSku LIMIT 1];
        PricebookEntry[] pricebookEntry = [SELECT UnitPrice, Product2Id FROM PricebookEntry WHERE Pricebook2.Name IN :(new String[]{ 'Motos', 'Descuentos Credito' }) AND Product2.StockKeepingUnit = :productSku ORDER BY Pricebook2.Name ASC];
        Decimal unitPrice = pricebookEntry[0].UnitPrice;
        Decimal listPrice = pricebookEntry[1].UnitPrice;
        Decimal quantity = 20;

        CartItem updatedCartItem = fan_B2BCartCtrl.updateCartItemQuantity(cartId, cartItem.Id, quantity)
        .get(cartItem.Id);

        System.assertEquals(quantity, updatedCartItem.Quantity, 'The Quantity of the CartItem is not as expected.');
        System.assertEquals(unitPrice, updatedCartItem.UnitAdjustedPrice, 'The UnitAdjustedPrice of the CartItem is not as expected.');
        System.assertEquals(listPrice, updatedCartItem.ListPrice, 'The ListPrice of the CartItem is not as expected.');
        System.assertEquals(unitPrice * quantity, updatedCartItem.TotalPrice, 'The TotalPrice of the CartItem is not as expected.');
        System.assertEquals(listPrice * quantity, updatedCartItem.TotalListPrice, 'The TotalListPrice of the CartItem is not as expected.');
    }

    @IsTest
    static void updateCartItemQuantityWithEmptyCartItemId() {

        String cartId = [SELECT Id FROM WebCart LIMIT 1].Id;
        String cartItemId = '';
        Decimal quantity = 20;

        try {
            fan_B2BCartCtrl.updateCartItemQuantity(cartId, cartItemId, quantity);
            Assert.fail('An AuraHandledException was expected.');
        } catch (Exception e) {
            Assert.isInstanceOfType(e, AuraHandledException.class, 'The exception type is not as expected.');
        }
    }

    @IsTest
    static void updateOrderType() {
        WebCart cart = [SELECT Id, webStoreId, fan_TipoPedido__c FROM WebCart LIMIT 1];

        fan_B2BOrderTypeValidation orderTypeValidation = fan_B2BCartCtrl.updateOrderType(cart);

        Assert.areEqual(null, orderTypeValidation.orderType, 'The fan_TipoPedido__c is not as expected.');
    }

    @IsTest
    static void updateCodigoVIN() {

        String testWebCartId = [SELECT Id FROM WebCart LIMIT 1].Id;

        String newCodigoVIN = '15391915391915391';

        // Set new codigo VIN.
        fan_B2BCartCtrl.updateCodigoVIN(testWebCartId, newCodigoVIN);

        String updatedCodigoVIN  = [SELECT fan_CodigoVIN__c FROM WebCart LIMIT 1].fan_CodigoVIN__c;

        System.assertEquals(newCodigoVIN, updatedCodigoVIN, 'The fan_CodigoVIN__c of the WebCart is invalid');
    }

    // If the cartId or codigoVIN argument is invalid, an exception will be thrown.
    @IsTest
    static void updateCodigoVINWithInvalidArgument() {

        String testWebCartId = [SELECT Id FROM WebCart LIMIT 1].Id;

        // Invalid length.
        String newCodigoVIN = '5a55n55a5555A5555555555555555';

        try {
            fan_B2BCartCtrl.updateCodigoVIN(testWebCartId, newCodigoVIN);
            Assert.fail('An AuraHandledException was expected.');
        } catch (Exception e) {
            Assert.isInstanceOfType(e, AuraHandledException.class, 'The type of the exception is not as expected.');
        }
    }

    @IsTest
    static void updateOrderTypeWithoutWebCart() {
        try {
            fan_B2BCartCtrl.updateOrderType(null);
            Assert.fail('An exception was expected.');
        } catch (Exception e) {
            Assert.isInstanceOfType(e, AuraHandledException.class, 'An Aura handled exception is not as expected.');
        }
    }

    @IsTest
    static void updatePaymentCondition() {

        WebCart testWebCart = [SELECT Id FROM WebCart LIMIT 1];
        // Set contado as the default payment condition.
        testWebCart.fan_FormaPago__c = 'contado';

        // Set new payment condition.
        fan_B2BCartCtrl.updatePaymentCondition(testWebCart.Id, 'credito');

        String newPaymentCondition = [SELECT fan_FormaPago__c FROM WebCart WHERE Id =: testWebCart.Id].fan_FormaPago__c;

        System.assertEquals('credito', newPaymentCondition, 'paymentCondition is invalid');
    }

    // If the cartId argument is invalid, an exception will be thrown.
    @IsTest
    static void updatePaymentConditionWithInvalidArgument() {
        try {
            fan_B2BCartCtrl.updatePaymentCondition('', 'credito');
        } catch (Exception e) {
            System.assert(e instanceof AuraHandledException, 'cartId is valid and must not be invalid.');
        }
    }

    @IsTest
    static void updateCartItemPrices() {

        String communityId = '';
        String accountId = [SELECT Id FROM WebCart LIMIT 1].Id;
        WebCart cart = [SELECT WebStoreId FROM WebCart LIMIT 1];
        CartItem cartItem = [SELECT Quantity, Product2Id FROM CartItem WHERE CartId =: cart.Id LIMIT 1];
        PricebookEntry[] pricebookEntry = [SELECT UnitPrice, Product2Id FROM PricebookEntry WHERE Pricebook2.Name IN :(new String[]{ 'Motos', 'Descuentos Credito' }) AND Product2Id = :CartItem.Product2Id ORDER BY Pricebook2.Name ASC];
        Decimal unitPrice = pricebookEntry[0].UnitPrice;
        Decimal listPrice = pricebookEntry[1].UnitPrice;

        fan_B2BUtils.testWebStoreId = cart.WebStoreId;

        Map<String, CartItem> updatedCartItems = fan_B2BCartCtrl.updateCartItemPrices(cart.Id);
        CartItem updatedCartItem = updatedCartItems.get(updatedCartItems.keySet().iterator().next());

        System.assertEquals(unitPrice, updatedCartItem.UnitAdjustedPrice, 'The UnitAdjustedPrice of the CartItem is not as expected.');
        System.assertEquals(listPrice, updatedCartItem.ListPrice, 'The ListPrice of the CartItem is not as expected.');
        System.assertEquals(unitPrice * cartItem.Quantity, updatedCartItem.TotalPrice, 'The TotalPrice of the CartItem is not as expected.');
        System.assertEquals(listPrice * cartItem.Quantity, updatedCartItem.TotalListPrice, 'The TotalListPrice of the CartItem is not as expected.');
    }

    @IsTest 
    static void deleteCartCheckoutSessionTest() {
        String testWebCartId = [SELECT Id FROM WebCart LIMIT 1].Id;

        fan_B2BCartCtrl.deleteCartCheckoutSession(testWebCartId);
    }

    @IsTest
    static void getCartDeliveryGroups() {

        String webCartId = [SELECT Id FROM WebCart LIMIT 1].Id;

        List<CartDeliveryGroup> cartDeliveryGroups = fan_B2BCartCtrl.getCartDeliveryGroups(webCartId);

        System.assert(!cartDeliveryGroups.isEmpty(), 'CartDeliveryGroups list is empty.');
        System.assertEquals('Test CartGroup', cartDeliveryGroups[0].Name, 'The CartDeliveryGroup name is not as expected.');
    }

    // If the orderSummaryOrCartId argument does not belong to an OrderSummary or a WebCart, an exception will be thrown.
    @IsTest
    static void getCartDeliveryGroupsWithInvalidArgument() {

        String accountId = [SELECT Id FROM Account LIMIT 1].Id;

        try {
            fan_B2BCartCtrl.getCartDeliveryGroups(accountId);
        } catch (Exception e) {
            System.assert(e instanceof AuraHandledException, 'The expection is not an AuraHandledException instance.');
        }
    }

    @IsTest
    static void getCartTotals() {
        Id cartId = [SELECT Id FROM WebCart].Id;

        fan_CartSummaryCalculator.CartSummary cartSummary = fan_B2BCartCtrl.getCartTotals(cartId);

        Assert.areEqual(118.5, cartSummary.grossValue, 'The grossValue of the cartSummary is not as expected.');
        Assert.areEqual(21.5, cartSummary.discounts, 'The discounts of the cartSummary is not as expected.');
        Assert.areEqual(97, cartSummary.subtotal, 'The subtotal of the cartSummary is not as expected.');
        Assert.areEqual(0, cartSummary.IVA, 'The IVA of the cartSummary is not as expected.');
        Assert.areEqual(97, cartSummary.totalToPay, 'The totalToPay of the cartSummary is not as expected.');
    }

    @IsTest
    static void getCartTotalsShouldThrowAnException() {
        try {
            fan_B2BCartCtrl.getCartTotals(null);
            Assert.fail('An AuraHandledException was expected.');
        } catch (Exception e) {
            Assert.isInstanceOfType(e, AuraHandledException.class, 'The exception is not as expected.');
        }
    }

    @IsTest
    static void updateMetodoPago() {

        String testWebCartId = [SELECT Id FROM WebCart LIMIT 1].Id;

        fan_B2BCartCtrl.updateMetodoPago(testWebCartId, 'Tarjeta');

        String metodoPago  = [SELECT fan_MetodoPago__c FROM WebCart LIMIT 1].fan_MetodoPago__c;

        System.assertEquals('Tarjeta', metodoPago, 'The fan_MetodoPago__c is not as expected.');
    }

    @IsTest
    static void updateMetodoPagoWithInvalidArgument() {

        String testWebCartId = [SELECT Id FROM WebCart LIMIT 1].Id;

        try {
            fan_B2BCartCtrl.updateMetodoPago(testWebCartId, 'Something');
            System.assert(false, 'An exception was expected.');
        } catch (Exception e) {
            // The fan_MetodoPago__c supplied was invalid.
            System.assert(e instanceOf AuraHandledException, 'The exception is not AuraHandledException.');
        }
    }

    @IsTest
    static void setAnticipoTest() {
        // Obtener datos de prueba
        WebCart cart = [SELECT Id FROM WebCart LIMIT 1];

        Test.startTest();
        // Llamar al método setAnticipo
        fan_B2BCartCtrl.setAnticipo(true, cart.Id);

        // Obtener el carrito actualizado desde la base de datos
        WebCart cartActualizado = [SELECT Id, fan_EsAnticipo__c FROM WebCart WHERE Id = :cart.Id LIMIT 1];

        // Verificar que el valor de fan_EsAnticipo__c se haya actualizado correctamente
        System.assertEquals(true, cartActualizado.fan_EsAnticipo__c, 'El valor de fan_EsAnticipo__c no se actualizó correctamente');

        // Intentar desactivar el anticipo
        fan_B2BCartCtrl.setAnticipo(false, cart.Id);

        // Obtener el carrito actualizado desde la base de datos
        cartActualizado = [SELECT Id, fan_EsAnticipo__c FROM WebCart WHERE Id = :cart.Id LIMIT 1];

        // Verificar que el valor de fan_EsAnticipo__c se haya actualizado correctamente al desactivar el anticipo
        System.assertEquals(false, cartActualizado.fan_EsAnticipo__c, 'El valor de fan_EsAnticipo__c no se desactivó correctamente');
        Test.stopTest();
    }
}