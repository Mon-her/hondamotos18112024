/**
 * @description       : 
 * @author            : ChangeMeIn@UserSettingsUnder.SFDoc
 * @group             : 
 * @last modified on  : 08-19-2024
 * @last modified by  : ChangeMeIn@UserSettingsUnder.SFDoc
**/
public without sharing class SelectorLocalProductItem {
    
    public static Map<String, List<ProductItem>> getProductItemsByProductId(Set<Id> productIds, Integer queryLimits) {
        Map<String, List<ProductItem>> productItemsMap = new Map<String, List<ProductItem>>();
        List<Product2> productWithProductItems = [SELECT Id, Name, Codigo_de_producto__c, 
                                                    (
                                                        SELECT 
                                                            Id, LocationId, Location.Name, Location.codigoBodega__c, QuantityOnHand, QuantityUnitOfMeasure, SerialNumber, Product2.Codigo_de_producto__c 
                                                        FROM
                                                            ProductItems
                                                    )
                                                    FROM
                                                        Product2
                                                    WHERE
                                                        Id IN :productIds WITH SECURITY_ENFORCED LIMIT :queryLimits];

        // Storage product code and inventory 
        for(Product2 prod : productWithProductItems) {
            productItemsMap.put(prod.Codigo_de_producto__c, prod.ProductItems);
        }

        return productItemsMap;
    }

}