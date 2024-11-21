@IsTest
public class fan_TestDataGenerator {
	public static void seedLocationData(){
        // Create Locations
        Schema.Location loc1 = new Schema.Location(
                                    Name = 'Loc-1',
                                    LocationType = 'Warehouse',
                                    ShouldSyncWithOci = true,
            						ExternalReference = 'Loc-1'
                                );  
        Schema.Location loc2 = new Schema.Location(
                                    Name = 'Loc-2',
                                    LocationType = 'Warehouse',
                                    ShouldSyncWithOci = true,
            						ExternalReference = 'Loc-2'
                                ); 
        Schema.Location loc3 = new Schema.Location(
                                    Name = 'Loc-3',
                                    LocationType = 'Warehouse',
                                    ShouldSyncWithOci = true,
            						ExternalReference = 'Loc-3'
                                );
        Schema.Location loc4 = new Schema.Location(
                                    Name = 'Loc-4',
                                    LocationType = 'Warehouse',
                                    ShouldSyncWithOci = true,
            						ExternalReference = 'Loc-4'
                                );
        
        List<Schema.Location> locations = new List<Schema.Location>();
        locations.add(loc1); 
        locations.add(loc2);
        locations.add(loc3);
        locations.add(loc4);
        insert locations;                  


        // Create LocationGroups
        List<LocationGroup> locationGroups = createLocationGroups();

        // Create Location Group Assignment
        List<LocationGroupAssignment> assignments = new List<LocationGroupAssignment> {
            new LocationGroupAssignment(
                LocationId = loc1.Id,
                LocationGroupId = locationGroups[0].Id
            ),
            new LocationGroupAssignment(
                LocationId = loc2.Id,
                LocationGroupId = locationGroups[0].Id
            ),
            new LocationGroupAssignment(
                LocationId = loc3.Id,
                LocationGroupId = locationGroups[0].Id
            ),
            new LocationGroupAssignment(
                LocationId = loc4.Id,
                LocationGroupId = locationGroups[1].Id
            )
        };
        insert assignments;

    }
    
    public static List<LocationGroup> createLocationGroups() {
        // Create LocationGroups - Default East and West Warehouse types
        LocationGroup group1 = new LocationGroup(
                                    LocationGroupName = 'East',
                                    ExternalReference = 'East',
                                    ShouldSyncWithOci = true
                                );
        LocationGroup group2 = new LocationGroup(
                                    LocationGroupName = 'West',
                                    ExternalReference = 'West',
                                    ShouldSyncWithOci = true
                                );
        
        List<LocationGroup> locationGroups = new List<LocationGroup>();
        locationGroups.add(group1);
        locationGroups.add(group2);
        insert locationGroups;
        
        return locationGroups;
    }
    
    public static List<String> getLocationGroupIDs() {
        // Query LocationGroups East and West for their IDs
        List<Schema.LocationGroup> locationGroups = [SELECT Id, ExternalReference 
                                                     FROM LocationGroup 
                                                     WHERE ExternalReference  = 'West' OR ExternalReference  = 'East'];
        
        List<String> locationGroupIDs = new List<String>();
        for(LocationGroup locationGroup : locationGroups) {
            locationGroupIDs.add(locationGroup.Id);
        }
        
        System.assertNotEquals(null, locationGroupIDs, 'Location Group IDs should not be null');
        
        return locationGroupIDs;
    }
    
    public static Account getAccount(String name) {
        List<Account> account = [SELECT Id, Name FROM Account WHERE Name =: name LIMIT 1];
        
        if (account.size() == 0) {
            return null;
        }
        
        return account[0];
    }
    
    public static Contact getContact(String accountId) {
        List<Contact> contact = [SELECT Id FROM Contact WHERE AccountId =: accountId LIMIT 1];
        
        if (contact.size() == 0) {
            return null;
        }
        
        return contact[0];
    }
    
