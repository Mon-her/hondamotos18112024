@isTest
public class CustomLookup_Test {
  @TestSetup
  static void makeData() {
    Concesionario__c concesionario = new Concesionario__c();
    concesionario.Name = 'Concesionario 1';
    concesionario.Codigo_de_agencia__c = 'CodigoAgencia1';
    concesionario.Codigo_concesionario__c = 'CONC1';
    insert concesionario;

    Concesionario__c concesionario2 = new Concesionario__c();
    concesionario2.Name = 'Concesionario 2';
    concesionario2.Codigo_de_agencia__c = 'CodigoAgencia2';
    concesionario2.Codigo_concesionario__c = 'CONC2';
    insert concesionario2;

    Miembro_de_Concesionario__c miembroDeConcesionario = new Miembro_de_Concesionario__c();
    miembroDeConcesionario.Concesionario__c = concesionario.Id;
    miembroDeConcesionario.Nombre_de_asesor__c = UserInfo.getUserId();
    insert miembroDeConcesionario;

    Miembro_de_Concesionario__c miembroDeConcesionario2 = new Miembro_de_Concesionario__c();
    miembroDeConcesionario2.Concesionario__c = concesionario2.Id;
    miembroDeConcesionario2.Nombre_de_asesor__c = UserInfo.getUserId();
    insert miembroDeConcesionario2;
  }

  @isTest
  static void lookup() {
    User user = [
      SELECT Id, Name
      FROM User
      WHERE Id = :UserInfo.getUserId()
      LIMIT 1
    ];

    List<Miembro_de_Concesionario__c> results = CustomLookup.lookup(
      'Miembro_de_Concesionario__c',
      'Nombre_de_asesor__r.Name',
      'Nombre_de_asesor__r.Name, Nombre_de_asesor__c, Concesionario__c',
      user.Name.substring(0, user.Name.length() - 2)
    );

    System.assert(results.size() == 2, true);
    System.assert(results[0].Nombre_de_asesor__c == user.Id, true);
    System.assert(results[0].Nombre_de_asesor__r.Name == user.Name, true);
    System.assert(results[1].Nombre_de_asesor__r.Name == user.Name, true);
    System.assert(results[1].Concesionario__c != null, true);
  }
}