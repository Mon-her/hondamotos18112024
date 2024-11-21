/**
 * Fanalca
 * @author           Olvin Abarca
 * Description:      Class that provides product/inventory information from SAP
 *
 * Changes (Version)
 * -------------------------------------
 *           No.     Date            Author                  Description
 *           -----   ----------      --------------------    ---------------
 * @version  1.0     1/12/2020      Olvin Abarca            Class definition.
 *********************************************************************************************************/
public class AM_ConsultarInventario {
  public static final String RESPONSE_OK = 'OK';
  public static final String RESPONSE_ERR = 'ERR';

  @AuraEnabled(cacheable=true)
  public static Map<String, Object> init() {
    String userId = UserInfo.getUserId();
    String userProfileId = UserInfo.getProfileId();
    Miembro_de_Concesionario__c miembroDeConcesionario = getMiembroDeConcesionarioFor(
      userId
    );

    Profile profile = getProfileById(userProfileId);

    boolean isEditor = isUserAnEditor(profile, userId);
    Boolean isAutosProfile = isAutosProfile(profile);

    Map<String, Object> returns = new Map<String, Object>();
    returns.put('Miembro_de_Concesionario__c', miembroDeConcesionario);
    returns.put('ProfileId', userProfileId);
    returns.put('isEditor', isEditor);
    returns.put('isAutosProfile', isAutosProfile);

    if (isAutosProfile) {
      List<PricebookEntry> autosPricebookEntries = getAutosPricebookEntries();
      returns.put('autosPricebookEntries', autosPricebookEntries);
    }

    return returns;
  }

  private static boolean isUserAnEditor(Profile profile, String userId) {
    String[] editorProfileNames = Label.consultarInventarioEditores.split(';');
    boolean isEditor = arrayContains(editorProfileNames, profile.Name);
    return isEditor;
  }

  private static Profile getProfileById(String profileId) {
    return [SELECT Name FROM Profile WHERE Id = :profileId LIMIT 1];
  }

  private static boolean arrayContains(Object[] source, Object target) {
    return (new Set<Object>(source)).contains(target);
  }

  private static Miembro_de_Concesionario__c getMiembroDeConcesionarioFor(
    String userId
  ) {
    try {
      return [
        SELECT Id, Concesionario__c, Name
        FROM Miembro_de_Concesionario__c
        WHERE Nombre_de_asesor__c = :userId
        LIMIT 1
      ];
    } catch (Exception ex) {
      System.debug('ex: ' + ex.getMessage());
    }
    return null;
  }

  @AuraEnabled(cacheable=true)
  public static QueryResponse consultar(
    String productoId,
    String concesionarioId,
    String dateString
  ) {
    Profile profile = [
      SELECT Id, Name
      FROM Profile
      WHERE Id = :UserInfo.getProfileId()
      LIMIT 1
    ];

    Boolean isAutosProfile = isAutosProfile(profile);

    Product2 product = getProductById(productoId);

    if ((product == null || product.ProductCode == null) && !isAutosProfile) {
      return new QueryResponse(
        RESPONSE_ERR,
        'Código del producto está vacio',
        null,
        null
      );
    }

    String productCode = (product == null ||
      product.ProductCode == null)
      ? ''
      : product.ProductCode;
    String extension1 = '';
    String extension2 = '';
    String extension3 = '';
    String extension4 = '';
    String extension5 = '';
    String endpoint = Label.EndpointConsultarInventario;

    if (isAutosProfile) {
      productCode = '';
      extension1 = 'X';
      extension2 = (product == null ||
        product.Referencia_comercial__c == null)
        ? ''
        : product.Referencia_comercial__c;
      endpoint = Label.EndpointConsultarInventarioAutos;
    }

    String newDateString = reformatDateString(dateString);

    String codigoDeConcesionario = '';
    if (concesionarioId != null && concesionarioId != '') {
      Concesionario__c concesionario = getConcesionarioBy(concesionarioId);
      codigoDeConcesionario = concesionario.Codigo_concesionario__c;
    }

    List<QueryResponseItem> results = sendOutboundRequest(
      productCode,
      codigoDeConcesionario,
      newDateString,
      extension1,
      extension2,
      extension3,
      extension4,
      extension5,
      endpoint
    );

    QueryResponse response = new QueryResponse();

    if (results == null) {
      response.code = RESPONSE_ERR;
      response.msg = isAutosProfile
        ? 'El Vehículo no tiene existencias en el inventario'
        : 'SAP no regresó información para estos filtos (productCode = ' +
          productCode +
          ', extension2 = ' +
          extension2 +
          ', concesionario = ' +
          codigoDeConcesionario +
          ')';
      response.total = 0;
    } else {
      results = removeProductsWithZeroAvailability(results);

      results = attachConcesionarioName(results, codigoDeConcesionario);

      response.code = RESPONSE_OK;
      response.msg = '';
      response.total = results.size();
      response.results = results;
    }

    return response;
  }

