@IsTest
class fan_CartToOrderTest {

    @TestSetup
    static void makeData(){
        Account account = fan_B2BTestDataFactory.createAccount('5311581', 'NIT');
        WebStore webStore = fan_B2BTestDataFactory.createWebStore('WebStore');
        WebCart cart = fan_B2BTestDataFactory.createWebCart(webStore.Id, account.Id, 'contado');

        Product2 product = fan_B2BTestDataFactory.createProduct('SKU-1', account.Id, null);

        CartDeliveryGroup cartDeliveryGroup = fan_B2BTestDataFactory.createCartDeliveryGroup('CartDeliveryGroup', cart.Id);

        CartItem cartItem = fan_B2BTestDataFactory.buildCartItem(product, fan_Constants.CartItemType.PRODUCT.name(), 5, 79.99, cart.Id, cartDeliveryGroup.Id);
        cartItem.fan_QuantityOrdered__c = 5;
        INSERT cartItem;

        fan_B2BTestDataFactory.createCartTax(cartItem.Id, 72.190975, 19);

        fan_B2BTestDataFactory.createCartCheckoutSession(null, cart.Id);
    }

    @IsTest
    static void cartToOrder() {
        CartCheckoutSession cartCheckoutSession = [SELECT WebCartId FROM CartCheckoutSession];

        fan_CartToOrder.CartToOrderRequest request = new fan_CartToOrder.CartToOrderRequest();
        request.cartId = cartCheckoutSession.WebCartId;
        request.checkoutSessionId = cartCheckoutSession.Id;

        fan_CartToOrder.cartToOrder(new fan_CartToOrder.CartToOrderRequest[]{ request });
    }
}