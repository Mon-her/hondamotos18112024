public with sharing class fan_InventoryHandler {

    @TestVisible
    static ConnectApi.OCIGetInventoryAvailabilityOutputRepresentation testOutputRepresentation;

    // Motos
    @TestVisible
    void requestForAvailability(ConnectApi.OCIGetInventoryAvailabilityInputRepresentation inventoryAvailabilityInput, Map<String, Product> productBySku) {

        ConnectApi.OCIGetInventoryAvailabilityOutputRepresentation inventoryAvailabilityOutput = Test.isRunningTest() ? testOutputRepresentation : ConnectApi.OmnichannelInventoryService.getInventoryAvailability(inventoryAvailabilityInput);

        for(ConnectApi.OCILocationAvailabilityOutputRepresentation location : inventoryAvailabilityOutput.locations) {
            for(ConnectApi.OCIInventoryRecordOutputRepresentation inventory : location.inventoryRecords) {
                String sku = inventory.stockKeepingUnit;
                Product product = productBySku.get(sku);
                if(product == null) {
                    product = new Product();
                }
                product.available += inventory.availableToFulfill;
                productBySku.put(sku, product);
            }
        }
    }

    // Posventa
    public void requestForAvailability(String locationGroupIdentifier, Map<String, Product> products) {

        String[] requestSkus = new List<String>();
        ConnectApi.OCIGetInventoryAvailabilityInputRepresentation inventoryAvailabilityInput = new ConnectApi.OCIGetInventoryAvailabilityInputRepresentation();
        inventoryAvailabilityInput.locationGroupIdentifiers = new String[]{ locationGroupIdentifier };

        Iterator<String> iterator = products.keyset().iterator();
        while (iterator.hasNext()) {
            requestSkus.add(iterator.next());
            // The product of the size of locations by the size of skus must not exceed 100.
            if((requestSkus.size() + 1) > 100 || !iterator.hasNext()) {
                inventoryAvailabilityInput.stockKeepingUnits = requestSkus;
                ConnectApi.OCIGetInventoryAvailabilityOutputRepresentation inventoryAvailabilityOutput = Test.isRunningTest() ? testOutputRepresentation : ConnectApi.OmnichannelInventoryService.getInventoryAvailability(inventoryAvailabilityInput);
                for(ConnectApi.OCILocationGroupAvailabilityOutputRepresentation locationGroup : inventoryAvailabilityOutput.locationGroups){
                    for(ConnectApi.OCIInventoryRecordOutputRepresentation inventoryRecord : locationGroup.inventoryRecords){
                        products.get(inventoryRecord.stockKeepingUnit).available = inventoryRecord.availableToFulfill;
                    }
                }
                requestSkus.clear();
            }
        }
    }

    // Motos
    public Map<String, Map<String, Product>> getAvailability(Map<String, String[]> skusByCity) {

        Map<String, Map<String, Product>> skuAvailabilityByCity = new Map<String, Map<String, Product>>();
        Map<String, Set<String>> locationsByCity = getLocationsByCity(skusByCity.keySet());
        ConnectApi.OCIGetInventoryAvailabilityInputRepresentation inventoryAvailabilityInput = new ConnectApi.OCIGetInventoryAvailabilityInputRepresentation();

        for (String city : locationsByCity.keySet()) {
            String[] requestSkus = new List<String>();
            Map<String, Product> availabilityBySku = new Map<String, Product>(); // Side effect in requestForAvailability method.
            Set<String> locations = locationsByCity.get(city);
            inventoryAvailabilityInput.locationIdentifiers = new List<String>(locations);
            Iterator<String> iterator = skusByCity.get(city).iterator();
            while (iterator.hasNext()) {
                requestSkus.add(iterator.next());
                // The product of the size of locations by the size of skus must not exceed 100.
                if(locations.size() * (requestSkus.size() + 1) > 100 || !iterator.hasNext()) {
                    inventoryAvailabilityInput.stockKeepingUnits = requestSkus;
                    requestForAvailability(inventoryAvailabilityInput, availabilityBySku);
                    requestSkus.clear();
                }
            }
            skuAvailabilityByCity.put(city, availabilityBySku);
        }
        return skuAvailabilityByCity;
    }

    // Posventa
    public Map<String, Product> getAvailability(String locationGroup, String[] skus) {

        Map<String, Product> products = new Map<String, Product>(); // Side effect in requestForAvailability method.

        for (String sku : skus) products.put(sku, new Product());

        for(fan_RelatedProducts__c relatedProduct : [SELECT fan_Target__r.StockKeepingUnit, fan_Source__r.StockKeepingUnit FROM fan_RelatedProducts__c
                                                    WHERE fan_RelationType__c = '3' AND fan_Source__r.StockKeepingUnit IN :skus]){
            String sku = relatedProduct.fan_Source__r.StockKeepingUnit;
            String substituteSku = relatedProduct.fan_Target__r.StockKeepingUnit;
            Product product = products.containsKey(sku) ? products.get(sku) : new Product();
            product.substitutes.add(substituteSku);
            products.put(sku, product);

            Product substitute = products.containsKey(substituteSku) ? products.get(substituteSku) : new Product();
            products.put(substituteSku, substitute);
        }
        requestForAvailability(locationGroup, products);
        return products;
    }

    Map<String, Set<String>> getLocationsByCity(Set<String> cities) {
        Map<String, Set<String>> locationsByCity = new Map<String, Set<String>>();
        for (fan_CityLocation__c cityLocation : [SELECT fan_Ciudad__c, fan_Location__r.ExternalReference FROM fan_CityLocation__c
                                                WHERE fan_Ciudad__c IN :cities WITH SECURITY_ENFORCED]) {
            Set<String> locations = locationsByCity.get(cityLocation.fan_Ciudad__c);
            if(locations == null) {
                locations = new Set<String>();
            }
            locations.add(cityLocation.fan_Location__r.ExternalReference);
            locationsByCity.put(cityLocation.fan_Ciudad__c, locations);
        }
        return locationsByCity;
    }

    @TestVisible
    Decimal extractAvailabilityFromRelatedProducts(Map<String, Product> skusAvailability, String[] sustitutes, Decimal elegibleQuantity, Decimal orderedQuantity) {
        Decimal extractedAvailabilityTotal = 0;
	    Iterator<String> iterator = sustitutes.iterator();
	    while (elegibleQuantity < orderedQuantity && iterator?.hasNext() == true) {
		    String relatedProductSku = iterator.next();
		    // Quantity needed to complete the request.
		    Decimal requiredQuantity = orderedQuantity - elegibleQuantity;
		    Product substitute = skusAvailability.get(relatedProductSku);
		    // Quantity that can be extracted from the related product. 
		    Decimal extractedAvailability = Math.min(substitute.available, requiredQuantity);
            extractedAvailabilityTotal += extractedAvailability;
		    elegibleQuantity += extractedAvailability;

            substitute.available -= extractedAvailability;
	    }
	    return extractedAvailabilityTotal;
    }

    /**
     * @param skusAvailability Availability in the inventory.
     * @param stockKeepingUnit Product identifier in the inventory.
     * @param orderedQuantity Quantity to extract from the inventory.
     * @return Quanity can could be withdrawn.
     */
    public Decimal extractAvailability(Map<String, Product> skusAvailability,  String stockKeepingUnit, Decimal orderedQuantity) {
        // Quantity in the inventory.
        Product product = skusAvailability?.containsKey(stockKeepingUnit) == true ? skusAvailability.get(stockKeepingUnit) : new Product();
        // Quantity that can be ordered. 
        Decimal elegibleQuantity = Math.min(product.available, orderedQuantity);
        // Update sku availability.
        product.available -= elegibleQuantity;
        // Get quantity from related products to complete the requested.
        if(!product.substitutes.isEmpty()) {
            elegibleQuantity += extractAvailabilityFromRelatedProducts(skusAvailability, product.substitutes, elegibleQuantity, orderedQuantity);
        }
        return elegibleQuantity;
    }

    /**
     * Obtain the quantity that can be ordered.
     * NOTE: Cart items must be sorted by Id in ascending order.
     * */ 
    public Map<String, Decimal> getElegibleQuantity(WebStore webStore, CartItem[] cartItems) {
        Map<String, Decimal> elegibleQuantity = new Map<String, Decimal>();

        fan_IdTienda__mdt idTiendaMdt = fan_B2BUtils.getIdTiendaMdt(webStore.Id, fan_IdTienda__mdt.fan_IdTienda__c);
        if(idTiendaMdt.DeveloperName == fan_Constants.StoreDeveloperName.MOTOS.name()) {
            elegibleQuantity = getElegibleQuantity(cartItems);
        } else if(idTiendaMdt.DeveloperName == fan_Constants.StoreDeveloperName.POSVENTA.name()) {
            elegibleQuantity = getElegibleQuantity(webStore.fan_LocationGroupReference__c, cartItems);
        }
        return elegibleQuantity;
    }

    // Motos
    Map<String, Decimal> getElegibleQuantity(CartItem[] cartItems) {
        Map<String, Decimal> elegibleQuantity = new Map<String, Decimal>();
        Map<String, String[]> skusByCity = new Map<String, String[]>();
        for (CartItem cartItem : cartItems) {
            String city = cartItem.CartDeliveryGroup.DeliverToCity;
            String[] skus = skusByCity.containsKey(city) ? skusByCity.get(city) : new List<String>();

            skus.add(cartItem.Sku);
            skusByCity.put(cartItem.CartDeliveryGroup.DeliverToCity, skus);
        }
        Map<String, Map<String, Product>> availabilityByCity = getAvailability(skusByCity);

        for (CartItem cartItem : cartItems) {
            Map<String, Product> availability = availabilityByCity.get(cartItem.CartDeliveryGroup.DeliverToCity);
            Decimal available = extractAvailability(availability, cartItem.Sku, cartItem.Quantity);
            elegibleQuantity.put(cartItem.Id, available);
        }
        return elegibleQuantity;
    }

    // Posventa
    Map<String, Decimal> getElegibleQuantity(String locationGroup, CartItem[] cartItems) {
        Map<String, Decimal> elegibleQuantity = new Map<String, Decimal>();
        Set<String> skus = new Set<String>();
        for (CartItem cartItem : cartItems) {
            skus.add(cartItem.Sku);
        }
        Map<String, Product> availability = getAvailability(locationGroup, new List<String>(skus));

        for (CartItem cartItem : cartItems) {
            Decimal available = extractAvailability(availability, cartItem.Sku, cartItem.Quantity);
            elegibleQuantity.put(cartItem.Id, available);
        }
        return elegibleQuantity;
    }

    public class Product {
        @AuraEnabled
        public Decimal available = 0;
        @AuraEnabled
        public String[] substitutes = new List<String>();
    }
}