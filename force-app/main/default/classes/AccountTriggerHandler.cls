/**
 * Fanalca
 * @author           Olvin Abarca
 * Description:      This class runs several processes on Account
 *
 * Changes (Version)
 * -------------------------------------
 *           No.     Date            Author                  Description
 *           -----   ----------      --------------------    ---------------
 * @version  1.0     ??/??/??        ???                     Class definition
 * @version  1.1     12/17/2020      Olvin Abarca            Added mechanism beforeInsert function to set autos/motos checkbox
 * @version  1.2     12/21/2020      Jonathan Parrales       
 * @version  1.3     01/08/2021      Jonathan Parrales       Validate cell phone not in cell phone in users, except when the account has the same numero de documento
 * @version  1.4     April/2021      Jonathan Parrales       Send to UNOEE if the account is created in that system
 * @version  1.5     Novem/2021      Jonathan Parrales       calling frecuencia de actualización here, instead of CuentaTriggerHandler call
 *********************************************************************************************************/

public class AccountTriggerHandler extends TriggerHandler {
  public static Boolean unaVez = true; //variable que estaba en CuentaTriggerHandler, para que no se ejecutara frecuenciaDeActualización más de una vez
    
  //Listas de Account
  private list<Account> newAccountList;

  //Mapa de Account de tipo id, Account
  private Map<Id, Account> newAccountMap;
  private Map<Id, Account> oldAccountMap;

  public AccountTriggerHandler() {
    //Cargamos la lista de Account con lo que viene en el contexto de trigger.new
    newAccountList = (list<Account>) Trigger.New;

    //Cargamos el mapa de Account con lo que viene en el contexto de trigger.newmap
    newAccountMap = (Map<Id, Account>) Trigger.NewMap;

    //Cargamos el mapa de Account con lo que viene en el contexto de trigger.oldmap
    oldAccountMap = (Map<Id, Account>) Trigger.OldMap;
      
  }

  public override void beforeInsert() {
    System.debug('AccountTriggerHandler.beforeInsert()');
      
      Profile perfil = [select Id, Name from Profile where Id=:userInfo.getProfileId()];
      setAutosMotosFlags(newAccountList, perfil.Name);
      
      set<Id> setOwners = new set<Id>();
      map<Id,User> mapOwners = new map<Id,User>();
      
      //Validar el celular ingresado, si éste corresponde con alguno de los celulares de los usuarios de motos 
      
      String likePerfilBuscarCelulares='%';
      if (perfil.Name.contains('moto')) likePerfilBuscarCelulares = 'moto%';
      if (perfil.Name.contains('auto')) likePerfilBuscarCelulares = 'auto%';
      
      set<String> setCelulares = new set<String>();
      for (account a: newAccountList){
          if (!String.isBlank(a.PersonMobilePhone)) setCelulares.add(a.PersonMobilePhone);
          setOwners.add(a.OwnerId);//fill owners set
          
          //Uper case name
          if (a.IsPersonAccount) {
              if (a.FirstName!=null) a.FirstName = a.FirstName.toUpperCase();
              if (a.LastName!=null) a.LastName = a.LastName.toUpperCase();
              if (a.Segundo_Nombre__c!=null) a.Segundo_Nombre__c = a.Segundo_Nombre__c.toUpperCase();
              if (a.Segundo_Apellido__c!=null) a.Segundo_Apellido__c = a.Segundo_Apellido__c.toUpperCase();
          }else a.Name = a.Name.toUpperCase();
      }
      
      //get owners profiles
      for (User u: [select Id, Profile.Name from User where Id in:setOwners]){
          mapOwners.put(u.Id, u);
      }
      
      list<User> lstUsuarios = [select Id,MobilePhone,Numero_de_documento__c from user where profile.Name like :likePerfilBuscarCelulares and MobilePhone in:setCelulares];
      map<String,user> mapUsuarios = new map<String,user>();
      for (User u: lstUsuarios){           mapusuarios.put(u.MobilePhone, u);       }
      
      for (account a: newAccountList){
          if (!String.isBlank(a.PersonMobilePhone)){
              if ( mapUsuarios.containsKey(a.PersonMobilePhone) && a.AM_Numero_de_documento__c!=mapUsuarios.get(a.PersonMobilePhone).Numero_de_documento__c) a.addError('No puede ingresar un celular de uno de los usuarios del sistema!');
          }
          
          //if account's owner is asesores autos then fill PrimerUsAut__c
          if (mapOwners.get(a.OwnerId).Profile.Name.toUpperCase() ==Label.ProfileAsesoresAutos.toUpperCase()){ a.PrimerUsAut__c = a.OwnerId;          }
      }
  }

