@IsTest
class fan_HomeCarouselCtrlTest {

    @IsTest
    static void getImagesFromTopic() {

        ConnectApi.ManagedContentVersionCollection contentVersionCollection = new ConnectApi.ManagedContentVersionCollection();
        ConnectApi.ManagedContentVersion managedContent = new ConnectApi.ManagedContentVersion();
        Map<String,ConnectApi.ManagedContentNodeValue> contentNodesMap = new Map<String,ConnectApi.ManagedContentNodeValue>();

        ConnectApi.ManagedContentMediaSourceNodeValue source = new ConnectApi.ManagedContentMediaSourceNodeValue();
        source.url = 'http://image.png';

        ConnectApi.ManagedContentTextNodeValue altText = new ConnectApi.ManagedContentTextNodeValue();
        altText.value = 'recordId';

        contentNodesMap.put('source' , source);
        contentNodesMap.put('altText' , altText);

        managedContent.contentNodes = contentNodesMap;

        contentVersionCollection.items = new List<ConnectApi.ManagedContentVersion> { managedContent };

        fan_HomeCarouselCtrl.testContentVersionCollection = contentVersionCollection;
        List<fan_HomeCarouselCtrl.Image> images = fan_HomeCarouselCtrl.getImagesFromTopic('', 'Home Collection');

        Assert.areEqual('http://image.png', images[0].url, 'The url of the image is not as expected.');
        Assert.areEqual('recordId', images[0].recordId, 'The productUrl of the image is not as expected.');
    }

    @IsTest
    static void getImagesFromTopicWithInvalidCommunityId() {
        try {
            fan_HomeCarouselCtrl.getImagesFromTopic('', 'Home Collection');
            Assert.fail('An exception was expected.');
        } catch (Exception e) {
            Assert.isInstanceOfType(e, AuraHandledException.class, 'An AuraHandledException was expected.');
        }
    }

    @IsTest
    static void buildImage() {

        Map<String, ConnectApi.ManagedContentNodeValue> contentNodes = new Map<String,ConnectApi.ManagedContentNodeValue>();

        ConnectApi.ManagedContentMediaSourceNodeValue mediaSource = new ConnectApi.ManagedContentMediaSourceNodeValue();
        mediaSource.url = 'http://image.png';

        ConnectApi.ManagedContentTextNodeValue text = new ConnectApi.ManagedContentTextNodeValue();
        text.value = 'recordId';

        contentNodes.put('source' , mediaSource);
        contentNodes.put('altText' , text);

        fan_HomeCarouselCtrl.Image image = fan_HomeCarouselCtrl.buildImage('Main image', contentNodes);

        Assert.areEqual('Main image', image.title, 'The title of the image is not as expected.');
        Assert.areEqual('http://image.png', image.url, 'The url of the image is not as expected.');
        Assert.areEqual('recordId', image.recordId, 'The recordId of the image is not as expected.');
    }
}