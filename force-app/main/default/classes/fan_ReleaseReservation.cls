public with sharing class fan_ReleaseReservation {

    @TestVisible
    static ConnectApi.OCIReleaseReservationOutputRepresentation testReleaseReservationOutput;

    /** @param inputs will always be expected as a single element. */
    @InvocableMethod(label='Release Reservation' category='Order Management' callout=true)
    public static void releaseReservation(Input[] inputs) {
        Input input = inputs[0];
        Set<String> failedReservationRelease = new Set<String>();

        ConnectApi.OCIReleaseReservationInputRepresentation releaseReservationInput = new ConnectApi.OCIReleaseReservationInputRepresentation();
        releaseReservationInput.releaseRecords = input.releaseReservationSingleInputs;

        ConnectApi.OCIReleaseReservationSingleInputRepresentation[] releaseReservationSingleInputsBatch = new List<ConnectApi.OCIReleaseReservationSingleInputRepresentation>();
        Iterator<ConnectApi.OCIReleaseReservationSingleInputRepresentation> releaseReservationSingleInputsIterator = input.releaseReservationSingleInputs.iterator();

        while (releaseReservationSingleInputsIterator.hasNext()) {

            releaseReservationSingleInputsBatch.add(releaseReservationSingleInputsIterator.next());

            if(releaseReservationSingleInputsBatch.size() == 100 || !releaseReservationSingleInputsIterator.hasNext()) {
                ConnectApi.OCIReleaseReservationOutputRepresentation releaseReservationOutput = Test.isRunningTest() ? testReleaseReservationOutput : ConnectApi.OmnichannelInventoryService.releaseReservation(releaseReservationInput);

                if(releaseReservationOutput.errors.size() > 0){
                    for (ConnectApi.OCIReleaseReservationErrorOutputRepresentation releaseReservationErrorOutput : releaseReservationOutput.errors) {
                        failedReservationRelease.add(releaseReservationErrorOutput.details.stockKeepingUnit + ': ' + releaseReservationErrorOutput.message);
                    }
                }
                releaseReservationSingleInputsBatch.clear();
            }
        }

        if(!failedReservationRelease.isEmpty()) {
            throw new FlowException(Label.fan_ReleaseReservationsErrorMessage + ' ' + failedReservationRelease.toString());
        }
    }

    public class Input {
        @InvocableVariable
        public ConnectApi.OCIReleaseReservationSingleInputRepresentation[] releaseReservationSingleInputs;
    }
}