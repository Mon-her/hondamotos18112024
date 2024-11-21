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
public with sharing class UpdateAccountOwnerBatch implements Database.Batchable<sObject> {
  /*list<Id> accountIds;
  Id newOwnerUser;
  public UpdateAccountOwnerBatch(List<Id> accIds, list<Id> newOwners) {
      accountIds = accIds;
      newOwnerUser = newOwner;
  }*/
  list<changeAccountOwner.accountOwnerChangesData> datosCuentas;
  map<Id,changeAccountOwner.accountOwnerChangesData> mapDatosCuentas;
    
  public UpdateAccountOwnerBatch(list<changeAccountOwner.accountOwnerChangesData> datos) {
      datosCuentas = datos;
      mapDatosCuentas = new map<Id,changeAccountOwner.accountOwnerChangesData>();
      for (changeAccountOwner.accountOwnerChangesData dato: datos){
      	mapDatosCuentas.put(dato.accountId, dato);
      }
      system.debug('Constructor UpdateAccountOwnerBatch. mapDatosCuentas: ' + mapDatosCuentas.values());
  }
    
  public Database.QueryLocator start(Database.BatchableContext bc) {
    String limitString = '';
    if (Test.isRunningTest()) {
      limitString = 'LIMIT 20';
    }
    
   	//set<Id> accountIds = new set<Id>();
    //for (changeAccountOwner.accountOwnerChangesData dato: datosCuentas){
	//	accountIds.add(dato.accountId);	          
    //}
      
    String query;// = 'Select Id, OwnerId from Account where Id in:mapDatosCuentas.keySet() '+ limitString;//String query = 'Select Id, OwnerId from Account where Id =\'' + (new list<Id>(accountIds))[0] +'\''+ limitString;
    if (datosCuentas.size()==1) query = 'Select Id, OwnerId from Account where Id = \''+ datosCuentas.get(0).accountId +'\' '+ limitString;
    else query = 'Select Id, OwnerId from Account where Id in:mapDatosCuentas.keySet() '+ limitString;
    system.debug('query: ' + query);  
    return Database.getQueryLocator(query);
  }

  public void execute(Database.BatchableContext BC, List<Account> accounts) {
      List<Account> lstUpdateAccounts = new List<Account>();
      for (Account acc : accounts) {
         Account updateAcc = new Account();
         updateAcc.Id = acc.Id;
         updateAcc.OwnerId = mapDatosCuentas.get(acc.Id).newOwnerId;//updateAcc.OwnerId = newOwnerUser;
         lstUpdateAccounts.add(updateAcc);
      }
      update lstUpdateAccounts;
  }

  public void finish(Database.BatchableContext BC) {
      UpdateOpportunityOwnerBatch batchable = new UpdateOpportunityOwnerBatch(datosCuentas);//UpdateOpportunityOwnerBatch batchable = new UpdateOpportunityOwnerBatch(accountIds, newOwnerUser);
      Database.executebatch(batchable, 1);
  }
}