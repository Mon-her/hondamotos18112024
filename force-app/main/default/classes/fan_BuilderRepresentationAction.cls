public with sharing  class fan_BuilderRepresentationAction {
    
    public fan_BuilderRepresentationAction() {
        
    }
    
    @InvocableMethod(label='Generate Find Routes With Fewest Splits Input Representation' description='Generate Find Routes With Fewest Splits Input Representation' category='Order Management')
    public static List<BuilderRepresentationResult> generateFindRoutesWithFewestSplitsInput(List<BuilderRepresentationInput> inputs){
 
        List<BuilderRepresentationResult> results = new List<BuilderRepresentationResult>();
        Map<string, decimal> mpRealQty = new Map<string, decimal>();        
        Map<String, Decimal> locationGroupAvailability = new Map<String, Decimal>();
        
        for ( BuilderRepresentationInput input : inputs) {
            
            BuilderRepresentationResult result = new BuilderRepresentationResult();
            BuilderRepresentationOutput output = new BuilderRepresentationOutput();
            
            ConnectApi.FindRoutesWithFewestSplitsInputRepresentation frwfsInput = new ConnectApi.FindRoutesWithFewestSplitsInputRepresentation();
            frwfsInput.locationAvailableInventory = new List<ConnectApi.LocationAvailabilityInputRepresentation>();
            frwfsInput.orderedQuantities = new List<ConnectApi.QuantityWithSkuInputRepresentation>();
            frwfsInput.maximumNumberOfSplits = input.maximumSplits;
            System.debug('Result ------- ' + input.maximumSplits);

            for (ConnectApi.OCIGetInventoryAvailabilityOutputRepresentation inventory : input.inventoryAvailabilityList) {
                for (ConnectApi.OCILocationGroupAvailabilityOutputRepresentation locationGroup : inventory.locationGroups) {
                    for (ConnectApi.OCIInventoryRecordOutputRepresentation inventoryRecord : locationGroup.inventoryRecords) {
                        locationGroupAvailability.put(inventoryRecord.stockKeepingUnit, inventoryRecord.availableToFulfill);
                    }
                }
            }
            
            for (ConnectApi.OCIGetInventoryAvailabilityOutputRepresentation inventory : input.inventoryAvailabilityList) {
                for (ConnectApi.OCILocationAvailabilityOutputRepresentation location : inventory.locations) {
                    for (ConnectApi.OCIInventoryRecordOutputRepresentation inventoryRecord : location.inventoryRecords) {
                        Decimal availableToFulfill = Math.min(inventoryRecord.availableToFulfill, locationGroupAvailability.get(inventoryRecord.stockKeepingUnit));

                        ConnectApi.LocationAvailabilityInputRepresentation locationAvailabilityInputRepresentation = new ConnectApi.LocationAvailabilityInputRepresentation();
                        locationAvailabilityInputRepresentation.externalReferenceId = location.locationIdentifier;
                        locationAvailabilityInputRepresentation.stockKeepingUnit = inventoryRecord.stockKeepingUnit;
                        locationAvailabilityInputRepresentation.quantity = availableToFulfill;
                        frwfsInput.locationAvailableInventory.add(locationAvailabilityInputRepresentation);
                        
                        if(!mpRealQty.containsKey(inventoryRecord.stockKeepingUnit)){
                            mpRealQty.put(inventoryRecord.stockKeepingUnit, availableToFulfill);
                        }
                        else{
                            Decimal prevQty = mpRealQty.get(inventoryRecord.stockKeepingUnit);
                            mpRealQty.put(inventoryRecord.stockKeepingUnit, prevQty + availableToFulfill);
                        }
                    }
                    
                }
            }
            
            for (OrderItemSummary orderItemSummary : input.orderItemSummaries) {
                if (orderItemSummary.Type != 'Delivery Charge') {
                    
                    //Agregado por Wilfredo Burgos para verificar la cantidad real que se puede suplir
                    //BEGIN
                    Decimal realQty = 0;                        
                    if(mpRealQty.containsKey(orderItemSummary.stockKeepingUnit)){
                        if(orderItemSummary.QuantityAvailableToFulfill <= mpRealQty.get(orderItemSummary.StockKeepingUnit)){
                            realQty = orderItemSummary.QuantityAvailableToFulfill;
                        }
                        else{
                            realQty = mpRealQty.get(orderItemSummary.StockKeepingUnit);
                        }
                    } 
                    //END
                    
                    ConnectApi.QuantityWithSkuInputRepresentation qwsInputRep = new ConnectApi.QuantityWithSkuInputRepresentation();
                    qwsInputRep.quantity = realQty; //orderItemSummary.QuantityAvailableToFulfill;
                    qwsInputRep.stockKeepingUnit = orderItemSummary.StockKeepingUnit;
                    frwfsInput.orderedQuantities.add(qwsInputRep);
                }       
            }
            
            output.findRoutesWithFewestSplitsInput = frwfsInput;
            result.builderOutput = output;
            
            results.add(result);                
        }
        return results;
    }   
    
}