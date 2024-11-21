@IsTest
class fan_RenewBackorderTest {

    @IsTest
    static void start() {
        Test.startTest();
        System.schedule('Posventa Backorder Test', '0 0 * * * ?', new fan_RenewBackorder()); // Schedule to run every hour
        Test.stopTest();
    }

    @IsTest
    static void execute() {

        OrderSummaryRoutingSchedule[] orderSummaryRoutingSchedules = new OrderSummaryRoutingSchedule[]{
            new OrderSummaryRoutingSchedule()
        };
        new fan_RenewBackorder().execute(null, orderSummaryRoutingSchedules);
    }
}