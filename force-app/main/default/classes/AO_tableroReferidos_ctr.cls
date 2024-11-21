public with sharing  class AO_tableroReferidos_ctr {
    
    public static integer intReferidosContactos = 0;
    public static integer intReferidosCuentas   = 0;
    public static integer intNuevos         = 0;
    public static integer intUsados         = 0;
    public static integer intRenting        = 0;
    public static date    dToday            = Date.today();
    public static date    dMonthAgo         = Date.today().addDays( -30 );
    public static date    dThreeMonthsAgo   = Date.today().addDays( -90 ); 
    public list< wrpReferidos > lstReferidosExcel {get; set;}
    public  List<Account> accList {get; set;}
    
    public AO_tableroReferidos_ctr(){
        accList =  getReferidos( '100', '1' );
        if( apexpages.currentpage() != null && apexpages.currentpage().getparameters() != null && apexpages.currentpage().getparameters().get('start') != null && !apexpages.currentpage().getparameters().get('start').contains('(') ){
            dMonthAgo = date.ValueOf( apexpages.currentpage().getparameters().get('start') );            
        }
        if( apexpages.currentpage() != null && apexpages.currentpage().getparameters() != null && apexpages.currentpage().getparameters().get('end') != null && !apexpages.currentpage().getparameters().get('end').contains('(') ){
            dToday = date.ValueOf( apexpages.currentpage().getparameters().get('end') );
        }
        wrpResponse  objWrpResponse = getWrpReferidos(  '100', '1',dMonthAgo, dToday );
        lstReferidosExcel = objWrpResponse.lstwReferidos;
    }
        @AuraEnabled
 
    public static String formatDate(Date d) {
        return d.year() + '-' + d.month() + '-' + d.day();
    } 
    
    @AuraEnabled
    public static List<Account> getReferidos( String pageSize, String pageNumber ) {
        Integer psize = Integer.valueOf(pageSize);
        Integer pnumber = Integer.valueOf(pageNumber)-1;
         
        List<Account> accList = [SELECT Id, Name, AccountNumber, Industry, Phone
                                  FROM Account LIMIT :Integer.valueOf(psize) OFFSET :(psize*pnumber)];
        //return list of accounts
        return accList;
    }
    @AuraEnabled
    public static wrpResponse getWrpReferidos(  String pageSize, String pageNumber,date dStart, date dEnd ){
        if(dStart == null ){ 
            dMonthAgo = dMonthAgo;
        }
        if(dEnd == null ){
           dEnd = dToday; 
        }
        Integer psize = Integer.valueOf(pageSize);
        Integer pnumber = Integer.valueOf(pageNumber)-1;
        wrpResponse varResponse = new wrpResponse();
        
        list< wrpReferidos > lstWrpResponse = new  list< wrpReferidos >();
        list< wrpReferidos > lstReferidosContactos  = getReferidosContactos(psize,pnumber,dStart, dEnd  );
        list< wrpReferidos > lstReferidosCuentas    = getReferidosCuentas(psize,pnumber,dStart, dEnd  );
        lstWrpResponse.addall( lstReferidosContactos );
        lstWrpResponse.addall( lstReferidosCuentas );   
        varResponse.wReferidosContactos = intReferidosContactos;
        varResponse.wReferidosCuentas   = intReferidosCuentas;
        varResponse.wCotizacioRenting   = intRenting;
        varResponse.wCotizacioNuevos    = intNuevos;
        varResponse.wCotizacioUsuados   = intUsados;
        varResponse.lstwReferidos       = lstWrpResponse;
        return varResponse;
    }
    
    @AuraEnabled
    public static list< wrpReferidos > getReferidosContactos( integer intSize, integer intNumber,date dStartContact, date dEndContact  ){        
        dEndContact = date.valueOf( Datetime.newInstance(  dEndContact.year(), dEndContact.month(), dEndContact.day(), 23, 59, 59 ));//.format( 'yyyy-MM-dd\'T\'HH:mm:ss.SSS\'Z\'',  UserInfo.getTimeZone().getDisplayName() ));    
        user objCurrentUser = [SELECT name, Id,AM_Concesionario__c,profile.name,Username FROM User WHERE ID =: UserInfo.getUserId() ];    
        boolean isAdmin = false;
        list< AO_REFERIDOSADMIN__mdt > lstReferidos = [SELECT Admin__c,DeveloperName FROM AO_REFERIDOSADMIN__mdt WHERE DeveloperName = 'Admin'];  
        list< string > lstAdminUser = lstReferidos[0].Admin__c != null ? lstReferidos[0].Admin__c.split(','): new list<string>();  
        
        for( string varString: lstAdminUser ) {
            if( objCurrentUser.Username.contains( varString ) ){
                isAdmin= true;
            }
        }
        list<MC_Contactos__c> lstContact = [ SELECT  CreatedDate,Id,MC_Vitrina_Prospecto__c,Owner.name,SO_Referidor__r.SO_Numero_de_identificacion_referidorCTA__c,
                                                    SO_Tipo_de_cliente_Referidor__c ,SO_Referidor__r.Name,SO_Referidor__r.SO_Email_de_referidor_CTA__c,Name, SO_Referidor__r.Phone,
                                                    MC_celular_prospecto__c,MC_Tipo_de_cotizacion_contactos__c,MC_Vehiculo_contactos__r.Name,MC_Vehiculo_contactos__r.Id,MC_estado_prospecto__c
                                             FROM MC_Contactos__c WHERE MC_fuente_prospecto__c = 'Referidos' AND (CreatedDate >=:dStartContact AND CreatedDate <=: dEndContact)  ]; //  AND                                             (CreatedDate >=:dStartContact AND CreatedDate <=: dEndContact)  LIMIT :Integer.valueOf(intSize) OFFSET :(intSize*intNumber)
       
        list< wrpReferidos > lstWrpReferidosContactos = new list< wrpReferidos >();
        for(MC_Contactos__c varContacto: lstContact ){
            if( ( string.isnotblank( varContacto.MC_Vitrina_Prospecto__c ) && varContacto.MC_Vitrina_Prospecto__c.equalsIgnoreCase( objCurrentUser.AM_Concesionario__c ) )|| isAdmin ){            
                if( ( objCurrentUser.profile.name.equalsIgnoreCase( 'Asesor de ventas') && varContacto.Owner.name.equalsIgnoreCase( objCurrentUser.Name ) ) || !objCurrentUser.profile.name.equalsIgnoreCase( 'Asesor de ventas') ){
                    wrpReferidos wobjeto = new wrpReferidos(); 
                    wobjeto.wTipo               =   'Contacto';
                    wobjeto.wAgencia            =   varContacto.MC_Vitrina_Prospecto__c;       
                    wobjeto.wFechaCreacion      =   string.ValueOf( varContacto.CreatedDate );  
                    wobjeto.wAsesorComercial    =   varContacto.Owner.name;             
                    wobjeto.wQuienRefiere       =   varContacto.SO_Tipo_de_cliente_Referidor__c;              
                    wobjeto.wCedulaReferidor    =   varContacto.SO_Referidor__r.SO_Numero_de_identificacion_referidorCTA__c ;       
                    wobjeto.wNombreReferidor    =   varContacto.SO_Referidor__r.Name;
                    wobjeto.wMailReferidor      =   varContacto.SO_Referidor__r.SO_Email_de_referidor_CTA__c; 
                    wobjeto.wPhoneReferidor     =   varContacto.SO_Referidor__r.Phone; 
                    wobjeto.wCedulaReferido     =   'No aplica';         
                    wobjeto.wNombreReferido     =   varContacto.Name;    
                    wobjeto.wNombreReferidoId   =   varContacto.Id;    
                    wobjeto.wTelefonoReferido   =   varContacto.MC_celular_prospecto__c;        
                    wobjeto.wNoCotizacion       =   'No aplica';          
                    wobjeto.wTipoCotizacion     =   varContacto.MC_Tipo_de_cotizacion_contactos__c;
                    wobjeto.wLineaInteres       =   varContacto.MC_Vehiculo_contactos__r.Name;            
                    wobjeto.wLineaInteresId     =   varContacto.MC_Vehiculo_contactos__r.Id;
                    wobjeto.wFechaEstimadaCompra =  'No aplica'; 
                    wobjeto.wEstadoProspeccion  =   varContacto.MC_estado_prospecto__c; 
                    wobjeto.wFechaFactura       =   'No aplica';
                    wobjeto.wVIN                =   'No aplica';
                    wobjeto.wPlaca              =   'No aplica';
                    wobjeto.wNoFactura          =   'No aplica';
                    lstWrpReferidosContactos.add( wobjeto );
                }
            }
        }
        intReferidosContactos = lstWrpReferidosContactos.size();
        return lstWrpReferidosContactos;
    }
    @AuraEnabled
     public static list< wrpReferidos > getReferidosCuentas(  integer intSize, integer intNumber, date dStartAcc, date dEndAcc   ){
        list< wrpReferidos > lstWrpReferidosCuentas = new  list< wrpReferidos >();
         dEndAcc = date.valueOf( Datetime.newInstance(  dEndAcc.year(), dEndAcc.month(), dEndAcc.day(), 23, 59, 59 ));//.format( 'yyyy-MM-dd\'T\'HH:mm:ss.SSS\'Z\'',  UserInfo.getTimeZone().getDisplayName() ));   
        user objCurrentUser = [SELECT Id,Name,AM_Concesionario__c,profile.name,Username FROM User WHERE ID =: UserInfo.getUserId() ];
        boolean isAdmin = false;    
        
        list< AO_REFERIDOSADMIN__mdt > lstReferidos = [SELECT Admin__c,DeveloperName FROM AO_REFERIDOSADMIN__mdt WHERE DeveloperName = 'Admin'];  
        list< string > lstAdminUser = lstReferidos[0].Admin__c != null ? lstReferidos[0].Admin__c.split(','): new list<string>();  

        for( string varString: lstAdminUser ) {
            if( objCurrentUser.Username.contains( varString ) ){
                isAdmin= true;
            }
        }

        list<Account>  lstAcc =[SELECT id,owner.AM_Concesionario__c,CreatedDate,MC_Vitrina_cuenta__c,Owner.Name,SO_Tipo_de_cliente_Referidor_cuenta__c,
                                SO_Referidor_Cuenta__r.SO_Numero_de_identificacion_referidorCTA__c,SO_Referidor_Cuenta__r.Name,SO_Referidor_Cuenta__r.Phone,
                                SO_Referidor_Cuenta__r.SO_Email_de_referidor_CTA__c,AM_Numero_de_documento__c,name,phone,
                                (select id,CreatedDate,name, AM_Tipo_de_cotizacion__c,AM_Modelo_de_interes__c,AM_Modelo_de_interes__r.name,AM_Modelo_de_interes__r.Id, AM_Fecha_de_cierre__c,AM_Etapa__c,
                                 AM_Fecha_de_factura__c,AM_Vin__c,AM_Placa__c,AM_Numero_de_factura__c from Oportunidades__r )    
                                FROM Account WHERE ( AM_Fuente_de_prospeccion__c='Referidos' OR AM_Fuente_Prospeccion__c ='Referidos') 
                                AND ( CreatedDate >=: dStartAcc AND CreatedDate <=: dEndAcc)
                                ];
      
         for(Account varAccount: lstAcc ){
            if( ( ( string.isnotblank( varAccount.owner.AM_Concesionario__c ) && varAccount.owner.AM_Concesionario__c.equalsIgnoreCase( objCurrentUser.AM_Concesionario__c ) ) ) || isAdmin ){                 
                if( ( objCurrentUser.profile.name.equalsIgnoreCase( 'Asesor de ventas') && varAccount.Owner.name.equalsIgnoreCase( objCurrentUser.Name ) ) || !objCurrentUser.profile.name.equalsIgnoreCase( 'Asesor de ventas') ){               
                    wrpReferidos wobjeto = new wrpReferidos(); 
                    wobjeto.wTipo               =   'Cuenta';
                    wobjeto.wAgencia            =   varAccount.owner.AM_Concesionario__c;       
                    wobjeto.wFechaCreacion      =   string.ValueOf( varAccount.CreatedDate );  
                    wobjeto.wAsesorComercial    =   varAccount.Owner.name;              
                    wobjeto.wQuienRefiere       =   varAccount.SO_Tipo_de_cliente_Referidor_cuenta__c;              
                    wobjeto.wCedulaReferidor    =   varAccount.SO_Referidor_Cuenta__r.SO_Numero_de_identificacion_referidorCTA__c ;       
                    wobjeto.wNombreReferidor    =   varAccount.SO_Referidor_Cuenta__r.Name;
                    wobjeto.wMailReferidor      =   varAccount.SO_Referidor_Cuenta__r.SO_Email_de_referidor_CTA__c;   
                    wobjeto.wPhoneReferidor     =   varAccount.SO_Referidor_Cuenta__r.Phone;               
                    wobjeto.wCedulaReferido     =   varAccount.AM_Numero_de_documento__c;         
                    wobjeto.wNombreReferido     =   varAccount.Name;  
                    wobjeto.wNombreReferidoId   =   varAccount.Id;  
                    wobjeto.wTelefonoReferido   =   varAccount.Phone;  
                    for( AM_Oportunidad__c varCotiza: varAccount.Oportunidades__r){
                        wobjeto.wNoCotizacion       =   varCotiza.name;          
                        wobjeto.wNoCotizacionId     =   varCotiza.Id;                
                        wobjeto.wTipoCotizacion     =   varCotiza.AM_Tipo_de_cotizacion__c;
                        if( wobjeto.wTipoCotizacion =='Nuevos'){
                            intNuevos += 1;
                        }
                        else if( wobjeto.wTipoCotizacion =='Renting'){
                            intRenting +=1;
                        }
                        else if(wobjeto.wTipoCotizacion =='Usados'){
                            intUsados +=1;
                        }
                        wobjeto.wLineaInteres       =   varCotiza.AM_Modelo_de_interes__r.name;
                        wobjeto.wLineaInteresId     =   varCotiza.AM_Modelo_de_interes__r.Id;
                        wobjeto.wFechaEstimadaCompra =  string.ValueOf( varCotiza.AM_Fecha_de_cierre__c ); 
                        wobjeto.wEstadoProspeccion  =   varCotiza.AM_Etapa__c; 
                        wobjeto.wFechaFactura       =   string.valueOf( varCotiza.AM_Fecha_de_factura__c );
                        wobjeto.wVIN                =   varCotiza.AM_Vin__c;
                        wobjeto.wPlaca              =   varCotiza.AM_Placa__c;
                        wobjeto.wNoFactura          =   varCotiza.AM_Numero_de_factura__c;
                    }  
                    lstWrpReferidosCuentas.add( wobjeto );
                }
            }
        }  
        intReferidosCuentas = lstWrpReferidosCuentas.size(); 
        return lstWrpReferidosCuentas;
    }
     public class wrpReferidos{        
        @AuraEnabled public string wTipo                {get; set;}         
        @AuraEnabled public string wAgencia             {get; set;}         
        @AuraEnabled public string wFechaCreacion       {get; set;}         
        @AuraEnabled public string wAsesorComercial     {get; set;}        
        @AuraEnabled public string wQuienRefiere        {get; set;}               
        @AuraEnabled public string wCedulaReferidor     {get; set;}        
        @AuraEnabled public string wNombreReferidor     {get; set;}
        @AuraEnabled public string wMailReferidor       {get; set;} 
        @AuraEnabled public string wPhoneReferidor      {get; set;}   
        @AuraEnabled public string wCedulaReferido      {get; set;}         
        @AuraEnabled public string wNombreReferido      {get; set;}   
        @AuraEnabled public string wNombreReferidoId    {get; set;}
        @AuraEnabled public string wTelefonoReferido    {get; set;}         
        @AuraEnabled public string wNoCotizacion        {get; set;}
        @AuraEnabled public string wNoCotizacionId      {get; set;}
        @AuraEnabled public string wTipoCotizacion      {get; set;}
        @AuraEnabled public string wLineaInteres        {get; set;}
        @AuraEnabled public string wLineaInteresId      {get; set;}
        @AuraEnabled public string wFechaEstimadaCompra {get; set;}
        @AuraEnabled public string wEstadoProspeccion   {get; set;} 
        @AuraEnabled public string wFechaFactura        {get; set;} 
        @AuraEnabled public string wVIN                 {get; set;} 
        @AuraEnabled public string wPlaca               {get; set;}
        @AuraEnabled public string wNoFactura           {get; set;} 
    }
    
    public class wrpResponse{        
        @AuraEnabled public Integer wReferidosContactos         {get; set;}  
        @AuraEnabled public Integer wReferidosCuentas           {get; set;}  
        @AuraEnabled public Integer wCotizacioRenting           {get; set;}  
        @AuraEnabled public Integer wCotizacioNuevos            {get; set;}            
        @AuraEnabled public Integer wCotizacioUsuados           {get; set;}
        @AuraEnabled public list< wrpReferidos > lstwReferidos  {get; set;}
    }

}