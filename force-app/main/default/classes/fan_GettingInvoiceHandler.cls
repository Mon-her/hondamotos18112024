public with sharing class fan_GettingInvoiceHandler {
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

  public static fan_GettingInvoice.row_element[] getData(
    String idTercero,
    String startDate,
    String endDate
  ) {
    fan_ServiceEndpoint__c settings = getSettings('Fanalca');
    fan_GettingInvoice.HTTPS_Port port = new fan_GettingInvoice.HTTPS_Port(
      settings.url__c
    );

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

    fan_GettingInvoice.row_element[] rows = port.POST(
      IdTercero,
      startDate,
      endDate
    );

    return rows;
  }
}