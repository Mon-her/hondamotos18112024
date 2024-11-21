public with sharing class fan_ReservationTransferInvocable {

    @TestVisible
    static OCIInteractionOrderItemSummary__c[] testInteractionOrderItems;
    @TestVisible
    static ConnectApi.OCITransferReservationOutputRepresentation testTransferReservationOutput;

    @InvocableMethod(label='Transfer Reservation')
    public static Response[] transferReservation(String[] interactionOrderSummaryIds) {

        Response[] responses = new List<Response>();
        Map<String, OCIInteractionOrderItemSummary__c[]> interactionOrderItemsByInteractionOrderId = getInteractionOrderItemsByInteractionOrderId(interactionOrderSummaryIds);

        String orderProductType = fan_Constants.OrderItemSummaryType.ORDER_PRODUCT.name().replace('_', ' ');
        for (String interactionOrderId : interactionOrderSummaryIds) {
            OCIInteractionOrderItemSummary__c[] interactionOrderItems = interactionOrderItemsByInteractionOrderId.get(interactionOrderId);

            Response response = transferResersation(orderProductType, interactionOrderId, interactionOrderItems);
            responses.add(response);
        }
        return responses;
    }

    static Response transferResersation(String orderProductType, String interactionOrderId, OCIInteractionOrderItemSummary__c[] interactionOrderItems ) {
        ConnectApi.OCITransferReservationInputRepresentation transferReservationInput = new ConnectApi.OCITransferReservationInputRepresentation();
        transferReservationInput.transferRecords = new List<ConnectApi.OCITransferReservationSingleInputRepresentation>();

        Response response = new Response();
        response.interactionOrderItems = interactionOrderItems;
        Decimal numberOfRequest = 0;
        for (Integer i = 0; i < interactionOrderItems.size(); i++) {
            OCIInteractionOrderItemSummary__c interactionOrderItem = interactionOrderItems[i];
            
            if(interactionOrderItem.OrderItemSummary__r.Type == orderProductType && interactionOrderItem.Quantity__c > 0) {
                transferReservationInput.transferRecords.add(buildTransferReservationSingleInput(interactionOrderItem));
            }
            if(transferReservationInput.transferRecords.size() == 100 || i == (interactionOrderItems.size() - 1)) {
                transferReservationInput.allOrNothingTransferId = interactionOrderId + '-' + numberOfRequest++;
                ConnectApi.OCITransferReservationOutputRepresentation transferReservationOutput = Test.isRunningTest() ? testTransferReservationOutput : ConnectApi.OmnichannelInventoryService.transferReservation(transferReservationInput);
                System.debug(transferReservationOutput);
                if(response.hasErrorsFromOutputRepresentation = !transferReservationOutput.errors.isEmpty()) {
                    break;
                }
                transferReservationInput.transferRecords.clear();
            }
        }
        return response;
    }

    static Map<String, OCIInteractionOrderItemSummary__c[]> getInteractionOrderItemsByInteractionOrderId(String[] interactionOrderSummaryIds) {

        Map<String, OCIInteractionOrderItemSummary__c[]> interactionOrderItemsByInteractionOrderId = new Map<String, OCIInteractionOrderItemSummary__c[]>();
        OCIInteractionOrderItemSummary__c[] queriedInteractionOrderItems = [SELECT Quantity__c, FromLocationGroup__r.ExternalReference, ToLocation__r.ExternalReference, OCIInteractionOrderSummary__r.Name,
                                                                            OrderItemSummary__r.Type, OrderItemSummary__r.StockKeepingUnit FROM OCIInteractionOrderItemSummary__c
                                                                            WHERE OCIInteractionOrderSummary__c IN :interactionOrderSummaryIds ORDER BY OCIInteractionOrderSummary__c];

        for (OCIInteractionOrderItemSummary__c interactionOrderItem : Test.isRunningTest() ? testInteractionOrderItems : queriedInteractionOrderItems) {

            String interactionOrderId = interactionOrderItem.OCIInteractionOrderSummary__c;
            OCIInteractionOrderItemSummary__c[] interactionOrderItems = interactionOrderItemsByInteractionOrderId.containsKey(interactionOrderId) ?
            interactionOrderItemsByInteractionOrderId.get(interactionOrderId) : new List<OCIInteractionOrderItemSummary__c>();

            interactionOrderItems.add(interactionOrderItem);
            interactionOrderItemsByInteractionOrderId.put(interactionOrderId, interactionOrderItems);
        }
        return interactionOrderItemsByInteractionOrderId;
    }

    static ConnectApi.OCITransferReservationSingleInputRepresentation buildTransferReservationSingleInput(OCIInteractionOrderItemSummary__c interactionOrderItem) {
        ConnectApi.OCITransferReservationSingleInputRepresentation transferReservationSingleInput = new ConnectApi.OCITransferReservationSingleInputRepresentation();
        transferReservationSingleInput.actionRequestId = interactionOrderItem.Id;
        transferReservationSingleInput.externalRefId = interactionOrderItem.OCIInteractionOrderSummary__r.Name;
        transferReservationSingleInput.fromLocationGroupIdentifier = interactionOrderItem.FromLocationGroup__r.ExternalReference;
        transferReservationSingleInput.toLocationIdentifier = interactionOrderItem.ToLocation__r.ExternalReference;
        transferReservationSingleInput.stockKeepingUnit = interactionOrderItem.OrderItemSummary__r.StockKeepingUnit;
        transferReservationSingleInput.quantity = interactionOrderItem.Quantity__c;
        return transferReservationSingleInput;
    }

    public class Response {
        @InvocableVariable(label='Has Errors From Output Representation')
        public Boolean hasErrorsFromOutputRepresentation = false;
        @InvocableVariable(label='Interaction Order Items' required=true)
        public OCIInteractionOrderItemSummary__c[] interactionOrderItems;
    }

    class ReservationTransferException extends Exception {}
}