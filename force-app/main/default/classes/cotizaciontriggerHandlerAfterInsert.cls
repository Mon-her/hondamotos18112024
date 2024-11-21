/****************************************************************************************************
* Fanalca
* @author           Andrés Oliva
* Description:      trigger handler class.
*
* Changes (Version)
* -------------------------------------
*           No.     Date            Author                  Description
*           -----   ----------      --------------------    ---------------
* @version  1.0     20/08/2019      Andrés Oliva (AO)       Class definition.
*********************************************************************************************************/

public with sharing class cotizaciontriggerHandlerAfterInsert 
{
    /**
    * @Method:      updateCategiaNegocio
    * @param:       list< AM_Oportunidad__c >
    * @Description: Update field "Categoria de negocio"
    * @author       Andrés Oliva - 0820109
    */

    public static void updateCategiaNegocio( list< AM_Oportunidad__c > lstNewCotizacion  )
    {
        try {
            map< id, AM_Oportunidad__c >   mapCotizacion     =   new map< id, AM_Oportunidad__c >  ();
            list< task > lstTaskUpdate  = new list< task >();
            for( AM_Oportunidad__c varCotz: lstNewCotizacion )
            {
                mapCotizacion.put( varCotz.Id, varCotz ); 
            }
            list< task > lstTaskToUpdate    = [ SELECT  id, 
                                                        WhatId,
                                                        Propietario_de_la_cotizacion__c,
                                                        owner.USERNAME,
                                                        AM_Categoria_de_Negocio_1__c 
                                                FROM    TASK
                                                WHERE   WhatId IN: mapCotizacion.KeySet() 
                                                        AND AM_Categoria_de_Negocio_1__c = null
                                                       ];
            for(task varTask : lstTaskToUpdate )
            {
                if( varTask.WhatId != null  && mapCotizacion.containsKey( varTask.WhatId ) && 
                    varTask.Propietario_de_la_cotizacion__c == varTask.owner.username
                    )
                {
                    varTask.AM_Categoria_de_Negocio_1__c    =   mapCotizacion.get( varTask.WhatId ).AM_Etapa__c; 
                    lstTaskUpdate.add( varTask );
                }
            }            

            Database.SaveResult[] srList = Database.update( lstTaskUpdate, false);

            // Iterate through each returned result
            for (Database.SaveResult sr : srList) {
                if (!sr.isSuccess()) {                  
                    // Operation failed, so get all errors                
                    for(Database.Error err : sr.getErrors()) {
                        System.debug('The following error has occurred.');                    
                        System.debug(err.getStatusCode() + ': ' + err.getMessage());
                        System.debug('Task fields that affected this error: ' + err.getFields());
                    }
                }
            }                  
        } catch (Exception e ) {
            system.debug( '\n error found in update Categoria Negocio @@@ ' + e );
            throw e;
        }
        
    }
 
    /**
    * @Method:      createTask
    * @param:       list< AM_Oportunidad__c >
    * @Description: Create following task
    * @author       Andrés Oliva - 0820109
    */    
    public static list< task > createTask ( list< AM_Oportunidad__c > lstNewCotizacion )
    {
        
        list< task > lstTask    =   new     list< task >();
        try 
        {
            Id recordTypeId =   Schema.SObjectType.AM_Oportunidad__c.getRecordTypeInfosByDeveloperName().get('AM_Presupuesto').getRecordTypeId();     
            AO_diasActividadesCotizacion__c objDias = AO_diasActividadesCotizacion__c.getInstance();
            for( AM_Oportunidad__c varCot: lstNewCotizacion )
            { 
                    if( varCot.recorDtypeId != recordTypeId )
                    {
                        task  varTask                       =   new task ();
                        varTask.WhoId                       =   varCot.AM_Usuario_motocicleta__r.PersonContactId; 
                        varTask.whatId                      =   varCot.id;
                        varTask.Description                 =   system.Label.AO_descripcionTareaSeguimiento_lbl; //Comunicarse con el cliente para continuar con el proceso de venta y aclarar inquietudes sobre el automóvil.
                        varTask.Subject                     =   system.label.AO_subjectActividadSeguimt_lbl;    // Realizar actividad de seguimiento
                        varTask.Status                      =   system.label.AO_statusProgramada_lbl;   //Programada
                        varTask.Priority                    =   system.label.AO_priorityNormal_lbl;     //Normal  
                        date myDate = date.today();
                        varTask.ActivityDate                =   myDate.AddDays( Integer.ValueOf ( objDias.dias__c ) );                    
                        varTask.AM_Categoria_de_Negocio_1__c =  varCot.AM_Etapa__c;                    
                        lstTask.add( varTask );                
                    }                
            }           
            System.debug('\n regsitros a insertar @@@' +  lstTask );
            Database.SaveResult[] srList = Database.insert(lstTask, false);

            // Iterate through each returned result
            for (Database.SaveResult sr : srList) {
                if (!sr.isSuccess()) {                  
                    // Operation failed, so get all errors                
                    for(Database.Error err : sr.getErrors()) {
                        System.debug('The following error has occurred.');                    
                        System.debug(err.getStatusCode() + ': ' + err.getMessage());
                        System.debug('Task fields that affected this error: ' + err.getFields());
                    }
                }
            }          
        } 
        catch (Exception e) 
        {
            system.debug('\n error found @@@' + e );
            throw e;
        }        
        return lstTask ;    
    }

}