    public static List<OrderItemSummary> getOrderItemSummaries(String orderSummaryId) {
        List<OrderItemSummary> orderItemSummaries = [SELECT Id, QuantityOrdered, StockKeepingUnit, 
                                                     Product2Id, OrderSummaryId, QuantityAvailableToFulfill, 
                                                     Type, ReservedAtLocationId, fan_OrderSegmentationGroup__c,
                                                     fan_IsBackorder__c
                                                     FROM OrderItemSummary WHERE OrderSummaryId =: orderSummaryId ];
        
        return orderItemSummaries;
    }
    
    public static List<OrderItemSummary> getOrderItemSummariesByIdList(List<String> orderSummaries) {
        List<OrderItemSummary> orderItemSummaries = [SELECT Id, QuantityOrdered, StockKeepingUnit, 
                                                     Product2Id, OrderSummaryId, QuantityAvailableToFulfill, 
                                                     Type, ReservedAtLocationId FROM OrderItemSummary 
                                                     WHERE OrderSummaryId IN :orderSummaries ];
        
        return orderItemSummaries;
    }

    public static Account createAccount(String name, String email)
    {
      
        Account a = new Account(Name='SFDX Test');
        a.AM_Tipo_de_documento__c = 'CC';
        a.AM_Numero_de_documento__c = '22222222222';
        insert a;
            
        return a;
    }

    public static Contact createContact(String firstName, String lastName, String phoneNumber, String accID)
    {
        Contact con = new Contact(
            FirstName=firstName,
            LastName=lastName,
            Phone=phoneNumber,
            AccountId=accID);

        Database.DMLOptions dml = new Database.DMLOptions(); 
        dml.DuplicateRuleHeader.allowSave = true;
        Database.SaveResult sr = Database.insert(con, dml);
    
        if (sr.isSuccess()) {
            System.debug('Duplicate account has been inserted in Salesforce!');
        }

        System.debug('Contact Test: ' + con);
        
        return con;
    }

    public static SalesChannel createSalesChannel(String channelname)
    {
        SalesChannel sc = new SalesChannel();
        sc.SalesChannelName = channelname;
        
        return sc;
    }

    public static OrderItem createShippingOrderItem(Id orderId, Id product2Id, Id pricebookEntryId, Id orderDeliveryGroupId, Double amount)
    {
        OrderItem oi = new OrderItem();
        oi.OrderId = orderId;
        oi.Quantity = 1;
        oi.UnitPrice = 10;
        oi.Product2id = product2Id;
        oi.PricebookEntryId=pricebookEntryId;
        oi.OrderDeliveryGroupId = orderDeliveryGroupId;
        oi.Description = 'Shipping';
        oi.Type = 'Delivery Charge';
        oi.TotalLineAmount = amount; 
        
        return oi;
    }
    
    public static OrderDeliveryMethod createOrderDeliveryMethod(String name)
    {        
        OrderDeliveryMethod odm = new OrderDeliveryMethod(IsActive = true,
                                                          Name = name);
        
        return odm;
    }
    
    public static OrderDeliveryMethod createOrderDeliveryMethodWithProduct(String name, String externalReference, Product2 shippingProduct) {
        OrderDeliveryMethod odm = new OrderDeliveryMethod(IsActive = true,
                                                          Name = name,
                                                          ReferenceNumber = externalReference,
                                                          ProductId = shippingProduct.Id);
        
        return odm;
    }
    
    public static OrderDeliveryMethod getOrderDeliveryMethod(String externalReference) {
        List<OrderDeliveryMethod> orderDeliveryMethod = [SELECT Id, Name, ReferenceNumber FROM OrderDeliveryMethod WHERE ReferenceNumber =: externalReference LIMIT 1];
        
        if (orderDeliveryMethod.size() == 0) {
            return null;
        }
        
        return orderDeliveryMethod[0];
    }

