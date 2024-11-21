@IsTest
class fan_ValidateAvailabilityBCRTest {

    @IsTest
    static void fan_ValidateAvailabilityBCRShouldEndSucessfully() {

        String sku = '75375';
        Decimal availability = 1;

        LocationGroup locationGroup = new LocationGroup(ExternalReference = 'B2B_Posventa');

        fan_ValidateAvailabilityBCR.testGetInventoryAvailabilityOutput = getInventoryAvailabilityOutput(sku, availability);
        fan_ValidateAvailabilityBCR.testInteractionOrderItemSummaries = new OCIInteractionOrderItemSummary__c[] {
            new OCIInteractionOrderItemSummary__c(FromLocationGroup__r = locationGroup)
        };
        fan_ValidateAvailabilityBCR.testOrderedQuantities = new Map<String, Decimal> { sku => 1 };
        fan_ValidateAvailabilityBCR.Output[] outputs = fan_ValidateAvailabilityBCR.validateAvailabilityBCR(new List<String>());

        ConnectApi.OCICreateReservationSingleInputRepresentation createRecord = outputs[0].createRecords[0];

        Assert.areEqual('B2B_Posventa', createRecord.locationGroupIdentifier, 'The location group identifier is not as expected.');
        Assert.areEqual(sku, createRecord.stockKeepingUnit, 'The sku is not as expected.');
        Assert.areEqual(1, createRecord.quantity, 'The quantity is not as expected.');
    }

    @IsTest
    static void fan_ValidateAvailabilityBCRShouldThrowAnException() {

        String sku = '75375';
        Decimal availability = 0;

        fan_ValidateAvailabilityBCR.testGetInventoryAvailabilityOutput = getInventoryAvailabilityOutput(sku, availability);
        fan_ValidateAvailabilityBCR.testInteractionOrderItemSummaries = new List<OCIInteractionOrderItemSummary__c>();
        fan_ValidateAvailabilityBCR.testOrderedQuantities = new Map<String, Decimal> { sku => 1 };

        try {
            fan_ValidateAvailabilityBCR.validateAvailabilityBCR(new List<String>());
        } catch (Exception e) {
            Assert.areEqual('Skus sin disponibilidad: ' + new Set<String> { sku }, e.getMessage(), 'The exception message is not as expected.');
        }
    }

    static ConnectApi.OCIGetInventoryAvailabilityOutputRepresentation getInventoryAvailabilityOutput (String sku, Decimal availability) {
        ConnectApi.OCIGetInventoryAvailabilityOutputRepresentation getInventoryAvailabilityOutput = new ConnectApi.OCIGetInventoryAvailabilityOutputRepresentation();

        ConnectApi.OCIInventoryRecordOutputRepresentation inventoryRecordOutput = new ConnectApi.OCIInventoryRecordOutputRepresentation();
        inventoryRecordOutput.stockKeepingUnit = sku;
        inventoryRecordOutput.availableToFulfill = availability;

        ConnectApi.OCILocationGroupAvailabilityOutputRepresentation locationGroupAvailabilityOutputRepresentation = new ConnectApi.OCILocationGroupAvailabilityOutputRepresentation();
        locationGroupAvailabilityOutputRepresentation.inventoryRecords = new ConnectApi.OCIInventoryRecordOutputRepresentation[] { inventoryRecordOutput };
        getInventoryAvailabilityOutput.locationGroups = new ConnectApi.OCILocationGroupAvailabilityOutputRepresentation[] { locationGroupAvailabilityOutputRepresentation };

        ConnectApi.OCILocationAvailabilityOutputRepresentation locationAvailabilityOutputRepresentation = new ConnectApi.OCILocationAvailabilityOutputRepresentation();
        locationAvailabilityOutputRepresentation.inventoryRecords = new ConnectApi.OCIInventoryRecordOutputRepresentation[] { inventoryRecordOutput };
        getInventoryAvailabilityOutput.locations = new ConnectApi.OCILocationAvailabilityOutputRepresentation[] { locationAvailabilityOutputRepresentation };

        return getInventoryAvailabilityOutput;
    }
}