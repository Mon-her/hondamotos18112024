@isTest
public class fan_OCIGetAvailabilityFlowTest {
    
  @isTest
    static void test(){
        
        ConnectApi.OCIGetInventoryAvailabilityOutputRepresentation testProductDetail = new 
            ConnectApi.OCIGetInventoryAvailabilityOutputRepresentation();
        
        List<ConnectApi.OCILocationAvailabilityOutputRepresentation> lstLocation = new List<ConnectApi.OCILocationAvailabilityOutputRepresentation>();   
        List<ConnectApi.OCILocationGroupAvailabilityOutputRepresentation> lstLocationGroup = new List<ConnectApi.OCILocationGroupAvailabilityOutputRepresentation>();
        
        ConnectApi.OCILocationAvailabilityOutputRepresentation location = new ConnectApi.OCILocationAvailabilityOutputRepresentation();
        ConnectApi.OCILocationGroupAvailabilityOutputRepresentation locationGroup = new ConnectApi.OCILocationGroupAvailabilityOutputRepresentation();
        
        List<ConnectApi.OCIInventoryRecordOutputRepresentation> lstInventory = new List<ConnectApi.OCIInventoryRecordOutputRepresentation>();
        ConnectApi.OCIInventoryRecordOutputRepresentation inventory = new ConnectApi.OCIInventoryRecordOutputRepresentation();
        
        inventory.availableToFulfill = 100;
        inventory.availableToOrder = 100;
        inventory.onHand = 100;
        inventory.reserved = 0;
        inventory.safetyStockCount = 0;
        inventory.stockKeepingUnit = 'SKUTEST';
        lstInventory.add(inventory);
        
        locationGroup.locationGroupIdentifier = 'LOCATIONTEST';
        locationGroup.inventoryRecords = lstInventory;
        lstLocationGroup.add(locationGroup);
        
        location.locationIdentifier = 'LOCATIONTESTINV';
        location.inventoryRecords = lstInventory;
        lstLocation.add(location);
        
        testProductDetail.locations = lstLocation;
        testProductDetail.locationGroups = lstLocationGroup;
        
        fan_OCIGetAvailabilityAbstract.testOutputRepresentation = testProductDetail;
        
        List<fan_OCIGetAvailabilityFlow.Request> lstRequest = new List<fan_OCIGetAvailabilityFlow.Request>();
        
        fan_OCIGetAvailabilityFlow.Request request = new fan_OCIGetAvailabilityFlow.Request();
        request.location_group = 'TESTLOCAL';
        request.Stock_keeping_units = 'SKUTEST';
        lstRequest.add(request);
        
        fan_OCIGetAvailabilityFlow.getAvailability(lstRequest);
        
    }
    
}