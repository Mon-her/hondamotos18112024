public with sharing class fan_B2BManagedContentCtrl {

    // For unit tests.
    public static ConnectApi.ManagedContentVersionCollection managedContentVersionCollectionTest;
    public static Boolean throwException;

    /**
     * Everything is documented here. 
     * https://developer.salesforce.com/docs/atlas.en-us.apexref.meta/apexref/apex_ConnectAPI_ManagedContent_static_methods.htm#apex_ConnectAPI_ManagedContent_getManagedContentByContentKeys_2
     */
    @AuraEnabled(cacheable = true)
    public static ConnectApi.ManagedContentVersionCollection getManagedContentByContentKeys(
        String communityId,
        List<String> contentKeys,
        Integer pageParam,
        Integer pageSize,
        String language,
        String managedContentType,
        Boolean showAbsoluteUrl){

        ConnectApi.ManagedContentVersionCollection managedContentVersionCollection;

        try {
            // For testing purposes.
            if(throwException == true) {
                managedContentVersionCollection.currentPageUrl = '';
            }

            managedContentVersionCollection = Test.isRunningTest() ? managedContentVersionCollectionTest : ConnectApi.ManagedContent.getManagedContentByContentKeys(communityId, contentKeys, pageParam, pageSize, language, managedContentType, showAbsoluteUrl);
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
        return managedContentVersionCollection;
    }
}