    public static OrderDeliveryGroup createOrderDeliveryGroup(String orderId, Id orderDeliveryMethodId, 
                                                              String email, String name)
    {
        OrderDeliveryGroup odg = new OrderDeliveryGroup(DeliverToCity = 'Deerfield Beach', 
                                                       DeliverToStreet = '1166 W Newport Center Dr STE 210', 
                                                       DeliverToPostalCode = '33442',
                                                       DeliverToState = 'FL',
                                                       EmailAddress = email,
                                                       OrderId = orderId, 
                                                       DeliverToName = name, 
                                                       OrderDeliveryMethodId = orderDeliveryMethodId);        
        return odg;
    }

    public static OrderItemTaxLineItem createOrderItemTaxLineItem(String orderItemId, Double amount) 
    {
        OrderItemTaxLineItem oit = new OrderItemTaxLineItem(Name = 'Tax',
                                                            Amount = amount,
                                                            Description = 'Some taxes',
                                                            OrderItemId = orderItemId,
                                                            Rate = 1.0,
                                                            type = 'Estimated',
                                                            TaxEffectiveDate = system.today());
        
        
        return oit;
    }
    
    public static Product2 createProduct2(String name, String sku) {
        Product2 p2 = new Product2();
        p2.Name = name;
        p2.StockKeepingUnit = sku;
        
        return p2;
    }
    
    public static Product2 getProduct2(String productId) {
        List<Product2> result = [SELECT Id, Name FROM Product2 WHERE Id =: productId LIMIT 1];
        System.debug('Product Search result for productId=' + productId + ': ' + result);
        if ( result == null || result.size() == 0) {
            return null;
        } else {
            return result[0];
        }
    }
    
    public static PricebookEntry getPricebookEntry(String product2Id) {
        List<PricebookEntry> result = [SELECT Id FROM PricebookEntry WHERE Product2Id =: product2Id LIMIT 1];
        
        if (result.size() == 0) {
            return null;
        }
        
        return result[0];
    }

    public static OrderItem createOrderItem(Id orderId, Id product2Id, Id pricebookEntryId, Id orderDeliveryGroupId, 
                                            Double amount, String reservedAtLocation)
    {
        OrderItem oi = new OrderItem();
        oi.OrderId = orderId;
        oi.Quantity = 2;
        oi.UnitPrice = 240;
        oi.Product2id = product2Id;
        oi.PricebookEntryId=pricebookEntryId;
        oi.OrderDeliveryGroupId = orderDeliveryGroupId;
        oi.Description = 'Some Product';
        oi.TotalLineAmount = amount;
        oi.ReservedAtLocationId = reservedAtLocation;
        oi.Type = 'Order Product';
        
        return oi;
    }

    public static PriceBookEntry createPriceBookEntry(String productId, String priceBookId, Decimal UnitPrice)
    {
       PricebookEntry pbe = new PricebookEntry();
        pbe.Pricebook2Id = priceBookId;
        pbe.Product2Id = productId;
        pbe.UnitPrice = UnitPrice;
        pbe.IsActive = true;

       return pbe ;
    }

    public static Order createOrder(Id accountId, Id pricebook2Id, Id salesChannelId, String email)
    {
        Order o = new Order(Name = 'Order123456', 
                            AccountId = accountId, 
                            EffectiveDate = system.today(), 
                            status = 'Draft',
                            Pricebook2Id = pricebook2Id, 
                            SalesChannelId= salesChannelId,
                            OrderReferenceNumber ='CCS-Standard3', 
                            BillingStreet = '1166 W Newport Center Dr STE 210', 
                            BillingState= 'FL', 
                            BillingCountry = 'US', 
                            BillingPostalCode = '33442', 
                            BillingCity ='Deerfield Beach', 
                            OrderedDate = system.today(),
                            BillingEmailAddress = email);
        
        return o;
    }

