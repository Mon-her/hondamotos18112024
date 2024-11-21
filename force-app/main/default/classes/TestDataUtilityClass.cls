/**
 * Fanalca
 * @author           Juan Ansaldi
 * Description:      Utility class to create test data.
 *
 * Changes (Version)
 * -------------------------------------
 *           No.     Date            Author                  Description
 *           -----   ----------      --------------------    ---------------
 * @version  1.0     05/11/2020      Juan Ansaldi            Class definition.
 * @version  1.1     06/11/2020      Jonathan Parrales       Class definition
 * @version  1.2     12/26/2020      Olvin Abarca            Adding a return to function crearClienteMotos & crearOportunidadMotos
 *********************************************************************************************************/
@isTest
public class TestDataUtilityClass {
  public static List<AM_Municipio__c> crearMunicipios(Integer numMun) {
    List<AM_Municipio__c> municipios = new List<AM_Municipio__c>();

    for (Integer i = 0; i < numMun; i++) {
      AM_Municipio__c a = new AM_Municipio__c();
      a.Name = 'Municipio ' + i;
      a.AM_Nombre_departamento__c = 'Departamento ' + i;
      a.AM_Codigo_DANE_departamento__c = '' + i;
      a.AM_Codigo_DANE_municipio__c = '' + i;
      a.AM_Codigo_SIPRES_departamento__c = '0' + i;
      a.AM_Codigo_SIPRES_municipio__c = '0' + i;
      a.ID_REGION_SAP__c = '' + i;
      a.ID_POBLACION_SAP__c = '' + i;
      municipios.add(a);
    }
    insert municipios;

    return municipios;
  }
  public static map<integer, Account> mapClientesAutosNatural = new Map<integer, Account>();
  public static map<integer, Account> mapClientesAutosJuridico = new Map<integer, Account>();
  public static List<Account> crearCuentasAutos(
    Integer numAccts,
    String recordTypeId
  ) {
    List<Account> cuentas = new List<Account>();
    List<AM_Municipio__c> mun = new List<AM_Municipio__c>();
    mun = crearMunicipios(1);
    RecordType pnRecordType;
    RecordType pjRecordType;
    for (RecordType rt : [
      SELECT id, DeveloperName
      FROM RecordType
      WHERE sobjecttype = 'Account' AND isActive = TRUE
    ]) {
      if (rt.DeveloperName == Label.AutosRecordTypeDevNameAccountNatural)
        pnRecordType = rt;
      if (rt.DeveloperName == Label.AutosRecordTypeDevNameAccountJuridica)
        pjRecordType = rt;
    }

    for (Integer i = 0; i < numAccts; i++) {
      Account a = new Account();

      a.MC_Autoriza_tratardatos_personales__c = 'Si';
      a.Sucursal_activa__c = false;
      a.Phone = String.valueOf(3) + 4 + i + i + i + i + i; //'37623438' + i;
      a.AM_Ciudad__c = mun[0].Id;
      a.DireccionERP__c = 'Dirección' + i;
      a.Sucursal__c = '001';
      a.AM_Estado__c = 'Inactivo';
      a.AM_Tipo_de_usuario__c = 'Cliente Honda';
      a.AccountSource = 'Registro migrado';
      a.AM_Nivel_Socioeconomico__c = '3';
      a.AM_Numero_via_principal__c  = 2;
      a.AM_Numero_via_secundaria__c = 2;
      a.AM_Via_principal__c = 'AV';
      a.Segmentacion2__c = 'Prospecto';
	  a.Creado_en_UNOEE__c = true;
      a.Nivel_educativo__c = 'Ninguno';
      a.Grado_de_escolaridad__c = 'Otro';
      a.Actividad_economica__c = 'Administrativa';
	  a.AM_Ocupacion_pc__c = 'Empleado';
      //Persona Natural
      if (recordTypeId == Label.AutosRecordTypeDevNameAccountNatural) {
        a.AM_Numero_de_documento__c = '25974159' + i;
        a.recordTypeID = pnRecordType.Id;
        a.Salutation = 'Sr.';//'No especificado';
          a.Genero__c	 = 'Masculino'; //y esta creación manual todo el género
          a.AM_Genero__pc = 'Masculino';
          
        a.AM_Tipo_de_documento__c = 'Cédula de ciudadanía';
        a.FirstName = 'Jorge Pablo' + i;
        a.LastName = 'Perez' + i;
        a.Primer_nombre__c = a.FirstName;
        a.Primer_Apellido__c = a.LastName;
        a.Segundo_Apellido__c = 'Josema' + i;
        a.PersonEmail = 'email' + i + '@email.com';
        //a.PersonMobilePhone = '348789542' + i;
        a.PersonBirthdate = Date.newInstance(1997, 12, 30);
        a.AM_Estado_civil__pc = 'Soltero';
        a.Fecha_Fin_Garantia__c = Date.newInstance(2050, 12, 30);
        a.Segmentacion2__c = 'Cliente en Garantía';
        a.Creado_en_UNOEE__c = true;
        mapClientesAutosNatural.put(i, a);
      } else if (recordTypeId == Label.AutosRecordTypeDevNameAccountJuridica) {
        //Persona Jurídica
        a.AM_Numero_de_documento__c = '25974151' + i;
        a.recordTypeID = pjRecordType.Id;
        a.AM_Tipo_de_documento__c = 'NIT';
        a.Name = 'Empresa' + i;
        a.MC_Correo_electronico_Empresa__c = 'email' + i + '@email.com';
        a.Creado_en_UNOEE__c = true;
        mapClientesAutosJuridico.put(i, a);
      }
      cuentas.add(a);
    }
    insert cuentas;

    return cuentas;
  }

