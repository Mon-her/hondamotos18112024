public abstract class fan_OCIGetAvailabilityAbstract {

    @TestVisible
    static ConnectApi.OCIGetInventoryAvailabilityOutputRepresentation testOutputRepresentation;

    public static fan_OCIGetAvailabilityUtils.StockKeepingUnitsResult getAvaliavility(String locationGroup, String[] skus, Map<String, Product2> mapProduct, Map<String, LocationGroupAssignment> mapLocationAssignment, String[] locations){ 

        ConnectApi.OCIGetInventoryAvailabilityInputRepresentation inventoryAvailabilityInputRepresentation = 
            new ConnectApi.OCIGetInventoryAvailabilityInputRepresentation();
        fan_OCIGetAvailabilityUtils.StockKeepingUnitsResult result = new fan_OCIGetAvailabilityUtils.StockKeepingUnitsResult();
        
        if(locationGroup == 'B2B_Motos'){
            for (String singleLocation : locations) {
                inventoryAvailabilityInputRepresentation.locationIdentifiers = new String[]{singleLocation};
                getInventoryAvailability(result, inventoryAvailabilityInputRepresentation, locationGroup, skus, mapProduct, mapLocationAssignment);
            }
        } else if(locationGroup == 'B2B_Posventa') {
            inventoryAvailabilityInputRepresentation.locationGroupIdentifiers = new String[]{locationGroup};
            getInventoryAvailability(result, inventoryAvailabilityInputRepresentation, locationGroup, skus, mapProduct, mapLocationAssignment);
        }
        
        return result;
    }

    public static fan_OCIGetAvailabilityUtils.StockKeepingUnitsLocation[] getAvailavility(String locationGroup, Map<String, Product2> products, Map<String, LocationGroupAssignment> locationAssignments){ 

        fan_OCIGetAvailabilityUtils.StockKeepingUnitsLocation[] availability = new fan_OCIGetAvailabilityUtils.StockKeepingUnitsLocation[]{};
        ConnectApi.OCIGetInventoryAvailabilityInputRepresentation inventoryAvailabilityInputRepresentation =  new ConnectApi.OCIGetInventoryAvailabilityInputRepresentation();
        inventoryAvailabilityInputRepresentation.locationGroupIdentifier = locationGroup;
        System.debug(LoggingLevel.DEBUG, 'fan_OCIGetAvailabilityAbstract Data to sent getInventoryAvailability >>> ' + inventoryAvailabilityInputRepresentation);

        for (String sku : products.keySet()) {
            inventoryAvailabilityInputRepresentation.stockKeepingUnit = sku;
            ConnectApi.OCIGetInventoryAvailabilityOutputRepresentation output = Test.isRunningTest() ? testOutputRepresentation : ConnectApi.OmnichannelInventoryService.getInventoryAvailability(inventoryAvailabilityInputRepresentation);
            System.debug(LoggingLevel.DEBUG, 'fan_OCIGetAvailabilityAbstract Locations >>> ' + output.locations);

            for(ConnectApi.OCILocationAvailabilityOutputRepresentation location : output.locations){
                for(ConnectApi.OCIInventoryRecordOutputRepresentation inventoryRecord : location.inventoryRecords ){
                    availability.add(buildSKUAvailability(locationGroup, inventoryRecord, location.locationIdentifier, products, locationAssignments));
                }
            }
        }
        return availability;
    }

    public static void getInventoryAvailability(fan_OCIGetAvailabilityUtils.StockKeepingUnitsResult result, ConnectApi.OCIGetInventoryAvailabilityInputRepresentation inventoryAvailabilityInputRepresentation, String locationGroup, String[] skus, Map<String, Product2> mapProduct, Map<String, LocationGroupAssignment> mapLocationAssignment){
        String[] requestSkus = new List<String>();
        for (Integer i = 0; i < skus.size(); i++) {
            requestSkus.add(skus[i]);
            // If is the last item or if the array already has the 100 items, execute the availability method
            if(requestSkus.size() == 100 || skus.size() == (i + 1)) {
                inventoryAvailabilityInputRepresentation.stockKeepingUnits = requestSkus;

                System.debug(LoggingLevel.DEBUG, 'fan_OCIGetAvailabilityAbstract Data to sent getInventoryAvailability >>> '+inventoryAvailabilityInputRepresentation);
                ConnectApi.OCIGetInventoryAvailabilityOutputRepresentation output =  Test.isRunningTest() ? testOutputRepresentation : ConnectApi.OmnichannelInventoryService.getInventoryAvailability(inventoryAvailabilityInputRepresentation);

                System.debug(LoggingLevel.DEBUG, 'fan_OCIGetAvailabilityAbstract Locations (lstLocation) >>> '+output.locations);
                System.debug(LoggingLevel.DEBUG, 'fan_OCIGetAvailabilityAbstract Locations Groups (lstLocationGroup) >>> '+output.locationGroups);
                for(ConnectApi.OCILocationGroupAvailabilityOutputRepresentation locGroup : output.locationGroups){
                    for(ConnectApi.OCIInventoryRecordOutputRepresentation inventory :  locGroup.inventoryRecords){
                        result.lstLocationGroup.add(buildSKUAvailability(locationGroup, inventory, locGroup.locationGroupIdentifier, mapProduct, mapLocationAssignment));
                    }
                }

                for(ConnectApi.OCILocationAvailabilityOutputRepresentation location : output.locations){
                    for(ConnectApi.OCIInventoryRecordOutputRepresentation inventory : location.inventoryRecords ){
                        result.lstLocation.add(buildSKUAvailability(locationGroup, inventory, location.locationIdentifier, mapProduct, mapLocationAssignment));
                    }
                }
                requestSkus.clear();
            }
        }
    }

    public static fan_OCIGetAvailabilityUtils.StockKeepingUnitsLocation buildSKUAvailability(String locationGroup, ConnectApi.OCIInventoryRecordOutputRepresentation inventory, String locationId, Map<String, Product2> products, Map<String, LocationGroupAssignment> mapLocationAssignment){

        LocationGroupAssignment locationGroupAssignment = mapLocationAssignment.get(locationId);
        Product2 product = products.get(inventory.stockKeepingUnit);

        fan_OCIGetAvailabilityUtils.StockKeepingUnitsLocation sku = new fan_OCIGetAvailabilityUtils.StockKeepingUnitsLocation();
        sku.ubicacion = locationId;
        if(locationGroupAssignment != null) {
            sku.agencia = getLocationAddressInformation(locationGroupAssignment);
            sku.concessionaire = locationGroupAssignment.Location.Name;
        }
        if(product != null) {
            sku.description = product.Name;
            sku.modelLine = product.Linea_usado__c;
            sku.color = product.fan_BaseColor__c;
            sku.model = product.fan_YearModel__c;
            sku.reference = product.Referencia__c;
        }

        sku.availableToFulfill = inventory.availableToFulfill;
        sku.availableToOrder = inventory.availableToOrder;
        sku.onHand = inventory.onHand;
        sku.reserved = inventory.reserved;
        sku.safetyStockCount = inventory.safetyStockCount;
        sku.stockKeepingUnit = inventory.stockKeepingUnit;

        return sku;
    }

    public static Map<String, Product2> getProductInformationBySKU(String[] skus){

        Map<String, Product2> products = new Map<String, Product2>();
        for(ProductCategoryProduct productCategoryProduct : [SELECT Product.StockKeepingUnit, Product.Name, Product.Linea_usado__c, Product.fan_BaseColor__c, Product.Referencia__c,
                                                            Product.fan_YearModel__c FROM ProductCategoryProduct WHERE Product.StockKeepingUnit = :skus]){
            products.put(productCategoryProduct.Product.StockKeepingUnit, productCategoryProduct.Product);
        }
        return products;
    }

    public static Map<String, Integer> getCountRelatedProduct(List<String> lstSku){
        Map<String, Integer> result = new Map<String, Integer>();
        Map<String, Integer> resultQuery = new Map<String, Integer>();
        
        List<AggregateResult> lstAggregateResult = [SELECT fan_Source__r.StockKeepingUnit, COUNT(fan_Target__c)target_count FROM fan_RelatedProducts__c WHERE fan_RelationType__c = '3' AND fan_Source__r.StockKeepingUnit IN :lstSku GROUP BY fan_Source__r.StockKeepingUnit];
        for (AggregateResult queryResult : lstAggregateResult) {
            resultQuery.put(String.valueOf(queryResult.get('StockKeepingUnit')), Integer.valueOf(queryResult.get('target_count')));
        }
        for (String sku : lstSku) {
            Integer targetCount = resultQuery.containsKey(sku)? resultQuery.get(sku) : 0;
            result.put(sku, targetCount);
        }
        return result;
    }

    public static Map<String, Product2> getRelatedProduct(String sku){
        Map<String, Product2> products = new Map<String, Product2>();
        for(fan_RelatedProducts__c relatedProduct : [SELECT fan_Target__r.Name, fan_Target__r.StockKeepingUnit, fan_Target__r.Referencia__c FROM fan_RelatedProducts__c WHERE fan_RelationType__c = '3' AND fan_Source__r.StockKeepingUnit = :sku]){
            products.put(relatedProduct.fan_Target__r.StockKeepingUnit, relatedProduct.fan_Target__r);
        }
        return products;
    }

    public static fan_OCIGetAvailabilityUtils.StockKeepingUnitsResult getRelatedProductsAvailability(String locationGroup, Map<String, Product2> products){
        fan_OCIGetAvailabilityUtils.StockKeepingUnitsResult result = new fan_OCIGetAvailabilityUtils.StockKeepingUnitsResult();
        ConnectApi.OCIGetInventoryAvailabilityInputRepresentation inventoryAvailabilityInputRepresentation = new ConnectApi.OCIGetInventoryAvailabilityInputRepresentation();

        inventoryAvailabilityInputRepresentation.locationGroupIdentifiers = new String[] { locationGroup };
        inventoryAvailabilityInputRepresentation.stockKeepingUnits = new List<String>(products.keySet());

        ConnectApi.OCIGetInventoryAvailabilityOutputRepresentation output = Test.isRunningTest() ? testOutputRepresentation : ConnectApi.OmnichannelInventoryService.getInventoryAvailability(inventoryAvailabilityInputRepresentation);
        for(ConnectApi.OCILocationGroupAvailabilityOutputRepresentation OCI_lgaor : output.locationGroups){
            for(ConnectApi.OCIInventoryRecordOutputRepresentation inventory :  OCI_lgaor.inventoryRecords){
                fan_OCIGetAvailabilityUtils.StockKeepingUnitsLocation skul = new fan_OCIGetAvailabilityUtils.StockKeepingUnitsLocation();
                Product2 product = products.get(inventory.stockKeepingUnit);
                skul.description = product.Name;
                skul.reference = product.Referencia__c;
                skul.availableToFulfill = inventory.availableToFulfill;
                skul.stockKeepingUnit = inventory.stockKeepingUnit;
                result.lstLocationGroup.add(skul);
            }
        }
        return result;
    }

    /** Query ProductCategoryProduct for validate catalog ID and only show current store products
     * @param searchTerm The name or StockKeepingUnit of the Product2 to query.
     */
    public static Map<String, Product2> getProductInformation(String searchTerm, String locationGroup){

        Map<String, Product2> products = new Map<String, Product2>();
        searchTerm = '%' + searchTerm.trim() + '%';

        System.debug('locationGroup >>> '+locationGroup);
        WebStoreCatalog storeCatalog = [SELECT ProductCatalogId FROM WebStoreCatalog WHERE SalesStore.fan_LocationGroup__r.ExternalReference = :locationGroup LIMIT 1];
        // Get the store Catalog Id to search only products of current store
        List<ProductCategoryProduct> productCategoryProducts = [SELECT Product.StockKeepingUnit, Product.Name, Product.Referencia__c, Product.Linea_usado__c, Product.fan_BaseColor__c, Product.fan_YearModel__c
                                                                FROM ProductCategoryProduct WHERE ProductCategory.CatalogId = :storeCatalog.ProductCatalogId AND Product.StockKeepingUnit != null
                                                                AND (Product.StockKeepingUnit LIKE :searchTerm OR Product.Referencia__c LIKE :searchTerm OR Product.Name LIKE :searchTerm)];

        System.debug('productCategoryProducts query >>> ' + productCategoryProducts);
        for(ProductCategoryProduct productCategoryProduct : productCategoryProducts){
            products.put(productCategoryProduct.Product.StockKeepingUnit, productCategoryProduct.Product);
        }
        return products;
    }

    public static Map<String, LocationGroupAssignment> getLocationGroupAssignments(String locationGroup) {

        Map<String, LocationGroupAssignment> LocationGroupAssignmentMap = new Map<String, LocationGroupAssignment>();

        List<LocationGroupAssignment> locationGroupAssignments = [SELECT Location.ExternalReference, 
                Location.Name,
                Location.VisitorAddress.Street,
                Location.VisitorAddress.PostalCode,
                Location.VisitorAddress.City,
                Location.VisitorAddress.State,
                Location.VisitorAddress.Country
                FROM LocationGroupAssignment 
                WHERE LocationGroup.ExternalReference =: locationGroup];

        for (LocationGroupAssignment locationGroupAssignment : locationGroupAssignments) {
            LocationGroupAssignmentMap.put(locationGroupAssignment.Location.ExternalReference, locationGroupAssignment);
        }
        return LocationGroupAssignmentMap;
    }

    public static String getLocationAddressInformation(LocationGroupAssignment lga){
        return String.format('{0} {1} {2} {3} {4} ', new String[] {
            (String.isNotBlank(lga.Location.VisitorAddress.Street) ? lga.Location.VisitorAddress.Street : ''),
            (String.isNotBlank(lga.Location.VisitorAddress.PostalCode) ? lga.Location.VisitorAddress.PostalCode : ''),
            (String.isNotBlank(lga.Location.VisitorAddress.City) ? lga.Location.VisitorAddress.City : ''),
            (String.isNotBlank(lga.Location.VisitorAddress.State) ? lga.Location.VisitorAddress.State : ''),
            (String.isNotBlank(lga.Location.VisitorAddress.Country) ? lga.Location.VisitorAddress.Country : '')
        });
    }
    
}