  public static boolean isAutosProfile(Profile profile) {
    Boolean isAutosProfile =
      profile.Name.indexOf('Autos') > -1 ||
      profile.Name.indexOf('autos') > -1;
    return isAutosProfile;
  }

  private static List<QueryResponseItem> removeProductsWithZeroAvailability(
    List<QueryResponseItem> results
  ) {
    List<QueryResponseItem> filteredList = new List<QueryResponseItem>();
    for (QueryResponseItem queryResponseItem : results) {
      String unidades = queryResponseItem.unidades;

      if (unidades.trim() != '0' && unidades.trim() != '0.000') {
        filteredList.add(queryResponseItem);
      }
    }
    return filteredList;
  }

  private static List<QueryResponseItem> attachConcesionarioName(
    List<QueryResponseItem> results,
    String codigoDeConcesionario
  ) {
    List<Concesionario__c> listaDeConcesionarios = getConcesionarioById(
      codigoDeConcesionario
    );
    Map<String, Concesionario__c> mapaDeConcesionarios = createConcesionarioMapFromList(
      listaDeConcesionarios
    );

    for (QueryResponseItem queryResponseItem : results) {
      Concesionario__c concesionario = (Concesionario__c) mapaDeConcesionarios.get(
        queryResponseItem.agenciaCodigo
      );

      String agenciaNombre = queryResponseItem.agenciaCodigo;
      if (concesionario != null) {
        agenciaNombre = concesionario.Agencia__c;
      }
      queryResponseItem.agenciaNombre = agenciaNombre;
    }

    return results;
  }

  private static List<Concesionario__c> getConcesionarioById(
    String codigoDeConcesionario
  ) {
    return [
      SELECT
        Id,
        Agencia__c,
        Asesores_comerciales__c,
        CreatedById,
        Codigo_concesionario__c,
        Codigo_de_agencia__c,
        Departamento__c,
        Descripcion__c,
        Direccion_de_agencia__c,
        LastModifiedById,
        Name,
        OwnerId,
        Region__c,
        Telefono__c,
        Zona__c
      FROM Concesionario__c
    ];
  }

  private static Map<String, Concesionario__c> createConcesionarioMapFromList(
    List<Concesionario__c> listaDeConcesionarios
  ) {
    Map<String, Concesionario__c> mapaDeConcesionarios = new Map<String, Concesionario__c>();
    for (Concesionario__c concesionario : listaDeConcesionarios) {
      mapaDeConcesionarios.put(
        concesionario.Codigo_de_agencia__c,
        concesionario
      );
    }
    return mapaDeConcesionarios;
  }

  private static Product2 getProductById(String productoId) {
    if (productoId == '' || productoId == null) {
      return null;
    }

    return [
      SELECT Id, Name, ProductCode, Version__c, Referencia_comercial__c
      FROM Product2
      WHERE Id = :productoId
      LIMIT 1
    ];
  }

