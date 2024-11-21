@IsTest
class fan_OCIGetAvailabilityUtilsTest {

    @TestSetup
    static void makeData(){
        Product2 source1 = fan_B2BTestDataFactory.createProduct('SOURCE-SKU-1', 'SOURCE-ProductCode-1', null);
        Product2 target1 = fan_B2BTestDataFactory.createProduct('TARGET-SKU-1', 'TARGET-ProductCode-1', null);
        Product2 target2 = fan_B2BTestDataFactory.createProduct('TARGET-SKU-2', 'TARGET-ProductCode-2', null);
        fan_B2BTestDataFactory.createProduct('SOURCE-SKU-2', 'SOURCE-ProductCode-2', null);

        fan_B2BTestDataFactory.createRelatedProduct(source1.Id, target1.Id, '3');
        fan_B2BTestDataFactory.createRelatedProduct(source1.Id, target2.Id, '3');
    }

    @IsTest
    static void getRelatedProductGroupepBySource() {

        String[] productSkus = new String[]{ 'SOURCE-SKU-1', 'SOURCE-SKU-2' };

        Map<String, Set<String>> relatedProducts = fan_OCIGetAvailabilityUtils.getRelatedProductGroupepBySource(productSkus);
        Set<String> targetProducts = relatedProducts.get('SOURCE-SKU-1');

        Assert.isTrue(targetProducts.contains('TARGET-SKU-1'), 'Source 1 does not have the target 1.');
        Assert.isTrue(targetProducts.contains('TARGET-SKU-2'), 'Source 1 does not have the target 2.');
        Assert.isTrue(relatedProducts.get('SOURCE-SKU-2').isEmpty(), 'The source 2 has target products');
    }

    @IsTest
    static void addSubstitutesAvailability() {
        Map<String, Decimal> stockBySku = new Map<String, Decimal> {
            'SOURCE-SKU-1' => 5,
            'SOURCE-SKU-2' => 4,
            'TARGET-SKU-1' => 3,
            'TARGET-SKU-2' => 1
        };
        Map<String, Set<String>> relatedProductSkus = new Map<String, Set<String>> {
            'SOURCE-SKU-1' => new Set<String> { 'TARGET-SKU-1', 'TARGET-SKU-2' },
            'SOURCE-SKU-2' => new Set<String> ()
        };

        Map<String, Decimal> stock = fan_OCIGetAvailabilityUtils.addSubstitutesAvailability(stockBySku, relatedProductSkus);
        Assert.areEqual(9, stock.get('SOURCE-SKU-1'), 'The stock of the SOURCE-SKU-1 is not as expected.');
        Assert.areEqual(4, stock.get('SOURCE-SKU-2'), 'The stock of the SOURCE-SKU-2 is not as expected.');
    }

    @IsTest
    static void calculateSkuAvailability() {

        fan_OCIGetAvailabilityUtils.StockKeepingUnitsLocation sourceLocation1 = new fan_OCIGetAvailabilityUtils.StockKeepingUnitsLocation();
        sourceLocation1.stockKeepingUnit = 'SOURCE-SKU-1';
        sourceLocation1.availableToFulfill = 5;
        sourceLocation1.ubicacion = 'Location 1';

        fan_OCIGetAvailabilityUtils.StockKeepingUnitsLocation sourceLocation2 = new fan_OCIGetAvailabilityUtils.StockKeepingUnitsLocation();
        sourceLocation2.stockKeepingUnit = 'SOURCE-SKU-1';
        sourceLocation2.availableToFulfill = 1;
        sourceLocation2.ubicacion = 'Location 2';

        fan_OCIGetAvailabilityUtils.StockKeepingUnitsLocation target1 = new fan_OCIGetAvailabilityUtils.StockKeepingUnitsLocation();
        target1.stockKeepingUnit = 'TARGET-SKU-1';
        target1.availableToFulfill = 2;

        fan_OCIGetAvailabilityUtils.StockKeepingUnitsLocation target2 = new fan_OCIGetAvailabilityUtils.StockKeepingUnitsLocation();
        target2.stockKeepingUnit = 'TARGET-SKU-2';
        target2.availableToFulfill = 7;

        fan_OCIGetAvailabilityUtils.StockKeepingUnitsLocation[] stockKeepingUnitsLocations = new fan_OCIGetAvailabilityUtils.StockKeepingUnitsLocation[] {
            sourceLocation1, sourceLocation2,
            target1, target2
        };

        Map<String, Set<String>> relatedProductSkus = new Map<String, Set<String>> {
            'SOURCE-SKU-1' => new Set<String> { 'TARGET-SKU-1', 'TARGET-SKU-2' }
        };
        Map<String, Decimal> skuAvailability = fan_OCIGetAvailabilityUtils.calculateSkuAvailability(stockKeepingUnitsLocations, relatedProductSkus);

        Assert.areEqual(1, skuAvailability.size(), 'The size of the skuAvailability is not as expected.');
        Assert.areEqual(15, skuAvailability.get('SOURCE-SKU-1'), 'The sku availability of the SOURCE-SKU-1 is not as expected.');
    }
}