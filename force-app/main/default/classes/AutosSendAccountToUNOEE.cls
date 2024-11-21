/**
* Fanalca
* @author           Jonathan Parrales
* Description:      Consume of Web Service class to create/update Account in UNOEE.
*
* Changes (Version)
* -------------------------------------
*           No.     Date            Author                  Description
*           -----   ----------      --------------------    ---------------
* @version  1.0     March/01/2021   Jonathan Parrales       Class definition.      
* @version  1.1     June/30/2021    Jonathan Parrales       Add insertion of logs record.   
*********************************************************************************************************/
public class AutosSendAccountToUNOEE {
    //AutosSendAccountToUNOEE.SendAccount('0010100000Boz62AAB');0010100000CN614AAD
    public static FanalcaCrearModificarClientesUNOEE2.DT_CREATE_CUSTOMER objWS = new FanalcaCrearModificarClientesUNOEE2.DT_CREATE_CUSTOMER();
    @AuraEnabled
    public static String SendAccount(Id accountId){
        try{
            Account objSF = [select AM_Telefono_representante__c , Creado_en_UNOEE__c, Phone, IsPersonAccount, Id, AM_Numero_de_documento__c,AM_Tipo_de_documento__c,
                             Primer_nombre__c, FirstName, Segundo_Nombre__c, LastName, Segundo_Apellido__c, Name,Primer_apellido__c,
                             Sucursal__c, AM_Direccion__c, Fax, PersonMobilePhone, MC_Correo_electronico_Empresa__c,PersonEmail,Codigo_Postal__c,
                             AM_Ciudad__r.ID_UNOEE__c, AM_Ciudad_representante__r.ID_UNOEE__c, MC_Autoriza_tratardatos_personales__c
                             from Account where Id=:accountId];    
            
            
            //mapeo de campos
            objWS.nit = objSF.AM_Numero_de_documento__c;
            objWS.id_tipo_ident = Utilities.getTipoDocumentoSF_To_UNOEE(objSF.AM_Tipo_de_documento__c);
            objWS.ind_tipo_tercero = objSF.IsPersonAccount ? 1 : 2;
            if (objSF.IsPersonAccount) objWS.razon_social =(objSF.FirstName + ' ' + (String.isBlank(objSF.Segundo_Nombre__c) ? '' : objSF.Segundo_Nombre__c) + ' ' + objSF.LastName + ' ' + (String.isBlank(objSF.Segundo_Apellido__c) ? '' : objSF.Segundo_Apellido__c)).replace('  ', ' ');
            else objWS.razon_social = objSF.Name;
            objWS.apellido1 = objSF.LastName;//objSF.Primer_apellido__c;
            objWS.apelido2 = objSF.Segundo_Apellido__c;
            objWS.nombre1 = objSF.FirstName;//objSF.Primer_nombre__c;
            objWS.nombre2 = objSF.Segundo_Nombre__c;
            objWS.codigoPostal = objSF.Codigo_Postal__c;
            if (objSF.IsPersonAccount) objWS.id_sucursal = '001'; //T82 en CrearModificarClienteenUNOEE en excel de autos integraciones
            else objWS.id_sucursal = objSF.Sucursal__c;
            objWS.descripcion_sucursal = objWS.razon_social;
            if (! String.isBlank(objSF.AM_Direccion__c)){
                objWS.direccion1 = objSF.AM_Direccion__c.left(40);
                if (objSF.AM_Direccion__c.length() > 40) objWS.direccion2 = objSF.AM_Direccion__c.substring(40).left(40);
            }
            //objWS.direccion1 =  objSF.AM_Direccion__c; //TODO: los primeros 40 chars
            //objWS.direccion2 = objSF.; los siguientes 40 chars
            objWS.fax = objSF.Phone; 
            objWS.celular = objSF.IsPersonAccount ? objSF.PersonMobilePhone : objSF.AM_Telefono_representante__c; //Todo ask about this, in excel is written down to be maped to Phone
            objWS.email_emp = objSF.MC_Correo_electronico_Empresa__c;
            objWS.email_persona = objSF.PersonEmail;
            
            if(objSF.AM_Ciudad_representante__r.ID_UNOEE__c != null){
                objWS.id_ciudad = objSF.AM_Ciudad_representante__r.ID_UNOEE__c;
            }
            if(objSF.AM_Ciudad__r.ID_UNOEE__c != null) {
                objWS.id_ciudad = objSF.AM_Ciudad__r.ID_UNOEE__c;
            }
            objWS.autoriza_datos = objSF.MC_Autoriza_tratardatos_personales__c;
            objWS.cupo_credito = 0.00; //ver fila 89 del excel
            system.debug(' web service request @@@@ ' + JSON.serializePretty( objWS ) );
            
            FanalcaCrearModificarClientesUNOEE2.HTTPS_Port enviarWS = new FanalcaCrearModificarClientesUNOEE2.HTTPS_Port();
            Blob headerValue = Blob.valueOf(Label.FanalcaWSUser+':'+Label.FanalcaWSPassword);string authorizationHeader ='Basic '+EncodingUtil.base64Encode(headerValue);
            enviarWS.inputHttpHeaders_x = new Map<String, String>();enviarWS.inputHttpHeaders_x.put('Authorization',authorizationHeader); 
            enviarWS.inputHttpHeaders_x.put('Content-Type', 'application/soap+xml');
            enviarWS.timeout_x = 8000;
            
            String respuesta = 
                 enviarWS.SendToUNOEE(objWS);
            
            system.debug('respuesta:' + respuesta);
            system.debug('enviarWS.outputHttpHeaders_x:' + enviarWS.outputHttpHeaders_x);
            
            //Si respuesta es exitosa
            if (respuesta == '200' && objSF.Creado_en_UNOEE__c==false){
                Account a = new Account (Id = accountId, Creado_en_UNOEE__c=true);
                update a;
            }
            
            Log__c log = new Log__c();
            log.Body__c = JSON.serialize(objWS);
            log.Response__c =respuesta;
            log.Web_Service__c = 'AutosSendAccountToUNOEE.SendAccount';
            insert log;
            return respuesta;
           
        }catch(CalloutException ex){system.debug('Error: ' + ex.getMessage()); return 'Error: ' + ex.getMessage();}
        catch(Exception ex){
            system.debug('Error: ' + ex.getMessage());
            
            Log__c log = new Log__c();
            log.Body__c = JSON.serialize(objWS);
            log.Response__c ='Error: ' + ex.getMessage();
            log.Web_Service__c = 'AutosSendAccountToUNOEE.SendAccount';
            insert log;
            
            return 'Error: ' + ex.getMessage();
        }
        
        
    }
    
