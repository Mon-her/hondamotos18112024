public class fan_loadClientBatch implements Database.batchable<fan_CargaClientes.row_element>, Database.AllowsCallouts, Database.Stateful {

  final String PARENT_CODE_PREFIX = 'P';
  final Map<String, String> clientsLoaded = new Map<String, String>();

  final String[] accountErrors = new List<String>();
  final String[] contactPointAddressErrors = new List<String>();
  final String[] unexpectedErrors = new List<String>();

  public Iterable<fan_CargaClientes.row_element> start(
    Database.BatchableContext info
  ) {
    return fan_loadClientHandler.getData() ?? new List<fan_CargaClientes.row_element>();
  }

  public void execute(
    Database.BatchableContext info,
    fan_CargaClientes.row_element[] rows
  ) {
    SavePoint savePoint = Database.setSavePoint();
    try {
      Map<String, String> clientsLoaded = new Map<String, String>();
      Map<String, Account> parentAccounts = buildParentAccounts(rows);
      Account[] accountsCreated = upsertAccounts(parentAccounts, clientsLoaded);

      Map<String, Account> childAccounts = buildChildAccounts(rows, parentAccounts);
      Account[] childAccountsCreated = upsertAccounts(childAccounts, clientsLoaded);
      accountsCreated.addAll(childAccountsCreated);

      ContactPointAddress[] contactPointAddresses = buildContactPointAddresses(rows, parentAccounts, childAccounts) ;
      upsertContactPointAddresses(contactPointAddresses);

      activateAccountsAsBuyers(accountsCreated);
      this.clientsLoaded.putAll(clientsLoaded);
    } catch (Exception e) {
      unexpectedErrors.add('- ' + e.getMessage());
      Database.rollback(savepoint);
    }
  }

  public void finish(Database.BatchableContext info) {
    
    fan_LoadConfiguration__mdt loadConfiguration = fan_LoadConfiguration__mdt.getInstance(fan_Constants.LoadConfiguration.CLIENTS.Name());

    if(loadConfiguration?.fan_SendReport__c != true) {
      return;
    }
    Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();

    mail.setToAddresses(loadConfiguration.fan_Recipients__c.split('\n'));
    mail.setSenderDisplayName(loadConfiguration.fan_SenderDisplayName__c);
    mail.setSubject(loadConfiguration.fan_ReportHeader__c);
    mail.setPlainTextBody(buildEmailBody());

    Messaging.sendEmail(new Messaging.SingleEmailMessage[] { mail });
  }

  Map<String, Account> buildParentAccounts(fan_CargaClientes.row_element[] rows) {

    Map<String, Account> parentAccounts = new Map<String, Account>();

    for (fan_CargaClientes.row_element row : rows) {
      String documentNumber = fan_loadClientHandler.formatDocumentNumber(row);

      if(!parentAccounts.containsKey(documentNumber)) {
        Account account = fan_loadClientHandler.accountFormat(documentNumber, row);
        parentAccounts.put(account.AM_Numero_de_documento__c, account);
      }
    }
    return parentAccounts;
  }

  Map<String, Account> buildChildAccounts(fan_CargaClientes.row_element[] rows, Map<String, Account> parentAccounts) {

    Map<String, Account> childAccounts = new Map<String, Account>();

    for (fan_CargaClientes.row_element row : rows) {
      String parentAccountDocumentNumber = fan_loadClientHandler.formatDocumentNumber(row);
      String childAccountDocumentNumber = row.TERCERO + row.SUCURSAL;

      if(parentAccounts.containsKey(parentAccountDocumentNumber) && !childAccounts.containsKey(childAccountDocumentNumber)) {

        Account subAccount = fan_loadClientHandler.subAccountFormat(
          row,
          parentAccounts.get(parentAccountDocumentNumber).Id
        );
        childAccounts.put(childAccountDocumentNumber, subAccount);
      }
    }
    return childAccounts;
  }

  ContactPointAddress[] buildContactPointAddresses(fan_CargaClientes.row_element[] rows, Map<String, Account> parentAccounts, Map<String, Account> childAccounts) {

    Map<String, ContactPointAddress> contactPointAddresses = new Map<String, ContactPointAddress>();

    for (fan_CargaClientes.row_element row : rows) {
      String parentAccountDocumentNumber = fan_loadClientHandler.formatDocumentNumber(row);
      // Map ContactPointAddress for parent accounts.
      Account account = parentAccounts.get(parentAccountDocumentNumber);

      if(account == null) {
        continue;
      }
      String childAccountDocumentNumber = row.TERCERO + row.SUCURSAL;
      ContactPointAddress contactPointAddress = getContactPointAddress(account, childAccountDocumentNumber, row);
      contactPointAddresses.put(contactPointAddress.fan_Code__c, contactPointAddress);

      // Map ContactPointAddress for child Accounts.
      if(childAccounts.containsKey(childAccountDocumentNumber)) {
        account = childAccounts.get(childAccountDocumentNumber);

        contactPointAddress = getContactPointAddress(account, childAccountDocumentNumber, row);
        contactPointAddresses.put(contactPointAddress.fan_Code__c, contactPointAddress);
      }
    }
    return contactPointAddresses.values();
  }

  Account[] upsertAccounts(Map<String, Account> accounts, Map<String, String> clientsLoaded) {

    Account[] accountsCreated = new List<Account>();
    Account[] accountsToUpsert = accounts.values();
    Database.UpsertResult[] saveResults = Database.upsert(accountsToUpsert, Account.AM_Numero_de_documento__c, false);

    for (Integer i = 0; i < saveResults.size(); i++) {
      Database.UpsertResult upsertResult = saveResults[i];
      Account account = accountsToUpsert[i];
      String accountDocumentNumber = account.AM_Numero_de_documento__c ;

      if(upsertResult.isSuccess()) {
        clientsLoaded.put(account.AccountNumber, accountDocumentNumber);

        if(upsertResult.isCreated()) {
          accountsCreated.add(account);
        }
      } else {
        accounts.remove(accountDocumentNumber);
        accountErrors.add(formatError(accountDocumentNumber, upsertResult.getErrors()));
      }
    }
    return accountsCreated;
  }

  void upsertContactPointAddresses(ContactPointAddress[] contactPointAddresses) {

    Database.UpsertResult[] saveResults = Database.upsert(contactPointAddresses, ContactPointAddress.fan_Code__c, false);

    for (Integer i = 0; i < saveResults.size(); i++) {
      Database.UpsertResult upsertResult = saveResults[i];
      ContactPointAddress contactPointAddress = contactPointAddresses[i];

      if(!upsertResult.isSuccess()) {
        contactPointAddressErrors.add(formatError(contactPointAddress.fan_Code__c, upsertResult.getErrors()));
      }
    }
  }

  void activateAccountsAsBuyers(Account[] accountsCreated) {

    BuyerAccount[] buyerAccounts = new List<BuyerAccount>();
    for (Account account : accountsCreated) {
      buyerAccounts.add(new BuyerAccount(
        Name = account.Name,
        BuyerId = account.Id,
        IsActive = true
      ));
    }
    Database.insert(buyerAccounts, false);
  }

  String formatError(String identifier, Database.Error[] errors) {

    String[] errorsFormatted = new List<String>();

    for (Database.Error error : errors) {
      String errorFormatted = String.format('{0},{1},{2},{3}', new Object[]{
        identifier,
        error.getStatusCode(),
        error.getMessage(),
        String.join(error.getFields(), ';')
      });
      errorsFormatted.add(errorFormatted);
    }
    return String.join(errorsFormatted, ',');
  }

  String buildEmailBody() {
    System.debug(unexpectedErrors);

    String[] accountsLoadedMessage = new List<String>();
    for (String accountNumber : clientsLoaded.keySet()) {
      accountsLoadedMessage.add(accountNumber + ',' + clientsLoaded.get(accountNumber));
    }

    return String.format('{0}\n\n\n{1}\n\n\n{2}\n\n\n{3}\n\n\n', new Object[]{
      String.format('-> Cuentas cargadas:\n{0}\n{1}', new Object[]{
        'Número de cuenta,Número de documento',
        String.join(accountsLoadedMessage, '\n')
      }),

      String.format('-> Cuentas fallidas:\n{0}\n{1}', new Object[]{
        'Número de documento,Errores',
        String.join(accountErrors, '\n')
      }),

      String.format('-> Direcciones fallidas:\n{0}\n{1}', new Object[]{
        'Código de dirección,Errores',
        String.join(contactPointAddressErrors, '\n')
      }),

      String.format('-> Errores inesperados:\n{0}', new Object[]{
        String.join(unexpectedErrors, '\n')
      })
    });
  }

  private ContactPointAddress getContactPointAddress(Account account, String subAccountNumber, fan_CargaClientes.row_element cargaClientes){
    return fan_loadClientHandler.contactPointFormat(
      account.ParentId == null ? PARENT_CODE_PREFIX : '', 
      cargaClientes,
      account.Id,
      subAccountNumber
    );
  }
}