@IsTest
public class fan_PricebookJobRegisterTest implements HttpCalloutMock {

    @TestSetup
    static void makeData(){
        fan_B2BTestDataFactory.createServiceEndpoint('fanalca', 'https://fanalca.com');
        INSERT new Contact(LastName = 'Santiago');
    }

    @IsTest
    static void execute() {
        Test.startTest();
        Test.setMock(HttpCalloutMock.class, new fan_PricebookJobRegisterTest());
        fan_PricebookJobRegister.testLinkedEntityId = [SELECT Id FROM Contact].Id;
        System.enqueueJob(new fan_PricebookJobRegister('RMT', '1'));
        Test.stopTest();
    }

    public HttpResponse respond(HttpRequest request) {
        HttpResponse response = new HttpResponse();
        response.setBody('Hello world');
        return response;
    }
}