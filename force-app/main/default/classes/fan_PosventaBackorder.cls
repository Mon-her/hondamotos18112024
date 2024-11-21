public with sharing class fan_PosventaBackorder implements Database.batchable<OrderSummaryRoutingSchedule>, Database.Stateful {

    @TestVisible
    static OrderSummaryRoutingSchedule[] testOrderSummaryRoutingSchedules;
    @TestVisible
    static OrderDeliveryGroupSummary[] testOrderDeliveryGroupSummaries;

    final String LOCATION_GROUP = 'B2B_Posventa';
    final Integer LIMIT_OF_OSRS_RETRIEVED = 75;
    final String[] ORDER_TYPES = new List<String>{ 'RMT_Garantia', 'EMM_Emergencia', 'COU_ImCourier', 'AIR_ImAereo', 'RMT_Normal', 'REM_Remate' };

    Integer numberOfOSRSRetrieved;
    Configuration configuration;

    public fan_PosventaBackorder() {
        this(60);
    }

    public fan_PosventaBackorder(final Integer LIMIT_OF_ACTIVE_OSRS) {
        this(new Configuration(LIMIT_OF_ACTIVE_OSRS));
    }

    fan_PosventaBackorder(Configuration configuration) {
        this.configuration = configuration;
    }

    public Iterable<OrderSummaryRoutingSchedule> start(Database.BatchableContext BC) {

        OrderSummaryRoutingSchedule[] orderSummaryRoutingSchedules = Test.isRunningTest()
            ? testOrderSummaryRoutingSchedules
            : [SELECT OrderDeliveryGroupSummaryId__c FROM OrderSummaryRoutingSchedule
                WHERE (OrderSummary.OriginalOrder.fan_FormaPago__c = :fan_Constants.FormaPago.CREDITO.name() OR OrderSummary.OriginalOrder.fan_EsAnticipo__c = true)
                AND fan_OrderProcessed__c = false
                AND OrderSummary.SalesStore.Name = :fan_Constants.StoreDeveloperName.POSVENTA.name()
                AND OrderSummary.Status = :fan_Constants.OrderSummaryStatus.APROBADO.name()
                AND ScheduleStatus = 'SCHEDULED'
                AND fan_Step__c IN (null, 'Validate Availability', 'Create OCI Interaction Order Summaries')
                AND OrderSummaryId IN (SELECT OrderSummaryId FROM OrderItemSummary WHERE fan_IsBackorder__c = true AND QuantityAvailableToFulfill > 0)
                AND OrderSummary.fan_TipoPedido__c = :ORDER_TYPES[configuration.orderTypeIndex]
                ORDER BY CreatedDate LIMIT :LIMIT_OF_OSRS_RETRIEVED];

        numberOfOSRSRetrieved = orderSummaryRoutingSchedules.size();
        return orderSummaryRoutingSchedules;
    }

    public void execute(Database.BatchableContext bc, OrderSummaryRoutingSchedule[] orderSummaryRoutingSchedules) {

        OrderSummaryRoutingSchedule[] orderSummaryRoutingSchedulesToUpdate = new List<OrderSummaryRoutingSchedule>();
        Map<String, OrderDeliveryGroupSummary> orderDeliveryGroupSummaries = new Map<String, OrderDeliveryGroupSummary>();
        Map<String, fan_InventoryHandler.Product> products = collectOriginalProducts(orderSummaryRoutingSchedules, orderDeliveryGroupSummaries);
        includeSubstituteProducts(products);

        // Collect skus to request availability.
        Map<String, fan_InventoryHandler.Product> productsToRequest = new Map<String, fan_InventoryHandler.Product>();
        for (OrderSummaryRoutingSchedule orderSummaryRoutingSchedule : orderSummaryRoutingSchedules) {

            String orderDeliveryGroupId = orderSummaryRoutingSchedule.OrderDeliveryGroupSummaryId__c;
            Map<String, fan_InventoryHandler.Product> productsToAdd = new Map<String, fan_InventoryHandler.Product>();

            for (OrderItemSummary orderItemSummary : orderDeliveryGroupSummaries.get(orderDeliveryGroupId).OrderItemSummaries) {
                String sku = orderItemSummary.StockKeepingUnit;

                // Don't override the current availability.
                if(configuration.availability.containsKey(sku)) {
                    continue;
                }
                fan_InventoryHandler.Product product = products.get(sku);
                productsToAdd.put(sku, product);

                for (String substituteSku : product.substitutes) {
                    productsToAdd.put(substituteSku, products.get(substituteSku));
                }
            }

            if((productsToRequest.size() + productsToAdd.size()) > 14900) { // 14900 = 149 DML (GetInventoryAvailability * 100 products per request)
                break; // Schedule up to 60 OSRS.
            }
            productsToRequest.putAll(productsToAdd);
            orderSummaryRoutingSchedulesToUpdate.add(orderSummaryRoutingSchedule);
        }
        scheduleRoutingSchedules(orderSummaryRoutingSchedulesToUpdate, productsToRequest, orderDeliveryGroupSummaries);
    }

    Set<String> getOrderDeliveryGroupSummaryIds(OrderSummaryRoutingSchedule[] orderSummaryRoutingSchedules) {

       Set<String> orderDeliveryGroupSummaryIds = new Set<String>();

        for(OrderSummaryRoutingSchedule orderSummaryRoutingSchedule : orderSummaryRoutingSchedules) {
            orderDeliveryGroupSummaryIds.add(orderSummaryRoutingSchedule.OrderDeliveryGroupSummaryId__c);
        }
       return orderDeliveryGroupSummaryIds;
    }

    Map<String, fan_InventoryHandler.Product> collectOriginalProducts(OrderSummaryRoutingSchedule[] orderSummaryRoutingSchedules, Map<String, OrderDeliveryGroupSummary> orderDeliveryGroupSummaries) {
        
        Set<String> orderDeliveryGroupSummaryIds = getOrderDeliveryGroupSummaryIds(orderSummaryRoutingSchedules);
        Map<String, fan_InventoryHandler.Product> products = new Map<String, fan_InventoryHandler.Product>();

        for (OrderDeliveryGroupSummary orderDeliveryGroupSummary : Test.isRunningTest()
                                                                    ? testOrderDeliveryGroupSummaries
                                                                    : [SELECT
                                                                        (SELECT Product2Id, StockKeepingUnit, QuantityAvailableToFulfill, OrderDeliveryGroupSummaryId FROM OrderItemSummaries WHERE fan_IsBackorder__c = true AND QuantityAvailableToFulfill > 0)
                                                                        FROM OrderDeliveryGroupSummary WHERE Id IN :orderDeliveryGroupSummaryIds]) {

            for (OrderItemSummary orderItemSummary : orderDeliveryGroupSummary.OrderItemSummaries) {
                fan_InventoryHandler.Product product = new fan_InventoryHandler.Product();
                products.put(orderItemSummary.StockKeepingUnit, product);
            }
            orderDeliveryGroupSummaries.put(orderDeliveryGroupSummary.Id, orderDeliveryGroupSummary);
        }
        return products;
    }

    // Relate substitutes to the original products.
    void includeSubstituteProducts(Map<String, fan_InventoryHandler.Product> products) {

        for (fan_RelatedProducts__c relatedProduct : [SELECT fan_Source__r.StockKeepingUnit, fan_Target__r.StockKeepingUnit FROM fan_RelatedProducts__c
                                                        WHERE fan_RelationType__c = '3'
                                                        AND fan_Source__r.StockKeepingUnit IN :products.keySet()]) {

            String originalSku = relatedProduct.fan_Source__r.StockKeepingUnit;
            String substituteSku = relatedProduct.fan_Target__r.StockKeepingUnit;

            fan_InventoryHandler.Product original = products.get(originalSku);
            original.substitutes.add(substituteSku);

            fan_InventoryHandler.Product substitute = products.get(substituteSku) ?? new fan_InventoryHandler.Product();
            products.put(substituteSku, substitute);
        }
    }

    void scheduleRoutingSchedules(OrderSummaryRoutingSchedule[] orderSummaryRoutingSchedules, Map<String, fan_InventoryHandler.Product> productsToRequest, Map<String, OrderDeliveryGroupSummary> orderDeliveryGroupSummaries) {

        OrderSummaryRoutingSchedule[] orderSummaryRoutingSchedulesToUpdate = new List<OrderSummaryRoutingSchedule>();

        fan_InventoryHandler inventoryHandler = new fan_InventoryHandler();
        inventoryHandler.requestForAvailability(LOCATION_GROUP, productsToRequest);
        configuration.availability.putAll(productsToRequest); // Fill availability with the new skus requested.

        for (OrderSummaryRoutingSchedule orderSummaryRoutingSchedule : orderSummaryRoutingSchedules) {

            String orderDeliveryGroupId = orderSummaryRoutingSchedule.OrderDeliveryGroupSummaryId__c;
            Boolean isValid = false;

            for (OrderItemSummary orderItemSummary : orderDeliveryGroupSummaries.get(orderDeliveryGroupId).OrderItemSummaries) {
                String sku = orderItemSummary.StockKeepingUnit;
                Decimal availableQuantity = inventoryHandler.extractAvailability(configuration.availability, sku, orderItemSummary.QuantityAvailableToFulfill);

                if(availableQuantity > 0) {
                    isValid = true;
                }
            }

            if(isValid) {
                configuration.numberOfActiveOSRS++;
                orderSummaryRoutingSchedule.fan_Step__c = 'Validate Availability';
                orderSummaryRoutingSchedule.ScheduledDatetime = configuration.scheduleTime = configuration.scheduleTime.addMinutes(1); 
            }
            orderSummaryRoutingSchedule.fan_OrderProcessed__c = true;
            orderSummaryRoutingSchedulesToUpdate.add(orderSummaryRoutingSchedule);

            if(configuration.numberOfActiveOSRS >= configuration.LIMIT_OF_ACTIVE_OSRS) {
                break;
            }
        }
        if(!Test.isRunningTest()) UPDATE orderSummaryRoutingSchedulesToUpdate;
    }

    public void finish(Database.BatchableContext bc) {

        final Integer LIMIT_OF_ACTIVE_OSRS = configuration.LIMIT_OF_ACTIVE_OSRS;
        if(numberOfOSRSRetrieved < LIMIT_OF_OSRS_RETRIEVED) {
            configuration.orderTypeIndex++;
        }

        if(ORDER_TYPES.size() <= configuration.orderTypeIndex) {
            // Nothing else to do.
            return;
        }

        if(configuration.numberOfActiveOSRS < LIMIT_OF_ACTIVE_OSRS) {
            Database.executeBatch(new fan_PosventaBackorder(configuration));
        } else {
            // Execute one minute after the last one scheduled.
            System.scheduleBatch(new fan_PosventaBackorder(LIMIT_OF_ACTIVE_OSRS), 'Posventa backorder - next execution: ' + Datetime.now(), LIMIT_OF_ACTIVE_OSRS + 1);
        }
    }

    class Configuration {
        Integer orderTypeIndex;
        Integer numberOfActiveOSRS;
        final Integer LIMIT_OF_ACTIVE_OSRS;
        Datetime scheduleTime;
        Map<String, fan_InventoryHandler.Product> availability;

        Configuration(final Integer LIMIT_OF_ACTIVE_OSRS) {
            this.LIMIT_OF_ACTIVE_OSRS = LIMIT_OF_ACTIVE_OSRS;
            orderTypeIndex = 0;
            numberOfActiveOSRS = 0;
            scheduleTime = Datetime.now();
            availability = new Map<String, fan_InventoryHandler.Product>();
        }
    }
}