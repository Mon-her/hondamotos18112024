/******************************************************************************************************************************
*   @Class          :   AFOG_HandlerLlamadasSeguimiento_cls
*   @Author         :   Andrés Oliva andresolivag@gmail.com
*   @Created        :   14/01/2022
*   @Description    :   Esta clase ejecuta actualizar en la oportunidad el número de llamadas de seguimiento
*
*      Author                   Date                     Description
*      Andrés Oliva              21/01/2022                 Class creation
*******************************************************************************************************************************/
public with sharing class AFOG_LlamadasSeguimiento_Batch implements Database.Batchable<sObject> {
    public final String Query;

    public AFOG_LlamadasSeguimiento_Batch(String q){ 
       Query=q; 
    } 
    public Database.QueryLocator start(Database.BatchableContext BC){
       return Database.getQueryLocator(query);
    }
 
    public void execute(Database.BatchableContext BC, List<sObject> scope){
        list< Task > lstNewTask  = scope;
        AFOG_HandlerLlamadasSeguimiento_cls.AfterInsertCall( lstNewTask );
    } 
    public void finish(Database.BatchableContext BC){
    }
}