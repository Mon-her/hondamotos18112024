public with sharing class fan_B2BStorePricingCtrl {

    @TestVisible
    static ConnectApi.PricingResult testPricingResult;

    @AuraEnabled
    public static ConnectApi.PricingResult getProductPrices(String communityId, String effectiveAccountId, String[] productIds){
        try {
            String webstoreId = fan_B2BUtils.resolveCommunityIdToWebstoreId(communityId);

            ConnectApi.PricingLineItemInput[] pricingLineItemInputs = new List<ConnectApi.PricingLineItemInput>();
            for (String productId : productIds) {
                ConnectApi.PricingLineItemInput pricingLineItemInput = new ConnectApi.PricingLineItemInput();
                pricingLineItemInput.productId = productId;
                pricingLineItemInputs.add(pricingLineItemInput);
            }
            ConnectApi.PricingInput pricingInput = new ConnectApi.PricingInput();
            pricingInput.pricingLineItems = pricingLineItemInputs;

            return productIds.isEmpty() || Test.isRunningTest() ? testPricingResult : ConnectApi.CommerceStorePricing.getProductPrices(webstoreId, effectiveAccountId, pricingInput);
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }
}