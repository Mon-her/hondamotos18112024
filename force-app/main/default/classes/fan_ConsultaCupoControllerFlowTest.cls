@IsTest
class fan_ConsultaCupoControllerFlowTest {

    @TestSetup
    static void makeData(){
        INSERT fan_B2BTestDataFactory.buildServiceEndpoint('Fanalca', 'host', 'test', '123');
    }

    @IsTest
    static void validateCreditLineUsingAnUnknownAccountNumber() {

        OrderSummary orderSummary = generateOrderSummary('000000000', 25);

        fan_ConsultaCupoControllerFlow.testOrderSummaries = new OrderSummary[] { orderSummary };
        Test.setMock(WebServiceMock.class, new fan_ConsultaCupoMock());
        Test.startTest();
        fan_ConsultaCupoControllerFlow.validateCreditLine(new List<String>());
        Test.stopTest();

        Assert.areEqual('PENDING', orderSummary.Status, 'The status of the OrderSummary is not as expected.');
        Assert.areEqual('SCHEDULE', orderSummary.fan_ScheduleStatus__c, 'The schedule status is not as expected.');
    }

    @IsTest
    static void validateCreditLineShouldSetTheOrderSummaryStatusToAprobado() {

        OrderSummary orderSummary = generateOrderSummary('123456789', 25);

        fan_ConsultaCupoControllerFlow.testOrderSummaries = new OrderSummary[] { orderSummary };

        fan_ConsultaCupoMock.VALOR_VCTO_SIN_CO = '0';
        Test.setMock(WebServiceMock.class, new fan_ConsultaCupoMock());
        Test.startTest();
        fan_ConsultaCupoControllerFlow.validateCreditLine(new List<String>());
        Test.stopTest();

        Assert.areEqual('APROBADO', orderSummary.Status, 'The status of the OrderSummary is not as expected.');
        Assert.areEqual('COMPLETED', orderSummary.fan_ScheduleStatus__c, 'The schedule status is not as expected.');
    }

    @IsTest
    static void validateCreditLineShouldSetTheOrderSummaryStatusToAprobadoForRMT_GarantiaOrderType() {

        Map<String, Object> orderSummaryData = new Map<String, Object> {
            'fan_TipoPedido__c' => 'RMT_Garantia',
            'Account' => new Map<String, String>()
        };
        OrderSummary orderSummary = (OrderSummary) JSON.deserialize(JSON.serialize(orderSummaryData), OrderSummary.class);

        fan_ConsultaCupoControllerFlow.testOrderSummaries = new OrderSummary[] { orderSummary };

        Test.setMock(WebServiceMock.class, new fan_ConsultaCupoMock());
        Test.startTest();
        fan_ConsultaCupoControllerFlow.validateCreditLine(new List<String>());
        Test.stopTest();

        Assert.areEqual('APROBADO', orderSummary.Status, 'The status of the OrderSummary is not as expected.');
        Assert.areEqual('COMPLETED', orderSummary.fan_ScheduleStatus__c, 'The schedule status is not as expected.');
    }

    @IsTest
    static void validateCreditLineShouldSetTheOrderSummaryStatusToPending() {

        OrderSummary orderSummary = generateOrderSummary('987654321', 500);

        fan_ConsultaCupoControllerFlow.testOrderSummaries = new OrderSummary[] { orderSummary };
        Test.setMock(WebServiceMock.class, new fan_ConsultaCupoMock());
        Test.startTest();
        fan_ConsultaCupoControllerFlow.validateCreditLine(new List<String>());
        Test.stopTest();

        Assert.areEqual('PENDING', orderSummary.Status, 'The status of the OrderSummary is not as expected.');
        Assert.areEqual('SCHEDULE', orderSummary.fan_ScheduleStatus__c, 'The schedule status is not as expected.');
    }

    @IsTest
    static void validateCreditLineShouldSetTheOrderSummaryStatusToLocked() {

        OrderSummary orderSummary = generateOrderSummary('123456789', 25);

        fan_ConsultaCupoControllerFlow.testOrderSummaries = new OrderSummary[] { orderSummary };
        Test.setMock(WebServiceMock.class, new fan_ConsultaCupoMock());
        Test.startTest();
        fan_ConsultaCupoControllerFlow.validateCreditLine(new List<String>());
        Test.stopTest();

        Assert.areEqual('LOCKED', orderSummary.Status, 'The status of the OrderSummary is not as expected.');
        Assert.areEqual('SCHEDULE', orderSummary.fan_ScheduleStatus__c, 'The schedule status is not as expected.');
    }

    static OrderSummary generateOrderSummary(String accountNumber, Decimal grandTotalAmount) {
        JSONGenerator generator = JSON.createGenerator(false);
        generator.writeStartObject();
            generator.writeNumberField('fan_OutboundConnectionFailedAttempts__c', 0);
            generator.writeObjectField('Account', new Map<String, String> { 'AccountNumber' => accountNumber});
            generator.writeObjectField('Total_Valor_Pendiente_Impuestos__c', grandTotalAmount);
        generator.writeEndObject();
        generator.close();

        return (OrderSummary) JSON.deserialize(generator.getAsString(), OrderSummary.class);
    }
}