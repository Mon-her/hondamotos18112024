/**
 * Fast Cloud Consulting
 * @author           Olvin Abarca
 * Description:      Custom controller class to query the required fields to be displayed on the PDF document.
 * Added Referencia_comercial__c to the query, by JPD on July 28th, 21
 */
public class OrderPDFController {
  public Account account { get; set; }
  public Opportunity opportunity { get; set; }
  public OpportunityLineItem opportunityLineItem { get; set; }
  public Order order { get; set; }
  public OrderItem orderItem { get; set; }
  public User owner { get; set; }
  public User runningUser { get; set; }
  public Miembro_de_Concesionario__c miembroDeConcesionario { get; set; }

  public Decimal subtotal { get; set; }
  public Decimal iva { get; set; }
  public Decimal impoconsumo { get; set; }
  public Decimal descuentoEnPrecio { get; set; }
  public Decimal valorTotal { get; set; }
  public Decimal valorTotalNegocio { get; set; }
  public String tipoDePago { get; set; }

  public String nombreCompletoComprador { get; set; }
  public String nombreCompletoPagador { get; set; }
  public String nombreCompletoTitularPrendario { get; set; }
  public String nombreCompletoFacturaANombreDe { get; set; }

  public String compradorTelefonoResidencia { get; set; }
  public String compradorTelefonoOficina { get; set; }
  public String compradorTelefonoCelular { get; set; }
  public String compradorEmail { get; set; }

  public String facturaAnombreTelefonoResidencia { get; set; }
  public String facturaAnombreTelefonoOficina { get; set; }
  public String facturaAnombreTelefonoCelular { get; set; }
  public String facturaAnombreEmail { get; set; }

  public String garantiaDeUsados { get; set; }

  public Boolean isOpportunityAutosUsados { get; set; }
  public Boolean isOpportunityAutosNuevos { get; set; }
  public Boolean isOpportunityAutosRenting { get; set; }

  public CustomDetail orderCustomDetail { get; set; }

  public OrderPDFController() {

    this.runningUser = [SELECT Id, Name, Profile.Name FROM User WHERE Id = :UserInfo.getUserId() LIMIT 1];

    Boolean isProfileAuto =
    this.runningUser.Profile.Name.indexOf('auto') > -1 ||
    this.runningUser.Profile.Name.indexOf('Auto') > -1;

    String pageName = ApexPages.currentPage().getUrl().substringAfter('apex/');
    System.debug('p: ' + pageName);
    isProfileAuto = (pageName != null) ? (pageName.indexOf('Auto') > -1 || pageName.indexOf('auto') > -1) : isProfileAuto;

    this.init(isProfileAuto);
  }