  public static map<integer, Account> mapClientesMotosNatural = new Map<integer, Account>();
  public static map<integer, Account> mapClientesMotosJuridico = new Map<integer, Account>();
  public static List<Account> crearClienteMotos(
    String RecordTypeDeveName,
    integer nClientes
  ) {
    RecordType rt = [
      SELECT id, DeveloperName
      FROM RecordType
      WHERE
        sobjecttype = 'Account'
        AND isActive = TRUE
        AND DeveloperName = :RecordTypeDeveName
      LIMIT 1
    ];

    list<Account> lstCuentas = new List<Account>();
    for (integer i = 1; i <= nClientes; i++) {
      Account cuenta = new account(RecordTypeId = rt.Id);
      //cuenta.AM_Tipo_de_documento__c = 'NIT';//'Tarjeta extranjeria'; //code 21  en sap
      cuenta.Phone = String.valueOf(3) + 4 + i + i + i + i + i;
      List<AM_Municipio__c> mun = [SELECT id FROM AM_Municipio__c];
      if (mun.size() == 0)
        mun = crearMunicipios(1);
      cuenta.AM_Ciudad__c = mun[0].Id;
      if (RecordTypeDeveName == Label.MotosRecordTypeDevNameAccountJuridica) {
        cuenta.AM_Tipo_de_documento__c = 'NIT'; //'Tarjeta extranjeria'; //code 21  en sap
        cuenta.Name = 'AcctName' + i;
        cuenta.AM_Numero_de_documento__c = '89020708' + i; //'123456789' + i;
        cuenta.AM_Correo_Electronico_Trabajo__c = 'cgarcia@fastcloudconsulting.com'; //'email' + i + '@mail.com';
        mapClientesMotosJuridico.put(i, cuenta);
      }
      if (RecordTypeDeveName == Label.MotosRecordTypeDevNameAccountNatural) {
        cuenta.AM_Tipo_de_documento__c = 'Tarjeta extranjeria'; //code 21  en sap
        cuenta.AM_Numero_de_documento__c = '1234' + i;
        cuenta.Salutation = 'Sra.';//'Señorita'; //getSalutationSAP_To_SF('0004');
          cuenta.Genero__c	 = 'Masculino'; //y esta creación manual todo el género
          cuenta.AM_Genero__pc = 'Masculino';
          
        cuenta.Primer_Nombre__c = '1erName' + i;
        cuenta.FirstName = cuenta.Primer_Nombre__c;
        cuenta.Segundo_Nombre__c = '2doName' + i;
        cuenta.LastName = '1erLastName' + i;
        cuenta.Primer_Apellido__c = cuenta.LastName;
        cuenta.Segundo_Apellido__c = '2doLastName' + i;
        cuenta.PersonEmail = 'cgarcia@fastcloudconsulting.com';
        mapClientesMotosNatural.put(i, cuenta);
      }
      //cuenta.Codigo_ERP__c = '123'+i+i+i;
      lstCuentas.add(cuenta);
    }
    insert lstCuentas;
    system.debug('Creados ' + lstCuentas.size() + ' en CrearClienteMotos');
    return lstCuentas;
  }

