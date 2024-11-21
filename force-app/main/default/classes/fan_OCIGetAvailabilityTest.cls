@IsTest
public class fan_OCIGetAvailabilityTest {

    @TestSetup
    static void makeData(){
        Product2 source1 = fan_B2BTestDataFactory.createProduct('SOURCE-SKU-1', 'SOURCE-ProductCode-1', null);
        Product2 target1 = fan_B2BTestDataFactory.createProduct('TARGET-SKU-1', 'TARGET-ProductCode-1', null);
        Product2 target2 = fan_B2BTestDataFactory.createProduct('TARGET-SKU-2', 'TARGET-ProductCode-2', null);
        fan_B2BTestDataFactory.createProduct('SOURCE-SKU-2', 'SOURCE-ProductCode-2', null);

        fan_B2BTestDataFactory.createRelatedProduct(source1.Id, target1.Id, '3');
        fan_B2BTestDataFactory.createRelatedProduct(source1.Id, target2.Id, '3');

        ProductCatalog productCatalog = fan_B2BTestDataFactory.createProductCatalog('Motos Catalog');
        ProductCategory productCategory = fan_B2BTestDataFactory.createProductCategory('Segmentos', productCatalog.Id, 'M');
        fan_B2BTestDataFactory.createProductCategoryProduct(productCategory.Id, source1.Id);

        Schema.Location location1 = fan_B2BTestDataFactory.createLocation('Location 1', '09019', true);
        LocationGroup locationGroup1 = fan_B2BTestDataFactory.createLocationGroup('B2B Motos', 'B2B_Motos');
        fan_B2BTestDataFactory.createLocationGroupAssignment(location1.Id, locationGroup1.Id);

        Schema.Location location2 = fan_B2BTestDataFactory.createLocation('Location 2', '07010', true);
        LocationGroup locationGroup2 = fan_B2BTestDataFactory.createLocationGroup('B2C Fanalca SA_CO-inventory_RED', 'FanalcaSA_CO-inventory_RED');
        fan_B2BTestDataFactory.createLocationGroupAssignment(location2.Id, locationGroup2.Id);

        Account account = fan_B2BTestDataFactory.createAccount('123456789', 'NIT');

        fan_B2BTestDataFactory.createContactPointAddress('ContactPointAddress 1', 'CPA-1', 'Shipping', 'PASTO', account.Id);
        fan_B2BTestDataFactory.createContactPointAddress('ContactPointAddress 2', 'CPA-2', 'Shipping', 'PASTO', account.Id);

        fan_B2BTestDataFactory.createCityLocation(location1.Id, 'PASTO');
        fan_B2BTestDataFactory.createCityLocation(location2.Id, 'PASTO');

        WebStore webStore = fan_B2BTestDataFactory.createWebStore('Test WebStore');
        webStore.fan_LocationGroup__c = locationGroup1.Id;
        UPDATE webStore;

        fan_B2BTestDataFactory.createWebStoreCatalog(productCatalog.Id, webStore.Id);
    }

