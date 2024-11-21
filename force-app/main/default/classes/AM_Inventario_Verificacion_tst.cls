@isTest
public class AM_Inventario_Verificacion_tst{

    public static testMethod void testMyController() {
       
       //Use the PageReference Apex class to instantiate a page
       PageReference pageRef = Page.verificacionDisponibilidad;
       
       //In this case, the Visualforce page named 'success' is the starting point of this test method. 
       Test.setCurrentPage(pageRef);
     
      Date myDate = Date.newInstance(1980, 4, 15);
      //RM 14-01-2019. Adjust class coverage.
        /*Account acc = new Account(          
          FirstName__c = 'nametest1',
          LastName__c = 'lasttest1',          
          Phone = '3108203322',
          Salutation = 'Sra.',
          AM_Genero_pc__c = 'Masculino',
          //PersonBirthdate__c = myDate,
          AM_Estado_civil_pc__c= 'Soltero',
          AM_Nivel_de_estudio__c = 'Universitario',
          AM_Ocupacion_pc__c = 'Empleado',
          AM_Como_se_entero_de_la_marca__c = 'Amigo');
        insert acc;*/
        Account acc = new Account();
        acc.Phone = '3102334532';
        acc.FirstName ='test';
        acc.LastName = 'Test';
        acc.Salutation = 'Sra.';
        acc.AM_Genero__pc = 'Masculino';
        acc.AM_Numero_de_documento__c = '7738829231';
        acc.PersonEmail = 'test@test.com';
        insert acc;
      AM_Producto__c prod = new AM_Producto__c(
            Name = 'Glamour',
            Plan_Tipo_de_Modelo_Unoe__c = 'GLAMOUR',
            AM_Ano__c = 2.014,
            Plan_Tipo_de_Producto_Unoe__c = 'MOTOCICLETA');
      insert prod;

        AM_Oportunidad__c opp = new AM_Oportunidad__c(
         AM_Usuario_motocicleta__c = acc.Id,
         AM_Propietario_motocicleta__c = acc.Id,
         AM_Tipo_de_cotizacion__c = 'Nuevos',
         AM_Etapa__c ='P0',
         AM_Color__c = 'Blanco',
         Forma_de_pago__c = 'Contado',
         AM_Modelo_de_interes__c = prod.Id,
         AM_Canal_de_atencion__c = 'Aviso de prensa');
        insert opp;



        System.debug('etapa inicial ---------------> '+opp.AM_Etapa__c);
/* queries from controller.
        AM_Oportunidad__c AMOP = (AM_Oportunidad__c)controller.getRecord();
            AM_Oportunidad__c myCotizacion = [select id, AM_Color__c, AM_Modelo_de_interes__c from AM_Oportunidad__c where id = :AMOP.id];
            AM_Producto__c myProd = [select name from AM_Producto__c where id = :myCotizacion.AM_Modelo_de_interes__c];
            */

       //Instantiate and construct the controller class.   
       ApexPages.StandardController sc = new ApexPages.StandardController(opp);
       //newAccountPlan testAccPlan = new newAccountPlan(sc);
       AM_Inventario_VerificacionDisponibilidad controller = new AM_Inventario_VerificacionDisponibilidad(sc);

   }
   
}