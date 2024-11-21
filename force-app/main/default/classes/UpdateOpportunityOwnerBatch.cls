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
 * @version  1.1     08/XX/2021      Me			             Tuning class and updating vitrina.
 * @version  1.2     11/04/2021      Me			             delete ReasignacionMasiva__c custom settings if the reassignment finished
 *********************************************************************************************************/
public with sharing class UpdateOpportunityOwnerBatch implements Database.Batchable<Opportunity> {//public with sharing class UpdateOpportunityOwnerBatch implements Database.Batchable<sObject> {
  Set<Id> accountIds;
  Id newOwnerUser;
  String query;
  Set<String> setEtapaAutos;
  Set<String> setEtapaMotos;
    
  list<changeAccountOwner.accountOwnerChangesData> datosCuentas;
  map<Id,changeAccountOwner.accountOwnerChangesData> mapDatosCuentas;
  set<Id> oldAccountOwners;
  set<Id> newOwnerIds;
  map<Id, list<Id>> mapConcesionariosXUsuario;  
  public UpdateOpportunityOwnerBatch(list<changeAccountOwner.accountOwnerChangesData> datos) {
      datosCuentas = datos;
      oldAccountOwners = new set<Id>();
      mapDatosCuentas = new map<Id,changeAccountOwner.accountOwnerChangesData>();
      newOwnerIds = new set<Id>();  
      mapConcesionariosXUsuario = new map<Id, list<Id>>();
      for (changeAccountOwner.accountOwnerChangesData dato: datos){
      	mapDatosCuentas.put(dato.accountId, dato);
        oldAccountOwners.add(dato.oldOwnerId);
        newOwnerIds.add(dato.newOwnerId);  
      }
      
      for (Miembro_de_Concesionario__c mc: [Select Id,Nombre_de_asesor__c,Concesionario__c from Miembro_de_Concesionario__c where Nombre_de_asesor__c in: newOwnerIds]){
          if (!mapConcesionariosXUsuario.containsKey(mc.Nombre_de_asesor__c)) mapConcesionariosXUsuario.put(mc.Nombre_de_asesor__c, new list<Id>());
          mapConcesionariosXUsuario.get(mc.Nombre_de_asesor__c).add(mc.Concesionario__c);
      }
      
      system.debug('Constructor UpdateOpportunityOwnerBatch. mapDatosCuentas: ' + mapDatosCuentas.values());
  }
    
  public Iterable<Opportunity> start(Database.BatchableContext bc) {
      //get the opps
      set<String> setAllStages = new Set<String>{'P0', 'P1', 'P2', 'P3', 'P4', 'P5','-P0', '-P1', '-P2', '-P3'};
      list<Opportunity> lstOppsToProcess = new list<Opportunity>();
      list<Opportunity> allOppsRelated = [Select AccountId, Id, OwnerId, Owner.Name,Owner.Profile.Name, recordType.DeveloperName from Opportunity where StageName IN: setAllStages AND AccountId in:mapDatosCuentas.keySet()  AND OwnerId in:oldAccountOwners];
      for (Opportunity op: allOppsRelated) {
          changeAccountOwner.accountOwnerChangesData datoCuenta = mapDatosCuentas.get(op.AccountId);
          
          if (datoCuenta!=null && op.OwnerId == datoCuenta.oldOwnerId) {
              if ( (op.recordType.DeveloperName.toUpperCase().contains('MOTO') && datoCuenta.newOwnerProfileName.toUpperCase().contains('MOTO')) || (op.recordType.DeveloperName.toUpperCase().contains('AUTO') && datoCuenta.newOwnerProfileName.toUpperCase().contains('AUTO'))){
                  op.OwnerId = datoCuenta.newOwnerId;
                  
                  //buscar en el mapa de concesionarios por usuario y setear concesionario cuando solo tiene un concesionario matriculado el new owner
                  if (mapConcesionariosXUsuario.containsKey(op.OwnerId)){
                      if (mapConcesionariosXUsuario.get(op.OwnerId).size()==1) op.Vitrina__c= mapConcesionariosXUsuario.get(op.OwnerId)[0];
                  }
                  
                  lstOppsToProcess.add(op);   
                  system.debug('op to UpdateOwner: ' + op);
              }
          }
      }
     	
        system.debug('lstOppsToProcess.size() ' + lstOppsToProcess.size());
        return lstOppsToProcess;
        
  }

    public void execute(Database.BatchableContext bc, List<Opportunity> iteraciones){
        update iteraciones;
    }
 
  public void finish(Database.BatchableContext BC) {
      list<AsyncApexJob> reassignmentsNotCompletedUser = [SELECT Id, Status, NumberOfErrors, JobItemsProcessed,
                              TotalJobItems, CreatedBy.Email, MethodName
                              FROM AsyncApexJob WHERE CreatedById=:userInfo.getUserId() 
                                                          and ApexClass.Name in ('UpdateAccountOwnerBatch','UpdateOpportunityOwnerBatch','UpdateTaskOwnerBatch','UpdateContactOwnerBatch','UpdateRelatedAccountsBatch') 
                                                          and Status not in('Aborted','Completed','Failed')];
      
      if (reassignmentsNotCompletedUser.size()==0){
          system.debug('Reasignación Finalizada');
          ReasignacionMasiva__c t = ReasignacionMasiva__c.getValues(UserINfo.getUserId());
          if (t!=null) delete t;    
      }
            
  }
}