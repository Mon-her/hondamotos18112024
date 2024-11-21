/**
 * Fast Cloud Consulting
 * @author           Olvin Abarca
 * Description:      Custom controller class to query the required fields to be displayed on the PDF quote.
 */
public class QuotePDFController {
  public DatosDelCliente datosDelCliente { get; set; }
  public Date quoteExpirationDate { get; set; }
  public Miembro_de_Concesionario__c miembroDeConcesionario { get; set; }
  public List<QuotePDFDetail> quotePDFDetails { get; set; }
  public list<Product2> lstProductsUpdate { get; set; }
  public boolean isAutosMostrarPlanFinanciacion { get; set; }
  public String nombreCompletoComprador { get; set; }
  public String nombreCompletoPagador { get; set; }
  public String nombreCompletoTitularPrendario { get; set; }
  public String nombreCompletoFacturaANombreDe { get; set; }
  public Boolean isCommunityProfile { get; set; }
  public Boolean isOpportunityAutos { get; set; }
  public WrpGatantia wrpGatantiaP   { get; set; }

  public QuotePDFController() {
    this.quotePDFDetails = new List<QuotePDFDetail>();
    this.init();
  }
  /****************************************************************
   * DEVELOPER NAME : "Honda_CR_V" y "HR_V" 
   *************************************************************/
  public WrpGatantia GetTextoGarantia( string sProductName ){
      WrpGatantia oWrpGatanti = new WrpGatantia();
      string sGarantia = '';
      map< string, AFOG_GatantiaText__mdt > mapGarantia = new map< string, AFOG_GatantiaText__mdt >();
      list< AFOG_GatantiaText__mdt > lstGarantia = [ SELECT ID,DeveloperName,AFOG_Garantia__c FROM AFOG_GatantiaText__mdt ];
      for( AFOG_GatantiaText__mdt varGAT: lstGarantia ){
          mapGarantia.put( varGAT.DeveloperName,  varGAT);
      }
      //logo rojo
      if( sProductName.contains('CR-V') || sProductName.contains('PILOT ') || sProductName.contains('ACCORD ')  ){
        oWrpGatanti.sGarantia = mapGarantia.get('Honda_CR_V').AFOG_Garantia__c;
        oWrpGatanti.logoURL =  PageReference.forResource('AFOG_GatantiaLogoRojo').getUrl()+'/path/AFOG_GatantiaLogoRojo.png';
      }
      // logo azul
      else if( sProductName.contains('HR-V') || sProductName.contains('CITY') || sProductName.contains('WR-V') ){
        oWrpGatanti.sGarantia = mapGarantia.get('HR_V').AFOG_Garantia__c;
        oWrpGatanti.logoURL =  PageReference.forResource('AO_GarantiaHondaLogoAzul').getUrl()+'/path/AO_GarantiaHondaLogoAzul.png';
      }
      // logo y texto antiguo
      else{
        oWrpGatanti.sGarantia = system.label.RM_GarantiaHondaLBL;
        oWrpGatanti.logoURL =  PageReference.forResource('AO_GarantiaTotal').getUrl()+'/path/AO_GarantiaTotal.png';
      }
      return oWrpGatanti;
  }


