@isTest
public class FrecuenciaDeActualizacion_Test {
  @TestSetup
  static void makeData() {
    User portalUser = getPortalUser('PowerPartner', null, true);

    System.runAs(portalUser) {
      List<Account> accounts = TestDataUtilityClass.crearClienteMotos(
        Label.MotosRecordTypeDevNameAccountNatural,
        2
      );

      Account account = accounts[0];
      account.Telefono_Validado__c = true;
      account.Email_Validado__c = true;
      account.PersonMobilePhone = '3113858094';
      account.PersonEmail = 'olvinabarca@gmail.com';

      account = accounts[1];
      account.Telefono_Validado__c = false;
      account.Email_Validado__c = false;
      account.PersonMobilePhone = '3113858094';
      account.PersonEmail = 'olvinabarca@gmail.com';
      update accounts;
    }
  }

  /**
   * Attempt to run checks for multiple accounts
   */
  @isTest
  private static void isAccountFieldsUpdatedRecently1() {
    Test.startTest();

    String maxDiasTelefonoCuenta = '0';
    String maxDiasEmailCuenta = '0';

    List<Account> accounts = [
      SELECT Id, PersonMobilePhone, PersonEmail
      FROM Account
      LIMIT 2
    ];

    Integer result = FrecuenciaDeActualizacion.isAccountFieldsUpdatedRecently(
      accounts,
      accounts,
      maxDiasTelefonoCuenta,
      maxDiasEmailCuenta
    );
    System.debug('Test.isAccountFieldsUpdatedRecently1: result: ' + result);
    System.assert(result == 3, true);

    Test.stopTest();
  }

  /**
   * Attempt to update an account with updated phone and email.
   * Expect no errors
   */
  @isTest
  private static void isAccountFieldsUpdatedRecently2() {
    Test.startTest();

    String maxDiasTelefonoCuenta = '1';
    String maxDiasEmailCuenta = '1';

    Account account = [
      SELECT Id, PersonMobilePhone, PersonEmail
      FROM Account
      LIMIT 1
    ];
    List<Account> accounts = new List<Account>{ account };
    Integer result = FrecuenciaDeActualizacion.isAccountFieldsUpdatedRecently(
      accounts,
      accounts,
      maxDiasTelefonoCuenta,
      maxDiasEmailCuenta
    );
    System.debug('Test.isAccountFieldsUpdatedRecently2: result: ' + result);
    System.assert(result == 0, true);

    Test.stopTest();
  }

  /**
   * Attempt to update an account with updated phone and outdated email.
   * Expect no errors
   */
  @isTest
  private static void isAccountFieldsUpdatedRecently3() {
    Test.startTest();

    String maxDiasTelefonoCuenta = '1';
    String maxDiasEmailCuenta = '0';

    Account account = [
      SELECT Id, PersonMobilePhone, PersonEmail
      FROM Account
      LIMIT 1
    ];
    List<Account> accounts = new List<Account>{ account };

    User portalUser = [SELECT Id FROM User ORDER BY CreatedDate DESC LIMIT 1];
    System.runAs(portalUser) {
      Integer result = FrecuenciaDeActualizacion.isAccountFieldsUpdatedRecently(
        accounts,
        accounts,
        maxDiasTelefonoCuenta,
        maxDiasEmailCuenta
      );
      System.debug('Test.isAccountFieldsUpdatedRecently3: result: ' + result);
      // System.assert(result == 2, true); // AccountHistory records are not created in test env
    }

    Test.stopTest();
  }

  /**
   * Attempt to update an account with outdated phone and updated email.
   * Expect no errors
   */
  @isTest
  private static void isAccountFieldsUpdatedRecently4() {
    Test.startTest();

    String maxDiasTelefonoCuenta = '0';
    String maxDiasEmailCuenta = '1';

    Account account = [
      SELECT Id, PersonMobilePhone, PersonEmail
      FROM Account
      LIMIT 1
    ];
    List<Account> accounts = new List<Account>{ account };

    User portalUser = [SELECT Id FROM User ORDER BY CreatedDate DESC LIMIT 1];
    System.runAs(portalUser) {
      Integer result = FrecuenciaDeActualizacion.isAccountFieldsUpdatedRecently(
        accounts,
        accounts,
        maxDiasTelefonoCuenta,
        maxDiasEmailCuenta
      );
      System.debug('Test.isAccountFieldsUpdatedRecently4: result: ' + result);
      // System.assert(result == 1, true); // AccountHistory records are not created in test env
    }

    Test.stopTest();
  }

