public class LeadTriggerHandler extends TriggerHandler {
	//Listas de Lead
	private list<Lead> newLeadList;

	//Mapa de Lead de tipo id, Lead
	private Map<Id, Lead> newLeadMap;
	private Map<Id, Lead> oldLeadMap;

	public LeadTriggerHandler() {

		//Cargamos la lista de Lead con lo que viene en el contexto de trigger.new
		newLeadList = (list<Lead>) Trigger.New;

		//Cargamos el mapa de Lead con lo que viene en el contexto de trigger.newmap
		newLeadMap = (Map<Id, Lead>) Trigger.NewMap;

		//Cargamos el mapa de Lead con lo que viene en el contexto de trigger.oldmap
		oldLeadMap = (Map<Id, Lead>) Trigger.OldMap;

		//Precargamos la lista de tipos de registro
		//Util.getRecordTypes();

	}

	//public override void beforeInsert() {}		

	public override void afterInsert() {
		system.debug('LEAD: Entrando en After Insert');
        Date hoy = Test.isRunningTest() ? LeadTriggerHandler_Test.hoy : system.today();
        Datetime ahora = Test.isRunningTest() ? LeadTriggerHandler_Test.ahora : system.now();
		//esta variable para capturar el Id de los Tipo de registro
		List<Id>IdsRecordType=new List<Id>();
		//este mapa es para saber cual es el Tipo de registro relacionado a cada Lead
		Map<String, RecordType>MapRecordType;//=new Map<String , RecordType>();
		//esta variable es para saber si es que se debe consultar el horario de Motos
		Boolean HorarioMoto = false;
		//este mapa es para saber el Horario de Oficina relacionado al Tipo de registro de Motos
		//Map<String , BusinessHours>MapBusinessHour;			
		BusinessHours HorarioMotos;
		//Para cuando es un Lead de tipo de registro de Motos , se va evaluar el momento en que se asigna el LEAD, se calcula el due date del evento con base a la cantidad de horas maximas de atencion "4" y el horario de oficina de MOTOS
		for(Lead l : newLeadList){
			//capturar el tipo de registro
			IdsRecordType.add(l.RecordTypeId);
		}
		
		//consultar los tipos de registro relacionados a los Leads
		if(IdsRecordType.size()>0){
			//cargar el mapa con los tipos de registros de los LEad que sean de motos
			MapRecordType = new Map<String, RecordType>([Select Id , Name, DeveloperName FROM RecordType WHERE Id IN : IdsRecordType AND (DeveloperName=:'Persona_Juridica_Motos' OR DeveloperName=:'Persona_Natural_Motos')]);
			//si la consulta obtuvo resultados , osea , si alguno de los LEAD es del Tipo de registro de Motos
			if(MapRecordType.size()>0){
				//se debe marcar el flag que determina que se debe consultar el horario de Motos
				HorarioMoto = true;
			}
		}
		
		//se consulta el horario de MOTOS?
		if(HorarioMoto){
			/*MapBusinessHour = new Map<String , BusinessHours>([Select Name, IsActive, IsDefault, TimeZoneSidKey, MondayStartTime, MondayEndTime, TuesdayStartTime, TuesdayEndTime, WednesdayStartTime, WednesdayEndTime, ThursdayStartTime, 
															ThursdayEndTime, FridayStartTime, FridayEndTime, SaturdayStartTime, SaturdayEndTime, SundayStartTime, SundayEndTime FROM BusinessHours WHERE Name=:'Motos' AND IsActive=:true]);*/
			List<BusinessHours>Horarios = [Select Name, /*BusinessHoursId,*/ IsActive, IsDefault, TimeZoneSidKey, MondayStartTime, MondayEndTime, TuesdayStartTime, TuesdayEndTime, WednesdayStartTime, WednesdayEndTime, ThursdayStartTime, 
															ThursdayEndTime, FridayStartTime, FridayEndTime, SaturdayStartTime, SaturdayEndTime, SundayStartTime, SundayEndTime FROM BusinessHours WHERE Name=:'Motos' AND IsActive=:true];
			if(Horarios.size()>0){
				HorarioMotos = Horarios[0];
			}
		}
		
		//esta lista es para capturar los registros de evento para cada LEAD
		List<task>Eventos=new List<Task>();
		//para cada LEAD nuevo
		for(Lead l : newLeadList){
			//antes de entrar aca , se podria evaluar algun flag que determine si es que se asignó a un usuario	, en este momento se asume que ya se asignó
			//Por el tipo de registro veamos si es de Motos
			if(MapRecordType.ContainsKey(l.RecordTypeId) && HorarioMotos!=null){
				//si es de motos , entonces se captura el horario de oficina de motos
				//BusinessHours HorarioMotos = MapBusinessHour.get('Motos');
				system.debug('El horario es: '+HorarioMotos);
				//obtener el numero del dia de la semana a partir de la fecha de hoy
				Integer DiaDeSemana = getNumeroDiaSemana(hoy); //Changed 20210122 for test purpose system.today());
				//ahora desde el horario de oficina capturar la fecha de Inicio y Fin en dependencia del dia
				//esta variable es para capturar la hora de inicio en dependencia del dia
				Time HorarioDeInicio;
				HorarioDeInicio = (DiaDeSemana==1)?HorarioMotos.MondayStartTime:
							 (DiaDeSemana==2)?HorarioMotos.TuesdayStartTime:
							 (DiaDeSemana==3)?HorarioMotos.WednesdayStartTime:
							 (DiaDeSemana==4)?HorarioMotos.ThursdayStartTime:
							 (DiaDeSemana==5)?HorarioMotos.FridayStartTime:
							 (DiaDeSemana==6)?HorarioMotos.SaturdayStartTime:
							 (DiaDeSemana==7)? HorarioMotos.SundayStartTime:
							 null;
				Integer HoraInicio = HorarioDeInicio!=null ? HorarioDeInicio.hour() : 0;//HorarioDeInicio.hour();
				system.debug('LEAD: la Hora de inicio es: '+HoraInicio);
				//para capturar hora de fin en dependencia del dia
				Time HorarioDeFin;
				HorarioDeFin = (DiaDeSemana==1)?HorarioMotos.MondayEndTime:
							 (DiaDeSemana==2)?HorarioMotos.TuesdayEndTime:
							 (DiaDeSemana==3)?HorarioMotos.WednesdayEndTime:
							 (DiaDeSemana==4)?HorarioMotos.ThursdayEndTime:
							 (DiaDeSemana==5)?HorarioMotos.FridayEndTime:
							 (DiaDeSemana==6)?HorarioMotos.SaturdayEndTime:
							 (DiaDeSemana==7)?HorarioMotos.SundayEndTime:
							 null;					
				Integer HoraFin = HorarioDeFin!=null ? HorarioDeFin.hour() : 0;//HorarioDeFin.hour();
				system.debug('LEAD: la Hora de fin es ' +HoraFin);				
				
				//capturo la hora actual,si pasa de los 30 minutos se redondea al numero siguiente
				Integer HoraActual = ahora.hour();//Changed 20210122 system.now().hour();				
				system.debug('LEAD: la Hora actual es ' +HoraActual);
				//ahora debo calcular el tiempo del horario laboral a partir de la variable de la cantidad de horas maximas para atender al LEAD
				Integer HorasRestantesHorario = HoraFin - HoraActual;
				system.debug('LEAD: Faltan ' +HorasRestantesHorario+' para finalizar el horario laboral');
				//ahora capturo desde la etiqueta personalizada , el valor de la cantidad de horas maximas que tiene el usuario para atender al LEAD.
				Integer HorasParaEvento;// = Integer.valueOf(LABEL.HorasParaEvento);
                if(Test.isRunningTest()) { HorasParaEvento = LeadTriggerHandler_Test.HorasParaEvento; } //En modo test, se controla las horas para el evento
                else { HorasParaEvento = Integer.valueOf(LABEL.HorasParaEvento);}
				//esta variable es para saber si es que se debe hacer un incremento en dias para crear el evento
				Integer IncrementoEnDias = 0;
				//esta variable es para saber el incremento en horas a la fecha(hora) en la que se debe agendar el evento
				Integer IncrementEnHoras = 0;
				//ahora pregunto si es que las horas restantes del horario son menor que las horas en las que se debe agendar el evento
				if(HorasRestantesHorario<HorasParaEvento){
					//si son menor , entonces quiere decir que el evento NO se puede agendar para el dia de hoy , quiere decir que el evento se debe agendar para el dia siguiente
					//primero se debe saber cuanto será el incremento en dias
					IncrementoEnDias = (DiaDeSemana==6)?2:1;//si el dia es Sabado , entonces se incrementa los dias en 2 , sino , se incrementa solo en 1
					//ahora se debe saber cuanto seria el incremento en horas 
					IncrementEnHoras = HorasParaEvento - HorasRestantesHorario;	
					system.debug('Se incrementan en Dias '+IncrementoEnDias+' horas : '+IncrementEnHoras);					
				}else{
					//si las horas restantes no son menor a las horas para agendar , el incremento en dias queda en 0, 
					//el incremento en horas se le establece el valor de HorasParaEvento
					IncrementEnHoras = HorasParaEvento;
					system.debug('Se incrementan en horas : '+IncrementEnHoras);
				}
				
				//en esta variable voy a establecer cuando es la fecha y hora para el evento
				DateTime FechaHoraEvento;
				//esta variable es para establecer la fecha y hora de fin del evento
				DateTime FechaHoraFinEvento;
				Date FechaEvento;
				//si el incremento en dias es 0 , quiere decir que se agenda para hoy mismo
				if(IncrementoEnDias==0){
					//solo se incrementa la cantidad de horas segun la etiqueta personalizada
					//FechaHoraFinEvento = FechaHoraEvento.addHours(- 1);
					FechaHoraFinEvento = ahora.addHours(IncrementEnHoras);//Changed 20210122 system.now().addHours(IncrementEnHoras);
					//FechaHoraEvento = system.now().addHours(IncrementEnHoras);
					FechaHoraEvento = ahora;//Changed 20210122 system.now();//.addHours(IncrementEnHoras);
					//FechaHoraEvento = FechaHoraEvento.addHours(- 1);					
					system.debug('No hay incremento en dias , la fecha del evento seria '+FechaHoraEvento);
				}else{
					//si ya se determina que haya incremento en dias,
					//primero debemos inicializar una fecha donde se haga el incremento en dias
					FechaEvento = hoy.addDays(IncrementoEnDias);//Changed 20210122 for test purpose system.today().addDays(IncrementoEnDias);
					//ahora que ya tenemos la fecha , debemos saber que dia de la semana es mañana
					Integer DiaDeManana = getNumeroDiaSemana(FechaEvento);
					//una vez que ya sabemos el dia de manana , debemos mandar a traer desde el horario de oficina , la hora de inicio
					Time HorarioDeInicioManana;
					HorarioDeInicioManana = (DiaDeManana==1)?HorarioMotos.MondayStartTime:
								 (DiaDeManana==2)?HorarioMotos.TuesdayStartTime:
								 (DiaDeManana==3)?HorarioMotos.WednesdayStartTime:
								 (DiaDeManana==4)?HorarioMotos.ThursdayStartTime:
								 (DiaDeManana==5)?HorarioMotos.FridayStartTime:
								 (DiaDeManana==6)?HorarioMotos.SaturdayStartTime:
								 (DiaDeManana==7)?HorarioMotos.SundayStartTime:
								 null;
					Integer HoraInicioManana = HorarioDeInicioManana.hour();
					
					system.debug('LEAD: la Hora de inicio del proximo dia es: '+HoraInicioManana);	
					//preguntamos si a la hora de inicio se le debe incrementar
					if(IncrementEnHoras>0){
						//a la hora de inicio le incrementamos la cantidad de horas 
						HoraInicioManana = (HoraInicioManana + IncrementEnHoras) - 1;
						
						//HorarioDeInicioManana.addHours(IncrementEnHoras);
						system.debug('La hora de inicio de Manana se incrementa en '+IncrementEnHoras);
					}
					Integer HoraFinManana = HoraInicioManana+1;
					
					system.debug('La hora de Inicio del Evento queda en '+HoraInicioManana+' y la hora de fin del Evento '+HoraFinManana);
					
					//ahora se inicializa la fecha y hora del evento con el incremento de dias y horas segun corresponda
					//FechaHoraEvento = DateTime.newInstance(FechaEvento.year(), FechaEvento.month(), FechaEvento.day(), HoraInicioManana , HorarioDeInicioManana.minute(), HorarioDeInicioManana.second()); 					
					FechaHoraEvento = DateTime.newInstance(FechaEvento.year(), FechaEvento.month(), FechaEvento.day(), HoraInicioManana , HorarioDeInicioManana.minute(), HorarioDeInicioManana.second()); 					
					system.debug('HAY incremento en dias , la fecha del evento seria '+FechaHoraEvento);
					//FechaHoraFinEvento = DateTime.newInstance(FechaEvento.year(), FechaEvento.month(), FechaEvento.day(), HoraFinManana , HorarioDeInicioManana.minute(), HorarioDeInicioManana.second()); 					
					FechaHoraFinEvento = DateTime.newInstance(FechaEvento.year(), FechaEvento.month(), FechaEvento.day(), HoraFinManana , HorarioDeInicioManana.minute(), HorarioDeInicioManana.second()); 					
					system.debug('La hora de fin del evento seria : '+FechaHoraFinEvento);
				}
				
				//una vez definido la Fecha y hora del evento...
				//Event Evento = new Event();
				//Evento.OwnerId = l.OwnerId;
				//Evento.Description = LABEL.DescripcionDeEvento;
				//Evento.WhoId = l.Id;
				//Evento.Subject = LABEl.AsuntoDeEvento;
				//Evento.ActivityDate = Date.valueOf(FechaHoraEvento);
				//Evento.ActivityDateTime = FechaHoraEvento;
				//Evento.StartDateTime = FechaHoraEvento;
				//Evento.EndDateTime = FechaHoraFinEvento;
				//Evento.IsReminderSet = true;
				//Evento.ReminderDateTime = FechaHoraFinEvento.addHours(-1);//FechaHoraEvento;
				//Eventos.add(Evento);
                
                //una vez definido la Fecha y hora del evento...
                Task tarea = new Task();//Event Evento = new Event();
                tarea.OwnerId = l.OwnerId;//Evento.OwnerId = O.OwnerId;
                tarea.Subject = LABEl.AsuntoDeTareaLead;//Evento.Subject = LABEl.AsuntoDeEvento; //'Call';//
                tarea.Description = LABEL.DescripcionDeTareaLead;//Evento.Description = LABEL.DescripcionDeEvento;
                //tarea.StartDateTime = FechaHoraEvento;//Evento.StartDateTime = FechaHoraEvento;
                //tarea.EndDateTime = FechaHoraFinEvento;//Evento.EndDateTime = FechaHoraFinEvento;
                tarea.WhoId = l.Id;
                //tarea.WhatId = O.Id;//Evento.WhatId = O.Id;
                tarea.ActivityDate = Date.valueOf(FechaHoraEvento);//Evento.ActivityDate = Date.valueOf(FechaHoraEvento);
                //Not exists ActivityDateTime in Task tarea.ActivityDateTime = FechaHoraEvento;//Evento.ActivityDateTime = FechaHoraEvento;
                tarea.IsReminderSet = true;//Evento.IsReminderSet = true;
                tarea.ReminderDateTime = FechaHoraFinEvento.addHours(-1); //FechaHoraEvento;//Evento.ReminderDateTime = FechaHoraFinEvento.addHours(-1); //FechaHoraEvento;
                Eventos.add(tarea);//Eventos.add(Evento);
			}
		}
		
		//Hay eventos por insertar?
		if(Eventos.size()>0){
			insert Eventos;
		}
		
	}
	
