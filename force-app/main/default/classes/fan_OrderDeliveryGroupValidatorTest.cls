@IsTest
class fan_OrderDeliveryGroupValidatorTest {

    @IsTest
    static void validatOrderDeliveryGroups() {

        Schema.Location location = fan_B2BTestDataFactory.createLocation('Location', 'Location-1', true);
        Account account = fan_B2BTestDataFactory.createAccount('1537786428', 'NIT');

        fan_OrderDeliveryGroupValidator.testAttachedToId = fan_B2BTestDataFactory.createOrder(account.Id, Test.getStandardPricebookId()).Id; // Some Id
        fan_OrderDeliveryGroupValidator.testOrderItemSummaries = generateOrderItemSummaries(location);
        fan_OrderDeliveryGroupValidator.validatOrderDeliveryGroups(new String[] { null });
    }

    static OrderItemSummary[] generateOrderItemSummaries(Schema.Location location) {
        JSONGenerator generator = JSON.createGenerator(false);
        generator.writeStartArray();
            generator.writeObject(new Map<String, String> {
                'ReservedAtLocationId' => location.Id,
                'TypeCode' => fan_Constants.OrderItemSummaryTypeCode.PRODUCT.name()
            });
            generator.writeObject(new Map<String, String> {
                'TypeCode' => fan_Constants.OrderItemSummaryTypeCode.PRODUCT.name(),
                'StockKeepingUnit' => 'SKU-1'
            });
        generator.writeEndArray();
        generator.close();
        return (OrderItemSummary[]) JSON.deserialize(generator.getAsString(), OrderItemSummary[].class);
    }
}