public class VerificacionesAPI {
    //VerificacionesAPI.validarTelefono('31289777145','Hola');
    @auraEnabled
    //public static String validarTelefono(string numero, string mensaje){
    public static String validarTelefono(string numero, string mensaje){
        Log__c log = new Log__c();
        try
        {
            Http http = new Http();
            HttpRequest req = new HttpRequest();
            req.setEndpoint(Label.ValidarTelefonoEndPoint);
            req.setMethod('POST');
            req.setTimeout(120000);
            req.setHeader('Content-Type', 'application/json');
            HttpResponse res = new HttpResponse();  
            
            //Setear los valores a enviar en el json
            Verificaciones telefono = new Verificaciones();
            telefono.cliente = Label.DBAEXPERTSCliente;
            telefono.usuario=Label.DBAEXPERTSUsuario;
            telefono.api =Label.DBAEXPERTSAPI;
            telefono.numero =numero;
            telefono.mensaje= mensaje;
            telefono.param2 = '';
            telefono.param3 = '';
            telefono.param4 = '';
            telefono.param5 = '';
            
            Blob headerValue = Blob.valueOf(Label.FanalcaWSUser+':'+Label.FanalcaWSPassword);string authorizationHeader ='Basic '+EncodingUtil.base64Encode(headerValue);
            req.setHeader('Authorization',authorizationHeader); 
            req.setHeader('Content-Type', 'application/json');
            
            //setear el body y enviar el WS
            String body = JSON.serialize(telefono);
            req.setBody(body);
            
            
            log.body__c =body;
            log.Web_Service__c = 'VerificacionesAPI-validarTelefono';
            
            
            res = http.send(req);
            
            system.debug('response ' + res);
            log.Response__c = res.getBody();
            
            if(res.getStatusCode() == 200){
                system.debug('res.getBody(): ' + res.getBody());
                Verificaciones.Response response = Verificaciones.parseSuccessResponse(res.getBody());
                system.debug('response consulta ' + response.Consulta);
                if ( response.Consulta.resultado==1) {
                    insert log; return response.Consulta.codigo;   
                }
                else {
                    insert log; return 'Error: ' + response.Consulta.mensaje;
                }
            }else{
                insert log; return 'Error: StatusCode ' + res.getStatusCode() + ', Status ' + res.getStatus();
            }
           /*
            if(res.getStatusCode() == 200){
                insert log; return Verificaciones.parseSuccessResponse(res.getBody());
            }else{
                Verificaciones.Response vr = new Verificaciones.Response();
                vr.Consulta = new Verificaciones.Consulta( );
                vr.Consulta.mensaje ='Error, Status: ' + res.getStatusCode() + ', '+ res.getStatus();
                insert log; return vr;
            }
            */
        }catch (Exception ex){
            system.debug('Exception: ' + ex.getMessage()) ;
            insert log; 
            return 'Error: ' + ex.getMessage();
        }
    }
  
    @auraEnabled
    public static String removePhone(Id accountId, boolean isPersonAccount){
        try{
            Account a = new Account(Id=accountId);
            if (isPersonAccount) {
                a.PersonMobilePhone = '';
                update a;
            }else
                return 'La Cuenta no es de tipo Jurídica';
            return 'Código Incorrecto, El Celular de la cuenta ha sido Eliminado';
        }catch (Exception ex){
            return ex.getMessage();    
        }
    }
    
    @auraEnabled
    public static String setValidatedPhone(Id accountId){
        try{
            Account a = new Account(Id=accountId);
            a.Telefono_Validado__c = true;
            update a;
            return 'Teléfono Validado';
        }catch (Exception ex){
            return 'Error ' + ex.getMessage();    
        }
    }
    
    //VerificacionesAPI.validarTelefono('jparrales@gmail.com');
    @auraEnabled
    public static String validarEmail(Id accountId){
        Log__c log = new Log__c();
        try
        {
            Account a = [select Id, AM_Correo_Electronico_Trabajo__c,PersonEmail, RecordType.IsPersonType from account where Id=:accountId];
            String email;
            if (a.RecordType.IsPersonType) {
                email = a.PersonEmail;
            }else
                email = a.AM_Correo_Electronico_Trabajo__c;
            
            if (String.isBlank(email)) return 'No hay Email que Validar en la Cuenta';
            
            
            Http http = new Http();
            HttpRequest req = new HttpRequest();
            req.setEndpoint(Label.ValidarEmailEndPoint); 
            req.setMethod('POST');
            req.setTimeout(120000);
            //req.setHeader('Content-Type', 'application/json');
            HttpResponse res = new HttpResponse();  
            
            Blob headerValue = Blob.valueOf(Label.FanalcaWSUser+':'+Label.FanalcaWSPassword);string authorizationHeader ='Basic '+EncodingUtil.base64Encode(headerValue);
            req.setHeader('Authorization',authorizationHeader); 
            req.setHeader('Content-Type', 'application/json');
            
            //Setear los valores a enviar en el json
            Verificaciones emailVerificacion = new Verificaciones();
            emailVerificacion.cliente = Label.DBAEXPERTSCliente;
            emailVerificacion.usuario=Label.DBAEXPERTSUsuario;
            emailVerificacion.api =Label.DBAEXPERTSAPI;
            emailVerificacion.mail= email;
            
            
            
            //setear el body y enviar el WS
            String body = JSON.serialize(emailVerificacion);
            req.setBody(body);
            
            log.body__c =body;
            log.Web_Service__c = 'VerificacionesAPI-validarEmail';
            res = http.send(req);
            
            log.Response__c = res.getBody();
            
            system.debug('response ' + res);
            if(res.getStatusCode() == 200){
                Verificaciones.Response response = Verificaciones.parseSuccessResponse(res.getBody());
                if ( response.Consulta.resultado==1) {
                    insert log; 
                    a.Email_Validado__c=true;
                    update a;
                    return response.Consulta.mensaje;   
                }
                else {
                    insert log; 
                    if (response.Consulta.resultado==50009){
                        if (a.RecordType.IsPersonType) {
                            a.PersonEmail ='';
                        }else
                            a.AM_Correo_Electronico_Trabajo__c = '';    
                        a.Email_Validado__c=false;
                        update a;
                        return response.Consulta.mensaje + '. Se ha quitado el Email de la cuenta!';
                    }else{
                        return response.Consulta.mensaje;
                    }
                }
                
            }else{
               insert log; return 'Error: StatusCode ' + res.getStatusCode() + ', Status ' + res.getStatus(); 
            }
               
        }catch (Exception ex){
            system.debug('Error: ' + ex.getMessage()) ;
            upsert log; 
            return 'Error: ' + ex.getMessage();
        }
    }
    
    /*
    @auraEnabled
    public static String removeEmail(Id accountId, boolean isPersonAccount){
        try{
            Account a = new Account(Id=accountId);
            if (isPersonAccount) {
                a.PersonEmail ='';
            }else
                a.AM_Correo_Electronico_Trabajo__c = '';
            update a;
            return 'El email de la cuenta ha sido Eliminado';
        }catch (Exception ex){
            return 'Error: ' + ex.getMessage();    
        }
    }
    */
}