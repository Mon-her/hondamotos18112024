@isTest
public with sharing class LWCExampleControllerTest {
   /*********************************************************************************************************
    * @name			The name of your class or method
    * @author			Andres Oliva <andresoliva@gmail.com>
    * @created			30 / 07 / 2020
    * @description		Description of your code
    * @param			String param : Explanation
    * @return			Explanation of the return value
   **********************************************************************************************************/
    private static testMethod void readCSVFile() {
              
        User            usr         =   [SELECT ID, userName, Name FROM User WHERE ID = :UserInfo.getUserId()];
        string          strUserName =   usr.userName;
        string          sDocument1  =   '1030445434';
        string          sDocument2  =   '1050445434';
        account         objAcc      =   createDataDactory.createAccount( FALSE , 'testacc', sDocument1 );
        objAcc.AM_Tipo_de_documento__c ='Cédula de ciudadanía';
        INSERT objAcc;
        MC_Contactos__c objcontact  =   createDataDactory.createContact( true , objAcc.id ) ; 
        account         objAccRef   =   createDataDactory.createAccount( false , 'testaccref', sDocument2 );
        objAccRef.AM_Tipo_de_documento__c ='Cédula de ciudadanía';
        objAccRef.AM_Fuente_de_prospeccion__c = 'Referidos';
        objAccRef.SO_Referidor_Cuenta__c = objAcc.id;
        insert objAccRef;    

        //Create Document
        ContentVersion cv = new ContentVersion();
        cv.Title = 'Test Document';
        cv.PathOnClient = 'TestDocument.csv';
        cv.VersionData = Blob.valueOf(
            'Document;NewOwner'+'\n'+
            sDocument1+';'+strUserName+'\n'+
            sDocument2+';'+strUserName+'\n');
        cv.IsMajorVersion = true;
        Insert cv;
        
        //Get Content Documents
        Id conDocId = [SELECT ContentDocumentId FROM ContentVersion WHERE Id =:cv.Id].ContentDocumentId;        
        
        test.startTest();
            LWCExampleController.readCSVFile( conDocId );
            LWCExampleController.callUpdateUser();
        test.stopTest();
    }
}