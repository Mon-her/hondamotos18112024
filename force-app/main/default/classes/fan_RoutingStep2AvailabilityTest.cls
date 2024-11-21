@IsTest
class fan_RoutingStep2AvailabilityTest {

    @IsTest
    static void getAvailability() {

        LocationGroup locationGroup = fan_B2BTestDataFactory.createLocationGroup('Posventa', 'B2B_posventa');

        fan_RoutingStep2Availability.Request request = new fan_RoutingStep2Availability.Request();
        request.salesStoreId = fan_IdTienda__mdt.getInstance('posventa').fan_IdTienda__c;
        request.orderItemSummaries = new OrderItemSummary[] {
            new OrderItemSummary(ReservedAtLocationId = locationGroup.Id, Type = 'Order Product'),
            new OrderItemSummary(Type = 'Delivery Charge')
        };
        fan_RoutingStep2Availability.testInventoryAvailabilityOutput = fan_B2BTestDataFactory.generateOCIGetInventoryAvailability('B2B_Posventa', '11007', new String[] { 'SKU-1' });

        fan_RoutingStep2Availability.getAvailability(new fan_RoutingStep2Availability.Request[] { request });
    }
}