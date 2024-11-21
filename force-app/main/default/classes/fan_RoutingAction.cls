public with sharing class fan_RoutingAction {
    public fan_RoutingAction() {
        
    }
    
    @InvocableMethod(label='Generate Interaction Order Summary Data' description='Generate Interaction Order Summary Data' category='Order Management')
    public static List<RoutingActionResult> generateRoutingData(List<RoutingActionInput> inputs){
        
        Map<String, Decimal> locationGroupAvailability = new Map<String, Decimal>();
        List<RoutingActionResult> results = new List<RoutingActionResult>();
        Set<ID> locationGroupSet = new Set<ID>();
        
        for (RoutingActionInput input : inputs) {
            locationGroupSet.addAll(input.locationGroupIds);
        }
        
        List<Schema.LocationGroupAssignment> locationGroupAssignments = [SELECT LocationId, LocationExternalReference  
                                                                         FROM LocationGroupAssignment 
                                                                         WHERE LocationGroupId  IN: locationGroupSet];
        
        Map<String,Schema.LocationGroupAssignment> mapLocation = new Map<String,Schema.LocationGroupAssignment>();
        for (Schema.LocationGroupAssignment locationGroupAssignment : locationGroupAssignments) {
            if (!mapLocation.containsKey(locationGroupAssignment.LocationExternalReference)) {
                mapLocation.put(locationGroupAssignment.LocationExternalReference,locationGroupAssignment);
            }
        }
        
        for (RoutingActionInput input : inputs) {
            
            RoutingActionResult result = new RoutingActionResult();
            RoutingActionOutput output = new RoutingActionOutput();
            
            Map<String,List<ConnectApi.OCILocationAvailabilityOutputRepresentation>> locationInvtMap = 
                new  Map<String,List<ConnectApi.OCILocationAvailabilityOutputRepresentation>>();
            
            for (ConnectApi.OCIGetInventoryAvailabilityOutputRepresentation inventory : input.inventoryAvailabilityList) {
                for (ConnectApi.OCILocationAvailabilityOutputRepresentation location : inventory.locations) {
                    if (input.rankAvailableLocationsToFulfill.contains(location.locationIdentifier)) {
                        
                        if (locationInvtMap.containsKey(location.locationIdentifier)) {
                            locationInvtMap.get(location.locationIdentifier).add(location);
                        } else {
                            List<ConnectApi.OCILocationAvailabilityOutputRepresentation> listInv = 
                                new List<ConnectApi.OCILocationAvailabilityOutputRepresentation>();
                            listInv.add(location);
                            locationInvtMap.put(location.locationIdentifier,listInv);
                        }
                        
                    }
                }
                
            }
            
            Map<String,RoutingGroup> mapRoutingGroup = new  Map<String,RoutingGroup>();
            Map<String, Set<String>> orderSegmentationGroupsByLocation = new Map<String, Set<String>>();
            Map<String, OrderItemSummary[]> deliveryChargesBySegmentationGroup = new Map<String, OrderItemSummary[]>();

            for (ConnectApi.OCIGetInventoryAvailabilityOutputRepresentation inventory : input.inventoryAvailabilityList) {
                for (ConnectApi.OCILocationGroupAvailabilityOutputRepresentation locationGroup : inventory.locationGroups) {
                    for (ConnectApi.OCIInventoryRecordOutputRepresentation inventoryRecord : locationGroup.inventoryRecords) {
                        locationGroupAvailability.put(inventoryRecord.stockKeepingUnit, inventoryRecord.availableToFulfill);
                    }
                }
            }
            
            for (OrderItemSummary orderItemSummary : input.orderItemSummaries) {
                Double missingQuantityToFulfill = orderItemSummary.QuantityAvailableToFulfill;
                String orderSegmentationGroup = orderItemSummary.fan_OrderSegmentationGroup__c;
                
                if (orderItemSummary.Type == 'Delivery Charge') {
                    OrderItemSummary[] deliveryCharges = deliveryChargesBySegmentationGroup.containsKey(orderSegmentationGroup)
                    ? deliveryChargesBySegmentationGroup.get(orderSegmentationGroup)
                    : new List<OrderItemSummary>();

                    deliveryCharges.add(orderItemSummary);
                    deliveryChargesBySegmentationGroup.put(orderSegmentationGroup, deliveryCharges);
                } else {
                    for (String rankAvailableLocationToFulfill : input.rankAvailableLocationsToFulfill) {
                        List<ConnectApi.OCILocationAvailabilityOutputRepresentation> locations = locationInvtMap.get(rankAvailableLocationToFulfill);
                        ID currentLocationId = mapLocation.get(rankAvailableLocationToFulfill).LocationId;
                        for (ConnectApi.OCILocationAvailabilityOutputRepresentation location : locations) {
                            
                            for (ConnectApi.OCIInventoryRecordOutputRepresentation inventoryRecord : location.inventoryRecords) {
                                Decimal availableToFulfill = Math.min(inventoryRecord.availableToFulfill, locationGroupAvailability.get(inventoryRecord.stockKeepingUnit));
                                if (inventoryRecord.stockKeepingUnit == orderItemSummary.StockKeepingUnit && 
                                    availableToFulfill > 0 && 
                                    missingQuantityToFulfill > 0.0) {
                                        
                                        RoutingItem routingItem = new RoutingItem();
                                        routingItem.reservedAtLocationId = orderItemSummary.ReservedAtLocationId;
                                        routingItem.orderItemSummaryId = orderItemSummary.Id;
                                        
                                        if (availableToFulfill >= missingQuantityToFulfill ) {
                                            routingItem.quantity = missingQuantityToFulfill;
                                            missingQuantityToFulfill = 0.0;
                                        } else {
                                            routingItem.quantity = availableToFulfill;
                                            missingQuantityToFulfill = missingQuantityToFulfill - availableToFulfill;
                                        }
                                        
                                        if (mapRoutingGroup.containsKey(currentLocationId)) {
                                            RoutingGroup rg = mapRoutingGroup.get(currentLocationId);
                                            rg.routingItems.add(routingItem);
                                        } else {
                                            RoutingGroup rg = new RoutingGroup();
                                            rg.routingItems = new List<RoutingItem>();
                                            rg.fulfillFromLocationId = currentLocationId;
                                            rg.routingItems.add(routingItem);
                                            mapRoutingGroup.put(currentLocationId,rg);
                                        }

                                        if(orderSegmentationGroupsByLocation.containsKey(currentLocationId)) {
                                            orderSegmentationGroupsByLocation.get(currentLocationId).add(orderSegmentationGroup);
                                        } else {
                                            orderSegmentationGroupsByLocation.put(currentLocationId, new Set<String> { orderSegmentationGroup });
                                        }
                                    }
                            }
                        }
                    }
                }
            }
            
            for (String location : orderSegmentationGroupsByLocation.keySet()) {
                for (String orderSegmentationGroup : orderSegmentationGroupsByLocation.get(location)) {
                    Iterator<OrderItemSummary> deliveryCharges = deliveryChargesBySegmentationGroup.remove(orderSegmentationGroup)?.iterator();
                    while (deliveryCharges?.hasNext() == true) {
                        OrderItemSummary deliveryCharge = deliveryCharges.next();
                        RoutingItem routingItem = new RoutingItem();
                        routingItem.orderItemSummaryId = deliveryCharge.Id;
                        routingItem.quantity = deliveryCharge.QuantityAvailableToFulfill;
                        mapRoutingGroup.get(location).routingItems.add(routingItem);
                    }
                }
            }
            
            output.orderDeliveryGroupSummaryId = input.orderDeliveryGroupSummaryId;
            output.orderSummaryId = input.orderSummaryId;
            output.routingGroupList = mapRoutingGroup.values();
            result.output = output;
            
            results.add(result);
            
        }
        
        return results;
        
    }
}