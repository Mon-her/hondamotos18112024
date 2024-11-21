@isTest
public class ContactTriggerHandler_Test {
    private static testmethod void testear(){
        TestDataUtilityClass.crearCuentasAutos(1, Label.AutosRecordTypeDevNameAccountJuridica);
        
        Contact c = new Contact(LastName ='TestLN1',FirstName='TestFN1',AccountId=TestDataUtilityClass.mapClientesAutosJuridico.get(0).Id);
        insert c;
        
        c.FirstName='TestFN1E';
        update c;
    }
}