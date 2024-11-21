public with sharing class fan_CheckoutSummaryCtrl {

    // For unit tests.
    @TestVisible
    static OrderSummary testOrderSummary;

    /** @param recordId The Id of the OrderSummary or WebCart */
    @AuraEnabled
    public static Map<String, Decimal> getCheckoutSummary(String recordId){
        try {
            Map<String, Decimal> checkoutSummary;
            SObjectType sObjectType = Id.valueOf(recordId).getSObjectType();

            if(sObjectType == WebCart.getSObjectType()) {
                checkoutSummary = getWebCartTotals(recordId);
            } else if(sObjectType == OrderSummary.getSObjectType()) {
                checkoutSummary = getOrderSummaryTotals(recordId);
            }
            return checkoutSummary;
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }

    @TestVisible
    static Map<String, Decimal> getWebCartTotals(String cartId) {
        WebCart cart = [SELECT fan_totalOrdered__c, TotalChargeAmount, TotalTaxAmount
                        FROM WebCart WHERE Id =: cartId WITH SECURITY_ENFORCED];

        return new Map<String, Decimal> {
            'subtotal' => cart.fan_totalOrdered__c,
            'freight' => cart.TotalChargeAmount,
            'estimatedTaxes' => cart.TotalTaxAmount,
            'total' => cart.fan_totalOrdered__c + cart.TotalChargeAmount + cart.TotalTaxAmount
        };
    }

    @TestVisible
    static Map<String, Decimal> getOrderSummaryTotals(String orderSummaryId) {
        OrderSummary orderSummary = Test.isRunningTest() ? testOrderSummary : [SELECT TotalAdjustedProductAmount, TotalAdjDistAmount, TotalAdjustedDeliveryAmount, TotalTaxAmount, GrandTotalAmount FROM OrderSummary WHERE Id =: orderSummaryId WITH SECURITY_ENFORCED];

        return new Map<String, Decimal> {
            'subtotal' => orderSummary.TotalAdjustedProductAmount + orderSummary.TotalAdjDistAmount,
            'freight' => orderSummary.TotalAdjustedDeliveryAmount,
            'estimatedTaxes' => orderSummary.TotalTaxAmount,
            'total' => orderSummary.GrandTotalAmount
        };
    }
    @AuraEnabled
	public static Boolean isCartAnticipo(String cartId){
		    //Avoid getting null if the cartId is an OrderSummaryId
            cartId = fan_B2BCartCtrlUtils.getCartId(cartId) != null ? fan_B2BCartCtrlUtils.getCartId(cartId) : cartId;
            
			Boolean isAnticipo = [SELECT fan_EsAnticipo__c FROM WebCart WHERE Id=: cartId][0].fan_EsAnticipo__c;
			return isAnticipo;
	}
}