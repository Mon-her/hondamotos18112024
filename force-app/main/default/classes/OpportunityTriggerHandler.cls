//Last Updated by Me, December 13th '21. Si el estadoV de la opp está pasando a Inactivo, entonces no validar el miembro del concesionario al actualizarse la opp

public class OpportunityTriggerHandler extends TriggerHandler {
  //Listas de Opportunity
  private list<Opportunity> newOpportunityList;

  //Mapa de Opportunity de tipo id, Opportunity
  private Map<Id, Opportunity> newOpportunityMap;
  private Map<Id, Opportunity> oldOpportunityMap;

  public OpportunityTriggerHandler() {
    //Cargamos la lista de Opportunity con lo que viene en el contexto de trigger.new
    newOpportunityList = (list<Opportunity>) Trigger.New;

    //Cargamos el mapa de Opportunity con lo que viene en el contexto de trigger.newmap
    newOpportunityMap = (Map<Id, Opportunity>) Trigger.NewMap;

    //Cargamos el mapa de Opportunity con lo que viene en el contexto de trigger.oldmap
    oldOpportunityMap = (Map<Id, Opportunity>) Trigger.OldMap;

    //Precargamos la lista de tipos de registro
    //Util.getRecordTypes();
  }

  public override void beforeInsert() {
    System.debug(
      'Opportunity: Entrando en beforeInsert... de OpportunityTriggerHandler.'
    );

    //Boolean hasAtLeastOneAutosOpp = false;

    set<Id> setConcesionarios = new Set<Id>();
    map<Id, String> mapConcesionarios = new Map<Id, String>();
    for (Opportunity op : newOpportunityList) {
      setConcesionarios.add(op.Concesionario__c);

      //if(op.RecordType_Name__c == 'Oportunidad Autos'){ hasAtLeastOneAutosOpp = true; }
    }

    //if(!hasAtLeastOneAutosOpp) { checkAccountOutdatedFields(newOpportunityList); }

    for (Miembro_de_Concesionario__c mc : [
      SELECT Id, Concesionario__c, Concesionario__r.Name
      FROM Miembro_de_Concesionario__c
      WHERE
        Concesionario__c IN :setConcesionarios
        AND Nombre_de_asesor__c = :UserInfo.getUserId()
    ]) {
      mapConcesionarios.put(mc.Concesionario__c, mc.Concesionario__r.Name);
    }
    //para cada Opportunity...
    //if (UserInfo.getName().indexOf('Integraciones') == -1) {
    Profile perfil = [select id,name from Profile where id=:UserInfo.getProfileId()];
      
    if(perfil.Name.toUpperCase().contains('MOTO')){ checkAccountOutdatedFields(newOpportunityList); }
      
    if (UserInfo.getName().indexOf('Integraciones') == -1 && perfil.Name.toUpperCase()!='ADMINISTRADOR DEL SISTEMA' && perfil.Name.toUpperCase()!='SYSTEM ADMINISTRATOR') {    
      // Usuario no es Integraciones
      for (Opportunity op : newOpportunityList) {
        System.debug('Opportunity: Para la Opportunity ' + op.Id);
        if (
          op.concesionario__c != null &&
          !mapConcesionarios.containsKey(op.concesionario__c)
        ) {
          op.addError(
            'Usted no es un miembro del Concesionario Seleccionado en la Oportunidad, Póngase en contacto con su administrador de salesforce.'
          );
        }
      }
    }
      	Opportunity currentOpp = newOpportunityList.get(0);
      //Renting Opps
          //Change Opp name & owner
          if (currentOpp.Tipo_de_Oportunidad__c=='Renting' && newOpportunityList.size()==1){
              User oppOwner = [select Id, Profile.Name from User where Id=:currentOpp.ownerId];
              //if (oppOwner.Profile.Name.touppercase()!='ASESORES AUTOS'){
              if (!oppOwner.Profile.Name.touppercase().contains('RENTING') && perfil.Name.toUpperCase()!='ADMINISTRADOR DEL SISTEMA' && perfil.Name.toUpperCase()!='SYSTEM ADMINISTRATOR'){
                  //set name
                  //Opportunity thisOpp = [select Id, Account.Name from Opportunity where Id=:currentOpp.Id];
                  //currentOpp.Name = 'Venta para vehículo por Renting ' + currentOpp.Account.Name;    
                  list<Miembro_de_Concesionario__c> lstMiembros = New List<Miembro_de_Concesionario__c>();
                  //set owner
                  
                  list<Miembro_de_Concesionario__c> miembro = [Select Id, Concesionario__c  From Miembro_de_Concesionario__c where Nombre_de_asesor__c =: UserInfo.getUserId()];
                  if (miembro.size()== 0){ currentOpp.addError('Usted no se encuentra matriculado en ningún concesionario!');}
                  if (miembro.size() > 1){ currentOpp.addError('Usted se encuentra matriculado en varios concesionarios!');}
                  if (miembro.size() == 1){
                      lstMiembros = [select Id,Nombre_de_asesor__c from Miembro_de_Concesionario__c where Concesionario__c=: miembro.get(0).Concesionario__c and Asesor_de_renting2__c=true];
                      if (lstMiembros.size()==1){
                          currentOpp.OwnerId = lstMiembros.get(0).Nombre_de_asesor__c;
                      }
                  }
              }
          }
      
      
  }
  public String ErrorMSG;
  public override void beforeUpdate() {
    System.debug(
      'Opportunity: Entrando en beforeUpdate... de OpportunityTriggerHandler.'
    );

    boolean allowUpdate = PreventOpportunityChanges.areOpportunitiesUpdatable(
      newOpportunityList
    );
    if (!allowUpdate) {
      for (Opportunity op : newOpportunityList) {
        op.addError(
          'Error, no es posible actualizar la oportunidad porque una orden en UNOEE ha sido creada.'
        );
      }
    }
      
    //Boolean hasAtLeastOneAutosOpp = false;

      //Si estoy pasando a P4 pero no vengo de P5, en oportunidad usado, busco el inventario usado relacioado al oppty product line item y verifico si ese 
      //inventario usado ya esta en Usado_Separado__c .... Verificar si en una o en varias oppty usadas esta ese ID - Si es asi no debo dejar pasar la oppty. 
      if (newOpportunityList.size()==1){
          Opportunity currentOpp = newOpportunityList.get(0);

          //if(currentOpp.RecordType_Name__c == 'Oportunidad Autos'){ hasAtLeastOneAutosOpp = true; }

          if (currentOpp.Tipo_de_Oportunidad__c == 'Usados' && currentOpp.HasOpportunityLineItem && currentOpp.Usado_Separado__c!=null){
          	List<Opportunity> lstOppty = New List<Opportunity>();
          	OpportunityLineItem Oli = [Select Id, Product2Id, Product2.Inventario_de_Usados__c, OpportunityId, Opportunity.Fecha_de_factura__c, Opportunity.Amount from OpportunityLineItem where OpportunityId =: currentOpp.Id];	
          	lstOppty = [Select Id from Opportunity Where Usado_Separado__c =: Oli.Product2.Inventario_de_Usados__c and Id!=:currentOpp.Id]; //and Id!=:currentOpp.Id was added on July 6th '21
              
            Opportunity old = oldOpportunityMap.get(currentOpp.Id);
            if(currentOpp.StageName == 'P4' && old.StageName != 'P5' && currentOpp.Tipo_de_Oportunidad__c == 'Usados'){
            	if(lstOppty.size() > 0) {
                	currentOpp.addError('Error, no es posible cambiar el estado a P4 porque el auto usado se encuentra separado para otra Oportunidad.');
                }
            }  
          }
          //aca
          
          List<Account> acc = [Select Id, RecordType.DeveloperName, (Select Id from Contacts) from Account where Id =: currentOpp.AccountId Limit 1];
          if(acc.size()>0){
              if(acc[0].RecordType.DeveloperName == 'AM_CUE_Cuenta_empresarial') {
                  
                  if(!currentOpp.Registro_Migrado__c && currentOpp.RecordType_Name__c == 'Oportunidad Autos' && acc[0].Contacts.size() == 0){
                      currentOpp.addError('Error, debe tener creado un contacto relacionado a la Cuenta Juridica antes de hacer una oportunidad');
                  }
                  
                  if (currentOpp.StageName == 'PU' && currentOpp.Contacto__c != null && currentOpp.Registro_Migrado__c == false){
                      List<Contact> con = [Select Id, AM_Cargo__c,AM_Tipo_de_documento_Contacto__c, AM_Numero_de_documento_contacto__c, Birthdate, Estado_del_Contacto__c, Nivel_Socioeconomico__c, 
                                           AM_Estado_civil__c,AM_Deporte_que_prefiere__c, Grado_de_Escolaridad__c, Tiene_hijos__c, Que_actividad_realiza_en_tiempo_libre__c 
                                           From Contact Where Id =: currentOpp.Contacto__c Limit 1];
                      
                      if(returnError(con[0].AM_Cargo__c) || returnError(con[0].AM_Tipo_de_documento_Contacto__c) || returnError(con[0].AM_Numero_de_documento_contacto__c) ||
                         returnError(con[0].AM_Deporte_que_prefiere__c) || returnError(con[0].AM_Estado_civil__c) || returnError(con[0].Nivel_Socioeconomico__c) || returnError(con[0].Estado_del_Contacto__c) ||
                         returnError(con[0].Grado_de_Escolaridad__c) || returnError(con[0].Tiene_hijos__c) || returnError(con[0].Que_actividad_realiza_en_tiempo_libre__c) || 
                         returnError(currentOpp.CampaignId) || returnError(currentOpp.Razon_de_no_compra__c) || returnError(currentOpp.Bodega_Usados__c)) {
                             currentOpp.AddError(ErrorMSG);
                         }
                      if(con[0].BirthDate == null){
                          currentOpp.AddError('Error, debe tener digilenciado el campo Fecha de Nacimiento en el contacto relacionado antes de pasar la Oportunidad a PU.');
                      }
                      
                  }
              }
          }
      }

    //if(!hasAtLeastOneAutosOpp){ checkAccountOutdatedFields(newOpportunityList); }

    set<Id> setConcesionarios = new Set<Id>();
    map<Id, String> mapConcesionarios = new Map<Id, String>();
    for (Opportunity op : newOpportunityList) {
      setConcesionarios.add(op.Concesionario__c);
    }

    for (Miembro_de_Concesionario__c mc : [
      SELECT Id, Concesionario__c, Concesionario__r.Name
      FROM Miembro_de_Concesionario__c
      WHERE
        Concesionario__c IN :setConcesionarios
        AND Nombre_de_asesor__c = :UserInfo.getUserId()
    ]) {
      mapConcesionarios.put(mc.Concesionario__c, mc.Concesionario__r.Name);
    }

    String profileName = [
      SELECT Id, Name
      FROM Profile
      WHERE Id = :userInfo.getProfileId()
    ]
    .Name;
      
    if(profileName.toUpperCase().contains('MOTO')){ checkAccountOutdatedFields(newOpportunityList); }
    
    //para cada Opportunity...
    if (
      profileName != 'Contact Center Motos' &&
      UserInfo.getName().indexOf('Integraciones') == -1 &&
      profileName.toUpperCase()!='ADMINISTRADOR DEL SISTEMA' && profileName.toUpperCase()!='SYSTEM ADMINISTRATOR'  
    ) {
      // Usuario no es Integraciones
      for (Opportunity op : newOpportunityList) {
        System.debug('Opportunity: Para la Opportunity ' + op.Id);
        if (
          op.concesionario__c != null &&
          !mapConcesionarios.containsKey(op.concesionario__c)
        ) {
           if (op.Estado_V__c =='Inactivo' && oldOpportunityMap.get(op.Id).Estado_V__c !='Inactivo') system.debug('Cambiando EstadoV a Inactivo'); //Si no está cambiando el estado a inactivo, ya que eso lo hace inventario de usados trigger
           else op.addError( 'Usted no es un miembro del Concesionario Seleccionado en la Oportunidad, Póngase en contacto con su administrador de salesforce.' );
        }
      }
    }
   
  }
    
