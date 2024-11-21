public with sharing class fan_B2BProductCtrl {
    
    // For unit test
    public static ConnectApi.ProductDetail testProductDetail;
    public static ConnectApi.ProductPrice testProductPrice;
    public static ConnectApi.ProductOverviewCollection testProductCollection;
    @TestVisible
    static Boolean throwExeption = false;

    @AuraEnabled(cacheable=true)
    public static ConnectApi.ProductDetail getProduct(
        String communityId,
        String productId,
        String effectiveAccountId
    ) {
        // Lookup the webstore ID associated with the community
        String webstoreId = Test.isRunningTest() ? null : fan_B2BUtils.resolveCommunityIdToWebstoreId(communityId);

        // https://developer.salesforce.com/docs/atlas.en-us.apexcode.meta/apexcode/apex_ConnectAPI_CommerceCatalog_static_methods.htm#apex_ConnectAPI_CommerceCatalog_static_methods
        ConnectApi.ProductDetail productToReturn = Test.isRunningTest() ? testProductDetail : ConnectApi.CommerceCatalog.getProduct(webstoreId, productId, effectiveAccountID, null, false, null, false, true, false);

        System.debug(LoggingLevel.DEBUG, 'getProduct .. productToReturn >>> '+productToReturn);
        return productToReturn; 
    }

    @AuraEnabled
    public static ConnectApi.ProductOverviewCollection getProducts(
          String communityId,
          String effectiveAccountId, 
          List<String> lstSKU,
          List<String> lstFields
      ) {
          // Lookup the webstore ID associated with the community
          String webstoreId = Test.isRunningTest() ? null : fan_B2BUtils.resolveCommunityIdToWebstoreId(communityId);
          
          // https://developer.salesforce.com/docs/atlas.en-us.apexref.meta/apexref/apex_ConnectAPI_CommerceCatalog_static_methods.htm#apex_ConnectAPI_CommerceCatalog_getProducts_1
          return Test.isRunningTest() ? testProductCollection : ConnectApi.CommerceCatalog.getProducts(webstoreId, effectiveAccountID, null, lstSKU, lstFields, false, false
          );
    }

    @AuraEnabled
    public static ConnectApi.ProductPrice getProductPrice(
        String communityId,
        String productId,
        String effectiveAccountId
    ) {
        // Lookup the webstore ID associated with the community
        String webstoreId = Test.isRunningTest() ? null : fan_B2BUtils.resolveCommunityIdToWebstoreId(communityId);

        // https://developer.salesforce.com/docs/atlas.en-us.apexcode.meta/apexcode/apex_ConnectAPI_CommerceStorePricing_static_methods.htm#apex_ConnectAPI_CommerceStorePricing_static_methods
        ConnectApi.ProductPrice priceToReturn = Test.isRunningTest() ? testProductPrice : ConnectApi.CommerceStorePricing.getProductPrice(webstoreId, productId, effectiveAccountId);

        System.debug(LoggingLevel.DEBUG, 'getProductPrice .. priceToReturn >>> '+priceToReturn);
        return priceToReturn;
    }

    @AuraEnabled(cacheable=true)
    public static ConnectApi.ProductDetail getProductVariations(
        string communityId,
        string productId,
        string effectiveAccountId
    ) {
        // Lookup the webstore ID associated with the community
        String webstoreId = Test.isRunningTest() ? null : fan_B2BUtils.resolveCommunityIdToWebstoreId(communityId);

        // https://developer.salesforce.com/docs/atlas.en-us.apexref.meta/apexref/apex_ConnectAPI_CommerceCatalog_static_methods.htm#apex_ConnectAPI_CommerceCatalog_getProduct_3
        return Test.isRunningTest() ? testProductDetail : ConnectApi.Commercecatalog.getProduct(webstoreId, productId, effectiveAccountId, null, false, null, false, false, false);
    }

    @AuraEnabled(cacheable=true)
    public static WebStore getWebStoreInformation(String communityId){
        String webstoreId = fan_B2BUtils.resolveCommunityIdToWebstoreId(communityId);

        return [SELECT fan_LocationGroup__r.ExternalReference, fan_HasLimitedQuantityProduct__c
                FROM WebStore WHERE Id = :webstoreId];
    }

    @AuraEnabled(cacheable=true)
    public static Map<String, fan_ProductCategoryAvailability__mdt> getAvailabilityMapped(){
        Map<String, fan_ProductCategoryAvailability__mdt> mapProductCategory = new Map<String, fan_ProductCategoryAvailability__mdt>();
        
        List<fan_ProductCategoryAvailability__mdt> lstProcess = [SELECT Id, MasterLabel, DeveloperName,
                                                                 CantidadDisponible__c, CantidadLimitada__c 
                                                                 FROM fan_ProductCategoryAvailability__mdt];
        
        for(fan_ProductCategoryAvailability__mdt mdt : lstProcess){
            mapProductCategory.put(mdt.MasterLabel, mdt);
        }
        
        return mapProductCategory;
        
    }

    @AuraEnabled
    public static List<ProductAttribute> getProductAttributes(String variationParentId) {
        try {
            if(throwExeption) throw new AuraHandledException('');

            return [SELECT fan_Color__c, Product.fan_swatch__c FROM ProductAttribute WHERE VariantParentId =: variationParentId];
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }
}