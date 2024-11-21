public with sharing class fan_HomeCarouselCtrl {

    @TestVisible
    static ConnectApi.ManagedContentVersionCollection testContentVersionCollection;

    @AuraEnabled(cacheable=true)
    public static List<Image> getImagesFromTopic(String communityId, String topicName){
        try {
            ConnectApi.ManagedContentVersionCollection managedContentVersionCollection = Test.isRunningTest() ? testContentVersionCollection : ConnectApi.ManagedContent.getManagedContentByTopics(communityId, new List<String> { topicName }, 0, 10, 'en_US', 'cms_image', false);

            List<Image> images = new List<Image>();
            //loop through each item and prepare a wrapper list
            for(ConnectApi.ManagedContentVersion managedContentVersion: managedContentVersionCollection.items){
                images.add(buildImage(managedContentVersion.title, managedContentVersion.contentNodes));	
            }
            return images;
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }

    @TestVisible
    static Image buildImage(String contentVersionTitle, Map<String, ConnectApi.ManagedContentNodeValue> contentNodes)  {

        Image image = new Image();
        image.title = contentVersionTitle;

        for(String key : contentNodes.keySet()) {
            if(key == 'source'){
                image.url = ((ConnectApi.ManagedContentMediaSourceNodeValue) contentNodes.get(key)).url;
            } else if(key == 'altText'){
                image.recordId = ((ConnectApi.ManagedContentTextNodeValue) contentNodes.get(key)).value;
            }
        }
        return image;
    }

    @TestVisible
    class Image {
        @AuraEnabled
        public String title {get;set;}
        @AuraEnabled
        public String url {get;set;}
        @AuraEnabled
        public String recordId {get;set;}
    }
}