    private Boolean returnError(String campo){
        if (campo == null && campo == ''){
            String label = Schema.getGlobalDescribe().get('Contact').getDescribe().fields.getMap().get(campo).getDescribe().getLabel();
        	ErrorMSG = 'Error, debe tener digilenciado el campo ' + label + ' en el contacto relacionado antes de pasar la Oportunidad a PU.';
            return True;
        }
        return False;
    }
    
    
  public override void afterInsert() {
    system.debug('Opportunity: Entrando en After Insert');
    Date hoy = Test.isRunningTest()
      ? OpportunityTriggerTest.hoy
      : system.today();
    Datetime ahora = Test.isRunningTest()
      ? OpportunityTriggerTest.ahora
      : system.now();

    //esta variable para capturar el Id de los Tipo de registro
    List<Id> IdsRecordType = new List<Id>();
    //este mapa es para saber cual es el Tipo de registro relacionado a cada Opportunity
    Map<String, RecordType> MapRecordType; //=new Map<String , RecordType>();
    //esta variable es para saber si es que se debe consultar el horario de Motos
    Boolean HorarioMoto = false;
    //este mapa es para saber el Horario de Oficina relacionado al Tipo de registro de Motos
    //Map<String , BusinessHours>MapBusinessHour;
    BusinessHours HorarioMotos;
    //Para cuando es un Opportunity de tipo de registro de Motos , se va evaluar el momento en que se asigna el Opportunity, se calcula el due date del evento con base a la cantidad de horas maximas de atencion "4" y el horario de oficina de MOTOS
    for (Opportunity O : newOpportunityList) {
      //capturar el tipo de registro
      IdsRecordType.add(O.RecordTypeId);
    }

    //consultar los tipos de registro relacionados a los Opportunitys
    if (IdsRecordType.size() > 0) {
      //cargar el mapa con los tipos de registros de los Opportunity que sean de motos
      MapRecordType = new Map<String, RecordType>(
        [
          SELECT Id, Name, DeveloperName
          FROM RecordType
          WHERE
            Id IN :IdsRecordType
            AND DeveloperName = :'Motos_Opportunity_Layout'
        ]
      );
      //si la consulta obtuvo resultados , osea , si alguno de los Opportunity es del Tipo de registro de Motos
      if (MapRecordType.size() > 0) {
        //se debe marcar el flag que determina que se debe consultar el horario de Motos
        HorarioMoto = true;
      }
    }

    //se consulta el horario de MOTOS?
    if (HorarioMoto) {
      List<BusinessHours> Horarios = [
        SELECT
          Name,
          /*BusinessHoursId,*/ IsActive,
          IsDefault,
          TimeZoneSidKey,
          MondayStartTime,
          MondayEndTime,
          TuesdayStartTime,
          TuesdayEndTime,
          WednesdayStartTime,
          WednesdayEndTime,
          ThursdayStartTime,
          ThursdayEndTime,
          FridayStartTime,
          FridayEndTime,
          SaturdayStartTime,
          SaturdayEndTime,
          SundayStartTime,
          SundayEndTime
        FROM BusinessHours
        WHERE Name = :'Motos' AND IsActive = :true
      ];
      if (Horarios.size() > 0) {
        HorarioMotos = Horarios[0];
      }
    }

    //esta lista es para capturar los registros de evento para cada Opportunity
    List<TAsk> Eventos = new List<Task>(); //Changed jan 18, 21 List<Event> Eventos = new List<Event>();
    //para cada Opportunity nuevo
    for (Opportunity O : newOpportunityList) {
      //antes de entrar aca , se podria evaluar algun flag que determine si es que se asignó a un usuario , en este momento se asume que ya se asignó
      //Por el tipo de registro veamos si es de Motos
      if (MapRecordType.ContainsKey(O.RecordTypeId) && HorarioMotos != null) {
        //si es de motos , entonces se captura el horario de oficina de motos
        //BusinessHours HorarioMotos = MapBusinessHour.get('Motos');
        system.debug('El horario es: ' + HorarioMotos);
        //obtener el numero del dia de la semana a partir de la fecha de hoy
        Integer DiaDeSemana = getNumeroDiaSemana(hoy); //getNumeroDiaSemana(system.today());
        //ahora desde el horario de oficina capturar la fecha de Inicio y Fin en dependencia del dia
        //esta variable es para capturar la hora de inicio en dependencia del dia
        Time HorarioDeInicio;
        /*
        HorarioDeInicio = (DiaDeSemana == 1)
          ? HorarioMotos.MondayStartTime
          : (DiaDeSemana == 2)
              ? HorarioMotos.TuesdayStartTime
              : (DiaDeSemana == 3)
                  ? HorarioMotos.WednesdayStartTime
                  : (DiaDeSemana == 4)
                      ? HorarioMotos.ThursdayStartTime
                      : (DiaDeSemana == 5)
                          ? HorarioMotos.FridayStartTime
                          : (DiaDeSemana == 6)
                              ? HorarioMotos.SaturdayStartTime
                              : (DiaDeSemana == 7)
                                  ? HorarioMotos.SundayStartTime
                                  : null;
        */
        switch on DiaDeSemana {
          when 1 {
            HorarioDeInicio = HorarioMotos.MondayStartTime;
          }
          when 2 {
            HorarioDeInicio = HorarioMotos.TuesdayStartTime;
          }
          when 3 {
            HorarioDeInicio = HorarioMotos.WednesdayStartTime;
          }
          when 4 {
            HorarioDeInicio = HorarioMotos.ThursdayStartTime;
          }
          when 5 {
            HorarioDeInicio = HorarioMotos.FridayStartTime;
          }
          when 6 {
            HorarioDeInicio = HorarioMotos.SaturdayStartTime;
          }
          when 7 {
            HorarioDeInicio = HorarioMotos.SundayStartTime;
          }
          when else {
            HorarioDeInicio = null;
          }
        }
        Integer HoraInicio = HorarioDeInicio != null
          ? HorarioDeInicio.hour()
          : 0; //Integer HoraInicio = HorarioDeInicio.hour();
        system.debug('Opportunity: la Hora de inicio es: ' + HoraInicio);
        //para capturar hora de fin en dependencia del dia
        Time HorarioDeFin;
        /*
          HorarioDeFin = (DiaDeSemana == 1)
          ? HorarioMotos.MondayEndTime
          : (DiaDeSemana == 2)
              ? HorarioMotos.TuesdayEndTime
              : (DiaDeSemana == 3)
                  ? HorarioMotos.WednesdayEndTime
                  : (DiaDeSemana == 4)
                      ? HorarioMotos.ThursdayEndTime
                      : (DiaDeSemana == 5)
                          ? HorarioMotos.FridayEndTime
                          : (DiaDeSemana == 6)
                              ? HorarioMotos.SaturdayEndTime
                              : (DiaDeSemana == 7)
                                  ? HorarioMotos.SundayEndTime
                                  : null;
          */
        switch on DiaDeSemana {
          when 1 {
            HorarioDeFin = HorarioMotos.MondayEndTime;
          }
          when 2 {
            HorarioDeFin = HorarioMotos.TuesdayEndTime;
          }
          when 3 {
            HorarioDeFin = HorarioMotos.WednesdayEndTime;
          }
          when 4 {
            HorarioDeFin = HorarioMotos.ThursdayEndTime;
          }
          when 5 {
            HorarioDeFin = HorarioMotos.FridayEndTime;
          }
          when 6 {
            HorarioDeFin = HorarioMotos.SaturdayEndTime;
          }
          when 7 {
            HorarioDeFin = HorarioMotos.SundayEndTime;
          }
          when else {
            HorarioDeFin = null;
          }
        }
        Integer HoraFin = HorarioDeFin != null ? HorarioDeFin.hour() : 0; //Integer HoraFin = HorarioDeFin.hour();
        system.debug('Opportunity: la Hora de fin es ' + HoraFin);

        //capturar horario de los sabados , para incremento en dias posteriormente
        Integer HoraInicioSabado = HorarioMotos.SaturdayStartTime.hour();
        Integer HoraFinSabado = HorarioMotos.SaturdayEndTime.hour();
        Integer HorasHabilesSabado = HoraFinSabado - HoraInicioSabado;
        system.debug(
          'Opportunity: El horario de sabado es de ' +
          HoraInicioSabado +
          ' a ' +
          HoraFinSabado +
          ' para un total de ' +
          HorasHabilesSabado +
          ' horas habiles'
        );
        //capturo la hora actual,si pasa de los 30 minutos se redondea al numero siguiente
        Integer HoraActual = ahora.hour(); //system.now().hour();
        //esta variable es para identificar la cantidad de horas habiles en el dia , si es Lunes a viernes se resta hora de almuerzo
        Integer HorasHabiles;
        if (DiaDeSemana < 6) {
          //se le resta la hora de almuerzo
          HorasHabiles = HoraFin - HoraInicio - 1;
          //quedan en 9 horas habiles
        } else {
          //si es sabado, no se le resta la hora de almuerzo
          HorasHabiles = HoraFin - HoraInicio;
          //queda en 5 horas habiles
        }
        system.debug('Las horas habiles del dia de hoy son ' + HorasHabiles);
        system.debug('Opportunity: la Hora actual es ' + HoraActual);
        //ahora debo calcular el tiempo del horario laboral a partir de la variable de la cantidad de horas maximas para atender al Opportunity
        Integer HorasRestantesHorario = HoraFin - HoraActual;
        system.debug(
          'Opportunity: Faltan ' +
          HorasRestantesHorario +
          ' para finalizar el horario laboral'
        );
        //ahora capturo desde la etiqueta personalizada , el valor de la cantidad de horas maximas que tiene el usuario para atender al Opportunity.
        Integer HorasParaEvento = Test.isRunningTest()
          ? OpportunityTriggerTest.HorasParaEvento
          : Integer.valueOf(LABEL.HorasParaEvento);
        //validar si la hora actual es menor a la hora de almuerzo
        if (
          HoraActual < Integer.valueOf(LABEL.HoraInicioAlmuerzo) &&
          DiaDeSemana < 6
        ) {
          //Si es menor, se le debe incrementar en 1 el valor de horasParaEvento
          HorasParaEvento = HorasParaEvento + 1;
          system.debug(
            'Aun no ha pasado el Almuerzo, se incrementa en 1 la cantidad de horas para el evento ' +
            HorasParaEvento
          );
        }

        //esta variable es para saber si es que se debe hacer un incremento en dias para crear el evento
        Integer IncrementoEnDias = 0;
        //esta variable es para saber el incremento en horas a la fecha(hora) en la que se debe agendar el evento
        Integer IncrementEnHoras = 0;
        //ahora pregunto si es que las horas restantes del horario son menor que las horas en las que se debe agendar el evento
        if (HorasRestantesHorario < HorasParaEvento) {
          system.debug('Debe haber un incremento en dias');
          //si son menor , entonces quiere decir que el evento NO se puede agendar para el dia de hoy , quiere decir que el evento se debe agendar para el dia siguiente
          //primero se debe saber cuanto será el incremento en dias

          //ahora se debe saber cuanto seria el incremento en horas
          IncrementEnHoras = HorasParaEvento - HorasRestantesHorario;
          system.debug(
            'INICIALMENTE Se incrementarian en ' +
            IncrementoEnDias +
            ' dias y ' +
            IncrementEnHoras +
            ' horas'
          );

          /******************** Este bloque es para hacer el desgloce de la cantidad de dias segun las horas para el evento*******************/
          //Cantidad de dias a correr
          Integer DiasACorrer = 0;
          //Cantidad de horas a dividir en dias habiles
          Integer HorasARestar = IncrementEnHoras;

          //Si la cantidad de HorasHabiles es menor a la cantidad de IncrementEnHoras
          if (HorasHabiles < IncrementEnHoras) {
            system.debug(
              'La cantidad de horas a incrementar excede la cantidad de horas habiles'
            );
            //quiere decir que se deben correr mas dias
            //si mañana es Lunes , correr un dia mas y restar al total de incremento
            for (Integer i = 1; HorasARestar > 0; i++) {
              system.debug(
                'Incremento numero ' +
                i +
                ', Horas a Restar=' +
                HorasARestar
              );
              Date FechaSiguiente = hoy.addDays(i); //system.today().addDays(i);
              //ahora que ya tenemos la fecha , debemos saber que dia de la semana es
              Integer DiaSiguiente = getNumeroDiaSemana(FechaSiguiente);
              system.debug('El dia siguiente es ' + DiaSiguiente);

              if (DiaSiguiente < 6) {
                //las horas a restar son mayor que las horas habiles?
                if (HorasARestar > HorasHabiles) {
                  //si es dia entre Lunes y viernes , incrementar un dia y restar 9 horas
                  DiasACorrer = DiasACorrer + 1;
                  HorasARestar = HorasARestar - HorasHabiles; //se restan 9
                  system.debug(
                    'Es entre Lunes y Viernes , El contador de Dias a correr queda en ' +
                    DiasACorrer +
                    ' y Las horas que restan son ' +
                    HorasARestar
                  );
                } else {
                  //las horas a restar son menor , no se incrementa dia , solo horas
                  IncrementEnHoras = HorasARestar;
                  system.debug(
                    'Las horas a restar son menor que las horas habiles , se incrementa en ' +
                    IncrementEnHoras +
                    ' horas'
                  );
                  HorasARestar = 0;
                }
              } else if (DiaSiguiente == 6) {
                //las horas a restar son mayor que las horas habiles?
                if (HorasARestar > HorasHabilesSabado) {
                  //si es sabado, incrementar un dia pero restar 5 horas
                  DiasACorrer = DiasACorrer + 1;
                  HorasARestar = HorasARestar - HorasHabilesSabado; //se restan 5 horas
                  system.debug(
                    'Es Sabado , El contador de Dias a correr queda en ' +
                    DiasACorrer +
                    ' y Las horas que restan son ' +
                    HorasARestar
                  );
                } else {
                  //las horas a restar son menor , no se incrementa dia , solo horas
                  IncrementEnHoras = HorasARestar;
                  system.debug(
                    'Las horas a restar son menor que las horas habiles , se incrementa en ' +
                    IncrementEnHoras +
                    ' horas'
                  );
                  HorasARestar = 0;
                }
              } else if (DiaSiguiente == 7) {
                system.debug(
                  'El dia siguiente es domingo , se debe hacer un salto.'
                );
              }
            }
            IncrementoEnDias = (DiaDeSemana == 6)
              ? DiasACorrer + 2
              : DiasACorrer + 1;
          } else {
            IncrementoEnDias = (DiaDeSemana == 6) ? 2 : 1; //si el dia es Sabado , entonces se incrementa los dias en 2 , sino , se incrementa solo en 1
          }
          //Se aumenta el incremento en dias segun validacion previa
          system.debug(
            'Se incrementa un total de ' +
            IncrementoEnDias +
            ' dias y ' +
            IncrementEnHoras +
            ' horas'
          );

          /***********************************************************************************************************************************/
        } else {
          //si las horas restantes no son menor a las horas para agendar , el incremento en dias queda en 0,
          //el incremento en horas se le establece el valor de HorasParaEvento
          IncrementEnHoras = HorasParaEvento;
          system.debug('Se incrementan en horas : ' + IncrementEnHoras);
        }

        //en esta variable voy a establecer cuando es la fecha y hora para el evento
        DateTime FechaHoraEvento;
        //esta variable es para establecer la fecha y hora de fin del evento
        DateTime FechaHoraFinEvento;
        Date FechaEvento;
        //si el incremento en dias es 0 , quiere decir que se agenda para hoy mismo
        if (IncrementoEnDias == 0) {
          //solo se incrementa la cantidad de horas segun la etiqueta personalizada
          //FechaHoraFinEvento = FechaHoraEvento.addHours(- 1);
          FechaHoraFinEvento = ahora.addHours(IncrementEnHoras); //system.now().addHours(IncrementEnHoras);
          //FechaHoraEvento = system.now().addHours(IncrementEnHoras);
          //FechaHoraEvento = system.now();//.addHours(IncrementEnHoras);
          FechaHoraEvento = FechaHoraFinEvento.addHours(-1);
          system.debug(
            'No hay incremento en dias , la fecha del evento seria ' +
            FechaHoraEvento
          );
        } else {
          //si ya se determina que haya incremento en dias,
          //primero debemos inicializar una fecha donde se haga el incremento en dias
          FechaEvento = hoy.addDays(IncrementoEnDias); //system.today().addDays(IncrementoEnDias);
          //ahora que ya tenemos la fecha , debemos saber que dia de la semana es mañana
          Integer DiaDeManana = getNumeroDiaSemana(FechaEvento);
          /** 12NOV2020 - Ajuste para salto de dia cuando proximo dia es domingo**/
          if (DiaDeManana == 7) {
            FechaEvento = FechaEvento.addDays(1);
            DiaDeManana = getNumeroDiaSemana(FechaEvento);
            system.debug(
              'El proximo dia caia en domingo , se hizo un salto de un dia y queda en dia:' +
              DiaDeManana +
              ', y la fecha:' +
              FechaEvento
            );
          }
          //una vez que ya sabemos el dia de manana , debemos mandar a traer desde el horario de oficina , la hora de inicio
          Time HorarioDeInicioManana;
          HorarioDeInicioManana = (DiaDeManana == 1)
            ? HorarioMotos.MondayStartTime
            : (DiaDeManana == 2)
                ? HorarioMotos.TuesdayStartTime
                : (DiaDeManana == 3)
                    ? HorarioMotos.WednesdayStartTime
                    : (DiaDeManana == 4)
                        ? HorarioMotos.ThursdayStartTime
                        : (DiaDeManana == 5)
                            ? HorarioMotos.FridayStartTime
                            : (DiaDeManana == 6)
                                ? HorarioMotos.SaturdayStartTime
                                : (DiaDeManana == 7)
                                    ? HorarioMotos.SundayStartTime
                                    : null;
          Integer HoraInicioManana = HorarioDeInicioManana.hour();

          system.debug(
            'Opportunity: la Hora de inicio del proximo dia es: ' +
            HoraInicioManana
          );
          //preguntamos si a la hora de inicio se le debe incrementar
          if (IncrementEnHoras > 0) {
            //a la hora de inicio le incrementamos la cantidad de horas
            HoraInicioManana = (HoraInicioManana + IncrementEnHoras) - 1;

            //HorarioDeInicioManana.addHours(IncrementEnHoras);
            system.debug(
              'La hora de inicio de siguiente dia se incrementa en ' +
              IncrementEnHoras
            );
          }
          Integer HoraFinManana = HoraInicioManana + 1;

          system.debug(
            'La hora de Inicio del Evento queda en ' +
            HoraInicioManana +
            ' y la hora de fin del Evento ' +
            HoraFinManana
          );

          //ahora se inicializa la fecha y hora del evento con el incremento de dias y horas segun corresponda
          //FechaHoraEvento = DateTime.newInstance(FechaEvento.year(), FechaEvento.month(), FechaEvento.day(), HoraInicioManana , HorarioDeInicioManana.minute(), HorarioDeInicioManana.second());
          FechaHoraEvento = DateTime.newInstance(
            FechaEvento.year(),
            FechaEvento.month(),
            FechaEvento.day(),
            HoraInicioManana,
            HorarioDeInicioManana.minute(),
            HorarioDeInicioManana.second()
          );
          system.debug(
            'HAY incremento en dias , la fecha del evento seria ' +
            FechaHoraEvento
          );
          //FechaHoraFinEvento = DateTime.newInstance(FechaEvento.year(), FechaEvento.month(), FechaEvento.day(), HoraFinManana , HorarioDeInicioManana.minute(), HorarioDeInicioManana.second());
          FechaHoraFinEvento = DateTime.newInstance(
            FechaEvento.year(),
            FechaEvento.month(),
            FechaEvento.day(),
            HoraFinManana,
            HorarioDeInicioManana.minute(),
            HorarioDeInicioManana.second()
          );
          system.debug(
            'La hora de fin del evento seria : ' + FechaHoraFinEvento
          );
        }

        //una vez definido la Fecha y hora del evento...
        Task tarea = new Task(); //Event Evento = new Event();
        tarea.OwnerId = O.OwnerId; //Evento.OwnerId = O.OwnerId;
        tarea.Subject = LABEl.AsuntoDeEvento; //Evento.Subject = LABEl.AsuntoDeEvento; //'Call';//
        tarea.Description = LABEL.DescripcionDeEvento; //Evento.Description = LABEL.DescripcionDeEvento;
        //tarea.StartDateTime = FechaHoraEvento;//Evento.StartDateTime = FechaHoraEvento;
        //tarea.EndDateTime = FechaHoraFinEvento;//Evento.EndDateTime = FechaHoraFinEvento;
        //Evento.WhoId = O.Id;
        tarea.WhatId = O.Id; //Evento.WhatId = O.Id;
        tarea.ActivityDate = Date.valueOf(FechaHoraEvento); //Evento.ActivityDate = Date.valueOf(FechaHoraEvento);
        //Not exists ActivityDateTime in Task tarea.ActivityDateTime = FechaHoraEvento;//Evento.ActivityDateTime = FechaHoraEvento;
        tarea.IsReminderSet = true; //Evento.IsReminderSet = true;
        tarea.ReminderDateTime = FechaHoraFinEvento.addHours(-1); //FechaHoraEvento;//Evento.ReminderDateTime = FechaHoraFinEvento.addHours(-1); //FechaHoraEvento;
        Eventos.add(tarea); //Eventos.add(Evento);
      }
    }

    //Hay eventos por insertar?
    if (Eventos.size() > 0) {
      insert Eventos;
      system.debug('Eventos creados:' + Eventos);
    }
  }