  public List<QuotePDFDetail> init() {
    lstProductsUpdate = new List<Product2>();

    String quoteId = ApexPages.currentPage().getParameters().get('id');
    // String quoteId = quote.Id;

    Profile profile = [
      SELECT Name
      FROM Profile
      WHERE Id = :UserInfo.getProfileId()
      LIMIT 1
    ];
    this.isCommunityProfile = GenQuotePDF.isCommunityProfile(profile);

    List<QuoteLineItem> quoteLineItems = [
      SELECT
        Id,
        //
        QuoteId,
        Quote.QuoteNumber,
        Quote.CreatedDate,
        Quote.DescuentoApro__c,
        Quote.Account.AM_Numero_de_documento__c,
        Quote.Account.Name,
        Quote.Account.Phone,
        Quote.Account.PersonOtherPhone,
        Quote.Account.PersonEmail,
        Quote.Account.AM_Correo_Electronico_Trabajo__c,
        Quote.Account.AM_Direccion__c,
        Quote.GrandTotal,
        // TODO: these fields will probably be disallowed for motos profile users
        Quote.AM_Canon_Renting1__c,
        Quote.AM_Plazo_Renting1__c,
        Quote.AM_Kilometraje_Renting1__c,
        Quote.AM_IVA_Canon_Renting1__c,
        Quote.AM_Canon_Renting2__c,
        Quote.AM_Plazo_Renting2__c,
        Quote.AM_Kilometraje_Renting2__c,
        Quote.AM_IVA_Canon_Renting2__c,
        Quote.AM_Canon_Renting3__c,
        Quote.AM_Plazo_Renting3__c,
        Quote.AM_Kilometraje_Renting3__c,
        Quote.AM_IVA_Canon_Renting3__c,
        Quote.AM_Tipo_Renting__c,
        //
        Quote.Opportunity.Owner.Name,
        Quote.Opportunity.Owner.Email,
        Quote.Opportunity.Owner.MobilePhone,
        //
        Quote.Opportunity.Account.Datos_Autorizacion_Web__pc,
        Quote.Opportunity.Account.MC_Autoriza_tratardatos_personales__c,
        Quote.Opportunity.Forma_de_pago__c,
        Quote.Opportunity.Servicios_incluidos_Renting__c, // autos
        Quote.Opportunity.AM_Servicios_adicionales__c, // autos
        //
        Quote.Opportunity.Contacto__r.Account.AM_Numero_de_documento__c,
        Quote.Opportunity.Contacto__r.Name,
        Quote.Opportunity.Contacto__r.Account.AM_Direccion__c,
        Quote.Opportunity.Contacto__r.AM_Numero_de_documento_contacto__c,
        Quote.Opportunity.Contacto__r.Direccion__c,
        Quote.Opportunity.Contacto__r.Phone,
        Quote.Opportunity.Contacto__r.OtherPhone,
        Quote.Opportunity.Contacto__r.MobilePhone,
        Quote.Opportunity.Contacto__r.Email,
        //
        Quote.opportunity.RecordType.DeveloperName,
        Quote.Opportunity.Account.RecordType.DeveloperName,
        Quote.Opportunity.Account.Name,
        Quote.Opportunity.Account.FirstName,
        Quote.Opportunity.Account.Segundo_Nombre__c,
        Quote.Opportunity.Account.LastName,
        Quote.Opportunity.Account.Segundo_Apellido__c,
        Quote.Opportunity.Account.AM_Numero_de_documento__c,
        Quote.Opportunity.Account.Phone,
        Quote.Opportunity.Account.PersonOtherPhone,
        Quote.Opportunity.Account.AM_Direccion__c,
        Quote.Opportunity.Account.PersonEmail,
        Quote.Opportunity.Account.PersonMobilePhone,
        //
        Quote.Opportunity.Pagador__r.Name,
        Quote.Opportunity.Pagador__r.RecordType.DeveloperName,
        Quote.Opportunity.Pagador__r.MC_Direccion_completa__c,
        Quote.Opportunity.Pagador__r.AM_Ciudad__r.Name,
        Quote.Opportunity.Pagador__r.PersonHomePhone,
        Quote.Opportunity.Pagador__r.PersonMobilePhone,
        Quote.Opportunity.Pagador__r.FirstName,
        Quote.Opportunity.Pagador__r.LastName,
        Quote.Opportunity.Pagador__r.AM_Numero_de_documento__c,
        Quote.Opportunity.Pagador__r.Primer_nombre__c,
        Quote.Opportunity.Pagador__r.Segundo_Nombre__c,
        Quote.Opportunity.Pagador__r.Primer_apellido__c,
        Quote.Opportunity.Pagador__r.Segundo_Apellido__c,
        //
        Quote.Opportunity.Titular_prendario__r.Name,
        Quote.Opportunity.Titular_prendario__r.RecordType.DeveloperName,
        Quote.Opportunity.Titular_prendario__r.MC_Direccion_completa__c,
        Quote.Opportunity.Titular_prendario__r.AM_Ciudad__r.Name,
        Quote.Opportunity.Titular_prendario__r.PersonHomePhone,
        Quote.Opportunity.Titular_prendario__r.PersonMobilePhone,
        Quote.Opportunity.Titular_prendario__r.FirstName,
        Quote.Opportunity.Titular_prendario__r.LastName,
        Quote.Opportunity.Titular_prendario__r.Primer_nombre__c,
        Quote.Opportunity.Titular_prendario__r.Segundo_Nombre__c,
        Quote.Opportunity.Titular_prendario__r.Primer_apellido__c,
        Quote.Opportunity.Titular_prendario__r.Segundo_Apellido__c,
        Quote.Opportunity.Titular_prendario__r.AM_Numero_de_documento__c,
        //
        Quote.Opportunity.Facturar_a_nombre_de__r.Name,
        Quote.Opportunity.Facturar_a_nombre_de__r.AM_Direccion__c,
        Quote.Opportunity.Facturar_a_nombre_de__r.RecordType.DeveloperName,
        Quote.Opportunity.Facturar_a_nombre_de__r.MC_Direccion_completa__c,
        Quote.Opportunity.Facturar_a_nombre_de__r.AM_Ciudad__r.Name,
        Quote.Opportunity.Facturar_a_nombre_de__r.PersonHomePhone,
        Quote.Opportunity.Facturar_a_nombre_de__r.PersonMobilePhone,
        Quote.Opportunity.Facturar_a_nombre_de__r.FirstName,
        Quote.Opportunity.Facturar_a_nombre_de__r.LastName,
        Quote.Opportunity.Facturar_a_nombre_de__r.Primer_nombre__c,
        Quote.Opportunity.Facturar_a_nombre_de__r.Segundo_Nombre__c,
        Quote.Opportunity.Facturar_a_nombre_de__r.Primer_apellido__c,
        Quote.Opportunity.Facturar_a_nombre_de__r.Segundo_Apellido__c,
        Quote.Opportunity.Facturar_a_nombre_de__r.AM_Numero_de_documento__c,
        Quote.Opportunity.Facturar_a_nombre_de__r.PersonEmail,
        Quote.Opportunity.Facturar_a_nombre_de__r.Phone,
        //
        Product2.DisplayUrl,
        Product2.Name,
        Product2.Beneficios__c,
        Product2.Beneficios2__c,
        Product2.Beneficios3__c,
        Product2.Beneficios4__c,
        Product2.Motor__c,
        Product2.Cilindraje__c,
        Product2.Arranque__c,
        Product2.Dimensiones__c,
        Product2.Peso_en_seco__c,
        Product2.Certificacion__c,
        Product2.Potencia_max__c,
        Product2.Transmision__c,
        Product2.Caja__c,
        Product2.Modelo_Ao__c,
        Product2.Ano_modelo__c,
        Product2.Color__c,
        Product2.Placa__c,
        Product2.Marca__c,
        Product2.Version__c,
        Product2.Kilometraje__c,
        Product2.Ciudad_de_la_placa__r.Name,
        Product2.Linea_version__c,
        Product2.Linea__c,
        Product2.Frenado_autom_tico_de_emergencia__c,
        Product2.Control_Electr_de_Estabilidad__c,
        Product2.Sistema_Antibloqueo_Frenos__c,
        Product2.Sistema_de_bolsa_de_aire__c,
        Product2.Sistema_de_sujecion_infantil__c,
        Product2.Alerta_de_colisi_n_frontal__c,
        Product2.Numero_de_bolsas_de_aire__c,
        Product2.Referencia_comercial__c,
        //
        Entidad_Financiera__c,
        Entidad_Financiera2__c,
        ListPrice,
        UnitPrice,
        SO_Valor_Porcentaje_ARD__c,
        Descuento_aplicado_antes_de_impuesto__c,
        Observaciones__c,
        Valor_soat__c,
        Casco__c,
        Accesorios__c,
        Valor_matrcula__c,
        Descuento_Valor__c,
        DescValARD__c,
        Valor_seguro_robo__c,
        Quantity,
        Total_a_Pagar__c,
        Quote.Observaciones__c,
        Product2.La_motocicleta_se_entregan_con__c,
        TYPEOF Quote.Owner
          WHEN User THEN Name, Email, Phone, MobilePhone
          WHEN Group THEN Name, Email
        END,
        Quote.ExpirationDate,
        FinancieraPlan__c,
        Valor_Vehculo__c,
        Valor_Vehculo2__c,
        Cuota_Inicial__c,
        Cuota_inicial2__c,
        Saldo_a_financiar__c,
        Saldo_a_financiar2__c,
        Plazo_en_meses__c,
        Plazo_en_meses2__c,
        Cuota_mensual__c,
        Cuota_mensual2__c,
        Tasa_de_interes__c,
        Tasa_de_interes2__c,
        Product2.SO_Garantia_motocicleta__c
      FROM QuoteLineItem
      WHERE QuoteId = :quoteId
    ];

    
    this.datosDelCliente = new DatosDelCliente();

    Id ownerId = null;
    DateTime quoteCreatedDate = null;
    Integer index = 0;

    List<String> lstProductNoURLNames = new List<String>(); //Lista de nombres de los productos que no tienen displayURL
    for (QuoteLineItem quoteLineItem : quoteLineItems) {
      wrpGatantiaP =  GetTextoGarantia( quoteLineItem.Product2.Name );
      if (quoteLineItem.Product2.DisplayURL == null){        
        lstProductNoURLNames.add(quoteLineItem.Product2.Name);
      }
    }
    //Get the urls for products that don't have displayurl field filled, and update these products
    system.debug(lstProductNoURLNames);
    Map<String, String> mapProductsURLs = new Map<String, String>(); //mapa de nombres de productos sin display url con valor su url de imagen

    if (lstProductNoURLNames.size() > 0) {
      mapProductsURLs = QuotePdfController.generarURLs(lstProductNoURLNames);
    }

    isAutosMostrarPlanFinanciacion = false;

    String regExp = '\\s*null\\s*';
    String replacement = ' ';

    for (QuoteLineItem quoteLineItem : quoteLineItems) {

      this.isOpportunityAutos = quoteLineItem.quote.opportunity.RecordType.DeveloperName == Label.RTOportunidadAutos;

      System.debug('dn> '+quoteLineItem.Quote.Opportunity.Account.RecordType.DeveloperName);
      String datosDelClienteCC = ((
        quoteLineItem.Quote.Opportunity.Account.RecordType.DeveloperName ==
        Label.MotosRecordTypeDevNameAccountNatural
      ) || (quoteLineItem.Quote.Opportunity.Account.RecordType.DeveloperName == Label.AutosRecordTypeDevNameAccountNatural)) 
      ? quoteLineItem.Quote.Opportunity.Account.AM_Numero_de_documento__c : quoteLineItem.Quote.Opportunity.Contacto__r.AM_Numero_de_documento_contacto__c;
  
      String datosDelClienteTelefono = ((
        quoteLineItem.Quote.Opportunity.Account.RecordType.DeveloperName ==
        Label.MotosRecordTypeDevNameAccountNatural
      ) || (quoteLineItem.Quote.Opportunity.Account.RecordType.DeveloperName == Label.AutosRecordTypeDevNameAccountNatural)) 
      ? quoteLineItem.Quote.Opportunity.Account.PersonMobilePhone : quoteLineItem.Quote.Opportunity.Contacto__r.MobilePhone;
      
      String datosDelClienteOtroTelefono = ((
        quoteLineItem.Quote.Opportunity.Account.RecordType.DeveloperName ==
        Label.MotosRecordTypeDevNameAccountNatural
      ) || (quoteLineItem.Quote.Opportunity.Account.RecordType.DeveloperName == Label.AutosRecordTypeDevNameAccountNatural)) 
      ? quoteLineItem.Quote.Opportunity.Account.PersonOtherPhone : quoteLineItem.Quote.Opportunity.Contacto__r.OtherPhone;
      
      String datosDelClienteDireccion = ((
        quoteLineItem.Quote.Opportunity.Account.RecordType.DeveloperName ==
        Label.MotosRecordTypeDevNameAccountNatural
      ) || (quoteLineItem.Quote.Opportunity.Account.RecordType.DeveloperName == Label.AutosRecordTypeDevNameAccountNatural)) 
      ? quoteLineItem.Quote.Opportunity.Account.AM_Direccion__c : quoteLineItem.Quote.Opportunity.Contacto__r.Direccion__c;
      
      String datosDelClienteEmail = ((
        quoteLineItem.Quote.Opportunity.Account.RecordType.DeveloperName ==
        Label.MotosRecordTypeDevNameAccountNatural
      ) || (quoteLineItem.Quote.Opportunity.Account.RecordType.DeveloperName == Label.AutosRecordTypeDevNameAccountNatural)) 
      ? quoteLineItem.Quote.Opportunity.Account.PersonEmail : quoteLineItem.Quote.Opportunity.Contacto__r.Email;
  

      this.datosDelCliente.cc = datosDelClienteCC;
      this.datosDelCliente.telefono = datosDelClienteTelefono;
      this.datosDelCliente.otroTelefono = datosDelClienteOtroTelefono;
      this.datosDelCliente.direccion = datosDelClienteDireccion;
      this.datosDelCliente.email = datosDelClienteEmail;

      String[] listOfBenefits = new List<String>{
        quoteLineItem.Product2.Beneficios__c,
        quoteLineItem.Product2.Beneficios2__c,
        quoteLineItem.Product2.Beneficios3__c,
        quoteLineItem.Product2.Beneficios4__c
      };

      if (
        /*quoteLineItem.Quote.Opportunity.Forma_de_pago__c ==
        'Credito / Leasing' ||
        quoteLineItem.Quote.Opportunity.Forma_de_pago__c ==
        'Crédito / Leasing + Retoma' ||
        quoteLineItem.Quote.Opportunity.Forma_de_pago__c ==
        'Contado + Crédito + Retoma'*/
        quoteLineItem.Quote.Opportunity.Forma_de_pago__c != null &&
          (quoteLineItem.Quote.Opportunity.Forma_de_pago__c.toUpperCase().contains('CRÉDITO')  || quoteLineItem.Quote.Opportunity.Forma_de_pago__c.toUpperCase().contains('CREDITO'))
      ) {
        isAutosMostrarPlanFinanciacion = true;
      }

      Decimal autosPrecioDeVehiculo = 0;
      if (quoteLineItem.Quote.DescuentoApro__c) {
        autosPrecioDeVehiculo =
          quoteLineItem.UnitPrice * quoteLineItem.Quantity;
      } else {
        autosPrecioDeVehiculo =
          quoteLineItem.ListPrice * quoteLineItem.Quantity;
      }

      if (
        quoteLineItem.Product2.DisplayURL == null &&
        mapProductsURLs.containsKey(quoteLineItem.Product2.Name)
      ) {
        quoteLineItem.Product2.DisplayURL = mapProductsURLs.get(
          quoteLineItem.Product2.Name
        );
        lstProductsUpdate.add(
          new Product2(
            Id = quoteLineItem.Product2Id,
            DisplayURL = quoteLineItem.Product2.DisplayURL
          )
        );
      }

      ownerId = quoteLineItem.Quote.Opportunity.OwnerId;
      quoteCreatedDate = quoteLineItem.Quote.CreatedDate;

      String[] listOfDeliveries = new List<String>{};
      if (quoteLineItem.Product2.La_motocicleta_se_entregan_con__c != null) {
        listOfDeliveries = quoteLineItem.Product2.La_motocicleta_se_entregan_con__c.split(
          '\r\n'
        );
      }

      listOfDeliveries = Label.MotoSeEntregaCon.split(',');

      Decimal precioAntesDeDescuento = ( (quoteLineItem.Descuento_Valor__c == null ? 0 : quoteLineItem.Descuento_Valor__c) +
      (quoteLineItem.SO_Valor_Porcentaje_ARD__c * -1));

      // Domain theDomain = [SELECT Domain FROM Domain LIMIT 1];
      // String externalProductURL = URL.getSalesforceBaseUrl().toExternalForm() + quoteLineItem.Product2.DisplayURL;
      // String externalProductURL = theDomain.Domain + quoteLineItem.Product2.DisplayURL;

      String productImageURL = quoteLineItem.Product2.DisplayURL;

      // String externalProductURL = URL.getOrgDomainUrl().toExternalForm() + quoteLineItem.Product2.DisplayURL;
      // String productImageURL = (this.isOpportunityAutos && this.isCommunityProfile) ? externalProductURL : quoteLineItem.Product2.DisplayURL;

      // String externalProductURL = '/sfsites/c' + quoteLineItem.Product2.DisplayURL;
      // String productImageURL = (this.isOpportunityAutos && this.isCommunityProfile) ? externalProductURL : quoteLineItem.Product2.DisplayURL;


      QuotePDFDetail quotePDFDetail = new QuotePDFDetail(
        quoteLineItem,
        listOfBenefits,
        listOfDeliveries,
        index + 1,
        precioAntesDeDescuento,
        autosPrecioDeVehiculo,
        productImageURL
      );
      quotePDFDetails.add(quotePDFDetail);

      nombreCompletoComprador = (quoteLineItem.Quote.Opportunity.Account.FirstName +
        ' ' +
        quoteLineItem.Quote.Opportunity.Account.Segundo_Nombre__c +
        ' ' +
        quoteLineItem.Quote.Opportunity.Account.LastName +
        ' ' +
        quoteLineItem.Quote.Opportunity.Account.Segundo_Apellido__c)
        .replaceAll(regExp, replacement)
        .trim();

      nombreCompletoPagador = (quoteLineItem.Quote.Opportunity.Pagador__r.FirstName +
        ' ' +
        quoteLineItem.Quote.Opportunity.Pagador__r.Segundo_Nombre__c +
        ' ' +
        quoteLineItem.Quote.Opportunity.Pagador__r.LastName +
        ' ' +
        quoteLineItem.Quote.Opportunity.Pagador__r.Segundo_Apellido__c)
        .replaceAll(regExp, replacement)
        .trim();

      nombreCompletoTitularPrendario = (quoteLineItem.Quote.Opportunity.Titular_prendario__r.FirstName +
        ' ' +
        quoteLineItem.Quote.Opportunity.Titular_prendario__r.Segundo_Nombre__c +
        ' ' +
        quoteLineItem.Quote.Opportunity.Titular_prendario__r.LastName +
        ' ' +
        quoteLineItem.Quote.Opportunity.Titular_prendario__r.Segundo_Apellido__c)
        .replaceAll(regExp, replacement)
        .trim();

      nombreCompletoFacturaANombreDe = (quoteLineItem.Quote.Opportunity.Facturar_a_nombre_de__r.FirstName +
        ' ' +
        quoteLineItem.Quote.Opportunity.Facturar_a_nombre_de__r.Segundo_Nombre__c +
        ' ' +
        quoteLineItem.Quote.Opportunity.Facturar_a_nombre_de__r.LastName +
        ' ' +
        quoteLineItem.Quote.Opportunity.Facturar_a_nombre_de__r.Segundo_Apellido__c)
        .replaceAll(regExp, replacement)
        .trim();

      if (
        quoteLineItem.Quote.Opportunity.Account.RecordType.DeveloperName !=
        Label.MotosRecordTypeDevNameAccountNatural
      ) {
        nombreCompletoComprador = quoteLineItem.Quote.Opportunity.Account.Name;
      }

      if (
        quoteLineItem.Quote.Opportunity.Pagador__r.RecordType.DeveloperName !=
        Label.MotosRecordTypeDevNameAccountNatural
      ) {
        nombreCompletoPagador = quoteLineItem.Quote.Opportunity.Pagador__r.Name;
      }
      if (
        quoteLineItem.Quote.Opportunity.Titular_prendario__r.RecordType.DeveloperName !=
        Label.MotosRecordTypeDevNameAccountNatural
      ) {
        nombreCompletoTitularPrendario = quoteLineItem.Quote.Opportunity.Titular_prendario__r.Name;
      }

      if (
        quoteLineItem.Quote.Opportunity.Facturar_a_nombre_de__r.RecordType.DeveloperName !=
        Label.MotosRecordTypeDevNameAccountNatural
      ) {
        nombreCompletoFacturaANombreDe = quoteLineItem.Quote.Opportunity.Facturar_a_nombre_de__r.Name;
      }

      String datosDelClienteNombre = ((
      quoteLineItem.Quote.Opportunity.Account.RecordType.DeveloperName ==
      Label.MotosRecordTypeDevNameAccountNatural
    ) || (quoteLineItem.Quote.Opportunity.Account.RecordType.DeveloperName == Label.AutosRecordTypeDevNameAccountNatural)) 
    ? nombreCompletoComprador : quoteLineItem.Quote.Opportunity.Contacto__r.Name;
    this.datosDelCliente.nombre = datosDelClienteNombre;

      index++;
    }

    miembroDeConcesionario = [
      SELECT
        Id,
        Concesionario__r.Name,
        Concesionario__r.Agencia__c,
        Concesionario__r.Direccion_de_agencia__c,
        Concesionario__r.Telefono__c
      FROM Miembro_de_Concesionario__c
      WHERE Nombre_de_asesor__c = :ownerId
      LIMIT 1
    ];

    quoteExpirationDate = QuotePDFController.getLastWorkDayOfMonth(
      quoteCreatedDate
    );

    return quotePDFDetails;
  }

