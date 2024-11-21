//Made by me, JPPD 20201201
public class QuoteTriggerHandler extends TriggerHandler{
 	//Listas de Quote
    private list<Quote> newQuoteList;

    //Mapa de Quote de tipo id, Quote
    private Map<Id, Quote> newQuoteMap;
    private Map<Id, Quote> oldQuoteMap;

    public QuoteTriggerHandler() {

        //Cargamos la lista de Quote con lo que viene en el contexto de trigger.new
        newQuoteList = (list<Quote>) Trigger.New;

        //Cargamos el mapa de Quote con lo que viene en el contexto de trigger.newmap
        newQuoteMap = (Map<Id, Quote>) Trigger.NewMap;

        //Cargamos el mapa de Quote con lo que viene en el contexto de trigger.oldmap
        oldQuoteMap = (Map<Id, Quote>) Trigger.OldMap;

        //Precargamos la lista de tipos de registro
        //Util.getRecordTypes();

    }
    
    public override void beforeInsert() {
        System.debug('Quote: Entrando en beforeInsert... de QuoteTriggerHandler.');
        
        set<Id> setConcesionarios = new set<Id>();
        map<Id,String> mapConcesionarios= new map<Id,String>();
        for (Quote q: newQuoteList){
            setConcesionarios.add(q.Concesionario__c);
        }
        
        for (Miembro_de_Concesionario__c mc: [Select Id,Concesionario__c,Concesionario__r.Name from Miembro_de_Concesionario__c where Concesionario__c in:setConcesionarios and Nombre_de_asesor__c=:UserInfo.getUserId()]){
        	mapConcesionarios.put(mc.Concesionario__c, mc.Concesionario__r.Name);
        }
		//para cada Quote...
        //if (UserInfo.getName().indexOf('Integraciones') == -1) {
        Profile perfil = [select id,name from Profile where id=:UserInfo.getProfileId()];
		if (UserInfo.getName().indexOf('Integraciones') == -1 && perfil.Name.toUpperCase()!='ADMINISTRADOR DEL SISTEMA' && perfil.Name.toUpperCase()!='SYSTEM ADMINISTRATOR') {
            for (Quote q: newQuoteList){
                System.debug('Quote: Para la Quote '+q.Id);
                if (q.concesionario__c != null && !mapConcesionarios.containsKey(q.concesionario__c)){ q.addError('Usted no es un miembro del Concesionario Seleccionado en la Cotización, Póngase en contacto con su administrador de salesforce.');             }
            }
        }
    }        

    public override void beforeUpdate() {
        System.debug('Quote: Entrando en beforeUpdate... de QuoteTriggerHandler.');
        
        set<Id> setConcesionarios = new set<Id>();
        map<Id,String> mapConcesionarios= new map<Id,String>();
        for (Quote q: newQuoteList){
            setConcesionarios.add(q.Concesionario__c);
        }
        
        for (Miembro_de_Concesionario__c mc: [Select Id,Concesionario__c,Concesionario__r.Name from Miembro_de_Concesionario__c where Concesionario__c in:setConcesionarios and Nombre_de_asesor__c=:UserInfo.getUserId()]){
        	mapConcesionarios.put(mc.Concesionario__c, mc.Concesionario__r.Name);
        }
		//para cada Quote...
		Profile perfil = [select id,name from Profile where id=:UserInfo.getProfileId()];
		if (UserInfo.getName().indexOf('Integraciones') == -1 && perfil.Name.toUpperCase()!='ADMINISTRADOR DEL SISTEMA' && perfil.Name.toUpperCase()!='SYSTEM ADMINISTRATOR') {
            for (Quote q: newQuoteList){
                System.debug('Quote: Para la Quote '+q.Id);
                if (q.concesionario__c != null && !mapConcesionarios.containsKey(q.concesionario__c)){  q.addError('Usted no es un miembro del Concesionario Seleccionado en la Cotización, Póngase en contacto con su administrador de salesforce.');            }
            }
        }
    }
}