@RestResource(urlMapping='/IPN-listener')
global class fan_PayzenWebhook {

    @TestVisible
    static OrderSummary[] testOrderSummaries;
    @TestVisible
    static OCIInteractionOrderSummary__c[] testOCIInteractionOrderSummaries;

    @TestVisible
    enum CardBrand { RED_AVAL, BCO_BOGOTA_OFC }
    @TestVisible
    enum TransactionStatus { CAPTURED, EXPIRED, REFUSED }
    enum PaymentStatus { CANCELED, DRAFT, PROCESSED }

    @HttpPost
    global static void processIPN() {
        Map<String, String> params = RestContext.request.params;
        try {
            if(UserInfo.getUserType() == fan_Constants.UserType.GUEST.name()) {
                processIPNAsApiOnlyUser(params);
            } else {
                VadsField vadsField = new VadsField(params);
                if(vadsField.hasVadsHash() && (vadsField.cardBrand == CardBrand.RED_AVAL.name() || vadsField.cardBrand == CardBrand.BCO_BOGOTA_OFC.name())) {
                    fan_PayzenConfig__c payzenConfig = fan_PayzenConfig__c.getOrgDefaults();
                    String signature = fan_VadsSignature.buildSignature(payzenConfig.fan_SignatureAlgorithm__c, params, payzenConfig.fan_SecretKey__c);
                    if(vadsField.signature == signature) {
                        handleTransactionStatus(vadsField);
                        updatePaymentStatus(vadsField);
                    }
                }
                INSERT new fan_LogWS__c(fan_body__c = JSON.serialize(params));
            }
        } catch (Exception e) {
            handleIPNError(e, params);
        }
    }

    static String getAuthorizationToken(fan_PayzenIPNConfig__c payzenIPNConfig) {

        HttpRequest request = new HttpRequest();
        request.setMethod('POST');
        request.setHeader('Content-Type', 'application/x-www-form-urlencoded');
        request.setHeader('Accept', 'application/json');
        request.setEndpoint(Url.getOrgDomainUrl().toExternalForm()+'/services/oauth2/token');

        String requestBody = String.format('client_id={0}&client_secret={1}&username={2}&password={3}&grant_type=password', new String[] {
            EncodingUtil.urlDecode(payzenIPNConfig.fan_ClientId__c, 'UTF-8'),
            EncodingUtil.urlDecode(payzenIPNConfig.fan_ClientSecret__c, 'UTF-8'),
            EncodingUtil.urlDecode(payzenIPNConfig.fan_Username__c, 'UTF-8'),
            EncodingUtil.urlDecode(payzenIPNConfig.fan_Password__c + payzenIPNConfig.fan_SecurityToken__c, 'UTF-8')
        });
        request.setBody(requestBody);
        HttpResponse response = new Http().send(request); 

        if(response.getStatusCode() != 200) {
            throw new AuthenticationException('Could not authenticate user');
        }
        Map<String, Object> responseBody = (Map<String, Object>) JSON.deserializeUntyped(response.getBody());
        return responseBody.get('token_type') + ' ' + responseBody.get('access_token');
    }

    static void processIPNAsApiOnlyUser(Map<String, String> params) {

        String authorizationToken = getAuthorizationToken(fan_PayzenIPNConfig__c.getOrgDefaults());
        String[] formParams = new List<String>();

        HttpRequest request = new HttpRequest();
        request.setMethod('POST');
        request.setHeader('Authorization', authorizationToken);
        request.setHeader('Content-Type', 'application/x-www-form-urlencoded');
        request.setEndpoint(fan_PayzenConfig__c.getOrgDefaults().fan_UrlCheck__c);

        for (String fieldName : params.keySet()) {
            String value = EncodingUtil.urlEncode(params.get(fieldName), 'UTF-8');
            formParams.add(fieldName + '=' + value);
        }
        request.setBody(String.join(formParams, '&'));
        HttpResponse response = new Http().send(request);

        if(response.getStatusCode() != 200) {
            handleIPNError(response.getBody(), params);
        }
    }

    static void handleTransactionStatus(VadsField vadsField) {
        // The order number is for Payzen the id of the order.
        String orderNumber = vadsField.orderId;
        OrderSummary[] orderSummaries = Test.isRunningTest() ? testOrderSummaries : [SELECT Id FROM OrderSummary WHERE OrderNumber = :orderNumber
                                                                                        AND Status = :fan_Constants.OrderSummaryStatus.WAITING_FOR_PAYMENT.name().replace('_', ' ')];

        if(!orderSummaries.isEmpty()) {
            OrderSummary orderSummary = orderSummaries[0] ;
            if(vadsField.transactionStatus == TransactionStatus.CAPTURED.name()) {
                orderSummary.Status = fan_Constants.OrderSummaryStatus.APROBADO.name().capitalize();
                updateInteractionOrderSummaries(orderSummary.Id, fan_Constants.OCIInteractionOrderSummaryType.TRANSFER_ROUTING.name(), fan_Constants.OCIInteractionOrderSummaryStatus.REQUESTED.name());
            } else if(vadsField.transactionStatus == TransactionStatus.REFUSED.name() || vadsField.transactionStatus == TransactionStatus.EXPIRED.name()) {
                orderSummary.Status = fan_Constants.OrderSummaryStatus.CANCELADO.name().capitalize();
                updateInteractionOrderSummaries(orderSummary.Id, fan_Constants.OCIInteractionOrderSummaryType.RELEASE.name(), fan_Constants.OCIInteractionOrderSummaryStatus.REQUESTED.name());
            }
            if(!Test.isRunningTest()) UPDATE orderSummary;
        }
    }

    static void handleIPNError(Object error, Map<String, String> params) {
        String errorInfo = error instanceOf Exception ? ((Exception) error).getStackTraceString() + ' => ' + error : (String) error;
        INSERT new fan_LogWS__c(
            fan_Body__c = JSON.serialize(params).left(SObjectType.fan_LogWS__c.fields.fan_Body__c.length),
            fan_HasError__c = true,
            fan_ErrorMessage__c = errorInfo.left(SObjectType.fan_LogWS__c.fields.fan_ErrorMessage__c.length)
        );
        RestResponse response = RestContext.response;
        response.responseBody = Blob.valueOf(errorInfo);
        response.statusCode = 500;
    }

    static void updatePaymentStatus(VadsField vadsField) {
        Payment[] payments = [SELECT Id FROM Payment WHERE OrderPaymentSummary.OrderSummary.OriginalOrder.OrderNumber = :vadsField.orderId AND Status = :PaymentStatus.DRAFT.name()];
        if(!payments.isEmpty()) {
            Payment payment = payments[0];
            payment.status = vadsField.transactionStatus == TransactionStatus.CAPTURED.name() ? PaymentStatus.PROCESSED.name() : PaymentStatus.CANCELED.name();
            UPDATE payment;
        }
    }

    static void updateInteractionOrderSummaries(String orderSummaryId, String type, String status) {
        OCIInteractionOrderSummary__c[] OCIInteractionOrderSummaries = Test.isRunningTest() ? testOCIInteractionOrderSummaries : [SELECT Id FROM OCIInteractionOrderSummary__c WHERE OrderSummary__c = :orderSummaryId
                                                                                                                                    AND Type__c = :fan_Constants.OCIInteractionOrderSummaryType.CREATE_RESERVATION.name()
                                                                                                                                    AND Status__c = :fan_Constants.OCIInteractionOrderSummaryStatus.COMPLETED_SUCCEED.name()];
        for (OCIInteractionOrderSummary__c OCIInteractionOrderSummary : OCIInteractionOrderSummaries) {
            OCIInteractionOrderSummary.Schedule__c = Datetime.now();
            OCIInteractionOrderSummary.Type__c = type;
            OCIInteractionOrderSummary.Status__c = status;
        }
        if(!Test.isRunningTest()) UPDATE OCIInteractionOrderSummaries;
    }

    @TestVisible
    class VadsField {
        String signature;
        String orderId;
        String cardBrand;
        String transactionStatus;
        Map<String, String> params;

        public VadsField(Map<String, String> params) {
            this.params = params;
            this.signature = params.get('signature');
            this.orderId = params.get('vads_order_id');
            this.cardBrand = params.get('vads_card_brand');
            this.transactionStatus = params.get('vads_trans_status');
        }

        Boolean hasVadsHash() {
            return params.containsKey('vads_hash');
        }
    }

    class AuthenticationException extends Exception {}
}