    @IsTest
    static void getAvailabilityOfRelatedProducts() {
        String locationIdentifier = '09019';
        String locationGroupIdentifier = 'B2B_Motos';
        String sku = 'SOURCE-SKU-1';
        String[] locations = new List<String>();

        for (fan_CityLocation__c cityLocation : [SELECT fan_Location__r.ExternalReference FROM fan_CityLocation__c WHERE fan_Ciudad__c = 'PASTO']) {
            locations.add(cityLocation.fan_Location__r.ExternalReference);
        }
        fan_OCIGetAvailabilityAbstract.testOutputRepresentation = fan_B2BTestDataFactory.generateOCIGetInventoryAvailability(locationGroupIdentifier, locationIdentifier, new String[]{ sku });
        fan_OCIGetAvailabilityUtils.StockKeepingUnitsResultWithRelatedProduct stockKeepingUnitsResult = fan_OCIGetAvailability.getAvailabilityOfRelatedProducts(locationGroupIdentifier, sku, locations);
        fan_OCIGetAvailabilityUtils.StockKeepingUnitsLocationWithRelatedProduct locationGroup = stockKeepingUnitsResult.lstLocationGroup[0];

        Assert.areEqual(locationGroupIdentifier, locationGroup.ubicacion, 'The location group identifier is not as expected.');
        Assert.areEqual(sku, locationGroup.stockKeepingUnit, 'The stockKeepingUnit of the location is not as expected.');
        Assert.isTrue(locationGroup.hasRelatedProduct, 'The hasRelatedProduct of the location is not as expected.');
        Assert.areEqual(100, locationGroup.availableToFulfill, 'The availableToFulfill of the location is not as expected.');
        Assert.areEqual(100, locationGroup.availableToOrder, 'The availableToOrder of the location is not as expected.');
        Assert.areEqual(100, locationGroup.onHand, 'The onHand of the location is not as expected.');
        Assert.areEqual(0, locationGroup.reserved, 'The reserved of the location is not as expected.');
        Assert.areEqual(0, locationGroup.safetyStockCount, 'The safetyStockCount of the location is not as expected.');
    }

    @IsTest
    static void getAvailabilityForRedInventory() {

        String sku = 'SOURCE-SKU-1';
        String locationIdentifier = '07010';
        String locationGroupIdentifier = 'FanalcaSA_CO-inventory_RED';
        fan_OCIGetAvailabilityAbstract.testOutputRepresentation = fan_B2BTestDataFactory.generateOCIGetInventoryAvailability(locationGroupIdentifier, locationIdentifier, new String[]{ sku });

        fan_OCIGetAvailabilityUtils.StockKeepingUnitsLocation[] availability = fan_OCIGetAvailability.getAvailabilityForRedInventory('FanalcaSA_CO-inventory_RED', 'SOURCE-SKU');
        fan_OCIGetAvailabilityUtils.StockKeepingUnitsLocation stockKeepingUnitsLocation = availability[0];

        Assert.areEqual(locationIdentifier, stockKeepingUnitsLocation.ubicacion, 'The location identifier is not as expected.');
        Assert.areEqual(sku, stockKeepingUnitsLocation.stockKeepingUnit, 'The stockKeepingUnit of the location is not as expected.');
    }

    @IsTest
    static void getRelatedProductsWithAvailability() {
        String locationIdentifier = '09019';
        String locationGroupIdentifier = 'B2B_Motos';
        String sku = 'SOURCE-SKU-1';

        Set<String> relatedProductSkus = new Set<String>();
        for (fan_RelatedProducts__c relatedProduct : [SELECT fan_Target__r.StockKeepingUnit FROM fan_RelatedProducts__c WHERE fan_RelationType__c = '3' AND fan_Source__r.StockKeepingUnit = :sku]) {
            relatedProductSkus.add(relatedProduct.fan_Target__r.StockKeepingUnit);
        }
        fan_OCIGetAvailabilityAbstract.testOutputRepresentation = fan_B2BTestDataFactory.generateOCIGetInventoryAvailability(locationGroupIdentifier, locationIdentifier, new List<String>(relatedProductSkus));
        fan_OCIGetAvailabilityUtils.StockKeepingUnitsResult stockKeepingUnitsResult = fan_OCIGetAvailability.getRelatedProductsWithAvailability(locationGroupIdentifier, sku);

        Assert.areEqual(2, stockKeepingUnitsResult.lstLocationGroup.size(), 'The size of the lstLocationGroup is not as expected.');
    }

    @IsTest
    static void getLocationByCity() {

        String accountId = [SELECT Id FROM Account].Id;

        Map<String, String[]> cityLocations = fan_OCIGetAvailability.getLocationByCity(accountId);

        Assert.areEqual(2, cityLocations.get('PASTO').size(), 'The size of the cityLocations is not as expected.');
    }
}