  @isTest
  private static void checkIfUpdatedRecently() {
    Test.startTest();

    Account account = [SELECT Id FROM Account LIMIT 1];

    AccountHistory accountHistory = new AccountHistory();

    Boolean isIntegrationUser = false;
    Boolean isMotoUser = false;

    FrecuenciaDeActualizacion.checkIfUpdatedRecently(
      account,
      '0',
      accountHistory,
      'Field name',
      isIntegrationUser,
      isMotoUser
    );

    Test.stopTest();
  }

  @isTest
  private static void checkIfUpdatedRecentlyWithPortalUser() {
    Test.startTest();

    Account account = [SELECT Id FROM Account LIMIT 1];

    AccountHistory accountHistory = new AccountHistory();
    accountHistory.field = 'PersonMobilePhone';
    accountHistory.field = 'PersonEmail';
    // accountHistory.CreatedDate = System.today();

    User portalUser = [SELECT Id FROM User ORDER BY CreatedDate DESC LIMIT 1];

    Boolean isIntegrationUser = false;
    Boolean isMotoUser = true;

    System.runAs(portalUser) {
      FrecuenciaDeActualizacion.checkIfUpdatedRecently(
        account,
        '0',
        accountHistory,
        'Field name',
        isIntegrationUser,
        isMotoUser
      );
    }

    Test.stopTest();
  }

  public static User getPortalUser(
    String portalTypeName,
    User userWithRole,
    Boolean doInsert
  ) {
    /* Make sure the running user has a role otherwise an exception
     will be thrown. */
    String orgId = UserInfo.getOrganizationId();
    if (userWithRole == null) {
      if (UserInfo.getUserRoleId() == null) {
        UserRole r = new UserRole(name = 'VP Motos');
        Database.insert(r);
        userWithRole = new User(
          alias = 'hasrole',
          email = 'userwithrole@roletest1.com',
          username = 'puser@' + orgId + 'testing.com2',
          userroleid = r.id,
          emailencodingkey = 'UTF-8',
          lastname = 'Testing',
          languagelocalekey = 'en_US',
          localesidkey = 'en_US',
          profileid = UserInfo.getProfileId(),
          timezonesidkey = 'America/Los_Angeles'
        );
      } else {
        userWithRole = new User(
          Id = UserInfo.getUserId(),
          UserRoleId = UserInfo.getUserRoleId()
        );
      }
      System.assert(
        userWithRole.userRoleId != null,
        'This test requires the target org to have at least one UserRole created. Please create a user role in this organization and try again.'
      );
    }
    Account a;
    Contact c;
    System.runAs(userWithRole) {
      TestDataUtilityClass.crearClienteMotos(
        Label.MotosRecordTypeDevNameAccountJuridica,
        1
      );

      Account account = [
        SELECT Id
        FROM Account
        ORDER BY CreatedDate DESC
        LIMIT 1
      ];

      Contact contact = new Contact(
        FirstName = 'Test',
        Lastname = 'McTesty',
        AccountId = account.Id,
        Email = System.now().millisecond() + 'test@test.com'
      );
      Database.insert(contact);
      c = contact;
    }
    /* Get any profile for the given type.*/
    Profile portalUserProfile = [
      SELECT Id, Name
      FROM profile
      WHERE Name = 'Asesores motos'
      LIMIT 1
    ];

    String testemail = 'puser000@' + orgId + '.com';
    User pu = new User(
      profileId = portalUserProfile.Id,
      username = testemail,
      email = testemail,
      emailencodingkey = 'UTF-8',
      localesidkey = 'en_US',
      languagelocalekey = 'en_US',
      timezonesidkey = 'America/Los_Angeles',
      alias = 'cspu',
      lastname = 'lastname',
      contactId = c.id,
      Oportunidades_Objetivo__c = 10,
      Cuota__c = 10
    );
    if (doInsert) {
      Database.insert(pu);
    }
    return pu;
  }
}