    @AuraEnabled
    public static String SendAccountFacturar(Id accountId, double totalOpp){
        try{
            Account objSF = [select AM_Telefono_representante__c , Creado_en_UNOEE__c, Phone, IsPersonAccount, Id, AM_Numero_de_documento__c,AM_Tipo_de_documento__c,
                             Primer_nombre__c, FirstName, Segundo_Nombre__c, LastName, Segundo_Apellido__c, Name,Primer_apellido__c,Codigo_Postal__c,
                             Sucursal__c, AM_Direccion__c, Fax, PersonMobilePhone, MC_Correo_electronico_Empresa__c,PersonEmail,
                             AM_Ciudad__r.ID_UNOEE__c, MC_Autoriza_tratardatos_personales__c, AM_Ciudad_representante__r.ID_UNOEE__c
                             from Account where Id=:accountId];
            
            
            FanalcaCrearModificarClientesUNOEE2.DT_CREATE_CUSTOMER objWS = new FanalcaCrearModificarClientesUNOEE2.DT_CREATE_CUSTOMER();
            
            //mapeo de campos
            objWS.nit = objSF.AM_Numero_de_documento__c;
            objWS.id_tipo_ident = Utilities.getTipoDocumentoSF_To_UNOEE(objSF.AM_Tipo_de_documento__c);
            objWS.ind_tipo_tercero = objSF.IsPersonAccount ? 1 : 2;
            objWS.codigoPostal = objSF.Codigo_Postal__c;
            if (objSF.IsPersonAccount) objWS.razon_social =(objSF.FirstName + ' ' + (String.isBlank(objSF.Segundo_Nombre__c) ? '' : objSF.Segundo_Nombre__c) + ' ' + objSF.LastName + ' ' + (String.isBlank(objSF.Segundo_Apellido__c) ? '' : objSF.Segundo_Apellido__c)).replace('  ', ' ');
            else objWS.razon_social = objSF.Name;
            objWS.apellido1 = objSF.LastName;//objSF.Primer_apellido__c;
            objWS.apelido2 = objSF.Segundo_Apellido__c;
            objWS.nombre1 = objSF.FirstName;//objSF.Primer_nombre__c;
            objWS.nombre2 = objSF.Segundo_Nombre__c;
            if (objSF.IsPersonAccount) objWS.id_sucursal = '001'; //T82 en CrearModificarClienteenUNOEE en excel de autos integraciones
            else objWS.id_sucursal = objSF.Sucursal__c;
            objWS.descripcion_sucursal = objWS.razon_social;
            if (! String.isBlank(objSF.AM_Direccion__c)){
                objWS.direccion1 = objSF.AM_Direccion__c.left(40);
                if (objSF.AM_Direccion__c.length() > 40) objWS.direccion2 = objSF.AM_Direccion__c.substring(40).left(40);
            }
            //objWS.direccion1 =  objSF.AM_Direccion__c; //TODO: los primeros 40 chars
            //objWS.direccion2 = objSF.; los siguientes 40 chars
            objWS.fax = objSF.Phone; 
            objWS.celular = objSF.IsPersonAccount ? objSF.PersonMobilePhone : objSF.AM_Telefono_representante__c; //Todo ask about this, in excel is written down to be maped to Phone
            objWS.email_emp = objSF.MC_Correo_electronico_Empresa__c;
            objWS.email_persona = objSF.PersonEmail;
            if(objSF.AM_Ciudad_representante__r.ID_UNOEE__c != null){
                objWS.id_ciudad = objSF.AM_Ciudad_representante__r.ID_UNOEE__c;
            }
            if(objSF.AM_Ciudad__r.ID_UNOEE__c != null) {
                objWS.id_ciudad = objSF.AM_Ciudad__r.ID_UNOEE__c;
            }
            objWS.autoriza_datos = objSF.MC_Autoriza_tratardatos_personales__c;
            objWS.cupo_credito = totalOpp + totalOpp * Decimal.valueOf(Label.CupoCreditoPorcentajeUnoE)/100.00;// 1.10; //ver fila 89 del excel
            
            
            FanalcaCrearModificarClientesUNOEE2.HTTPS_Port enviarWS = new FanalcaCrearModificarClientesUNOEE2.HTTPS_Port();
            Blob headerValue = Blob.valueOf(Label.FanalcaWSUser+':'+Label.FanalcaWSPassword);string authorizationHeader ='Basic '+EncodingUtil.base64Encode(headerValue);
            enviarWS.inputHttpHeaders_x = new Map<String, String>();enviarWS.inputHttpHeaders_x.put('Authorization',authorizationHeader); 
            enviarWS.inputHttpHeaders_x.put('Content-Type', 'application/soap+xml');
            enviarWS.timeout_x = 8000;
            
            String respuesta = 
                 enviarWS.SendToUNOEE(objWS);
            
            system.debug('respuesta:' + respuesta);
            system.debug('enviarWS.outputHttpHeaders_x:' + enviarWS.outputHttpHeaders_x);
            
            //Si respuesta es exitosa
            if (respuesta == '200' && objSF.Creado_en_UNOEE__c==false){
                Account a = new Account (Id = accountId, Creado_en_UNOEE__c=true);
                update a;
            }
            
            Log__c log = new Log__c();
            log.Body__c = JSON.serialize(objWS);
            log.Response__c =respuesta;
            log.Web_Service__c = 'AutosSendAccountToUNOEE.SendAccountFacturar';
            insert log;
            
            return respuesta;
           
        }//catch(CalloutException ex){system.debug('Error: ' + ex.getMessage()); return 'Error: ' + ex.getMessage();}
        catch(Exception ex){
            system.debug('Error: ' + ex.getMessage());
                Log__c log = new Log__c();
                log.Body__c = '';
                log.Response__c ='Message: ' + ex.getMessage() + '. TypeName: ' + ex.getTypeName() + '. LineNumber: ' + ex.getLineNumber();
                log.Web_Service__c = 'AutosSendAccountToUNOEE.SendAccountFacturar';
                insert log;
            return 'Error: ' + ex.getMessage();
        }
    }
}