    public static String createOrderSummary(String orderId)
    {
        ConnectApi.OrderSummaryInputRepresentation inputRep  = new ConnectApi.OrderSummaryInputRepresentation();
        inputRep.orderId = orderId;
        inputRep.orderLifeCycleType = 'Managed';
        inputRep.name = 'OrderSummary' + orderId;
        
        ConnectApi.OrderSummaryOutputRepresentation outputRep = new ConnectApi.OrderSummaryOutputRepresentation();
        outputRep = connectapi.OrderSummaryCreation.createOrderSummary(inputRep);
        
        return outputRep.orderSummaryId;
    }
    
    public static OCIInteractionOrderSummary__c createInteractionOrderSummary(FulfillmentOrder fo, String orderSummaryId, String orderDeliveryGroupSummaryId, String typeValue, String statusValue) {
        OCIInteractionOrderSummary__c ociOrderSummary = new OCIInteractionOrderSummary__c(
            												OrderSummary__c = orderSummaryId,
                                                        	FulfillmentOrder__c = fo.Id,
            												ConnectionFailAttempts__c = 0,
            												OrderDeliveryGroupSummary__c = orderDeliveryGroupSummaryId,
            												Type__c = typeValue,
                                                        	Status__c = statusValue,
                                                        	Schedule__c = DateTime.now()
                                                    	);
        insert ociOrderSummary;
        return ociOrderSummary;  
    }
    
    public static List<OCIInteractionOrderSummary__c> createBulkInteractionOrderSummary(List<FulfillmentOrder> fulfillmentOrders, String typeValue, String statusValue) {
        List<OCIInteractionOrderSummary__c> interactionOrderSummaryList = new List<OCIInteractionOrderSummary__c>();
        
        for(FulfillmentOrder fo: fulfillmentOrders) {
            String odgs = getOrderSummaryDeliveryGroup(fo.OrderSummaryId);
        	OCIInteractionOrderSummary__c ociOrderSummary = new OCIInteractionOrderSummary__c(
                                                                OrderSummary__c = fo.OrderSummaryId,
                                                                FulfillmentOrder__c = fo.Id,
                                                                ConnectionFailAttempts__c = 0,
                                                                OrderDeliveryGroupSummary__c = odgs,
                                                                Type__c = typeValue,
                                                                Status__c = statusValue,
                                                                Schedule__c = DateTime.now()
                                                            );
            
            interactionOrderSummaryList.add(ociOrderSummary);
        }

        return interactionOrderSummaryList;  
    }
    
    public static OCIInteractionOrderItemSummary__c createInteractionOrderItemSummary(OCIInteractionOrderSummary__c ociOrderSummary, FulfillmentOrder fo, 
                                                                                      String orderItemSummaryId, String typeValue, String statusValue){
        OCIInteractionOrderItemSummary__c ociOrderItemSummary = new OCIInteractionOrderItemSummary__c(
            														Quantity__c = 1,
                                                                	OCIInteractionOrderSummary__c = ociOrderSummary.Id,
                                                                	FulfillmentOrder__c = fo.Id,
                                                                	Type__c = typeValue,
                                                                	Status__c = statusValue,
            														OrderItemSummary__c = orderItemSummaryId
                                                            	);
        insert ociOrderItemSummary;
        return ociOrderItemSummary;
    }
    
    
    public static List<OCIInteractionOrderItemSummary__c> createBulkInteractionOrderItemSummary(List<OCIInteractionOrderSummary__c> ociOrderSummaryList, 
                                                                                                String typeValue, String statusValue){
        List<OCIInteractionOrderItemSummary__c> ociOrderItemSummaryList = new List<OCIInteractionOrderItemSummary__c>();
        
        for(OCIInteractionOrderSummary__c ociOrderSummary: ociOrderSummaryList) {
            List<OrderItemSummary> associatedOrderItemSummaries = getOrderItemSummaries(ociOrderSummary.OrderSummary__c);
            for(OrderItemSummary ois: associatedOrderItemSummaries) {
            	OCIInteractionOrderItemSummary__c ociOrderItemSummary = new OCIInteractionOrderItemSummary__c(
                                                                            Quantity__c = 1,
                                                                            OCIInteractionOrderSummary__c = ociOrderSummary.Id,
                                                                            FulfillmentOrder__c = ociOrderSummary.FulfillmentOrder__c,
                                                                            Type__c = typeValue,
                                                                            Status__c = statusValue,
                                                                            OrderItemSummary__c = ois.Id
                                                                        );
                ociOrderItemSummaryList.add(ociOrderItemSummary);
            }
        }

        return ociOrderItemSummaryList;
    }
    
    
    public static List<OCIInteractionOrderSummary__c> getOCIInteractionOrderSummaryByOrderSummaryId(String orderSummaryId){
        return [SELECT Id, Status__c, Type__c, Schedule__c, FulfillmentOrder__c, OrderSummary__c 
                FROM OCIInteractionOrderSummary__c WHERE OrderSummary__c =: orderSummaryId];
    }
    