  public void init(Boolean isProfileAuto) {
    String orderId = ApexPages.currentPage().getParameters().get('id');

    this.order = getOrder(isProfileAuto, orderId);
    this.opportunityLineItem = getOpportunityLineItem(
      isProfileAuto,
      this.order.OpportunityId
    );

    this.isOpportunityAutosUsados =
      this.Order.Opportunity.Tipo_de_Oportunidad__c == 'Usados';

    this.isOpportunityAutosNuevos =
      this.Order.Opportunity.Tipo_de_Oportunidad__c == 'Nuevos';

    this.isOpportunityAutosRenting =
      this.Order.Opportunity.Tipo_de_Oportunidad__c == 'Renting';

    this.orderCustomDetail = new CustomDetail();

    this.owner = [
      SELECT Id, Name, AM_Concesionario__c, AM_Agencia__c, Manager.Name
      FROM User
      WHERE Id = :order.OwnerId
      LIMIT 1
    ];

    this.miembroDeConcesionario = [
      SELECT
        Id,
        Concesionario__r.Name,
        Concesionario__r.Agencia__c,
        Concesionario__r.Direccion_de_agencia__c,
        Concesionario__r.Telefono__c
      FROM Miembro_de_Concesionario__c
      WHERE Nombre_de_asesor__c = :owner.Id
      LIMIT 1
    ];

    if (isProfileAuto) {
      // asesores autos

      this.orderCustomDetail.linea = opportunityLineItem.Product2.Linea__c;

      garantiaDeUsados = garantiaDeUsados(this.order, opportunityLineItem);

      // compradorTeléfonoCelular = (opportunity.Facturar_a_nombre_de__r.RecordType.DeveloperName == Label.AutosRecordTypeDevNameAccountJuridica) ? opportunity.Facturar_a_nombre_de__r.Phone : ;


      compradorTelefonoResidencia = (this.order.opportunity.Account.RecordType.DeveloperName == Label.AutosRecordTypeDevNameAccountJuridica) ? this.order.opportunity.Account.AM_Telefono_representante__c : this.order.opportunity.Account.Phone;
      compradorTelefonoOficina = (this.order.opportunity.Account.RecordType.DeveloperName == Label.AutosRecordTypeDevNameAccountJuridica) ? this.order.opportunity.Account.AM_Telefono_representante__c : this.order.opportunity.Account.Phone;
      compradorTelefonoCelular = (this.order.opportunity.Account.RecordType.DeveloperName == Label.AutosRecordTypeDevNameAccountJuridica) ? this.order.opportunity.Account.PersonMobilePhone : this.order.opportunity.Account.PersonMobilePhone;
      compradorEmail = (this.order.opportunity.Account.RecordType.DeveloperName == Label.AutosRecordTypeDevNameAccountJuridica) ? this.order.opportunity.Account.MC_Correo_electronico_Empresa__c : this.order.opportunity.Account.PersonEmail;

      facturaAnombreTelefonoResidencia = (this.order.opportunity.Facturar_a_nombre_de__r.RecordType.DeveloperName == Label.AutosRecordTypeDevNameAccountJuridica) ? this.order.opportunity.Facturar_a_nombre_de__r.AM_Telefono_representante__c : this.order.opportunity.Facturar_a_nombre_de__r.Phone;
      facturaAnombreTelefonoOficina = (this.order.opportunity.Facturar_a_nombre_de__r.RecordType.DeveloperName == Label.AutosRecordTypeDevNameAccountJuridica) ? this.order.opportunity.Facturar_a_nombre_de__r.AM_Telefono_representante__c : this.order.opportunity.Facturar_a_nombre_de__r.Phone;
      facturaAnombreTelefonoCelular = (this.order.opportunity.Facturar_a_nombre_de__r.RecordType.DeveloperName == Label.AutosRecordTypeDevNameAccountJuridica) ? this.order.opportunity.Facturar_a_nombre_de__r.PersonMobilePhone : this.order.opportunity.Facturar_a_nombre_de__r.PersonMobilePhone;
      facturaAnombreEmail = (this.order.opportunity.Facturar_a_nombre_de__r.RecordType.DeveloperName == Label.AutosRecordTypeDevNameAccountJuridica) ? this.order.opportunity.Facturar_a_nombre_de__r.MC_Correo_electronico_Empresa__c : this.order.opportunity.Facturar_a_nombre_de__r.PersonEmail;

    } else {
      // asesores motos

      if (opportunityLineItem.Descuento_Valor__c == null) {
        opportunityLineItem.Descuento_Valor__c = 0;
      }
      if (opportunityLineItem.Precio_de_lista_antes_de_impuesto__c == null) {
        opportunityLineItem.Precio_de_lista_antes_de_impuesto__c = 0;
      }
      if (opportunityLineItem.Iva__c == null) {
        opportunityLineItem.Iva__c = 0;
      }
      if (opportunityLineItem.Impoconsumo__c == null) {
        opportunityLineItem.Impoconsumo__c = 0;
      }

      if (opportunityLineItem.Valor_seguro_robo__c == null) {
        opportunityLineItem.Valor_seguro_robo__c = 0;
      }

      if (opportunityLineItem.Casco__c == null) {
        opportunityLineItem.Casco__c = 0;
      }

      if (opportunityLineItem.Accesorios__c == null) {
        opportunityLineItem.Accesorios__c = 0;
      }

      if (opportunityLineItem.Soat__c == null) {
        opportunityLineItem.Soat__c = 0;
      }

      if (opportunityLineItem.Valor_matrcula__c == null) {
        opportunityLineItem.Valor_matrcula__c = 0;
      }

      descuentoEnPrecio =
        opportunityLineItem.Descuento_Valor__c +
        (opportunityLineItem.Valor_ARD__c * 1);

      subtotal =
        opportunityLineItem.Precio_de_lista_antes_de_impuesto__c -
        descuentoEnPrecio;

      iva =
        (opportunityLineItem.Iva__c / 100) *
        opportunityLineItem.Precio_de_lista_antes_de_impuesto__c;

      impoconsumo =
        (opportunityLineItem.Impoconsumo__c / 100) *
        opportunityLineItem.Precio_de_lista_antes_de_impuesto__c;

      valorTotal = subtotal + iva + impoconsumo;

      tipoDePago = getLabelFromValue(this.order.Opportunity.Tipo_de_Pago__c);

      this.valorTotalNegocio =
        valorTotal +
        opportunityLineItem.Valor_seguro_robo__c +
        opportunityLineItem.Accesorios__c +
        opportunityLineItem.Casco__c +
        opportunityLineItem.Soat__c +
        opportunityLineItem.Valor_matrcula__c;
    }

    String regExp = '\\s*null\\s*';
    String replacement = ' ';

    nombreCompletoComprador = (this.order.Opportunity.Account.FirstName +
      ' ' +
      this.order.opportunity.Account.Segundo_Nombre__c +
      ' ' +
      this.order.opportunity.Account.LastName +
      ' ' +
      this.order.opportunity.Account.Segundo_Apellido__c)
      .replaceAll(regExp, replacement)
      .trim();

    nombreCompletoPagador = (this.order.opportunity.Pagador__r.FirstName +
      ' ' +
      this.order.opportunity.Pagador__r.Segundo_Nombre__c +
      ' ' +
      this.order.opportunity.Pagador__r.LastName +
      ' ' +
      this.order.opportunity.Pagador__r.Segundo_Apellido__c)
      .replaceAll(regExp, replacement)
      .trim();

    nombreCompletoTitularPrendario = (this.order.opportunity.Titular_prendario__r.FirstName +
      ' ' +
      this.order.opportunity.Titular_prendario__r.Segundo_Nombre__c +
      ' ' +
      this.order.opportunity.Titular_prendario__r.LastName +
      ' ' +
      this.order.opportunity.Titular_prendario__r.Segundo_Apellido__c)
      .replaceAll(regExp, replacement)
      .trim();

    nombreCompletoFacturaANombreDe = (this.order.opportunity.Facturar_a_nombre_de__r.FirstName +
      ' ' +
      this.order.opportunity.Facturar_a_nombre_de__r.Segundo_Nombre__c +
      ' ' +
      this.order.opportunity.Facturar_a_nombre_de__r.LastName +
      ' ' +
      this.order.opportunity.Facturar_a_nombre_de__r.Segundo_Apellido__c)
      .replaceAll(regExp, replacement)
      .trim();

    if (
      this.order.opportunity.Account.RecordType.DeveloperName !=
      Label.MotosRecordTypeDevNameAccountNatural
    ) {
      nombreCompletoComprador = this.order.opportunity.Account.Name;
    }
    if (
      this.order.opportunity.Pagador__r.RecordType.DeveloperName !=
      Label.MotosRecordTypeDevNameAccountNatural
    ) {
      nombreCompletoPagador = this.order.opportunity.Pagador__r.Name;
    }
    if (
      this.order.opportunity.Titular_prendario__r.RecordType.DeveloperName !=
      Label.MotosRecordTypeDevNameAccountNatural
    ) {
      nombreCompletoTitularPrendario = this.order.opportunity.Titular_prendario__r.Name;
    }

    if (
      this.order.opportunity.Facturar_a_nombre_de__r.RecordType.DeveloperName !=
      Label.MotosRecordTypeDevNameAccountNatural
    ) {
      nombreCompletoFacturaANombreDe = this.order.opportunity.Facturar_a_nombre_de__r.Name;
    }
  }

