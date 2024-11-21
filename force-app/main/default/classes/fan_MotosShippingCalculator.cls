public with sharing class fan_MotosShippingCalculator extends fan_ShippingCalculator {

    // Get shipping options by delivery group to get the shipping cost for every delivery group.
    public override Map<String, Decimal> calculateShipping(String accountId, String webStoreId, Set<String> productIds, Product[] products) {

        Set<String> buyerGroupIds = getBuyerGroupIds(accountId, webStoreId);
        // Stores parent product id with the shipping cost.
        Map<String, Decimal> shippingCostByParentId = new Map<String, Decimal>();
        // Stores cart delivery group id with the shipping cost.
        Map<String, Decimal> deliveryGroupShippingCost = new Map<String, Decimal> ();
        // Stores the product variant id with parent id
        Map<String,String> productParent = new Map<String,String>();

        for (ProductAttribute prodAttr : [SELECT ProductId, VariantParentId FROM ProductAttribute WHERE ProductId IN :productIds]) {
            productParent.put(prodAttr.ProductId, prodAttr.VariantParentId);
        }

        fan_ProductoFlete__c[] shippingsProducts = [SELECT fan_Producto__c, fan_FleteProducto__r.fan_ValorFlete__c FROM fan_ProductoFlete__c 
                                                    WHERE fan_FleteProducto__r.fan_BuyerGroup__c IN :buyerGroupIds
                                                    AND fan_Producto__c IN :productParent.values()];
        System.debug(LoggingLevel.DEBUG, 'fan_ProductoFlete__c result list >>> '+shippingsProducts);
        // Iterate over fan_ProductoFlete__c result to map the product with his shipping logic.
        for (fan_ProductoFlete__c shipping : shippingsProducts){
            shippingCostByParentId.put(shipping.fan_Producto__c, shipping.fan_FleteProducto__r.fan_ValorFlete__c);
        }

        for (Product product : products) {
            String deliveryGroupId = product.deliveryGroupId;
            String parentId = productParent.get(product.id);
            Decimal shippingCost = shippingCostByParentId.get(parentId);

            // If current product has a shipping cost add it to deliveryGroupShippingCost.
            if (shippingCost > 0) {

                Decimal totalShippingCost = deliveryGroupShippingCost.containsKey(deliveryGroupId) ? deliveryGroupShippingCost.get(deliveryGroupId) : 0;
                totalShippingCost += shippingCost * product.quantity;

                deliveryGroupShippingCost.put(deliveryGroupId, totalShippingCost);
            }  
        }
        return deliveryGroupShippingCost;
    }
}