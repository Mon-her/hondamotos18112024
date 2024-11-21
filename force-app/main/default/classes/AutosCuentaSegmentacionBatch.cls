/**
 * Fanalca
 * @author           Juan Ansaldi
 * Description:      Batch class that updates Segmentacion__c field for Accounts.
 *
 * Changes (Version)
 * -------------------------------------
 *           No.     Date            Author                  Description
 *           -----   ----------      --------------------    ---------------
 * @version  1.0     03/17/2021      Juan Ansaldi            Class definition.
 *********************************************************************************************************/
global with sharing class AutosCuentaSegmentacionBatch implements Database.Batchable<sObject>, Database.Stateful {
  global AutosCuentaSegmentacionBatch() {
  }
  global Set<Id> successfullIdsSet;
  public Database.QueryLocator start(Database.BatchableContext bc) {
    String limitString = '';
    if (Test.isRunningTest()) {
      limitString = 'LIMIT 20';
    }
    String hoy = String.valueOf(Date.today());
    String query = 'SELECT Id, FechaAutosPU__c, Accord_Civic__c, Segmentacion2__c, Fecha_Fin_Garantia__c from Account where Fecha_Fin_Garantia__c != null AND Fecha_Fin_Garantia__c >='+hoy+limitString;
    /*String query = 'SELECT Id, FechaAutosPU__c, Accord_Civic__c, Segmentacion2__c, Fecha_Fin_Garantia__c from Account where Fecha_Fin_Garantia__c != null '+limitString;*/
    return Database.getQueryLocator(query);
  }
    
  public void execute(Database.BatchableContext BC, List<Account> accounts) {
      //Se ejecuta todos los dias a las 11:00 PM
      List<Account> lstUpdate = new List<Account>();
      successfullIdsSet = new Set<Id>();
      for (Account acc : accounts) {
      Account account = New Account();
          system.debug('valoracc '+acc.Segmentacion2__c + 'Fecha'+ acc.Fecha_Fin_Garantia__c);
          
          if(acc.Segmentacion2__c == null || acc.Segmentacion2__c == '' || acc.Fecha_Fin_Garantia__c < date.today()) {
          	acc.Segmentacion2__c = 'Prospecto';
          } else if(acc.Segmentacion2__c == 'Prospecto') {
              account.Id = acc.Id;
              if(acc.Accord_Civic__c == true) {
                  account.Segmentacion2__c = 'Cliente en Garantía (Extendida)';
              } else {
                  account.Segmentacion2__c = 'Cliente en Garantía';
              }
               lstUpdate.add(account);
          } else if ((acc.Segmentacion2__c == 'Cliente en Garantía' || acc.Segmentacion2__c == 'Cliente en Garantía (Extendida)') && acc.Fecha_Fin_Garantia__c == Date.today()) {
              account.Id = acc.Id;
              account.Segmentacion2__c = 'Cliente Potencial';
              account.Fecha_Fin_Garantia__c = acc.Fecha_Fin_Garantia__c.addYears(5);
              lstUpdate.add(account);
          } else if (acc.Segmentacion2__c == 'Cliente Potencial' && acc.Fecha_Fin_Garantia__c == Date.today()) {
              account.Id = acc.Id;
              account.Segmentacion2__c = 'Cliente Antiguo';
              lstUpdate.add(account);
          }
      }
      Database.SaveResult[] srList = Database.Update(lstUpdate, false);
      
      // Iterate through each returned result
      for (Database.SaveResult sr : srList) {
          if (sr.isSuccess()) {
              // Operation was successful, so get the ID of the record that was processed
              System.debug('Successfully updated account. Account ID: ' + sr.getId());
              successfullIdsSet.add(sr.getId());
          }
      }
  }

  public void finish(Database.BatchableContext BC) {
      System.debug(successfullIdsSet);
      AutosUpdateNotFailedRecords batchable = new AutosUpdateNotFailedRecords(successfullIdsSet);
      Database.executebatch(batchable, 200);
  }
}