@IsTest
/*************************************************************************************************************
 * @name            GTAO_UpdateERPorder_ctr
 * @author          Andres Oliva <andresolivag@gmail.com>
 * @created         31 / 10 / 2021
 * @description     This is a TEST controller class to update ERP order details with a WS
 *
 * Changes (version)
 * -----------------------------------------------------------------------------------------------------------
 *              No.     Date            Author                  Description
 *              ----    ------------    --------------------    ----------------------------------------------
 * @version     1.0     2021-12-06      Andres Oliva            Changes desription
 *
**************************************************************************************************************/
public class GTAO_UpdateERPorderREST_tst {

    private static String oppName = 'Sample';
    private static String orderERP = 'ERP_WS_ANS_0001';
    private static String orderERP2 = 'ERP_WS_ANS_0002ERP_WS_ANS_0002ERP_WS_ANS_0002ERP_WS_ANS_0002ERP_WS_ANS_0002ERP_WS_ANS_0002';

    /*********************************************************************************************************
    * @name             setupData
    * @author           Andres Oliva <andresolivag@gmail.com>
    * @created          06 / 12 / 2021
    * @description      Setup test date, create opportunity and order to the bikes business in order to update ERP order
    * @param            list<GTAO_UpdateERPorderREST_ws.RequestERP>  request of the web service
    * @return           map< string, list<GTAO_UpdateERPorderREST_ws.ResponseERP > > response of the webservice
    **********************************************************************************************************/
    @TestSetup
    static void setupData(){
       //Create sample account 
       List<Account> lstAccountMotos = TestDataUtilityClass.crearClienteMotos( Label.MotosRecordTypeDevNameAccountNatural, 1 ); 
       lstAccountMotos[0].LastName = oppName;
       update  lstAccountMotos[0];
       system.debug('\n account Motos @@' + lstAccountMotos);
       //Create Opportunity
       List<Opportunity> lstOppMotos = TestDataUtilityClass.crearOportunidadMotos(1);
       lstOppMotos[0].Name = oppName;      
       system.debug('\n opportunidad Motos @@' + lstOppMotos);
       //Create order
       order oOrder = new order();
       oOrder.OpportunityId = lstOppMotos [0].id;
       oOrder.AccountId     = lstAccountMotos[0].Id;
       oOrder.EffectiveDate = Date.today().addDays(10);
       oOrder.Status        = 'Draft';
       insert oOrder;

    }
    
    /*********************************************************************************************************
    * @name             testAccountCreation
    * @author           Andres Oliva <andresolivag@gmail.com>
    * @created          06 / 12 / 2021
    * @description      Execute the logic to update ERP order, and also the logic to validate KO webservice response.
    * @param            list<GTAO_UpdateERPorderREST_ws.RequestERP>  request of the web service
    * @return           map< string, list<GTAO_UpdateERPorderREST_ws.ResponseERP > > response of the webservice
    **********************************************************************************************************/
 
    @IsTest
    static void testAccountCreation(){

        Account testAccount = [SELECT Id,LastName FROM Account WHERE LastName =: oppName LIMIT 1];
        Opportunity testOpp = [SELECT Id,Numero_de_Oportunidad__c,ID_de_pedido_ERP__c FROM Opportunity WHERE Account.LastName =: oppName ];
        Order       ordTest     = [SELECT Id,ID_de_pedido_ERP__c FROM order WHERE OpportunityId =: testOpp.Id];
        system.debug('\n test opp @@' + testOpp+ '\n order test @@ ' +ordTest);        
        System.assertNotEquals(null, testAccount);
        //Update account name
        test.startTest();
            GTAO_UpdateERPorderREST_ws.RequestERP objRequest = new GTAO_UpdateERPorderREST_ws.RequestERP();
            objRequest.OpportunityNumber  = testOpp.Numero_de_Oportunidad__c;
            objRequest.ERPorderId         = orderERP;
            list< GTAO_UpdateERPorderREST_ws.RequestERP > lstRequest = new   list< GTAO_UpdateERPorderREST_ws.RequestERP >();
            lstRequest.add( objRequest );
            GTAO_UpdateERPorderREST_ws.updateERPorder( lstRequest );
            system.debug('\n test opp ERP @@' + testOpp+ '\n order test ERP @@ ' +ordTest);
            Opportunity testOppERP = [SELECT Id,Numero_de_Oportunidad__c,ID_de_pedido_ERP__c FROM Opportunity WHERE Account.LastName =: oppName ];
        
           //// System.assertEquals( testOppERP.ID_de_pedido_ERP__c  , orderERP); 

            GTAO_UpdateERPorderREST_ws.RequestERP objRequest2 = new GTAO_UpdateERPorderREST_ws.RequestERP();
            objRequest2.OpportunityNumber  = testOppERP.Numero_de_Oportunidad__c;
            objRequest2.ERPorderId         = orderERP2;
            list< GTAO_UpdateERPorderREST_ws.RequestERP > lstRequest2 = new   list< GTAO_UpdateERPorderREST_ws.RequestERP >();
            lstRequest2.add( objRequest2 );
            list<list<GTAO_UpdateERPorderREST_ws.ResponseERP > > lstResponse = GTAO_UpdateERPorderREST_ws.updateERPorder( lstRequest2 );
            system.debug('\n response call out with error @@'+ lstResponse);        
        test.stopTest();   
    }  
}