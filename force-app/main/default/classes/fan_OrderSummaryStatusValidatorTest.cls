@IsTest
class fan_OrderSummaryStatusValidatorTest {

    @TestSetup
    static void makeData(){
        fan_B2BTestDataFactory.createServiceEndpoint('fanalca', 'https://fanalca.com');
    }

    @IsTest
    static void scheduleOrderSummaryStatusValidator() {

        fan_OrderSummaryStatusValidator.testOrderSummaries = generateOrderSummaries();

        fan_OrderSummaryStatusValidator orderSummaryStatusValidator = new fan_OrderSummaryStatusValidator();

        Test.startTest();
        Test.setMock(WebServiceMock.class, new fan_ConsultaCupoMock());
        System.schedule('Validador de Estado de Resumenes de Pedidos - Diurno Test', '0 0 23 * * ?', orderSummaryStatusValidator);
        Test.stopTest();
    }

    static OrderSummary[] generateOrderSummaries() {

        Account account = new Account(AccountNumber = '0918276534');

        JSONGenerator gen = JSON.createGenerator(false);
        gen.writeStartArray();
            gen.writeStartObject();
                gen.writeStringField('Status', 'APROBADO');
                gen.writeNumberField('GrandTotalAmount', 5000);
                gen.writeNumberField('Total_Valor_Pendiente_Impuestos__c', 5000);
                gen.writeObjectField('Account', account);
            gen.writeEndObject();
        gen.writeEndArray();
        gen.close();

        return (OrderSummary[]) JSON.deserialize(gen.getAsString(), OrderSummary[].class);
    }
}