    private static list<AccountTeamMember> lstAccountTeamMembers;// = new list<AccountTeamMember>();
  public override void beforeUpdate() {
    System.debug('AccountTriggerHandler.beforeUpdate()');
      lstAccountTeamMembers = new list<AccountTeamMember>();
      //Desmarcar Validado Telefono y validado email si cambió
      for (account a: newAccountList){
          Account old = oldAccountMap.get(a.Id);
          if (a.PersonEmail!= old.PersonEmail || a.AM_Correo_Electronico_Trabajo__c!= old.AM_Correo_Electronico_Trabajo__c) a.Email_Validado__c=false;
          if (a.PersonMobilePhone!= old.PersonMobilePhone) a.Telefono_Validado__c = false;
          
          //Uper case name
          if (a.IsPersonAccount) {
              if (a.FirstName!=null) a.FirstName = a.FirstName.toUpperCase();
              if (a.LastName!=null) a.LastName = a.LastName.toUpperCase();
              if (a.Segundo_Nombre__c!=null) a.Segundo_Nombre__c = a.Segundo_Nombre__c.toUpperCase();
              if (a.Segundo_Apellido__c!=null) a.Segundo_Apellido__c = a.Segundo_Apellido__c.toUpperCase();
          }else a.Name = a.Name.toUpperCase();
      }
          
      User runningUser = [select Id, ManagerId,ProfileId, Profile.Name from User where Id=:UserInfo.getUserId()];
      
      if (Test.isRunningTest() || (AccountTriggerHandler.unaVez && runningUser.Profile.Name.toUpperCase().contains('MOTO'))){
      	FrecuenciaDeActualizacion.isAccountFieldsUpdatedRecently(
          newAccountList,
          newAccountList,
          Label.maxDiasTelefonoCuenta,
          Label.maxDiasEmailCuenta
      	);  
        AccountTriggerHandler.unaVez = false;
      }
      
      
      //Validar el celular ingresado, si éste corresponde con alguno de los celulares de los usuarios de motos 
      //Profile perfil = [select Id, Name from Profile where Id=:userInfo.getProfileId()];
      String likePerfilBuscarCelulares='%';
      if (runningUser.Profile.Name.toUpperCase().contains('MOTO')) likePerfilBuscarCelulares = '%moto%'; //if (perfil.Name.contains('moto')) likePerfilBuscarCelulares = '%moto%';
      if (runningUser.Profile.Name.toUpperCase().contains('AUTO')) likePerfilBuscarCelulares = '%auto%';//if (perfil.Name.contains('auto')) likePerfilBuscarCelulares = '%auto%';
      
      set<String> setCelulares = new set<String>();
      set<Id> setOwners = new set<Id>();
      map<Id,User> mapOwners = new map<Id,User>();
      
      
      for (account a: newAccountList){
          if (!String.isBlank(a.PersonMobilePhone)) setCelulares.add(a.PersonMobilePhone);
          setOwners.add(a.OwnerId);//fill owners set
          //setOwners.add(a.PrimerUsAut__c); //fill autos owners
      }
      
      //get owners profiles
      for (User u: [select Id, Profile.Name, ManagerId,IsActive from User where Id in:setOwners]){
          mapOwners.put(u.Id, u);
      }
      
      list<User> lstUsuarios = new list<User>();
      if (runningUser.Profile.Name.toUpperCase().contains('MOTO') && setCelulares.size()>0) lstUsuarios = [select Id,MobilePhone,Numero_de_documento__c from user where profile.Name like :likePerfilBuscarCelulares and MobilePhone in:setCelulares];
      map<String,user> mapUsuarios = new map<String,user>();
      for (User u: lstUsuarios){     mapusuarios.put(u.MobilePhone, u);       }
      
      //cantidad de Oportunidades del running user por cuenta, si es de renting el user se toman en cuenta para darle permiso de actualizar la cuenta
      List<AggregateResult> AggregateResultList = new List<AggregateResult>(); 
      map<Id,integer> mapOppsByAccount = new map<Id,integer>();
      if (runningUser.Profile.Name.toUpperCase()=='ASESORES AUTOS RENTING') AggregateResultList = [select AccountId, count(Id) cantidad from opportunity where OwnerId=:runningUser.Id and AccountId in:newAccountMap.keySet() group by AccountId];
      for (AggregateResult ar: AggregateResultList){ mapOppsByAccount.put(String.valueOf(ar.get('AccountId')), Integer.valueOf(ar.get('cantidad'))); }
      
      for (account a: newAccountList){
          Account old = oldAccountMap.get(a.Id);
          if (!String.isBlank(a.PersonMobilePhone)){
              if ( mapUsuarios.containsKey(a.PersonMobilePhone) && a.AM_Numero_de_documento__c!=mapUsuarios.get(a.PersonMobilePhone).Numero_de_documento__c)  a.addError('No puede ingresar un celular de uno de los usuarios del sistema!');
          }
          
          //PrimerUsAut__c filled and validations
          String thisOwnerPerfil = mapOwners.get(a.OwnerId).Profile.Name.toUpperCase();
          //if Owner Id is not the same as running user and is not about a owner changing
          if (a.OwnerId!=UserINfo.getUserId() && a.OwnerId==old.OwnerId){
              if (mapOwners.get(a.OwnerId).Profile.Name.toUpperCase().contains('MOTO') || mapOwners.get(a.OwnerId).Profile.Name.toUpperCase()=='ADMINISTRADOR DEL SISTEMA' || mapOwners.get(a.OwnerId).Profile.Name.toUpperCase()=='SYSTEM ADMINISTRATOR'){
                  if (runningUser.Profile.Name.toUpperCase()==Label.ProfileAsesoresAutos.toUpperCase() || runningUser.Profile.Name.toUpperCase()=='ASESORES AUTOS RENTING'  
                      || runningUser.Profile.Name.toUpperCase()=='GERENCIAS AUTOS' || runningUser.Profile.Name.toUpperCase()=='GERENCIA GENERAL AUTOS'){
                      //TODO create account team member for runningUserId and OwnerId
                      if (mapOwners.get(a.OwnerId).isActive){
                      	  AccountTeamMember atm = new AccountTeamMember(AccountId = a.Id, UserId = a.OwnerId, TeamMemberRole = 'Account Manager');
                          //atm.AccountId = a.Id;
                          //atm.UserId = a.OwnerId;
                          //atm.TeamMemberRole = 'Account Manager';     
                          lstAccountTeamMembers.add(atm);         
                      }
                      
                          
                      AccountTeamMember atmNewUser = new AccountTeamMember(AccountId = a.Id, UserId = runningUser.Id, TeamMemberRole = 'Account Manager');
                      //atmNewUser.AccountId = a.Id;
                      //atmNewUser.UserId = runningUser.Id;
                      //atmNewUser.TeamMemberRole = 'Account Manager';     
                      lstAccountTeamMembers.add(atmNewUser); 
                          system.debug('lstAccountTeamMembers'); system.debug(lstAccountTeamMembers);
                      a.OwnerId = runningUser.Id;
                      
                  }
              }
              else{
              	if ((runningUser.Profile.Name.toUpperCase()=='GERENCIAS AUTOS' && runningUser.ID!=mapOwners.get(a.OwnerId).ManagerId) || runningUser.Profile.Name.toUpperCase() == Label.ProfileAsesoresAutos.toUpperCase() || (runningUser.Profile.Name.toUpperCase() == 'ASESORES AUTOS RENTING' && (mapOppsByAccount.get(a.Id) ==null || mapOppsByAccount.get(a.Id) ==0 ) ) ) a.addError('Usted no es usuario de Asesores Autos propietario de esta cuenta!');    
              }
              
              /*if (!runningUser.Profile.Name.toUpperCase().contains('MOTO')  && runningUser.Id != mapOwners.get(a.PrimerUsAut__c).ManagerId
                  && runningUser.Profile.Name.toUpperCase()!='ADMINISTRADOR DEL SISTEMA' && runningUser.Profile.Name.toUpperCase()!='SYSTEM ADMINISTRATOR' && runningUser.Profile.Name.toUpperCase()!='INTEGRACIONES'
                  && runningUser.Profile.Name.toUpperCase()!='ANALISTA DE MERCADEO AGENCIA AUTOS' && runningUser.Profile.Name.toUpperCase()!='GERENCIA GENERAL AUTOS'){
                      a.addError('Usted no tiene permisos para modificar esta cuenta');
                  }
			*/
          }
          
         
          
      }system.debug(lstAccountTeamMembers);
      //if (lstAccountTeamMembers.size()>0) {
      //    insert lstAccountTeamMembers;
      //    system.debug('lstAccountTeamMembers');system.debug(lstAccountTeamMembers);
      //}
      setAutosMotosFlags(newAccountList, runningUser.Profile.Name);

    System.debug('AccountTriggerHandler.beforeUpdate() Saliendo');
  }

