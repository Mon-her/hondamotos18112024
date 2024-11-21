@IsTest
class fan_ReleaseReservationTest {

    @IsTest
    static void releaseReservationShouldEndSuccessfully() {

        String sku = '75375';

        ConnectApi.OCIReleaseReservationSingleInputRepresentation releaseReservationSingleInput = new ConnectApi.OCIReleaseReservationSingleInputRepresentation();
        releaseReservationSingleInput.stockKeepingUnit = sku;
        releaseReservationSingleInput.quantity = 1;

        fan_ReleaseReservation.Input input = new fan_ReleaseReservation.Input();
        input.releaseReservationSingleInputs = new ConnectApi.OCIReleaseReservationSingleInputRepresentation[] { releaseReservationSingleInput };

        ConnectApi.OCIReleaseReservationOutputRepresentation releaseReservationOutput = new ConnectApi.OCIReleaseReservationOutputRepresentation();
        releaseReservationOutput.errors = new List<ConnectApi.OCIReleaseReservationErrorOutputRepresentation>();

        fan_ReleaseReservation.testReleaseReservationOutput = releaseReservationOutput;
        fan_ReleaseReservation.releaseReservation(new fan_ReleaseReservation.Input[] { input });
    }

    @IsTest
    static void releaseReservationShouldThrowAnException() {

        String sku = '75375';

        ConnectApi.OCIReleaseReservationSingleInputRepresentation releaseReservationSingleInput = new ConnectApi.OCIReleaseReservationSingleInputRepresentation();
        releaseReservationSingleInput.stockKeepingUnit = sku;
        releaseReservationSingleInput.quantity = 1;

        fan_ReleaseReservation.Input input = new fan_ReleaseReservation.Input();
        input.releaseReservationSingleInputs = new ConnectApi.OCIReleaseReservationSingleInputRepresentation[] { releaseReservationSingleInput };

        ConnectApi.OCIReleaseReservationSingleOutputRepresentation releaseReservationSingleOutput = new ConnectApi.OCIReleaseReservationSingleOutputRepresentation();
        releaseReservationSingleOutput.stockKeepingUnit = sku;
        
        ConnectApi.OCIReleaseReservationErrorOutputRepresentation releaseReservationErrorOutput = new ConnectApi.OCIReleaseReservationErrorOutputRepresentation();
        releaseReservationErrorOutput.details = releaseReservationSingleOutput;
        releaseReservationErrorOutput.message = 'Insufficient Quantity';

        ConnectApi.OCIReleaseReservationOutputRepresentation releaseReservationOutput = new ConnectApi.OCIReleaseReservationOutputRepresentation();
        releaseReservationOutput.errors = new ConnectApi.OCIReleaseReservationErrorOutputRepresentation[] { releaseReservationErrorOutput };

        try {
            fan_ReleaseReservation.testReleaseReservationOutput = releaseReservationOutput;
            fan_ReleaseReservation.releaseReservation(new fan_ReleaseReservation.Input[] { input });
        } catch (Exception e) {
            Assert.areEqual('No fue posible liberar reservas. {75375: Insufficient Quantity}', e.getMessage(), 'The exception message is not as expected.');
        }
    }
}