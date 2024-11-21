/**
* Fanalca
* @author           Me
* Description:      Case Trigger Handler
* Tested by			CaseTriggerHandler_Test
* Changes (Version)
* -------------------------------------
*           No.     Date            Author                  Description
*           -----   ----------      --------------------    ---------------
* @version  1.0     December/2021   Me            Class definition.        
* @version  1.1     March/2022   	Me            Now motos scalations can work for more than one record.   
* @version  1.2     April/05/2022   Me            block update Autos Cases to users not owner, admin, integraciones. 
*********************************************************************************************************/
public class CaseTriggerHandler extends TriggerHandler{
    //Listas de Case
    private list<Case> newCaseList;
    private list<Case> oldCaseList;
    
    //Mapa de Case de tipo id, Case
    private Map<Id, Case> newCaseMap;
    private Map<Id, Case> oldCaseMap;
    
    public CaseTriggerHandler() {
        //Cargamos la lista de Case con lo que viene en el contexto de trigger.new
        newCaseList = (list<Case>) Trigger.New;
        
        //Cargamos el mapa de Case con lo que viene en el contexto de trigger.newmap
        newCaseMap = (Map<Id, Case>) Trigger.NewMap;
        
        //Cargamos el mapa de Case con lo que viene en el contexto de trigger.oldmap
        oldCaseMap = (Map<Id, Case>) Trigger.OldMap;
        
        oldCaseList = (list<Case>) Trigger.Old;
    }
    
