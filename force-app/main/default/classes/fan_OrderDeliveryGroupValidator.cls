public with sharing class fan_OrderDeliveryGroupValidator {

    @TestVisible
    static String testAttachedToId;
    @TestVisible
    static OrderItemSummary[] testOrderItemSummaries;

    @InvocableMethod(label='Validar Grupos de Entrega de Pedidos' description='Valida que productos son validos para programar ruta y cuales pueden generar un pedido final' category='Order Management')
    public static Output[] validatOrderDeliveryGroups(String[] orderSummaryIds) {

        ProcessException[] processExceptions = new List<ProcessException>();
        Output[] outputs = new List<Output>();
        Map<String, Boolean> reservedAtLocation = new Map<String, Boolean>();
        Map<String, Map<String, OrderDeliveryGroupSummary>> orderDeliveryGroupSummariesByOrderSummaryId = getOrderDeliveryGroupSummariesByOrderSummaryId(orderSummaryIds, reservedAtLocation);
        updateShouldSyncWithOCIStatus(reservedAtLocation);

        for (String orderSummaryId : orderSummaryIds) {
            ConnectApi.MultipleFulfillmentOrderInputRepresentation multipleFulfillmentOrderInput = new ConnectApi.MultipleFulfillmentOrderInputRepresentation();
            multipleFulfillmentOrderInput.fulfillmentOrders = new List<ConnectApi.FulfillmentOrderInputRepresentation>();

            Output output = new output();
            output.orderDeliveryGroupSummaryIds = new List<String>();
            output.multipleFulfillmentOrderInput = multipleFulfillmentOrderInput;

            for (OrderDeliveryGroupSummary orderDeliveryGroupSummary : orderDeliveryGroupSummariesByOrderSummaryId.containsKey(orderSummaryId)
                                                                        ? orderDeliveryGroupSummariesByOrderSummaryId.get(orderSummaryId).values()
                                                                        : new List<OrderDeliveryGroupSummary>()) {
                validateOrderItemSummaries(orderDeliveryGroupSummary, reservedAtLocation, output, processExceptions);
            }
            outputs.add(output);
        }
        INSERT processExceptions;
        return outputs;
    }

    static Map<String, Map<String, OrderDeliveryGroupSummary>> getOrderDeliveryGroupSummariesByOrderSummaryId(String[] orderSummaryIds, Map<String, Boolean> reservetAtLocation) {

        Map<String, Map<String, OrderDeliveryGroupSummary>> orderDeliveryGroupSummariesByOrderSummaryId = new Map<String, Map<String, OrderDeliveryGroupSummary>>();
        OrderItemSummary[] orderItemSummaries = [SELECT StockKeepingUnit, TypeCode, Quantity, OrderSummaryId, OrderDeliveryGroupSummaryId, ReservedAtLocationId
                                                FROM OrderItemSummary WHERE QuantityAvailableToFulfill > 0 AND TotalPrice > 0 AND OrderSummaryId IN :orderSummaryIds];

        for (OrderItemSummary orderItemSummary : Test.isRunningTest() ? testOrderItemSummaries : orderItemSummaries) {

            String orderSummaryId = orderItemSummary.OrderSummaryId;
            String orderDeliveryGroupSummaryId = orderItemSummary.OrderDeliveryGroupSummaryId;
            reservetAtLocation.put(orderItemSummary.ReservedAtLocationId, false);

            Map<String, OrderDeliveryGroupSummary> orderDeliveryGroupSummaryById = orderDeliveryGroupSummariesByOrderSummaryId.containsKey(orderSummaryId) ? orderDeliveryGroupSummariesByOrderSummaryId.get(orderSummaryId) : new Map<String, OrderDeliveryGroupSummary>();

            OrderDeliveryGroupSummary orderDeliveryGroupSummary = orderDeliveryGroupSummaryById.containsKey(orderDeliveryGroupSummaryId) ? orderDeliveryGroupSummaryById.get(orderDeliveryGroupSummaryId) : new OrderDeliveryGroupSummary(orderDeliveryGroupSummaryId, orderSummaryId);
            orderDeliveryGroupSummary.orderItemSummaries.add(orderItemSummary);
            orderDeliveryGroupSummaryById.put(orderDeliveryGroupSummaryId, orderDeliveryGroupSummary);
            orderDeliveryGroupSummariesByOrderSummaryId.put(orderSummaryId, orderDeliveryGroupSummaryById);
        }
        return orderDeliveryGroupSummariesByOrderSummaryId;
    }

    static void validateOrderItemSummaries(OrderDeliveryGroupSummary orderDeliveryGroupSummary, Map<String, Boolean> reservedAtLocation, Output output, ProcessException[] processExceptions) {
        Id locationId;
        Boolean anyBOPIS = false;
        Boolean hasFault = false;
        Boolean OCISyncEnabled = false;
        Boolean isLocationGroupType = false;

        ConnectApi.FulfillmentGroupInputRepresentation fulfillmentGroupInput = new ConnectApi.FulfillmentGroupInputRepresentation();
        fulfillmentGroupInput.orderItemSummaries = new List<ConnectApi.OrderItemSummaryInputRepresentation>();

        for (OrderItemSummary orderItemSummary : orderDeliveryGroupSummary.orderItemSummaries) {
            if(orderItemSummary.TypeCode == fan_Constants.OrderItemSummaryTypeCode.PRODUCT.name()) {
                if(orderItemSummary.ReservedAtLocationId == null) {
                    String exceptionMessage = buildExceptionMessage(Label.FlowErrors_reservedAtLocationIdIsNotSetErrorMessage, orderItemSummary.StockKeepingUnit);
                    processExceptions.add(buildProcessException(orderDeliveryGroupSummary.orderSummaryId, Label.FlowErrors_reservedAtLocationIdIsNotSetErrorDescription, exceptionMessage));
                    hasFault = true;
                    break;
                }

                if(locationId == null) {
                    locationId = orderItemSummary.ReservedAtLocationId;
                    isLocationGroupType = locationId.getSobjectType() == LocationGroup.getSobjectType();
                    OCISyncEnabled = reservedAtLocation.get(locationId);
                }

                if(orderItemSummary.ReservedAtLocationId != locationId) {
                    String exceptionMessage = buildExceptionMessage(Label.FlowErrors_locationGroupMissMatchErrorMessage, orderItemSummary.StockKeepingUnit);
                    processExceptions.add(buildProcessException(orderDeliveryGroupSummary.orderSummaryId, Label.FlowErrors_locationGroupMissMatchErrorDescription, exceptionMessage));
                    hasFault = true;
                    break;
                }

                if(!OCISyncEnabled) {
                    String exceptionMessage = buildExceptionMessage(Label.FlowErrors_locationGroupIsNotEnabledErrorMessage, locationId);
                    processExceptions.add(buildProcessException(orderDeliveryGroupSummary.orderSummaryId, Label.FlowErrors_locationGroupIsNotEnabledErrorDescription, exceptionMessage));
                    hasFault = true;
                    break;
                }

                if(!isLocationGroupType) {
                    fulfillmentGroupInput.orderItemSummaries.add(buildOrderItemSummaryInput(orderItemSummary.Id, orderItemSummary.Quantity));
                    fulfillmentGroupInput.fulfilledFromLocationId = locationId;
                    anyBOPIS = true;
                }
            } else if(orderItemSummary.TypeCode == fan_Constants.OrderItemSummaryTypeCode.CHARGE.name()) {
                fulfillmentGroupInput.orderItemSummaries.add(buildOrderItemSummaryInput(orderItemSummary.Id, orderItemSummary.Quantity));
            }
        }

        if(!hasFault) {
            if(isLocationGroupType) {
                output.orderDeliveryGroupSummaryIds.add(orderDeliveryGroupSummary.Id);
            }
            if(anyBOPIS) {
                output.anyBOPIS = true;
                ConnectApi.FulfillmentOrderInputRepresentation fulfillmentOrderInput = new ConnectApi.FulfillmentOrderInputRepresentation();
                fulfillmentOrderInput.orderSummaryId = orderDeliveryGroupSummary.orderSummaryId;
                fulfillmentOrderInput.orderDeliveryGroupSummaryId = orderDeliveryGroupSummary.Id;
                fulfillmentOrderInput.fulfillmentGroups = new ConnectApi.FulfillmentGroupInputRepresentation[] { fulfillmentGroupInput };

                output.multipleFulfillmentOrderInput.fulfillmentOrders.add(fulfillmentOrderInput);
            }
        }
    }

    static ConnectApi.OrderItemSummaryInputRepresentation buildOrderItemSummaryInput(String orderItemSummaryId, Decimal quantity) {
        ConnectApi.OrderItemSummaryInputRepresentation orderItemSummaryInput = new ConnectApi.OrderItemSummaryInputRepresentation();
        orderItemSummaryInput.orderItemSummaryId = orderItemSummaryId;
        orderItemSummaryInput.quantity = quantity;

        return orderItemSummaryInput;
    }

    static String buildExceptionMessage(String template, String param) {
        return template.replace('{0}', param);
    }

    static ProcessException buildProcessException(String orderSummaryId, String description, String message) {
        return new ProcessException(
            AttachedToId = Test.isRunningTest() ? testAttachedToId : orderSummaryId,
            Category = fan_Constants.ProcessExceptionCategory.FULFILLMENT.name(),
            Description = description,
            Message = message,
            OrderSummaryId = orderSummaryId,
            Priority = fan_Constants.ProcessExceptionPriority.HIGH.name(),
            Severity = fan_Constants.ProcessExceptionSeverity.HIGH.name(),
            Status = 'New'
        );
    }

    class OrderDeliveryGroupSummary {
        String id;
        String orderSummaryId;
        OrderItemSummary[] orderItemSummaries = new List<OrderItemSummary>();

        public OrderDeliveryGroupSummary(String id, String orderSummaryId) {
            this.id = id;
            this.orderSummaryId = orderSummaryId;
        }
    }

    public class Output {
        @InvocableVariable(label='OrderDeliveryGroupSummaryIds' required=true)
        public String[] orderDeliveryGroupSummaryIds;
        @InvocableVariable(label='MultipleFulfillmentOrderInputList' required=true)
        public ConnectApi.MultipleFulfillmentOrderInputRepresentation multipleFulfillmentOrderInput;
        @InvocableVariable(label='AnyBOPIS' required=true)
        public Boolean anyBOPIS = false;
    }

    static void updateShouldSyncWithOCIStatus(Map<String, Boolean> reservedAtLocation) {
        for (Schema.Location location : [SELECT ShouldSyncWithOci FROM Location WHERE Id =: reservedAtLocation.keySet()]) {
            reservedAtLocation.put(location.Id, location.ShouldSyncWithOci);
        }

        for (LocationGroup locationGroup : [SELECT ShouldSyncWithOci FROM LocationGroup WHERE Id =: reservedAtLocation.keySet()]) {
            reservedAtLocation.put(locationGroup.Id, locationGroup.ShouldSyncWithOci);
        }
    }
}