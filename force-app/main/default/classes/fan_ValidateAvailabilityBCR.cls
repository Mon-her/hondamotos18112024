// BCR -> Before Create Reservation
public with sharing class fan_ValidateAvailabilityBCR {

    @TestVisible
    static OCIInteractionOrderItemSummary__c[] testInteractionOrderItemSummaries;
    @TestVisible
    static Map<String, Decimal> testOrderedQuantities;
    @TestVisible
    static ConnectApi.OCIGetInventoryAvailabilityOutputRepresentation testGetInventoryAvailabilityOutput;

    /** @param interactionOrderSummaryIds will always be expected as a single element. */
    @InvocableMethod(label='Validate Availability Before Create Reservations' category='Order Management' callout=true)
    public static Output[] validateAvailabilityBCR(String[] interactionOrderSummaryIds) {

        String[] skus = new List<String>();
        Set<String> unavailableSkus = new Set<String>();
        ReservationInfo reservationInfo = getReservationInfo(interactionOrderSummaryIds);
        Map<String, Decimal> orderedQuantities = getOrderedQuantities(interactionOrderSummaryIds);
        Iterator<String> skusIterator = orderedQuantities.keySet().iterator();

        while (skusIterator.hasNext()) {
            skus.add(skusIterator.next());
            // The product of the skus, location and location group parameters must not excedd 100. (A location group plus a location) multiplied by the number of skus.
            if(skus.size() == 50 || !skusIterator.hasNext()) {
                ConnectApi.OCIGetInventoryAvailabilityInputRepresentation inventoryAvailabilityInput = buildGetInventoryAvailabilityInputRepresentation(reservationInfo, skus);
                validateAvailability(inventoryAvailabilityInput, orderedQuantities, unavailableSkus);
                skus.clear();
            }
        }

        if(!unavailableSkus.isEmpty()) {
            throw new FlowException(Label.fan_UnavailableSkus + ': ' + unavailableSkus);
        }
        return new Output[] {
            new Output(buildCreateRecords(orderedQuantities, reservationInfo))
        };
    }

    static ReservationInfo getReservationInfo(String[] interactionOrderSummaryIds) {

        OCIInteractionOrderItemSummary__c[] interactionOrderItemSummaries = Test.isRunningTest()
                                                                            ? testInteractionOrderItemSummaries
                                                                            : [SELECT FromLocationGroup__r.ExternalReference, ToLocation__r.ExternalReference FROM OCIInteractionOrderItemSummary__c
                                                                                WHERE OCIInteractionOrderSummary__c IN: interactionOrderSummaryIds
                                                                                AND OrderItemSummary__r.TypeCode =: fan_Constants.OrderItemSummaryTypeCode.PRODUCT.name() LIMIT 1];

        OCIInteractionOrderItemSummary__c interactionOrderItemSummary = interactionOrderItemSummaries.isEmpty() ? new OCIInteractionOrderItemSummary__c() : interactionOrderItemSummaries[0];
        return new ReservationInfo(interactionOrderItemSummary.FromLocationGroup__r.ExternalReference, interactionOrderItemSummary.ToLocation__r.ExternalReference);
    }

    static Map<String, Decimal> getOrderedQuantities(String[] interactionOrderSummaryIds) {

        Map<String, Decimal> orderedQuantities = new Map<String, Decimal>();

        for(AggregateResult product : [SELECT OrderItemSummary__r.StockKeepingUnit StockKeepingUnit, SUM(Quantity__c) Quantity FROM OCIInteractionOrderItemSummary__c
                                        WHERE OCIInteractionOrderSummary__c IN: interactionOrderSummaryIds
                                        AND OrderItemSummary__r.TypeCode =: fan_Constants.OrderItemSummaryTypeCode.PRODUCT.name()
                                        GROUP BY OrderItemSummary__r.StockKeepingUnit
                                        ORDER BY OrderItemSummary__r.StockKeepingUnit]) {

            String sku = (String) product.get('StockKeepingUnit');
            Decimal orderedQuantity = (Decimal) product.get('Quantity');

            orderedQuantities.put(sku, orderedQuantity);
        }
        return Test.isRunningTest() ? testOrderedQuantities : orderedQuantities;
    }

    // Check if the ordered quantity is available to reserve.
    static void validateAvailability(ConnectApi.OCIGetInventoryAvailabilityInputRepresentation inventoryAvailabilityInput, Map<String, Decimal> orderedQuantities, Set<String> unavailableSkus) {

        ConnectApi.OCIGetInventoryAvailabilityOutputRepresentation inventoryAvailabilityOutput = Test.isRunningTest() ? testGetInventoryAvailabilityOutput : ConnectApi.OmnichannelInventoryService.getInventoryAvailability(inventoryAvailabilityInput);

        for(ConnectApi.OCILocationGroupAvailabilityOutputRepresentation locationGroupAvailabilityOutput : inventoryAvailabilityOutput.locationGroups) {
            for(ConnectApi.OCIInventoryRecordOutputRepresentation inventory : locationGroupAvailabilityOutput.inventoryRecords) {
                String sku = inventory.stockKeepingUnit;
                if(orderedQuantities.get(sku) > inventory.availableToFulfill) {
                    unavailableSkus.add(sku);
                }
            }
        }

        for(ConnectApi.OCILocationAvailabilityOutputRepresentation locationAvailabilityOutput : inventoryAvailabilityOutput.locations) {
            for(ConnectApi.OCIInventoryRecordOutputRepresentation inventory : locationAvailabilityOutput.inventoryRecords) {
                String sku = inventory.stockKeepingUnit;
                if(orderedQuantities.get(sku) > inventory.availableToFulfill) {
                    unavailableSkus.add(sku);
                }
            }
        }
    }

    static ConnectApi.OCIGetInventoryAvailabilityInputRepresentation buildGetInventoryAvailabilityInputRepresentation(ReservationInfo reservationInfo, String[] skus) {

        ConnectApi.OCIGetInventoryAvailabilityInputRepresentation inventoryAvailabilityInput = new ConnectApi.OCIGetInventoryAvailabilityInputRepresentation();
        inventoryAvailabilityInput.locationIdentifiers = new List<String> { reservationInfo.toLocation };
        inventoryAvailabilityInput.locationGroupIdentifiers = new List<String> { reservationInfo.fromLocationGroup };
        inventoryAvailabilityInput.useCache = false;
        inventoryAvailabilityInput.stockKeepingUnits = skus;

        return inventoryAvailabilityInput;
    }

    static ConnectApi.OCICreateReservationSingleInputRepresentation[] buildCreateRecords(Map<String, Decimal> orderedQuantities, ReservationInfo reservationInfo) {

        ConnectApi.OCICreateReservationSingleInputRepresentation[] createRecords = new List<ConnectApi.OCICreateReservationSingleInputRepresentation>();

        for(String sku : orderedQuantities.keySet()) {
            ConnectApi.OCICreateReservationSingleInputRepresentation createRecord = new ConnectApi.OCICreateReservationSingleInputRepresentation();
            createRecord.locationGroupIdentifier = reservationInfo.fromLocationGroup;
            createRecord.stockKeepingUnit = sku;
            createRecord.quantity = orderedQuantities.get(sku);
            createRecords.add(createRecord);
        }
        return createRecords;
    }

    public class Output {
        @InvocableVariable
        public ConnectApi.OCICreateReservationSingleInputRepresentation[] createRecords;

        Output(ConnectApi.OCICreateReservationSingleInputRepresentation[] createRecords) {
            this.createRecords = createRecords;
        }
    }

    class ReservationInfo {
        String fromLocationGroup;
        String toLocation;

        public ReservationInfo(String fromLocationGroup, String toLocation) {
            this.fromLocationGroup = fromLocationGroup;
            this.toLocation = toLocation;
        }
    }
}