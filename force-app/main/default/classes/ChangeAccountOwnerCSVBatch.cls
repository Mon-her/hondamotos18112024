//Created by Me, Aug '21
//Test Class: ChangeAccountOwnerCSV_Test
//This batch must be called in a batch size of ONE 1
public class ChangeAccountOwnerCSVBatch  implements Database.Batchable<sObject>, Database.Stateful {
    list<Sobject> lstActualizar;
    list<Log__c> lstErrores = new list<Log__c>();
    Datetime horaInicio;
    String objeto;
    public ChangeAccountOwnerCSVBatch (list<Sobject> lstDatosActualizar, String strObjeto, Datetime horaStart){
        lstActualizar = lstDatosActualizar;
        objeto = strObjeto;
        horaInicio = horaStart;
    }
    
    public Iterable<Sobject> start(Database.BatchableContext bc) {
        return lstActualizar;
    }
    
    public void execute(Database.BatchableContext bc, List<Sobject> iteraciones){
        try{
        	update iteraciones;    
        }catch (Exception ex){
            Log__c error = new Log__c();
            Id accountId, relatedAccountId, taskId, oppId, contactId;
            if (objeto=='Cuentas') error.Cuenta__c = ((Account) iteraciones.get(0)).Id;
            if (objeto=='Oportunidades') {error.Oportunidad__c = ((Opportunity) iteraciones.get(0)).Id; error.Cuenta__c = ((Opportunity) iteraciones.get(0)).AccountId;}
            if (objeto=='Contactos') { error.Contacto__c = ((Contact) iteraciones.get(0)).Id; error.Cuenta__c = ((Contact) iteraciones.get(0)).AccountId;}
        	if (objeto=='Cuentas Relacionadas') { error.Cuenta__c = ((Account) iteraciones.get(0)).Id; }
            if (objeto=='Tareas') {
            	Task t = (Task) iteraciones.get(0);
                if (t.What.Type=='Opportunity') error.Oportunidad__c = t.WhatId;
                if (t.What.Type=='Account') error.Cuenta__c = t.WhatId;
                error.Asunto__c = t.Subject;
                error.Asignado_a__c = t.OwnerId;
                error.Fecha_Contacto__c = t.ActivityDate;
                error.Id_Tarea__c = t.Id;
            }
            error.Hora_Inicio_Reasignacion__c = horaInicio;
            error.Error_Reasignacion__c = ex.getMessage();
            error.Objeto_a_Reasignar__c = objeto;
            lstErrores.add(error);
        }
    }
    
    public void finish(Database.BatchableContext BC) {
        if (lstErrores.size()>0) insert lstErrores;
        if (lstActualizar.size()>0){
        	/*Map<String,String> keys = new Map<String,String>();
            Map<String,Schema.SobjectType> describe = Schema.getGlobalDescribe();
            for(String s:describe.keyset())
                keys.put(describe.get(s).getDescribe().getKeyPrefix(),s);
            
            Id recordId =lstActualizar.get(0).Id;
            String strObjeto = keys.get(String.valueOf(recordId).substring(0,3));
            system.debug(strObjeto);    
            */
            
            // Get the ID of the AsyncApexJob representing this batch job
            // from Database.BatchableContext.
            // Query the AsyncApexJob object to retrieve the current job's information.
            AsyncApexJob a = [SELECT Id, Status, NumberOfErrors, JobItemsProcessed,
                              TotalJobItems, CreatedBy.Email, MethodName
                              FROM AsyncApexJob WHERE Id =
                              :BC.getJobId()];
            
            list<AsyncApexJob> reassignmentsNotCompletedUser = [SELECT Id, Status, NumberOfErrors, JobItemsProcessed,
                              TotalJobItems, CreatedBy.Email, MethodName
                              FROM AsyncApexJob WHERE CreatedById=:userInfo.getUserId() and ApexClass.Name='ChangeAccountOwnerCSVBatch' and Status not in('Aborted','Completed','Failed')];
            
            // Get the Id for our custom notification type
            CustomNotificationType notificationType = 
                [SELECT Id, DeveloperName 
                 FROM CustomNotificationType 
                 WHERE DeveloperName='Avisos_por_Flow'];
            
            // Create a new custom notification
            Messaging.CustomNotification notification = new Messaging.CustomNotification();
    
            // Set the contents for the notification
            notification.setTitle('Notificatión de Asignación Masiva de ' + objeto);
            //notification.setBody('Errores '+ a.NumberOfErrors +' / Total de Registros ' + a.TotalJobItems);
    notification.setBody('Errores '+ lstErrores.size() +' / Total de Registros ' + lstActualizar.size());
            // Set the notification type and target
            notification.setNotificationTypeId(notificationType.Id);
            notification.setTargetId(a.Id);//notification.setTargetId(targetId);
            
            // Actually send the notification
            try {
                //if the reassignments process finished, then delete the custom settings for the current user
                if (reassignmentsNotCompletedUser.size()==0){
                    system.debug('Reasignación Finalizada');
                    ReasignacionMasiva__c t = ReasignacionMasiva__c.getValues(UserINfo.getUserId());
                    if (t!=null) delete t;    
                }
                
                notification.send(new set<String> {UserINfo.getUserId()});//notification.send(recipientsIds);
            }
            catch (Exception e) {
                System.debug('Problem sending notification: ' + e.getMessage());
            }
        }
        
  }
}