  public static map<integer, Opportunity> mapOpportunitiesMotos = new Map<integer, Opportunity>();
  public static List<Opportunity> crearOportunidadMotos(integer n) {
    RecordType rt = [
      SELECT Id, DeveloperName
      FROM RecordType
      WHERE DeveloperName = :Label.RTOportunidadMotos
    ]; //RTOportunidadAutos para autos
    for (integer i = 1; i <= n; i++) {
      Opportunity op = new Opportunity();
      op.Name = 'Opp ' + i;
      op.AccountId = mapClientesMotosNatural.get(i).Id;
      op.Tipo_de_cliente__c = 'Cliente Honda';
      op.CloseDate = system.today();
      //op.Tipo_de_Pago__c = '107 - E-commerce';//op.Tipo_de_Pago__c = '101 - Contado';
      op.Temperatura_de_la_Compra__c = 'Media';
      op.StageName = '-P0';
      op.RecordTypeId = rt.Id;
      mapOpportunitiesMotos.put(i, op);
    }

    List<Opportunity> lista = mapOpportunitiesMotos.values();
    insert lista;
    return lista;
  }

  public static map<integer, Opportunity> mapOpportunitiesAutos = new Map<integer, Opportunity>();
  public static List<Opportunity> crearOportunidadAutos(integer n) {
    RecordType rt = [
      SELECT Id, DeveloperName
      FROM RecordType
      WHERE DeveloperName = :Label.RTOportunidadAutos
    ];
    for (integer i = 1; i <= n; i++) {
      Opportunity op = new Opportunity();
      op.Name = 'Opp ' + i;
      op.AccountId = mapClientesAutosNatural.get(i - 1).Id;
      //op.AccountId = mapClientesAutosJuridico.get(i).Id;
      op.Tipo_de_cliente__c = 'Cliente Honda';
      op.CloseDate = system.today();
      op.Tipo_de_Pago__c = '101';
      op.AutoNumber__c = '123';
      op.Temperatura_de_la_Compra__c = 'Media';
      op.StageName = '-P0';
      op.RecordTypeId = rt.Id;
      op.CloseDate = Date.newInstance(2010, 12, 30);
      op.Fecha_de_determinacion_del_precio__c = Date.newInstance(2010, 5, 30);
      op.Fecha_de_validez__c = Date.today() + 10;
      op.Tipo_de_Pago__c = '101';
      op.OwnerId = Userinfo.getUserId();
      op.Motivo_de_Oportunidad_Vendida__c = 'Otras';
      op.Averigu_sobre_otras_marcas__c = 'No';
      op.Tipo_de_cliente__c = 'Cliente Honda';
      op.Temperatura_de_la_Compra__c = 'Media';
      op.Amount = 1.1;
      op.Tipo_de_Oportunidad__c = 'Nuevos';
      op.Order_Generated__c = false;
      op.Concesionario__c = mapConcesionarios.get(i).Id;
      op.AutoNumber__c = '123';
      mapOpportunitiesAutos.put(i, op);
    }

    List<Opportunity> lista = mapOpportunitiesAutos.values();
    insert lista;
    return lista;
  }

  public static map<integer, Quote> mapQuotesMotos = new Map<integer, Quote>();
  public static void crearQuoteMotos(integer n) {
    RecordType rt = [
      SELECT Id, DeveloperName
      FROM RecordType
      WHERE DeveloperName = :Label.RTQuoteMotos
    ]; //RTOportunidadAutos para autos
    for (integer i = 1; i <= n; i++) {
      Quote q = new Quote();
      q.Name = 'Quote ' + i;
      q.OpportunityId = mapOpportunitiesMotos.get(i).Id;
      if (mapConcesionarios.containsKey(i))
        q.Concesionario__c = mapConcesionarios.get(i).Id;
      q.RecordTypeId = rt.Id;
      mapQuotesMotos.put(i, q);
    }

    insert mapQuotesMotos.values();
  }
    