    public override void beforeUpdate() {
        //Se encarga de validar que no se pueda marcar la casilla apoyo concluido sin haber diligenciado comentarios internos.
        //Nadie más que el usuario especificado en CAso.IdApoyo puede escribir en comentarios internos mientras el estado sea solicitud de apoyo
        system.debug('before Update Case Trigger. Caso.escalar ' + newCaseList.get(0).Escalar_Caso__c);
        system.debug('before Update Case Trigger. Old Caso.escalar ' + oldCaseList.get(0).Escalar_Caso__c);
        AggregateResult[] groupedResults   = [select count(Id) comentarios,ParentId from CaseComment where ParentId in:Trigger.newMap.keySet() group by ParentId];
        map<Id,Integer> mapCommentsByCase = new map<Id,Integer>();
        
        for (AggregateResult ar : groupedResults)  {
            mapCommentsByCase.put((Id)ar.get('ParentId'),(Integer)ar.get('comentarios'));
            system.debug(ar);
        }
        
        
        map<Id,map<Id, CaseTeamMember>> mapTeamMembersByCase = new map<Id, map<Id, CaseTeamMember>>(); //map de miembros de equipo de caso x Caso
        for (CaseTeamMember ctm: [select Id, ParentId, MemberId from CaseTeamMember where ParentId in:Trigger.newMap.keySet() ]){//for (CaseTeamMember ctm: [select Id, ParentId, MemberId from CaseTeamMember where ParentId in:Trigger.newMap.keySet() and Parent.RecordType.DeveloperName like 'Moto%']){
            if (!mapTeamMembersByCase.containsKey(ctm.ParentId)) mapTeamMembersByCase.put(ctm.ParentId, new map<Id,CaseTeamMember>());
            mapTeamMembersByCase.get(ctm.ParentId).put(ctm.MemberId, ctm);
        }
       
        
        //list<Id> idCasosMotos = new list<Id>();
        
        DateTime completionDate = System.now(); 
        List<Id> updateCases = new List<Id>();
        list<ID> idsCasosMotosClosed = new list<ID>(); //ids de motos con estado cerrado
        for (Case c : newCaseList){
            if (c.Escalar_Caso__c && c.Nivel_de_Escalacin__c == 1){ c.Status = 'Escalado 1'; }
            if (c.Escalar_Caso__c && c.Nivel_de_Escalacin__c == 2){ c.Status = 'Escalado 2'; }
            if ( c.Status == 'Cerrado' || c.Status == 'Cerrado no aprobado') {//if ((c.Nivel_de_Escalacin__c<3 && c.Escalar_Caso__c == true) || c.Status == 'Cerrado') {
                //c.Nivel_de_Escalacin__c++;     
                updateCases.add(c.Id);
               // c.EntitlementId = null;
               // c.IsStopped = true;
            }
            //String rtCaseName = Schema.getGlobalDescribe().get('Case').getDescribe().getRecordTypeInfosById().get(c.recordTypeId).getName();
            //if (rtCaseName.toUpperCase().startsWith('MOTOS')) idCasosMotos.add(c.Id);
            
            //Get the Ids for habeas data cases
            String rtCaseName = Schema.getGlobalDescribe().get('Case').getDescribe().getRecordTypeInfosById().get(c.recordTypeId).getDeveloperName();
            if (c.IsClosed && rtCaseName.toUpperCase().contains('MOTO')) idsCasosMotosClosed.add(c.ID);//if (c.IsClosed && rtCaseName=='Motos_Habeas_Data') idsCasosMotosClosed.add(c.ID);
        }
        if (updateCases.isEmpty() == false)
            milestoneUtils.completeMilestone(updateCases, completionDate);
        
        //if there are habeas data cases closed, then I need to know if there are open cases 
        AggregateResult[] groupedMotosCases = new AggregateResult[]{}; 
        map<Id,Integer> mapChildrenCasesMotos = new map<Id,Integer>();
        if (idsCasosMotosClosed.size()>0){
            groupedMotosCases   = [select count(Id) casosHijosAbiertos,ParentId from Case where ParentId in:idsCasosMotosClosed and isClosed=false group by ParentId];
            //map<Id,Integer> mapChildrenCasesMotos = new map<Id,Integer>();
            
            for (AggregateResult ar : groupedMotosCases)  {
                mapChildrenCasesMotos.put((Id)ar.get('ParentId'),(Integer)ar.get('casosHijosAbiertos'));
                system.debug(ar);
            }
        }
          
        User UserLogged = [Select Id, Name, Profile.Name from User where Id=:UserInfo.getUserId()];
        
        
        for (Case c: newCaseList){
            String rtCaseName = Schema.getGlobalDescribe().get('Case').getDescribe().getRecordTypeInfosById().get(c.recordTypeId).getDeveloperName();
            SYSTEM.debug('Record type: ' + rtCaseName);
            Case oldCase = oldCaseMap.get(c.Id);
            Boolean tieneComentariosCaso = false;
            if (mapCommentsByCase.containsKey(c.Id)) tieneComentariosCaso =true;
            if (oldCase.Status!='Apoyo Concluido' && c.Status=='Apoyo Concluido' && String.isBlank(c.Comments) && !tieneComentariosCaso) c.addError('Debe diligenciar los comentarios internos antes de cambiar al estado de Apoyo Concluído!');
            //if (c.Status=='Apoyo Solicitado' && !String.isBlank(c.Comments) && UserINfo.getUserId()!=c.Id_Apoyo__c) c.addError('Sólo el Usuario de Apoyo puede escribir en Comentarios Internos!');
            if (rtCaseName.toUpperCase().startsWith('MOTOS') && UserLogged.Profile.Name!='Servicio al cliente (Motos)' && c.OwnerId!=userinfo.getUserId() && c.Status=='Apoyo Solicitado' && !String.isBlank(c.Comments) && (!mapTeamMembersByCase.containsKey(c.Id) || !mapTeamMembersByCase.get(c.Id).containsKey(UserINfo.getUserId()) )) c.addError('Sólo los Usuarios miembros del equipo del caso pueden escribir en Comentarios Internos!');
            if (oldCase.Status!='Apoyo Concluido' && c.Status=='Apoyo Concluido') { 
                //c.Status='Listo para respuesta';
                //if (rtCaseName=='Motos_PQRSjFS_Motos') c.Id_Apoyo__c = userinfo.getUserId(); //el usuario que establece el estado del caso a apoyo concluido es el que queda en id apoyo finalmente
                c.Id_Apoyo__c = userinfo.getUserId(); //el usuario que establece el estado del caso a apoyo concluido es el que queda en id apoyo finalmente
            } 
            
            
            
            //los casos de motos no pueden modificarse por alguien que no es el owner ni parte del equipo del caso
            if (rtCaseName.toUpperCase().startsWith('MOTOS') && UserLogged.Profile.Name!='Servicio al cliente (Motos)' && UserLogged.Profile.Name!='Integraciones' && UserLogged.Profile.Name!='System Administrator'  && UserLogged.Profile.Name!='Administrador del sistema' && c.OwnerId!=UserINfo.getUserId() && (!mapTeamMembersByCase.containsKey(c.Id) || !mapTeamMembersByCase.get(c.Id).containsKey(UserINfo.getUserId()) )){
                if (oldCase.Status != c.Status || oldCase.Reason != c.Reason || oldCase.Subcategoria__c != c.Subcategoria__c || oldCase.Respuesta_final_caso__c != c.Respuesta_final_caso__c 
                    || oldCase.Description != c.Description || oldCase.Comments != c.Comments || oldCase.Placa_del_vehiculo__c != c.Placa_del_vehiculo__c || oldCase.VIN__c != c.VIN__c
                    || oldCase.Parte__c != c.Parte__c || oldCase.Grupo_de_Parte__c != c.Grupo_de_Parte__c) 
                    	c.addError('Sólo el propietario del caso y los miembros del equipo del caso pueden modificarlo!');
            }
            
            //los casos de autos no pueden modificarse por alguien que no es el owner ni parte del equipo del caso
            if (rtCaseName.toUpperCase().startsWith('AUTO') && rtCaseName!='Autos_Mesa_de_Ayuda' && rtCaseName!='Autos_Entrega_Vehiculo_Nuevo_Usado_y_Renting' && UserLogged.Profile.Name!='Integraciones' && UserLogged.Profile.Name!='System Administrator'  && UserLogged.Profile.Name!='Administrador del sistema' && UserLogged.Profile.Name!='Administrador del sistema autos' && c.OwnerId!=UserINfo.getUserId() && (!mapTeamMembersByCase.containsKey(c.Id) || !mapTeamMembersByCase.get(c.Id).containsKey(UserINfo.getUserId()) )){
                if (oldCase.Status != c.Status || oldCase.Reason != c.Reason || oldCase.Subcategoria__c != c.Subcategoria__c || oldCase.Respuesta_final_caso__c != c.Respuesta_final_caso__c 
                    || oldCase.Description != c.Description || oldCase.Comments != c.Comments || oldCase.Placa_del_vehiculo__c != c.Placa_del_vehiculo__c || oldCase.VIN__c != c.VIN__c
                    || oldCase.Parte__c != c.Parte__c || oldCase.Grupo_de_Parte__c != c.Grupo_de_Parte__c) 
                    	c.addError('Sólo el propietario del caso y los miembros del equipo del caso pueden modificarlo!');
            }
            
            
            //Change to uppercase placa when RT is motos
            if (!String.isBlank(c.Placa_del_vehiculo__c)){ //&& rtCaseName.toUpperCase().startsWith('MOTOS')){
                c.Placa_del_vehiculo__c = c.Placa_del_vehiculo__c.toUpperCase();
            }
            
            //validate that closed habeas data have their children cases closed
            if (mapChildrenCasesMotos.containsKey(c.ID)) c.addError('El caso tiene ' + mapChildrenCasesMotos.get(c.Id) +' casos hijos relacionados sin cerrarse');
        }
        
        //Escalación de motos
        //For Motos: get the escalacion1 and 2 fields, when the case is scalating for case owners and case primera asignacion
        set<Id> setOwnerIdsCasesMotosScalating = new set<Id>();
        map<Id,User> mapOwnerCasosMotosScalating = new map<Id,User>();
        for (Case caso: newCaseList){
            if (caso.Nivel_de_Escalacin__c >= 1 && caso.Escalar_Caso__c && caso.IsClosed == false){
                setOwnerIdsCasesMotosScalating.add(caso.ownerId);
                if (caso.Primera_asignacion_motos__c!=null) setOwnerIdsCasesMotosScalating.add(caso.Primera_asignacion_motos__c);
            }
        }
        
        if (setOwnerIdsCasesMotosScalating.size()>0){
            for (User u: [Select Id,Escalacion_1_Motos__c, Escalacion_2_Motos__c from User where Id in:setOwnerIdsCasesMotosScalating]){
                mapOwnerCasosMotosScalating.put(u.Id, u);
            }
        }
        
        //update the motos cases scalating/////////////
        ///////////////////////////////////////
        List<Case> lstCasosUpdate = new List<Case>();
        //limitado a 10 registros máximo, para evitar que revienten el límite de llamadas futuras
        if (setOwnerIdsCasesMotosScalating.size()>0 && setOwnerIdsCasesMotosScalating.size() <= 10){
            for (Case caso: newCaseList){
                Case casoUpdate = new Case();
                
                if (caso.Nivel_de_Escalacin__c == 1 && caso.Escalar_Caso__c && caso.IsClosed == false){
                    casoUpdate.Id = caso.Id;
                    caso.Escalar_Caso__c = false;
                    
                    if (mapOwnerCasosMotosScalating.containsKey(caso.OwnerId) && mapOwnerCasosMotosScalating.get(caso.OwnerId).Escalacion_1_Motos__c!=null) casoUpdate.OwnerId = mapOwnerCasosMotosScalating.get(caso.OwnerId).Escalacion_1_Motos__c;
                    casoUpdate.Primera_asignacion_motos__c = caso.OwnerId;
                    
                    system.debug('mapOwnerCasosMotosScalating.get(caso.OwnerId): ' + mapOwnerCasosMotosScalating.get(caso.OwnerId));
                    system.debug('caso.Nivel_de_Escalacin__c: ' + caso.Nivel_de_Escalacin__c);
                    system.debug('casoUpdate.OwnerId: ' + casoUpdate.OwnerId);
                    
                    changeMotosOwnerScalation(caso.Id, casoUpdate.OwnerId, casoUpdate.Primera_asignacion_motos__c);
                }
                
                if (caso.Nivel_de_Escalacin__c == 2 && caso.Escalar_Caso__c && caso.IsClosed == false){
                    casoUpdate.Id = caso.Id;
                    casoUpdate.Escalar_Caso__c = false;
                    caso.Escalar_Caso__c = false;
                    
                    if (mapOwnerCasosMotosScalating.containsKey(caso.Primera_asignacion_motos__c) && mapOwnerCasosMotosScalating.get(caso.Primera_asignacion_motos__c).Escalacion_2_Motos__c!=null) casoUpdate.OwnerId = mapOwnerCasosMotosScalating.get(caso.Primera_asignacion_motos__c).Escalacion_2_Motos__c;
                    
                    system.debug('mapOwnerCasosMotosScalating.get(caso.Primera_asignacion_motos__c): ' + mapOwnerCasosMotosScalating.get(caso.Primera_asignacion_motos__c));
                    system.debug('caso.Nivel_de_Escalacin__c: ' + caso.Nivel_de_Escalacin__c);
                    system.debug('casoUpdate.OwnerId: ' + casoUpdate.OwnerId);
                    
                    changeMotosOwnerScalation(caso.Id, casoUpdate.OwnerId, null);
                }
            }
        }
        
    }
    
