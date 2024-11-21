@IsTest
class fan_CreateReservationTest {

    @IsTest
    static void createReservationTestShouldEndSucessfully() {
        fan_CreateReservation.Input input = new fan_CreateReservation.Input();
        input.interactionOrderSummary = new OCIInteractionOrderSummary__c();

        ConnectApi.OCICreateReservationSingleInputRepresentation createReservationSingleInput = new ConnectApi.OCICreateReservationSingleInputRepresentation();
        createReservationSingleInput.locationGroupIdentifier = 'B2B_Posventa';
        createReservationSingleInput.stockKeepingUnit = '75375';
        createReservationSingleInput.quantity = 1;
        input.createRecords = new ConnectApi.OCICreateReservationSingleInputRepresentation[] { createReservationSingleInput };

        ConnectApi.OCICreateReservationOutputRepresentation createReservationOutput = new ConnectApi.OCICreateReservationOutputRepresentation();
        createReservationOutput.details = new List<ConnectApi.OCICreateReservationSingleOutputRepresentation>();
        fan_CreateReservation.testCreateReservationOutput = createReservationOutput;
        fan_CreateReservation.Output[] oututs = fan_CreateReservation.createReservation(new fan_CreateReservation.Input[] { input});

        Assert.isFalse(oututs[0].createReservationFailed, 'The reservation creation failed.');
    }

    @IsTest
    static void createReservationTestShouldFail() {

        String sku = '75375';

        fan_CreateReservation.Input input = new fan_CreateReservation.Input();
        input.interactionOrderSummary = new OCIInteractionOrderSummary__c();

        ConnectApi.OCICreateReservationSingleInputRepresentation createReservationSingleInput = new ConnectApi.OCICreateReservationSingleInputRepresentation();
        createReservationSingleInput.locationGroupIdentifier = 'B2B_Posventa';
        createReservationSingleInput.stockKeepingUnit = sku;
        createReservationSingleInput.quantity = 1;
        input.createRecords = new ConnectApi.OCICreateReservationSingleInputRepresentation[] { createReservationSingleInput };

        ConnectApi.OCICreateReservationSingleOutputRepresentation createReservationSingleOutput = new ConnectApi.OCICreateReservationSingleOutputRepresentation();
        createReservationSingleOutput.errorCode = 'InsufficientQuantity';
        createReservationSingleOutput.stockKeepingUnit = sku;

        ConnectApi.OCICreateReservationOutputRepresentation createReservationOutput = new ConnectApi.OCICreateReservationOutputRepresentation();
        createReservationOutput.details = new ConnectApi.OCICreateReservationSingleOutputRepresentation[] { createReservationSingleOutput };
        fan_CreateReservation.testCreateReservationOutput = createReservationOutput;
        fan_CreateReservation.Output[] oututs = fan_CreateReservation.createReservation(new fan_CreateReservation.Input[] { input});

        Assert.isTrue(oututs[0].createReservationFailed, 'The reservation creation did not fail.');
    }
}