@IsTest
class fan_ReservationTransferInvocableTest {

    @IsTest
    static void transferReservation() {

        fan_ReservationTransferInvocable.testInteractionOrderItems = generateInteractionOrderItems();

        ConnectApi.OCITransferReservationOutputRepresentation transferReservationOutput = new ConnectApi.OCITransferReservationOutputRepresentation();
        transferReservationOutput.errors = new List<ConnectApi.OCITransferReservationErrorOutputRepresentation>();
        fan_ReservationTransferInvocable.testTransferReservationOutput = transferReservationOutput;

        fan_ReservationTransferInvocable.Response[] responses = fan_ReservationTransferInvocable.transferReservation(new String[] { null });
        Assert.isFalse(responses[0].hasErrorsFromOutputRepresentation, 'Transfer reservation output has errors.');
    }

    static OCIInteractionOrderItemSummary__c[] generateInteractionOrderItems() {

        JSONGenerator generator = JSON.createGenerator(false);
        generator.writeStartArray();
            generator.writeStartObject();
                generator.writeObjectField('FromLocationGroup__r', new Map<String, String>());
                generator.writeObjectField('OCIInteractionOrderSummary__r', new Map<String, String>());
                generator.writeObjectField('OrderItemSummary__r', new Map<String, String> { 'Type' => 'Order Product'});
                generator.writeNumberField('Quantity__c', 1);
                generator.writeObjectField('ToLocation__r', new Map<String, String>());
            generator.writeEndObject();
        generator.writeEndArray();
        generator.close();
        return (OCIInteractionOrderItemSummary__c[]) JSON.deserialize(generator.getAsString(), OCIInteractionOrderItemSummary__c[].class);
    }
}