    public static String getOrderSummaryDeliveryGroup(String orderSummaryId){
        List<OrderDeliveryGroupSummary> odgs = [SELECT Id  FROM OrderDeliveryGroupSummary WHERE OrderSummaryId =: orderSummaryId LIMIT 1];
        return odgs[0].Id;
    }
    
    public static String getOrderSummaryItems(String orderSummaryId){
        List<OrderItemSummary> ois = [SELECT Id  FROM OrderItemSummary WHERE OrderSummaryId =: orderSummaryId LIMIT 1];
    	return ois[0].Id;
    }
    
    public static List<OrderItemSummary> getOrderSummaryItemList(String orderSummaryId, String productType){
        List<OrderItemSummary> ois = [SELECT Id  FROM OrderItemSummary WHERE OrderSummaryId =: orderSummaryId AND Type =: productType];
    	return ois;
    }
    
    public static OrderSummary getOrderSummaryObject(String orderSummaryId){
        List<OrderSummary> os = [SELECT Id  FROM OrderSummary WHERE Id =: orderSummaryId LIMIT 1];
    	return os[0];
    }
    
    public static List<FulfillmentOrderLineItem> getFulfillOrderLineItemsByFulfillmentOrderList(List<FulfillmentOrder> fulfillmentOrders) {
        return [SELECT Id, FulfillmentOrderId, OrderItemSummaryId, Quantity 
                FROM FulfillmentOrderLineItem 
                WHERE FulfillmentOrderId IN :fulfillmentOrders];
    }
   
    public static FulfillmentOrderLineItem createFulfillOrderLineItem(FulfillmentOrder fo, String orderItemSummaryId){
        FulfillmentOrderLineItem foli = new FulfillmentOrderLineItem(
            								Type = 'Order Product',
            								TypeCode = 'Product',
            								Quantity = 1.0,
            								OriginalQuantity = 1.0,
            								UnitPrice = 100.00,
                                            FulfillmentOrderId = fo.Id,
             								OrderItemSummaryId = orderItemSummaryId
                                        );
        insert foli;
        return foli;
    }
    
    public static FulfillmentOrder createFulfillOrder(OrderDeliveryMethod odm, String orderSummaryId){        
        FulfillmentOrder fo = new FulfillmentOrder(
                                    FulfilledToName = 'test',
                                    DeliveryMethodId = odm.Id,
            						OrderSummaryId = orderSummaryId,
            						status = 'Draft'
                                );
        insert fo;
        return fo;
    }
    