  /**
   * Setiamos el checkbox Cuenta_autos__c/Cuenta_motos__c en dependencia
   * del nombre del perfil del usuario creando la cuenta. Estos campos
   * son necesarios para identificar si la cuenta es cliente de motos y/o autos
   */
  private void setAutosMotosFlags(List<Account> newAccountList, String profileName) {
    //Profile profile = [
    //  SELECT Id, Name
    //  FROM Profile
    //  WHERE Id = :UserInfo.getProfileId()
    //  LIMIT 1
    //];

    String profileIntegraciones = 'Integraciones';
    //String profileName = profile.Name;

    for (Account newAccount : newAccountList) {
      Boolean isMotosProfile =
        (profileName.toLowerCase().indexOf('motos') > -1) ||
        (profileName == profileIntegraciones && newAccount.Codigo_ERP__c != null && newAccount.Codigo_ERP__c != '');
      Boolean isAutosProfile =
        (profileName.toLowerCase().indexOf('autos') > -1) ||
        (profileName == profileIntegraciones && newAccount.Codigo_UNOEE__c != null && newAccount.Codigo_UNOEE__c != '');

      if (isAutosProfile) {
        newAccount.Cuenta_autos__c = true;
      } else if (isMotosProfile) {
        newAccount.Cuenta_motos__c = true;
      }
    }
  }