  public void updateProducts() {
    if (lstProductsUpdate.size() > 0)
      update lstProductsUpdate;
  }

  public static Map<String, String> generarURLs(String[] productNames) {
    Map<String, String> URLs = new Map<String, String>();
    if (ProductNames.size() > 0) {
      List<ContentDocument> matches = [
        SELECT
          Id,
          Title,
          (SELECT id FROM ContentVersions ORDER BY versionNumber DESC LIMIT 1)
        FROM contentdocument
        WHERE Title IN :productNames
      ];
      //https://hondaautos--fase1fcc.my.salesforce.com/sfc/#workspaceView?selectedWorkspaceId=0581F000000LZ4G
      for (ContentDocument match : matches) {
        //https://hondaautos--fase1fcc--c.documentforce.com
        //Quitada 23 feb 21, en producción no funciona. String template =  URL.getOrgDomainUrl().toExternalForm() + '/sfc/servlet.shepherd/version/renditionDownload?rendition=ORIGINAL_Jpg&versionId=' + match.ContentVersions[0].Id + '&operationContext=CHATTER&contentId=' + match.Id;
        //Quitada 23 feb 21, no funciona en sb, en producci{on no lo probé, y además simpler is better. String template =  Label.ContentURL + '/sfc/servlet.shepherd/version/renditionDownload?rendition=ORIGINAL_Jpg&versionId=' + match.ContentVersions[0].Id + '&operationContext=CHATTER&contentId=' + match.Id;
        String template =
          '/sfc/servlet.shepherd/version/download/' +
          match.ContentVersions[0].Id;
        //Este es el formato que le gusta => String template ='https://hondaautos--fase1fcc--c.documentforce.com/sfc/servlet.shepherd/version/renditionDownload?rendition=ORIGINAL_Jpg&versionId=0681F0000017Dvr&operationContext=CHATTER&contentId=05T1F000003d3j9';
        URLs.put(match.Title, template);
      }
    }
    return URLs;
  }

