public with sharing class AFOG_InventarioUsadosUtilidades_cls {
      
    /***************************************************************************************************************************  
    * @Method          :   notifyUsers
    * @Author          :   Andrés Oliva andresolivag@gmail.com
    * @Created         :   11/01/2022
    * @Description     :   Posteriormente se le envié una notificación por correo y en campanita al asesor y a la administrativa que
                           indique que el pedido xxx se anuló de la oportunidad.  
    * @param           :   opportunity  objOpp 
    * @return          :    List< Order >   
    ****************************************************************************************************************************/    

   
    public static map<id,user> validateActiveUsers (){
        map<id,user> mapActiveuse = new map<id,user>( [SELECT id,email,IsActive FROM USER WHERE IsActive = true]);
        return mapActiveuse;
    }

    public static void  sendAlertOpportunityConsigRetiradoUpdate( list< Inventario_de_Usados__c> lstNewInventarioUsados ,map<id, Inventario_de_Usados__c > mapOldInventarioUsados  ){
        map< id,set< string > > mapInventarioUsados = new map< id,set< string > >();  //key ==>target , values ==>recipients
        map<id, Inventario_de_Usados__c> mapDetails = new  map<id, Inventario_de_Usados__c> ();
        map<id,user> mapActiveUser =validateActiveUsers(); 
        list< id >  lstIdInventarioUsados = new  list< id >();
        CustomNotificationType notificationType =  [SELECT Id, DeveloperName 
                                                    FROM CustomNotificationType 
                                                    WHERE DeveloperName='Vehculo_retirado_del_inventario'];
         set< string > setUserId = new set< string >();
        for( Inventario_de_Usados__c varNewInventarioUsados: lstNewInventarioUsados ){
            if( varNewInventarioUsados.Estado_Del_Vehiculo__c == 'CONSIG. RETIRADO'  && mapOldInventarioUsados.get( varNewInventarioUsados.Id ).Estado_Del_Vehiculo__c != 'CONSIG. RETIRADO'){
               
                mapDetails.put( varNewInventarioUsados.id,varNewInventarioUsados );
                setUserId.add( varNewInventarioUsados.OwnerId );
                setUserId.add(varNewInventarioUsados.Asesor_Que_Gestiona_El_Ingreso_Del_Vh_Us__c);
                lstIdInventarioUsados.add( varNewInventarioUsados.Id);
                mapInventarioUsados.put( varNewInventarioUsados.Id, setUserId );
            }
        }  
        list<user> lstUserEmail =[SELECT Id,email FROM User WHERE Id IN:setUserId];
        set<string> setEmails = new set<string> ();
        for(user oUser: lstUserEmail ){
            setEmails.add(oUser.email);
        }
        List< Quote > lstQuote = [ Select Id,owner.email, Opportunity.OwnerId , Opportunity.Usado_Separado__c,opportunity.owner.email from quote  where Opportunity.Usado_Separado__c IN: lstIdInventarioUsados ];
        system.debug('lstQuote @@@@' + JSON.serializePretty( lstQuote ));
        
        for( Quote varQuote: lstQuote ){ 
            setEmails.add(varQuote.owner.email);
            setEmails.add(varQuote.opportunity.owner.email);
            if( mapInventarioUsados.containsKey( varQuote.Opportunity.Usado_Separado__c ) && mapActiveUser.containsKey( varQuote.Opportunity.OwnerId )){
                mapInventarioUsados.get( varQuote.Opportunity.Usado_Separado__c ).add( varQuote.Opportunity.OwnerId ); 
            }
        }
        List<String> listEmails=new List<String>();
        listEmails.addAll(setEmails);
        system.debug('/n mapInventarioUsados @@@'+ JSON.serializePretty( mapInventarioUsados ) + ' /n mapDetails @@@@' +JSON.serializePretty( mapDetails ) + '/n list emails @@@@ ' + setEmails );
        for( id varTarget : mapInventarioUsados.keySet() ){
            if( mapDetails.containsKey( varTarget ) ){
                notifyUsers( mapInventarioUsados.get( varTarget ) , varTarget, mapDetails.get( varTarget ).Placas__c, notificationType.id, listEmails );
            }
            
        }      
    }  
   
   
    /***************************************************************************************************************************  
    * @Method          :   notifyUsers
    * @Author          :   Andrés Oliva andresolivag@gmail.com
    * @Created         :   11/01/2022
    * @Description     :   De manera  automática se debe enviar una alerta a los asesores que tengan un vehículo asociado o una 
                            cotización indicando que el vehículo fue retirado del inventario.
    * @param           :   opportunity  objOpp 
    * @return          :    List< Order >   
    ****************************************************************************************************************************/    

    public static void notifyUsers(Set<String> recipientsIds, String targetId, string sPlacas,id notificationId, list< string > lstEmails ) {        
               
        // Create a new custom notification
        String Recordlink = URL.getOrgDomainUrl().toExternalForm()+'/'+targetId;
        Messaging.CustomNotification notification = new Messaging.CustomNotification();

        // Set the contents for the notification
        notification.setTitle( system.label.AFOG_title_VehiculoRetiradoInventario );
        notification.setBody( system.label.AFOG_BodyVehiculoRetiradoInventario.replace('{placas}', sPlacas));

        // Set the notification type and target
        notification.setNotificationTypeId( notificationId );
        notification.setTargetId(targetId);
    
        // Actually send the notification        
        notification.send(recipientsIds);        
       
       // lstEmails.add( 'andresolivag@gmail.com' );
        SYSTEM.DEBUG('DESTINATARIOS @@@'+lstEmails );
        Messaging.SingleEmailMessage email = new Messaging.SingleEmailMessage();
        email.setSubject( system.label.AFOG_title_VehiculoRetiradoInventario );
        email.setToAddresses( lstEmails );     
        email.setPlainTextBody( system.label.AFOG_BodyVehiculoRetiradoInventario.replace('{placas}', sPlacas).replace('{link}', Recordlink) ); // +'  ' + sPlacas +' se ha retirado del inventario. ' + urlRecord
        Messaging.sendEmail(new Messaging.SingleEmailMessage[] { email });    
    } 

}