  public static map<integer, Quote> mapQuotesAutos = new Map<integer, Quote>();
  public static void crearQuoteAutos(integer n) {
    RecordType rt = [
      SELECT Id, DeveloperName
      FROM RecordType
      WHERE DeveloperName = :Label.RTQuoteAutos
    ]; //RTOportunidadAutos para autos
    for (integer i = 1; i <= n; i++) {
      Quote q = new Quote();
      q.Name = 'Quote ' + i;
      q.OpportunityId = mapOpportunitiesAutos.get(i).Id;
      //if (mapConcesionarios.containsKey(i))
        //q.Concesionario__c = mapConcesionarios.get(i).Id;
      q.RecordTypeId = rt.Id;
      mapQuotesautos.put(i, q);
    }

    insert mapQuotesAutos.values();
  }

  public static map<integer, Concesionario__c> mapConcesionarios = new Map<integer, Concesionario__c>();
  public static void crearConcesionarios(integer n) {
    for (integer i = 1; i <= n; i++) {
      Concesionario__c c = new Concesionario__c();
      c.Name = 'Concesionario ' + i;
      mapConcesionarios.put(i, c);
    }

    insert mapConcesionarios.values();
  }

  public static map<integer, Miembro_de_Concesionario__c> mapMiembroConcesionarios = new Map<integer, Miembro_de_Concesionario__c>();
  public static void crearMiembroConcesionarios(integer n) {
    for (integer i = 1; i <= n; i++) {
      Miembro_de_Concesionario__c mc = new Miembro_de_Concesionario__c();
      mc.Concesionario__c = mapConcesionarios.get(i).Id;
      mc.Nombre_de_asesor__c = UserInfo.getUserId();
      //c.Name = 'Miembro Concesionario ' + i;

      mapMiembroConcesionarios.put(i, mc);
    }
      system.debug(mapMiembroConcesionarios);

    insert mapMiembroConcesionarios.values();
  }

  public static map<integer, Lead> mapLeadMotosNatural = new Map<integer, Lead>();
  public static map<integer, Lead> mapLeadMotosJuridico = new Map<integer, Lead>();
  public static void crearLeadMotos(String RecordTypeDevName, integer nLeads) {
    RecordType rt = [
      SELECT id, DeveloperName
      FROM RecordType
      WHERE
        sobjecttype = 'Lead'
        AND isActive = TRUE
        AND DeveloperName = :RecordTypeDevName
      LIMIT 1
    ];

    list<Lead> lstLeads = new List<Lead>();
    for (integer i = 1; i <= nLeads; i++) {
      Lead lead = new Lead(RecordTypeId = rt.Id);
      lead.Tipo_de_documento__c = 'Tarjeta extranjeria'; //code 21  en sap
      lead.Phone = String.valueOf(3) + 4 + i + i + i + i + i;
      List<AM_Municipio__c> mun = [SELECT id FROM AM_Municipio__c];
      if (mun.size() == 0)
        mun = crearMunicipios(1);
      lead.Ciudad__c = mun[0].Id;
      if (RecordTypeDevName == Label.RTLeadMotosJuridico) {
        //lead.Name = 'AcctName' + i;
        lead.Tipo_de_documento__c = 'NIT'; //code 21  en sap
        lead.Nmero_de_documento__c = '98043657' + i; //'123456789' + i;
        lead.Segundo_nombre__c = '2doName' + i;
        lead.LastName = '1erLastName' + i;
        lead.Company = 'Empresa ' + i;
        mapLeadMotosJuridico.put(i, lead);
      }
      if (RecordTypeDevName == Label.RTLeadMotosNatural) {
        lead.Nmero_de_documento__c = '123456' + i;
        lead.Salutation = 'Señorita'; //getSalutationSAP_To_SF('0004');
        //lead.Primer_Nombre__c = '1erName' + i;
        //lead.FirstName = lead.Primer_Nombre__c;
        lead.Segundo_nombre__c = '2doName' + i;
        lead.LastName = '1erLastName' + i;
        //lead.Primer_Apellido__c = lead.LastName;
        lead.Segundo_Apellido__c = '2doLastName' + i;
        lead.Email = 'email' + i + '@mail.com';
        mapLeadMotosNatural.put(i, lead);
      }
      //lead.Codigo_ERP__c = '123'+i+i+i;
      lstLeads.add(lead);
    }
    insert lstLeads;
    system.debug('Creados ' + lstLeads.size() + ' en CrearClienteMotos');
  }
}