  public static Date getLastWorkDayOfMonth(Datetime baseDate) {
    DateTime tmpDateTime = DateTime.newInstance(
      baseDate.year(),
      baseDate.month(),
      baseDate.day()
    );
    tmpDateTime = tmpDateTime.addMonths(1);

    DateTime firstDayDate = DateTime.newInstance(
      tmpDateTime.year(),
      tmpDateTime.month(),
      1,
      0,
      0,
      0
    );

    DateTime lastWorkday = firstDayDate.addDays(-1);

    while (lastWorkday.format('EEEE').equalsIgnoreCase('Sunday')) {
      lastWorkday = lastWorkday.addDays(-1);
    }

    List<Holiday> holidays = null;
    do {
      holidays = [
        SELECT Id, StartTimeInMinutes, Name, ActivityDate
        FROM Holiday
        WHERE ActivityDate = :lastWorkday.date()
      ];
      if (holidays.size() > 0) {
        lastWorkday = lastWorkday.addDays(-1);
      }
    } while (holidays.size() > 0);

    return lastWorkday.date();
  }

  public class DatosDelCliente {
    public String nombre { get; set; }
    public String cc { get; set; }
    public String telefono { get; set; }
    public String otroTelefono { get; set; }
    public String direccion { get; set; }
    public String email { get; set; }

