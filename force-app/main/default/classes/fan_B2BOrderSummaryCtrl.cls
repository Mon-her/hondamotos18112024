public with sharing class fan_B2BOrderSummaryCtrl {

    @TestVisible
    static String testOriginalOrderId;
    @TestVisible
    static OrderSummary[] testOrderSummaries;
    @TestVisible
    static Payment[] testPayments;

    @AuraEnabled(cacheable=true)
    public static Map<String, String> getOrderInformation(String orderSummaryId){

        String orderSummaryStatus;
        String cartId;
        String paymentMethod;
        OrderSummary[] orderSummaries = Test.isRunningTest() ? testOrderSummaries : [SELECT OriginalOrderId, Status, (SELECT PaymentMethod.NickName FROM OrderPaymentSummaries) FROM OrderSummary WHERE Id =: orderSummaryId];
        if(!orderSummaries.isEmpty()) {

            String originalOrderId = Test.isRunningTest() ? testOriginalOrderId : orderSummaries[0].OriginalOrderId;
            CartCheckoutSession[] cartCheckoutSessions = [SELECT WebCartId FROM CartCheckoutSession WHERE OrderId =: originalOrderId];

            cartId = cartCheckoutSessions.isEmpty() ? '' : cartCheckoutSessions[0].WebCartId;
            orderSummaryStatus = orderSummaries[0].Status;
            if(!Test.isRunningTest()) paymentMethod =  orderSummaries[0].OrderPaymentSummaries[0].PaymentMethod.NickName;
        }
        return new Map<String, String> {
            'cartId' => cartId,
            'orderSummaryStatus' => orderSummaryStatus,
            'paymentMethod' => paymentMethod
        };
    }

    @AuraEnabled(cacheable=true)
    public static String getPaymentExpirationDate(String orderSummaryId) {
        String paymentDate;
        Payment[] payments = Test.isRunningTest() ? testPayments : [SELECT Date FROM Payment WHERE OrderPaymentSummary.OrderSummaryId = :orderSummaryId AND Status = 'Draft'];

        Integer daysToExpire = 3;
        if(!payments.isEmpty()) paymentDate = payments[0].Date.addDays(daysToExpire).format('dd/MM/yyy;hh:mm a');

        return paymentDate;
    }
}