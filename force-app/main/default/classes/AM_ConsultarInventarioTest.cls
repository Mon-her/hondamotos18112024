@isTest
public class AM_ConsultarInventarioTest {
  private static Map<String, Object> objects = mock();

  private static Map<String, Object> mock() {
    Map<String, Object> objects = new Map<String, Object>();

    Concesionario__c concesionario = new Concesionario__c();
    concesionario.Name = 'Concesionario 1';
    concesionario.Codigo_de_agencia__c = 'CodigoAgencia';
    concesionario.Codigo_concesionario__c = 'CONC1';
    insert concesionario;
    objects.put('concesionario', concesionario);

    Miembro_de_Concesionario__c miembroDeConcesionario = new Miembro_de_Concesionario__c();
    miembroDeConcesionario.Concesionario__c = concesionario.Id;
    miembroDeConcesionario.Nombre_de_asesor__c = UserInfo.getUserId();
    insert miembroDeConcesionario;
    objects.put('miembroDeConcesionario', miembroDeConcesionario);

    RecordType recordTypeMoto = [
      SELECT Id
      FROM RecordType
      WHERE developerName = 'Motos' AND sobjecttype = 'Product2'
      LIMIT 1
    ];
    Product2 product1 = new Product2(Name = 'Product Name');
    product1.RecordTypeId = recordTypeMoto.Id;
    product1.productCode = 'PCODE1';
    insert product1;
    objects.put('product1', product1);

    return objects;
  }

  @isTest
  private static void init() {
    Map<String, Object> results = AM_ConsultarInventario.init();
    Miembro_de_Concesionario__c miembroDeConcesionario = (Miembro_de_Concesionario__c) objects.get(
      'miembroDeConcesionario'
    );

    Miembro_de_Concesionario__c miembroDeConcesionarioRefresh = (Miembro_de_Concesionario__c) results.get(
      'Miembro_de_Concesionario__c'
    );
    System.assert(
      miembroDeConcesionario.Id == miembroDeConcesionarioRefresh.Id,
      true
    );

    Boolean isEditor = (Boolean) results.get('isEditor');
    System.assert(isEditor, true);
  }

  @isTest
  private static void consultar() {
    Test.startTest();

    Test.setMock(WebServiceMock.class, new AM_ConsultarInventarioSoapWsMock());

    Product2 product1 = (Product2) objects.get('product1');
    Miembro_de_Concesionario__c miembroDeConcesionario = (Miembro_de_Concesionario__c) objects.get(
      'miembroDeConcesionario'
    );
    String productoId = String.valueOf(product1.Id);
    String concesionarioId = miembroDeConcesionario.Concesionario__c;
    String dateString = '2020-11-30';

    AM_ConsultarInventario.QueryResponse queryResponse = AM_ConsultarInventario.consultar(
      productoId,
      concesionarioId,
      dateString
    );

    System.assert(queryResponse.code != null, true);

    Test.stopTest();
  }
}