    public static Boolean alerta1YaMarcada=false; //For some reason, the case enters 2 times to the after update with old case value for alerta 1 equals false, so it tried to send the alert twice
    public static Boolean alerta2YaMarcada=false;
    public override void afterUpdate() { 
        //Only for one record, if there are many records the limits would let you know, this is for sending email alerts for autos
        if (newCaseList.size()==1 && newCaseList.get(0).IsClosed==false){
            Case caso = newCaseList.get(0);
            Case oldCaso = oldCaseMap.get(caso.Id);
            
            Boolean alerta1=false, alerta2=false;
            system.debug('alerta1: ' +caso.Alerta_1__c);
            system.debug('old alerta1: ' +oldCaso.Alerta_1__c);
            if (caso.Alerta_1__c && !oldCAso.Alerta_1__c && alerta1YaMarcada==false) { alerta1=true; alerta1YaMarcada=true;}
            if (caso.Alerta_2__c && !oldCAso.Alerta_2__c && alerta2YaMarcada==false) { alerta2=true; alerta2YaMarcada=true;}
            
            if (alerta1 || alerta2){
                //Get all the roles to then receive the users to send the alerts         
                set<String> setRolesRecipientes = new set<String>();
                for (CaseAlertConfiguration__mdt config: CaseAlertConfiguration__mdt.getAll().values()){
                    setRolesRecipientes.add(config.Rol_Recipiente_Alerta2y3__c); 
                    setRolesRecipientes.add(config.Rol_Recipiente_Alerta4y5__c);
                }
                
                map<String, User> mapUsuariosRecipientes = new map<String, User>();
                for (User u: [select Id, Email, UserRole.Name from User where isActive=true and UserRole.Name in: setRolesRecipientes]){
                    if (!mapUsuariosRecipientes.containsKey(u.UserRole.Name)) mapUsuariosRecipientes.put(u.UserRole.Name, u);
                }
                //if (caso.Alerta_1__c && !oldCAso.Alerta_1__c) alert1Activated(caso, oldCaso);
                //if (caso.Alerta_2__c && !oldCAso.Alerta_2__c) alert2Activated(caso, oldCaso);
                
                for (CaseAlertConfiguration__mdt config: CaseAlertConfiguration__mdt.getAll().values()){
                    if (caso.Reason == config.Reason__c && caso.Subcategoria__c == config.Subcategoria__c)    {
                        system.debug('Reason y subcategoria iguales');
                        if (config.Subcategoria_2__c==null || (caso.Subcategoria_2__c== config.Subcategoria_2__c)){
                            system.debug('Subcategoria 2 iguales o no importa');
                            if (config.Subcategoria_3__c==null || (caso.Subcategoria_3__c== config.Subcategoria_3__c)){
                                system.debug('Subcategoria 3 iguales o no importa');
                                system.debug('Fila de config: ' + config.Label);
                                String recipienteAlerta2y3, recipienteAlerta4y5;
                                String cronAlerta2, cronAlerta3,cronAlerta4, cronAlerta5;
                                
                                if (alerta1){
                                    if (config.Buscar_Agencia_Concesionario_Alerta2y3__c || !String.isblank(config.Usuario_Recipiente_Alerta2y3__c) || config.Recipiente_Alerta2y3_Manager__c){
                                        //si se debe buscar el rol en la tabla de miembros de concesionario, puede que haya que buscar en la tabla 2 roles en caso de que se especificara un 2do rol para estas alertas
                                        if (config.Buscar_Agencia_Concesionario_Alerta2y3__c){
                                            list<Miembro_de_Concesionario__c> lstMiembrosRolConcesionario2y3 = String.isBlank(config.Rol_Recipiente_Alerta2y3_2do__c) ? [select Nombre_de_asesor__r.Email from Miembro_de_Concesionario__c where Concesionario__c=:caso.Agencia_motos_Vitrina_autos__c and Rol_de_asesor__c like :(config.Rol_Recipiente_Alerta2y3__c + '%') and Nombre_de_asesor__r.isActive=true] 
                                                : [select Nombre_de_asesor__r.Email from Miembro_de_Concesionario__c where Concesionario__c=:caso.Agencia_motos_Vitrina_autos__c and (Rol_de_asesor__c like :(config.Rol_Recipiente_Alerta2y3__c + '%') or Rol_de_asesor__c like :(config.Rol_Recipiente_Alerta2y3_2do__c + '%') ) and Nombre_de_asesor__r.isActive=true];
                                            if (lstMiembrosRolConcesionario2y3.size()>0) recipienteAlerta2y3 = lstMiembrosRolConcesionario2y3.get(0).Nombre_de_asesor__r.Email;
                                        }
                                        //si se debe usar un usuario específico al cual enviar las alertas 2 y 3
                                        if (!String.isblank(config.Usuario_Recipiente_Alerta2y3__c)){ recipienteAlerta2y3 = [select Email from User where userName=:config.Usuario_Recipiente_Alerta2y3__c].Email; }
                                        //si el email a quien se va a enviar es el owner del propietario del caso
                                        if (config.Recipiente_Alerta2y3_Manager__c){ recipienteAlerta2y3 = [select Manager.Email from User where Id=:caso.OwnerId].Manager.Email; }
                                    }else{
                                         //este debería ser el caso más común, el de enviar al email del usuario del rol especificado
                                        if(mapUsuariosRecipientes.containsKey(config.Rol_Recipiente_Alerta2y3__c))    {
                                            recipienteAlerta2y3 = mapUsuariosRecipientes.get(config.Rol_Recipiente_Alerta2y3__c).email;
                                        }
                                    }
                                    
                                   
                                }
                                if (alerta2){
                                    if (config.Buscar_Agencia_Concesionario_Alerta4y5__c || !String.isblank(config.Usuario_Recipiente_Alerta4y5__c) || config.Recipiente_Alerta4y5_Manager__c){
                                        //si se debe buscar el rol en la tabla de miembros de concesionario, puede que haya que buscar en la tabla 2 roles en caso de que se especificara un 2do rol para estas alertas
                                        if (config.Buscar_Agencia_Concesionario_Alerta4y5__c){
                                            list<Miembro_de_Concesionario__c> lstMiembrosRolConcesionario4y5 = String.isBlank(config.Rol_Recipiente_Alerta4y5_2do__c) ? [select Nombre_de_asesor__r.Email from Miembro_de_Concesionario__c where Concesionario__c=:caso.Agencia_motos_Vitrina_autos__c and Rol_de_asesor__c like :(config.Rol_Recipiente_Alerta4y5__c + '%') and Nombre_de_asesor__r.isActive=true] 
                                                : [select Nombre_de_asesor__r.Email from Miembro_de_Concesionario__c where Concesionario__c=:caso.Agencia_motos_Vitrina_autos__c and (Rol_de_asesor__c like :(config.Rol_Recipiente_Alerta4y5__c + '%') or Rol_de_asesor__c like :(config.Rol_Recipiente_Alerta4y5_2do__c + '%') ) and Nombre_de_asesor__r.isActive=true];
                                            if (lstMiembrosRolConcesionario4y5.size()>0) recipienteAlerta4y5 = lstMiembrosRolConcesionario4y5.get(0).Nombre_de_asesor__r.Email;
                                        }
                                        //si se debe usar un usuario específico al cual enviar las alertas 4 y 5
                                        if (!String.isblank(config.Usuario_Recipiente_Alerta4y5__c)){ recipienteAlerta4y5 = [select Email from User where userName=:config.Usuario_Recipiente_Alerta4y5__c].Email;}
                                        //si el email a quien se va a enviar es el owner del propietario del caso
                                        if (config.Recipiente_Alerta4y5_Manager__c){ recipienteAlerta4y5 = [select Manager.Email from User where Id=:caso.OwnerId].Manager.Email; }
                                    }else{
                                        //este debería ser el caso más común, el de enviar al email del usuario del rol especificado
                                        if(mapUsuariosRecipientes.containsKey(config.Rol_Recipiente_Alerta4y5__c))    {
                                            recipienteAlerta4y5 = mapUsuariosRecipientes.get(config.Rol_Recipiente_Alerta4y5__c).email;
                                        }    
                                    }
                                    
                                }
                              
                                
                                system.debug('recipienteAlerta2y3: ' + recipienteAlerta2y3);
                                system.debug('recipienteAlerta4y5: ' + recipienteAlerta4y5);
                                if (recipienteAlerta2y3!=null){
                                    sendEmailAfterXHours(Integer.valueOf(config.Alerta2_Hrs_vencido_TR1__c), caso.CaseNumber + ' - alerta 2. ' + String.valueOf(Datetime.now()), caso, recipienteAlerta2y3);
                                    sendEmailAfterXHours(Integer.valueOf(config.Alerta3_Hrs_vencido_TR1__c), caso.CaseNumber + ' - alerta 3. ' + String.valueOf(Datetime.now()), caso, recipienteAlerta2y3);    
                                }
                                if (recipienteAlerta4y5!=null){
                                    sendEmailAfterXHours(Integer.valueOf(config.Alerta3_Hrs_vencido_TR1__c), caso.CaseNumber + ' - alerta 4', caso, recipienteAlerta4y5);
                                    sendEmailAfterXHours(Integer.valueOf(config.Alerta4_Hrs_vencido_TR1__c), caso.CaseNumber + ' - alerta 5', caso, recipienteAlerta4y5);    
                                }
                              
                            }    
                        }
                    }
                }
            }
            
        }
    
       
    }
    
