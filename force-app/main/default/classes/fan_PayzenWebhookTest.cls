@IsTest
class fan_PayzenWebhookTest implements HttpCalloutMock {

    // Required to make requests to Salesforce.
    User administrator;

    fan_PayzenWebhookTest(User administrator) {
        this.administrator = administrator; 
    }

    @TestSetup
    static void makeData(){
        fan_B2BTestDataFactory.createPayzenConfig();
        fan_B2BTestDataFactory.createPayzenIPNConfig('clientId', 'clientSecret', 'username', 'password', 'securityToken');
    }

    @IsTest
    static void processIPNWithCaptureTransactionStatus() {
        OrderSummary orderSummary = new OrderSummary();
        String secretKey = fan_PayzenConfig__c.getOrgDefaults().fan_SecretKey__c;
        Map<String, String> params = new Map<String, String> {
            'vads_hash' => 'hash',
            'vads_card_brand' => 'RED_AVAL',
            'vads_trans_status' => 'CAPTURED'
        };
        String signature = fan_VadsSignature.buildSignature('hmacSHA256', params, secretKey);

        RestRequest request = RestContext.request = new RestRequest();
        request.requestURI = '/services/apexrest/IPN-listener';
        request.httpMethod = 'POST';
        request.params.put('vads_hash', params.get('vads_hash'));
        request.params.put('vads_trans_status', params.get('vads_trans_status'));
        request.params.put('vads_card_brand', params.get('vads_card_brand'));
        request.params.put('signature', signature);
        
        User administrator = [SELECT Id FROM User WHERE IsActive = TRUE AND Profile.Name IN ('System Administrator', 'Administrador del Sistema') LIMIT 1];
        Test.setMock(HttpCalloutMock.class, new fan_PayzenWebhookTest(administrator));

        Test.startTest();
        User guestUser = [SELECT Id FROM User WHERE UserType = 'Guest' LIMIT 1];
        System.runAs(guestUser) {
            fan_PayzenWebhook.testOrderSummaries = new OrderSummary[] { orderSummary };
            fan_PayzenWebhook.testOCIInteractionOrderSummaries = new OCIInteractionOrderSummary__c[] { new OCIInteractionOrderSummary__c() };
            fan_PayzenWebhook.processIPN();
        }
        Test.stopTest();

        Assert.areEqual(fan_Constants.OrderSummaryStatus.APROBADO.name(), orderSummary.Status, 'The Status of the OrderSummary is not as expected.');
    }

    @IsTest
    static void processIPNShouldThrowAnException() {
        OrderSummary orderSummary = new OrderSummary();
        String secretKey = fan_PayzenConfig__c.getOrgDefaults().fan_SecretKey__c;
        Map<String, String> params = new Map<String, String> {
            'vads_hash' => 'hash',
            'vads_card_brand' => 'RED_AVAL',
            'vads_trans_status' => 'CAPTURED'
        };
        String signature = fan_VadsSignature.buildSignature('hmacSHA256', params, secretKey);

        RestRequest request = RestContext.request = new RestRequest();
        request.params.put('vads_hash', params.get('vads_hash'));
        request.params.put('vads_trans_status', params.get('vads_trans_status'));
        request.params.put('vads_card_brand', params.get('vads_card_brand'));
        request.params.put('signature', signature);

        RestContext.response = new RestResponse();
        
        Test.startTest();
        fan_PayzenWebhook.processIPN();
        Test.stopTest();
    }

    public HttpResponse respond(HttpRequest request) {
        String endpoint = request.getEndpoint();
        HttpResponse response = new HttpResponse();
        response.setStatusCode(200);

        if(endpoint.endsWith('/services/oauth2/token')) {
            response.setBody('{"token_type":"Bearer","access_token":"token"}');
        } else if(endpoint.endsWith('/IPN-listener')) {
            RestContext.request = new RestRequest();

            for (String param : request.getBody().split('&')) {
                String[] field = param.split('=');
                RestContext.request.params.put(field[0], EncodingUtil.urlDecode(field[1], 'UTF-8'));
            }
            System.runAs(administrator) {
                fan_PayzenWebhook.processIPN();
            }
        }
        return response;
    }
}