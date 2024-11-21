/**
* Fanalca
* @author           Alejandro Rebollo
* Description:      Test Class for AR_Convertir_Contacto_a_cuenta_cls Controller
*
* Changes (Version)
* -------------------------------------
*           No.     Date            Author                  Description
*           -----   ----------      --------------------    ---------------
* @version  1.0     12/12/2019      Alejandro Rebollo(AR)   Class definition 
*********************************************************************************************************/

@istest
public class AR_Convertir_Contacto_a_Cuenta_tst {
 // Prueba de Controlador
       static testMethod void testMyController() {   
 // Variables auxiliares
        MC_Contactos__c Contacto1 = new MC_Contactos__c();
           
 // Set data, input parameters
//        AM_Municipio__c catMunicipio = [SELECT Id FROM AM_Municipio__c WHERE Name = 'CARTAGENA' LIMIT 1];
        Contacto1.MC_tratamiento_prospecto__c = 'Sr.';
        Contacto1.Name = 'Test1';
        Contacto1.MC_apellidos_prospecto__c = 'Test1';
        Contacto1.MC_fuente_prospecto__c = 'Referidos';
        Contacto1.MC_correo_electronico_prospecto__c = 'me@test1.com';
        Contacto1.MC_celular_prospecto__c = '3147710584';
        Contacto1.MC_No_autoriza_tratamiento_de_datosLeads__c = True;
//        Contacto1.MC_ciudad_prospecto__c = catMunicipio.id;
        Contacto1.MC_No_autoriza_tratamiento_de_datosLeads__c = true;
        Contacto1.MC_Ultimo_comentaro__c = 'Nada';
        Contacto1.MC_Fecha_ultimo_contacto__c = Date.newInstance(2019, 12, 9);
        Contacto1.MC_Autoriza_tratadedatos_personales__c = 'No';
        
        insert Contacto1;
           
        // Ajusta controlador
        ApexPages.StandardController stdContacto = new ApexPages.StandardController(Contacto1);
        AR_Convertir_Contacto_a_cuenta_cls MyContactoController  = new AR_Convertir_Contacto_a_cuenta_cls(stdContacto);
           
        // Ajusta variables adicionales
        MyContactoController.selEstado = 'Activo';
        MyContactoController.selTipoDeDocumento = 'Cedula de ciudadanía';
        MyContactoController.txtNoDeDocumento = '7738829239';
        MyContactoController.selTipoDeCliente = 'Cliente No Honda';
        MyContactoController.chkNotCorreo = false;
        MyContactoController.selOcupacion = 'Empleado';
           
       // Guarda tratamiento en controlador
        MyContactoController.save();
        }	    
}