    @future
    private static void changeMotosOwnerScalation(Id idCaso, ID newOwnerId, Id primeraAsignacion){
        Case caso = new Case( Id = idCaso, ownerId = newOwnerId);//, Escalar_Caso__c=false );
        if (primeraAsignacion!=null) caso.Primera_asignacion_motos__c = primeraAsignacion;
        update caso;
    }
       
    
    public static void sendEmailAfterXHours(Integer hours, String jobName, Case caso, String recipiente){
        String asunto = 'Notificación de vencimiento del Caso';
        String mensaje = 'El Caso <a href="' + Label.URLNavegacionLightning +'/'+ caso.Id + '" rel="noopener noreferrer" target="_blank">'+
            '# ' + caso.CaseNumber +' está vencido.</a>. Por favor darle seguimiento lo antes posible.';
        if (hours==0) schCaseSendingAlerts.sendEmail(recipiente, asunto, mensaje);
        else{
            Datetime sysTime = System.now().addHours(hours); //addMinutes(hours);
            String cronExpression = '0 ' +  sysTime.minute() + ' ' + sysTime.hour() + ' ' + sysTime.day() + ' ' + sysTime.month() + ' ? ' + sysTime.year();
            system.debug('cronExpression: ' + cronExpression);
            System.schedule(jobName, cronExpression, new schCaseSendingAlerts(caso.Id,recipiente, asunto, mensaje ));
        }
        
    }
    
    public override void beforeInsert() {
        //Se encarga de validar que no se pueda marcar la casilla apoyo concluido sin haber diligenciado comentarios internos.
        for (Case c: newCaseList){
            if (c.Status=='Apoyo Concluido' && String.isBlank(c.Comments)) c.addError('Debe diligenciar los comentarios internos antes de cambiar al estado Apoyo Concluído!');
        }
    }
}