  private String garantiaDeUsados(
    Order order,
    OpportunityLineItem opportunityLineItem
  ) {
    String garantia = '';
    // this.order.opportunity.Tipo_de_Inv_Usado__c == 'Propio' ||
    // this.order.opportunity.Tipo_de_Inv_Usado__c == 'Activo Fijo';

    garantia = (this.order.opportunity.Tipo_de_Oportunidad__c == 'Usados'
      ? (((opportunityLineItem.Product2.Inventario_de_Usados__r.Origen__c ==
          'RETOMA' ||
          opportunityLineItem.Product2.Inventario_de_Usados__r.Origen__c ==
          'RENTING') &&
          (opportunityLineItem.Product2.Inventario_de_Usados__r.Marca__c ==
          'HONDA'))
          ? 'SI'
          : 'NO')
      : '');

    return garantia;
  }

  private Order getOrder(Boolean isProfileAuto, String orderId) {
    Order order = null;
    if (isProfileAuto) {
      order = [
        SELECT
          Id,
          QuoteId,
          OrderNumber,
          CreatedDate,
          AccountId,
          Valor_total__c,
          OwnerId,

          //opportunity fields
          OpportunityId,
          Opportunity.Account.Name,
          Opportunity.Account.RecordType.DeveloperName,
          Opportunity.Account.FirstName,
          Opportunity.Account.LastName,
          Opportunity.Account.Primer_nombre__c,
          Opportunity.Account.Segundo_Nombre__c,
          Opportunity.Account.Primer_apellido__c,
          Opportunity.Account.Segundo_Apellido__c,
          Opportunity.Account.MC_Direccion_completa__c,
          Opportunity.Account.AM_Numero_de_documento__c,
          Opportunity.Account.AM_Ciudad__r.Name,
          Opportunity.Account.PersonHomePhone,
          Opportunity.Account.PersonMobilePhone,
          Opportunity.Account.AM_Direccion__c,
          Opportunity.Account.AM_Telefono_representante__c,
          Opportunity.Account.MC_Correo_electronico_Empresa__c,
          Opportunity.Account.Phone,
          Opportunity.Account.PersonEmail,
          Opportunity.Pagador__r.Name,
          Opportunity.Pagador__r.RecordType.DeveloperName,
          Opportunity.Pagador__r.AM_Direccion__c,
          Opportunity.Pagador__r.AM_Ciudad__r.Name,
          Opportunity.Pagador__r.PersonHomePhone,
          Opportunity.Pagador__r.PersonMobilePhone,
          Opportunity.Pagador__r.FirstName,
          Opportunity.Pagador__r.LastName,
          Opportunity.Pagador__r.AM_Numero_de_documento__c,
          Opportunity.Pagador__r.Primer_nombre__c,
          Opportunity.Pagador__r.Segundo_Nombre__c,
          Opportunity.Pagador__r.Primer_apellido__c,
          Opportunity.Pagador__r.Segundo_Apellido__c,
          Opportunity.Tipo_de_Pago__c,
          Opportunity.Titular_prendario__r.Name,
          Opportunity.Titular_prendario__r.RecordType.DeveloperName,
          Opportunity.Titular_prendario__r.AM_Direccion__c,
          Opportunity.Titular_prendario__r.AM_Ciudad__r.Name,
          Opportunity.Titular_prendario__r.PersonHomePhone,
          Opportunity.Titular_prendario__r.PersonMobilePhone,
          Opportunity.Titular_prendario__r.FirstName,
          Opportunity.Titular_prendario__r.LastName,
          Opportunity.Titular_prendario__r.Primer_nombre__c,
          Opportunity.Titular_prendario__r.Segundo_Nombre__c,
          Opportunity.Titular_prendario__r.Primer_apellido__c,
          Opportunity.Titular_prendario__r.Segundo_Apellido__c,
          Opportunity.Titular_prendario__r.AM_Numero_de_documento__c,
          Opportunity.Facturar_a_nombre_de__r.Name,
          Opportunity.Facturar_a_nombre_de__r.AM_Direccion__c,
          Opportunity.Facturar_a_nombre_de__r.RecordType.DeveloperName,
          Opportunity.Facturar_a_nombre_de__r.MC_Direccion_completa__c,
          Opportunity.Facturar_a_nombre_de__r.AM_Ciudad__r.Name,
          Opportunity.Facturar_a_nombre_de__r.PersonHomePhone,
          Opportunity.Facturar_a_nombre_de__r.AM_Telefono_representante__c,
          Opportunity.Facturar_a_nombre_de__r.MC_Correo_electronico_Empresa__c,
          Opportunity.Facturar_a_nombre_de__r.PersonMobilePhone,
          Opportunity.Facturar_a_nombre_de__r.FirstName,
          Opportunity.Facturar_a_nombre_de__r.LastName,
          Opportunity.Facturar_a_nombre_de__r.Primer_nombre__c,
          Opportunity.Facturar_a_nombre_de__r.Segundo_Nombre__c,
          Opportunity.Facturar_a_nombre_de__r.Primer_apellido__c,
          Opportunity.Facturar_a_nombre_de__r.Segundo_Apellido__c,
          Opportunity.Facturar_a_nombre_de__r.AM_Numero_de_documento__c,
          Opportunity.Facturar_a_nombre_de__r.PersonEmail,
          Opportunity.Facturar_a_nombre_de__r.Phone,
          Opportunity.Marca_retoma__c,
          Opportunity.Modelo_retoma__c,
          Opportunity.Placa_retoma__c,
          Opportunity.Version_retoma__c,
          Opportunity.Caja_retoma__c,
          Opportunity.Color_retoma__c,
          Opportunity.Contrato_retoma__c,
          Opportunity.Kilometraje_retoma__c,
          Opportunity.Linea_retoma__c,
          Opportunity.Avaluado_por_retoma__c,
          Opportunity.Avaluo_retoma__c,
          Opportunity.Sitio_de_matricula_retoma__c,
          Opportunity.Tipo_de_carroceria_retoma__c,
          Opportunity.Tipo_de_Inv_Usado__c,
          Opportunity.VIN__c,
          Opportunity.Placa__c,
          Opportunity.Amount,
          // Correo_Electronico_FactANomb__c,
          // Direccion_FactANomb__c,
          // Ciudad_FactANomb__c,
          // Telefono_FactANomb__c,
          // Telefono_oficina_FactANomb__c,
          // Celular_FactANomb__c,
          // Numero_de_identificacion_FactANomb__c,
          Opportunity.Observaciones__c,
          Opportunity.Tipo_de_cliente__c, // "Cliente Honda", "Cliente Otra Marca", "Cliente Primera Moto"
          Opportunity.Tipo_de_Oportunidad__c, // "Nuevos", "Usados", "Crédito", "Otro", "Renting"
          Opportunity.Owner.Name,
          Opportunity.CreatedBy.Name
        FROM Order
        WHERE Id = :orderId
        LIMIT 1
      ];
    } else {
      order = [
        SELECT
          Id,
          QuoteId,
          OrderNumber,
          CreatedDate,
          NIT__c,
          Solicitud_de_pedido__c,
          Numero_del_pedido__c,
          OwnerId,
          Motocicleta_o_producto__c,
          Color__c,
          Modelo__c,
          ID_de_pedido_ERP__c,
          Comprador__c,
          Comprador__r.AM_Numero_de_documento__c,
          Comprador__r.Name,
          Pagador__c,
          Pagador__r.AM_Numero_de_documento__c,
          Pagador__r.Name,
          Titular_prendario__c,
          Titular_prendario__r.Name,
          Titular_prendario__r.AM_Numero_de_documento__c,
          Valor__c,
          Descuento_en_precio__c,
          Subtotal__c,
          IVA__c,
          Impuesto_al_consumo__c,
          Valor_total__c,
          Tipo_de_Pago2__c,
          Entidad_financiera__c,
          Valor_Total_Monto__c,
          Seguro_de_Moto__c,
          Accesorios__c,
          Casco__c,
          Matricula__c,
          Soat__c,
          Total_Negocio__c,
          Cuota_inicial__c,
          Observaciones__c,
          AccountId,
          Account.Name,
          Account.MC_Direccion_completa__c,
          Account.AM_Numero_de_documento__c,
          Account.AM_Ciudad__r.Name,
          Account.PersonMobilePhone,
          Account.Phone,
          Account.PersonEmail,

          // Opportunity fields
          OpportunityId,
          Opportunity.Account.Name,
          Opportunity.Account.RecordType.DeveloperName,
          Opportunity.Account.FirstName,
          Opportunity.Account.LastName,
          Opportunity.Account.Primer_nombre__c,
          Opportunity.Account.Segundo_Nombre__c,
          Opportunity.Account.Primer_apellido__c,
          Opportunity.Account.Segundo_Apellido__c,
          Opportunity.Account.MC_Direccion_completa__c,
          Opportunity.Account.AM_Numero_de_documento__c,
          Opportunity.Account.AM_Ciudad__r.Name,
          Opportunity.Account.PersonMobilePhone,
          Opportunity.Account.Phone,
          Opportunity.Account.PersonEmail,
          Opportunity.Pagador__r.Name,
          Opportunity.Pagador__r.RecordType.DeveloperName,
          Opportunity.Pagador__r.FirstName,
          Opportunity.Pagador__r.LastName,
          Opportunity.Pagador__r.AM_Numero_de_documento__c,
          Opportunity.Pagador__r.Primer_nombre__c,
          Opportunity.Pagador__r.Segundo_Nombre__c,
          Opportunity.Pagador__r.Primer_apellido__c,
          Opportunity.Pagador__r.Segundo_Apellido__c,
          Opportunity.Tipo_de_Pago__c,
          Opportunity.Titular_prendario__r.Name,
          Opportunity.Titular_prendario__r.RecordType.DeveloperName,
          Opportunity.Titular_prendario__r.FirstName,
          Opportunity.Titular_prendario__r.LastName,
          Opportunity.Titular_prendario__r.Primer_nombre__c,
          Opportunity.Titular_prendario__r.Segundo_Nombre__c,
          Opportunity.Titular_prendario__r.Primer_apellido__c,
          Opportunity.Titular_prendario__r.Segundo_Apellido__c,
          Opportunity.Titular_prendario__r.AM_Numero_de_documento__c,
          Opportunity.Entidad_Financiera__c,
          Opportunity.Facturar_a_nombre_de__r.Name,
          Opportunity.Facturar_a_nombre_de__r.RecordType.DeveloperName,
          Opportunity.Facturar_a_nombre_de__r.FirstName,
          Opportunity.Facturar_a_nombre_de__r.LastName,
          Opportunity.Facturar_a_nombre_de__r.Primer_nombre__c,
          Opportunity.Facturar_a_nombre_de__r.Segundo_Nombre__c,
          Opportunity.Facturar_a_nombre_de__r.Primer_apellido__c,
          Opportunity.Facturar_a_nombre_de__r.Segundo_Apellido__c,
          Opportunity.Facturar_a_nombre_de__r.AM_Numero_de_documento__c,
          Opportunity.Correo_Electronico_FactANomb__c,
          Opportunity.Direccion_FactANomb__c,
          Opportunity.Ciudad_FactANomb__c,
          Opportunity.Telefono_FactANomb__c,
          Opportunity.Telefono_oficina_FactANomb__c,
          Opportunity.Celular_FactANomb__c,
          Opportunity.Observaciones__c,
          Opportunity.Numero_de_identificacion_FactANomb__c,
          Opportunity.Tipo_de_cliente__c, // "Cliente Honda", "Cliente Otra Marca", "Cliente Primera Moto"
          Opportunity.Tipo_de_Oportunidad__c // "Nuevos", "Usados", "Crédito", "Otro", "Renting"
        FROM Order
        WHERE Id = :orderId
        LIMIT 1
      ];
    }

    return order;
  }

