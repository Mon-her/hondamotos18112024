@IsTest
private class fan_MotosBackorderTest {

    @isTest
    static void testMotosBatchExecution() {

        fan_MotosBackorder.testOrderSummaryRoutingSchedules = new OrderSummaryRoutingSchedule[] {
            new OrderSummaryRoutingSchedule()
        };

        Test.startTest();
        fan_MotosBackorder batchInstance = new fan_MotosBackorder();
        System.schedule('Test Fan Motos Backorder Batch', '0 0 * * * ?', batchInstance); // Schedule to run every hour
        batchInstance.execute(null);
        Test.stopTest();
        
        // Check if batch job is scheduled correctly
       System.assertEquals(1, [SELECT count() FROM CronTrigger WHERE CronJobDetail.Name = 'Test Fan Motos Backorder Batch']);
        
    }
}