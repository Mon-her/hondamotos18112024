/**
* Fanalca
* @author           Alejandro Rebollo
* Description:      Extension in Contact Custom Object - Convert Invidual Contact to Account
*
* Changes (Version)
* -------------------------------------
*           No.     Date            Author                  Description
*           -----   ----------      --------------------    ---------------
* @version  1.0     19/10/2019      Alejandro Rebollo(AR)   Class definition (Controller)
* @version  1.0     07/02/2021      Andrés Oliva(AO)        Replace phone by personalMovilPhone in account convertion (Controller)
*********************************************************************************************************/

public with sharing class AR_Convertir_Contacto_a_Cuenta_cls {
    //Parent controller
   private final SObject parent; 
    
       //Valores seleccionados en los picklist
   public String selEstado {set;get;}
   public String selTipoDeDocumento {set;get;}
   public String selTipoDeCliente {set;get;} 
   public String selOcupacion {set;get;}
   public list<selectoption> getCmbEstado {get;set;}
   public list<selectoption> getCmbTipoDeDocumento {get;set;}
   public list<selectoption> getCmbTipoDeCliente {get;set;}
   public list<selectoption> getCmbOcupacion {get;set;}
    
     // Valores adicionales de la página
   public String sMsg{get;set;}
   public boolean INPUT{get;set;}
   public String txtNoDeDocumento{get;set;}
   public String txtCorreoElectronico{get;set;}
   public boolean chkNotCorreo{get;set;}
    
    // Variable para instancia de nueva cuenta
   public String sID;
   public MC_Contactos__c Contacto, ContactoEmail;
   public Account chkAcctDoc;
    
    // Método para guardar
    public pageReference save(){   
        //Variables auxiliares
        String sAccID;
        Boolean bExistDoc;
       
     // Recupera datos del lead actual
       Contacto = [select MC_tratamiento_prospecto__c, MC_nombres_prospecto__c, MC_apellidos_prospecto__c, MC_fuente_prospecto__c,
               MC_celular_prospecto__c, MC_No_autoriza_tratamiento_de_datosLeads__c, MC_ciudad_prospecto__c, Name,
               MC_Ultimo_comentaro__c, MC_Fecha_ultimo_contacto__c, MC_Autoriza_tratadedatos_personales__c
               from MC_Contactos__c where id = :sID];

       // Válida que no exista el mismo número
        try {
       chkAcctDoc = [select id, AM_ContactoRelacionadoAC__c from Account 
                     where AM_ContactoRelacionadoAC__c = :sID];
            
            bExistDoc = true;
        } catch (exception e) {
            bExistDoc = false;
        }
        
        if (bExistDoc == false) {
         // Agrega nuevo registro, conforme mapeo
           Account AccountNew = new Account();
           AccountNew.Salutation = Contacto.MC_tratamiento_prospecto__c;
           AccountNew.FirstName = Contacto.Name;
           AccountNew.LastName = Contacto.MC_apellidos_prospecto__c;
           AccountNew.AM_Fuente_de_prospeccion__c = Contacto.MC_fuente_prospecto__c;
           AccountNew.PersonEmail = txtCorreoElectronico;
           AccountNew.PersonMobilePhone= Contacto.MC_celular_prospecto__c; //07/02/2021  AO Replace Phone by personMobilePhone
           AccountNew.MC_No_autoriza_tratamiento_de_datos__c = Contacto.MC_No_autoriza_tratamiento_de_datosLeads__c;
           AccountNew.AM_Ciudad__c = Contacto.MC_ciudad_prospecto__c;
            
         // Agrega campos del formato de entrada
           AccountNew.AM_Estado__c = selEstado;
           AccountNew.AM_Tipo_de_documento__c = selTipoDeDocumento;
           AccountNew.AM_Numero_de_documento__c = txtNoDeDocumento;
           AccountNew.AM_Tipo_de_usuario__c = selTipoDeCliente;
           AccountNew.PersonHasOptedOutOfEmail = chkNotCorreo;
           AccountNew.AM_Ocupacion__pc = selOcupacion;
           AccountNew.AM_ContactoRelacionadoAC__c = sID;
            
         //Agrega comentarios
           AccountNew.MC_ultimo_comentario_en_cuenta__c = Contacto.MC_Ultimo_comentaro__c;
           AccountNew.AM_Fecha_Ultimo_Contacto_Cliente__c = Contacto.MC_Fecha_ultimo_contacto__c;
            
          //Autoriza trata de datos personales
           AccountNew.MC_Autoriza_tratardatos_personales__c = Contacto.MC_Autoriza_tratadedatos_personales__c;
            
            // Inserta regristro
           try{
               insert AccountNew;
               sAccID = AccountNew.id;
               
           // Actualiza Lead
               try {
                   Contacto.MC_estado_prospecto__c = 'Convertido a cuenta';
                   Contacto.MC_cuenta_relacionada_prospecto__c = AccountNew.id;
                   update Contacto;
                   
                   //navigateToSObject(AccountNew.id);
                    PageReference ref= new PageReference('/'+AccountNew.id);
                    ref.setredirect(true);
                    return ref;
               } catch (exception e){
               sAccID = '';
               sMsg = e.getMessage();
               }
            }
            catch(exception e){
               sAccID = '';
               sMsg = e.getMessage();
            }
        } else {
            sAccID = '';
            sMsg = 'El número de contacto: ' + sID + ' ya existe en la cuenta ID: ' + chkAcctDoc.id + '.';
        }

                   // Ajusta mensaje de salida
        if (sAccID <> '') {
            sMsg = 'Se ha creado la cuenta: ' + sAccID;
        }
        
        //Envío de mensaje
            INPUT = false;
            
        // Regresa a la página actual
        return null;
    }
    
    //constructor, limpia, los valores de selección
    public AR_Convertir_Contacto_a_cuenta_cls(ApexPages.StandardController controller) {
        parent = controller.getRecord();
        
        sID = parent.id;
        selEstado = 'Activo';
        selTipoDeDocumento = 'Cedula de ciudadanía';
        selTipoDeCliente = 'Cliente No Honda'; 
        selOcupacion = '';

        // Recupera la cuenta del contacto
      // Recupera datos del lead actual
       ContactoEmail = [select MC_correo_electronico_prospecto__c
               from MC_Contactos__c where id = :sID];
        
        txtCorreoElectronico = ContactoEmail.MC_correo_electronico_prospecto__c;

        INPUT = true;

        // Llena la lista de Estados
        List<SelectOption> EstadoList = new List<SelectOption>();
        Map<String, String> EstadoPicklist = picklistValues('Account', 'AM_Estado__c');
        
        for (String value : EstadoPickList.keySet()) {
            EstadoList.add(new SelectOption(value, EstadoPickList.get(value)));
        }
        getCmbEstado = EstadoList;

        // Llena la lista de Tipo de Documento
        List<SelectOption> TipoDeDocumentoList = new List<SelectOption>();
        TipoDeDocumentoList.add(new SelectOption('Cédula de ciudadanía', 'Cédula de ciudadanía'));
        TipoDeDocumentoList.add(new SelectOption('Cédula de extranjería', 'Cédula de extranjería'));
        TipoDeDocumentoList.add(new SelectOption('NUIP', 'NUIP'));
        TipoDeDocumentoList.add(new SelectOption('Pasaporte', 'Pasaporte'));
        TipoDeDocumentoList.add(new SelectOption('Tarjeta de identidad', 'Tarjeta de identidad'));
        TipoDeDocumentoList.add(new SelectOption('Tarjeta de extranjería', 'Tarjeta de extranjería'));
        getCmbTipoDeDocumento = TipoDeDocumentoList;
        
        //Llena lista de Tipo de cliente
        List<SelectOption> TipoDeClienteList = new List<SelectOption>();
        Map<String, String> TipoDeClientePicklist = picklistValues('Account', 'AM_Tipo_de_usuario__c');
        
        for (String value : TipoDeClientePickList.keySet()) {
            TipoDeClienteList.add(new SelectOption(value, TipoDeClientePickList.get(value)));
        }
        getCmbTipoDeCliente = TipoDeClienteList;

        // Llena lista de ocupaciones
        List<SelectOption> OcupacionOptionList = new List<SelectOption>();
        Map<String, String> OcupacionPicklist = picklistValues('Account', 'AM_Ocupacion__pc');
        
        for (String value : OcupacionPickList.keySet()) {
            OcupacionOptionList.add(new SelectOption(value, OcupacionPickList.get(value)));
        }

        getCmbOcupacion = OcupacionOptionList;
    }
    
    public static Map<String, String> picklistValues(String objectName, String fieldName) {
        Map<String, String> values = new Map<String, String>{};
        List<Schema.DescribeSobjectResult> results = Schema.describeSObjects(new List<String>{objectName});
        for(Schema.DescribeSobjectResult res : results) {
            for (Schema.PicklistEntry entry : res.fields.getMap().get(fieldName).getDescribe().getPicklistValues()) {
                if (entry.isActive()) {
                    values.put(entry.getValue(), entry.getLabel());
                }
            }
        }
        return values;
    }
}