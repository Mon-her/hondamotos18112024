@IsTest
class fan_ShippingChargesValidatorTest {

    @IsTest
    static void validateMotosShippingCharges() {

        String salesStoreId = fan_IdTienda__mdt.getInstance('motos').fan_IdTienda__c;

        fan_ShippingChargesValidator.Input input = new fan_ShippingChargesValidator.Input();
        input.orderSummary = generateOrderSummary('', salesStoreId);
        input.orderItemSummaries = new List<OrderItemSummary>();

        fan_ShippingChargesValidator.testOrderItemSummaries = generateOrderItemSummaries();
        fan_ShippingChargesValidator.validateShippingCharges(new fan_ShippingChargesValidator.Input[] { input });
    }

    @IsTest
    static void validatePosventaShippingCharges() {

        String salesStoreId = fan_IdTienda__mdt.getInstance('posventa').fan_IdTienda__c;

        fan_ShippingChargesValidator.Input input = new fan_ShippingChargesValidator.Input();
        input.orderSummary = generateOrderSummary('', salesStoreId);
        input.orderItemSummaries = new List<OrderItemSummary>();

        fan_ShippingChargesValidator.testOrderItemSummaries = generateOrderItemSummaries();
        fan_ShippingChargesValidator.validateShippingCharges(new fan_ShippingChargesValidator.Input[] { input });
    }

    static OrderSummary generateOrderSummary(String accountId, String salesStoreId) {
        JSONGenerator jsonGenerator = JSON.createGenerator(false);

        jsonGenerator.writeStartObject();
        jsonGenerator.writeStringField('AccountId', accountId);
        jsonGenerator.writeStringField('SalesStoreId', salesStoreId);
        jsonGenerator.writeEndObject();

        jsonGenerator.close();
        return (OrderSummary) JSON.deserialize(jsonGenerator.getAsString(), OrderSummary.class);
    }

    static OrderItemSummary[] generateOrderItemSummaries() {
        JSONGenerator generator = JSON.createGenerator(false);
        generator.writeStartArray();
            generator.writeObject(new Map<String, Object> {
                'TypeCode' => fan_Constants.OrderItemSummaryTypeCode.PRODUCT.name(),
                'OriginalOrderItem' => new OrderItem(),
                'Quantity' => 1,
                'AdjustedLineAmount' => 10
            });
            generator.writeObject(new Map<String, Object> {
                'TypeCode' => fan_Constants.OrderItemSummaryTypeCode.CHARGE.name(),
                'AdjustedLineAmount' => 3
            });
        generator.writeEndArray();
        generator.close();
        return (OrderItemSummary[]) JSON.deserialize(generator.getAsString(), OrderItemSummary[].class);
    }
}