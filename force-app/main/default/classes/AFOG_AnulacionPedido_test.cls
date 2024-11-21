/******************************************************************************************************************************
*   @Class          :   AFOG_AnulacionPedido_test
*   @Author         :   Andrés Oliva andresolivag@gmail.com
*   @Created        :   11/01/2022
*   @Description    :   Esta clase valida las  acciones para eliminar el pedido.
*
*      Author                   Date                     Description
*      Andrés Oliva              15/02/2022                 Class creation
*******************************************************************************************************************************/
@isTest
public with sharing class AFOG_AnulacionPedido_test {
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
        //objOpp.Como_se_entero_del_vehiculo_o_marca__c   = 'Actividades comerciales';
        //objOpp.Vehiculo_Anterior_MarcaLineaModelo__c    = 'N/A';
        objOpp.Es_un_HONDA_adicional__c                 = 'No';
        objOpp.Linea_Modelo__c                          =  'N/A';
        objOpp.Otra_Marca_Considero_Opcion_1__c         = 'DODGE';
        objOpp.Linea_Modelo_Marca_Considero_1__c        = 'DURANGO';
        objOpp.Posee_vehiculo_de_otra_marca__c          = 'NO';
        objOpp.MarcaLineaModelo__c                      = 'NO';
       // objOpp.MarcaLineaModelo1__c                     = 'N/A';
        objOpp.Otra_Marca_Considero_Opcion_2__c         = 'FORD';
        objOpp.Linea_Modelo_Marca_Considero_2__c        = 'SCAPE';
        //objOpp.Como_se_entero_del_vehiculo_o_marca__c = 'Actividades comerciales';
        if( isInsert ){
            insert objOpp;
        }
        return objOpp;             
    }
    static testMethod void validateTrigger() {
        account     objAcc  =   createAccount( true , 'Account_Test', '102547845');
        opportunity objOpp  =   createOpportunity( true , objAcc.Id );
        test.StartTest();
        	AFOG_AnualacionPedido.anularPedido( objOpp.Id );
        test.StopTest();       
    }

}