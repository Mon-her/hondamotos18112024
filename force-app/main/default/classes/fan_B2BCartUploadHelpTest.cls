@IsTest
class fan_B2BCartUploadHelpTest {

    @IsTest
    static void getContent() {
        ConnectApi.ManagedContentVersionCollection managedContentVersionCollection = new ConnectApi.ManagedContentVersionCollection();
        managedContentVersionCollection.items = new ConnectApi.ManagedContentVersion[] {
            new ConnectApi.ManagedContentVersion()
        };
        fan_B2BCartUploadHelp.testManagedContentVersionCollection = managedContentVersionCollection;

        fan_B2BCartUploadHelp.getContent('', '', 'en_US', '');
    }

    @IsTest
    static void getContentThrowAnException() {
        try {
            fan_B2BCartUploadHelp.getContent('', '', 'en_US', '');
            Assert.fail('An exception was expected.');
        } catch (Exception e) {
            Assert.isInstanceOfType(e, Exception.class, 'The type of the exception is not as expected.');
        }
    }
}