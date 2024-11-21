/**
 * Fanalca
 * @author           Olvin Abarca
 *
 * Changes (Version)
 * -------------------------------------
 *           No.     Date            Author                  Description
 *           -----   ----------      --------------------    ---------------
 * @version  1.0     08/20/2021      Olvin Abarca            Class definition.
 *********************************************************************************************************/
@isTest
private class DatosReporteForecastVentasAutosUsadTest {
  static Map<String, Object> objects = new Map<String, Object>();


  private static RecordType makeDataGetProductRT(Boolean isAutos){
    String productRtDevName = isAutos ? 'Autos' : 'Motos';
    RecordType productRecordType = [
      SELECT Id
      FROM RecordType
      WHERE developerName = :productRtDevName  AND sobjecttype = 'Product2'
      LIMIT 1
    ];

    return productRecordType;
  }

  static void makeDataForAutos() {
    Boolean isAutos = true;
    RecordType productRecordType = makeDataGetProductRT(isAutos);
    // User portalUser = getPortalUser('PowerPartner', null, true);

    TriggerHandler.bypass('AccountTriggerHandler');
    Triggerhandler.bypass('OpportunityTriggerHandler');
    Triggerhandler.bypass('QuoteTriggerHandler');
    Triggerhandler.bypass('TaskTriggerHandler');

    TestDataUtilityClass.crearConcesionarios(1);
    Concesionario__c concesionario = TestDataUtilityClass.mapConcesionarios.get(1);

    Miembro_de_Concesionario__c miembroDeConcesionario = new Miembro_de_Concesionario__c();
    miembroDeConcesionario.Concesionario__c = concesionario.Id;
    miembroDeConcesionario.Nombre_de_asesor__c = UserInfo.getUserId();
    insert miembroDeConcesionario;
    objects.put('miembroDeConcesionario', miembroDeConcesionario);

    List<Account> accounts = TestDataUtilityClass.crearCuentasAutos(
      1,
      Label.AutosRecordTypeDevNameAccountNatural
    );
    Account personaNaturalAccountAutos = accounts[0];
    objects.put('account', personaNaturalAccountAutos);

    List<Opportunity> opps = TestDataUtilityClass.crearOportunidadAutos(1);
    Opportunity oppAutos = opps[0];
    objects.put('opportunity', oppAutos);
  }

  @isTest
  static void runAsAdministrativaAutos() {

    User thisUser = [SELECT Id FROM User WHERE Profile.Name = 'Administrativo autos' AND ManagerId <> null AND IsActive = true LIMIT 1]; 

    System.runAs ( thisUser ) {
      makeDataForAutos();

      Test.startTest();
      DatosReporteForecastVentasAutos instance = new DatosReporteForecastVentasAutos();
      Test.stopTest();
    }
  }

  @isTest
  static void runAsAsesorAutos() {

    User thisUser = [SELECT Id FROM User WHERE Profile.Name = :Label.Autos_Nombre_Perfil_Asesores_Autos AND ManagerId <> null AND IsActive = true LIMIT 1]; 

    Meta_de_Venta__c meta = new Meta_de_Venta__c();
      meta.Cuota__c = 5;
      meta.Asesor__c = thisUser.Id;
      meta.Version__c = 'USADOS';
      insert meta;

    System.runAs ( thisUser ) {
      makeDataForAutos();

      Test.startTest();
      DatosReporteForecastVentasAutosUsados instance = new DatosReporteForecastVentasAutosUsados();
      Test.stopTest();
    }
  }

    @isTest
    static void runAsGerenteAutos() {
  
      User thisUser = [SELECT Id FROM User WHERE Profile.Name = :Label.Autos_Nombre_Perfil_Gerentes_Autos AND ManagerId <> null AND IsActive = true LIMIT 1]; 
  
      System.runAs ( thisUser ) {
        makeDataForAutos();
  
        Test.startTest();
        DatosReporteForecastVentasAutosUsados instance = new DatosReporteForecastVentasAutosUsados();
        Test.stopTest();
      }
    }

    @isTest
    static void runAsOther() {
      
      User thisUser = [SELECT Id FROM User WHERE Profile.Name = 'Administrador mercadeo autos' AND ManagerId <> null AND IsActive = true LIMIT 1]; 
      System.runAs ( thisUser ) {
        makeDataForAutos();
  
        Test.startTest();
        DatosReporteForecastVentasAutosUsados instance = new DatosReporteForecastVentasAutosUsados();
        Test.stopTest();
      }
    }

}