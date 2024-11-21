public class ChangeAccountOwner {
    
    @AuraEnabled
    //@future
    public static void changeOwner(Id accountId, Id newOwner){
        try {
            //TODO: Pass de variable of the old owner of the account to all the batches.
            set<Id> accIds = new set<Id>();
            accIds.add(accountId);
            
            User newOwnerUser = [select Id, Profile.Name from user where  ID=:newOwner];
            
            
            Account ac = [select OwnerId,Owner.Profile.Name from Account where Id=:accountId];
            accountOwnerChangesData datoCuenta = new accountOwnerChangesData();
            datoCuenta.accountId = accountId;
            datoCuenta.newOwnerId = newOwner;
            datoCuenta.oldOwnerId = ac.OwnerId;
            datoCuenta.oldOwnerProfileName = ac.Owner.Profile.Name;
            datoCuenta.newOwnerProfileName = newOwnerUser.Profile.Name;
            
            UpdateAccountOwnerBatch batchable = new UpdateAccountOwnerBatch(new list<accountOwnerChangesData>{datoCuenta});//UpdateAccountOwnerBatch batchable = new UpdateAccountOwnerBatch(accIds, newOwner);
            Database.executebatch(batchable, 1);
            
            list<tasksOwnerChangesData> lstTasksToProcess = new list<tasksOwnerChangesData>();
            
            tasksOwnerChangesData datoTaskAccount = new tasksOwnerChangesData();
            datoTaskAccount.whatId = accountId;
            datoTaskAccount.newOwnerId = newOwner;
            datoTaskAccount.oldOwnerId = ac.OwnerId;
            datoTaskAccount.oldOwnerProfileName = ac.Owner.Profile.Name;
            datoTaskAccount.newOwnerProfileName = newOwnerUser.Profile.Name;
            lstTasksToProcess.add(datoTaskAccount);
            
            List<Opportunity> lstOpptys = New List<Opportunity>();
            
            //Account a = [Select Id, OwnerId, Owner.Profile.Name from Account where Id =: accountId];
            Set<String> setEtapas = New Set<String>();
            if (!ac.Owner.Profile.Name.toUpperCase().contains('MOTO')){
                setEtapas = new Set<String>{'P0', 'P1', 'P2', 'P3', 'P4'};
                lstOpptys = [Select Id, OwnerId, Owner.Profile.Name from Opportunity where StageName IN: setEtapas AND AccountId =: ac.Id  AND OwnerId =: ac.OwnerId AND recordType.DeveloperName = 'Oportunidad_Autos' ];
		    } else {
                setEtapas = new Set<String>{'-P0', '-P1', '-P2', '-P3'};
                lstOpptys = [Select Id, OwnerId, Owner.Profile.Name from Opportunity where StageName IN: setEtapas AND AccountId =: ac.Id AND OwnerId =: ac.OwnerId AND recordType.DeveloperName = 'Motos_Opportunity_Layout'];   
            }
            
            
            
            for(Opportunity opp : lstOpptys) {
                tasksOwnerChangesData datoTask = new tasksOwnerChangesData();
                datoTask.whatId = opp.Id;
                datoTask.newOwnerId = newOwner;
                datoTask.oldOwnerId = opp.OwnerId;
                datoTask.oldOwnerProfileName = opp.Owner.Profile.Name;
                datoTask.newOwnerProfileName = newOwnerUser.Profile.Name;
                lstTasksToProcess.add(datoTask);
            }
            
            UpdateTaskOwnerBatch batchableTask = new UpdateTaskOwnerBatch(lstTasksToProcess, new list<accountOwnerChangesData>{datoCuenta});//UpdateTaskOwnerBatch batchableTask = new UpdateTaskOwnerBatch(accIds, newOwner, setWhatIds);
      		Database.executebatch(batchableTask, 1);
                        
            ReasignacionMasiva__c obj = ReasignacionMasiva__c.getValues(UserINfo.getUserId());
            system.debug(obj);  
            if (obj==null) {
                obj = new ReasignacionMasiva__c(Name=UserINfo.getUserName(), Id_Usuario__c=UserInfo.getUserId(), SetupOwnerId = UserINfo.getUserId());
                insert obj;
                system.debug(obj);    
            }

        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
        //return 'Se ha actualizado el dueño de la Cuenta y sus registros relacionados con exito!';
    }
    
    public class accountOwnerChangesData{
        @AuraEnabled public  string accountId  { get; set;}
        @AuraEnabled public  string newOwnerId { get; set;}
        @AuraEnabled public  string newOwnerProfileName { get; set;}
        @AuraEnabled public  string oldOwnerId { get; set;}
        @AuraEnabled public  string oldOwnerProfileName { get; set;}
    }
    
    public class tasksOwnerChangesData{
        @AuraEnabled public  string whatId  { get; set;}
        @AuraEnabled public  string newOwnerId { get; set;}
        @AuraEnabled public  string newOwnerProfileName { get; set;}
        @AuraEnabled public  string oldOwnerId { get; set;}
        @AuraEnabled public  string oldOwnerProfileName { get; set;}
    }
}