/******************************************************************************************************************************
*   @Class          :   AFOG_HandlerLlamadasSeguimiento_cls
*   @Author         :   Andrés Oliva andresolivag@gmail.com
*   @Created        :   14/01/2022
*   @Description    :   Esta clase ejecuta acciones para eliminar el pedido.
*
*      Author                   Date                     Description
*      Andrés Oliva              14/01/2022                 Class creation
*******************************************************************************************************************************/
public without sharing class AFOG_HandlerLlamadasSeguimiento_cls {
     /***************************************************************************************************************************  
    * @Method          :   AfterUpdateCall
    * @Author          :   Andrés Oliva andresolivag@gmail.com
    * @Created         :   14/01/2022
    * @Description     :   Luego de insertar una tarea de seguimiento se actualiza la cotización con el No total de llamadsa de 
    *                      seguimiento programadas y completadas
    * @param           :   list< Task > lstNewTask ,map<id, Task >
    ****************************************************************************************************************************/   
    public static void AfterUpdateCall( list< Task > lstNewTask, map<id,task > mapOldTask ){
        list< Task >  lstTaksUpdate = new  list< Task >();
        for(task varTask: lstNewTask ){
            if( varTask.Status != mapOldTask.get( varTask.Id).status ){
                lstTaksUpdate.add( varTask );
            }
        }
        set< id > setQuoteId = getQuoteIds( lstTaksUpdate );
        if( setQuoteId.size() > 0 ){
            map< id, wrpCotizaciones > mapQuotes =  getNoTaskByQuote(  setQuoteId ) ;
            list< Opportunity > lstOpp = updateQuote(  mapQuotes );
        }
    }
    /***************************************************************************************************************************  
    * @Method          :   AfterInsertCall
    * @Author          :   Andrés Oliva andresolivag@gmail.com
    * @Created         :   14/01/2022
    * @Description     :   Luego de insertar una tarea de seguimiento se actualiza la cotización con el No total de llamadsa de 
    *                      seguimiento programadas y completadas
    * @param           :   list< Task > lstNewTask 
    ****************************************************************************************************************************/   
    public static void AfterInsertCall( list< Task > lstNewTask ){
        set< id > setQuoteId = getQuoteIds( lstNewTask );
        if( setQuoteId.size() > 0 ){
            map< id, wrpCotizaciones > mapQuotes =  getNoTaskByQuote(  setQuoteId ) ;
            list< Opportunity > lstOpp = updateQuote(  mapQuotes );
        }
    }

    /***************************************************************************************************************************  
    * @Method          :   changeStageToP3
    * @Author          :   Andrés Oliva andresolivag@gmail.com
    * @Created         :   11/01/2022
    * @Description     :   En la oportunidad quitar el checkbox de se creó pedido en UNO-E y regresar la oportunidad a P3
    * @param           :   opportunity  objOpp 
    ****************************************************************************************************************************/   
    public static set< id > getQuoteIds( list<Task> lstTask ){
        set< id > setQuoteId = new set< id >();
        for( task objTask: lstTask ){
            if( objTask.WhatId != null ){
                String sobjectType = objTask.WhatId.getSObjectType().getDescribe().getName();
                if( sobjectType =='Opportunity'){
                    setQuoteId.add( objTask.WhatId );
                }              
            }            
        }    
        system.debug('\n set ids quote @@' + JSON.serializePretty(setQuoteId));
        return setQuoteId;
    }
    /***************************************************************************************************************************  
    * @Method          :   changeStageToP3
    * @Author          :   Andrés Oliva andresolivag@gmail.com
    * @Created         :   11/01/2022
    * @Description     :   En la oportunidad quitar el checkbox de se creó pedido en UNO-E y regresar la oportunidad a P3
    * @param           :   opportunity  objOpp 
    ****************************************************************************************************************************/  
    public static  map< id, wrpCotizaciones > getNoTaskByQuote(  set< id > setIdQuote ){
        map< id, wrpCotizaciones > mapCotizaciones = new map< id, wrpCotizaciones >();
        list< task > lstTask = [SELECT id,status,WhatId FROM Task WHERE WhatId IN: setIdQuote ];
        for(task objTask: lstTask ){
            if( mapCotizaciones.ContainsKey( objTask.WhatId ) && objTask.status =='Programada' ){
                mapCotizaciones.get( objTask.WhatId ).intLlamadasPrograma = mapCotizaciones.get( objTask.WhatId ).intLlamadasPrograma + 1;
            }
            else if(  mapCotizaciones.ContainsKey( objTask.WhatId ) && objTask.status !='Programada'){
                mapCotizaciones.get( objTask.WhatId ).intLlamdasCompletada = mapCotizaciones.get( objTask.WhatId ).intLlamdasCompletada + 1;
            }  
            else if( !mapCotizaciones.ContainsKey( objTask.WhatId ) && objTask.status =='Programada'){
                wrpCotizaciones objWrapper = new wrpCotizaciones(  );
                objWrapper.idQuote = objTask.WhatId;
                objWrapper.intLlamadasPrograma = 1;
                objWrapper.intLlamdasCompletada = 0;
                mapCotizaciones.put( objTask.WhatId, objWrapper );
            }
            else if( !mapCotizaciones.ContainsKey( objTask.WhatId ) && objTask.status !='Programada'){
                wrpCotizaciones objWrapper = new wrpCotizaciones(  );
                objWrapper.idQuote              = objTask.WhatId;
                objWrapper.intLlamadasPrograma  = 0;
                objWrapper.intLlamdasCompletada            = 1;
                mapCotizaciones.put( objTask.WhatId, objWrapper );
            }   
            else{
                wrpCotizaciones objWrapper = new wrpCotizaciones( ); 
                objWrapper.idQuote              = objTask.WhatId;
                objWrapper.intLlamadasPrograma  = 0;
                objWrapper.intLlamdasCompletada            = 0;
                mapCotizaciones.put( objTask.WhatId, objWrapper );        
            }       
        } 
        system.debug('\n map cotizaciones@@' + JSON.serializePretty( mapCotizaciones ));
        return   mapCotizaciones;     
    }

    /***************************************************************************************************************************  
    * @Method          :   changeStageToP3
    * @Author          :   Andrés Oliva andresolivag@gmail.com
    * @Created         :   11/01/2022
    * @Description     :   En la oportunidad quitar el checkbox de se creó pedido en UNO-E y regresar la oportunidad a P3
    * @param           :   opportunity  objOpp 
    ****************************************************************************************************************************/  
    public static list< opportunity > updateQuote(  map< id, wrpCotizaciones > mapCotizaciones ){
        list< opportunity > lstOpp = new list< opportunity > ();
        try{            
            for (wrpCotizaciones varWrp : mapCotizaciones.values() ){
                opportunity objOpp = new opportunity(    id = varWrp.idQuote, 
                                            AFOG_NoLlamadasSeguimientoCompletadas__c = mapCotizaciones.get( varWrp.idQuote).intLlamdasCompletada , 
                                            AFOG_NoLlamadasSeguimientoProgramadas__c = mapCotizaciones.get( varWrp.idQuote).intLlamadasPrograma );
                lstOpp.add( objOpp );
            }
            system.debug('\n lst Opp to update Seguimientos @@' + JSON.serializePretty( lstOpp ));
            AFOG_BypassTrigger_ctr.ByPass( 'OpportunityTrigger');
            update lstOpp ; 
        }catch( exception e ){
            system.debug( '\n error on AFOG_HandlerLlamadasSeguimiento_cls @@@ '+e.getMessage() +'\n error type @@@ ' + e.getTypeName() +'\n line number @@@' +e.getLineNumber()  );
            throw e ;
        }
        return lstOpp;       
    }
    
    /***************************************************************************************************************************  
    * @Class          :   wrpCotizaciones
    * @Author          :   Andrés Oliva andresolivag@gmail.com
    * @Created         :   14/01/2022
    * @Description     :   Clase wrapper para almacenar las tareas de seguimiento cerradas y programadas de una cotizacón
    ****************************************************************************************************************************/  
    public class wrpCotizaciones{
        id      idQuote                 {get; set;}
        integer intLlamdasCompletada    {get; set;}
        integer intLlamadasPrograma     {get; set;}
    }
}