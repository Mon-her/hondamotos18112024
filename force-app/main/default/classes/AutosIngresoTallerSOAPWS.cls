/**
 * Fanalca
 * @author           Olvin Abarca
 * Description:      This class exposes method that inserts entries into object Ingreso_a_taller__c on demand.
 *
 * Changes (Version)
 * -------------------------------------
 *           No.     Date            Author                  Description
 *           -----   ----------      --------------------    ---------------
 * @version  1.0     12/11/2020      Olvin Abarca            Class definition.
 *********************************************************************************************************/
global class AutosIngresoTallerSOAPWS {
  global class Input {
    webService string F926_ID_TIPO_VEHICULO { get; set; } // tipo vehiculo
    webService string F926_ID { get; set; } // VIN del Vehículo 
    webService string F350_350 { get; set; } // Fecha de Factura
    webService string F350_FECHA_TS_APROBACION { get; set; } // Fecha de asistencia 
    webService string Nro_Documento { get; set; } // numero de documento
    webService string F021_descripcion { get; set; } // Servicio prestado 
    webService string Valor_Neto { get; set; } // valor neto
    webService string F350_Notas { get; set; } // notas
  }

  global class Output {
    webService String error { get; set; }
    webService String MnsjRta { get; set; }
    webService String idSF { get; set; }
  }

  webService static List<Output> insertar(List<Input> input) {
    List<Output> respuestas = new List<Output>();
    List<Ingreso_a_taller__c> ingresosToInsert = new List<Ingreso_a_taller__c>();

    for (Input inputItem : input) {
      // generate list of Ingreso_a_taller__c to insert

      Output respuesta = new Output();

      try {
        Ingreso_a_taller__c insertable = convertToInsertable(inputItem);

        if (insertable == null) {
          throw new DMLException(
            'El VIN ' +
            inputItem.F926_ID +
            ' no pertenece a ningún vehículo en Salesforce'
          );
        }

        ingresosToInsert.add(insertable);
      } catch (Exception ex) {
        respuesta.error = ex.getMessage();
        respuesta.mnsjRta = 'Operación fallida';
        respuesta.idSF = '';
      }

      respuestas.add(respuesta);
    }

    if (ingresosToInsert.size() > 0) {
      List<Database.SaveResult> insertResult = Database.insert(
        ingresosToInsert,
        false
      );

      Integer i = 0;
      for (Database.SaveResult result : insertResult) {
        Ingreso_a_taller__c insertable = ingresosToInsert.get(i);

        while (respuestas[i].error == 'ERROR') {
          i++;
        }
        Output respuesta = respuestas[i];

        if (result.isSuccess()) {
          respuesta.MnsjRta = 'Operación exitosa';
          respuesta.error = '';
          respuesta.idSF = insertable.id;
        } else {
          for (Database.Error error : result.getErrors()) {
            respuesta.error =
              'Error: ' +
              error.getMessage() +
              ' Campos ' +
              error.getFields() +
              ' StatusCode ' +
              error.getStatusCode();
            respuesta.idSF = insertable.id;
            respuesta.MnsjRta = 'Operación fallida';
          }
        }

        i++;
      }
    }

    return respuestas;
  }

  private static Ingreso_a_taller__c convertToInsertable(Input inputItem) {
    Ingreso_a_taller__c ingresoToInsert = new Ingreso_a_taller__c();
    ingresoToInsert.Fecha_de_asistencia__c = strToDate(
      inputItem.F350_FECHA_TS_APROBACION
    );
    ingresoToInsert.Fecha_de_Factura__c = strToDate(inputItem.F350_350);
    ingresoToInsert.Notas__c = inputItem.F350_Notas;
    ingresoToInsert.Numero_de_documento__c = inputItem.Nro_Documento;
    //   ingresoToInsert.Quien_atiende_el_vehiculo__c = inputItem.;
    ingresoToInsert.Servicio_prestado__c = inputItem.F021_descripcion;
    // ingresoToInsert.Tipo_de_Vehiculo__c = inputItem.F926_ID_TIPO_VEHICULO;
    if (inputItem.F926_ID_TIPO_VEHICULO == '1')
      ingresoToInsert.Tipo_de_Vehiculo__c = 'Vehiculo Honda';
    if (inputItem.F926_ID_TIPO_VEHICULO == '2')
      ingresoToInsert.Tipo_de_Vehiculo__c = 'Vehiculo Otras marcas';
    ingresoToInsert.Valor_neto__c = Decimal.valueOf(inputItem.Valor_Neto);

    List<Asset> vehiculos = [
      SELECT Id, Name, Id_Vehiculo_ERP__c //VIN__c
      FROM Asset
      // WHERE VIN__c = :inputItem.F926_ID
      WHERE Id_Vehiculo_ERP__c = :inputItem.F926_ID
    ];
    if (vehiculos.size() == 0) {
      return null;
    }
    Asset vehiculo = vehiculos[0];
    ingresoToInsert.Vehiculo__c = vehiculo.Id;
    ingresoToInsert.Name = vehiculo.Name + ' ' + vehiculo.Id_Vehiculo_ERP__c; //vehiculo.VIN__c;

    return ingresoToInsert;
  }

  private static Date strToDate(String dateString) {
    try {
      // TODO: accept YYYY-MM-DD
      List<String> parts = dateString.split('/');
      String newDateString = parts[2] + '-' + parts[1] + '-' + parts[0];
      return Date.valueOf(newDateString);
    } catch (Exception ex) {
      throw new IllegalArgumentException(
        'Formato de fecha "' +
        dateString +
        '" incorrecto'
      );
    }
  }
}