  public override void afterUpdate() {
      
      //Envía a Prolibu en el futuro las cotizaciones relacionadas a esta oportunidad si la oportunidad cambió de estado y ahora se encuentra cerrada o Stage = P5
      //Sólo se envía si es una sola opp la que se está actualizando
      if (newOpportunityList.size()==1){
          Opportunity currentOpp = newOpportunityList.get(0);
          Opportunity old = oldOpportunityMap.get(currentOpp.Id);
          //if (currentOpp.IsClosed && (currentOpp.StageName != old.StageName) && currentOpp.SyncedQuoteId!=null && currentOpp.Quote_Synced_Sent_Prolibu__c) ProlibuProposalChangeStatus.sendOppStatusFuture(currentOpp.Id,currentOpp.SyncedQuoteId,currentOpp.IsWon);//ProlibuProposalChangeStatus.sendAllProposalStatusFuture(currentOpp.Id);
          Quote quoteSynced;
          if (currentOpp.SyncedQuoteId!=null)  quoteSynced = [select Id, Creado_Prolibu__c from Quote where ID=:currentOpp.SyncedQuoteId];
          //if ( (currentOpp.IsClosed || currentOpp.StageName=='P5') && currentOpp.StageName != old.StageName && currentOpp.SyncedQuoteId!=null && currentOpp.Quote_Synced_Sent_Prolibu__c) ProlibuProposalChangeStatus.sendOppStatusFuture(currentOpp.Id,currentOpp.SyncedQuoteId, currentOpp.StageName=='P5' ? true : currentOpp.IsWon);//ProlibuProposalChangeStatus.sendAllProposalStatusFuture(currentOpp.Id);
          if ( (currentOpp.IsClosed || currentOpp.StageName=='P5') && currentOpp.StageName != old.StageName && currentOpp.SyncedQuoteId!=null && quoteSynced!=null && quoteSynced.Creado_Prolibu__c) ProlibuProposalChangeStatus.sendOppStatusFuture(currentOpp.Id,currentOpp.SyncedQuoteId, currentOpp.StageName=='P5' ? true : currentOpp.IsWon);//ProlibuProposalChangeStatus.sendAllProposalStatusFuture(currentOpp.Id);
          
          //Renting Opps, Send Notification of changed owner
          if (currentOpp.Tipo_de_Oportunidad__c=='Renting' && old.OwnerId!=currentOpp.OwnerId){
              notifyNewOwnerUser(new Set<String> {currentOpp.OwnerId}, (String) currentOpp.Id, currentOpp.Name);
          }	
      }
      Set<Id> setOpps = New Set<Id>();
      List<Inventario_de_Usados__c> lstInvUsados = New List<Inventario_de_Usados__c>();
      List<Opportunity> lstOpps = [Select Id, Tipo_de_Oportunidad__c from Opportunity where Id in: Trigger.New AND Tipo_de_Oportunidad__c = 'Usados' AND StageName = 'P5'];
      if(lstOpps.size()> 0) {
          List<OpportunityLineItem> lstOli = [Select Id, Product2Id, Product2.Inventario_de_Usados__c, OpportunityId,
                                              Opportunity.Fecha_de_factura__c, Opportunity.Amount from OpportunityLineItem where OpportunityId in: lstOpps];	
          if(lstOli.size()> 0){
              List<Inventario_de_Usados__c> lstInvUpdate = New List<Inventario_de_Usados__c>();
              List<Product2> lstPrdUpdate = New List<Product2>();
              for(OpportunityLineItem oli : lstOli){
                  Product2 p2 = New Product2();
                  p2.Id = oli.Product2Id;
                  p2.IsActive = false;
                  lstPrdUpdate.add(p2);
                  
                  Inventario_de_Usados__c u = New Inventario_de_Usados__c();
                  if(newOpportunityMap.containsKey(oli.OpportunityId)) {
                      u.Id = oli.Product2.Inventario_de_Usados__c;
                      u.Fecha_De_Factura__c = oli.Opportunity.Fecha_de_factura__c;
                      u.Precio_De_Factura__c = oli.Opportunity.Amount;
                      u.Estado_Del_Vehiculo__c = 'FACTURADO';
                      lstInvUpdate.add(u);
                  }
              }
              
              if(lstInvUpdate.size()> 0){
                  update lstInvUpdate;
              }
              if(lstPrdUpdate.size()> 0){
                  update lstPrdUpdate;
              }
              
          
          }
      }
      
  }
    
