@isTest
private class GTAO_ResetSendERPorder_test 
{
    private static String oppName = 'Sample';
    private static String orderERP = 'ERP_WS_ANS_0001';
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
       lstOppMotos[0].GTAO_PedidoEnviadoSAP__c = true;
       update   lstOppMotos;
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
    * @name             updateResentToSAP 
    * @author           Andres Oliva <andresolivag@gmail.com>
    * @created          06 / 12 / 2021
    * @description      Setup test date, create opportunity and order to the bikes business in order to update ERP order
    * @param            list<GTAO_UpdateERPorderREST_ws.RequestERP>  request of the web service
    * @return           map< string, list<GTAO_UpdateERPorderREST_ws.ResponseERP > > response of the webservice
    **********************************************************************************************************/
    
    public static testMethod void testRunAs() 
    {
        Account testAccount = [SELECT Id,LastName FROM Account WHERE LastName =: oppName LIMIT 1];
        Opportunity testOpp = [SELECT Id,Numero_de_Oportunidad__c,ID_de_pedido_ERP__c FROM Opportunity WHERE Account.LastName =: oppName ];
               
        Test.startTest();
    
             GTAO_ResetSendERPorder_sch obj = new GTAO_ResetSendERPorder_sch();   
             String chron = '0 0 23 * * ?';        
             String jobid = System.schedule('testScheduledApex', chron, obj);
             CronTrigger ct = [Select id , CronExpression from CronTrigger where id = :jobId];
             System.assertEquals(chron,ct.CronExpression); 
             Opportunity testOppAfterUpdate = [SELECT Id,Numero_de_Oportunidad__c,GTAO_PedidoEnviadoSAP__c,ID_de_pedido_ERP__c FROM Opportunity WHERE Account.LastName =: oppName ];
             system.debug('\n opp update @@@'+ testOppAfterUpdate  );
             
        Test.stopTest();
    }
}