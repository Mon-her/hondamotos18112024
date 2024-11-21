//Made by me, June 2021
@isTest
public class ProlibuProposalChangeStatus_Test {
    public static testmethod void testear(){
        TestDataUtilityClass.crearCuentasAutos(1, Label.AutosRecordTypeDevNameAccountNatural);
        TestDataUtilityClass.crearConcesionarios(1);
        TestDataUtilityClass.crearMiembroConcesionarios(1);
        TestDataUtilityClass.crearOportunidadAutos(1);
        TestDataUtilityClass.crearQuoteAutos(1);
        
        Opportunity opp = TestDataUtilityClass.mapOpportunitiesAutos.get(1);
        
        system.debug('opp id ' + opp.Id);
        system.debug([select id, whatId from task]);
        Quote q= TestDataUtilityClass.mapQuotesAutos.get(1);
        q.Creado_Prolibu__c = true;
        update q;
        
        Test.startTest();
        
        opp.SyncedQuoteId = q.Id;
        //opp.StageName ='PU'; //Closed Won para Autos
        update opp;
        
        ProlibuProposalChangeStatus.sendOppStatusFuture(opp.Id, q.Id,true);
        Test.stopTest();
        Test.setMock(HttpCalloutMock.class, new ProlibuProposalChangeStatus_Mock(1));
        ProlibuProposalChangeStatus.sendOppStatusFuture(opp.Id, q.Id,true);
    }
    
    public static testmethod void testearError(){
        TestDataUtilityClass.crearCuentasAutos(1, Label.AutosRecordTypeDevNameAccountNatural);
        TestDataUtilityClass.crearConcesionarios(1);
        TestDataUtilityClass.crearMiembroConcesionarios(1);
        TestDataUtilityClass.crearOportunidadAutos(1);
        TestDataUtilityClass.crearQuoteAutos(1);
        
        Opportunity opp = TestDataUtilityClass.mapOpportunitiesAutos.get(1);
        
        Test.startTest();
        Test.setMock(HttpCalloutMock.class, new ProlibuProposalChangeStatus_Mock(3));
        ProlibuProposalChangeStatus.sendOppStatusFuture(opp.Id, null,true);
        Test.stopTest();
    }
}