  private static List<QueryResponseItem> sendOutboundRequest(
    String productoCode,
    String codigoDeConcesionario,
    String dateString,
    String ext1,
    String ext2,
    String ext3,
    String ext4,
    String ext5,
    String endpoint
  ) {
    AM_ConsultarInventarioSoapWs.DT_MS_RESPONSE response;

    String MATNR = productoCode;
    String WERKS = codigoDeConcesionario;
    String DATLO = dateString;
    String EXTENSION1 = ext1;
    String EXTENSION2 = ext2;
    String EXTENSION3 = ext3;
    String EXTENSION4 = ext4;
    String EXTENSION5 = ext5;

    AM_ConsultarInventarioSoapWs.HTTPS_Port HTTPSPort = new AM_ConsultarInventarioSoapWs.HTTPS_Port();
    AM_ConsultarInventarioSoapWs.DT_MS_RESPONSE serviceResponse = HTTPSPort.GET(
      MATNR,
      WERKS,
      DATLO,
      EXTENSION1,
      EXTENSION2,
      EXTENSION3,
      EXTENSION4,
      EXTENSION5,
      endpoint
    );

    List<QueryResponseItem> results = new List<QueryResponseItem>();

    if (serviceResponse.Row != null) {
      for (AM_ConsultarInventarioSoapWs.Row row : serviceResponse.Row) {
        QueryResponseItem responseItem = new QueryResponseItem();
        responseItem.codigo = row.MATNR;
        responseItem.agenciaCodigo = row.WERKS;
        responseItem.segmento = row.SEGMENT;
        responseItem.referencia = row.MKTXT;
        responseItem.anioModelo = row.MODELO;
        responseItem.color = row.COLOR;
        responseItem.linea = row.LINEA;
        responseItem.ubicacion = (row.LGORT != null &&
          row.LGORT != '')
          ? row.LGORT
          : row.UBICACION;
        responseItem.unidades = row.LABTS;

        responseItem.vinInterno = row.VH;
        responseItem.nombreComercial = row.H99;
        responseItem.chasis = row.CHASIS;
        responseItem.motor = row.MOTOR;
        responseItem.estado = row.ESTADO;
        responseItem.diasInventario = row.DIAS_INVENTARIO;
        responseItem.diasSeparacion = row.DIAS_SEPARACION;
        responseItem.descripcion = row.H30;
        responseItem.familia = row.H40;
        responseItem.disponible = row.ESTADO == 'DISPONIBLE' ? '1' : '0';
        responseItem.comprometido = row.ESTADO == 'SEPARADO' ? '1' : '0';

        results.add(responseItem);
      }

      return results;
    }

    return null;
  }

  public static List<PricebookEntry> getAutosPricebookEntries() {
    map<String, PricebookEntry> mapPBE = new map<String, PricebookEntry>();
    
    for (PricebookEntry pbe: [SELECT Product2.Id, Product2.Name, Product2.Referencia_Comercial__c FROM PricebookEntry WHERE Pricebook2.Name = 'Autos' AND IsActive = TRUE order by Product2.Referencia_Comercial__c asc]){
        mapPBE.put(pbe.Product2.Referencia_Comercial__c, pbe);
    }
    
    return mapPBE.values();
    /*
    return [
      SELECT Product2.Id, Product2.Name, Product2.Referencia_Comercial__c
      FROM PricebookEntry
      WHERE Pricebook2.Name = 'Autos' AND IsActive = TRUE
    ];*/
  }

  private static String reformatDateString(String isoDateString) {
    String[] parts = isoDateString.split('-');
    String newDateString = parts[2] + '.' + parts[1] + '.' + parts[0];
    return newDateString;
  }

  private static Concesionario__c getConcesionarioBy(String concesionarioId) {
    return [
      SELECT Id, Codigo_concesionario__c
      FROM Concesionario__c
      WHERE Id = :concesionarioId
      LIMIT 1
    ];
  }

  public class QueryResponse {
    @AuraEnabled
    public String code;
    @AuraEnabled
    public String msg;
    @AuraEnabled
    public List<Object> results;
    @AuraEnabled
    public Integer total;

    public QueryResponse() {
    }
    public QueryResponse(
      String code,
      String msg,
      List<Object> results,
      Integer total
    ) {
      this.code = code;
      this.msg = msg;
      this.results = results;
      this.total = total;
    }
  }

  public class QueryResponseItem {
    @AuraEnabled
    public String codigo;
    @AuraEnabled
    public String agenciaCodigo;
    @AuraEnabled
    public String agenciaNombre;
    @AuraEnabled
    public String segmento;
    @AuraEnabled
    public String referencia;
    @AuraEnabled
    public String anioModelo;
    @AuraEnabled
    public String color;
    @AuraEnabled
    public String linea;
    @AuraEnabled
    public String ubicacion;
    @AuraEnabled
    public String unidades;

    @AuraEnabled
    public String vinInterno;
    @AuraEnabled
    public String nombreComercial;
    @AuraEnabled
    public String chasis;
    @AuraEnabled
    public String motor;
    @AuraEnabled
    public String estado;
    @AuraEnabled
    public String diasInventario;
    @AuraEnabled
    public String diasSeparacion;
    @AuraEnabled
    public String descripcion;
    @AuraEnabled
    public String disponible;
    @AuraEnabled
    public String comprometido;
    @AuraEnabled
    public String familia;
  }
}