public with sharing class fan_CheckoutSetDeliveryMethod {
    
    @InvocableMethod(label='Set Delivery Methods')
    public static void setDeliveryMethods(List<String> Data){
        String cartId = Data[0];
        CartDeliveryGroupMethod cartDeliveryMethod = [SELECT Id, DeliveryMethodId, ShippingFee, CartDeliveryGroupId FROM CartDeliveryGroupMethod WHERE WebCartId = :cartId LIMIT 1];
        System.debug('cartDeliveryMethod to set >>> '+cartDeliveryMethod);
        // Get cartDeliveryGroups of actual cart
        List<CartDeliveryGroup> cdgList = [SELECT Id, CartId, DeliveryMethodId FROM CartDeliveryGroup WHERE CartId = :cartId];
        System.debug('setDeliveryMethods Cart Delivery Groups List >>> '+cdgList);
        for (CartDeliveryGroup cdg : cdgList) {
            // If cartDeliveryGroup doenst have a delivery method, set the default
            if (cdg.DeliveryMethodId != cartDeliveryMethod.DeliveryMethodId) { 
                cdg.DeliveryMethodId = cartDeliveryMethod.DeliveryMethodId; 
            } 
        }
        UPDATE cdgList;
    }
}