  // private Opportunity getOpportunity(
  //   Boolean isProfileAuto,
  //   String opportunityId
  // ) {
  //   Opportunity opportunity = null;
  //   if (isProfileAuto) {
  //     opportunity = [
  //       SELECT
  //         Id,
  //         Account.Name,
  //         Account.RecordType.DeveloperName,
  //         Account.FirstName,
  //         Account.LastName,
  //         Account.Primer_nombre__c,
  //         Account.Segundo_Nombre__c,
  //         Account.Primer_apellido__c,
  //         Account.Segundo_Apellido__c,
  //         Account.MC_Direccion_completa__c,
  //         Account.AM_Numero_de_documento__c,
  //         Account.AM_Ciudad__r.Name,
  //         Account.PersonHomePhone,
  //         Account.PersonMobilePhone,
  //         Account.AM_Direccion__c,
  //         Account.AM_Telefono_representante__c,
  //         Account.MC_Correo_electronico_Empresa__c,
  //         Account.Phone,
  //         Account.PersonEmail,
  //         Pagador__r.Name,
  //         Pagador__r.RecordType.DeveloperName,
  //         Pagador__r.AM_Direccion__c,
  //         Pagador__r.AM_Ciudad__r.Name,
  //         Pagador__r.PersonHomePhone,
  //         Pagador__r.PersonMobilePhone,
  //         Pagador__r.FirstName,
  //         Pagador__r.LastName,
  //         Pagador__r.AM_Numero_de_documento__c,
  //         Pagador__r.Primer_nombre__c,
  //         Pagador__r.Segundo_Nombre__c,
  //         Pagador__r.Primer_apellido__c,
  //         Pagador__r.Segundo_Apellido__c,
  //         Tipo_de_Pago__c,
  //         Titular_prendario__r.Name,
  //         Titular_prendario__r.RecordType.DeveloperName,
  //         Titular_prendario__r.AM_Direccion__c,
  //         Titular_prendario__r.AM_Ciudad__r.Name,
  //         Titular_prendario__r.PersonHomePhone,
  //         Titular_prendario__r.PersonMobilePhone,
  //         Titular_prendario__r.FirstName,
  //         Titular_prendario__r.LastName,
  //         Titular_prendario__r.Primer_nombre__c,
  //         Titular_prendario__r.Segundo_Nombre__c,
  //         Titular_prendario__r.Primer_apellido__c,
  //         Titular_prendario__r.Segundo_Apellido__c,
  //         Titular_prendario__r.AM_Numero_de_documento__c,
  //         Facturar_a_nombre_de__r.Name,
  //         Facturar_a_nombre_de__r.AM_Direccion__c,
  //         Facturar_a_nombre_de__r.RecordType.DeveloperName,
  //         Facturar_a_nombre_de__r.MC_Direccion_completa__c,
  //         Facturar_a_nombre_de__r.AM_Ciudad__r.Name,
  //         Facturar_a_nombre_de__r.PersonHomePhone,
  //         Facturar_a_nombre_de__r.AM_Telefono_representante__c,
  //         Facturar_a_nombre_de__r.MC_Correo_electronico_Empresa__c,
  //         Facturar_a_nombre_de__r.PersonMobilePhone,
  //         Facturar_a_nombre_de__r.FirstName,
  //         Facturar_a_nombre_de__r.LastName,
  //         Facturar_a_nombre_de__r.Primer_nombre__c,
  //         Facturar_a_nombre_de__r.Segundo_Nombre__c,
  //         Facturar_a_nombre_de__r.Primer_apellido__c,
  //         Facturar_a_nombre_de__r.Segundo_Apellido__c,
  //         Facturar_a_nombre_de__r.AM_Numero_de_documento__c,
  //         Facturar_a_nombre_de__r.PersonEmail,
  //         Facturar_a_nombre_de__r.Phone,
  //         Marca_retoma__c,
  //         Modelo_retoma__c,
  //         Placa_retoma__c,
  //         Version_retoma__c,
  //         Caja_retoma__c,
  //         Color_retoma__c,
  //         Contrato_retoma__c,
  //         Kilometraje_retoma__c,
  //         Linea_retoma__c,
  //         Avaluado_por_retoma__c,
  //         Avaluo_retoma__c,
  //         Sitio_de_matricula_retoma__c,
  //         Tipo_de_carroceria_retoma__c,
  //         Tipo_de_Inv_Usado__c,
  //         VIN__c,
  //         Placa__c,
  //         Amount,
  //         // Correo_Electronico_FactANomb__c,
  //         // Direccion_FactANomb__c,
  //         // Ciudad_FactANomb__c,
  //         // Telefono_FactANomb__c,
  //         // Telefono_oficina_FactANomb__c,
  //         // Celular_FactANomb__c,
  //         // Numero_de_identificacion_FactANomb__c,
  //         Observaciones__c,
  //         Tipo_de_cliente__c, // "Cliente Honda", "Cliente Otra Marca", "Cliente Primera Moto"
  //         Tipo_de_Oportunidad__c, // "Nuevos", "Usados", "Crédito", "Otro", "Renting"
  //         Owner.Name,
  //         CreatedBy.Name
  //       FROM Opportunity
  //       WHERE Id = :opportunityId
  //       LIMIT 1
  //     ];
  //   } else {
  //     opportunity = [
  //       SELECT
  //         Id,
  //         Account.Name,
  //         Account.RecordType.DeveloperName,
  //         Account.FirstName,
  //         Account.LastName,
  //         Account.Primer_nombre__c,
  //         Account.Segundo_Nombre__c,
  //         Account.Primer_apellido__c,
  //         Account.Segundo_Apellido__c,
  //         Account.MC_Direccion_completa__c,
  //         Account.AM_Numero_de_documento__c,
  //         Account.AM_Ciudad__r.Name,
  //         Account.PersonMobilePhone,
  //         Account.Phone,
  //         Account.PersonEmail,
  //         Pagador__r.Name,
  //         Pagador__r.RecordType.DeveloperName,
  //         Pagador__r.FirstName,
  //         Pagador__r.LastName,
  //         Pagador__r.AM_Numero_de_documento__c,
  //         Pagador__r.Primer_nombre__c,
  //         Pagador__r.Segundo_Nombre__c,
  //         Pagador__r.Primer_apellido__c,
  //         Pagador__r.Segundo_Apellido__c,
  //         Tipo_de_Pago__c,
  //         Titular_prendario__r.Name,
  //         Titular_prendario__r.RecordType.DeveloperName,
  //         Titular_prendario__r.FirstName,
  //         Titular_prendario__r.LastName,
  //         Titular_prendario__r.Primer_nombre__c,
  //         Titular_prendario__r.Segundo_Nombre__c,
  //         Titular_prendario__r.Primer_apellido__c,
  //         Titular_prendario__r.Segundo_Apellido__c,
  //         Titular_prendario__r.AM_Numero_de_documento__c,
  //         Entidad_Financiera__c,
  //         Facturar_a_nombre_de__r.Name,
  //         Facturar_a_nombre_de__r.RecordType.DeveloperName,
  //         Facturar_a_nombre_de__r.FirstName,
  //         Facturar_a_nombre_de__r.LastName,
  //         Facturar_a_nombre_de__r.Primer_nombre__c,
  //         Facturar_a_nombre_de__r.Segundo_Nombre__c,
  //         Facturar_a_nombre_de__r.Primer_apellido__c,
  //         Facturar_a_nombre_de__r.Segundo_Apellido__c,
  //         Facturar_a_nombre_de__r.AM_Numero_de_documento__c,
  //         Correo_Electronico_FactANomb__c,
  //         Direccion_FactANomb__c,
  //         Ciudad_FactANomb__c,
  //         Telefono_FactANomb__c,
  //         Telefono_oficina_FactANomb__c,
  //         Celular_FactANomb__c,
  //         Observaciones__c,
  //         Numero_de_identificacion_FactANomb__c,
  //         Tipo_de_cliente__c, // "Cliente Honda", "Cliente Otra Marca", "Cliente Primera Moto"
  //         Tipo_de_Oportunidad__c // "Nuevos", "Usados", "Crédito", "Otro", "Renting"
  //       FROM Opportunity
  //       WHERE Id = :opportunityId
  //       LIMIT 1
  //     ];
  //   }
  //   return opportunity;
  // }