    //metodo para capturar el numero del dia de la semana de  la fecha que se recibe //Este metodo se puede poner en una clase Utilitaria
    public static integer getNumeroDiaSemana(Date fechaValor) {
        system.debug('Entrando en getNumeroDiaSemana');
        integer dia = 0;
        //en esta variable se captura el dia de hoy
        Datetime fechaHoy = DateTime.newInstance(
            fechaValor,
      Time.newInstance(0, 0, 0, 0)
    );
    //variable para saber el nombre de dia de la semana
    String nombreDia = fechaHoy.format('EEEE');
    system.debug('El nombre del Dia es ' + nombreDia);
    dia = (nombreDia == 'Monday')
      ? 1
      : (nombreDia == 'Tuesday')
          ? 2
          : (nombreDia == 'Wednesday')
              ? 3
              : (nombreDia == 'Thursday')
                  ? 4
                  : (nombreDia == 'Friday')
                      ? 5
                      : (nombreDia == 'Saturday')
                          ? 6
                          : (nombreDia == 'Sunday') ? 7 : 0;
    system.debug('El numero del dia es : ' + dia);
    return dia;
  }

  private void checkAccountOutdatedFields(List<Opportunity> opportunities) {
    List<Account> accounts = null;

    List<Id> accountIds = new List<Id>();

    for (Opportunity op : opportunities) {
      Id accountId = op.AccountId;
      if(op.RecordType.DeveloperName == Label.RTOportunidadMotos){
        accountIds.add(accountId);
      }
    }

    
    accounts = accountIds.size() == 0 ? new List<Account>() : [
      SELECT Id, PersonMobilePhone, PersonEmail
      FROM Account
      WHERE Id IN :accountIds
    ];

    checkAccountOutdatedFieldsIn(accounts, opportunities);
  }

