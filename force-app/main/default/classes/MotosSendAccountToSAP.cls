/**
* Fanalca
* @author           Jonathan Parrales
* Description:      Consume of Web Service class to create/update Account in SAP.
*
* Changes (Version)
* -------------------------------------
*           No.     Date            Author                  Description
*           -----   ----------      --------------------    ---------------
* @version  1.0     27/Nov/2020      Jonathan Parrales       Class definition.
* @version  1.1     		        Jonathan Parrales                    
*********************************************************************************************************/
public class MotosSendAccountToSAP {
    //MotosSendAccountToSAP.SendAccount('0011F00000kxC0ZQAU','C');
    public static final String Crear = 'C';
    public static final String Modificar = 'M';
    static final string urlSF =  URL.getSalesforceBaseUrl().toExternalForm();
    @AuraEnabled
    public static String SendAccount(Id accountId, String accion){
        try{
            Account objSF = [select Prefijo_Complemento__c, AM_Complemento__c, AM_Direccion__c,Digito_de_verificacion__c,Codigo_ERP__c, PersonMobilePhone, Autoriza_Tratamiento_Datos_Personales__c,Autoriza_Tratamiento_de_Datos_personale__pc,Id, RecordType.DeveloperName, Name, AM_Correo_Electronico_Trabajo__c, 
                           Salutation, Primer_Nombre__c,FirstName,Segundo_Nombre__c,LastName,Primer_Apellido__c,Segundo_Apellido__c,
                           PersonEmail,AM_Tipo_de_documento__c,AM_Numero_de_documento__c,Phone,
                           AM_Ciudad__r.ID_POBLACION_SAP__c,AM_Ciudad__r.ID_REGION_SAP__c,AM_Ciudad__r.ID_PAIS_SAP__c, DireccionERP__c,Fax,AM_Estado__c,Organizacion_Ventas__c from Account where Id=:accountId];
            
            if (objSF.Codigo_ERP__c!=null && accion == Crear ) throw new DMLException('No puede Enviar una Acción de Crear Cliente en SAP si éste ya Existe en SAP!');
            
            //get the organizacion de ventas o concesionario
            list<Miembro_de_Concesionario__c> lstConcesionarios = [select Id, Concesionario__r.Codigo_concesionario__c, Concesionario__r.Codigo_de_agencia__c from Miembro_de_Concesionario__c where Nombre_de_asesor__c=:UserInfo.getUserId()];
			system.debug('lstConcesionarios' + lstConcesionarios);
            system.debug('lstConcesionarios.size(): ' + lstConcesionarios.size());
            system.debug('UserInfo.getUserId(): ' + UserInfo.getUserId());
            FanalcaCrearModificarClientesSAP.DT_CUSTOMER_CR_MO objWS = new FanalcaCrearModificarClientesSAP.DT_CUSTOMER_CR_MO();
            objWS.TYPE_T = accion; //C para crear, M para modificar
            objWS.KUNNR = objSF.Codigo_ERP__c;//objSF.Id;
            if (lstConcesionarios.size()>0) objWS.VKORG = lstConcesionarios[0].Concesionario__r.Codigo_concesionario__c;
            //objWS.VKORG = objSF.Organizacion_Ventas__c;
            system.debug('objWS.VKORG: ' + objWS.VKORG);
            objWS.STCDT = Utilities.getTipoDocumentoSF_To_SAP(objSF.AM_Tipo_de_documento__c);
            objWS.STCD1 = objSF.AM_Numero_de_documento__c + (objSF.AM_Tipo_de_documento__c=='NIT' ? String.valueOf(objSF.Digito_de_verificacion__c) : '');
            system.debug('STCDT: ' + objWS.STCDT);
            system.debug('STCDT1: ' + objWS.STCD1);
            if(String.IsBlank(objSF.AM_Direccion__c)){
                if(String.IsBlank(objSF.Prefijo_Complemento__c) || String.IsBlank(objSF.AM_Complemento__c)){
                    return 'Error, no es posible crear una cuenta sin dirección en SAP.';
                } else {
                    objWS.STREET = (objSF.Prefijo_Complemento__c + ', ' + objSF.AM_Complemento__c);
                }
            } else {
                objWS.STREET = objSF.AM_Direccion__c;
            }
            
           // objWS.STREET = String.IsBlank(objSF.AM_Direccion__c) ? (objSF.Prefijo_Complemento__c + ', ' + objSF.AM_Complemento__c) : objSF.AM_Direccion__c;//objSF.AM_Direccion__c;//objSF.DireccionERP__c;
            objWS.ORT01 = objSF.AM_Ciudad__r.ID_POBLACION_SAP__c;
            objWS.REGIO = objSF.AM_Ciudad__r.ID_REGION_SAP__c;
            objWS.LAND1 = objSF.AM_Ciudad__r.ID_PAIS_SAP__c;
            objWS.TELF1 = objSF.Phone;
            objWS.SKFTO =  objSF.AM_Estado__c == 'Inactivo' ? 'X' : ''; 
            if (objSF.RecordType.DeveloperName ==Label.MotosRecordTypeDevNameAccountNatural){
                objWS.ANRED = Utilities.getSalutationSF_To_SAP(objSF.Salutation);
                objWS.NAME1_P = objSF.FirstName;
                objWS.NAME1_S = objSF.Segundo_Nombre__c;
                objWS.NAME2_P = objSF.LastName;
                objWS.NAME2_S = objSF.Segundo_Apellido__c;
                objWS.CEL_NUMBER = objSF.PersonMobilePhone;
                objWS.SMTP_ADDR_P = objSF.PersonEmail;
                objWS.EXTENSION1 = objSF.Autoriza_Tratamiento_de_Datos_personale__pc=='Si' ? 'Z01' : 'Z02'; //Preguntar a SAul
                objWS.NAME1 = objSF.FirstName + (String.isBlank(objSF.Segundo_Nombre__c) ? ' ' : (' ' + objSF.Segundo_Nombre__c + ' ') ) + objSF.LastName + (String.isBlank(objSF.Segundo_Apellido__c) ? '' : ' ' + objSF.Segundo_Apellido__c);
                system.debug('Extension1' + objWS.EXTENSION1);
            }
            if (objSF.RecordType.DeveloperName ==Label.MotosRecordTypeDevNameAccountJuridica){
                objWS.ANRED = '0003'; //Empresa
                objWS.NAME1 = objSF.Name;
                objWS.SMTP_ADDR_E = objSF.AM_Correo_Electronico_Trabajo__c;
                objWS.EXTENSION1 = objSF.Autoriza_Tratamiento_Datos_Personales__c=='Si' ? 'Z01' : 'Z02'; //Preguntar a SAul
            }
            
           //objWS.EXTENSION1 = 'Z03';//z03 venía de ejemplo en el documento de analisis tecnico, mensaje de error si no lo seteo: 'Aut. Cont. es un campo obligatorio'
           objWS.EXTENSION2 = '02'; //002 venía de ejemplo en el documento de analisis técnico, mensaje de error si no lo seteo: 'Clase de impuesto es un campo obligatorio' 
           
           //objWS.TYPE_T = 'C';
           //objWS.KUNNR = '';
           //objWS.STCD1 = '79946946' ;
           //objWS.STCDT='13';
           //objWS.ANRED = ;
           //bjWS.NAME1='Crear cliente';
           //objWS.SMTP_ADDR_P='mail@gmail.com';
           //objWS.ORT01='66045';    
           //objWS.STREET='Calle de por ahi';    
           //objWS.REGIO='66';
           //objWS.LAND1='CO';
           //objWS.TELF1='3959595';
           //objWS.SKFTO = '';
           //objWS.VKORG='1200'; 
           //objWS.EXTENSION1='Z01'; 
           //objWS.EXTENSION2='02'; 
            
            FanalcaCrearModificarClientesSAP.HTTPS_Port enviarWS = new FanalcaCrearModificarClientesSAP.HTTPS_Port();
            Blob headerValue = Blob.valueOf(Label.FanalcaWSUser+':'+Label.FanalcaWSPassword);string authorizationHeader ='Basic '+EncodingUtil.base64Encode(headerValue);
            enviarWS.inputHttpHeaders_x = new Map<String, String>();enviarWS.inputHttpHeaders_x.put('Authorization',authorizationHeader); 
            enviarWS.inputHttpHeaders_x.put('Content-Type', 'application/soap+xml');
            enviarWS.timeout_x = 8000;
            
            //*enviarWS.clientCertName_x='FanalcaClienteSAPCertificate';
        	//enviarWS.clientCert_x='wsuser';
        	//enviarWS.clientCertPasswd_x='beta1234';
            
             FanalcaCrearModificarClientesSAP.DT_RESPONSE respuesta = 
                 //enviarWS.CREATE('C','10000','79946946','13','','Nombre','nombre1', 'mombre2','apellido1','apellido2', '', 'mail@gmail.com','', '66045', 'any calle', '66', 
                 //                'CO', '3959595', '', '1200', 'Z01', '02', '','', '', '', '', '', '', '');
            
                 //enviarWS.CREATE(objWS.TYPE_T,objWS.KUNNR,objWS.STCD1,objWS.STCDT,objWS.ANRED,objWS.Name1,objWS.NAME1_P, objWS.NAME1_S, objWS.NAME2_P, objWS.NAME2_S, objWS.CEL_NUMBER, objWS.SMTP_ADDR_E, objWS.SMTP_ADDR_P, objWS.ORT01, objWS.STREET, objWS.REGIO, 
                 //                objWS.LAND1, objWS.TELF1, objWS.SKFTO, objWS.VKORG, objWS.EXTENSION1, objWS.EXTENSION2, objWS.EXTENSION3, objWS.EXTENSION4, objWS.EXTENSION5, objWS.EXTENSION6, objWS.EXTENSION7, objWS.EXTENSION8, objWS.EXTENSION9, objWS.EXTENSION10);
                 //enviarWS.CREATE(TYPE_T, KUNNR, STCD1, STCDT, ANRED, NAME1, NAME1_P, NAME1_S, NAME2_P, NAME2_S, CEL_NUMBER, SMTP_ADDR_E, SMTP_ADDR_P, ORT01, STREET, REGIO, LAND1, TELF1, SKFTO, VKORG, EXTENSION1, EXTENSION2, EXTENSION3, EXTENSION4, EXTENSION5, EXTENSION6, EXTENSION7, EXTENSION8, EXTENSION9, EXTENSION10)
                 enviarWS.SendToSAP(objWS);
            
            Log__c log = new Log__c();
            log.body__c =JSON.serialize(objWS);
            log.Web_Service__c = 'AccountToSAP';
            system.debug('body__c: ' + log.body__c);
            insert log;
           system.debug('Respuesta: ' + respuesta); 
           system.debug('TYPE_x: ' + respuesta.TYPE_x); //E para error, S para éxito
           system.debug('MSSGS: ' + respuesta.MSSGS);
           system.debug('KUNNR: ' + respuesta.KUNNR); 
            if (respuesta.TYPE_x=='S' ){
                //objSF.Codigo_ERP__c = respuesta.KUNNR;
                //update objSF;
                system.debug('Respuesta exitosa del WS.');
                if (accion == Crear ) {
                	Account accUpdate = new Account(Id=objSF.Id,Codigo_ERP__c = prefixZeroes(respuesta.KUNNR) );
                	update accUpdate;
                    return respuesta.MSSGS + '. Código SAP: ' + respuesta.KUNNR;
                }
                else {
                    //String mensajeEmail = respuesta.MSSGS + '. Código SAP: ' + respuesta.KUNNR + '<br />'+ '<a href="'+ urlSF + '/' + objSF.Id +'">Click aquí para ver la Cuenta</a>';
                    //EMailManager.sendEmail('Actualización de Cliente SAP desde Salesforce - ' + objSF.Name,UserInfo.getUserEmail() + ';' + Label.RecipientesEmailConsumoWSAccount, mensajeEmail);
                 	return respuesta.MSSGS;   
                }
            }else{
                //if (accion=='M'){
                //    String mensajeEmail = respuesta.MSSGS + '. Código SAP: ' + respuesta.KUNNR + '<br />'+ '<a href="'+ urlSF + '/' + objSF.Id +'">Click aquí para ver la Cuenta</a>';
                //    EMailManager.sendEmail('Error en Actualización de Cliente SAP desde Salesforce - ' + objSF.Name,UserInfo.getUserEmail() + ';' +Label.RecipientesEmailConsumoWSAccount, mensajeEmail);    
                //}               
                return 'Error: ' + respuesta.MSSGS;
            }
            
        }catch(CalloutException ex){ return 'Error: ' + ex.getMessage();    }
        catch(Exception ex){
            system.debug('Error: ' + ex.getMessage());
            //if (accion=='M'){
            //    String mensajeEmail = ex.getMessage() + '<br />'+ '<a href="'+ urlSF + '/' + accountId +'">Click aquí para ver la Cuenta</a>';
            //    EMailManager.sendEmail('Error en Actualización de Cliente SAP desde Salesforce',UserInfo.getUserEmail() + ';' +Label.RecipientesEmailConsumoWSAccount, mensajeEmail);    
            //} 
            return 'Error: ' + ex.getMessage();
        }
        
        
    }
    //Send Account to SAP without DML operations
    public static String SendAccountOrder(Id accountId, String accion){
        try{
            Account objSF = [select Prefijo_Complemento__c, AM_Complemento__c, AM_Direccion__c,Digito_de_verificacion__c,Codigo_ERP__c, PersonMobilePhone, Autoriza_Tratamiento_Datos_Personales__c,Autoriza_Tratamiento_de_Datos_personale__pc,Id, RecordType.DeveloperName, Name, AM_Correo_Electronico_Trabajo__c, 
                           Salutation, Primer_Nombre__c,FirstName,Segundo_Nombre__c,LastName,Primer_Apellido__c,Segundo_Apellido__c,
                           PersonEmail,AM_Tipo_de_documento__c,AM_Numero_de_documento__c,Phone,
                           AM_Ciudad__r.ID_POBLACION_SAP__c,AM_Ciudad__r.ID_REGION_SAP__c,AM_Ciudad__r.ID_PAIS_SAP__c, DireccionERP__c,Fax,AM_Estado__c,Organizacion_Ventas__c from Account where Id=:accountId];
            
            if (objSF.Codigo_ERP__c!=null && accion == Crear ) throw new DMLException('No puede Enviar una Acción de Crear Cliente en SAP si éste ya Existe en SAP!');
            
            //get the organizacion de ventas o concesionario
            list<Miembro_de_Concesionario__c> lstConcesionarios = [select Id, Concesionario__r.Codigo_concesionario__c, Concesionario__r.Codigo_de_agencia__c from Miembro_de_Concesionario__c where Nombre_de_asesor__c=:UserInfo.getUserId()];
			system.debug('lstConcesionarios' + lstConcesionarios);
            system.debug('lstConcesionarios.size(): ' + lstConcesionarios.size());
            system.debug('UserInfo.getUserId(): ' + UserInfo.getUserId());
            FanalcaCrearModificarClientesSAP.DT_CUSTOMER_CR_MO objWS = new FanalcaCrearModificarClientesSAP.DT_CUSTOMER_CR_MO();
            objWS.TYPE_T = accion; //C para crear, M para modificar
            objWS.KUNNR = objSF.Codigo_ERP__c;//objSF.Id;
            if (lstConcesionarios.size()>0) objWS.VKORG = lstConcesionarios[0].Concesionario__r.Codigo_concesionario__c;
            //objWS.VKORG = objSF.Organizacion_Ventas__c;
            system.debug('objWS.VKORG: ' + objWS.VKORG);
            objWS.STCDT = Utilities.getTipoDocumentoSF_To_SAP(objSF.AM_Tipo_de_documento__c);
            objWS.STCD1 = objSF.AM_Numero_de_documento__c + (objSF.AM_Tipo_de_documento__c=='NIT' ? String.valueOf(objSF.Digito_de_verificacion__c) : '');
            system.debug('STCDT: ' + objWS.STCDT);
            system.debug('STCDT1: ' + objWS.STCD1);
            objWS.STREET = String.IsBlank(objSF.AM_Direccion__c) ? (objSF.Prefijo_Complemento__c + ', ' + objSF.AM_Complemento__c) : objSF.AM_Direccion__c;//objSF.AM_Direccion__c;//objSF.DireccionERP__c;
            objWS.ORT01 = objSF.AM_Ciudad__r.ID_POBLACION_SAP__c;
            objWS.REGIO = objSF.AM_Ciudad__r.ID_REGION_SAP__c;
            objWS.LAND1 = objSF.AM_Ciudad__r.ID_PAIS_SAP__c;
            objWS.TELF1 = objSF.Phone;
            objWS.SKFTO =  objSF.AM_Estado__c == 'Inactivo' ? 'X' : ''; 
            if (objSF.RecordType.DeveloperName ==Label.MotosRecordTypeDevNameAccountNatural){
                objWS.ANRED = Utilities.getSalutationSF_To_SAP(objSF.Salutation);
                objWS.NAME1_P = objSF.FirstName;
                objWS.NAME1_S = objSF.Segundo_Nombre__c;
                objWS.NAME2_P = objSF.LastName;
                objWS.NAME2_S = objSF.Segundo_Apellido__c;
                objWS.CEL_NUMBER = objSF.PersonMobilePhone;
                objWS.SMTP_ADDR_P = objSF.PersonEmail;
                objWS.EXTENSION1 = objSF.Autoriza_Tratamiento_de_Datos_personale__pc=='Si' ? 'Z01' : 'Z02'; //Preguntar a SAul
                objWS.NAME1 = objSF.FirstName + (String.isBlank(objSF.Segundo_Nombre__c) ? ' ' : (' ' + objSF.Segundo_Nombre__c + ' ') ) + objSF.LastName + (String.isBlank(objSF.Segundo_Apellido__c) ? '' : ' ' + objSF.Segundo_Apellido__c);
                system.debug('Extension1' + objWS.EXTENSION1);
            }
            if (objSF.RecordType.DeveloperName ==Label.MotosRecordTypeDevNameAccountJuridica){
                objWS.ANRED = '0003'; //Empresa
                objWS.NAME1 = objSF.Name;
                objWS.SMTP_ADDR_E = objSF.AM_Correo_Electronico_Trabajo__c;
                objWS.EXTENSION1 = objSF.Autoriza_Tratamiento_Datos_Personales__c=='Si' ? 'Z01' : 'Z02'; //Preguntar a SAul
            }
            
           objWS.EXTENSION2 = '02'; //002 venía de ejemplo en el documento de analisis técnico, mensaje de error si no lo seteo: 'Clase de impuesto es un campo obligatorio' 
         
            
            FanalcaCrearModificarClientesSAP.HTTPS_Port enviarWS = new FanalcaCrearModificarClientesSAP.HTTPS_Port();
            Blob headerValue = Blob.valueOf(Label.FanalcaWSUser+':'+Label.FanalcaWSPassword);string authorizationHeader ='Basic '+EncodingUtil.base64Encode(headerValue);
            enviarWS.inputHttpHeaders_x = new Map<String, String>();enviarWS.inputHttpHeaders_x.put('Authorization',authorizationHeader); 
            enviarWS.inputHttpHeaders_x.put('Content-Type', 'application/soap+xml');
            enviarWS.timeout_x = 8000;
          
            
             FanalcaCrearModificarClientesSAP.DT_RESPONSE respuesta = 
                 enviarWS.SendToSAP(objWS);
            
           
            
            //insertLog(JSON.serialize(objWS), 'AccountToSAP');
            //insert log;
          
            if (respuesta.TYPE_x=='S' ){
                //objSF.Codigo_ERP__c = respuesta.KUNNR;
                //update objSF;
                system.debug('Respuesta exitosa del WS.');
                if (accion == Crear ) {
                	//Account accUpdate = new Account(Id=objSF.Id,Codigo_ERP__c = respuesta.KUNNR );
                	//update accUpdate;
                    return prefixZeroes(respuesta.KUNNR);//respuesta.MSSGS + '. Código SAP: ' + respuesta.KUNNR;
                }
                else {
                    //String mensajeEmail = respuesta.MSSGS + '. Código SAP: ' + respuesta.KUNNR + '<br />'+ '<a href="'+ urlSF + '/' + objSF.Id +'">Click aquí para ver la Cuenta</a>';
                    //EMailManager.sendEmail('Actualización de Cliente SAP desde Salesforce - ' + objSF.Name,UserInfo.getUserEmail() + ';' + Label.RecipientesEmailConsumoWSAccount, mensajeEmail);
                 	return respuesta.MSSGS;   
                }
            }else{
                //if (accion=='M'){
                    //String mensajeEmail = respuesta.MSSGS + '. Código SAP: ' + respuesta.KUNNR + '<br />'+ '<a href="'+ urlSF + '/' + objSF.Id +'">Click aquí para ver la Cuenta</a>';
                    //EMailManager.sendEmail('Error en Actualización de Cliente SAP desde Salesforce - ' + objSF.Name,UserInfo.getUserEmail() + ';' +Label.RecipientesEmailConsumoWSAccount, mensajeEmail);    
                //}               
                return 'Error: ' + respuesta.MSSGS;
            }
            
        }catch(CalloutException ex){ return 'Error: ' + ex.getMessage();    }
        catch(Exception ex){
            system.debug('Error: ' + ex.getMessage());
            //if (accion=='M'){
            //    String mensajeEmail = ex.getMessage() + '<br />'+ '<a href="'+ urlSF + '/' + accountId +'">Click aquí para ver la Cuenta</a>';
            //    EMailManager.sendEmail('Error en Actualización de Cliente SAP desde Salesforce',UserInfo.getUserEmail() + ';' +Label.RecipientesEmailConsumoWSAccount, mensajeEmail);    
            //} 
            return 'Error: ' + ex.getMessage();
        }
        
        
    }
    /*
    @future
    private static void insertLog(String body, string strWebService){ 
     	Log__c log = new Log__c();
        log.body__c =body;
        log.Web_Service__c = strWebService;
        insert log;
    }*/
    /*
    public static void SendAccountBulk(set<Id> accountIds, String accion){
        try{
            list<Account> lstAccounts = [select Digito_de_verificacion__c,Codigo_ERP__c, PersonMobilePhone, Autoriza_Tratamiento_Datos_Personales__c,Autoriza_Tratamiento_de_Datos_personale__pc,Id, RecordType.DeveloperName, Name, AM_Correo_Electronico_Trabajo__c, 
                           Salutation, Primer_Nombre__c,FirstName,Segundo_Nombre__c,LastName,Primer_Apellido__c,Segundo_Apellido__c,
                           PersonEmail,AM_Tipo_de_documento__c,AM_Numero_de_documento__c,Phone,
                           AM_Ciudad__r.ID_POBLACION_SAP__c,AM_Ciudad__r.ID_REGION_SAP__c,AM_Ciudad__r.ID_PAIS_SAP__c, DireccionERP__c,Fax,AM_Estado__c,Organizacion_Ventas__c from Account where Id in:accountIds];
            
       
            
            list<Log__c> lstLogsInsertar = new list<Log__c>();
            //get the organizacion de ventas o concesionario
            list<Miembro_de_Concesionario__c> lstConcesionarios = [select Id, Concesionario__r.Codigo_concesionario__c, Concesionario__r.Codigo_de_agencia__c from Miembro_de_Concesionario__c where Nombre_de_asesor__c=:UserInfo.getUserId()];
            
        	for (Account objSF: lstAccounts){
                if (objSF.Codigo_ERP__c!=null && accion == Crear ) throw new DMLException('No puede Enviar una Acción de Crear Cliente en SAP si éste ya Existe en SAP!');
                
                FanalcaCrearModificarClientesSAP.DT_CUSTOMER_CR_MO objWS = new FanalcaCrearModificarClientesSAP.DT_CUSTOMER_CR_MO();
                objWS.TYPE_T = accion; //C para crear, M para modificar
                objWS.KUNNR = objSF.Codigo_ERP__c;//objSF.Id;
                if (lstConcesionarios.size()>0) objWS.VKORG = lstConcesionarios[0].Concesionario__r.Codigo_concesionario__c;
                //objWS.VKORG = objSF.Organizacion_Ventas__c;
                objWS.STCDT = Utilities.getTipoDocumentoSF_To_SAP(objSF.AM_Tipo_de_documento__c);
                objWS.STCD1 = objSF.AM_Numero_de_documento__c + (objSF.AM_Tipo_de_documento__c=='NIT' ? String.valueOf(objSF.Digito_de_verificacion__c) : '');
                
                objWS.STREET = objSF.DireccionERP__c;
                objWS.ORT01 = objSF.AM_Ciudad__r.ID_POBLACION_SAP__c;
                objWS.REGIO = objSF.AM_Ciudad__r.ID_REGION_SAP__c;
                objWS.LAND1 = objSF.AM_Ciudad__r.ID_PAIS_SAP__c;
                objWS.TELF1 = objSF.Phone;
                objWS.SKFTO =  objSF.AM_Estado__c == 'Inactivo' ? 'X' : ''; 
                if (objSF.RecordType.DeveloperName ==Label.MotosRecordTypeDevNameAccountNatural){
                    objWS.ANRED = Utilities.getSalutationSF_To_SAP(objSF.Salutation);
                    objWS.NAME1_P = objSF.FirstName;
                    objWS.NAME1_S = objSF.Segundo_Nombre__c;
                    objWS.NAME2_P = objSF.LastName;
                    objWS.NAME2_S = objSF.Segundo_Apellido__c;
                    objWS.CEL_NUMBER = objSF.PersonMobilePhone;
                    objWS.SMTP_ADDR_P = objSF.PersonEmail;
                    objWS.EXTENSION1 = objSF.Autoriza_Tratamiento_de_Datos_personale__pc=='Si' ? 'Z01' : 'Z02'; //Preguntar a SAul
                    objWS.NAME1 = objSF.FirstName + (String.isBlank(objSF.Segundo_Nombre__c) ? ' ' : (' ' + objSF.Segundo_Nombre__c + ' ') ) + objSF.LastName + (String.isBlank(objSF.Segundo_Apellido__c) ? '' : ' ' + objSF.Segundo_Apellido__c);
                    system.debug('Extension1' + objWS.EXTENSION1);
                }
                if (objSF.RecordType.DeveloperName ==Label.MotosRecordTypeDevNameAccountJuridica){
                    objWS.ANRED = '0003'; //Empresa
                    objWS.NAME1 = objSF.Name;
                    objWS.SMTP_ADDR_E = objSF.AM_Correo_Electronico_Trabajo__c;
                    objWS.EXTENSION1 = objSF.Autoriza_Tratamiento_Datos_Personales__c=='Si' ? 'Z01' : 'Z02'; //Preguntar a SAul
                }
                
               //objWS.EXTENSION1 = 'Z03';//z03 venía de ejemplo en el documento de analisis tecnico, mensaje de error si no lo seteo: 'Aut. Cont. es un campo obligatorio'
               objWS.EXTENSION2 = '02'; //002 venía de ejemplo en el documento de analisis técnico, mensaje de error si no lo seteo: 'Clase de impuesto es un campo obligatorio' 
              
                FanalcaCrearModificarClientesSAP.HTTPS_Port enviarWS = new FanalcaCrearModificarClientesSAP.HTTPS_Port();
                Blob headerValue = Blob.valueOf(Label.FanalcaWSUser+':'+Label.FanalcaWSPassword);string authorizationHeader ='Basic '+EncodingUtil.base64Encode(headerValue);
                enviarWS.inputHttpHeaders_x = new Map<String, String>();enviarWS.inputHttpHeaders_x.put('Authorization',authorizationHeader); 
                enviarWS.inputHttpHeaders_x.put('Content-Type', 'application/soap+xml');
                enviarWS.timeout_x = 8000;
        
                 FanalcaCrearModificarClientesSAP.DT_RESPONSE respuesta = 
                     //enviarWS.CREATE('C','10000','79946946','13','','Nombre','nombre1', 'mombre2','apellido1','apellido2', '', 'mail@gmail.com','', '66045', 'any calle', '66', 
                     //                'CO', '3959595', '', '1200', 'Z01', '02', '','', '', '', '', '', '', '');
                
                     //enviarWS.CREATE(objWS.TYPE_T,objWS.KUNNR,objWS.STCD1,objWS.STCDT,objWS.ANRED,objWS.Name1,objWS.NAME1_P, objWS.NAME1_S, objWS.NAME2_P, objWS.NAME2_S, objWS.CEL_NUMBER, objWS.SMTP_ADDR_E, objWS.SMTP_ADDR_P, objWS.ORT01, objWS.STREET, objWS.REGIO, 
                     //                objWS.LAND1, objWS.TELF1, objWS.SKFTO, objWS.VKORG, objWS.EXTENSION1, objWS.EXTENSION2, objWS.EXTENSION3, objWS.EXTENSION4, objWS.EXTENSION5, objWS.EXTENSION6, objWS.EXTENSION7, objWS.EXTENSION8, objWS.EXTENSION9, objWS.EXTENSION10);
                     //enviarWS.CREATE(TYPE_T, KUNNR, STCD1, STCDT, ANRED, NAME1, NAME1_P, NAME1_S, NAME2_P, NAME2_S, CEL_NUMBER, SMTP_ADDR_E, SMTP_ADDR_P, ORT01, STREET, REGIO, LAND1, TELF1, SKFTO, VKORG, EXTENSION1, EXTENSION2, EXTENSION3, EXTENSION4, EXTENSION5, EXTENSION6, EXTENSION7, EXTENSION8, EXTENSION9, EXTENSION10)
                     enviarWS.SendToSAP(objWS);
                
                system.debug('Respuesta: ' + respuesta); 
                system.debug('TYPE_x: ' + respuesta.TYPE_x); //E para error, S para éxito
                system.debug('MSSGS: ' + respuesta.MSSGS);
                system.debug('KUNNR: ' + respuesta.KUNNR);
                
                Log__c log = new Log__c();
                log.body__c =JSON.serialize(objWS);
                log.Web_Service__c = 'AccountToSAP';
                
                lstLogsInsertar.add(log);
                
                if (respuesta.TYPE_x=='S' ){
                    //objSF.Codigo_ERP__c = respuesta.KUNNR;
                    //update objSF;
                    system.debug('Respuesta exitosa del WS.');
                    if (accion == Crear ) {
                        Account accUpdate = new Account(Id=objSF.Id,Codigo_ERP__c = respuesta.KUNNR );
                        update accUpdate;
                        system.debug(respuesta.MSSGS + '. Código SAP: ' + respuesta.KUNNR);//return respuesta.MSSGS + '. Código SAP: ' + respuesta.KUNNR;
                    }
                    else {
                        String mensajeEmail = respuesta.MSSGS + '. Código SAP: ' + respuesta.KUNNR + '<br />'+ '<a href="'+ urlSF + '/' + objSF.Id +'">Click aquí para ver la Cuenta</a>';
                        EMailManager.sendEmail('Actualización de Cliente SAP desde Salesforce - ' + objSF.Name,UserInfo.getUserEmail() + ';' + Label.RecipientesEmailConsumoWSAccount, mensajeEmail);
                        system.debug(respuesta.MSSGS);//return respuesta.MSSGS;   
                    }
                }else{
                    if (accion=='M'){
                        String mensajeEmail = respuesta.MSSGS + '. Código SAP: ' + respuesta.KUNNR + '<br />'+ '<a href="'+ urlSF + '/' + objSF.Id +'">Click aquí para ver la Cuenta</a>';
                        EMailManager.sendEmail('Error en Actualización de Cliente SAP desde Salesforce - ' + objSF.Name,UserInfo.getUserEmail() + ';' +Label.RecipientesEmailConsumoWSAccount, mensajeEmail);    
                    }               
                    system.debug(respuesta.MSSGS);//return 'Error: ' + respuesta.MSSGS;
                }
                
            }
            
            
            
            
            insert lstLogsInsertar;
            
            
            
        }catch(CalloutException ex){ system.debug(ex.getMessage());    }
        catch(Exception ex){
            system.debug('Error: ' + ex.getMessage());
            if (accion=='M'){
                String mensajeEmail = ex.getMessage(); //+ '<br />'+ '<a href="'+ urlSF + '/' + accountId +'">Click aquí para ver la Cuenta</a>';
                EMailManager.sendEmail('Error en Actualización de Cliente SAP desde Salesforce',UserInfo.getUserEmail() + ';' +Label.RecipientesEmailConsumoWSAccount, mensajeEmail);    
            } 
            //return 'Error: ' + ex.getMessage();
        }
        
        
    }
    */
    
    private static String prefixZeroes(String codigo){
        if (!String.isBlank(codigo) && codigo.length() < 10) {
            return '0'.repeat(10 - codigo.length()) + codigo;
        }else return codigo;
    }
}