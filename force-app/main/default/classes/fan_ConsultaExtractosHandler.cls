public class fan_ConsultaExtractosHandler {

    @TestVisible
    static String buildAuthorizationHeader(String username, String password) {
        return 'Basic ' + EncodingUtil.base64Encode(
            Blob.valueOf(username + ':' + password)
        );
    }

    public static List<fan_ConsultaExtractos.row_element> getData(String nitCliente, String startDate, String endDate) {

        fan_ServiceEndpoint__c serviceEndpoint = fan_ServiceEndpoint__c.getOrgDefaults();

        fan_ConsultaExtractos.HTTPS_Port port = new fan_ConsultaExtractos.HTTPS_Port(serviceEndpoint.url__c);
        port.inputHttpHeaders_x = new Map<String, String> {
            'Authorization' => buildAuthorizationHeader(serviceEndpoint.usuario__c, serviceEndpoint.contrasena__c),
            'Content-Type' => 'text/xml'
        };

        return port.POST(nitCliente, startDate, endDate);
    }
}