  private void checkAccountOutdatedFieldsIn(
    List<Account> accounts,
    List<Opportunity> opportunities
  ) {
    FrecuenciaDeActualizacion.isAccountFieldsUpdatedRecently(
      accounts,
      opportunities,
      Label.maxDiasTelefonoCuenta,
      Label.maxDiasEmailCuenta
    );
  }
    
    @future
    public static void notifyNewOwnerUser(Set<String> recipientsIds, String targetId, String oppName) {
 
        // Get the Id for our custom notification type
        CustomNotificationType notificationType = 
            [SELECT Id, DeveloperName 
             FROM CustomNotificationType 
             WHERE DeveloperName='Avisos_por_Flow'];
        
        // Create a new custom notification
        Messaging.CustomNotification notification = new Messaging.CustomNotification();
 
        // Set the contents for the notification
        notification.setTitle(Label.OppNotificationNewOwnerTitle);
        notification.setBody(Label.OppNotificationNewOwnerBody + ', Nombre de Oportunidad: ' + oppName);
 
        // Set the notification type and target
        notification.setNotificationTypeId(notificationType.Id);
        notification.setTargetId(targetId);
        
        // Actually send the notification
        try {
            notification.send(recipientsIds);
            emailNotificationChangedOwner((new list<string>(recipientsIds) )[0] , targetId, oppName);
        }
        catch (Exception e) {
            System.debug('Problem sending notification: ' + e.getMessage());
        }
    }
    
