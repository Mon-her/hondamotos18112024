/**
* Fanalca
* @author           Alejandro Rebollo
* Description:      Test Class for AR_Convertir_Contacto_a_cuenta__emp_cls Controller
*
* Changes (Version)
* -------------------------------------
*           No.     Date            Author                  Description
*           -----   ----------      --------------------    ---------------
* @version  1.0     13/12/2019      Alejandro Rebollo(AR)   Class definition 
*********************************************************************************************************/

@istest
public class AR_Convertir_Contacto_a_cuenta_emp_tst {
 // Prueba de Controlador
       static testMethod void testMyController() {   
 // Variables auxiliares
         MC_Contactos__c Contacto = new MC_Contactos__c();
 //        AM_Municipio__c Municipio = [SELECT Id, Name FROM AM_Municipio__c LIMIT 1];
           
 // Set data, input parameters
        Contacto.Name = 'Test1';
        Contacto.MC_telefono_fijo_prospecto__c = '3147710584';
        Contacto.MC_fuente_prospecto__c = 'Referidos';
        Contacto.MC_correo_electronico_prospecto__c = 'me@test1.com';
        Contacto.MC_celular_prospecto__c = '3147710584';
//        Contacto.MC_ciudad_prospecto__c = Municipio.Id;
//        Contacto.MC_ciudad_prospecto__c = [SELECT Id FROM AM_Municipio__c WHERE Name = 'PEREIRA'].Id;
        Contacto.MC_No_autoriza_tratamiento_de_datosLeads__c = true;
        Contacto.MC_Ultimo_comentaro__c = 'Nada';
        Contacto.MC_Fecha_ultimo_contacto__c = Date.newInstance(2019, 12, 9);
        Contacto.MC_Autoriza_tratadedatos_personales__c = 'No';
        
        insert Contacto;
     
        // Ajusta controlador
        ApexPages.StandardController stdContacto = new ApexPages.StandardController(Contacto);
        AR_Convertir_Contacto_a_cuenta_emp_cls MyContactoController  = new AR_Convertir_Contacto_a_cuenta_emp_cls(stdContacto);
           
        // Ajusta variables adicionales
        MyContactoController.selEstado = 'Activo';
        MyContactoController.selTipoDeDocumento = 'NIT';
        MyContactoController.txtNoDeDocumento = '7738829239';
        MyContactoController.selTipo = 'Privada';
        MyContactoController.selTipoDeCliente = 'Cliente No Honda';
        MyContactoController.chkNotCorreo = false;
        MyContactoController.selIndustry = 'Financiero';
        
       // Guarda tratamiento en controlador
        MyContactoController.save();
       }
}