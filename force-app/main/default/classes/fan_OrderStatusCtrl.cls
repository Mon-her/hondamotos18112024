public with sharing class fan_OrderStatusCtrl {

    public static final String SERVICE_NAME = 'Fanalca';

    // Tests variables
    public static List<Schema.FulfillmentOrder> ordersTests;
    public static String[] numbersForServiceTest;
    
    @AuraEnabled
    public static List<FulfillmentOrder> getStatusF0s(String effectiveAccountId, String orderSummaryId) {
        FulfillmentOrder[] fulfillmentOrders = new List<FulfillmentOrder>();
        List<Schema.FulfillmentOrder> fulfillmentOrdersQuery = getAccountF0s(orderSummaryId);
        String[] numbersForService;
        for (Schema.FulfillmentOrder order : fulfillmentOrdersQuery) {
            if (numbersForService == null) numbersForService = new String[]{order.FulfillmentOrderNumber}; else numbersForService.add(order.FulfillmentOrderNumber);
            effectiveAccountId = order.Account.ParentId !=  null ? order.Account.ParentId : order.AccountId;
        }
        String accountNumber = [SELECT AccountNumber FROM Account WHERE Id = :effectiveAccountId LIMIT 1].AccountNumber;

        if (Test.isRunningTest()) numbersForService = numbersForServiceTest;
        if (numbersForService != null) {
            Map<String, fan_OrderStatusFOs.row_element> orderRows = new Map<String, fan_OrderStatusFOs.row_element>();
            fan_OrderStatusFOs.row_element[] ordersResponse = makeRequest(accountNumber, numbersForService);
            for (fan_OrderStatusFOs.row_element orderRow : ordersResponse) {
                orderRows.put(orderRow.ORDEN_COMPRA, orderRow);
            }
            System.debug('accountNumber ' + accountNumber);
            System.debug('numbersForService ' + numbersForService);
            for (Schema.FulfillmentOrder fo : fulfillmentOrdersQuery) {
                fan_OrderStatusFOs.row_element orderRow = orderRows.get(fo.FulfillmentOrderNumber);
                fulfillmentOrders.add(new FulfillmentOrder(fo, orderRow));
            }
        }
        return fulfillmentOrders;
    }

    private static List<Schema.FulfillmentOrder> getAccountF0s(String orderSummaryId) {
        List<Schema.FulfillmentOrder> fulfillmentOrders = Test.IsRunningTest() ? ordersTests : [SELECT Id, FulfillmentOrderNumber, FulfilledToName, 
                                                    Status, TotalAmount,AccountId, Account.ParentId FROM FulfillmentOrder WHERE OrderSummaryId = :orderSummaryId];
        return fulfillmentOrders;
    }

    private static fan_ServiceEndpoint__c getSettings() {
        List<fan_ServiceEndpoint__c> settings = [ SELECT usuario__c, contrasena__c, url__c FROM fan_ServiceEndpoint__c WHERE Nombre__c = :SERVICE_NAME];
        if (settings.size() == 0) throw new HandledException('Settings not found to >>> ' + SERVICE_NAME);
    
        return settings[0];
    }

    private static fan_OrderStatusFOs.row_element[] makeRequest(String accountNumber, String[] numbersForService) {
        fan_ServiceEndpoint__c serviceSettings = getSettings();
        fan_OrderStatusFOs.HTTPS_Port service = new fan_OrderStatusFOs.HTTPS_Port(serviceSettings.url__c);
        String headerAuth = 'Basic ' + EncodingUtil.base64Encode(Blob.valueOf(serviceSettings.usuario__c + ':' + serviceSettings.contrasena__c));
        service.inputHttpHeaders_x = new Map<String,String>();
        service.inputHttpHeaders_x.put('Authorization', headerAuth);
        service.inputHttpHeaders_x.put('Content-Type', 'text/xml');
        fan_OrderStatusFOs.row_element[] response;
        try {
            response = service.POST(accountNumber, numbersForService);
        } catch (Exception e) {
            System.debug('Error in makeRequest >>> '+e);
        }
        return response == null ? new fan_OrderStatusFOs.row_element[]{} : response;
    }

    @TestVisible
    class FulfillmentOrder {
        @AuraEnabled
        public String Id;
        @AuraEnabled
        public String FulfillmentOrderNumber;
        @AuraEnabled
        public String FulfilledToName;
        @AuraEnabled
        public Decimal TotalAmount;
        @AuraEnabled
        public String Status;
        @AuraEnabled
        public String GuideNumber;

        FulfillmentOrder(Schema.FulfillmentOrder fulfillmentOrder, fan_OrderStatusFOs.row_element orderRow) {
            Id = fulfillmentOrder.Id;
            FulfillmentOrderNumber = fulfillmentOrder.FulfillmentOrderNumber;
            FulfilledToName = fulfillmentOrder.FulfilledToName;
            TotalAmount = fulfillmentOrder.TotalAmount;
            Status = orderRow == null ? fulfillmentOrder.Status : orderRow.ESTADOI_PICKLIST;
            this.GuideNumber = String.isBlank(orderRow?.NO_GUIA_TRANS) ? Label.fan_unavailable : orderRow.NO_GUIA_TRANS;
        }
    }
}