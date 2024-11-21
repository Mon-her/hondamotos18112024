public with sharing class fan_PricebookHandler {

    static fan_ServiceEndpoint__c getServiceEndpoint(String serviceName) {
      fan_ServiceEndpoint__c[] serviceEndpoints = [SELECT url__c, usuario__c, contrasena__c FROM fan_ServiceEndpoint__c
                                                    WHERE Nombre__c = :serviceName];

      if (serviceEndpoints.isEmpty()) {
        throw new HandledException('Settings not found to: ' + serviceName);
      }
      return serviceEndpoints[0];
    }

    public static fan_Pricebook.row_element[] getPricebookEntries(String pricebookName, String pageNumber) {

      fan_ServiceEndpoint__c serviceEndpoint = getServiceEndpoint('Fanalca');
      fan_Pricebook.HTTPS_Port port = new fan_Pricebook.HTTPS_Port(serviceEndpoint.url__c);

      Blob headerValue = Blob.valueOf(serviceEndpoint.usuario__c + ':' + serviceEndpoint.contrasena__c);
      port.inputHttpHeaders_x = new Map<String, String> {
        'Authorization' => 'Basic ' + EncodingUtil.base64Encode(headerValue),
        'Content-Type' => 'text/xml'
      };
      return port.POST(pricebookName, pageNumber);
    }
}