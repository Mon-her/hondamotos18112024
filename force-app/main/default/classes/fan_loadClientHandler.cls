public with sharing class fan_loadClientHandler {

  final static String BILLING_KEY = '000';
  final static String PERSON_ACCOUNT_PREFIX = 'NP';
  final static String PERSON_ACCOUNT_CODE = '1';

  private static fan_ServiceEndpoint__c getSettings(String serviceName) {
    List<fan_ServiceEndpoint__c> settings = [
      SELECT usuario__c, url__c, Nombre__c, contrasena__c
      FROM fan_ServiceEndpoint__c
      WHERE Nombre__c = :serviceName];

    if (settings.size() == 0) {
      throw new HandledException('Settings not found to: ' + serviceName);
    }

    return settings[0];
  }

  public static fan_CargaClientes.row_element[] getData() {
    fan_ServiceEndpoint__c settings = getSettings('Fanalca');
    fan_CargaClientes.HTTPS_Port port = new fan_CargaClientes.HTTPS_Port(
      settings.url__c
    );
    String[] tercero = new List<String>{ '' };

    port.inputHttpHeaders_x = new Map<String, String>();

    Blob headerValue = Blob.valueOf(
      settings.usuario__c +
      ':' +
      settings.contrasena__c
    );
    String authorizationHeader =
      'Basic ' + EncodingUtil.base64Encode(headerValue);
    port.inputHttpHeaders_x.put('Authorization', authorizationHeader);
    port.inputHttpHeaders_x.put('Content-Type', 'text/xml');

    fan_CargaClientes.row_element[] rows = port.POST('X');
    System.debug('Response rows' + rows);
    return rows;
  }

  public static String formatDocumentNumber(fan_CargaClientes.row_element row) {
    String documentNumber = row.TERCERO;
      if(row.PJURIDICA == PERSON_ACCOUNT_CODE) {
        documentNumber = PERSON_ACCOUNT_PREFIX + row.TERCERO;
      }
      return documentNumber;
  }

  public static Account accountFormat(String documentNumber, fan_CargaClientes.row_element row) {
    Account account = generalAccountData(row);
    
    account.AM_Numero_de_documento__c = documentNumber;
    account.Name = row.RSOCIAL;
    account.AccountNumber = row.TERCERO;

    return account;
  }

  public static Account subAccountFormat(fan_CargaClientes.row_element row, String parentId) {
    Account account = generalAccountData(row);
    
    account.AM_Numero_de_documento__c = row.TERCERO + row.SUCURSAL;
    account.Name = row.SUC_SUCURSAL;
    account.AccountNumber = row.TERCERO + row.SUCURSAL;
    account.ParentId = parentId;

    return account;
  }

  private static Account generalAccountData(fan_CargaClientes.row_element row){
    Account account = new Account(
      AM_Tipo_de_documento__c = 'NIT',
      fan_condicionPago__c = row.CRE_CONDPAGO,
      fan_aplicaIVA__c = row.IMPUESTOS == 'Si',
      fan_aplicaIVAC__c = row.RETENCIONES == 'Si',
      fan_plan_ARE__c = row.CLAS_PLAN_ARE,
      fan_plan_ASV__c = row.CLAS_PLAN_ASV,
      fan_plan_CAN__c = row.CLAS_PLAN_CAN,
      fan_plan_CL1__c = row.CLAS_PLAN_CL1,
      fan_plan_DST__c = row.CLAS_PLAN_DST,
      fan_plan_INT__c = row.CLAS_PLAN_INT,
      fan_plan_POS__c = row.CLAS_PLAN_POS,
      fan_plan_REG__c = row.CLAS_PLAN_REG,
      fan_plan_VE__c = row.CLAS_PLAN_VE,
      fan_plan_VP__c = row.CLAS_PLAN_VP,
      fan_plan_WMT__c = row.CLAS_PLAN_WMT,
      fan_plan_ZDC__c = row.CLAS_PLAN_ZDC,
      fan_plan_ZDD__c = row.CLAS_PLAN_ZDD,
      fan_plan_ZON__c = row.CLAS_PLAN_ZON,
      fan_plan_ZRP__c = row.CLAS_PLAN_ZRP
    );

    return account;
  }

  private static String codeFormat(String addressType) {
    String code = '';
    if (addressType == fan_Constants.ContactPointAddressType.BILLING.name()) {
      code = 'B-';
    } else if (addressType == fan_Constants.ContactPointAddressType.SHIPPING.name()) {
      code = 'S-';
    }
    return code;
  }

  public static ContactPointAddress contactPointFormat(
    String prefix,
    fan_CargaClientes.row_element row,
    String parentId,
    String subAccountNumber
  ) {
    String addressType = row.PENV_ID == BILLING_KEY ? fan_Constants.ContactPointAddressType.BILLING.name() : fan_Constants.ContactPointAddressType.SHIPPING.name();
    String pId = codeFormat(addressType);

    ContactPointAddress contactPoint = new ContactPointAddress(
      fan_Code__c = prefix + pId + subAccountNumber + row.PENV_ID,
      AddressType = addressType,
      City = row.PENV_CIUDAD,
      Country = row.PENV_PAIS,
      Street = row.PENV_DIRECCION1,
      State = row.PENV_DEPTO_ESTADO,
      ParentId = parentId,
      Name = row.SUC_SUCURSAL
    );
    return contactPoint;
  }
}