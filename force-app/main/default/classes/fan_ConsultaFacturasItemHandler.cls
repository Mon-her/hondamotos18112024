public class fan_ConsultaFacturasItemHandler {

    @TestVisible
    static String buildAuthorizationHeader(String username, String password) {
        return 'Basic ' + EncodingUtil.base64Encode(
            Blob.valueOf(username + ':' + password)
        );
    }

    public static List<fan_ConsultaFacturasItem.row_element> getData(String factura) {

        fan_ServiceEndpoint__c serviceEndpoint = fan_ServiceEndpoint__c.getOrgDefaults();

        fan_ConsultaFacturasItem.HTTPS_Port port = new fan_ConsultaFacturasItem.HTTPS_Port(serviceEndpoint.url__c);
        port.inputHttpHeaders_x = new Map<String, String> {
	        'Authorization' => buildAuthorizationHeader(serviceEndpoint.usuario__c, serviceEndpoint.contrasena__c),
            'Content-Type' => 'text/xml'
        };
        return port.POST(factura);
    }
}