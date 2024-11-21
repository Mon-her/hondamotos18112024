@isTest
public class fan_InsertCorePedidoTest {

    @TestSetup
    static void makeData(){
        String code = fan_InfoFletes__mdt.getInstance('producto').Label;
        fan_B2BTestDataFactory.createProduct(code, code, null);
    }
    
    @isTest static void fan_InsertCorePedidoTestCallout() {
        String accountNumber = '000000001';
        FulFillmentOrderLineItem fulFillmentOrderLineItem = generateFulFillmentOrderLineItem('PS-' + accountNumber + '328001');
        FulFillmentOrder fulFillmentOrder = generateFulFillmentOrder(accountNumber, new FulFillmentOrderLineItem[] { fulFillmentOrderLineItem });
        
        Test.setMock(HttpCalloutMock.class, new fan_InsertCorePedidoMock());
        
        Test.startTest();
        fan_InsertCorePedido.testFulFillmentOrders = new FulFillmentOrder[] { fulFillmentOrder };
        fan_InsertCorePedido.validateCreditLine(new List<String> { 'Anything' });
        Test.stopTest();
        
    }

    static FulFillmentOrder generateFulFillmentOrder(String accountNumber, FulFillmentOrderLineItem[] fulFillmentOrderLineItems) {
        JSONGenerator generator = JSON.createGenerator(false);
        generator.writeStartObject();
            generator.writeFieldName('Account');
            generator.writeStartObject();
                generator.writeStringField('AccountNumber', accountNumber);
                generator.writeStringField('fan_condicionPago__c', '30D');
            generator.writeEndObject();
            generator.writeFieldName('OrderSummary');
            generator.writeStartObject();
                generator.writeStringField('SalesStoreId', fan_IdTienda__mdt.getInstance('motos').fan_IdTienda__c);
                generator.writeStringField('fan_TipoPedido__c', 'RMT_Normal');
                generator.writeStringField('fan_OrderFormaPago__c', 'credito');
            generator.writeEndObject();
            generator.writeFieldName('FulfillmentOrderLineItems');
            generator.writeStartObject();
                generator.writeNumberField('totalSize', 1);
                generator.writeBooleanField('done', true);
                generator.writeObjectField('records', fulFillmentOrderLineItems);
            generator.writeEndObject();
        generator.writeEndObject();
        generator.close();
        return (FulFillmentOrder) JSON.deserialize(generator.getAsString(), FulFillmentOrder.class);
    }

    static FulFillmentOrderLineItem generateFulFillmentOrderLineItem(String orderGroupCode) {
        JSONGenerator generator = JSON.createGenerator(false);
        generator.writeStartObject();
            generator.writeNumberField('Quantity', 1);
            generator.writeNumberField('TotalAdjustmentAmount', 37);
            generator.writeDateField('CreatedDate', Date.today());
            generator.writeObjectField('Product2', new Product2(fan_Classification__c = 'CBU'));
            generator.writeFieldName('OrderItemSummary');
            generator.writeStartObject();
                generator.writeStringField('fan_FormattedPaymentCondition__c', '30D');
                generator.writeFieldName('OrderDeliveryGroupSummary');
                generator.writeStartObject();
                    generator.writeFieldName('OriginalOrderDeliveryGroup');
                    generator.writeStartObject();
                        generator.writeStringField('fan_Code__c', orderGroupCode);
                    generator.writeEndObject();
                generator.writeEndObject();
            generator.writeEndObject();
        generator.writeEndObject();
        generator.close();
        return ((FulFillmentOrderLineItem) JSON.deserialize(generator.getAsString(), FulFillmentOrderLineItem.class));
    }
}