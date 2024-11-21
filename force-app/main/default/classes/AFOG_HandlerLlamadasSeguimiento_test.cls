/******************************************************************************************************************************
*   @Class          :   AFOG_HandlerLlamadasSeguimiento_test
*   @Author         :   Andrés Oliva andresolivag@gmail.com
*   @Created        :   14/01/2022
*   @Description    :   Esta clase ejecuta actualizar en la oportunidad el número de llamadas de seguimiento
*
*      Author                   Date                     Description
*      Andrés Oliva              21/01/2022                 Class creation
*******************************************************************************************************************************/
@isTest
private class AFOG_HandlerLlamadasSeguimiento_test {
    public static string sOppId ;
     /*********************************************************************************************************
     * @name            createAccount
     * @author          Andres Oliva <andres.oliva@cognizant.com>
     * @created         30 / 07 / 2020
     * @description     Description of your code
     * @param           String param : Explanation
     * @return          Explanation of the return value
    **********************************************************************************************************/
    public static account createAccount( Boolean isInsert , string sName, string iDocumentNumber){
           Account objAcc = new Account();
        objAcc.Phone = '8624597';
        objAcc.FirstName ='test';
        objAcc.LastName = sName;
        objAcc.Salutation = 'Sra.';
        objAcc.AM_Como_se_entero_de_la_marca__c = 'Radio';
        objAcc.AM_Genero__pc = 'Masculino';
        objAcc.PersonEmail = sName+'test@test.com';
        //objAcc.PersonOtherPhone = 3256745;
        objAcc.AM_Numero_de_documento__c = iDocumentNumber;
        objAcc.AM_Tipo_de_documento__c ='Cédula de ciudadanía';
        if( isInsert ){
            insert objAcc;
        }
        return objAcc;            
    }

    /*********************************************************************************************************
     * @name            createAccount
     * @author          Andres Oliva <andres.oliva@cognizant.com>
     * @created         30 / 07 / 2020
     * @description     Description of your code
     * @param           String param : Explanation
     * @return          Explanation of the return value
    **********************************************************************************************************/
    public static opportunity createOpportunity( Boolean isInsert , id accountId ){
        opportunity objOpp              = new opportunity();
        objOpp.Name                     = 'Opp test';
        objOpp.AccountId                = accountId;
        objOpp.CloseDate                = system.today().addDays( 10 );
        objOpp.Propietario_vehiculo__c  = accountId;
        objOpp.Forma_de_pago__c         = 'Contado';
        objOpp.LeadSource               = 'Actividades comerciales';
        objOpp.StageName                = 'P2';
        objOpp.Como_se_entero_del_vehiculo_o_marca__c   = 'Actividades comerciales';
        objOpp.Vehiculo_Anterior_MarcaLineaModelo__c    = 'N/A';
        objOpp.Es_un_HONDA_adicional__c                 = 'No';
        objOpp.Linea_Modelo__c                          =  'N/A';
        objOpp.Otra_Marca_Considero_Opcion_1__c         = 'DODGE';
        objOpp.Linea_Modelo_Marca_Considero_1__c        = 'DURANGO';
        objOpp.Posee_vehiculo_de_otra_marca__c          = 'NO';
        objOpp.MarcaLineaModelo__c                      = 'NO';
        objOpp.MarcaLineaModelo1__c                     = 'N/A';
        objOpp.Otra_Marca_Considero_Opcion_2__c         = 'FORD';
        objOpp.Linea_Modelo_Marca_Considero_2__c        = 'SCAPE';
        objOpp.Como_se_entero_del_vehiculo_o_marca__c = 'Actividades comerciales';
        if( isInsert ){
            insert objOpp;
        }
        return objOpp;             
    }
    static testMethod void validateTrigger() {
        account     objAcc  =   createAccount( true , 'Account_Test', '102547845');
        opportunity objOpp  =   createOpportunity( true , objAcc.Id );
        test.StartTest();
            task        objTask =  [select id,Status from task where whatid =:objOpp.id];
            objTask.Status = 'Completada';
            update objTask;
        test.StopTest();
        opportunity lstOpp = [ SELECT id,AFOG_NoLlamadasSeguimientoCompletadas__c,AFOG_NoLlamadasSeguimientoProgramadas__c FROM Opportunity WHERE Id =: objOpp.Id ];
        system.debug('\n Opp @@@@ '+ JSON.serializePretty( lstOpp ) );       
    }

     static testMethod void validateBatchProcess() {
        account     objAcc  =   createAccount( true , 'Account_Test', '102547845');
        opportunity objOpp  =   createOpportunity( true , objAcc.Id );
          sOppId = '\''+objOpp.Id+'\'';
        test.StartTest();         
            string querie = ' select id, whatid from task where whatid = '+  sOppId +' ';
            system.debug('\n querie @@@' + querie);
            AFOG_LlamadasSeguimiento_Batch ba= new AFOG_LlamadasSeguimiento_Batch( querie );
            Id jobid= Database.executeBatch(ba,5);
        test.StopTest();
        opportunity lstOpp = [ SELECT id,AFOG_NoLlamadasSeguimientoCompletadas__c,AFOG_NoLlamadasSeguimientoProgramadas__c FROM Opportunity WHERE Id =: objOpp.Id ];
        system.debug('\n Opp after batch @@@@ '+ JSON.serializePretty( lstOpp ) );       
    }
}