/**********************************************************************************
Desarrollado por:   Viseo
Autor:              Simón Way Esalas Young
Descripción:        Clase para obtener información relacionada a inventario.
Cambios (Versiones)
---------------------------------------------------------------------------------
No.     Fecha       Autor                                   Descripción
---------------------------------------------------------------------------------
1.0     01-08-2022  Simón Way Esalas Young                  Creación de la clase
***********************************************************************************/
public without sharing class fan_OCIGetAvailability extends fan_OCIGetAvailabilityAbstract {

    @AuraEnabled
    public static fan_OCIGetAvailabilityUtils.StockKeepingUnitsResultWithRelatedProduct getAvailabilityOfRelatedProducts(String locationGroup, String searchTerm, List<String> locations){
        Map<String, Product2> products = getProductInformation(searchTerm, locationGroup);
        Map<String, LocationGroupAssignment> locationAssignments = getLocationGroupAssignments(locationGroup);

        String[] skus = new List<String>(products.keySet());
        Map<String, Integer> skuWithRelatedProductsCount = getCountRelatedProduct(skus);
        fan_OCIGetAvailabilityUtils.StockKeepingUnitsResult stockKeepingUnitsResult = getAvaliavility(locationGroup, skus, products, locationAssignments, locations);

        return new fan_OCIGetAvailabilityUtils.StockKeepingUnitsResultWithRelatedProduct(stockKeepingUnitsResult, skuWithRelatedProductsCount);
    }

    @AuraEnabled
    public static fan_OCIGetAvailabilityUtils.StockKeepingUnitsLocation[] getAvailabilityForRedInventory(String locationGroup, String searchTerm){

        searchTerm = '%' + searchTerm.trim() + '%';
        Map<String, Product2> products = new Map<String, Product2>();
        Map<String, LocationGroupAssignment> locationAssignments = getLocationGroupAssignments(locationGroup);

        // 150 is to not exceed the limit of DML statements in getInventoryAvailability.
        for(ProductCategoryProduct productCategoryProduct : [SELECT Product.StockKeepingUnit, Product.Name, Product.Referencia__c, Product.Linea_usado__c, Product.fan_BaseColor__c, Product.fan_YearModel__c
                                                                FROM ProductCategoryProduct WHERE Product.StockKeepingUnit != null
                                                                AND (Product.StockKeepingUnit LIKE :searchTerm OR Product.Referencia__c LIKE :searchTerm OR Product.Name LIKE :searchTerm) LIMIT 150]) {
            products.put(productCategoryProduct.Product.StockKeepingUnit, productCategoryProduct.Product);
        }
        return getAvailavility(locationGroup, products, locationAssignments);
    }

    @AuraEnabled
    public static fan_OCIGetAvailabilityUtils.StockKeepingUnitsResult getRelatedProductsWithAvailability(String locationGroup, String sku){
        Map<String, Product2> products = getRelatedProduct(sku);
        return getRelatedProductsAvailability(locationGroup, products);
    }

    @AuraEnabled
    public static String getMotosAvailability(Map<String, String[]> skusByCity){
        Map<String, Map<String, fan_InventoryHandler.Product>> availability = new fan_InventoryHandler().getAvailability(skusByCity);
        return JSON.serialize(availability);
    }

    @AuraEnabled
    public static Map<String, fan_InventoryHandler.Product> getPosventaAvailability(String communityId, String[] skus) {
        String webstoreId = fan_B2BUtils.resolveCommunityIdToWebstoreId(communityId);
        String locationGroup = [SELECT fan_LocationGroup__r.ExternalReference FROM WebStore WHERE Id = :webstoreId].fan_LocationGroup__r.ExternalReference;

        return new fan_InventoryHandler().getAvailability(locationGroup, skus);
    }

    @AuraEnabled
    public static Map<String, String[]> getLocationByCity(String accountId){

        String[] cities = new List<String>();
        Map<String, String[]> cityLocations = new Map<String, String[]>();
        // Get cities
        for (ContactPointAddress contactPointAddress : [SELECT City FROM ContactPointAddress WHERE ParentId =: accountId AND AddressType = 'Shipping']) {
            cities.add(contactPointAddress.City);
        }
        // Group locations by City.
        for (fan_CityLocation__c cityLocation : [SELECT fan_Ciudad__c, fan_Location__r.ExternalReference FROM fan_CityLocation__c
                                                    WHERE fan_Ciudad__c IN :cities WITH SECURITY_ENFORCED]) {
            if(cityLocations.containsKey(cityLocation.fan_Ciudad__c)) {
                cityLocations.get(cityLocation.fan_Ciudad__c).add(cityLocation.fan_Location__r.ExternalReference);
            } else {
                cityLocations.put(cityLocation.fan_Ciudad__c, new String[]{ cityLocation.fan_Location__r.ExternalReference });
            }
        }
        return cityLocations;
    }
}