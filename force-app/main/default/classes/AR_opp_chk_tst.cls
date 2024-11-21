/**
* Fanalca
* @author           Alejandro Rebollo
* Description:      Test class for AR_opp_chk_tgr trigger.
*
* Changes (Version)
* -------------------------------------
*           No.     Date            Author                  Description
*           -----   ----------      --------------------    ---------------
* @version  1.0     19/06/2019      Alejandro Rebollo (AR)  Class definition.
*********************************************************************************************************/

@isTest
public class AR_opp_chk_tst {
   public static AM_Oportunidad__c objOppL;
   public static AM_Oportunidad__c objOpp1L; 
   public static AM_Oportunidad__c objOpp;
 
    static testMethod void myUnitTest() {
      
        String uniqueUserName = 'standarduser' + DateTime.now().getTime() + '@testorg.com';
        UserRole r = new UserRole(DeveloperName = 'MyCustomRole', Name = 'My Role');
        insert r;
  
        Profile p = [SELECT Id FROM Profile WHERE Name='Analistas'];
        User u = new User(Alias = 'standt', Email='standarduser@testorg.com',
        EmailEncodingKey='UTF-8', LastName='Testing', LanguageLocaleKey='en_US',
        LocaleSidKey='en_US', ProfileId = p.Id,
        TimeZoneSidKey='America/Los_Angeles',
        UserName=uniqueUserName,
        UserRoleId = r.Id);
        
        
        RecordType recTyp = [Select Id, Name From RecordType Where SobjectType = 'AM_Oportunidad__c' AND DEVELOPERNAME ='AM_FP_Cotizacion_contado' Limit 1];
        id uid = UserInfo.getUserId();
        System.runAs(u) {    
            
         Test.StartTest();   
            Account objAcc = new Account();
            objAcc.Phone = '3103221923';
            objAcc.FirstName ='test';
            objAcc.LastName = 'Test';
            objAcc.Salutation = 'Sra.';
            objAcc.AM_Como_se_entero_de_la_marca__c = 'Radio';
            objAcc.AM_Genero__pc = 'Masculino';
            objAcc.PersonEmail = 'test@test.com';
            objAcc.AM_Numero_de_documento__c = '23434565'; 
            objAcc.owneriD = uid ;               
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
            
            objOpp = new AM_Oportunidad__c();
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
            objOpp.owneriD = uid ; 
           
            try {  
             insert objOpp;
            } 
               catch(Exception z)
            {   
                System.Assert(z.getMessage().contains('No tiene acceso a la creación de cotizaciones para esta cuenta.'));
            }            
          
         }          
        Test.StopTest();
    }
    
    
    static testMethod void myUnitTest2() {
      
        RecordType recTyp = [Select Id, Name From RecordType Where SobjectType = 'AM_Oportunidad__c' AND DEVELOPERNAME ='AM_FP_Cotizacion_contado' Limit 1];
           
            
         Test.StartTest();   
            Account objAcc = new Account();
            objAcc.Phone = '3103221987';
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
            
            objOpp = new AM_Oportunidad__c();
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
            
           
            try {  
             insert objOpp;
            } 
               catch(Exception z)
            {   
                System.Assert(z.getMessage().contains('No tiene acceso a la creación de cotizaciones para esta cuenta.'));
            }  
            Test.StopTest();
         }          
        
    
}