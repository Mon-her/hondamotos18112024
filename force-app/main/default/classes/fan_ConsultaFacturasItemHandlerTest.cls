@IsTest
class fan_ConsultaFacturasItemHandlerTest {

    @TestSetup
    static void makeData(){
        INSERT new fan_ServiceEndpoint__c(
            usuario__c = 'test user',
            contrasena__c = 'test password',
            url__c = 'http://example.com'
        );
    }

    @IsTest
    static void buildAuthorizationHeader() {

        fan_ServiceEndpoint__c serviceEndpoint = fan_ServiceEndpoint__c.getOrgDefaults();

        String authorizationHeader = fan_ConsultaFacturasItemHandler.buildAuthorizationHeader(serviceEndpoint.usuario__c, serviceEndpoint.contrasena__c);

        String testAuthorizationHeader = 'Basic ' + EncodingUtil.base64Encode(
            Blob.valueOf(serviceEndpoint.usuario__c + ':' + serviceEndpoint.contrasena__c)
        );

        Assert.areEqual(testAuthorizationHeader, authorizationHeader, 'Authorization header is not as expected.');
    }

    @IsTest
    static void getData() {

		String factura = '239875614';

        Test.setMock(WebServiceMock.class, new fan_ConsultaFacturasItemMock());
        fan_ConsultaFacturasItemMock.factura = factura;

        Test.startTest();
        List<fan_ConsultaFacturasItem.row_element> rows = fan_ConsultaFacturasItemHandler.getData(factura);
        Test.stopTest();

        fan_ConsultaFacturasItem.row_element firstRow = rows?.get(0);

        Assert.isFalse(rows.isEmpty(), 'Rows is empty.');
        Assert.areEqual(factura, firstRow.DOCUMENTO, 'The DOCUMENTO is not as expected.');
        Assert.areEqual('FLM-4642', firstRow.REFERENCIA, 'The REFERENCIA is not as expected.');
        Assert.areEqual('MOTOCICLETA FLM-4642', firstRow.DES_REFERENCIA, 'The DES_REFERENCIA is not as expected.');
        Assert.areEqual('2022-06-21', firstRow.FECHA, 'The FECHA is not as expected.');
        Assert.areEqual('1', firstRow.CANTIDAD, 'The CANTIDAD is not as expected.');
        Assert.areEqual('19133858', firstRow.PR_UNITARIO, 'The PR_UNITARIO is not as expected.');
        Assert.areEqual('0.14', firstRow.POR_DESCUENTO, 'The POR_DESCUENTO is not as expected.');
        Assert.areEqual('16455118', firstRow.VALOR_SUBTOTAL, 'The VALOR_SUBTOTAL is not as expected.');
        Assert.areEqual('0.19', firstRow.POR_IMPUESTOS, 'The POR_IMPUESTOS is not as expected.');
        Assert.areEqual('3126472', firstRow.VALOR_IMPUESTOS, 'The VALOR_IMPUESTOS is not as expected.');
        Assert.areEqual('19581590', firstRow.VALOR_NETO, 'The VALOR_NETO is not as expected.');
    }
}