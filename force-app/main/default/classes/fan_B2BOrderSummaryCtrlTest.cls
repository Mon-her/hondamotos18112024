@IsTest
class fan_B2BOrderSummaryCtrlTest {

    @TestSetup
    static void makeData(){
        String pricebookId = Test.getStandardPricebookId();

        Account account = fan_B2BTestDataFactory.createAccount('5311581', 'NIT');
        WebStore webStore = fan_B2BTestDataFactory.createWebStore('Test WebStore');
        WebCart webCart = fan_B2BTestDataFactory.createWebCart(webStore.Id, account.Id, 'contado');
        Order order = fan_B2BTestDataFactory.createOrder(account.Id, pricebookId);

        fan_B2BTestDataFactory.createCartCheckoutSession(order.Id, webCart.Id);
    }

    @IsTest
    static void getOrderInformation() {

        String cartId = [SELECT Id FROM WebCart].Id;
        String orderSummaryStatus = 'Waiting for payment';

        fan_B2BOrderSummaryCtrl.testOriginalOrderId = [SELECT Id FROM Order].Id;
        fan_B2BOrderSummaryCtrl.testOrderSummaries = new OrderSummary[]{ new OrderSummary(Status = orderSummaryStatus) };
        Map<String, String> orderInformation = fan_B2BOrderSummaryCtrl.getOrderInformation('');

        Assert.areEqual(cartId, orderInformation.get('cartId'), 'The Id of the WebCart is not as expected.');
        Assert.areEqual(orderSummaryStatus, orderInformation.get('orderSummaryStatus'), 'The status of the OrderSummary is not as expected.');
    }

    @IsTest
    static void getExpirationDateForPayment(){
        fan_B2BOrderSummaryCtrl.testPayments = new Payment[]{
            new Payment(Date = Datetime.newInstance(2023, 3, 16, 5, 51, 0))
        };
        String paymentExpirationDate = fan_B2BOrderSummaryCtrl.getPaymentExpirationDate('');

        Assert.areEqual(paymentExpirationDate, '19/03/2023;05:51 AM', 'The expiration date of the payment is not as expected.');
    }
}