@isTest
public with sharing class AO_tableroReferidos_tst {
    private static testMethod void readCSVFile() {   
        AM_Producto__c              objProduct  =   createDataDactory.createProduct( true );
        AM_Plan_financiacion__c     objPlan     =   createDataDactory.createFinantialPlan( true ); 
        account                     objAcc      =   createDataDactory.createAccount( true , 'testacc', '1030445434' );
        MC_Contactos__c             objcontact  =   createDataDactory.createContact( true , objAcc.id ) ; 
        account                     objAccRef   =   createDataDactory.createAccount( false , 'testaccref', '1050445434' );
        objAccRef.AM_Fuente_de_prospeccion__c = 'Referidos';
        objAccRef.SO_Referidor_Cuenta__c = objAcc.id;
        insert objAccRef;                
        AM_Oportunidad__c           objQuote    =   createDataDactory.createQuote( true, objAccRef.Id,objProduct.id, objPlan.id );  
        
        test.startTest();
            AO_tableroReferidos_ctr objTablero = new AO_tableroReferidos_ctr();
            AO_tableroReferidos_ctr.getWrpReferidos(  '1','1',system.today().addDays(-20), system.today() );
        test.stopTest();

    }
}