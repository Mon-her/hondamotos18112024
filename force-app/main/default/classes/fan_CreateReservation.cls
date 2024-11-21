public with sharing class fan_CreateReservation {

    @TestVisible
    static ConnectApi.OCICreateReservationOutputRepresentation testCreateReservationOutput;

    /** @param inputs will always be expected as a single element. */
    @InvocableMethod(label='Create Reservation' category='Order Management' callout=true)
    public static Output[] createReservation(Input[] inputs) {
        Input input = inputs[0];
        Output output = new Output();

        ConnectApi.OCICreateReservationInputRepresentation createReservationInputRepresentation = new ConnectApi.OCICreateReservationInputRepresentation();
        createReservationInputRepresentation.externalRefId = input.interactionOrderSummary.Name;
        createReservationInputRepresentation.allowPartialReservations = false;

        Decimal requestCounter = 0;
        ConnectApi.OCICreateReservationSingleInputRepresentation[] createRecordsBatch = new List<ConnectApi.OCICreateReservationSingleInputRepresentation>();
        Iterator<ConnectApi.OCICreateReservationSingleInputRepresentation> createRecordsIterator = input.createRecords.iterator();

        while (createRecordsIterator.hasNext()) {

            createRecordsBatch.add(createRecordsIterator.next());
            if(createRecordsBatch.size() == 100 || !createRecordsIterator.hasNext()) {

                createReservationInputRepresentation.actionRequestId = input.interactionOrderSummary.Id + '-' + requestCounter++;
                try {
                    createReservationInputRepresentation.createRecords = createRecordsBatch;
                    ConnectApi.OCICreateReservationOutputRepresentation createReservationOutputRepresentation = Test.isRunningTest() ? testCreateReservationOutput : ConnectApi.OmnichannelInventoryService.createReservation(createReservationInputRepresentation);
                    validateCreateReservationOutputRepresentationDetails(createRecordsBatch, createReservationOutputRepresentation, input, output);
                } catch(Exception e) {
                    output.createReservationFailed = true;
                }

                if(output.createReservationFailed) {
                    break;
                }
                createRecordsBatch.clear();
            }
        }
        return new Output[] { output };
    }

    static void validateCreateReservationOutputRepresentationDetails(ConnectApi.OCICreateReservationSingleInputRepresentation[] createRecords, ConnectApi.OCICreateReservationOutputRepresentation createReservationOutputRepresentation, Input input, Output output) {
        Set<String> failedReservations = new Set<String>();

        for(ConnectApi.OCICreateReservationSingleOutputRepresentation createReservationSingleOutput : createReservationOutputRepresentation.details) {
            if(createReservationSingleOutput.errorCode != null) {
                failedReservations.add(createReservationSingleOutput.stockKeepingUnit);
            }
        }

        for (ConnectApi.OCICreateReservationSingleInputRepresentation createReservationSingleInput : createRecords) {
            if(!failedReservations.contains(createReservationSingleInput.stockKeepingUnit)) {
                ConnectApi.OCIReleaseReservationSingleInputRepresentation releaseReservationSingleInput = buildReleaseReservationSingleInputRepresentation(input.interactionOrderSummary, createReservationSingleInput);
                output.releaseReservationSingleInputs.add(releaseReservationSingleInput);
            }
        }
        output.createReservationFailed = !failedReservations.isEmpty();
    }

    static ConnectApi.OCIReleaseReservationSingleInputRepresentation buildReleaseReservationSingleInputRepresentation(OCIInteractionOrderSummary__c interactionOrderSummary, ConnectApi.OCICreateReservationSingleInputRepresentation createReservationSingleInput) {
        ConnectApi.OCIReleaseReservationSingleInputRepresentation releaseReservationSingleInput = new ConnectApi.OCIReleaseReservationSingleInputRepresentation();
        releaseReservationSingleInput.actionRequestId = interactionOrderSummary.Name + '-' + createReservationSingleInput.stockKeepingUnit;
        releaseReservationSingleInput.externalRefId = interactionOrderSummary.Name;
        releaseReservationSingleInput.locationGroupIdentifier = createReservationSingleInput.locationGroupIdentifier;
        releaseReservationSingleInput.stockKeepingUnit = createReservationSingleInput.stockKeepingUnit;
        releaseReservationSingleInput.quantity = createReservationSingleInput.quantity;

        return releaseReservationSingleInput;
    }

    public class Input {
        @InvocableVariable
        public ConnectApi.OCICreateReservationSingleInputRepresentation[] createRecords;
        @InvocableVariable
        public OCIInteractionOrderSummary__c interactionOrderSummary;
    }

    public class Output {
        @InvocableVariable
        public Boolean createReservationFailed = false;
        @InvocableVariable
        public ConnectApi.OCIReleaseReservationSingleInputRepresentation[] releaseReservationSingleInputs = new List<ConnectApi.OCIReleaseReservationSingleInputRepresentation>();
    }
}