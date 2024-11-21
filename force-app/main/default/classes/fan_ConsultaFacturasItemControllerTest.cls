@IsTest
class fan_ConsultaFacturasItemControllerTest {

    @TestSetup
    static void makeData(){
        INSERT new fan_ServiceEndpoint__c(
            usuario__c = 'test user',
            contrasena__c = 'test password',
            url__c = 'http://example.com'
        );
    }

    @IsTest
    static void getInvoiceItems() {

		String factura = '239875614';

        Test.setMock(WebServiceMock.class, new fan_ConsultaFacturasItemMock());
        fan_ConsultaFacturasItemMock.factura = factura;

        Test.startTest();
        List<fan_ConsultaFacturasItemController.InvoiceItem> invoiceItems = fan_ConsultaFacturasItemController.getInvoiceItems(factura);
        Test.stopTest();

        fan_ConsultaFacturasItemController.InvoiceItem invoiceItem = invoiceItems?.get(0);

        Assert.isFalse(invoiceItems.isEmpty(), 'Rows is empty.');
        Assert.areEqual(factura, invoiceItem.document, 'The document is not as expected.');
        Assert.areEqual('FLM-4642', invoiceItem.reference, 'The reference is not as expected.');
        Assert.areEqual('MOTOCICLETA FLM-4642', invoiceItem.referenceDescription, 'The reference description is not as expected.');
        Assert.areEqual('2022-06-21', invoiceItem.issueDate, 'The issue date is not as expected.');
        Assert.areEqual(1, invoiceItem.quantity, 'The quantity is not as expected.');
        Assert.areEqual(19133858, invoiceItem.unitPrice, 'The unit price is not as expected.');
        Assert.areEqual(0.14, invoiceItem.discountRate, 'The discount rate is not as expected.');
        Assert.areEqual(16455118, invoiceItem.subtotal, 'The subtotal is not as expected.');
        Assert.areEqual(0.19, invoiceItem.feeRate, 'The fee rate is not as expected.');
        Assert.areEqual(3126472, invoiceItem.feeValue, 'The fee value is not as expected.');
        Assert.areEqual(19581590, invoiceItem.netValue, 'The net value is not as expected.');
    }

    @IsTest
    static void getInvoiceItemsWithInvalidFacturaArgument() {

        Test.setMock(WebServiceMock.class, new fan_ConsultaFacturasItemMock());

        Test.startTest();
        List<fan_ConsultaFacturasItemController.InvoiceItem> invoiceItems = fan_ConsultaFacturasItemController.getInvoiceItems('75317531');
        Test.stopTest();

        Assert.isTrue(invoiceItems.isEmpty(), 'Invoice items is not empty.');
    }

    @IsTest
    static void getInvoiceItemsWithReadTimedOutException() {

        Test.setMock(WebServiceMock.class, new fan_ConsultaFacturasItemMock());
        fan_ConsultaFacturasItemMock.isReadTimedOutException = true;

        try {
            Test.startTest();
            List<fan_ConsultaFacturasItemController.InvoiceItem> invoiceItems = fan_ConsultaFacturasItemController.getInvoiceItems('1357135');
            Test.stopTest();
            Assert.fail('An exception was expected.');
        } catch (Exception e) {
            Assert.isInstanceOfType(e, AuraHandledException.class, 'An AuraHandledException was expected.');
        }
    }
}