/**
 * Fanalca
 * @author           Juan Ansaldi
 * Description:      .
 *
 * Changes (Version)
 * -------------------------------------
 *           No.     Date            Author                  Description
 *           -----   ----------      --------------------    ---------------
 * @version  1.0     03/17/2021      Juan Ansaldi            Class definition.
 *********************************************************************************************************/
public with sharing class UpdateTaskOwnerBatch implements Database.Batchable<Task> {//public with sharing class UpdateTaskOwnerBatch implements Database.Batchable<sObject> {
  /*
    Set<Id> accountIds;
  Set<Id> setWhatIdsTasks;
  Id newOwnerUser;
  Id oldOwnerId;
  String query;
  public UpdateTaskOwnerBatch(Set<Id> accIds, Id newOwner, Set<Id> setWhatIds, Id oldOwId) {
      accountIds = accIds;
      newOwnerUser = newOwner;
      setWhatIdsTasks = setWhatIds;
      oldOwnerId = oldOwId;
  }
    */
  list<changeAccountOwner.accountOwnerChangesData> datosCuentas;
  list<changeAccountOwner.tasksOwnerChangesData> datosTasks;
  map<Id,changeAccountOwner.tasksOwnerChangesData> mapDatosTasks;
  set<Id> oldAccountOwners;  
  public UpdateTaskOwnerBatch(list<changeAccountOwner.tasksOwnerChangesData> datos, list<changeAccountOwner.accountOwnerChangesData> datosCtas) {
      datosTasks = datos;
      datosCuentas = datosCtas;
      mapDatosTasks = new map<Id,changeAccountOwner.tasksOwnerChangesData>();
	  oldAccountOwners = new set<Id>();
      
      for (changeAccountOwner.tasksOwnerChangesData dato: datos){
      	mapDatosTasks.put(dato.whatId, dato);
        oldAccountOwners.add(dato.oldOwnerId);
      }
      system.debug('Constructor UpdateRelatedAccountsBatch. mapDatosTasks: ' + mapDatosTasks.values());
  }
  
  /*
  public Database.QueryLocator start(Database.BatchableContext bc) {
    String limitString = '';
    if (Test.isRunningTest()) {
      limitString = 'LIMIT 20';
    }
    
    Account a = [Select Id, OwnerId, Owner.Profile.Name from Account where Id =: (new list<Id>(accountIds))[0]];
      
     if (!a.Owner.Profile.Name.toUpperCase().contains('MOTO')){
                //query = 'Select Id, OwnerId, WhoId from Task where RecordType.DeveloperName = \'Tareas_Autos\' AND WhatId IN: setWhatIdsTasks AND Status = \'Programada\' AND WhoId = \''+ a.OwnerId +'\'' + limitString;
                query = 'Select Id, OwnerId, WhoId from Task where RecordType.DeveloperName = \'Tareas_Autos\' AND WhatId IN: setWhatIdsTasks AND Status = \'Programada\' AND OwnerId = \''+ oldOwnerId +'\'' + limitString;
                
            } else {
                //query = 'Select Id, OwnerId, WhoId from Task where RecordType.DeveloperName = \'Motos_Tareas\' AND WhatId IN: setWhatIdsTasks AND Status = \'Programada\' AND WhoId = \''+ a.OwnerId +'\'' + limitString;
                query = 'Select Id, OwnerId, WhoId from Task where RecordType.DeveloperName = \'Motos_Tareas\' AND WhatId IN: setWhatIdsTasks AND Status = \'Programada\' AND OwnerId = \''+ oldOwnerId +'\'' + limitString;
            }
      
    return Database.getQueryLocator(query);
  }
*/
    public Iterable<Task> start(Database.BatchableContext bc) {
      //get the tasks
      list<Task> lstTasksToProcess = new list<Task>();
      list<Task> allTasksRelated = [Select WhatId, Id, OwnerId, Owner.Name,Owner.Profile.Name, recordType.DeveloperName from Task where WhatId IN: mapDatosTasks.keySet() and Status = 'Programada' AND OwnerId in:oldAccountOwners];
      for (Task t: allTasksRelated) {
          changeAccountOwner.tasksOwnerChangesData datoTask = mapDatosTasks.get(t.whatId);
          
          if (datoTask!=null && t.OwnerId == datoTask.oldOwnerId) {
              if ( (t.recordType.DeveloperName.toUpperCase().contains('MOTO') && datoTask.newOwnerProfileName.toUpperCase().contains('MOTO')) || (t.recordType.DeveloperName.toUpperCase().contains('AUTO') && datoTask.newOwnerProfileName.toUpperCase().contains('AUTO'))){
                  t.OwnerId = datoTask.newOwnerId;
                  lstTasksToProcess.add(t);   
                  system.debug('t to UpdateOwner: ' + t);
              }
          }
      }
     	
        system.debug('lstTasksToProcess.size() ' + lstTasksToProcess.size());
        return lstTasksToProcess;
  }
  
    public void execute(Database.BatchableContext bc, List<Task> iteraciones){
        update iteraciones;
    }
    /*
  public void execute(Database.BatchableContext BC, List<Task> tasks) {
      List<Task> lstTasksUpdate = new List<Task>();
      //User u = [Select Id, ContactId from User where Id=: newOwnerUser];
      User u = [Select Id, ContactId from User where Id=: oldOwnerId];
      if(tasks.size() > 0) {
          for(Task t : tasks) {
              Task ta = New Task();
              ta.Id = t.Id;
              ta.OwnerId = newOwnerUser;
              if(u.ContactId!=null) ta.WhoId = u.ContactId; 
              lstTasksUpdate.add(ta);
          }
      }   
      update lstTasksUpdate;
  }
*/
  public void finish(Database.BatchableContext BC) {
      UpdateContactOwnerBatch batchable = new UpdateContactOwnerBatch(datosCuentas);//UpdateContactOwnerBatch batchable = new UpdateContactOwnerBatch(accountIds, newOwnerUser, oldOwnerId);
      Database.executebatch(batchable, 1);
  }
}