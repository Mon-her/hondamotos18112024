@IsTest
class fan_PricesSchedulerTest {

    @TestSetup
    static void makeData(){
        fan_B2BTestDataFactory.createServiceEndpoint('fanalca', 'https://fanalca.com');
    }

    @IsTest
    static void execute() {
        Test.setMock(WebServiceMock.class, new fan_PricebookMock());
        Test.startTest();
        String chron = '0 0 23 * * ?';
        System.schedule('Validate price book entries', chron, new fan_PricesScheduler());
        Test.stopTest();
    }
}