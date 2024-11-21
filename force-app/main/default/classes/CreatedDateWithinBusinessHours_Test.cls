@isTest
public class CreatedDateWithinBusinessHours_Test {
 static testMethod void validateCDBusinessHours() {
        List<CreatedDateWithinBusinessHours.Requests> requestList = new List<CreatedDateWithinBusinessHours.Requests>();
        CreatedDateWithinBusinessHours.Requests req = new CreatedDateWithinBusinessHours.Requests();
        req.inputCreatedDateTime = system.now();
     	req.FlowBusinessHours = 'Motos Service';
        requestList.add(req);
        Test.startTest();
        List<CreatedDateWithinBusinessHours.Results> responseList = CreatedDateWithinBusinessHours.execute(requestList);
        Test.stopTest();
        system.assert(responseList.size()>0);
    }
}