//Created by Me, Oct '21
//Test Class: batchMarketingJourneys_Test
//batchMarketingJourneys batchable = new batchMarketingJourneys();
//Database.executebatch(batchable, n);  
//Modified on december '21 by me, Adding Vitrina_Oportunidad__c and Propietario_Oportunidad__c to Marketing Journey Record
public class batchMarketingJourneys implements Database.Batchable<sObject>{
 	public Iterable<Sobject> start(Database.BatchableContext bc) {
        //Seleccionar todas las oportunidades que tuvieron cambio de stagename entre ayer y hoy
		list<Opportunity> lstOpps = [select Id, Name,StageName, AccountId,(select Id, Field, OldValue, NewValue from Histories order by createddate desc limit 1)
                                     from Opportunity
                                     where RecordType.Name like '%auto%' and StageName in:mapGruposEtapas.keySet() and Id in (select OpportunityId from OpportunityFieldHistory where Field='StageName' and CreatedDate>=Yesterday)
                                     order by Probability desc];
        
        set<Id> setAccountIds = new set<Id>();
        for (Opportunity op: lstOpps){
            if (!setAccountIds.contains(op.AccountId)) setAccountIds.add(op.AccountId);  
        }
 
       return [select Id from Account where Id in:setAccountIds];
    }
    
    public void execute(Database.BatchableContext bc, List<Account> records){
        //upsert records;
        set<Id> setAccountIds = new set<Id>();
        for (Account a: records) setAccountIds.add(a.Id);
        
        map<Id, list<Opportunity>> mapOppsByAccount = new map<Id, list<Opportunity>>(); //Oportunidades por cuenta con el grupo de cierre más próximo
        map<Id, set<Id>> mapOppIdsByAccount = new map<Id, set<Id>>(); //Todos los Ids de todas las Oportunidades por cuenta
        //set<Id> setOppMayorGrupoIds = new set<Id>();
        for (Opportunity op: [select Vitrina__c,OwnerId,Id, Name,StageName, AccountId from Opportunity where RecordType.Name like '%auto%' and StageName in:mapGruposEtapas.keySet() and AccountId in:setAccountIds order by AccountId, Probability desc]){
            if (!mapOppIdsByAccount.containsKey(op.AccountId)) mapOppIdsByAccount.put(op.AccountId, new set<Id>{op.Id});
            else  mapOppIdsByAccount.get(op.AccountId).add(op.Id);
            
            if (!mapOppsByAccount.containsKey(op.AccountId)) mapOppsByAccount.put(op.AccountId, new list<Opportunity>{op});
            else {
                //Aquí se halan las oportunidades del mismo grupo de la oportunidad de mayor probabilidad, si la oportunidades subsiguientes en probabilidad no pertenecen al mismo grupo que la primera en la misma cuenta entonces no se considera
                if (!cambiaGrupoEtapa(mapOppsByAccount.get(op.AccountId)[0].StageName , op.StageName)) mapOppsByAccount.get(op.AccountId).add(op);
            }
        }
        
        //Marketing Journeys de las cuentas con oportunidades que cambiaron de etapa
        map<Id,Marketing_Journeys__c> mapMarkJourneys = new map<Id,Marketing_Journeys__c>();
        for (Marketing_Journeys__c mj: [select Id,Cuenta__c,Oportunidad__c,Activar_Journey__c,Etapa__c from Marketing_Journeys__c where Cuenta__c in:setAccountIds]) {
            mapMarkJourneys.put(mj.Oportunidad__c, mj);
        }
        
        list<Marketing_Journeys__c> lstNewMJourneys = new list<Marketing_Journeys__c>(); //Marketing Journeys a insertar
        list<Marketing_Journeys__c> lstDisableMJourneys = new list<Marketing_Journeys__c>(); //Marketing Journeys a Inactivar
        list<Marketing_Journeys__c> lstUpdateJourneys = new list<Marketing_Journeys__c>(); //Marketing Journeys a Inactivar
        
        //Ver si existe una de las oportunidades de mayor grupo en la tabla custom
        for (Id idCuenta:  mapOppsByAccount.keySet()) {
            Marketing_Journeys__c mj;
            for (Opportunity op: mapOppsByAccount.get(idCuenta)){
                if (mapMarkJourneys.containsKey(op.Id)){
                    mj = mapMarkJourneys.get(op.Id);
                    //1. Si la oportunidad de mayor probabilidad existe en la tabla custom en un grupo diferente, actualizar  el campo "Stage" con el estado que tenga esta oppty y colocar el campo  "Activar Journey"
                    if (cambiaGrupoEtapa(mj.Etapa__c, op.StageName)){
                        mj.Etapa__c = op.StageName;
                        mj.Activar_Journey__c = true;
                        mj.Vitrina_Oportunidad__c = op.Vitrina__c;
                        mj.Propietario_Oportunidad__c= op.OwnerId;// Vitrina__c,OwnerId
                        lstUpdateJourneys.add(mj);
                    }else{} //2. Si esta oppty ya existe en la tabla custom con un estado diferente pero perteneciente al mismo grupo no se modifica nada en el registro.
                    break;
                }
            }
            
            //3. Si no existe en la tabla custom crear un registro con esta (el campo "Activar Journey" en true) y buscar si existía algún registro de oppty con el campo "Activar Journey" en true para esa cuenta y colocarlo en false.
            if (mj==null){
                Opportunity op = mapOppsByAccount.get(idCuenta)[0];
                Marketing_Journeys__c nmj = new Marketing_Journeys__c(Oportunidad__c=op.Id, Cuenta__c=op.AccountId, Activar_Journey__c=true, Etapa__c=op.StageName,Vitrina_Oportunidad__c=op.Vitrina__c,Propietario_Oportunidad__c=op.OwnerId);
                lstNewMJourneys.add(nmj);
                
                for (Id idOpp: mapOppIdsByAccount.get(idCuenta)){
                    Marketing_Journeys__c mjN = mapMarkJourneys.get(idOpp);
                    if (mjN!=null && mjN.Activar_Journey__c) {
                        mjN.Activar_Journey__c = false;
                        lstDisableMJourneys.add(mjN);
                    }
                }
            }
        }
        
       
        system.debug(lstNewMJourneys);
        system.debug(lstDisableMJourneys);
        system.debug(lstUpdateJourneys);
        
        if (lstNewMJourneys.size()>0) insert lstNewMJourneys;
        if (lstDisableMJourneys.size()>0) update lstDisableMJourneys;
        if (lstUpdateJourneys.size()>0) update lstUpdateJourneys;
    }
    
    public void finish(Database.BatchableContext bc){
        // execute any post-processing operations
    }
    
    private static map<String, Integer> mapGruposEtapas = new map<String, Integer>{'P0'=>1, 'P1'=>1,'P2'=>2,'P3'=>2,'PSI'=>3,'PC'=>4,'PSP'=>5};
    private static boolean cambiaGrupoEtapa(String oldStage, String newStage){
        //String grupos= 'P0+P1, P2+P3, PSI, PC, PSP';
       
        if (mapGruposEtapas.containsKey(oldStage) && mapGruposEtapas.containsKey(newStage)) return mapGruposEtapas.get(oldStage)==mapGruposEtapas.get(newStage) ? false : true;
        else return false;
    }
}