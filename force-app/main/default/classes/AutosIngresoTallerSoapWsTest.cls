@isTest
private with sharing class AutosIngresoTallerSoapWsTest {
  @TestSetup
  static void makeData() {
    List<Account> personaNaturalAccounts = TestDataUtilityClass.crearCuentasAutos(
      1,
      Label.AutosRecordTypeDevNameAccountNatural
    );

    Asset vehiculo1 = new Asset();
    //vehiculo1.RecordTypeId = Label.AssetVehiculoRecordType;
    vehiculo1.Name = 'Vehiculo 1';
    vehiculo1.AccountId = personaNaturalAccounts[0].Id;
    insert vehiculo1;
  }

  @isTest
  static void insertar() {
    Asset vehiculo1 = [SELECT Id FROM Asset LIMIT 1];

    AutosIngresoTallerSoapWs.Input inputItem1 = new AutosIngresoTallerSoapWs.Input();
    inputItem1.F926_ID_TIPO_VEHICULO = '1';
    inputItem1.F926_ID = String.valueOf(vehiculo1.Id);
    inputItem1.F350_350 = '01/12/2020'; // fecha factura
    inputItem1.F350_FECHA_TS_APROBACION = '01/12/2020'; // fecha aprobacion
    inputItem1.Nro_Documento = '0001';
    inputItem1.F021_descripcion = 'Servicio prestado'; // Servicio prestado 
    inputItem1.Valor_Neto = '999.99';
    inputItem1.F350_Notas = 'Estas son unas notas de prueba.';

    AutosIngresoTallerSoapWs.Input inputItem2 = new AutosIngresoTallerSoapWs.Input();
    inputItem2.F926_ID_TIPO_VEHICULO = '2';
    inputItem2.F926_ID = String.valueOf(vehiculo1.Id);
    inputItem2.F350_350 = ''; // this will cause an exception
    inputItem2.F350_FECHA_TS_APROBACION = ''; // this will cause an exception
    inputItem2.Nro_Documento = '0002';
    inputItem2.F021_descripcion = 'Servicio prestado'; // Servicio prestado 
    inputItem2.Valor_Neto = '999.99';
    inputItem2.F350_Notas = 'Estas son unas notas de prueba.';

    AutosIngresoTallerSoapWs.Input inputItem3 = new AutosIngresoTallerSoapWs.Input();
    inputItem3.F926_ID_TIPO_VEHICULO = '1';
    inputItem3.F926_ID = ''; // this will cause an insert error
    inputItem3.F350_350 = '01/12/2020'; // fecha factura
    inputItem3.F350_FECHA_TS_APROBACION = '01/12/2020'; // fecha aprobacion
    inputItem3.Nro_Documento = '0001';
    inputItem3.F021_descripcion = 'Servicio prestado'; // Servicio prestado 
    inputItem3.Valor_Neto = '999.99';
    inputItem3.F350_Notas = 'Estas son unas notas de prueba.';

    List<AutosIngresoTallerSoapWs.Input> input = new List<AutosIngresoTallerSoapWs.Input>();
    input.add(inputItem1);
    input.add(inputItem2);
    input.add(inputItem3);

    List<AutosIngresoTallerSoapWs.Output> respuestas = AutosIngresoTallerSoapWs.insertar(
      input
    );
    System.assert(respuestas.size() == input.size(), true);

    AutosIngresoTallerSoapWs.Output respuesta1 = respuestas[0];
    System.assert(respuesta1.error == '', true);

    AutosIngresoTallerSoapWs.Output respuesta2 = respuestas[1];
    System.assert(respuesta2.error != '', true);

    AutosIngresoTallerSoapWs.Output respuesta3 = respuestas[2];
    System.assert(respuesta3.error != '', true);
  }
}