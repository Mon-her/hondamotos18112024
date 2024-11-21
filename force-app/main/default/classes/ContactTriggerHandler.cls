public class ContactTriggerHandler extends TriggerHandler{
    //Listas de Contact
    private list<Contact> newContactList;
    
    //Mapa de Contact de tipo id, Contact
    private Map<Id, Contact> newContactMap;
    private Map<Id, Contact> oldContactMap;
    
    public ContactTriggerHandler() {
        //Cargamos la lista de Contact con lo que viene en el contexto de trigger.new
        newContactList = (list<Contact>) Trigger.New;
        
        //Cargamos el mapa de Contact con lo que viene en el contexto de trigger.newmap
        newContactMap = (Map<Id, Contact>) Trigger.NewMap;
        
        //Cargamos el mapa de Contact con lo que viene en el contexto de trigger.oldmap
        oldContactMap = (Map<Id, Contact>) Trigger.OldMap;
    }
    
    public override void beforeUpdate() {
    	System.debug('ContactTriggerHandler.beforeUpdate()');
    
        set<Id> setOwnersAndRunning = new set<Id>();
      	map<Id,User> mapOwnersAndRunning = new map<Id,User>();
        setOwnersAndRunning.add(UserInfo.getUserId());
        
        set<Id> contactAccountIds = new set<Id>();
        for (Contact c: newContactList){
        	contactAccountIds.add(c.AccountId);
            setOwnersAndRunning.add(c.OwnerId);//fill owners set
        }
        
        for (User u: [select Id, Profile.Name, ManagerId,IsActive from User where Id in:setOwnersAndRunning]){
        	mapOwnersAndRunning.put(u.Id, u);
      	}
        
        User runningUser = mapOwnersAndRunning.get(UserInfo.getUserId());//[select Id, ManagerId,ProfileId, Profile.Name from User where Id=:UserInfo.getUserId()];
        
        //cantidad de Oportunidades del running user por cuenta, si es de renting el user se toman en cuenta para darle permiso de actualizar la cuenta
        List<AggregateResult> AggregateResultList = new List<AggregateResult>(); 
        map<Id,integer> mapOppsByAccount = new map<Id,integer>();
        if (runningUser.Profile.Name.toUpperCase()=='ASESORES AUTOS RENTING') AggregateResultList = [select AccountId, count(Id) cantidad from opportunity where OwnerId=:runningUser.Id and AccountId in:contactAccountIds group by AccountId];
        for (AggregateResult ar: AggregateResultList){ mapOppsByAccount.put(String.valueOf(ar.get('AccountId')), Integer.valueOf(ar.get('cantidad'))); }
        
        for (Contact c: newContactList){
            //Si el usuario es de renting autos y no tiene oportunidades relacionada a la cuenta del contacto, entonces no puede modificar el contacto
            if (c.OwnerId!=runningUser.Id && runningUser.Profile.Name.toUpperCase() == 'ASESORES AUTOS RENTING' && (mapOppsByAccount.get(c.AccountId) ==null || mapOppsByAccount.get(c.AccountId) ==0 ) ) c.addError('Usted no es usuario de Asesores Autos Renting con Oportunidad relacionada a la cuenta de este contacto!');    
            //Si el usuario es de Auto yel contacto pertenece a uno de motos entonces set el running user como propietario del contacto
		    if (mapOwnersAndRunning.get(c.OwnerId).Profile.Name.toUpperCase().contains('MOTO') && runningUser.Profile.Name.toUpperCase().contains('AUTO') )    c.OwnerId = runningUser.Id; 
        }
     
    System.debug('ContactTriggerHandler.beforeUpdate() Saliendo');
  }
}