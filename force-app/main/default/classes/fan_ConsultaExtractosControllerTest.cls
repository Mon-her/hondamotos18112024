@IsTest
public class fan_ConsultaExtractosControllerTest {

    @TestSetup
    static void makeData(){
        INSERT new fan_ServiceEndpoint__c(
            usuario__c = 'test user',
            contrasena__c = 'test password',
            url__c = 'http://example.com'
        );
        INSERT new fan_CorporationInformation__c(
            fan_Name__c = 'Test Corporation',
            fan_Phone__c = '157399031',
            fan_Currency__c = 'COP-Pesos',
            fan_Address__c = 'Peter Jason #1'
        );

        Account currentAccount =  new Account(
            Name = 'Test Account',
            AccountNumber = '123456789',
            AM_Numero_de_documento__c = '123456789',
            AM_Tipo_de_documento__c = 'NIT'
        );
        INSERT currentAccount;

        INSERT new Account(
            Name = 'Current Account',
            AccountNumber = '123456789531',
            AM_Numero_de_documento__c = '123456789531',
            AM_Tipo_de_documento__c = 'NIT',
            ParentId = currentAccount.Id
        );

        System.debug(JSON.serializePretty([SELECT Name FROM Account]));
    }

    @IsTest
    static void getMovements() {

        String nitCliente = [SELECT AccountNumber FROM Account LIMIT 1].AccountNumber;

        Test.setMock(WebServiceMock.class, new fan_ConsultaExtractosMock());
        fan_ConsultaExtractosMock.NITCLIENTE = nitCliente;

        Test.startTest();
        List<fan_ConsultaExtractosController.Movement> movements = fan_ConsultaExtractosController.getMovements(nitCliente, '2022-06-04', '2022-09-13');
        Test.stopTest();

        fan_ConsultaExtractosController.Movement firstMovement = movements?.get(0);

        Assert.isFalse(movements.isEmpty(), 'Rows is empty.');
        Assert.areEqual(nitCliente, firstMovement.nit, 'The nit is not as expected.');
        Assert.areEqual('DOC-MXBB-319319', firstMovement.document, 'The document is not as expected.');
        Assert.areEqual('2022-06-25', firstMovement.documentDate, 'The date of the document is not as expected.');
        Assert.areEqual('NDE-3135', firstMovement.crossingDocument, 'The crossing document is not as expected.');
        Assert.areEqual('2022-07-25', firstMovement.expirationDate, 'The expiration date is not as expected.');
        Assert.areEqual(46204213, firstMovement.documentValue, 'The value of the document is not as expected.');
        Assert.areEqual(46204213, firstMovement.initialBalance, 'The initial balance is not as expected.');
        Assert.areEqual(0, firstMovement.appliedValue, 'The applied value is not as expected.');
        Assert.areEqual(46204213, firstMovement.endingBalance, 'The ending balance is not as expected.');
        Assert.areEqual('ANTIC. DE CLIENTES', firstMovement.subsidiary, 'The subsidiary is not as expected.');
    }

    @IsTest
    static void getMovementsWithInvalidNitCliente() {

        String nitCliente = '31590397';

        Test.setMock(WebServiceMock.class, new fan_ConsultaExtractosMock());

        Test.startTest();
        List<fan_ConsultaExtractosController.Movement> movements = fan_ConsultaExtractosController.getMovements(nitCliente, '2022-06-04', '2022-09-13');
        Test.stopTest();

        Assert.isTrue(movements.isEmpty(), 'An empty movement list was expected.');
    }

    @IsTest
    static void getMovementsWithReadTimedOutException() {

        String nitCliente = '31590397';

        Test.setMock(WebServiceMock.class, new fan_ConsultaExtractosMock());
        fan_ConsultaExtractosMock.isReadTimedOutException = true;

        try {
            Test.startTest();
            List<fan_ConsultaExtractosController.Movement> movements = fan_ConsultaExtractosController.getMovements(nitCliente, '2022-06-04', '2022-09-13');
            Test.stopTest();
            Assert.fail('An exception was expected.');
        } catch (Exception e) {
            Assert.isInstanceOfType(e, AuraHandledException.class, 'AuraHandledException was expected.');
        }
    }

    @IsTest
    static void getCorporation() {

       Map<String, String> corporation = fan_ConsultaExtractosController.getCorporation();

       Assert.areEqual('Test Corporation', corporation.get('name'), 'The fan_Name__c of the fan_CorporationInformation__c is not as expected.');
       Assert.areEqual('157399031', corporation.get('phone'), 'The fan_Phone__c of the fan_CorporationInformation__c is not as expected.');
       Assert.areEqual('COP-Pesos', corporation.get('currency'), 'The fan_Currency__c of the fan_CorporationInformation__c is not as expected.');
       Assert.areEqual('Peter Jason #1', corporation.get('address'), 'The fan_Address__c of the fan_CorporationInformation__c is not as expected.');
    }

    @IsTest
    static void getCurrentAccount() {

        String accountId = [SELECT Id FROM Account WHERE AM_Numero_de_documento__c = '123456789531'].Id;

       Account account = fan_ConsultaExtractosController.getAccount(accountId);

       Assert.areEqual('123456789', account.AccountNumber, 'The AccountNumber of the account is not as expected.');
       Assert.areEqual('TEST ACCOUNT', account.Name, 'The Name of the account is not as expected.');
    }

    @IsTest
    static void getParentAccount() {

        String accountId = [SELECT Id FROM Account WHERE AM_Numero_de_documento__c = '123456789'].Id;

       Account account = fan_ConsultaExtractosController.getAccount(accountId);

       Assert.areEqual('123456789', account.AccountNumber, 'The AccountNumber of the account is not as expected.');
       Assert.areEqual('TEST ACCOUNT', account.Name, 'The Name of the account is not as expected.');
    }

    @IsTest
    static void getAccountInformation() {

        String accountId = [SELECT Id FROM Account WHERE AM_Numero_de_documento__c = '123456789531'].Id;

       Map<String, Object> accountInformation = fan_ConsultaExtractosController.getAccountInformation(accountId);
       Assert.areEqual('123456789', accountInformation.get('nit'), 'The nit of the account is not as expected.');
       Assert.areEqual('TEST ACCOUNT', accountInformation.get('name'), 'The name of the account is not as expected.');

       Map<String, String> corporation = (Map<String, String>) accountInformation.get('corporation');
       Assert.areEqual('Test Corporation', corporation.get('name'), 'The name of the corporation is not as expected.');
       Assert.areEqual('157399031', corporation.get('phone'), 'The phone of the corporation is not as expected.');
       Assert.areEqual('COP-Pesos', corporation.get('currency'), 'The currency of the corporation is not as expected.');
       Assert.areEqual('Peter Jason #1', corporation.get('address'), 'The address of the corporation is not as expected.');
    }

    @IsTest
    static void getAccountInformationWithInvalidAccountId() {

        String accountId = '173513571753';
        try {
            fan_ConsultaExtractosController.getAccountInformation(accountId);
            Assert.fail('An exception was expected.');
        } catch (Exception e) {
            Assert.isInstanceOfType(e, AuraHandledException.class, 'An AuraHandledException was expected.');
        }
    }
}