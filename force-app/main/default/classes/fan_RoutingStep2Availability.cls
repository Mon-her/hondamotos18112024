public with sharing class fan_RoutingStep2Availability {

    @TestVisible
    static ConnectApi.OCIGetInventoryAvailabilityOutputRepresentation testInventoryAvailabilityOutput;

    @InvocableMethod(label='Get Availability')
    public static Response[] getAvailability(Request[] requests) {
        Request request = requests[0];
        Response response = new Response();

        String orderProductType = fan_Constants.OrderItemSummaryType.ORDER_PRODUCT.name().replace('_', ' ');
        Set<String> locationGroupIds = new Set<String>();
        Set<String> locations = new Set<String>();
        Set<String> skus = new Set<String>();

        for(OrderItemSummary orderItemSummary : request.orderItemSummaries) {
            if(orderItemSummary.Type == orderProductType && orderItemSummary.ReservedAtLocationId?.getSobjectType() == LocationGroup.SObjectType) {
                response.orderItemSummaryIds.add(orderItemSummary.Id);
                response.originalProductIds.add(orderItemSummary.Product2Id);
                locationGroupIds.add(orderItemSummary.ReservedAtLocationId);
                skus.add(orderItemSummary.StockKeepingUnit);
            }
        }
        
        if(request.salesStoreId == fan_IdTienda__mdt.getInstance(fan_Constants.StoreDeveloperName.POSVENTA.name().toLowerCase()).fan_IdTienda__c) {
            skus.addAll(getSubstitutes(response.originalProductIds));
            locations = getLocations(locationGroupIds);
        } else if(request.salesStoreId == fan_IdTienda__mdt.getInstance(fan_Constants.StoreDeveloperName.MOTOS.name().toLowerCase()).fan_IdTienda__c) {
            locations = getLocations(request.deliverToCity);
        }
        // Only one location group is used.
        String locationGroupIdentifier = [SELECT ExternalReference FROM LocationGroup WHERE Id =: locationGroupIds].ExternalReference;
        setAvailability(locationGroupIdentifier, locations, skus, response);

        response.locationGroupIds = new List<String>(locationGroupIds);
        return new Response[] { response };
    }

    static Set<String> getLocations(Set<String> locationGroupIds) {
        Set<String> locations = new Set<String>();
        for(LocationGroupAssignment locationGroupAssignment : [SELECT LocationExternalReference FROM LocationGroupAssignment WHERE LocationGroupId IN :locationGroupIds]) {
            locations.add(locationGroupAssignment.LocationExternalReference);
        }
        return locations;
    }

    static Set<String> getLocations(String deliverToCity) {
        Set<String> locations = new Set<String>();
        for (fan_CityLocation__c cityLocation : [SELECT fan_Location__r.ExternalReference FROM fan_CityLocation__c WHERE fan_Ciudad__c = :deliverToCity]) {
            locations.add(cityLocation.fan_Location__r.ExternalReference);
        }
        return locations;
    }

    static Set<String> getSubstitutes(String[] originalProductIds) {
        Set<String> substitutes = new Set<String>();
        // fan_RelationType__c: 3 -> substitutes
        for (fan_RelatedProducts__c relatedProduct : [SELECT fan_Target__r.StockKeepingUnit FROM fan_RelatedProducts__c
                                                        WHERE fan_RelationType__c = '3' AND fan_Source__c = :originalProductIds]) {
            substitutes.add(relatedProduct.fan_Target__r.StockKeepingUnit);
        }
        return substitutes;
    }

    static ConnectApi.OCIGetInventoryAvailabilityOutputRepresentation requestAvailability(ConnectApi.OCIGetInventoryAvailabilityInputRepresentation inventoryAvailabilityInput, Map<String, SkuQuantity> skuQuantities, Map<String, Decimal> locationGroupAvailability) {

        ConnectApi.OCIGetInventoryAvailabilityOutputRepresentation inventoryAvailabilityOutput = Test.isRunningTest() ? testInventoryAvailabilityOutput : ConnectApi.OmnichannelInventoryService.getInventoryAvailability(inventoryAvailabilityInput);
        if(inventoryAvailabilityOutput == null || inventoryAvailabilityOutput.locations == null) {
            throw new OCIGetInventoryAvailabilityException(Label.OCI_Get_Availability_Output_Error);
        }

        for(ConnectApi.OCILocationGroupAvailabilityOutputRepresentation locationGroup : inventoryAvailabilityOutput.locationGroups) {
            for(ConnectApi.OCIInventoryRecordOutputRepresentation inventory : locationGroup.inventoryRecords) {
                locationGroupAvailability.put(inventory.stockKeepingUnit, inventory.availableToFulfill);
            }
        }

        for(Integer locationIndex = inventoryAvailabilityOutput.locations.size() - 1; locationIndex >= 0; locationIndex--) {
            ConnectApi.OCILocationAvailabilityOutputRepresentation location = inventoryAvailabilityOutput.locations[locationIndex];
            for(Integer inventoryIndex = location.inventoryRecords.size() - 1; inventoryIndex >= 0; inventoryIndex--) {
                ConnectApi.OCIInventoryRecordOutputRepresentation inventory = location.inventoryRecords[inventoryIndex];
                String sku = inventory.stockKeepingUnit;
                skuQuantities.put(sku, buildSkuQuantity(sku, inventory.availableToFulfill, skuQuantities));

                if(inventory.availableToFulfill == 0) {
                    location.inventoryRecords.remove(inventoryIndex);
                }
            }

            if(location.inventoryRecords.isEmpty()) {
                inventoryAvailabilityOutput.locations.remove(locationIndex);
            }
        }
        return inventoryAvailabilityOutput;
    }

    static void setAvailability(String locationGroupIdentifier, Set<String> locations, Set<String> skus, Response response) {
        Map<String, Decimal> locationGroupAvailability = new Map<String, Decimal>();
        Map<String, SkuQuantity> skuQuantities = new Map<String, SkuQuantity>();
        String[] requestSkus = new List<String>();
        Iterator<String> iterator = ((Iterable<String>) skus).iterator();
        ConnectApi.OCIGetInventoryAvailabilityInputRepresentation inventoryAvailabilityInput = new ConnectApi.OCIGetInventoryAvailabilityInputRepresentation();
        inventoryAvailabilityInput.locationGroupIdentifiers = new String[] { locationGroupIdentifier };
        inventoryAvailabilityInput.locationIdentifiers = new List<String>(locations);
        inventoryAvailabilityInput.useCache = false;
        while (iterator.hasNext()) {
            requestSkus.add(iterator.next());
            // The product of the size of locations by the size of skus must not exceed 100. The one in the expresion (locations.size() + 1) represents the location group.
            if((locations.size() + 1) * (requestSkus.size() + 1) > 100 || !iterator.hasNext()) {
                inventoryAvailabilityInput.stockKeepingUnits = requestSkus;
                ConnectApi.OCIGetInventoryAvailabilityOutputRepresentation inventoryAvailabilityOutput = requestAvailability(inventoryAvailabilityInput, skuQuantities, locationGroupAvailability);
                // This validation is required to process backorder.
                if(!inventoryAvailabilityOutput.locations.isEmpty()) {
                    response.inventoryAvailabilityOutputs.add(inventoryAvailabilityOutput);
                }
                requestSkus.clear();
            }
        }
        validateAvailabilityAgainstLocactionGroup(skuQuantities, locationGroupAvailability);
        response.skuQuantity = skuQuantities.values();
    }

    static void validateAvailabilityAgainstLocactionGroup(Map<String, SkuQuantity> skuQuantities, Map<String, Decimal> locationGroupAvailability) {
        for (String sku : skuQuantities.keySet()) {

            SkuQuantity skuQuantity = skuQuantities.get(sku);
            skuQuantity.Quantity = Math.min(skuQuantity.Quantity, locationGroupAvailability.get(sku));
        }
    }

    static SkuQuantity buildSkuQuantity(String sku, Decimal availableToFulfill, Map<String, SkuQuantity> skuQuantities) {
        SkuQuantity skuQuantity = skuQuantities.containsKey(sku) ? skuQuantities.get(sku) : new SkuQuantity();
        skuQuantity.Quantity = (skuQuantity.Quantity == null ? 0 : skuQuantity.Quantity) + availableToFulfill;
        skuQuantity.SKU = sku;
        return skuQuantity;
    }

    public class Request {
        @InvocableVariable(label='OrderItemSummaries' required=true)
        public OrderItemSummary[] orderItemSummaries;
        @InvocableVariable(label='SalesStoreId' required=true)
        public String salesStoreId;
        @InvocableVariable(label='DeliverToCity')
        public String deliverToCity;
    }

    public class Response {
        @InvocableVariable(label='LocationGroupIdCollection')
        public String[] locationGroupIds;
        @InvocableVariable(label='OrderItemSummaryIdList')
        public String[] orderItemSummaryIds = new List<String>();
        @InvocableVariable(label='OriginalProductIds')
        public List<String> originalProductIds = new List<String>();
        @InvocableVariable(label='SKUQuantityList')
        public SkuQuantity[] skuQuantity;
        @InvocableVariable(label='InventoryAvailabilityOutputCollection')
        public ConnectApi.OCIGetInventoryAvailabilityOutputRepresentation[] inventoryAvailabilityOutputs = new List<ConnectApi.OCIGetInventoryAvailabilityOutputRepresentation>();
    }

    class OCIGetInventoryAvailabilityException extends Exception {}
}