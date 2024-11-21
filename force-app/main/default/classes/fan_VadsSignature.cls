public class fan_VadsSignature {

	/** * Actual signing operation.  */
	@TestVisible
    static String generateHmacBase64(String algorithmName, String message, String secretKey) {
	    Blob signature = Crypto.generateMac(algorithmName, Blob.valueOf(message), Blob.valueOf(secretKey));
		return EncodingUtil.base64Encode(signature);
    }

	/** * @param parameters Vads fields to encrypt.  */
    public static String buildSignature(String algorithmName, Map<String, String> parameters, String secretKey) {

		String[] keys = new List<String>();
		String message = '';

		for(String key : parameters.keySet()) {
			if(key.startsWith('vads_')) {
		    	keys.add(key);
			}
		}
		keys.sort();

		for(String key : keys) {
			message += parameters.get(key) + '+';
		}
		message += secretKey;

		return generateHmacBase64(algorithmName, message, secretKey);
    }
}