  public override void afterUpdate() {
    system.debug('AccountTriggerHandler: Entrando afterUpdate');
      system.debug('lstAccountTeamMembers: ' + lstAccountTeamMembers);
    try {
      if (newAccountList.size()==1) {
        Account a = newAccountList[0];
        Account old = oldAccountMap.get(a.Id);
        //Envío a SAP
        if (
          a.Codigo_ERP__c != null && a.Codigo_ERP__c != '' &&
          (a.Actualizar_Concesionario__c ||
          a.AM_Tipo_de_documento__c != old.AM_Tipo_de_documento__c ||
          a.AM_Numero_de_documento__c != old.AM_Numero_de_documento__c ||
          a.AM_Direccion__c != old.AM_Direccion__c ||//a.DireccionERP__c != old.DireccionERP__c ||
          a.AM_Ciudad__c != old.AM_Ciudad__c ||
          a.Phone != old.Phone ||
          a.PersonMobilePhone != old.PersonMobilePhone ||
          a.AM_Estado__c != old.AM_Estado__c ||
          a.Salutation != old.Salutation ||
          a.FirstName != old.FirstName ||
          a.Segundo_Nombre__c != old.Segundo_Nombre__c ||
          a.LastName != old.LastName ||
          a.Segundo_Apellido__c != old.Segundo_Apellido__c ||
          a.PersonEmail != old.PersonEmail ||
          a.Autoriza_Tratamiento_de_Datos_personale__pc !=
          old.Autoriza_Tratamiento_de_Datos_personale__pc ||
          a.Autoriza_Tratamiento_Datos_Personales__c !=
          old.Autoriza_Tratamiento_Datos_Personales__c ||
          a.AM_Correo_Electronico_Trabajo__c !=
          old.AM_Correo_Electronico_Trabajo__c ||
          a.Name != old.Name)
        ) {
          EnviarASAP(a.Id, a.Actualizar_Concesionario__c);
          system.debug(
            'Se envío al WS de modificación de cliente en sap ' + a.Id
          );
        }
          
        //Envío a UNOEE
        if (a.Creado_en_UNOEE__c &&
          (a.AM_Tipo_de_documento__c != old.AM_Tipo_de_documento__c ||
          a.AM_Numero_de_documento__c != old.AM_Numero_de_documento__c ||
          a.FirstName != old.FirstName ||
          a.Segundo_Nombre__c != old.Segundo_Nombre__c ||
          a.LastName != old.LastName ||
          a.Segundo_Apellido__c != old.Segundo_Apellido__c ||
          a.Sucursal__c != old.Sucursal__c ||
          a.AM_Direccion__c != old.AM_Direccion__c ||
          a.Phone != old.Phone ||
          a.PersonMobilePhone != old.PersonMobilePhone ||
          a.MC_Correo_electronico_Empresa__c != old.MC_Correo_electronico_Empresa__c || //ojo para sap se mapea AM_Correo_Electronico_Trabajo__c
          a.PersonEmail != old.PersonEmail ||
          a.AM_Ciudad__c != old.AM_Ciudad__c ||
          a.MC_Autoriza_tratardatos_personales__c != old.MC_Autoriza_tratardatos_personales__c || //ojo en SAP se usa Autoriza_Tratamiento_Datos_Personales__c  
          a.Name != old.Name)
        ) {
          EnviarAUNOEE(a.Id);
          system.debug(
            'Se envío al WS de modificación de cliente A UNOEE ' + a.Id
          );
        }
      }
        
        if (lstAccountTeamMembers!=null && lstAccountTeamMembers.size()>0) {
            insert lstAccountTeamMembers;
        	system.debug('lstAccountTeamMembers: ' + lstAccountTeamMembers);       
            lstAccountTeamMembers = null;
        }
    } catch (Exception ex) {
      system.debug(ex.getMessage());
    }

    system.debug('AccountTriggerHandler: Saliendo afterUpdate');
  }

  @Future(callout=true)
  private static void EnviarASAP(
    Id accountId,
    boolean ActualizarConcesionario
  ) {
    MotosSendAccountToSAP.SendAccount(accountId, 'M');
    if (ActualizarConcesionario) {
      Account a = new Account(
        id = accountId,
        Actualizar_Concesionario__c = false
      );
      TriggerHandler.bypass('AccountTriggerHandler');
      update a;
      TriggerHandler.clearBypass('AccountTriggerHandler');
    }
  }
     
  @Future(callout=true)
  private static void EnviarAUNOEE( Id accountId ) {
    AutosSendAccountToUNOEE.SendAccount(accountId);
  }
}