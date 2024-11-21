/**
 * @description       : Apex class for code coverage of Utilities apex class
 * @author            : ChangeMeIn@UserSettingsUnder.SFDoc
 * @group             : 
 * @last modified on  : 08-19-2024
 * @last modified by  : ChangeMeIn@UserSettingsUnder.SFDoc
**/

@isTest
public class Utilities_Test {
    public static testmethod void testear(){
        Utilities.getTipoDocumentoSAP_To_SF('anything');
        Utilities.getTipoDocumentoSF_To_SAP('anything');
        Utilities.getSalutationSAP_To_SF('anything');
        Utilities.getSalutationSF_To_SAP('anything');
        
        Utilities.getTipoDocumentoSF_To_UNOEE('anything');
        Utilities.getTipoDocumentoUNOEE_To_SF('anything');
    }

    @IsTest
    static void insertLogTest() {
        Log__c log = new Log__c();
        Boolean result = false;

        Test.startTest();
            log.Body__c = 'test';
            log.Web_Service__c = 'test.test';
            log.Response__c = 'OK';

            List<Database.SaveResult> results = Utilities.insertLog(new List<Log__c>{log});
            result = results.get(0).isSuccess();
        Test.stopTest();
        
        // Assertion 
        Assert.isTrue(result);
    }
}