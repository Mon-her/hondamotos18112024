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
 * @version  1.1     11/04/2021      Me			             delete ReasignacionMasiva__c custom settings if the reassignment finished
 *********************************************************************************************************/
public with sharing class UpdateRelatedAccountsBatch implements Database.Batchable<Account> {//public with sharing class UpdateRelatedAccountsBatch implements Database.Batchable<sObject> {
    list<changeAccountOwner.accountOwnerChangesData> datosCuentas;
  map<Id,changeAccountOwner.accountOwnerChangesData> mapDatosCuentas;
  set<Id> oldAccountOwners;
    
  public UpdateRelatedAccountsBatch(list<changeAccountOwner.accountOwnerChangesData> datos) {
      datosCuentas = datos;
      mapDatosCuentas = new map<Id,changeAccountOwner.accountOwnerChangesData>();
      oldAccountOwners = new set<Id>();
      for (changeAccountOwner.accountOwnerChangesData dato: datos){
      	mapDatosCuentas.put(dato.accountId, dato);
        oldAccountOwners.add(dato.oldOwnerId);
      }
      system.debug('Constructor UpdateRelatedAccountsBatch. mapDatosCuentas: ' + mapDatosCuentas.values());
  }
    
 
  
    public Iterable<Account> start(Database.BatchableContext bc) {
      
         list<Account> lstAccountsToProcess = new list<Account>();
        List<Relacion_de_Cuenta__c> lstRelaciones = [Select Id, Cuenta_Relacionada__c,Cuenta_Relacionada__r.OwnerId,Cuenta_Principal__c From Relacion_de_Cuenta__c Where Cuenta_Principal__c =: mapDatosCuentas.keySet() AND Cuenta_Relacionada__r.OwnerId =: oldAccountOwners];
        for(Relacion_de_Cuenta__c rel : lstRelaciones) {
            changeAccountOwner.accountOwnerChangesData datoCuenta = mapDatosCuentas.get(rel.Cuenta_Principal__c);  
            if (rel.Cuenta_Relacionada__r.OwnerId == datoCuenta.oldOwnerId){
                Account acc = new Account(Id=rel.Cuenta_Relacionada__c, OwnerId=datoCuenta.newOwnerId);
                lstAccountsToProcess.add(acc);
            }
           
        }
       
        return lstAccountsToProcess;
  	}

    public void execute(Database.BatchableContext bc, List<Account> iteraciones){
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