    public DatosDelCliente(){}
  }

  public class QuotePDFDetail {
    public QuoteLineItem quoteLineItem { get; set; }
    public String[] listOfBenefits { get; set; }
    public String[] listOfDeliveries { get; set; }
    public String observaciones { get; set; }
    public Integer index { get; set; }
    public Decimal precioAntesDeDescuento { get; set; }
    public Decimal autosPrecioDeVehiculo { get; set; }
    public String productImageURL { get; set; }
    public boolean blnGarantia1 { get; set; }
    public boolean blnGarantia2 { get; set; }
    public boolean blnGarantia3 { get; set; }
    public boolean blnGarantia4 { get; set; }

    public QuotePDFDetail(
      QuoteLineItem quoteLineItem,
      String[] listOfBenefits,
      String[] listOfDeliveries,
      Integer index,
      Decimal precioAntesDeDescuento,
      Decimal autosPrecioDeVehiculo,
      String productImageURL
    ) {
      this.quoteLineItem = quoteLineItem;
      this.listOfBenefits = listOfBenefits;
      this.listOfDeliveries = listOfDeliveries;
      this.index = index;
      this.precioAntesDeDescuento = precioAntesDeDescuento;
      this.autosPrecioDeVehiculo = autosPrecioDeVehiculo;
      this.productImageURL = productImageURL;
      if( quoteLineItem.Product2.SO_Garantia_motocicleta__c =='Garantia1' || quoteLineItem.Product2.SO_Garantia_motocicleta__c == ''){    
          this.productImageURL = productImageURL;
          this.blnGarantia1 = true;
          this.blnGarantia2 = false;
          this.blnGarantia3 = false;
          this.blnGarantia4 = false;  
      }
      else if( quoteLineItem.Product2.SO_Garantia_motocicleta__c =='Garantia2' ){
          this.blnGarantia1 = false;
          this.blnGarantia2 = true;
          this.blnGarantia3 = false;
          this.blnGarantia4 = false;
      }
      else if( quoteLineItem.Product2.SO_Garantia_motocicleta__c =='Garantia3' ){
          this.blnGarantia1 = false;
          this.blnGarantia2 = false;
          this.blnGarantia3 = true;
          this.blnGarantia4 = false;
      }
      else if( quoteLineItem.Product2.SO_Garantia_motocicleta__c =='Garantia4' ){
          this.blnGarantia1 = false;  
          this.blnGarantia2 = false;
          this.blnGarantia3 = false;  
          this.blnGarantia4 = true;
      }
      if (quoteLineItem.Quote.Observaciones__c != null) {
        if (
          !quoteLineItem.Quote.Observaciones__c.startsWith('Observaciones: ')
        ) {
          quoteLineItem.Quote.Observaciones__c =
            'Observaciones: ' + quoteLineItem.Quote.Observaciones__c;
        }
      } else {
        quoteLineItem.Quote.Observaciones__c = 'Observaciones: ';
      }
    }
  }
  public class WrpGatantia{
    public string sGarantia { get; set; }
    public string logoURL   { get; set; }
  }
}