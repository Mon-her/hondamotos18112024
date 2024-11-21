@IsTest
public class OrderPDFController_Test {
  private static Map<String, Object> objects = new Map<String, Object>();

  static void makeDataHelper(Boolean isAutos, Account account, Opportunity opp, RecordType productRT){

    Pricebook2 standardPricebook = new Pricebook2(
      Id = Test.getStandardPricebookId(),
      IsActive = true
    );
    update standardPricebook;

    Pricebook2 pricebk = new Pricebook2();
    pricebk.Name = 'PB test';
    pricebk.IsActive = true;
    insert pricebk;

    Product2 prod = new Product2(
      RecordTypeId = productRT.Id,
      Name = 'Product X',
      ProductCode = 'Pro-X',
      isActive = true
    );
    insert prod;

    if (
      // [
      //   SELECT id
      //   FROM PricebookEntry
      //   WHERE
      //     Product2Id = :prod.Id
      //     AND Pricebook2Id = :Test.getStandardPricebookId()
      // ]
      // .size() == 0
      false
    ) {
      PricebookEntry pbentrySt = new PricebookEntry(
        Pricebook2Id = Test.getStandardPricebookId(),
        Product2Id = prod.Id,
        UnitPrice = 1000,
        IsActive = true
      );
      insert pbentrySt;
    }

    //Create your pricebook entry
    PricebookEntry pbEntry = new PricebookEntry(
      Pricebook2Id = pricebk.Id,
      Product2Id = prod.Id,
      UnitPrice = 100.00,
      IsActive = true
    );
    insert pbEntry;


    OpportunityLineItem oli = new OpportunityLineItem(
      OpportunityId = opp.Id,
      Quantity = 5,
      PricebookEntryId = pbEntry.Id,
      TotalPrice = 5 * pbEntry.UnitPrice
    );

    insert oli;

    Order order1 = new Order();
    order1.AccountId = account.Id;
    order1.Status = 'Draft';
    order1.OpportunityId = opp.Id;
    order1.EffectiveDate = Date.today();
    order1.Pricebook2Id = pricebk.Id;
    order1.OwnerId = UserInfo.getUserId();
    insert order1;
    objects.put('order', order1);
  }

  @TestSetup
  static void makeData() {
    
  }

  @IsTest
  static void OrderPDFControllerMotos() {
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

    List<Account> accounts = TestDataUtilityClass.crearClienteMotos(
      Label.MotosRecordTypeDevNameAccountNatural,
      1
    );
    Account personaNaturalAccountMotos = accounts[0];

    List<Opportunity> opps = TestDataUtilityClass.crearOportunidadMotos(1);
    Opportunity oppMotos = opps[0];

    Boolean isAutos = false;
    

    Test.startTest();
      RecordType productRecordTypesMotos = [
        SELECT Id, DeveloperName
        FROM RecordType
        WHERE sobjecttype = 'Product2' AND 
        DeveloperName = :System.Label.MotosRecordTypeDevNameProduct
        LIMIT 1
      ];
      makeDataHelper(isAutos, personaNaturalAccountMotos, oppMotos, productRecordTypesMotos);

    Order orderMotos = [SELECT Id FROM Order ORDER BY CreatedDate ASC LIMIT 1];

    PageReference pageRef = Page.invoiceRequestMotoTemplate;
    Test.setCurrentPage(pageRef);
    ApexPages.currentPage().getParameters().put('Id', orderMotos.id);

    new OrderPDFController();
    Test.stopTest();
  }


  @IsTest
  static void OrderPDFControllerAutos() {
    TriggerHandler.bypass('AccountTriggerHandler');
    Triggerhandler.bypass('OpportunityTriggerHandler');
    Triggerhandler.bypass('QuoteTriggerHandler');
    Triggerhandler.bypass('TaskTriggerHandler');

    User thisUser = [SELECT Id FROM User WHERE Profile.Name = :Label.Autos_Nombre_Perfil_Asesores_Autos AND IsActive = true LIMIT 1]; 

    System.runAs ( thisUser ) { 

      RecordType productRecordTypesAutos = [
        SELECT Id, DeveloperName
        FROM RecordType
        WHERE sobjecttype = 'Product2' AND 
        DeveloperName = :System.Label.AutosRecordTypeDevNameProduct
        LIMIT 1
      ];

      TestDataUtilityClass.crearConcesionarios(1);

      List<Account> accounts = TestDataUtilityClass.crearCuentasAutos(
        1,
        Label.AutosRecordTypeDevNameAccountNatural
      );
      Account personaNaturalAccountAutos = accounts[0];

      Concesionario__c concesionario = TestDataUtilityClass.mapConcesionarios.get(1);

      Miembro_de_Concesionario__c miembroDeConcesionario = new Miembro_de_Concesionario__c();
      miembroDeConcesionario.Concesionario__c = concesionario.Id;
      miembroDeConcesionario.Nombre_de_asesor__c = UserInfo.getUserId();
      insert miembroDeConcesionario;

      Test.startTest();

      List<Opportunity> opps = TestDataUtilityClass.crearOportunidadAutos(1);
      Opportunity oppAutos = opps[0];

      Boolean isAutos = true;
      makeDataHelper(isAutos, personaNaturalAccountAutos, oppAutos, productRecordTypesAutos);

      // Order orderAutos = [SELECT Id, OwnerId FROM Order ORDER BY CreatedDate DESC LIMIT 1];
      Order orderAutos = (Order) objects.get('order');
      
      PageReference pageRef = Page.invoiceRequestAutoTemplate;
      Test.setCurrentPage(pageRef);
      ApexPages.currentPage().getParameters().put('Id', orderAutos.id);

      new OrderPDFController();

      Test.stopTest();
    }
    
    
    
  }
}