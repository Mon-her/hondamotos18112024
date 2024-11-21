public without sharing class EnviarQuoteHaciaNodriza {
  public static void send(Quote quote, Date quoteExpiration) {
    Http http = new Http();

    String endpoint = quote.Creado_Prolibu__c
      ? 'callout:Prolibu/' + quote.QuoteNumber
      : 'callout:Prolibu';
    String method = quote.Creado_Prolibu__c ? 'PUT' : 'POST';

    HttpRequest request = new HttpRequest();
    request.setEndpoint(endpoint);
    request.setMethod(method);
    request.setTimeout(120000);
    request.setHeader('Content-Type', 'application/json');
    request.setHeader('Authorization', 'Bearer {!$Credential.Password}');
    request.setHeader('Content-Type', 'application/json;charset=UTF-8');

    NodrizaRequestQuote bodyObj = createNodrizaRequestQuote(
      quote,
      quoteExpiration
    );

    String jsonString = JSON.serialize(bodyObj);
    request.setBody(jsonString);

    HttpResponse response = http.send(request);
    String responseString = response.getBody();

    Boolean isOkResponse =
      response.getStatusCode() == 201 ||
      response.getStatusCode() == 200;
    EnviarQuoteHaciaNodriza.NodrizaResponseQuote nodrizaResponseQuote = null;
    if (response.getStatusCode() == 201) {
      nodrizaResponseQuote = (EnviarQuoteHaciaNodriza.NodrizaResponseQuote) JSON.deserialize(
        responseString,
        EnviarQuoteHaciaNodriza.NodrizaResponseQuote.class
      );
    } else if (response.getStatusCode() == 200) {
      List<EnviarQuoteHaciaNodriza.NodrizaResponseQuote> nodrizaResponseQuotes = (List<EnviarQuoteHaciaNodriza.NodrizaResponseQuote>) JSON.deserialize(
        responseString,
        List<EnviarQuoteHaciaNodriza.NodrizaResponseQuote>.class
      );
      nodrizaResponseQuote = nodrizaResponseQuotes[0];
    }

    String urlPrevisualizacion = isOkResponse
      ? nodrizaResponseQuote.anonymousUrl
      : '';
    String urlSeguimiento = isOkResponse ? nodrizaResponseQuote.leadUrl : '';

    Boolean creadoEnProlibu = quote.Creado_Prolibu__c
      ? quote.Creado_Prolibu__c
      : isOkResponse;

    updateQuoteWithNodrizaResponse(
      String.valueOf(quote.Id),
      jsonString,
      responseString,
      urlPrevisualizacion,
      urlSeguimiento,
      creadoEnProlibu
    );
  }

  @future
  public static void updateQuoteWithNodrizaResponse(
    String quoteId,
    String requestString,
    String responseString,
    String anonymousUrl,
    String leadUrl,
    Boolean creadoEnProlibu
  ) {
    // Log__c log = new Log__c();
    // log.body__c = responseString;
    // log.Web_Service__c = 'Enviar Quote a Nodriza';
    // insert log;

    Quote quote = [SELECT Id FROM Quote WHERE Id = :quoteId LIMIT 1];
    quote.Nodriza_URL_pre_visualizaci_n__c = anonymousUrl;
    quote.Nodriza_URL_de_seguimiento__c = leadUrl;
    quote.nodriza_request_json__c = System.Label.saveNodrizaDebugInQuote == 'true' ? requestString : '';
    quote.nodriza_json__c = System.Label.saveNodrizaDebugInQuote == 'true' ? responseString : '';
    quote.Creado_Prolibu__c = creadoEnProlibu;
    update quote;
  }

  public static NodrizaRequestQuote createNodrizaRequestQuote(
    Quote quote,
    Date quoteExpirationDate
  ) {
    Boolean isBusinessAccount =
      quote.opportunity.Account.RecordType.DeveloperName ==
      System.Label.AutosRecordTypeDevNameAccountJuridica;

    NodrizaRequestLead requestLead = new NodrizaRequestLead();
    requestLead.firstName = quote.opportunity.Account.isPersonAccount ? quote.opportunity.Account.FirstName : quote.Opportunity.Contacto__r.FirstName;
    requestLead.lastName = quote.opportunity.Account.isPersonAccount ? quote.opportunity.Account.LastName : quote.Opportunity.Contacto__r.LastName;
    requestLead.email = quote.opportunity.Account.isPersonAccount ? quote.opportunity.Account.PersonEmail : quote.Opportunity.Contacto__r.Email;
    requestLead.assignedTo = quote.opportunity.Owner.Name; ////
    requestLead.companyName = isBusinessAccount
      ? quote.opportunity.Account.Name
      : '';
    requestLead.mobile = isBusinessAccount
      ? quote.opportunity.Account.Phone
      : quote.opportunity.Account.PersonMobilePhone;
    requestLead.taxId = quote.opportunity.Account.AM_Numero_de_documento__c;
    requestLead.street = quote.opportunity.Account.AM_Direccion__c;
    requestLead.city = quote.opportunity.Account.AM_Ciudad__c;

    NodrizaRequestAgentMetadata requestAgentMetadata = new NodrizaRequestAgentMetadata();
    requestAgentMetadata.vitrina = quote.opportunity.Vitrina__r.Name;

    NodrizaRequestAgent requestAgent = new NodrizaRequestAgent();
    requestAgent.firstName = quote.opportunity.Owner.FirstName;
    requestAgent.lastName = quote.opportunity.Owner.LastName;
    requestAgent.position = quote.opportunity.Owner.Title;
    requestAgent.email = quote.opportunity.Owner.Email;
    requestAgent.mobile = quote.opportunity.Owner.MobilePhone;
    //requestAgent.department = quote.opportunity.Concesionario__r.Name;
    requestAgent.street = quote.opportunity.Vitrina__r.Direccion_de_agencia__c;
    requestAgent.city = quote.opportunity.Vitrina__r.Departamento__c;
    requestAgent.metadata = requestAgentMetadata;

    Map<String, String> canonMensual = new Map<String, String>();
    canonMensual.put(
      'opcion1',
      quote.AM_Canon_Renting1__c == null
        ? ''
        : String.valueOf(quote.AM_Canon_Renting1__c)
    );
    canonMensual.put(
      'opcion2',
      quote.AM_Canon_Renting2__c == null
        ? ''
        : String.valueOf(quote.AM_Canon_Renting2__c)
    );
    canonMensual.put(
      'opcion3',
      quote.AM_Canon_Renting3__c == null
        ? ''
        : String.valueOf(quote.AM_Canon_Renting3__c)
    );

    Map<String, String> recoridoKm = new Map<String, String>();
    recoridoKm.put(
      'opcion1',
      quote.AM_Kilometraje_Renting1__c == null
        ? ''
        : String.valueOf(quote.AM_Kilometraje_Renting1__c)
    );
    recoridoKm.put(
      'opcion2',
      quote.AM_Kilometraje_Renting2__c == null
        ? ''
        : String.valueOf(quote.AM_Kilometraje_Renting2__c)
    );
    recoridoKm.put(
      'opcion3',
      quote.AM_Kilometraje_Renting3__c == null
        ? ''
        : String.valueOf(quote.AM_Kilometraje_Renting3__c)
    );

    Map<String, String> plazoMeses = new Map<String, String>();
    plazoMeses.put(
      'opcion1',
      quote.AM_Plazo_Renting1__c == null
        ? ''
        : String.valueOf(quote.AM_Plazo_Renting1__c)
    );
    plazoMeses.put(
      'opcion2',
      quote.AM_Plazo_Renting2__c == null
        ? ''
        : String.valueOf(quote.AM_Plazo_Renting2__c)
    );
    plazoMeses.put(
      'opcion3',
      quote.AM_Plazo_Renting3__c == null
        ? ''
        : String.valueOf(quote.AM_Plazo_Renting3__c)
    );

    Map<String, String> ivas = new Map<String, String>();
    ivas.put(
      'opcion1',
      quote.AM_IVA_Canon_Renting1__c == null
        ? ''
        : String.valueOf(quote.AM_IVA_Canon_Renting1__c)
    );
    ivas.put(
      'opcion2',
      quote.AM_IVA_Canon_Renting2__c == null
        ? ''
        : String.valueOf(quote.AM_IVA_Canon_Renting2__c)
    );
    ivas.put(
      'opcion3',
      quote.AM_IVA_Canon_Renting3__c == null
        ? ''
        : String.valueOf(quote.AM_IVA_Canon_Renting3__c)
    );

    NodrizaRequestDataMetadataRentingContractTipoOpciones requestDataMetadataRentingContractTipoOpciones = new NodrizaRequestDataMetadataRentingContractTipoOpciones();
    requestDataMetadataRentingContractTipoOpciones.canonMensual = canonMensual;
    requestDataMetadataRentingContractTipoOpciones.recoridoKm = recoridoKm;
    requestDataMetadataRentingContractTipoOpciones.plazoMeses = plazoMeses;
    requestDataMetadataRentingContractTipoOpciones.iva = ivas;

    List<String> incluidos = new List<String>();
    if (quote.Servicios_incluidos__c != null) {
      incluidos = quote.Servicios_incluidos__c.split('<br>');
    }

    List<String> adicionales = new List<String>();
    if (quote.AM_Servicios_adicionales__c != null) {
      adicionales = quote.AM_Servicios_adicionales__c.split(';');
    }

    NodrizaRequestDataMetadataRentingContractServicios requestDataMetadataRentingContractServicios = new NodrizaRequestDataMetadataRentingContractServicios();
    requestDataMetadataRentingContractServicios.incluidos = incluidos;
    requestDataMetadataRentingContractServicios.adicionales = adicionales;

    NodrizaRequestDataMetadataRentingContract requestDataMetadataRentingContract = new NodrizaRequestDataMetadataRentingContract();
    requestDataMetadataRentingContract.cantidadVehiculo = Integer.valueOf(
      quote.opportunity.AM_Cantidad_de_vehiculos__c == null
        ? '0'
        : quote.opportunity.AM_Cantidad_de_vehiculos__c + ''
    );
    requestDataMetadataRentingContract.tipo = quote.AM_Tipo_Renting__c;
    requestDataMetadataRentingContract.tipoOpciones = requestDataMetadataRentingContractTipoOpciones;
    requestDataMetadataRentingContract.servicios = requestDataMetadataRentingContractServicios;

    requestDataMetadataRentingContract = (quote.AM_Tipo_Renting__c == null ||
      quote.AM_Tipo_Renting__c == '')
      ? null
      : requestDataMetadataRentingContract;

    NodrizaRequestDataMetadataFinanciacion requestDataMetadataFinanciacion1 = new NodrizaRequestDataMetadataFinanciacion();
    NodrizaRequestDataMetadataFinanciacion requestDataMetadataFinanciacion2 = new NodrizaRequestDataMetadataFinanciacion();

    for (QuoteLineItem oli : quote.QuoteLineItems) {
      requestDataMetadataFinanciacion1.entidadFinanciera = oli.Entidad_Financiera__c;
      requestDataMetadataFinanciacion1.planFinanciero = oli.Plan_Financiero__c;
      requestDataMetadataFinanciacion1.coutaInicial = oli.Cuota_inicial__c;
      requestDataMetadataFinanciacion1.saldoFinanciar = oli.Saldo_a_financiar__c;
      requestDataMetadataFinanciacion1.cuotaMensual = oli.Cuota_mensual__c;
      requestDataMetadataFinanciacion1.plazoMeses = Integer.valueOf(
        oli.Plazo_en_meses__c == null ? '0' : oli.Plazo_en_meses__c + ''
      );
      requestDataMetadataFinanciacion1.tasaInteres = Decimal.valueOf(
        oli.Tasa_de_interes__c == null ? '0' : oli.Tasa_de_interes__c + ''
      );

      requestDataMetadataFinanciacion2.entidadFinanciera = oli.Entidad_Financiera2__c;
      requestDataMetadataFinanciacion2.planFinanciero = oli.Plan_Financiero2__c;
      requestDataMetadataFinanciacion2.coutaInicial = oli.Cuota_inicial2__c;
      requestDataMetadataFinanciacion2.saldoFinanciar = oli.Saldo_a_financiar2__c;
      requestDataMetadataFinanciacion2.cuotaMensual = oli.Cuota_mensual2__c;
      requestDataMetadataFinanciacion2.plazoMeses = Integer.valueOf(
        oli.Plazo_en_meses2__c == null ? '0' : oli.Plazo_en_meses2__c + ''
      );
      requestDataMetadataFinanciacion2.tasaInteres = Decimal.valueOf(
        oli.Tasa_de_interes2__c == null ? '0' : oli.Tasa_de_interes2__c + ''
      );
    }

    NodrizaRequestDataMetadata requestDataMetadata = new NodrizaRequestDataMetadata();
    requestDataMetadata.rentingContract = requestDataMetadataRentingContract;
    requestDataMetadata.financiacion = new List<NodrizaRequestDataMetadataFinanciacion>();

    if (
      (quote.AM_Tipo_Renting__c == null) &&
      requestDataMetadataFinanciacion1.entidadFinanciera != null &&
      requestDataMetadataFinanciacion1.entidadFinanciera != ''
    ) {
      requestDataMetadata.financiacion.add(requestDataMetadataFinanciacion1);
    }

    if (
      (quote.AM_Tipo_Renting__c == null) &&
      requestDataMetadataFinanciacion2.entidadFinanciera != null &&
      requestDataMetadataFinanciacion2.entidadFinanciera != ''
    ) {
      requestDataMetadata.financiacion.add(requestDataMetadataFinanciacion2);
    }

    List<NodrizaRequestDataProduct> products = new List<NodrizaRequestDataProduct>();
    for (QuoteLineItem oli : quote.QuoteLineItems) {
      Product2 product = oli.Product2;

      NodrizaRequestDataProductMetadata requestDataProductMetadata = new NodrizaRequestDataProductMetadata();
      requestDataProductMetadata.name = product.Referencia_comercial__c;
      requestDataProductMetadata.category = (Integer) product.Ano_modelo__c;

      NodrizaRequestDataProduct requestDataProduct = new NodrizaRequestDataProduct();
      requestDataProduct.quantity = (Integer) oli.Quantity;
      requestDataProduct.discountAmount = oli.Descuento_valor__c;
      //   requestDataProduct.price = oli.UnitPrice;
      requestDataProduct.metadata = requestDataProductMetadata;

      products.add(requestDataProduct);
    }

    NodrizaRequestData requestData = new NodrizaRequestData();
    requestData.title = quote.Name;
    requestData.expirationDate = quoteExpirationDate;
    requestData.referenceNumber = quote.opportunity.Id;
    requestData.metadata = requestDataMetadata;
    requestData.products = products;

    NodrizaRequestQuote requestQuote = new NodrizaRequestQuote();
    requestQuote.uuid = quote.QuoteNumber;
    // requestQuote.uuid = 'q' + Integer.valueof((Math.random() * 1000000));
    requestQuote.lead = requestLead;
    requestQuote.agent = requestAgent;
    requestQuote.data = requestData;

    return requestQuote;
  }

  ///////////

  public class NodrizaRequestQuote {
    public String uuid { get; set; }
    public NodrizaRequestLead lead { get; set; }
    public NodrizaRequestAgent agent { get; set; }
    public NodrizaRequestData data { get; set; }
  }

  public class NodrizaRequestLead {
    public String firstName { get; set; }
    public String lastName { get; set; }
    public String email { get; set; }
    public String assignedTo { get; set; }
    public String companyName { get; set; }
    public String mobile { get; set; }
    public String taxId { get; set; }
    public String street { get; set; }
    public String city { get; set; }
  }

  public class NodrizaRequestAgent {
    public String firstName { get; set; }
    public String lastName { get; set; }
    public String position { get; set; }
    public String email { get; set; }
    public String mobile { get; set; }
    // public String department { get; set; }
    public String street { get; set; }
    public String city { get; set; }
    public NodrizaRequestAgentMetadata metadata;
    public NodrizaRequestAgentAvatars avatars;
  }

  public class NodrizaRequestAgentMetadata {
    public String vitrina { get; set; }
  }

  public class NodrizaRequestAgentAvatars {
    public String original { get; set; }
    public String small { get; set; }
    public String large { get; set; }
    public String medium { get; set; }
  }

  public class NodrizaRequestData {
    public String title { get; set; }
    public Date expirationDate { get; set; }
    public String referenceNumber { get; set; }
    public NodrizaRequestDataMetadata metadata { get; set; }
    public List<NodrizaRequestDataProduct> products { get; set; }
  }

  public class NodrizaRequestDataMetadata {
    public NodrizaRequestDataMetadataRentingContract rentingContract {
      get;
      set;
    }
    public List<NodrizaRequestDataMetadataFinanciacion> financiacion {
      get;
      set;
    }
  }

  public class NodrizaRequestDataMetadataRentingContract {
    public Integer cantidadVehiculo { get; set; }
    public String tipo { get; set; }
    public NodrizaRequestDataMetadataRentingContractTipoOpciones tipoOpciones {
      get;
      set;
    }
    public NodrizaRequestDataMetadataRentingContractServicios servicios {
      get;
      set;
    }
  }

  public class NodrizaRequestDataMetadataRentingContractTipoOpciones {
    public Map<String, String> canonMensual { get; set; }
    public Map<String, String> recoridoKm { get; set; }
    public Map<String, String> plazoMeses { get; set; }
    public Map<String, String> iva { get; set; }
  }

  public class NodrizaRequestDataMetadataRentingContractServicios {
    public List<String> incluidos { get; set; }
    public List<String> adicionales { get; set; }
  }

  public class NodrizaRequestDataMetadataFinanciacion {
    public String entidadFinanciera { get; set; }
    public String planFinanciero { get; set; }
    public Decimal coutaInicial { get; set; }
    public Decimal saldoFinanciar { get; set; }
    public Decimal cuotaMensual { get; set; }
    public Integer plazoMeses { get; set; }
    public Decimal tasaInteres { get; set; }
  }

  public class NodrizaRequestDataProduct {
    public Integer quantity { get; set; }
    public Decimal discountAmount { get; set; }
    public NodrizaRequestDataProductMetadata metadata { get; set; }
  }

  public class NodrizaRequestDataProductMetadata {
    public String name { get; set; }
    public Integer category { get; set; }
    public String sku { get; set; }
  }

  public class NodrizaResponseQuote {
    public String uuid { get; set; }
    public NodrizaRequestLead lead { get; set; }
    public NodrizaRequestAgent agent { get; set; }
    public NodrizaRequestData data { get; set; }
    public String createdBy { get; set; }
    public String updatedBy { get; set; }
    public String proposal { get; set; }
    public String anonymousUrl { get; set; }
    public String resolvedUrl { get; set; }
    public String leadUrl { get; set; }
    public String createdAt { get; set; }
    public String updatedAt { get; set; }
    public String id { get; set; }
  }
}