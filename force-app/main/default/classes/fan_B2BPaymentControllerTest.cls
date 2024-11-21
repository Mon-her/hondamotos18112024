@IsTest
public class fan_B2BPaymentControllerTest {

    @TestSetup
    static void setup() {

        Account account = fan_B2BTestDataFactory.createAccount('12312', 'Pasaporte');

        WebStore webStore = fan_B2BTestDataFactory.createWebStore('Test WebStore');
        WebCart cart = fan_B2BTestDataFactory.createWebCart(webStore.Id, account.Id, null);
        Order order = fan_B2BTestDataFactory.createOrder(account.Id, null);

        fan_B2BTestDataFactory.createCartCheckoutSession(order.Id, cart.Id);

        fan_B2BTestDataFactory.createAlternativePaymentMethod(account.Id);
        fan_B2BTestDataFactory.createPayzenConfig();
    }

    @IsTest
    static void getPayzenParameters() {

        String cartId = [SELECT Id FROM WebCart LIMIT 1].Id;
        String orderNumber = [SELECT OrderNumber FROM Order LIMIT 1].OrderNumber;

        Map<String, Object> payzenParameters = fan_B2BPaymentController.getPayzenParameters(cartId);

        Assert.areEqual('TEST', payzenParameters.get('ctxMode'), 'The ctxMode Id is not as expected.');
        Assert.areEqual(orderNumber, payzenParameters.get('orderId'), 'The Order Id is not as expected.');
        Assert.areEqual('VISA;MASTERCARD', payzenParameters.get('paymentCards'), 'The paymentCards Id is not as expected.');
        Assert.areEqual('12345678', payzenParameters.get('siteId'), 'The siteId is not as expected.');
        Assert.areEqual(5, payzenParameters.get('redirectErrorTimeout'), 'The redirectErrorTimeout is not as expected.');
        Assert.areEqual(3, payzenParameters.get('redirectSuccessTimeout'), 'The redirectSuccessTimeout is not as expected.');
        Assert.areEqual('https://IPN-listener', payzenParameters.get('urlCheck'), 'The urlCheck is not as expected.');
    }

    @IsTest
    static void buildSignature() {

        Map<String, String> signatureResult = fan_B2BPaymentController.buildSignature(new Map<String, String> {
            'vads_ctx_mode' => 'TEST'
        });

        System.assert(!signatureResult.keySet().isEmpty(), 'The signature result is empty.');
    }

    @IsTest
    static void buildSignatureWithoutSecretKey() {

        fan_PayzenConfig__c payzenConfig = [SELECT Id FROM fan_PayzenConfig__c LIMIT 1];
        payzenConfig.fan_SecretKey__c = '';
        UPDATE payzenConfig;

        try {
            fan_B2BPaymentController.buildSignature(new Map<String, String> {
                'vads_ctx_mode' => 'TEST'
            });
            System.assert(false, 'An exception was expected.');
        } catch (Exception e) {
            // There is not registered Secret Key.
            System.assert(e instanceOf AuraHandledException, 'The exception is not AuraHandledException.');
        }
    }

    @IsTest
    static void generateTransactionId() {

        String transactionId = fan_B2BPaymentController.generateTransactionId();

        System.assert(String.isNotBlank(transactionId), 'The transaction id is blank.');
    }

    @IsTest
    static void registerPayment() {
        String accountId = [SELECT Id FROM Account LIMIT 1].Id;
        WebCart webCart = [SELECT Id FROM WebCart LIMIT 1];
        webCart.fan_MetodoPago__c = 'Tarjeta'; // When a payment is made.
        UPDATE webCart;

        Map<String, Object> parameters = new Map<String, Object> {
            'authNumber' => '1753135',
            'transactionDate' => '20021123095324',
            'gatewayRefDetails' => new Map<Object, Object> { 'TARJETA' => 'VISA5391' }
        };
        fan_B2BPaymentController.registerPayment(WebCart.Id, parameters);

        Payment payment = [SELECT GatewayRefNumber, GatewayRefDetails FROM Payment WHERE AccountId =: accountId];

        Assert.areEqual('1753135', payment.GatewayRefNumber, 'The GatewayRefNumber of the Payment is not expected.');
        Assert.areEqual('VISA5391', payment.GatewayRefDetails, 'The GatewayRefDetails of the Payment is not expected.');
    }

    @IsTest
    static void registerPaymentWithInvalidArguments() {
        try {
            fan_B2BPaymentController.registerPayment(null, null);
            Assert.fail('An exception was expected.');
        } catch(Exception e) {
            Assert.isInstanceOfType(e, AuraHandledException.class, 'An AuraHandledException was expected.');
        }
    }

    @IsTest
    static void resolveAlternativePaymentMethodWithPse() {

        String accountId = [SELECT Id FROM Account LIMIT 1].Id;
        String paymentMethod = 'Pse';

        AlternativePaymentMethod result = fan_B2BPaymentController.resolveAlternativePaymentMethod(accountId, paymentMethod);
        String alternativePaymentMethodNickname = [SELECT Nickname FROM AlternativePaymentMethod
                                                    WHERE Id =: result.Id].NickName;

        Assert.areEqual('Pse', result.NickName, 'The Nickname of the AlternativePaymentMethod is not as expected.');
    }

