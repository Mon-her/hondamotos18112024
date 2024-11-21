/**
* Fanalca
* @author           ?
* Description:      Test class for Task trigger (UpdateField2).
*
* Changes (Version)
* -------------------------------------
*           No.     Date            Author                  Description
*           -----   ----------      --------------------    ---------------
* @version  1.0     05/02/2018      ?                       Class definition.
* @version  1.0     03/12/2018      Raul Mora (RM)          Adjust to increase coverage.
* @version  1.0     31/01/2021      Andrés Oliva (AO)       Adjust to fix error related with a validation rule
*********************************************************************************************************/
@isTest
private class UpdateField2_tst {
    static testMethod void myUnitTest() {
        //03/12/2018 RM. Remove record type name as where condition.
        RecordType recTyp = [Select Id, Name From RecordType Where SobjectType = 'AM_Oportunidad__c' Limit 1];
        
        Account cuenta = new Account();
        //RM 14-01-2019. Adjust test class coverage.
        cuenta.Phone = '9876543'; // AO 31/01/2021 Asjust to fix validation rule error
        cuenta.FirstName ='test';
        cuenta.LastName = 'Test';
        //03/12/2018 RM. Validation rule require salutation to create account.
        cuenta.Salutation = 'Sra.';
        cuenta.AM_Como_se_entero_de_la_marca__c = 'Radio';
        cuenta.AM_Genero__pc = 'Masculino';
        cuenta.PersonEmail = 'test@test.com';
        cuenta.AM_Numero_de_documento__c = '98475743';
        cuenta.AM_Tipo_de_documento__c = 'Pasaporte';
        insert cuenta;
        
        AM_Producto__c prod = new AM_Producto__c();
        prod.AM_Activo__c = true;
        prod.AM_Ano__c = 2014;
        prod.AM_Codigo_de_producto__c = 'test';
        prod.AM_Color_disponible__c = 'Rojo';
        prod.AM_Precio_de_lista__c = 2000000;
        prod.Name = 'MotoTest';
        prod.Plan_Tipo_de_Producto_Unoe__c = 'MOTOCICLETA';
        prod.Plan_Tipo_de_Modelo_Unoe__c = 'GLAMOUR';
        insert prod; 
        
        //03/12/2018 RM. Create test data for plan de financiacion.
        AM_Plan_financiacion__c objPlanF = new AM_Plan_financiacion__c();
        objPlanF.Name = 'Test Plan Financiacion';
        objPlanF.AM_Activo__c = true;
        objPlanF.AM_Plan_financiacion__c = 'Flexible';
        insert objPlanF;
        
        AM_Oportunidad__c cot = new AM_Oportunidad__c();
        cot.AM_Usuario_motocicleta__c = cuenta.Id;
        //RM 14-01-2019. Adjust test class coverage.
        cot.AM_Propietario_motocicleta__c  = cuenta.Id;
        cot.RecordTypeId = recTyp.Id;
        Cot.AM_Fecha_de_cierre__c = system.today();
        cot.AM_Modelo_de_interes__c = prod.Id;
        //cot.AM_Color__c = 'GRIS';
        cot.AM_Valor_cuota_inicial__c = 100000;
        cot.AM_Valor_matricula__c = 20000;
        cot.AM_Valor_SOAT__c = 20000;
        cot.AM_Plazo__c = 12;
        cot.AM_Desea_incluir_seguro_de_robo__c = 'Si';
        //03/12/2018 RM. Restricted picklist, it had a value that was not included.
        cot.AM_Canal_de_atencion__c = 'Volantes';
        cot.Uso_de_Motocicleta__c = 'Trabajo';
        //03/12/2018 RM. Assign a plan de financiacion.
        cot.AM_Plan_de_financiacion__c = objPlanF.Id;
        //03/12/2018 RM. Include required fields.
        //cot.Forma_de_pago__c = 'Contado';
        cot.AM_Estado1__c = 'Activo';
        insert cot;
        
        //03/12/2018 RM. Create test data for task to excecute trigger.
        Task objTask = new Task();
        objTask.WhatId = cot.Id;
        objTask.Description = 'Test';
        objTask.ActivityDate    =   system.today().addDays(4);
        //insert objTask;
        
        
   }
    
    static testMethod void myUnitTest2() {        
        Account cuenta = new Account();
        //RM 14-01-2019. Adjust test class coverage.
        cuenta.Phone = '9876543'; // AO 31/01/2021 Asjust to fix validation rule error
        cuenta.FirstName ='test';
        cuenta.LastName = 'Test';
        cuenta.AM_Numero_de_documento__c = '98475743';
        cuenta.AM_Tipo_de_documento__c = 'Pasaporte';
        //03/12/2018 RM. Validation rule require salutation to create account.
        cuenta.Salutation = 'Sra.';
        cuenta.AM_Como_se_entero_de_la_marca__c = 'Radio';
        cuenta.AM_Genero__pc = 'Masculino';
        cuenta.PersonEmail = 'test@test.com';
        insert cuenta;        
        
        
        //03/12/2018 RM. Create test data for task to excecute trigger.
        Task objTask = new Task();
        objTask.WhatId = cuenta.Id;
        objTask.Description = 'Test';
        objTask.ActivityDate    =   system.today().addDays(4);
        insert objTask;
        
        
   }
   static testMethod void updateAccountRelation() { 
        RecordType recTyp = [Select Id, DeveloperName From RecordType Where SobjectType = 'Account' and DeveloperName ='AM_CUE_Persona_natural' Limit 1];
        Account objCuenta = new Account();        
        objCuenta.Phone = '9876543'; // AO 31/01/2021 Asjust to fix validation rule error
        objCuenta.FirstName ='test';
        objCuenta.LastName = 'Test'; 
        objCuenta.RecordTypeId  =  recTyp.ID;        
        objCuenta.Salutation = 'Sra.';
        objCuenta.AM_Como_se_entero_de_la_marca__c = 'Radio';
        objCuenta.AM_Genero__pc = 'Masculino';
        objCuenta.PersonEmail = 'test@test.com';
        objCuenta.AM_Tipo_de_documento__c = 'Pasaporte';
        objCuenta.AM_Numero_de_documento__c = '98475743';
        insert objCuenta;   
        test.StartTest();
            task objTask    =   new task();
            objTask.WhatId  =   objCuenta.Id;
            objTask.ActivityDate    =   system.today().addDays(4);
            objTask.Description =   'test task';            
            objTask.status  =   'Programada';
            insert  objTask;
        Test.StopTest();
        system.assertEquals( [Select AM_Busqueda_cuenta__c FROM Task WHERE ID =:objTask.ID ].AM_Busqueda_cuenta__c, objCuenta.Id);

   }
}