    public static void emailNotificationChangedOwner(String userId, String targetId, String oppName)
    {
        Messaging.SingleEmailMessage semail = new Messaging.SingleEmailMessage();
        String email = [select Id, email from user where Id=:userId].email;
        String[] sendingTo = new String[]{email}; 
        semail.setToAddresses(sendingTo); 
        //String[] sendingToBccAdd = new String[]{‘XXXXXXXXX@gmail.com’}; 
        //semail.setBccAddresses(sendingToBccAdd); 
        //String[] sendingTocAdd = new String[]{‘XXXXXXXXXXX@gmail.com’}; 
        //semail.setCcAddresses(sendingTocAdd); 
        semail.setSubject(Label.OppNotificationNewOwnerTitle); 
        semail.setPlainTextBody(Label.OppEmailNewOwnerBody + ', Nombre de Oportunidad: ' + oppName); 
        semail.setHtmlBody(Label.OppEmailNewOwnerBody + '<br/> <b>Nombre de Oportunidad:</b> ' + oppName); 
        //semail.setHtmlBody(Label.OppNotificationNewOwnerBody + ', Nombre de Oportunidad: ' + oppName +
        //                  '<br/>Click aquí para ver la oportunidad <a href=' + System.URL.getSalesforceBaseUrl() + '/' + targetId + '>click aquí.</a>');                  
        Messaging.sendEmail(new Messaging.SingleEmailMessage[] {semail}); 
        
    } 
}