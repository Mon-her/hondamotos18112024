@isTest
private class fan_BuilderRepresentationActionTest {
    @isTest static void test_BuilderRepresentationAction() {
        List<BuilderRepresentationInput> inputs = CreateInputs();        
        List<BuilderRepresentationResult> results = fan_BuilderRepresentationAction.generateFindRoutesWithFewestSplitsInput(inputs);
        
        System.assertEquals(inputs.size(),results.size());
        System.assertEquals(2,results.get(0).builderOutput.findRoutesWithFewestSplitsInput.locationAvailableInventory.size());
        System.assertEquals('loc1',results.get(0).builderOutput.findRoutesWithFewestSplitsInput.locationAvailableInventory.get(0).externalReferenceId);
        System.assertEquals(2,results.get(0).builderOutput.findRoutesWithFewestSplitsInput.orderedQuantities.size());
    }
    
    
    private static List<BuilderRepresentationInput>  CreateInputs(){
        List<BuilderRepresentationInput> inputs = new List<BuilderRepresentationInput>();
        
        //Creating Availability Data       
        List<ConnectApi.OCIInventoryRecordOutputRepresentation> inventoryRecords = new List<ConnectApi.OCIInventoryRecordOutputRepresentation>();
        ConnectApi.OCIInventoryRecordOutputRepresentation record1 = new ConnectApi.OCIInventoryRecordOutputRepresentation();
        record1.stockKeepingUnit = 'sku1';
        record1.availableToFulfill = 10;
        ConnectApi.OCIInventoryRecordOutputRepresentation record2 = new ConnectApi.OCIInventoryRecordOutputRepresentation();
        record2.stockKeepingUnit = 'sku2';
        record2.availableToFulfill = 10;
        inventoryRecords.add(record1);
        inventoryRecords.add(record2);


        ConnectApi.OCILocationGroupAvailabilityOutputRepresentation locationGroupAvailability = new ConnectApi.OCILocationGroupAvailabilityOutputRepresentation();
        locationGroupAvailability.locationGroupIdentifier = 'locgroup1';
        locationGroupAvailability.inventoryRecords = inventoryRecords;
        
        ConnectApi.OCILocationAvailabilityOutputRepresentation locationAvailability = new ConnectApi.OCILocationAvailabilityOutputRepresentation();
        locationAvailability.locationIdentifier = 'loc1';
        locationAvailability.inventoryRecords = inventoryRecords;
        
        List<ConnectApi.OCILocationAvailabilityOutputRepresentation> locations = new List<ConnectApi.OCILocationAvailabilityOutputRepresentation>();
        locations.add(locationAvailability);        
        
    	ConnectApi.OCIGetInventoryAvailabilityOutputRepresentation availability1 = new ConnectApi.OCIGetInventoryAvailabilityOutputRepresentation();
        availability1.locations = locations;
        availability1.locationGroups = new ConnectApi.OCILocationGroupAvailabilityOutputRepresentation[] { locationGroupAvailability };
        
        List<ConnectApi.OCIGetInventoryAvailabilityOutputRepresentation> inventoryAvailabilityList = new List<ConnectApi.OCIGetInventoryAvailabilityOutputRepresentation>();
        inventoryAvailabilityList.add(availability1);
        

        //Creating Order Summaries Data
        Product2 product1 = fan_B2BTestDataFactory.createProduct('sku1', 'Product1', null);
        Product2 product2 = fan_B2BTestDataFactory.createProduct('sku2', 'Product2', null);
        
        List<OrderItemSummary> orderItemSummaries = new List<OrderItemSummary>();
        OrderItemSummary orderItemSummary1 = new OrderItemSummary();
        orderItemSummary1.QuantityOrdered = 2;
        orderItemSummary1.Product2Id = product1.Id;
        OrderItemSummary orderItemSummary2 = new OrderItemSummary();
        orderItemSummary2.QuantityOrdered = 5;
        orderItemSummary2.Product2Id = product2.Id;
        
        orderItemSummaries.add(orderItemSummary1);
        orderItemSummaries.add(orderItemSummary2);
       
        
        //Creating Input
        BuilderRepresentationInput input1 = new BuilderRepresentationInput();
        input1.inventoryAvailabilityList = inventoryAvailabilityList;
        input1.orderItemSummaries = orderItemSummaries;
        input1.maximumSplits = 2;
        
        inputs.add(input1);
        
    	return inputs;   
    }       
}