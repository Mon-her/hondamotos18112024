trigger OpportunityTrigger on Opportunity (before insert, before update, after insert, after update) {     
    
    if( trigger.isInsert && trigger.IsBefore ){
        AFOG_OpportunityHandlerMotos_cls.tareasSeguimientoOpp( trigger.new );
    }
    if(  trigger.isinsert && trigger.isAfter  ){
        AFOG_OpportunityHandlerMotos_cls.crearActividadSeguimientoMotos( trigger.new, system.today().addDays(1) );
    }
    
    if( trigger.isUpdate && trigger.isAfter ){
       // A definir los campos  AFOG_OpportunityHandler_cls.MethodTovalidateMandatoryFieldsToChangePUstatus( trigger.newMap, trigger.oldMap );       
    }       
}