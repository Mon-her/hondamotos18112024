public with sharing class fan_B2BPaymentController {

    final static String ALTERNATIVE_PAYMENT_METHOD_STATUS = 'Active';
    final static String ALTERNATIVE_PAYMENT_METHOD_PROCESSING_MODE = 'External';
    final static String PAYMENT_PROCESSING_MODE = 'External';
    final static String PAYMENT_STATUS = 'Processed';
    final static String PAYMENT_TYPE = 'Sale';

    @AuraEnabled
    public static Map<String, Object> getPayzenParameters(String cartId) {
        try {
            fan_PayzenConfig__c payzenConfig = fan_PayzenConfig__c.getOrgDefaults();

            CartCheckoutSession cartSession = new CartCheckoutSession();
            String accountNumber;
            String amount;

            if(!String.isEmpty(cartId)){
              cartSession = [SELECT OrderId,Order.Account.AccountNumber,Order.OrderNumber,WebCart.WebStore.fan_OperationCenter__c 
                  FROM CartCheckoutSession WHERE WebCartId =: cartId AND IsArchived = false WITH SECURITY_ENFORCED];
  
              amount = String.valueOf(getPaymentTotal(cartId)).replace('.','');
              accountNumber = fan_B2BUtils.resolveAccountNumber(cartSession.order.AccountId);
            }

            Map<String, Object> payzenData = new Map<String, Object> {
                'amount' => amount,
                'ctxMode' => payzenConfig.fan_CtxMode__c,
                'orderId' => cartSession.order.OrderNumber,
                'accountNumber' => accountNumber,
                'operationCenter' => cartSession.WebCart.WebStore.fan_OperationCenter__c,
                'paymentCards' => payzenConfig.fan_PaymentCards__c,
                'siteId' => payzenConfig.fan_SiteId__c,
                'transactionId' => generateTransactionId(),
                'redirectErrorTimeout' => payzenConfig.fan_RedirectErrorTimeout__c,
                'redirectSuccessTimeout' => payzenConfig.fan_RedirectSuccessTimeout__c,
                'urlCheck' => payzenConfig.fan_UrlCheck__c
            };
            
            System.debug('MAP >>> '+payzenData);
            return payzenData;
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }

    @AuraEnabled
    public static Map<String, String> buildSignature(Map<String, String> formParameters) {
        try {
            String transactionDate = generateTransactionDate();
            formParameters.put('vads_trans_date', transactionDate);

            fan_PayzenConfig__c payzenConfig = fan_PayzenConfig__c.getOrgDefaults();

            String signature = fan_VadsSignature.buildSignature(
                payzenConfig.fan_SignatureAlgorithm__c,
                formParameters,
                payzenConfig.fan_SecretKey__c
            );
	        return new Map<String, String> {
                'signature' => signature,
                'vads_trans_date' => transactionDate
            };
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }

    @TestVisible
    static String generateTransactionDate() {
        return Datetime.now().formatGmt('yyyyMMddHHmmss');
    }

    /**
     * Creates a string like au4145, where the first character is a random letter, the second is current hour represented as a letter,
     * and the last four characters are the current minute and second respectively.
     */
    @TestVisible
    static String generateTransactionId() {

        Datetime currentTime = Datetime.now();

        // Lowercase letter "a" in ASCII.
        final Integer A = 97;

        Integer rawHour = A + currentTime.hourGmt();

        String hour = String.fromCharArray(new List<Integer> { rawHour });
        String minute = currentTime.formatGmt('mm');
        String second = currentTime.formatGmt('ss');

        // Get a random integer between 0 and 26.
        Integer randomNumber =  Math.mod(Crypto.getRandomInteger(), 26);

        // A letter of the alphabet in ASCII format.
        String randomLetter = String.fromCharArray(new List<Integer> { A + Math.abs(randomNumber) });

        return randomLetter + hour + minute + second;
    }

    @AuraEnabled
    public static void registerPayment(String cartId, Map<String, Object> parameters){
        try {
            final CartCheckoutSession cartCheckoutSession = [SELECT Order.AccountId, WebCart.fan_MetodoPago__c
                                                            FROM CartCheckoutSession WHERE WebCartId =: cartId AND IsArchived = false
                                                            WITH SECURITY_ENFORCED];

            final PaymentGroup paymentGroup = new PaymentGroup(SourceObjectId = cartCheckoutSession.OrderId);
            INSERT paymentGroup;
            Decimal totalToPay = getPaymentTotal(cartId);

            INSERT buildPayment(
                new PaymentGroup(
                    Id = paymentGroup.Id,
                    SourceObject = cartCheckoutSession.Order
                ),
                resolveAlternativePaymentMethod(cartCheckoutSession.Order.AccountId, cartCheckoutSession.WebCart.fan_MetodoPago__c),
                parameters,
                totalToPay
            );
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }

    @TestVisible
    static AlternativePaymentMethod resolveAlternativePaymentMethod(String accountId, String paymentMethod) {

        final List<AlternativePaymentMethod> alternativePaymentMethods = [SELECT NickName FROM AlternativePaymentMethod
                                                                            WHERE AccountId =: accountId AND NickName =: paymentMethod
                                                                            AND Status =: ALTERNATIVE_PAYMENT_METHOD_STATUS];
        if(alternativePaymentMethods.isEmpty()) {
            AlternativePaymentMethod alternativePaymentMethod = new AlternativePaymentMethod(
                AccountId = accountId,
                NickName = paymentMethod,
                ProcessingMode = ALTERNATIVE_PAYMENT_METHOD_PROCESSING_MODE,
                Status = ALTERNATIVE_PAYMENT_METHOD_STATUS
            );
            INSERT alternativePaymentMethod;
            return alternativePaymentMethod;
        } else {
            return alternativePaymentMethods.get(0);
        }
    }

    /** @param value String integers */
    @TestVisible
    static Integer extractInteger(String value, Integer startIndex, Integer endIndex) {
        return Integer.valueOf(value.substring(startIndex, endIndex));
    }

    /** @param value vads_trans_date - transaction date */
    @TestVisible
    static Datetime resolveTransactionDate(Object value) {
        // 20021123095324 -> yyyyMMddHHmmss
        final String transactionDate = value == null ? generateTransactionDate() : String.valueOf(value);

        final Integer year = extractInteger(transactionDate, 0, 4);
        final Integer month = extractInteger(transactionDate, 4, 6);
        final Integer day = extractInteger(transactionDate, 6, 8);
        final Integer hour = extractInteger(transactionDate, 8, 10);
        final Integer minute = extractInteger(transactionDate, 10, 12);
        final Integer second = extractInteger(transactionDate, 12, 14);

        return Datetime.newInstanceGmt(year, month, day, hour, minute, second);
    }

    @TestVisible
    static Payment buildPayment(PaymentGroup paymentGroup, AlternativePaymentMethod alternativePaymentMethod, Map<String, Object> parameters, Decimal totalToPay) {

        final Object gatewayRefDetails = ((Map<Object, Object>) parameters.get('gatewayRefDetails'))
        .get(alternativePaymentMethod.NickName.toUpperCase());
        return new Payment(
            AccountId = paymentGroup.SourceObject.AccountId,
            PaymentGroupId = paymentGroup.Id,
            PaymentMethodId = alternativePaymentMethod.Id,
            Status = (alternativePaymentMethod.NickName == 'RED_AVAL' ||  alternativePaymentMethod.NickName == 'BCO_BOGOTA_OFC') ? 'Draft' : PAYMENT_STATUS,
            Type = PAYMENT_TYPE,
            ProcessingMode = PAYMENT_PROCESSING_MODE,
            Amount = totalToPay,
            GatewayRefNumber = String.valueOf(parameters.get('authNumber')),
            GatewayRefDetails = String.valueOf(gatewayRefDetails),
            Date = resolveTransactionDate(parameters.get('transactionDate'))
        );
    }
    static Decimal getPaymentTotal(String cartId) {
        WebCart cart = [SELECT fan_totalOrdered__c, TotalChargeAmount, TotalTaxAmount FROM WebCart WHERE Id = :cartId];
        Decimal totalToPay = cart.fan_totalOrdered__c + cart.TotalChargeAmount + cart.TotalTaxAmount;

        System.debug('TOTAL TO PAY >>> ' + totalToPay);
        return totalToPay.setScale(2);
    }

    @AuraEnabled
    public static Double getValorAnticipo(String cartId){
        try {

            //Avoid getting null if the cartId is an OrderSummaryId
            cartId = fan_B2BCartCtrlUtils.getCartId(cartId) != null ? fan_B2BCartCtrlUtils.getCartId(cartId) : cartId;

            Double valueToSend = 0;

            Id accountId = [SELECT AccountId FROM WebCart WHERE Id =: cartId LIMIT 1].AccountId;
            Account account = [SELECT ParentId, Parent.fan_valorAnticipo__c, fan_valorAnticipo__c  FROM Account Where Id =: accountId][0];

            if(String.isBlank(account.ParentId)){
                valueToSend =  account.fan_valorAnticipo__c;
            }
            else {
                valueToSend = account.Parent.fan_valorAnticipo__c;
            }
            
            return valueToSend;
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }
    private static void paymentValorAnticipo(String cartId, Decimal totalToPay, String accountId){
        try {
            System.debug('INICIA PAYMENT VALOR ANTICIPO'); 
            
            Account account = [SELECT ParentId, Parent.fan_valorAnticipo__c,fan_valorAnticipo__c FROM Account WHERE Id =: accountId ];

            //Is NOT a parent Account
            if(String.isBlank(account.ParentId)){
                account.fan_valorAnticipo__c -= totalToPay;
                UPDATE account;
            } else {
                //It is a Parent Account
                Account parentAccount = [SELECT id,fan_valorAnticipo__c FROM account WHERE id =: account.ParentId ];
                parentAccount.fan_valorAnticipo__c -= totalToPay;
                UPDATE parentAccount;
            }
        
            System.debug('TERMINA PAYMENT VALOR ANTICIPO'); 
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }
    
    public static void registerAnticipoPayment(Id cartId){
        try {
            final CartCheckoutSession cartCheckoutSession = [SELECT Order.AccountId
                                                            FROM CartCheckoutSession WHERE WebCartId =: cartId AND IsArchived = false
                                                            WITH SECURITY_ENFORCED];

            final PaymentGroup paymentGroup = new PaymentGroup(SourceObjectId = cartCheckoutSession.OrderId);
            UPSERT paymentGroup;
            Decimal totalToPay = getPaymentTotal(cartId); 

            PaymentGroup paymentGroupToCreate = new PaymentGroup(
            Id = paymentGroup.Id,
            SourceObject = cartCheckoutSession.Order);

            UPSERT paymentGroupToCreate; 

            AlternativePaymentMethod alternative = resolveAlternativePaymentMethod(cartCheckoutSession.Order.AccountId, 'anticipo');
            
            Payment pago =  new Payment(
                AccountId = paymentGroupToCreate.SourceObject.AccountId,
                PaymentGroupId = paymentGroupToCreate.Id,
                PaymentMethodId = alternative.Id,
                Status = (alternative.NickName == 'RED_AVAL' ||  alternative.NickName == 'BCO_BOGOTA_OFC') ? 'Draft' : PAYMENT_STATUS,
                Type = PAYMENT_TYPE,
                ProcessingMode = PAYMENT_PROCESSING_MODE,
                Amount = totalToPay,
                GatewayRefNumber = '',
                GatewayRefDetails = '',
                Date = Datetime.now()
            );
            UPSERT pago;
            //Execute payment with valor anticipo
            paymentValorAnticipo(cartId, totalToPay, cartCheckoutSession.Order.AccountId);

        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }
}