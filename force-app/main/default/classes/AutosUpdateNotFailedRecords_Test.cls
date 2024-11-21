/**
* Fanalca
* @author           Juan Ansaldi
* Description:      Test class for AutosUpdateNotFailedRecords.
*
* Changes (Version)
* -------------------------------------
*           No.     Date            Author                  Description
*           -----   ----------      --------------------    ---------------
* @version  1.0     10/03/2021      Juan Ansaldi            Class definition.
* @version  1.1     12/03/2021      Juan Ansaldi            Class finished testing succesfully 100% class AutosUpdateNotFailedRecords. 
*********************************************************************************************************/
@isTest
public class AutosUpdateNotFailedRecords_Test {
    public static List<Opportunity> oppList;
    public static List<Account> cuentaPN;
    public static List<Account> cuentaPJ;
    public static User u2;
    //Method for creating test data
    @testSetup 
    static void setUp() {
        List<AM_Municipio__c> municipios = TestDataUtilityClass.CrearMunicipios(1); 
		TestDataUtilityClass.crearConcesionarios(1);
        TestDataUtilityClass.crearMiembroConcesionarios(1);
        cuentaPN = TestDataUtilityClass.crearCuentasAutos(3, Label.AutosRecordTypeDevNameAccountNatural);
    }
    
    @isTest
    public static void testRunBatch(){
        
        Test.startTest();
        Triggerhandler.bypass('OpportunityTriggerHandler');
        Triggerhandler.bypass('QuoteTriggerHandler');
        Triggerhandler.bypass('AccountTriggerHandler');
        Triggerhandler.bypass('TaskTriggerHandler');
        TriggerStopper.stopOppLine = true;
        Triggerstopper.stopQuoteLine = true;
        TriggerStopper.stopOpp = true;
        TriggerStopper.stopQuote = true;
        
        List<Account> a = [Select Id, Segmentacion2__c from Account Limit 3];
        a[0].Segmentacion2__c = 'Prospecto';
        a[0].Fecha_Fin_Garantia__c = Date.today();
        update a[0];

        a[1].Segmentacion2__c = 'Cliente en Garantía';
        a[1].Fecha_Fin_Garantia__c = Date.today();
        update a[1];

        a[2].Segmentacion2__c = 'Cliente Potencial';
        a[2].Fecha_Fin_Garantia__c = Date.today();
        update a[2];
        
		Set<Id> setIds = New Set<Id>();
        setIds.add(a[0].Id);
        setIds.add(a[1].Id);
        setIds.add(a[2].Id);
        
        AutosUpdateNotFailedRecords batchable2 = new AutosUpdateNotFailedRecords(setIds);
    	Id batchProcessId2 = Database.executeBatch(batchable2);
        
    	Test.stopTest();
    }


}