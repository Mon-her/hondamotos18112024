public class fan_CartBillingAddressController {

    @AuraEnabled
    public static List<CartDeliveryGroup> getCartDeliveryGroupByCartId(String cartId){
        return [SELECT Name FROM CartDeliveryGroup WHERE CartId =: cartId];
    }
}