    public static List<FulfillmentOrder> createBulkFulfillOrders(OrderDeliveryMethod odm, List<OrderItemSummary> orderItemSummaries){        
        
        List<FulfillmentOrder> fulfillmentOrders = new List<FulfillmentOrder>();
        List<FulfillmentOrderLineItem> fulfillmentOrderItems = new List<FulfillmentOrderLineItem>();
        
        for(OrderItemSummary ois: orderItemSummaries) {
        	FulfillmentOrder fulfillmentOrder = new FulfillmentOrder(
                                                    FulfilledToName = 'test',
                                                    DeliveryMethodId = odm.Id,
                                                    OrderSummaryId = ois.OrderSummaryId,
                                                    status = 'Draft'
                                                );
            insert fulfillmentOrder;
            fulfillmentOrders.add(fulfillmentOrder);
            
            FulfillmentOrderLineItem foli = new FulfillmentOrderLineItem(
                                                Type = 'Order Product',
                                                TypeCode = 'Product',
                                                Quantity = 1.0,
                                                OriginalQuantity = 1.0,
                                                UnitPrice = 100.00,
                                                FulfillmentOrderId = fulfillmentOrder.Id,
                                                OrderItemSummaryId = ois.Id
                                            );
            fulfillmentOrderItems.add(foli);
        }
        
        //insert fulfillmentOrders;
        insert fulfillmentOrderItems;

        return fulfillmentOrders;
    }
    
    public static OCIInteractionFulfillOrder__c createInteractionFulfillOrder(Integer connectionFailedAttempts,
                                                                              Id fulfillmentOrderId,
                                                                              DateTime schedule, 
                                                                              String status,
                                                                              String fulfillmentType) {
                                                                                  
        OCIInteractionFulfillOrder__c ociInteractionFulfillOrder = new OCIInteractionFulfillOrder__c(ConnectionFailedAttempts__c = connectionFailedAttempts,
                                                                                          			 FulfillmentOrder__c = fulfillmentOrderId,
                                                                                          			 Schedule__c = schedule,
                                                                                           			 Status__c = status,
                                                                                           			 Type__c = fulfillmentType);
        
        insert ociInteractionFulfillOrder;
        
        return ociInteractionFulfillOrder;
    }
    
    public static OCIInteractionFulfillOrderItem__c createInteractionFulfillOrderItem(FulfillmentOrderLineItem fulfillmentOrderItem,
                                                                                      OCIInteractionFulfillOrder__c interactionFulfillOrder,
                                                                                      Decimal quantity,
                                                                                      Id locationGroup,
                                                                                      Id fromLocationGroup) {
                                                                                          
        OCIInteractionFulfillOrderItem__c ociInteractionFulfillOrderItem = new OCIInteractionFulfillOrderItem__c(FulfillmentOrderItem__c =fulfillmentOrderItem.Id,
                                                                                                                 OCIInteractionFulfillOrder__c = interactionFulfillOrder.Id,
                                                                                                                 Quantity__c = quantity,
                                                                                                                 Status__c  = interactionFulfillOrder.Status__c,
                                                                                                                 Type__c  = interactionFulfillOrder.Type__c,
                                                                                                                 ToLocationGroup__c = locationGroup,
                                                                                                                 FromLocationGroup__c = fromLocationGroup);
        
        insert ociInteractionFulfillOrderItem;
        
        return ociInteractionFulfillOrderItem;
    }
    
    public static List<OCIInteractionFulfillOrder__c> getOCIInteractionFulfillOrderByFulfillmentOrderId(String fulfillmentOrderId) {
        return [SELECT Id, Status__c, Type__c FROM OCIInteractionFulfillOrder__c WHERE FulfillmentOrder__c =: fulfillmentOrderId];
    }
    
  
    public static ProcessException createProcessException(Id fulfillmentOrderId, String category, String message, Id orderSummaryId, 
                                                          String priority, String severity) {
        ProcessException procEx = new ProcessException(AttachedToId=fulfillmentOrderId, 
                                                       Category=category, 
                                                       Message=message,
                                                       Description=message,
                                                       OrderSummaryId=orderSummaryId,
                                                       Priority=priority,
                                                       Severity=severity,
                                                       Status='New');
        
        insert procEx;
                                                              
        return procEx;
    }
    
