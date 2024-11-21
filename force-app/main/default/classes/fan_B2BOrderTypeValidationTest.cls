@IsTest
class fan_B2BOrderTypeValidationTest {

    @IsTest
    static void buildOrderTypeValidation() {
        fan_B2BOrderTypeValidation.Builder builder = new fan_B2BOrderTypeValidation.Builder('RMT_Normal');
        builder.setOrderType('RMT_RE');
        builder.setPaymentCondition('contado');
        builder.setIsPaymentConditionChangeable(false);
        builder.setTitle('Invalid order type.');
        builder.setMessage('The order type name is not registered.');
        builder.setShow(true);
        builder.setApplied(true);
        fan_B2BOrderTypeValidation orderTypeValidation = builder.build();

        Assert.areEqual('RMT_RE', orderTypeValidation.orderType, 'The orderType of the orderTypeValidation is not as expected.');
        Assert.areEqual('contado', orderTypeValidation.paymentCondition, 'The paymentCondition of the orderTypeValidation is not as expected.');
        Assert.isFalse(orderTypeValidation.isPaymentConditionChangeable, 'The isPaymentConditionChangeable of the orderTypeValidation is not as expected.');
        Assert.areEqual('Invalid order type.', orderTypeValidation.title, 'The title of the orderTypeValidation is not as expected.');
        Assert.areEqual('The order type name is not registered.', orderTypeValidation.message, 'The message of the orderTypeValidation is not as expected.');
        Assert.isTrue(orderTypeValidation.show, 'The show of the orderTypeValidation is not as expected.');
        Assert.isTrue(orderTypeValidation.applied, 'The applied of the orderTypeValidation is not as expected.');
    }
}