  private OpportunityLineItem getOpportunityLineItem(
    Boolean isProfileAuto,
    String opportunityId
  ) {
    OpportunityLineItem oli = null;
    if (isProfileAuto) {
      oli = [
        SELECT
          Id,
          Name,
          Entidad_Financiera__c,
          Product2.Name,
          Product2.Marca__c, //Product2.Marca_usado__c,
          // Product2.VIN__c, // no existe
          Product2.Linea__c, //Product2.Linea_version__c,Product2.Linea_usado__c,
          Product2.Ano_modelo__c, //Product2.Modelo_Ao__c,Product2.Ano_modelo_usado__c,Product2.Ano_modelo__c,
          Product2.Cilindraje__c, //Product2.Cilindraje__c,Product2.Cilindraje_usado__c,
          Product2.Caja__c, //Product2.Tipo_de_caja__c,
          Product2.Placa__c,
          Product2.Numero_VIN__c,
          Product2.Kilometraje__c,
          Product2.Color__c,
          Product2.Inventario_de_Usados__r.Origen__c, // TODO: revisar que tengan acceso todos los perfiles de autos
          Product2.Inventario_de_Usados__r.Marca__c, // TODO: revisar que tengan acceso todos los perfiles de autos
          Product2.Referencia_comercial__c,
          Valor_Vehculo__c,
          Iva__c,
          Anticipo__c,
          Desembolso_entidad_financiera__c,
          Cheque_posfechado_avalado__c,
          Otros_Gastos__c,
          Saldo_contra_entrega__c,
          Recompra__c,
          Subtotal_form__c,
          Total_a_Pagar__c,
          Impoconsumo__c,
          Total__c
        FROM OpportunityLineItem
        WHERE OpportunityId = :opportunityId
        LIMIT 1
      ];
    } else {
      oli = [
        SELECT
          Id,
          Name,
          Precio_de_lista_antes_de_impuesto__c,
          Descuento_aplicado_antes_de_impuesto__c,
          Subtotal_Precio_Motocicleta__c,
          Valor_seguro_robo__c,
          Impoconsumo__c,
          Accesorios__c,
          Iva__c,
          Entidad_Financiera__c,
          Product2.Name,
          Descuento_valor__c,
          Valor_ARD__c,
          Valor_matrcula__c,
          Soat__c,
          Total_a_Pagar_Motos__c,
          Cuota_inicial__c,
          Colorx__c,
          Casco__c,
          Modelox__c
        FROM OpportunityLineItem
        WHERE OpportunityId = :opportunityId
        LIMIT 1
      ];
    }

    return oli;
  }

  private String getLabelFromValue(String value) {
    List<Schema.PicklistEntry> picklistEntries = Schema.SObjectType.Opportunity.fields.Tipo_de_Pago__c.getPicklistValues();

    for (Schema.PicklistEntry ple : picklistEntries) {
      if (value == ple.getValue()) {
        return ple.getLabel();
      }
    }

    return 'nulo';
  }


  public class CustomDetail {
    public String linea { get; set; }

    public CustomDetail(){}
    public CustomDetail(
      String linea
    ) {
      this.linea = linea;
    }
  }
}