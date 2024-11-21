/******************************************************************************************************************************
*   @Class          :   AFOG_AnualacionPedido
*   @Author         :   Andrés Oliva andresolivag@gmail.com
*   @Created        :   11/01/2022
*   @Description    :   Esta clase ejecuta acciones para eliminar el pedido.
*
*      Author                   Date                     Description
*      Andrés Oliva              11/01/2022                 Class creation
*******************************************************************************************************************************/
public without sharing class AFOG_AnualacionPedido {
   
    /***************************************************************************************************************************  
    * @Method          :   changeStageToP3
    * @Author          :   Andrés Oliva andresolivag@gmail.com
    * @Created         :   11/01/2022
    * @Description     :   En la oportunidad quitar el checkbox de se creó pedido en UNO-E y regresar la oportunidad a P3
    * @param           :   opportunity  objOpp 
    ****************************************************************************************************************************/   
    @AuraEnabled
    public static Opportunity anularPedido( string oppId){
    
        Opportunity objOpp ; 
        list< Inventario_de_Usados__c > lstUsadosToUpdate;
         try{
            objOpp = new Opportunity(id = oppId );          
            objOpp =  blankOpportunityFields( detenerSincronizacion( changeStageToP3( objOpp ) ));
            list< OpportunityLineItem >     lstOppLineToDelete      = oppProductsToDelete( objOpp );
            list< QuoteLineItem   >         lstQuoteLineToDelete    = quoteLinesToDelete( objOpp );           
            List< Order >                   lstOrderToDelete        = getOrderToDelete( objOpp );
            List< Quote >                   lstQuoteToDelete        = getQuoteToDelete( objOpp );
            if( lstOrderToDelete.size() < 1 ){
                objOpp.Order_Generated__c  =   false;
            }
            string sOrder = '';
            opportunity objOppDetails   = getOpportunityFields( oppId );
            if( objOppDetails.Usado_Separado__c != null ){
                lstUsadosToUpdate       = estadoVehiculoUsado( objOppDetails );
                update lstUsadosToUpdate;
            }    
            if( lstOrderToDelete.size() > 0){
                sOrder = lstOrderToDelete[0].OrderNumber;
            } 
            update objOpp;
            delete lstOppLineToDelete;
            delete lstQuoteLineToDelete;                
            update lstOrderToDelete;
           // delete lstOrderToDelete;
            //delete lstQuoteToDelete;
                    
            set< string >  setEmails = getEmailList( objOppDetails );
            sendMail( setEmails, objOppDetails.Numero_de_Oportunidad__c , sOrder, oppId );
            Set<String> recipientsId = new Set<String> ();
            if( objOppDetails.owner.isActive == true){
                recipientsId.add( objOppDetails.ownerid );
            }
            if( objOppDetails.LastModifiedBy.IsActive == true ){
                recipientsId.add( objOppDetails.LastModifiedById );
            }            
           
            notifyUsers( recipientsId , objOppDetails.Id, objOppDetails.Numero_de_Oportunidad__c );
            System.debug('\n opportunity @@@'+JSON.SerializePretty( objOpp ) +'\n oppline item @@@ ' + JSON.SERIALIZEPRETTY(lstOppLineToDelete) + '\n QL to delete' + JSON.SERIALIZEPRETTY( lstQuoteLineToDelete ) + '\N Inventario usados @@@@' + JSON.SerializePretty( lstUsadosToUpdate ) + '\n order to delete @@@' + JSON.SERIALIZEPRETTY( lstOrderToDelete )+'\n quote to delete @@@'+ JSON.SERIALIZEPRETTY( lstQuoteToDelete ));
        }catch( exception e ){
           // system.debug( '\n error AFOG_AnualacionPedido @@@ '+e.getMessage() +'\n line number @@@ '+ e.getLineNumber() + '\n stackTrace @@@ ' + e.getStackTraceString()+ '\n type name @@@ '+e.getTypeName());
            throw new AuraHandledException('Error Exception happend'+e.getMessage());   
        }     
        return  objOpp;            
    }  
    
    /***************************************************************************************************************************  
    * @Method          :   getOpportunityFields
    * @Author          :   Andrés Oliva andresolivag@gmail.com
    * @Created         :   11/01/2022
    * @Description     :   Devuelven el listado de emails para enviar la notificación de anulación de pedido
    * @param           :   opportunity  objOpp 
    ****************************************************************************************************************************/   
    public static  opportunity getOpportunityFields( string oppId ){
        Opportunity oOpp =[SELECT Id,Owner.email, LastModifiedBy.email,Numero_de_Oportunidad__c,ownerid,owner.isActive,LastModifiedById,LastModifiedBy.IsActive,Usado_Separado__c FROM Opportunity WHERE id =: oppId];
        return oOpp;
    }
   
    /***************************************************************************************************************************  
    * @Method          :   getEmailList
    * @Author          :   Andrés Oliva andresolivag@gmail.com
    * @Created         :   11/01/2022
    * @Description     :   Devuelven el listado de emails para enviar la notificación de anulación de pedido
    * @param           :   opportunity  objOpp 
    ****************************************************************************************************************************/   
    public static set< string > getEmailList( Opportunity opp ){
        set< string >  setEmail = new set< string > ();        
        setEmail.add( opp.Owner.email );
        setEmail.add(  opp.LastModifiedBy.email );
        return setEmail;
    }

    /***************************************************************************************************************************  
    * @Method          :   changeStageToP3
    * @Author          :   Andrés Oliva andresolivag@gmail.com
    * @Created         :   11/01/2022
    * @Description     :   En la oportunidad quitar el checkbox de se creó pedido en UNO-E y regresar la oportunidad a P3
    * @param           :   opportunity  objOpp 
    ****************************************************************************************************************************/   
    public static opportunity changeStageToP3( opportunity  objOpp ){
        objOpp.Se_creo_pedido_en_UNOEE__c   = false; 
        objOpp.StageName                    = 'P3';
        return objOpp;
    }

    /***************************************************************************************************************************  
    * @Method          :   detenerSincronizacion
    * @Author          :   Andrés Oliva andresolivag@gmail.com
    * @Created         :   11/01/2022
    * @Description     :   Este código detiene la sincronización de la cotización con la oportunidad
    * @param           :   opportunity  objOpp 
    * @return          :   opportunity  ==> devuelve un registro de oportunidad tras aplicar la desincronización de la cotización
    ****************************************************************************************************************************/     
    public static opportunity detenerSincronizacion( opportunity  objOpp  ){
        objOpp.SyncedQuoteId = null;
        return objOpp;
    }    
 
    /***************************************************************************************************************************  
    * @Method          :   blankOpportunityFields
    * @Author          :   Andrés Oliva andresolivag@gmail.com
    * @Created         :   11/01/2022
    * @Description     :   En la oportunidad dejar en blanco los siguientes campos:
   *                      En información adicional: Vitrina de Despacho / Notas de Despacho / Bodega Usados (caso usados)
   *                      En cierre de negocio: Agencia / Vin o Placa / Vehículo (nuevo/renting)
    * @param           :   opportunity  objOpp 
    * @return          :   opportunity   
    ****************************************************************************************************************************/     
    public static opportunity blankOpportunityFields( opportunity  objOpp  ){
        objOpp.Vitrina_de_despacho__c   =   null;
        objOpp.Notas_de_despacho__c     =   '';
        objOpp.SO_Notas_de_despacho__c  =   '';
        objOpp.Bodega_Usados__c         =   '';
        objOpp.Concesionario__c         =   null;
        objOpp.VIN__c                   =   '';
        objOpp.Placa__c                 =   '';
        objOpp.Vehiculo__c              =   null;
        objOpp.Order_Generated__c       =   true;
        objOpp.Usado_Separado__c        =   null;
        objOpp.AM_Agencia_de_entrega__c =   '';
        objOpp.Recibo_de_caja__c        =   '';
        objOpp.Fecha_de_envio_a_UNOEE__c =   null;
        objOpp.AFOG_FechaAnulacionPedido__c = system.now();
        objOpp.Tipo_Impo_Utilidad__c 	= null;
        objOpp.Valor_Utilidad__c 		= null;
        return objOpp;
    }   

    /***************************************************************************************************************************  
    * @Method          :   oppProductsToDelete
    * @Author          :   Andrés Oliva andresolivag@gmail.com
    * @Created         :   11/01/2022
    * @Description     :   En la sección de producto eliminar el producto (opportunityProduct)
    * @param           :   opportunity  objOpp 
    * @return          :   opportunity   
    ****************************************************************************************************************************/   
    public static list< OpportunityLineItem > oppProductsToDelete ( Opportunity objOpp ){
        list< OpportunityLineItem > lstOppProducts  = [SELECT Id FROM  OpportunityLineItem WHERE OpportunityId =: objOpp.id ];
        return lstOppProducts; 
    }


    /***************************************************************************************************************************  
    * @Method          :   quoteLinesToDelete
    * @Author          :   Andrés Oliva andresolivag@gmail.com
    * @Created         :   11/01/2022
    * @Description     :   En la sección de producto eliminar el producto (quoteLineItem)
    * @param           :   opportunity  objOpp 
    * @return          :   opportunity   
    ****************************************************************************************************************************/   
    public static list< QuoteLineItem   > quoteLinesToDelete ( Opportunity objOpp ){
        list< QuoteLineItem > lstQuoteLine = [SELECT id FROM  QuoteLineItem WHERE Quote.OpportunityId =: objOpp.id ];
        return lstQuoteLine;      
    }

    /***************************************************************************************************************************  
    * @Method          :   estadoVehiculoUsado
    * @Author          :   Andrés Oliva andresolivag@gmail.com
    * @Created         :   11/01/2022
    * @Description     :   Para el caso de usados, para ese vehículo debe actualizarse de manera automática el estado a disponible,
    *                      y el en registro de ese usado se debe eliminar la oportunidad a la que está asociada.
    * @param           :   opportunity  objOpp 
    * @return          :   list< Inventario_de_Usados__c >   
    ****************************************************************************************************************************/ 
    public static list< Inventario_de_Usados__c > estadoVehiculoUsado( Opportunity opp ){
        list< Inventario_de_Usados__c > lstVehiculoUsado = [SELECT Id,Estado_Del_Vehiculo__c FROM Inventario_de_Usados__c WHERE id =: opp.Usado_Separado__c];
        for( Inventario_de_Usados__c varUsados: lstVehiculoUsado ){
            if( varUsados.Estado_Del_Vehiculo__c != 'DISPONIBLE' ){
                varUsados.Estado_Del_Vehiculo__c = 'DISPONIBLE';
                varUsados.Oportunidad__c = null;
            }
        }
        return lstVehiculoUsado;
    }

    /***************************************************************************************************************************  
    * @Method          :   getOrderToDelete
    * @Author          :   Andrés Oliva andresolivag@gmail.com
    * @Created         :   11/01/2022
    * @Description     :   Respecto de la cotización esta se debe eliminar, respecto del pedido este también se debe eliminar 
    * @param           :   opportunity  objOpp 
    * @return          :    List< Order >   
    ****************************************************************************************************************************/ 
    public static   List< Order > getOrderToDelete ( Opportunity objOpp ){
        List< Order > lstOrder = [ SELECT Id,Status,OrderNumber  FROM Order WHERE OpportunityId =: objOpp.Id ];
        for(order varOrder: lstOrder){        
            varOrder.Status = 'Activated';                      
        }
        return lstOrder ;
    }

    /***************************************************************************************************************************  
    * @Method          :   getQuoteToDelete
    * @Author          :   Andrés Oliva andresolivag@gmail.com
    * @Created         :   11/01/2022
    * @Description     :   Respecto de la cotización esta se debe eliminar, respecto del pedido este también se debe eliminar 
    * @param           :   opportunity  objOpp 
    * @return          :    List< Order >   
    ****************************************************************************************************************************/  
    public static  List< Quote >  getQuoteToDelete ( Opportunity objOpp ){
        List< Quote > lstQuote = [ SELECT Id FROM Quote WHERE OpportunityId =: objOpp.Id ];
        return lstQuote ;
    }    
    /** Posteriormente se le envié una notificación por correo y en campanita al asesor y a la administrativa que
    indique que el pedido xxx se anuló de la oportunidad xxx */
    /***************************************************************************************************************************  
    * @Method          :   sendMail
    * @Author          :   Andrés Oliva andresolivag@gmail.com
    * @Created         :   11/01/2022
    * @Description     :   Posteriormente se le envié una notificación por correo y en campanita al asesor y a la administrativa que
                           indique que el pedido xxx se anuló de la oportunidad.  
    * @param           :   opportunity  objOpp 
    * @return          :    List< Order >   
    ****************************************************************************************************************************/     
    public static void sendMail( set<string> setEmailTo,string sNoOpportunidad, string sNoPedido,string idOpportunidad ){
        Messaging.SingleEmailMessage email = new Messaging.SingleEmailMessage();
        list<string> to = new list<string>( setEmailTo );
        email.setToAddresses( to );    
        email.setSubject( system.label.AFOG_subject );        
        email.setHtmlBody(system.label.AFOG_Hola + ' '+ sNoPedido + ' '+ system.label.AFOG_msm_relacionado + ' ' + sNoOpportunidad + ' ' + system.label.AFOG_msm_anulo+idOpportunidad+'/view' );
        Messaging.sendEmail(new Messaging.SingleEmailMessage[] { email });              
    }

    /***************************************************************************************************************************  
    * @Method          :   notifyUsers
    * @Author          :   Andrés Oliva andresolivag@gmail.com
    * @Created         :   11/01/2022
    * @Description     :   Posteriormente se le envié una notificación por correo y en campanita al asesor y a la administrativa que
                           indique que el pedido xxx se anuló de la oportunidad.  
    * @param           :   opportunity  objOpp 
    * @return          :    List< Order >   
    ****************************************************************************************************************************/    

    public static void notifyUsers(Set<String> recipientsIds, String targetId, string sNoOpportunidad ) {        
        // Get the Id for our custom notification type
        CustomNotificationType notificationType = 
            [SELECT Id, DeveloperName 
                FROM CustomNotificationType 
                WHERE DeveloperName='Borrado_de_pedido'];
        
        // Create a new custom notification
        Messaging.CustomNotification notification = new Messaging.CustomNotification();

        // Set the contents for the notification
        notification.setTitle( system.label.AFOG_msm_Title );
        notification.setBody( system.label.AFOG_msm_anulacionOpp +' '+ sNoOpportunidad);

        // Set the notification type and target
        notification.setNotificationTypeId(notificationType.Id);
        notification.setTargetId(targetId);
    
        // Actually send the notification        
        notification.send(recipientsIds);      
    }

}