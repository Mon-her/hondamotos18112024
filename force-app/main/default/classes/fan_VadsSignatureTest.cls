@IsTest
class fan_VadsSignatureTest {

    @TestSetup
    static void setup(){
        fan_PayzenConfig__c payzenConfig = new fan_PayzenConfig__c();
        payzenConfig.fan_SecretKey__c = 'SecretKey';
        payzenConfig.fan_SignatureAlgorithm__c = 'hmacSHA256';
        INSERT payzenConfig;
    }

    @IsTest
    static void generateHmacBase64() {

        fan_PayzenConfig__c payzenConfig = fan_PayzenConfig__c.getOrgDefaults();
        String message = 'This is a stest';

	    Blob rawSignature = Crypto.generateMac(payzenConfig.fan_SignatureAlgorithm__c, Blob.valueOf(message), Blob.valueOf(payzenConfig.fan_SecretKey__c));
        String signatureTest = EncodingUtil.base64Encode(rawSignature);

        String signature = fan_VadsSignature.generateHmacBase64(payzenConfig.fan_SignatureAlgorithm__c, message, payzenConfig.fan_SecretKey__c);

        System.assertEquals(signatureTest, signature, 'The signature is not as expected.');
    }

    @IsTest
    static void buildSignature() {

        fan_PayzenConfig__c payzenConfig = fan_PayzenConfig__c.getOrgDefaults();
        String message = '';

        Map<String, String> parameters = new Map<String, String> {
            'vads_currency' => '170',
            'vads_payment_config' => 'SINGLE',
            'vads_amount' => '57142',
            'vads_ctx_mode' => 'TEST'
        };

        // Configuracion of the data to be tested.
        List<String> keys = new List<String>(parameters.keySet());
        keys.sort();

        for (String key : keys) {
            message += parameters.get(key) + '+';
        }
        message += payzenConfig.fan_SecretKey__c;

        String signatureTest = fan_VadsSignature.generateHmacBase64(payzenConfig.fan_SignatureAlgorithm__c, message, payzenConfig.fan_SecretKey__c);

        String signature = fan_VadsSignature.buildSignature(payzenConfig.fan_SignatureAlgorithm__c, parameters, payzenConfig.fan_SecretKey__c);
        System.assertEquals(signatureTest, signature, 'The signature is not as expected.');
    }
}