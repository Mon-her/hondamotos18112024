@isTest
public class UserOppGoalsBatchable_Test {
  @isTest
  private static void exex() {
    User pu = getPortalUser(null, true);

    System.runAs(pu) {
      String hoy = String.valueOf(date.today());
      String traerAnio = hoy.left(4);
      String traerMes = '';
      switch on hoy.left(7).right(2) {
        when '01' {
          traerMes = 'Enero';
        }
        when '02' {
          traerMes = 'Febrero';
        }
        when '03' {
          traerMes = 'Marzo';
        }
        when '04' {
          traerMes = 'Abril';
        }
        when '05' {
          traerMes = 'Mayo';
        }
        when '06' {
          traerMes = 'Junio';
        }
        when '07' {
          traerMes = 'Julio';
        }
        when '08' {
          traerMes = 'Agosto';
        }
        when '09' {
          traerMes = 'Septiembre';
        }
        when '10' {
          traerMes = 'Octubre';
        }
        when '11' {
          traerMes = 'Noviembre';
        }
        when '12' {
          traerMes = 'Diciembre';
        }
      }

      Meta_de_Venta__c m = new Meta_de_Venta__c();
      m.Mes__c = traerMes;
      m.Anio__c = traerAnio;
      m.Asesor__c = pu.Id;
      m.Cuota__c = 10;
      insert m;
    }

    UserOppGoalsBatchable batchable = new UserOppGoalsBatchable();
    Id batchProcessId = Database.executeBatch(batchable);
  }

  private static User getPortalUser(User userWithRole, Boolean doInsert) {
    /* Make sure the running user has a role otherwise an exception
     will be thrown. */
    if (userWithRole == null) {
      if (UserInfo.getUserRoleId() == null) {
        UserRole r = new UserRole(name = 'VP Motos');
        Database.insert(r);
        userWithRole = new User(
          alias = 'hasrole',
          email = 'userwithrole@roletest1.com',
          username = 'puser000@amamama.com2',
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
      Id recordTypeAccountPersonaNaturalMoto = Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName()
        .get(Label.MotosRecordTypeDevNameAccountJuridica)
        .getRecordTypeId();
      Account account = new Account();
      account.RecordTypeId = recordTypeAccountPersonaNaturalMoto;
      account.AccountSource = 'Web';
      account.BillingCountry = 'Nicaragua';
      account.BillingStreet = 'Billing st';
      account.Phone = '8572434';
      account.AM_Numero_de_documento__c = '259741510';
      account.AM_Tipo_de_documento__c = 'NIT';
      account.Name = 'Empresa1';
      account.MC_Correo_electronico_Empresa__c = 'email1@email.com';

      Database.insert(account);
      a = account;

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

    String orgId = UserInfo.getOrganizationId();
    String dateString = String.valueof(Datetime.now())
      .replace(' ', '')
      .replace(':', '')
      .replace('-', '');
    Integer randomInt = Integer.valueOf(math.rint(math.random() * 1000000));
    String uniqueName = orgId + dateString + randomInt;
    User pu = new User(
      profileId = portalUserProfile.Id,
      username = uniqueName + '@test' + orgId + '.org',
      email = uniqueName + '@test' + orgId + '.org',
      emailencodingkey = 'UTF-8',
      localesidkey = 'en_US',
      languagelocalekey = 'en_US',
      timezonesidkey = 'America/Los_Angeles',
      alias = 'cspu',
      lastname = 'lastname',
      contactId = c.id,
      Oportunidades_Objetivo__c = 10,
      IsActive = true,
      Cuota__c = 10
    );
    if (doInsert) {
      Database.insert(pu);
    }
    return pu;
  }
}