    public static List<ProcessException> getProcessExceptionById(String processExceptionId) {
        return [SELECT Id, Status, OrderSummaryId FROM ProcessException WHERE Id =:processExceptionId];
    }
    
    public static List<OrderSummaryRoutingSchedule> getOrderSummaryRoutingScheduleByOrderSummaryId(String orderSummaryId) {
        return [SELECT Id, OrderSummaryId, ScheduleStatus, Reason, ScheduledDatetime, OrderDeliveryGroupSummaryId__c 
                FROM OrderSummaryRoutingSchedule WHERE OrderSummaryId =:orderSummaryId];
    }
    
    public static List<OrderItemSummary> seedOrderItemSummaries(OrderDeliveryMethod odm){
        // Create Product Data
        Product2 p1 = new Product2();
        p1.Name = 'P1';
        p1.StockKeepingUnit = 'sku1'+DateTime.now();
        p1.ProductCode = 'sku2p1';
        insert p1;
        
        Product2 p2 = new Product2();
        p2.Name = 'P2';
        p2.StockKeepingUnit = 'sku2'+DateTime.now();
        p2.ProductCode = 'sku2p2';
        insert p2;
        
        Product2 p3 = createProduct2('Shipping', 'sku3'+DateTime.now());
        p3.ProductCode = 'sku2p3';
        insert p3;
        
        PriceBookEntry pbe1 = createPriceBookEntry(p1.Id, System.Test.getStandardPricebookId(), 1.2);
        insert pbe1;
        PriceBookEntry pbe2 = createPriceBookEntry(p2.Id, System.Test.getStandardPricebookId(), 2.3);
        insert pbe2;
        PriceBookEntry pbe3 = createPriceBookEntry(p3.Id, System.Test.getStandardPricebookId(), 3.2);
        insert pbe3;

        // Test Data for Order
        String firstName = 'Codey';
        String lastName = ' Bear';
        String fullName = firstName + lastName;
        String testEmail = 'test1@salesforce.com';
        String testPhone = '555-555-5777';
		
        Account acc = getAccount(fullName);

        if (acc == null) {
           acc = createAccount(fullName, testEmail); 
        }

        Contact contact =  getContact(acc.Id);
        if (contact == null) {
            contact = createContact(firstName, lastName, testPhone, acc.Id);
        }
        
        Saleschannel sc = createSaleschannel('RoutingTest');

        // Create Order, Order Summary, and retrieve Order Delivery Group Summary
        Order order = createOrder(acc.Id, System.Test.getStandardPricebookId(), sc.Id, testEmail);
        insert order;
        
		OrderDeliveryGroup orderDeliveryGroup = createOrderDeliveryGroup(order.Id, odm.Id, testEmail, fullName);
        insert orderDeliveryGroup;
        
        List<String> locationGroupIDs = getLocationGroupIDs();
        String reservedAtLocation = locationGroupIDs[0];
        
        OrderItem oi1 =  createOrderItem(order.Id, p1.Id, pbe1.Id, orderDeliveryGroup.Id, 200.0d, reservedAtLocation);
        insert oi1;
        OrderItem oi2 =  createOrderItem(order.Id, p2.Id, pbe2.Id, orderDeliveryGroup.Id, 249.0d, reservedAtLocation);
        insert oi2;
        OrderItem oi3 =  createShippingOrderItem(order.Id, p3.Id, pbe3.Id, orderDeliveryGroup.Id, 20.0d);
        insert oi3;
        
        order.Status='Activated';
        update order;
        
        String orderSummaryId = createOrderSummary(order.Id);
        System.debug('Got the ID: '+ orderSummaryId);
        
        System.debug('Order Summary Id: ' + orderSummaryId);
        
        return getOrderItemSummaries(orderSummaryId);
    }
    
}