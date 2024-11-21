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
//public with sharing class UpdateContactOwnerBatch implements Database.Batchable<sObject> {
public with sharing class UpdateContactOwnerBatch implements Database.Batchable<Contact> {
  /*Set<Id> accountIds;
  Id newOwnerUser;
  Id oldOwnerId;
  public UpdateContactOwnerBatch(Set<Id> accIds, Id newOwner, Id oldOwId) {
      accountIds = accIds;
      newOwnerUser = newOwner;
      oldOwnerId = oldOwId;
  }
    */
    list<changeAccountOwner.accountOwnerChangesData> datosCuentas;
  map<Id,changeAccountOwner.accountOwnerChangesData> mapDatosCuentas;
  set<Id> oldAccountOwners;
    
  public UpdateContactOwnerBatch(list<changeAccountOwner.accountOwnerChangesData> datos) {
      datosCuentas = datos;
      mapDatosCuentas = new map<Id,changeAccountOwner.accountOwnerChangesData>();
      oldAccountOwners = new set<Id>();
      
      for (changeAccountOwner.accountOwnerChangesData dato: datos){
      	mapDatosCuentas.put(dato.accountId, dato);
        oldAccountOwners.add(dato.oldOwnerId);
      }
      system.debug('Constructor UpdateRelatedAccountsBatch. mapDatosCuentas: ' + mapDatosCuentas.values());
  }
    
    /*
  public Database.QueryLocator start(Database.BatchableContext bc) {
    String limitString = '';
    if (Test.isRunningTest()) {
      limitString = 'LIMIT 20';
    }
    Account a = [Select Id, OwnerId, Owner.Profile.Name from Account where Id =: (new list<Id>(accountIds))[0]];
    //String query = 'Select Id, OwnerId from Contact where Account.RecordType.DeveloperName = \'AM_CUE_Cuenta_empresarial \' AND OwnerId = \''+ a.OwnerId +'\' AND AccountId =\'' +a.Id+'\''+ limitString;
    String query = 'Select Id, OwnerId from Contact where Account.RecordType.DeveloperName = \'AM_CUE_Cuenta_empresarial \' AND OwnerId = \''+ oldOwnerId +'\' AND AccountId =\'' +a.Id+'\''+ limitString;
    return Database.getQueryLocator(query);
  }
    */
    public Iterable<Contact> start(Database.BatchableContext bc) {
        //Account a = [Select Id, OwnerId, Owner.Profile.Name from Account where Id =: (new list<Id>(accountIds))[0]];
        //String query = 'Select Id, OwnerId from Contact where Account.RecordType.DeveloperName = \'AM_CUE_Cuenta_empresarial \' AND OwnerId = \''+ oldOwnerId +'\' AND AccountId =\'' +a.Id+'\''+ limitString;
        list<Contact> lstAllContactsRelated = [Select Id, OwnerId,AccountId from Contact where Account.RecordType.DeveloperName = 'AM_CUE_Cuenta_empresarial' AND OwnerId in: oldAccountOwners AND AccountId in: mapDatosCuentas.keySet()];
        list<Contact> lstContactsToProcess = new list<Contact>();
        
        for (contact c: lstAllContactsRelated){
            changeAccountOwner.accountOwnerChangesData datoCuenta = mapDatosCuentas.get(c.AccountId);    
            if (c.OwnerId == datoCuenta.oldOwnerId) {
                c.ownerId= datoCuenta.newOwnerId;
                lstContactsToProcess.add(c);
            }
        }
        return lstContactsToProcess;
    }
    
    public void execute(Database.BatchableContext bc, List<Contact> iteraciones){
        update iteraciones;
    }

  /*  
  public void execute(Database.BatchableContext BC, List<Contact> contacts) {
      List<Contact> lstUpdateContacts = new List<Contact>();
      for (Contact con : contacts) {
         Contact updateCon = new Contact();
         updateCon.Id = con.Id;
         updateCon.OwnerId = oldOwnerId;//updateCon.OwnerId = newOwnerUser;
         lstUpdateContacts.add(updateCon);
      }
      update lstUpdateContacts;
  }
*/
  public void finish(Database.BatchableContext BC) {
      UpdateRelatedAccountsBatch batchable = new UpdateRelatedAccountsBatch(datosCuentas);//UpdateRelatedAccountsBatch batchable = new UpdateRelatedAccountsBatch(accountIds, newOwnerUser, oldOwnerId);
      Database.executebatch(batchable, 1);
  }
}