@isTest
public class fan_AttachedFileCtrlTest {

    @TestSetup
    static void makeData(){
        Contact testContact = new Contact(
            Title = 'ContactTest',
            Phone = '8004446666',
            FirstName = 'ContactTest',
            LastName = 'ContactTest'
        );
        insert testContact;

        ContentVersion content = new ContentVersion(); 
        content.Title = 'TestOfPDF'; 
        content.PathOnClient ='/' + content.Title + '.pdf'; 
        Blob bodyBlob=Blob.valueOf('Unit Test ContentVersion Body'); 
        content.VersionData=bodyBlob; 
        content.origin = 'C';
        insert content;

        ContentDocumentLink contentlink = new ContentDocumentLink();
        contentlink.LinkedEntityId = testContact.id;
        contentlink.contentdocumentid = [select contentdocumentid from contentversion where id =: content.id].contentdocumentid;
        contentlink.Visibility = 'AllUsers'; 
        insert contentlink;
    }

    @IsTest
    static void getRelatedFiles(){

        Id testId = [SELECT Id FROM Contact].Id;

        List<ContentDocumentLink> CDLPId = [SELECT ContentDocument.LatestPublishedVersionId FROM ContentDocumentLink WHERE LinkedEntityId =: testId];
        List<Id> result = fan_AttachedFileCtrl.getRelatedFiles(testId);
        Assert.areEqual(CDLPId[0].ContentDocument.LatestPublishedVersionId, result[0]);
    }
}