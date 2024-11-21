@IsTest
class fan_ConsultaExtractosHandlerTest {

    @TestSetup
    static void makeData(){
        INSERT new fan_ServiceEndpoint__c(
            usuario__c = 'test user',
            contrasena__c = 'test password',
            url__c = 'http://example.com'
        );

        INSERT new Account(
            Name = 'Test Account',
            AccountNumber = '123456789',
            AM_Numero_de_documento__c = '123456789',
            AM_Tipo_de_documento__c = 'NIT'
        );
    }

    @IsTest
    static void buildAuthorizationHeader() {

        fan_ServiceEndpoint__c serviceEndpoint = fan_ServiceEndpoint__c.getOrgDefaults();

        String authorizationHeader = fan_ConsultaExtractosHandler.buildAuthorizationHeader(serviceEndpoint.usuario__c, serviceEndpoint.contrasena__c);

        String testAuthorizationHeader = 'Basic ' + EncodingUtil.base64Encode(
            Blob.valueOf(serviceEndpoint.usuario__c + ':' + serviceEndpoint.contrasena__c)
        );

        Assert.areEqual(testAuthorizationHeader, authorizationHeader, 'Authorization header is not as expected.');
    }

    @IsTest
    static void getData() {

        String nitCliente = [SELECT AccountNumber FROM Account LIMIT 1].AccountNumber;

        Test.setMock(WebServiceMock.class, new fan_ConsultaExtractosMock());
        fan_ConsultaExtractosMock.NITCLIENTE = nitCliente;

        Test.startTest();
        List<fan_ConsultaExtractos.row_element> rows = fan_ConsultaExtractosHandler.getData(nitCliente, '2022-06-04', '2022-09-13');
        Test.stopTest();

        fan_ConsultaExtractos.row_element firstRow = rows?.get(0);

        Assert.isFalse(rows.isEmpty(), 'Rows is empty.');
        Assert.areEqual(nitCliente, firstRow.NIT, 'The NIT is not as expected.');
        Assert.areEqual('2022-06-25', firstRow.FECHA, 'The FECHA is not as expected.');
        Assert.areEqual('DOC-MXBB-319319', firstRow.DOCUMENTO, 'The DOCUMENTO is not as expected.');
        Assert.areEqual('NDE-3135', firstRow.DOCTO_CRUCE, 'The DOCTO_CRUCE is not as expected.');
        Assert.areEqual('2022-07-25', firstRow.VCTO, 'The VCTO is not as expected.');
        Assert.areEqual('46204213', firstRow.VALOR_DOCUMENTO, 'The VALOR_DOCUMENTO is not as expected.');
        Assert.areEqual('46204213', firstRow.SALDO_INICIAL, 'The SALDO_INICIAL is not as expected.');
        Assert.areEqual('0', firstRow.VALOR_APLICADO, 'The VALOR_APLICADO is not as expected.');
        Assert.areEqual('46204213', firstRow.SALDO, 'The SALDO is not as expected.');
        Assert.areEqual('ANTIC. DE CLIENTES', firstRow.AUXILIAR, 'The AUXILIAR is not as expected.');
    }
}