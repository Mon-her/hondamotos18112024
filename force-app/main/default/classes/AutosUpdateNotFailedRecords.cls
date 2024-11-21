/**
 * Fanalca
 * @author           Juan Ansaldi
 * Description:      Batch class that updates not failed AutosCuentaSegmentacionBatch records.
 *
 * Changes (Version)
 * -------------------------------------
 *           No.     Date            Author                  Description
 *           -----   ----------      --------------------    ---------------
 * @version  1.0     07/31/2021      Juan Ansaldi            Class definition.
 *********************************************************************************************************/
global with sharing class AutosUpdateNotFailedRecords implements Database.Batchable<sObject>, Database.Stateful {
  global Set<Id> successIds = New Set<Id>();
  global AutosUpdateNotFailedRecords(Set<Id> successfullIdsSet) {
      successIds = successfullIdsSet;
  }
    
  public Database.QueryLocator start(Database.BatchableContext bc) {
    String limitString = '';
    if (Test.isRunningTest()) {
      limitString = 'LIMIT 20';
    }
    String query = '';
    String hoy = String.valueOf(Date.today());
    String noexiste = '123456789123456789';
    if(successIds != null ){
       	query = 'SELECT Id, FechaAutosPU__c, Accord_Civic__c, Segmentacion2__c, Fecha_Fin_Garantia__c from Account where Fecha_Fin_Garantia__c != null AND Id IN: successIds AND Fecha_Fin_Garantia__c >='+hoy+limitString;	
    	return Database.getQueryLocator(query);
    } else {
        query = 'Select Id from Account where Id =: noexiste';
        return Database.getQueryLocator(query);
    }
    
  }
    
  public void execute(Database.BatchableContext BC, List<Account> accounts) {
      //Se ejecuta todos los dias a las 11:00 PM
      List<Account> lstUpdate = new List<Account>();
      successIds = new Set<Id>();
      for (Account acc : accounts) {
      Account account = New Account();
          if(acc.Segmentacion2__c == 'Prospecto') {
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
          }else{
              for(Database.Error err : sr.getErrors()) {
                  System.debug(err.getStatusCode() + ': ' + err.getMessage());
              }
          }
      }
  }

  public void finish(Database.BatchableContext BC) {
  }
}