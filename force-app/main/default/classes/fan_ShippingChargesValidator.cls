public with sharing class fan_ShippingChargesValidator {

    @TestVisible
    static OrderItemSummary[] testOrderItemSummaries;

    @InvocableMethod
    public static List<OrderItemSummary[]> validateShippingCharges(Input[] inputs) {

        Input input = inputs[0];
        Set<String> productIds = new Set<String>();
        fan_ShippingCalculator.Product[] products = new List<fan_ShippingCalculator.Product>();
        OrderItemSummary[] orderItemSummaries = new List<OrderItemSummary>();
        Map<String, OrderItemSummary> orderItemSummaryById = new Map<String, OrderItemSummary>(input.orderItemSummaries);
        Map<String, OrderItemSummary> shippingCharges = new Map<String, OrderItemSummary>();

        for (OrderItemSummary orderItemSummary : Test.isRunningTest() ? testOrderItemSummaries :
                                                    [SELECT TypeCode, Product2Id, fan_OrderSegmentationGroup__c, OriginalOrderItem.fan_PaymentCondition__c,
                                                        Quantity, OrderDeliveryGroupSummaryId, AdjustedLineAmount FROM OrderItemSummary
                                                        WHERE OrderDeliveryGroupSummaryId = :input.orderDeliveryGroupSummaryId AND Quantity > 0]) {

            if(orderItemSummary.TypeCode == fan_Constants.OrderItemSummaryTypeCode.PRODUCT.name()) {
                productIds.add(orderItemSummary.Product2Id);
                products.add(new fan_ShippingCalculator.Product(orderItemSummary));
            } else if(orderItemSummary.TypeCode == fan_Constants.OrderItemSummaryTypeCode.CHARGE.name()) {
                String key = orderItemSummary.fan_OrderSegmentationGroup__c + ':' + orderItemSummary.OriginalOrderItem.fan_PaymentCondition__c;
                shippingCharges.put(key, orderItemSummary);
            }
        }

        if(input.OrderSummary.SalesStoreId == fan_IdTienda__mdt.getInstance(fan_Constants.StoreDeveloperName.POSVENTA.name().toLowerCase()).fan_IdTienda__c) {
            orderItemSummaries = managePosventaShippingCosts(input, orderItemSummaryById, shippingCharges, productIds, products);
        } else if(input.OrderSummary.SalesStoreId == fan_IdTienda__mdt.getInstance(fan_Constants.StoreDeveloperName.MOTOS.name().toLowerCase()).fan_IdTienda__c) {
            orderItemSummaries = manageMotosShippingCosts(input, orderItemSummaryById, shippingCharges, productIds, products);
        }
        return new List<OrderItemSummary[]> { orderItemSummaries };
    }

    static OrderItemSummary[] manageMotosShippingCosts(Input input, Map<String, OrderItemSummary> orderItemSummaryById, Map<String, OrderItemSummary> shippingCharges, Set<String> productIds, fan_ShippingCalculator.Product[] products) {

        Map<String, Decimal> shippingCosts = new fan_MotosShippingCalculator().calculateShipping(input.orderSummary.AccountId, input.orderSummary.SalesStoreId, productIds, products);
        OrderItemSummary shippingCharge;
        Decimal shippingCost = shippingCosts.get(input.orderDeliveryGroupSummaryId);

        if(!shippingCharges.isEmpty()) {
            shippingCharge = shippingCharges.values()[0];
        }

        // Decrease shipping charge amount.
        if(shippingCharge != null && shippingCharge.AdjustedLineAmount != shippingCost) {
            if(shippingCost == null || shippingCost == 0) {
                shippingCost = shippingCharge.AdjustedLineAmount;
                orderItemSummaryById.remove(shippingCharge.Id);
            } else {
                shippingCost = shippingCharge.AdjustedLineAmount - shippingCost;
            }

            ConnectApi.AdjustOrderItemSummaryInputRepresentation adjustOrderItemSummaryInput = new ConnectApi.AdjustOrderItemSummaryInputRepresentation();
            adjustOrderItemSummaryInput.adjustItems = new ConnectApi.AdjustItemInputRepresentation[] { buildAdjustItemInput(shippingCharge.Id, shippingCost) };

            if(!Test.isRunningTest()) ConnectApi.OrderSummary.adjustSubmit(input.OrderSummary.Id, adjustOrderItemSummaryInput);
        }
        return orderItemSummaryById.values();
    }

    static OrderItemSummary[] managePosventaShippingCosts(Input input, Map<String, OrderItemSummary> orderItemSummaryById, Map<String, OrderItemSummary> shippingCharges, Set<String> productIds, fan_ShippingCalculator.Product[] products) {

        Map<String, Decimal> shippingCosts = new fan_PosventaShippingCalculator().calculateShipping(input.orderSummary.AccountId, input.orderSummary.SalesStoreId, productIds, products);
        OrderItemSummary[] shippingChargesToIncreaseAmount = new List<OrderItemSummary>();

        ConnectApi.AdjustOrderItemSummaryInputRepresentation adjustOrderItemSummaryInput = new ConnectApi.AdjustOrderItemSummaryInputRepresentation();
        adjustOrderItemSummaryInput.adjustItems = new List<ConnectApi.AdjustItemInputRepresentation>();

        for (String identifier : shippingCharges.keySet()) {
            OrderItemSummary shippingCharge = shippingCharges.get(identifier);
            Decimal shippingCost = shippingCosts.get(identifier);

            if(shippingCharge.AdjustedLineAmount < shippingCost) {
                // Increase shipping charge amount.
                shippingCharge.fan_ShippingExtraAmount__c = shippingCost - shippingCharge.AdjustedLineAmount;
                shippingChargesToIncreaseAmount.add(shippingCharge);
            } else if(shippingCharge.AdjustedLineAmount != shippingCost) {
                // Decrease shipping charge amount.
                if(shippingCost == null || shippingCost == 0) {
                    shippingCost = shippingCharge.AdjustedLineAmount;
                    orderItemSummaryById.remove(shippingCharge.Id);
                } else {
                    shippingCost = shippingCharge.AdjustedLineAmount - shippingCost;
                }
                adjustOrderItemSummaryInput.adjustItems.add(buildAdjustItemInput(shippingCharge.Id, shippingCost));
            }
        }

        if(!adjustOrderItemSummaryInput.adjustItems.isEmpty() && !Test.isRunningTest()) {
            ConnectApi.OrderSummary.adjustSubmit(input.OrderSummary.Id, adjustOrderItemSummaryInput);
        }
        if(!shippingChargesToIncreaseAmount.isEmpty()) {
            UPDATE shippingChargesToIncreaseAmount;
        }
        return orderItemSummaryById.values();
    }

    static ConnectApi.AdjustItemInputRepresentation buildAdjustItemInput(String shippingChargeId, Decimal shippingCost) {
        ConnectApi.AdjustItemInputRepresentation adjustItemInput = new ConnectApi.AdjustItemInputRepresentation();
        adjustItemInput.orderItemSummaryId = shippingChargeId;
        adjustItemInput.amount = -shippingCost;
        adjustItemInput.reason = 'Otros';
        adjustItemInput.adjustmentType = 'AmountWithoutTax';
        return adjustItemInput;
    }

    public class Input {
        @InvocableVariable(required=true)
        public OrderSummary orderSummary;
        @InvocableVariable(required=true)
        public String orderDeliveryGroupSummaryId;
        @InvocableVariable(required=true)
        public OrderItemSummary[] orderItemSummaries;
    }
}