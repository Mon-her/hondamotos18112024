@IsTest
class fan_B2BManagedContentCtrlTest {

    @IsTest
    static void getManagedContentByContentKeys() {

        ConnectApi.ManagedContentVersionCollection managedContentVersionCollectionTest = new ConnectApi.ManagedContentVersionCollection();
        managedContentVersionCollectionTest.currentPageUrl = '/currentPage';
        managedContentVersionCollectionTest.total = 1;
        managedContentVersionCollectionTest.totalTypes = 1;
        managedContentVersionCollectionTest.nextPageUrl = '/nextPage';

        fan_B2BManagedContentCtrl.managedContentVersionCollectionTest = managedContentVersionCollectionTest;
        ConnectApi.ManagedContentVersionCollection managedContentVersionCollection = fan_B2BManagedContentCtrl.getManagedContentByContentKeys(null, null, 0, 1, null, 'cms_document', true);

        System.assertEquals(managedContentVersionCollectionTest.currentPageUrl, managedContentVersionCollection.currentPageUrl, 'The current page url is not as expected.');
        System.assertEquals(managedContentVersionCollectionTest.total, managedContentVersionCollection.total, 'The total is not as expected.');
        System.assertEquals(managedContentVersionCollectionTest.totalTypes, managedContentVersionCollection.totalTypes, 'The total types is not as expected.');
        System.assertEquals(managedContentVersionCollectionTest.nextPageUrl, managedContentVersionCollection.nextPageUrl, 'The next page url is not as expected.');
    }

    @IsTest
    static void getManagedContentByContentKeysSimulatingException() {

        try {
            fan_B2BManagedContentCtrl.throwException = true;
            fan_B2BManagedContentCtrl.getManagedContentByContentKeys(null, null, null, null, null, null, null);
        } catch (Exception e) {
            System.assertEquals('Script-thrown exception', e.getMessage());
            // The way the auraHandledException is thrown, this isn't available unless we call setMessage() prior to
            // throwing the exception. So, we'll make due with a generic exception message for this reference
        }
    }
}