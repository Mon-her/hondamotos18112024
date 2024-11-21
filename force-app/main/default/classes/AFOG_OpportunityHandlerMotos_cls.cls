public with sharing class AFOG_OpportunityHandlerMotos_cls {
      
    /***************************************************************************************************************************  
    * @Method          :   crearActividadSeguimientoMotos
    * @Author          :   AFOG Cloud Service
    * @Created         :   19/05/2023
    * @Description     :   Al crear una oportunidad de motos se debe crear su tarea de seguimiento
    * @param           :   opportunity  objOpp 
    ****************************************************************************************************************************/   
    public static void crearActividadSeguimientoMotos( list< opportunity > lstNewOpp, date activityDate ){
        list< task > lstTareasMotos = new list< task >();
        set< id > setOPPid = new set< id >();
        SET<ID > setOppWithTask = new SET<ID >(); 
       
        list< recordtype > lstMotos = [select id,DeveloperName,SobjectType from recordtype where  DeveloperName  in ('Motos_Opportunity_Layout','Motos_Tareas') ];
        map< string,id > mapNameRT =  new  map< string,id > (); 
        map< id,string > mapidRT =  new  map< id,string > (); 
        for( recordtype varRT: lstMotos ){
            mapNameRT.put( varRT.DeveloperName, varRT.Id );
            mapidRT.put( varRT.Id, varRT.DeveloperName );
        }
        for( opportunity varOpp: lstNewOpp ){
            if(  mapidRT.containsKey( varOpp.recordtypeId ) ){
                setOPPid.add( varOpp.Id );
            }           
        }


        list< task > lstTask = [SELECT id,RecordType.name, CreatedDate  FROM task WHERE RecordType.name like '%motos%' AND WhatId In:setOPPid ORDER BY createddate desc  ];
        for( task vartask: lstTask){
            setOppWithTask.add( vartask.WhatId);
        }
        for(opportunity varOpp: lstNewOpp ){
            if( mapidRT.containsKey( varOpp.recordtypeId ) && !setOppWithTask.contains(varOpp.id)){
                task oTask = new task();
                otask.Subject                           =   'Seguimiento a Oportunidad';
                otask.status                            =   'Programada';
                otask.Priority                          =   'Normal';
                otask.AM_Telefono_Light__c              =   varOpp.Telefono_contacto__c;
                otask.ownerId                           =   varOpp.OwnerId;
                otask.Fecha_de_cierre_de_oportunidad__c =   varOpp.Fecha_de_validez__c;
                otask.Etapa_de_Oportunidad_del__c       =   varopp.StageName;
                otask.activityDate                      =   activityDate ;
                otask.IsReminderSet                     =   false;
                oTask.WhatId                            =   varOpp.Id;
                oTask.Producto_de_Interes__c            =   varOpp.Producto_de_Interes__c;
                oTask.RecordTypeId                      =   mapNameRT.get('Motos_Tareas');
                oTask.Description                       =   system.label.DescripcionTareaSegimiento;
                lstTareasMotos.add( oTask );
            }
        }
        if( !lstTareasMotos.isEmpty()){
            String jsonString = json.serialize( lstTareasMotos );
            crearTareasSeguimiento( jsonString );            
        }
    }

    /***************************************************************************************************************************  
    * @Method          :   tareasSeguimientoOpp
    * @Author          :   AFOG Cloud Service
    * @Created         :   19/05/2023
    * @Description     :   Este método actualiza el numero de llamadas a uno durante la creación de la oportunidad de motos
    * @param           :   opportunity  objOpp 
    ****************************************************************************************************************************/   
    public static void tareasSeguimientoOpp( list< opportunity > lstNewOpp ){
        map< id,string > mapidRT =  new  map< id,string > (); 
        list< recordtype > lstMotos = [select id,DeveloperName,SobjectType from recordtype where  DeveloperName  in ('Motos_Opportunity_Layout') ];
        for( recordtype varRT: lstMotos ){
            mapidRT.put( varRT.Id, varRT.DeveloperName );
        }
        for(opportunity varOpp: lstNewOpp ){
            if( mapidRT.containsKey( varOpp.recordtypeId )){
                varOpp.AFOG_NoLlamadasSeguimientoProgramadas__c = 1;
            }
        }      
    }

    /***************************************************************************************************************************  
    * @Method          :   crearTareasSeguimiento
    * @Author          :   AFOG Cloud Service
    * @Created         :   19/05/2023
    * @Description     :   Este método futuro ejecuta el DML para insertar las nuevas tareas, se hace así para evitar problemas de 
                           recursividad con el trigger de oportunidad
    * @param           :   opportunity  objOpp 
    ****************************************************************************************************************************/ 
    @future
    public static void crearTareasSeguimiento( String jsonString ){
        List<task> taskList = (List<task>)Json.deserialize(jsonString,List<task>.class);
        insert taskList;
    }

}