    @IsTest
    static void resolveAlternativePaymentMethodWithTarjeta() {

        String accountId = [SELECT Id FROM Account LIMIT 1].Id;
        String paymentMethod = 'Tarjeta';

        AlternativePaymentMethod result = fan_B2BPaymentController.resolveAlternativePaymentMethod(accountId, paymentMethod);
        String alternativePaymentMethodNickname = [SELECT Nickname FROM AlternativePaymentMethod
                                                    WHERE Id =: result.Id].NickName;

        Assert.areEqual(alternativePaymentMethodNickname, result.NickName, 'The Nickname of the AlternativePaymentMethod is not as expected.');
    }

    @IsTest
    static void extractInteger() {

        Integer year = fan_B2BPaymentController.extractInteger('20021123095324', 0, 4);

        Assert.areEqual(2002, year, 'The result of the extractInteger is not as excepted.');
    }

    @IsTest
    static void resolveTransactionDateWithStringArgument() {

        Datetime transactionDate = fan_B2BPaymentController.resolveTransactionDate('20021123095324');
        Datetime expectedResult = Datetime.newInstanceGmt(2002, 11, 23, 09, 53, 24);

        Assert.areEqual(expectedResult, transactionDate, 'The transactionDate is not as excepted.');
    }

    @IsTest
    static void resolveTransactionDateWithNullArgument() {

        Datetime transactionDate = fan_B2BPaymentController.resolveTransactionDate(null);

        Assert.isNotNUll(transactionDate, 'The transactionDate is null.');
    }

    @IsTest
    static void buildPayment() {

        String accountId = [SELECT Id FROM Account LIMIT 1].Id;
        AlternativePaymentMethod alternativePaymentMethod = [SELECT Nickname FROM AlternativePaymentMethod LIMIT 1];
        Order order = [SELECT AccountId, GrandTotalAmount FROM Order LIMIT 1];

        PaymentGroup paymentGroup = new PaymentGroup(
            SourceObject = Order
        );
        Map<String, Object> parameters = new Map<String, Object> {
            'authNumber' => '1753135',
            'transactionDate' => '20021123095324',
            'gatewayRefDetails' => new Map<Object, Object> { 'PSE' => 'PSE35157397953' }
        };
        Payment payment = fan_B2BPaymentController.buildPayment(paymentGroup, alternativePaymentMethod, parameters, 871);

        Assert.areEqual(accountId, payment.AccountId, 'The AccountId of the Payment is not as expected.');
        Assert.areEqual(paymentGroup.Id, payment.PaymentGroupId, 'The PaymentGroupId of the Payment is not as expected.');
        Assert.areEqual(alternativePaymentMethod.Id, payment.PaymentMethodId, 'The PaymentMethodId of the Payment is not as expected.');
        Assert.areEqual(871, payment.Amount, 'The Amount of the Payment is not as expected.');
        Assert.areEqual(parameters.get('authNumber'), payment.GatewayRefNumber, 'The GatewayRefNumber of the Payment is not as expected.');
        Assert.areEqual('PSE35157397953', payment.GatewayRefDetails, 'The GatewayRefDetails of the Payment is not as expected.');
    }

    @IsTest
    static void generateTransactionDate() {

        String transactionDate = fan_B2BPaymentController.generateTransactionDate();

        Assert.isNotNull(transactionDate, 'The transaction date is null.');
    }

    @IsTest
    static void getValorAnticipoTest() {
        // Obiene datos de prueba
        WebCart cart = [SELECT Id, AccountId FROM WebCart WHERE WebStore.Name = 'Test WebStore' LIMIT 1][0];

        Account account = [SELECT Id,fan_valorAnticipo__c FROM Account WHERE Id =: cart.AccountId];
        account.fan_valorAnticipo__c = 500.00;

        UPDATE Account;

        Test.startTest();


        // Llamar al método getValorAnticipo
        Double valorAnticipo = fan_B2BPaymentController.getValorAnticipo(cart.Id);

        // Verificar que el valor de anticipo devuelto sea el esperado
        System.assertEquals(500.00, valorAnticipo, 'El valor de anticipo no coincide');
        Test.stopTest();
    }

    @IsTest
    static void registerAnticipoPaymentTest() {
        // Obiene datos de prueba
        WebCart cart = [SELECT Id, AccountId FROM WebCart WHERE WebStore.Name = 'Test WebStore' LIMIT 1][0];
        Order orden = [SELECT Id FROM Order WHERE AccountId =: cart.AccountId];

        CartCheckoutSession cartCheckoutSession = [SELECT Id,OrderId FROM CartCheckoutSession WHERE OrderId =: orden.Id];

        Test.startTest();

        // Llamar al método registerAnticipoPayment
        fan_B2BPaymentController.registerAnticipoPayment(cart.Id);

        // Verificar que se haya creado el PaymentGroup y el Payment correctamente
        List<PaymentGroup> paymentGroups = [SELECT Id FROM PaymentGroup WHERE SourceObjectId = :cartCheckoutSession.OrderId];
        System.assertEquals(1, paymentGroups.size(), 'No se creó correctamente el PaymentGroup');

        List<Payment> pagos = [SELECT Id FROM Payment WHERE PaymentGroupId = :paymentGroups[0].Id];
        System.assertEquals(1, pagos.size(), 'No se creó correctamente el Payment');
        Test.stopTest();
    }
}