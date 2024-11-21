@IsTest
public class GenOrderPDF_Test {
  private static Map<String, Object> objects = new Map<String, Object>();

  static void makeData() {
    List<Account> accounts = TestDataUtilityClass.crearClienteMotos(
      Label.MotosRecordTypeDevNameAccountNatural,
      1
    );
    Account personaNaturalAccount = accounts[0];

    List<Opportunity> opps = TestDataUtilityClass.crearOportunidadMotos(1);
    Opportunity opp = opps[0];
    objects.put('opportunity', opp);

    Pricebook2 standardPricebook = new Pricebook2(
      Id = Test.getStandardPricebookId(),
      IsActive = true
    );
    update standardPricebook;

    Order order1 = new Order();
    order1.AccountId = personaNaturalAccount.Id;
    order1.Status = 'Draft';
    order1.OpportunityId = opp.Id;
    order1.EffectiveDate = Date.today();
    order1.Pricebook2Id = standardPricebook.Id;
    insert order1;
    objects.put('order', order1);
      
  }

  static void makeDataAutos() {
    List<Account> accounts = TestDataUtilityClass.crearClienteMotos(
      Label.MotosRecordTypeDevNameAccountNatural,
      1
    );
    Account personaNaturalAccount = accounts[0];

    List<Opportunity> opps = TestDataUtilityClass.crearOportunidadMotos(1);
    Opportunity opp = opps[0];
    objects.put('opportunity', opp);

    Pricebook2 standardPricebook = new Pricebook2(
      Id = Test.getStandardPricebookId(),
      IsActive = true
    );
    update standardPricebook;

    Order order1 = new Order();
    order1.AccountId = personaNaturalAccount.Id;
    order1.Status = 'Draft';
    order1.OpportunityId = opp.Id;
    order1.EffectiveDate = Date.today();
    order1.Pricebook2Id = standardPricebook.Id;
    insert order1;
    objects.put('order', order1);
      
  }

  @IsTest
  static void GenOrderPDF() {

    makeData();

    Order order = (Order) objects.get('order');
    Opportunity opp = (Opportunity) objects.get('opportunity');

    // Order order = [SELECT Id FROM Order LIMIT 1];
    // Opportunity opp = [SELECT Id FROM Opportunity LIMIT 1];

    Test.startTest();
    ApexPages.currentPage().getParameters().put('Id', order.id);

    ApexPages.StandardController stdController = new ApexPages.StandardController(
      opp
    );
    new GenOrderPDF(stdController);
    Test.stopTest();
  }
    
  @IsTest
  static void GenOrderPDFAutos() {

      
      User thisUser = [SELECT Id FROM User WHERE Profile.Name = :Label.Autos_Nombre_Perfil_Asesores_Autos AND ManagerId <> null AND IsActive = true LIMIT 1]; 

      TriggerHandler.bypass('AccountTriggerHandler');
      Triggerhandler.bypass('OpportunityTriggerHandler');
      Triggerhandler.bypass('QuoteTriggerHandler');
      Triggerhandler.bypass('TaskTriggerHandler');

      System.runAs ( thisUser ) {

        // Order order = (Order) objects.get('order');
        // Opportunity opp = (Opportunity) objects.get('opportunity');

        TestDataUtilityClass.crearCuentasAutos(1,Label.AutosRecordTypeDevNameAccountNatural);
        TestDataUtilityClass.crearConcesionarios(1);
        TestDataUtilityClass.crearMiembroConcesionarios(1);
        TestDataUtilityClass.crearOportunidadAutos(1);
        
        TestDataUtilityClass.mapOpportunitiesAutos.get(1).Forma_de_pago__c = 'Crédito / Leasing + Retoma';
        TestDataUtilityClass.mapOpportunitiesAutos.get(1).Marca_retoma__c = 'Toyota';
        TestDataUtilityClass.mapOpportunitiesAutos.get(1).Linea_retoma__c = 'Linea retomada';
        TestDataUtilityClass.mapOpportunitiesAutos.get(1).Version_retoma__c = 'version retomada';
        TestDataUtilityClass.mapOpportunitiesAutos.get(1).Modelo_retoma__c = 'modelo retomada';
        TestDataUtilityClass.mapOpportunitiesAutos.get(1).Kilometraje_retoma__c = 1000000;
        TestDataUtilityClass.mapOpportunitiesAutos.get(1).Color_retoma__c = 'Beige';
        TestDataUtilityClass.mapOpportunitiesAutos.get(1).Caja_retoma__c = 'Caja retomada';
        TestDataUtilityClass.mapOpportunitiesAutos.get(1).Tipo_de_carroceria_retoma__c = 'carroceria retomada';
        TestDataUtilityClass.mapOpportunitiesAutos.get(1).Sitio_de_matricula_retoma__c = 'sitio matricula retomada';
        TestDataUtilityClass.mapOpportunitiesAutos.get(1).Placa_retoma__c = 'placa retomada';
        TestDataUtilityClass.mapOpportunitiesAutos.get(1).Avaluado_por_retoma__c = '5 velocidades';
        TestDataUtilityClass.mapOpportunitiesAutos.get(1).Avaluo_retoma__c = 'Avaluo retoma';
        TestDataUtilityClass.mapOpportunitiesAutos.get(1).Contrato_retoma__c = 'Contrato retomado';
            
        update TestDataUtilityClass.mapOpportunitiesAutos.get(1);
        
        Order order = new Order();
        order.AccountId = TestDataUtilityClass.mapClientesAutosNatural.get(0).Id;
        order.Status = 'Draft';
        order.OpportunityId = TestDataUtilityClass.mapOpportunitiesAutos.get(1).ID;
        order.EffectiveDate = Date.today();
        order.Pricebook2Id = Test.getStandardPricebookId();
        insert order;
        
        Test.startTest();
        ApexPages.currentPage().getParameters().put('Id', order.id);
        
        ApexPages.StandardController stdController = new ApexPages.StandardController(
            TestDataUtilityClass.mapOpportunitiesAutos.get(1)
        );
        new GenOrderPDF(stdController);
        
        Test.stopTest();
      }

      // Triggerhandler.clearBypass('OpportunityTriggerHandler');
      // TriggerHandler.clearBypass('AccountTriggerHandler');
      // Triggerhandler.clearBypass('QuoteTriggerHandler');
      // Triggerhandler.clearBypass('TaskTriggerHandler');
  }
    
}