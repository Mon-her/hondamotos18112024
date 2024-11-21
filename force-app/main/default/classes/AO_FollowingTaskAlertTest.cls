/*  @Class          :   AO_FollowingTaskAlertTest.cls
*   @Author         :   Andrés Oliva
*   @Created        :   13/05/2020
*   @Description    :   Test class alert messege in task creation
*
*   ----------------------------------------------------------------------------------------------------------------------------
*      Modification Log :
*   ----------------------------------------------------------------------------------------------------------------------------
*      Author           		Date                     Description
*	   Andrés Oliva 			18/1/2018				 Test class alert messege in task creation   
*   ----------------------------------------------------------------------------------------------------------------------------
*********************************************************************************************************************************/
@isTest
public class AO_FollowingTaskAlertTest {
   	
    public static AM_Oportunidad__c objOpp;
    /***************************************************************************************************************************  
	* @Method          :   setup
	* @Author          :   Andrés Oliva <andresolivag@gmail.com>
	* @Created         :   13/05/2020
	* @Description     :    - setup test class 
	* @param 		   :  
	****************************************************************************************************************************/

      @testSetup static void setup() {
        RecordType recTyp = [Select Id, Name From RecordType Where SobjectType = 'AM_Oportunidad__c' AND DEVELOPERNAME ='AM_FP_Cotizacion_contado' Limit 1];    
        Account objAcc = new Account();
        objAcc.Phone = '3103221212';
        objAcc.FirstName ='test';
        objAcc.LastName = 'Test';
        objAcc.Salutation = 'Sra.';
        objAcc.AM_Como_se_entero_de_la_marca__c = 'Radio';
        objAcc.AM_Genero__pc = 'Masculino';
        objAcc.PersonEmail = 'test@test.com';
        objAcc.AM_Numero_de_documento__c = '23434565';
        insert objAcc;
        
        AM_Producto__c objPrd = new AM_Producto__c();
        objPrd.AM_Activo__c = true;
        objPrd.AM_Ano__c = 2014;
        objPrd.AM_Codigo_de_producto__c = 'test';
        objPrd.AM_Color_disponible__c = 'NEGRO';
        objPrd.AM_Precio_de_lista__c = 2000000;
        objPrd.Name = 'MotoTest';
        objPrd.Plan_Tipo_de_Producto_Unoe__c = 'MOTOCICLETA';
        objPrd.Plan_Tipo_de_Modelo_Unoe__c = 'GLAMOUR';
        insert objPrd; 
        
        AM_Plan_financiacion__c objPlanF = new AM_Plan_financiacion__c();
        objPlanF.Name = 'Test Plan Financiacion';
        objPlanF.AM_Activo__c = true;
        objPlanF.AM_Plan_financiacion__c = 'Flexible';
        insert objPlanF;
        
        AM_Oportunidad__c objOpp = new AM_Oportunidad__c();
        objOpp.AM_Usuario_motocicleta__c = objAcc.Id;
        objOpp.AM_Tipo_de_cotizacion__c = 'Nuevos';
        objOpp.AM_Propietario_motocicleta__c  = objAcc.Id;
        objOpp.RecordTypeId = recTyp.Id;
        objOpp.AM_Fecha_de_cierre__c = system.today();
        objOpp.AM_Modelo_de_interes__c = objPrd.Id;
        objOpp.AM_Color__c = 'PLATEADO';
        objOpp.AM_Valor_cuota_inicial__c = 100000;
        objOpp.AM_Valor_matricula__c = 20000;
        objOpp.AM_Valor_SOAT__c = 20000;
        objOpp.AM_Plazo__c = 12;
        objOpp.AM_Desea_incluir_seguro_de_robo__c = 'Si';
        objOpp.AM_Canal_de_atencion__c = 'Volantes';
        objOpp.Uso_de_Motocicleta__c = 'Trabajo';
        objOpp.AM_Plan_de_financiacion__c = objPlanF.Id;
        objOpp.Forma_de_pago__c = 'Contado';
        objOpp.AM_Estado1__c = 'Activo';
        objOpp.AM_ObservacionesL__c = 'TEST TEST TEST TEST TEST TEST TEST TEST TEST TEST TEST TEST TEST TEST TEST TEST TEST TEST TEST TEST TEST TEST TEST TEST TEST TEST TEST TEST';
        insert objOpp;        
    }
     /***************************************************************************************************************************  
	* @Method          :   setup
	* @Author          :   Andrés Oliva <andresolivag@gmail.com>
	* @Created         :   13/05/2020
	* @Description     :    - setup test class 
	* @param 		   :  
	****************************************************************************************************************************/
   	@isTest static void statusWTBDpendingToRefused(){
        Account objAcct = [select id from account where FirstName='test' limit 1];
        AM_Oportunidad__c objOpp = [select id from AM_Oportunidad__c limit 1];
        Test.StartTest(); 
			Task objTask = new task();
            objTask.ActivityDate = system.Today();
            objTask.whatId 	= objAcct.Id; 
            objTask.Description = 'test'; 
        	objTask.Fecha_de_proximo_seguimiento__c        = system.Today().addDays( 10 );
        	objTask.status = 'Programada';	
        	insert objTask;
        	ObjTask.status = 'Completada';	
        	UPDATE ObjTask;
        	AO_FollowingTaskAlert_ctr.showAlert( objTask.Id,null, system.Today().addDays( 10 ) );           
        Test.StopTest();
    }    
}