	//public override void beforeUpdate() {}
	/*
	public override void afterUpdate() {
		system.debug('LEAD: Entrando en After Update');
		//esta variable para capturar el Id de los Tipo de registro
		List<Id>IdsRecordType=new List<Id>();
		//este mapa es para saber cual es el Tipo de registro relacionado a cada Lead
		Map<String, RecordType>MapRecordType;//=new Map<String , RecordType>();
		//esta variable es para saber si es que se debe consultar el horario de Motos
		Boolean HorarioMoto = false;
		//este mapa es para saber el Horario de Oficina relacionado al Tipo de registro de Motos
		//Map<String , BusinessHours>MapBusinessHour;			
		BusinessHours HorarioMotos;
		//Para cuando es un Lead de tipo de registro de Motos , se va evaluar el momento en que se asigna el LEAD, se calcula el due date del evento con base a la cantidad de horas maximas de atencion "4" y el horario de oficina de MOTOS
		for(Lead l : newLeadList){
			//capturar el tipo de registro
			IdsRecordType.add(l.RecordTypeId);
		}
		
		//consultar los tipos de registro relacionados a los Leads
		if(IdsRecordType.size()>0){
			//cargar el mapa con los tipos de registros de los LEad que sean de motos
			MapRecordType = new Map<String, RecordType>([Select Id , Name, DeveloperName FROM RecordType WHERE Id IN : IdsRecordType AND (DeveloperName=:'Persona_Juridica_Motos' OR DeveloperName=:'Persona_Natural_Motos')]);
			//si la consulta obtuvo resultados , osea , si alguno de los LEAD es del Tipo de registro de Motos
			if(MapRecordType.size()>0){
				//se debe marcar el flag que determina que se debe consultar el horario de Motos
				HorarioMoto = true;
			}
		}
		
		//se consulta el horario de MOTOS?
		if(HorarioMoto){
			//MapBusinessHour = new Map<String , BusinessHours>([Select Name, IsActive, IsDefault, TimeZoneSidKey, MondayStartTime, MondayEndTime, TuesdayStartTime, TuesdayEndTime, WednesdayStartTime, WednesdayEndTime, ThursdayStartTime, 
			//												ThursdayEndTime, FridayStartTime, FridayEndTime, SaturdayStartTime, SaturdayEndTime, SundayStartTime, SundayEndTime FROM BusinessHours WHERE Name=:'Motos' AND IsActive=:true]);
			List<BusinessHours>Horarios = [Select Name, IsActive, IsDefault, TimeZoneSidKey, MondayStartTime, MondayEndTime, TuesdayStartTime, TuesdayEndTime, WednesdayStartTime, WednesdayEndTime, ThursdayStartTime, 
															ThursdayEndTime, FridayStartTime, FridayEndTime, SaturdayStartTime, SaturdayEndTime, SundayStartTime, SundayEndTime FROM BusinessHours WHERE Name=:'Motos' AND IsActive=:true];
			if(Horarios.size()>0){
				HorarioMotos = Horarios[0];
			}
		}
		
		//esta lista es para capturar los registros de evento para cada LEAD
		List<Event>Eventos=new List<Event>();
		//para cada LEAD nuevo
		for(Lead l : newLeadList){
			//antes de entrar aca , se podria evaluar algun flag que determine si es que se asignó a un usuario	, en este momento se asume que ya se 
			//hubo cambio de Owner?
			if(l.OwnerId!=oldLeadMap.get(l.Id).OwnerId){
				//Por el tipo de registro veamos si es de Motos
				if(MapRecordType.ContainsKey(l.RecordTypeId) && HorarioMotos!=null){
					//si es de motos , entonces se captura el horario de oficina de motos
					//BusinessHours HorarioMotos = MapBusinessHour.get('Motos');
					system.debug('El horario es: '+HorarioMotos);
					//obtener el numero del dia de la semana a partir de la fecha de hoy
					Integer DiaDeSemana = getNumeroDiaSemana(system.today());
					//ahora desde el horario de oficina capturar la fecha de Inicio y Fin en dependencia del dia
					//esta variable es para capturar la hora de inicio en dependencia del dia
					Time HorarioDeInicio;
					HorarioDeInicio = (DiaDeSemana==1)?HorarioMotos.MondayStartTime:
								 (DiaDeSemana==2)?HorarioMotos.TuesdayStartTime:
								 (DiaDeSemana==3)?HorarioMotos.WednesdayStartTime:
								 (DiaDeSemana==4)?HorarioMotos.ThursdayStartTime:
								 (DiaDeSemana==5)?HorarioMotos.FridayStartTime:
								 (DiaDeSemana==6)?HorarioMotos.SaturdayStartTime:
								 (DiaDeSemana==7)?HorarioMotos.SundayStartTime:
								 null;
					Integer HoraInicio = HorarioDeInicio.hour();
					system.debug('LEAD: la Hora de inicio es: '+HoraInicio);
					//para capturar hora de fin en dependencia del dia
					Time HorarioDeFin;
					HorarioDeFin = (DiaDeSemana==1)?HorarioMotos.MondayEndTime:
								 (DiaDeSemana==2)?HorarioMotos.TuesdayEndTime:
								 (DiaDeSemana==3)?HorarioMotos.WednesdayEndTime:
								 (DiaDeSemana==4)?HorarioMotos.ThursdayEndTime:
								 (DiaDeSemana==5)?HorarioMotos.FridayEndTime:
								 (DiaDeSemana==6)?HorarioMotos.SaturdayEndTime:
								 (DiaDeSemana==7)?HorarioMotos.SundayEndTime:
								 null;					
					Integer HoraFin = HorarioDeFin.hour();
					system.debug('LEAD: la Hora de fin es ' +HoraFin);				
					
					//capturo la hora actual,si pasa de los 30 minutos se redondea al numero siguiente
					Integer HoraActual = system.now().hour();				
					system.debug('LEAD: la Hora actual es ' +HoraActual);
					//ahora debo calcular el tiempo del horario laboral a partir de la variable de la cantidad de horas maximas para atender al LEAD
					Integer HorasRestantesHorario = HoraFin - HoraActual;
					system.debug('LEAD: Faltan ' +HorasRestantesHorario+' para finalizar el horario laboral');
					//ahora capturo desde la etiqueta personalizada , el valor de la cantidad de horas maximas que tiene el usuario para atender al LEAD.
					Integer HorasParaEvento = Integer.valueOf(LABEL.HorasParaEvento);
					//esta variable es para saber si es que se debe hacer un incremento en dias para crear el evento
					Integer IncrementoEnDias = 0;
					//esta variable es para saber el incremento en horas a la fecha(hora) en la que se debe agendar el evento
					Integer IncrementEnHoras = 0;
					//ahora pregunto si es que las horas restantes del horario son menor que las horas en las que se debe agendar el evento
					if(HorasRestantesHorario<HorasParaEvento){
						//si son menor , entonces quiere decir que el evento NO se puede agendar para el dia de hoy , quiere decir que el evento se debe agendar para el dia siguiente
						//primero se debe saber cuanto será el incremento en dias
						IncrementoEnDias = (DiaDeSemana==6)?2:1;//si el dia es Sabado , entonces se incrementa los dias en 2 , sino , se incrementa solo en 1
						//ahora se debe saber cuanto seria el incremento en horas 
						IncrementEnHoras = HorasParaEvento - HorasRestantesHorario;	
						system.debug('Se incrementan en Dias '+IncrementoEnDias+' horas : '+IncrementEnHoras);					
					}else{
						//si las horas restantes no son menor a las horas para agendar , el incremento en dias queda en 0, 
						//el incremento en horas se le establece el valor de HorasParaEvento
						IncrementEnHoras = HorasParaEvento;
						system.debug('Se incrementan en horas : '+IncrementEnHoras);
					}
					
				//en esta variable voy a establecer cuando es la fecha y hora para el evento
				DateTime FechaHoraEvento;
				//esta variable es para establecer la fecha y hora de fin del evento
				DateTime FechaHoraFinEvento;
				Date FechaEvento;
				//si el incremento en dias es 0 , quiere decir que se agenda para hoy mismo
				if(IncrementoEnDias==0){
					//solo se incrementa la cantidad de horas segun la etiqueta personalizada
					//FechaHoraFinEvento = FechaHoraEvento.addHours(- 1);
					FechaHoraFinEvento = system.now().addHours(IncrementEnHoras);
					//FechaHoraEvento = system.now().addHours(IncrementEnHoras);
					FechaHoraEvento = system.now();//.addHours(IncrementEnHoras);
					//FechaHoraEvento = FechaHoraEvento.addHours(- 1);					
					system.debug('No hay incremento en dias , la fecha del evento seria '+FechaHoraEvento);
				}else{
					//si ya se determina que haya incremento en dias,
					//primero debemos inicializar una fecha donde se haga el incremento en dias
					FechaEvento = system.today().addDays(IncrementoEnDias);
					//ahora que ya tenemos la fecha , debemos saber que dia de la semana es mañana
					Integer DiaDeManana = getNumeroDiaSemana(FechaEvento);
					//una vez que ya sabemos el dia de manana , debemos mandar a traer desde el horario de oficina , la hora de inicio
					Time HorarioDeInicioManana;
					HorarioDeInicioManana = (DiaDeManana==1)?HorarioMotos.MondayStartTime:
								 (DiaDeManana==2)?HorarioMotos.TuesdayStartTime:
								 (DiaDeManana==3)?HorarioMotos.WednesdayStartTime:
								 (DiaDeManana==4)?HorarioMotos.ThursdayStartTime:
								 (DiaDeManana==5)?HorarioMotos.FridayStartTime:
								 (DiaDeManana==6)?HorarioMotos.SaturdayStartTime:
								 (DiaDeManana==7)?HorarioMotos.SundayStartTime:
								 null;
					Integer HoraInicioManana = HorarioDeInicioManana.hour();
					
					system.debug('LEAD: la Hora de inicio del proximo dia es: '+HoraInicioManana);	
					//preguntamos si a la hora de inicio se le debe incrementar
					if(IncrementEnHoras>0){
						//a la hora de inicio le incrementamos la cantidad de horas 
						HoraInicioManana = (HoraInicioManana + IncrementEnHoras) - 1;
						
						//HorarioDeInicioManana.addHours(IncrementEnHoras);
						system.debug('La hora de inicio de Manana se incrementa en '+IncrementEnHoras);
					}
					Integer HoraFinManana = HoraInicioManana+1;
					
					system.debug('La hora de Inicio del Evento queda en '+HoraInicioManana+' y la hora de fin del Evento '+HoraFinManana);
					
					//ahora se inicializa la fecha y hora del evento con el incremento de dias y horas segun corresponda
					//FechaHoraEvento = DateTime.newInstance(FechaEvento.year(), FechaEvento.month(), FechaEvento.day(), HoraInicioManana , HorarioDeInicioManana.minute(), HorarioDeInicioManana.second()); 					
					FechaHoraEvento = DateTime.newInstance(FechaEvento.year(), FechaEvento.month(), FechaEvento.day(), HoraInicioManana , HorarioDeInicioManana.minute(), HorarioDeInicioManana.second()); 					
					system.debug('HAY incremento en dias , la fecha del evento seria '+FechaHoraEvento);
					//FechaHoraFinEvento = DateTime.newInstance(FechaEvento.year(), FechaEvento.month(), FechaEvento.day(), HoraFinManana , HorarioDeInicioManana.minute(), HorarioDeInicioManana.second()); 					
					FechaHoraFinEvento = DateTime.newInstance(FechaEvento.year(), FechaEvento.month(), FechaEvento.day(), HoraFinManana , HorarioDeInicioManana.minute(), HorarioDeInicioManana.second()); 					
					system.debug('La hora de fin del evento seria : '+FechaHoraFinEvento);
				}
				
				//una vez definido la Fecha y hora del evento...
				Event Evento = new Event();
				Evento.OwnerId = l.OwnerId;
				Evento.Description = LABEL.DescripcionDeEvento;
				Evento.WhoId = l.Id;
				Evento.Subject = LABEl.AsuntoDeEvento;
				Evento.ActivityDate = Date.valueOf(FechaHoraEvento);
				Evento.ActivityDateTime = FechaHoraEvento;
				Evento.StartDateTime = FechaHoraEvento;
				Evento.EndDateTime = FechaHoraFinEvento;
				Evento.IsReminderSet = true;
				Evento.ReminderDateTime = FechaHoraFinEvento.addHours(-1);//FechaHoraEvento;
				Eventos.add(Evento);
				}			
			}
		}
		
		//Hay eventos por insertar?
		if(Eventos.size()>0){
			insert Eventos;
		}		
	}
	*/
	//metodo para capturar el numero del dia de la semana de  la fecha que se recibe //Este metodo se puede poner en una clase Utilitaria
	public static integer getNumeroDiaSemana(Date fechaValor){
		system.debug('Entrando en getNumeroDiaSemana');
		integer dia = 0;
		//en esta variable se captura el dia de hoy
		Datetime fechaHoy = DateTime.newInstance(fechaValor, Time.newInstance(0, 0, 0, 0));
		//variable para saber el nombre de dia de la semana
		String nombreDia = fechaHoy.format('EEEE');
		system.debug('El nombre del Dia es '+nombreDia);
		dia = (nombreDia=='Monday')?1:
			  (nombreDia=='Tuesday')?2:
			  (nombreDia=='Wednesday')?3:
			  (nombreDia=='Thursday')?4:
			  (nombreDia=='Friday')?5:
			  (nombreDia=='Saturday')?6:
			  (nombreDia=='Sunday')?7:
			  0;
		system.debug('El numero del dia es : ' +dia);			  
		return dia;
	}		
}