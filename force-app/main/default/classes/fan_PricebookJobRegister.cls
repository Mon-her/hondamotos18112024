public class fan_PricebookJobRegister implements Queueable, Database.AllowsCallouts {

    @TestVisible
    static String testLinkedEntityId;
    String pricebookName;
    String pageNumber;

    public fan_PricebookJobRegister(String pricebookName, String pageNumber) {
        this.pricebookName = pricebookName;
        this.pageNumber = pageNumber;
    }

    public void execute(QueueableContext context) {

        String title = Datetime.now() + ' ' + pricebookName + '-' + pageNumber;

        fan_ServiceEndpoint__c serviceEndpoint = [SELECT url__c, usuario__c, contrasena__c FROM fan_ServiceEndpoint__c WHERE Nombre__c = 'Fanalca'];
        Blob credentials = Blob.valueOf(serviceEndpoint.usuario__c + ':' + serviceEndpoint.contrasena__c);

        HttpRequest request = new HttpRequest();
        request.setHeader('Authorization', 'Basic ' + EncodingUtil.base64Encode(credentials));
        request.setHeader('Content-Type', 'text/xml');
        request.setMethod('POST');
        request.setEndpoint(serviceEndpoint.url__c + 'XISOAPAdapter/MessageServlet?senderParty=&senderService=BC_SALESFORCE&receiverParty=&receiverService=&interface=SI_Consulta_Lista_Precios_OB&interfaceNamespace=http://fanalca.com/SalesForceConsultaListaPreciosSFC2SapEcc');
        request.setBody(String.format('<soapenv:Envelope xmlns:soapenv="http://schemas.xmlsoap.org/soap/envelope/" xmlns:sal="http://fanalca.com/SalesForceConsultaListaPreciosSFC2SapEcc"><soapenv:Header/><soapenv:Body><sal:MT_Lista_Precios_OUT><ITEM>{0}</ITEM><DETALLE>{1}</DETALLE></sal:MT_Lista_Precios_OUT></soapenv:Body></soapenv:Envelope>', new String[] {
            pricebookName,
            pageNumber
        }));
 
        ContentVersion contentVersion = new ContentVersion(
            ContentLocation = 'S',
            PathOnClient = title + '.xml',
            Title = title,
            VersionData = Blob.valueOf(new Http().send(request).getBody())
        );
        INSERT contentVersion;

        INSERT new ContentDocumentLink(
            LinkedEntityId = Test.isRunningTest() ? testLinkedEntityId : '0036O0000490wvlQAA',
            ContentDocumentId = [SELECT ContentDocumentId FROM ContentVersion WHERE Id = :contentVersion.Id].ContentDocumentId,
            shareType = 'V'
        );
    }
}