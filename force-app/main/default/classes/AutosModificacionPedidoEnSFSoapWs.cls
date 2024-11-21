/**
 * Fanalca
 * @author           Olvin Abarca
 * Description:      This class exposes method that updates properties in Order records.
 *
 * Changes (Version)
 * -------------------------------------
 *           No.     Date            Author                  Description
 *           -----   ----------      --------------------    ---------------
 * @version  1.0     12/11/2020      Olvin Abarca            Class definition.
 *********************************************************************************************************/
global class AutosModificacionPedidoEnSFSoapWs {
  global class ConfirmarInput {
    webService String Consecutivo_pedido { get; set; } // Número generado automáticamente por SF que fue enviado al ERP  al momento de enviar los datos  para solicitar la creación del pedido
    webService Boolean Pedido_creado_ERP { get; set; } // True si la creación fue exitosa
    webService String Estado_Pedido_en_ERP { get; set; } // Estado del pedido en el ERP
  }

  global class ModificarInput {
    webService String f431_referencia_item { get; set; }
    webService Decimal f431_precio_unitario { get; set; }
    webService String f430_num_docto_referencia { get; set; }
  }

  global class Output {
    webService String error { get; set; }
    webService String MnsjRta { get; set; }
    webService String idSF { get; set; }
  }

  webService static List<Output> confirmar(List<ConfirmarInput> inputList) {
    List<Output> outputs = new List<Output>();

    List<Order> dbRecords = new List<Order>();

    for (ConfirmarInput input : inputList) {
      Output output = new Output();

      try {
        Order dbRecord = (Order) convertToConfirmarDbRecord(input);
        dbRecords.add(dbRecord);

        output.error = '';
        output.mnsjRta = 'Operación exitosa';
        output.idSF = dbRecord.Id;
      } catch (Exception ex) {
        output.error = ex.getMessage();
        output.mnsjRta = 'Operación fallida';
        output.idSF = '';
      }

      outputs.add(output);
    }

    if (dbRecords.size() > 0) {
      List<Database.SaveResult> saveResults = Database.update(dbRecords, false);

      Integer i = 0;
      for (Database.SaveResult saveResult : saveResults) {
        Order dbRecord = dbRecords.get(i);

        while (outputs[i].error != '') {
          // operacion fallida
          i++;
        }
        Output output = outputs[i];

        if (saveResult.isSuccess()) {
          //   output.MnsjRta = 'Operación exitosa';
          //   output.error = '';
          //   output.idSF = dbRecord.Id;
        } else {
          for (Database.Error error : saveResult.getErrors()) {
            output.error =
              'Error: ' +
              error.getMessage() +
              ' Campos ' +
              error.getFields() +
              ' StatusCode ' +
              error.getStatusCode();
            output.idSF = dbRecord.id;
            output.MnsjRta = 'Operación fallida';
          }
        }

        i++;
      }
    }

    return outputs;
  }

  private static Object convertToConfirmarDbRecord(ConfirmarInput input) {
    Order order = [
      SELECT Id, OrderNumber, Pedido_creado_ERP__c, Estado_Pedido_en_ERP__c
      FROM Order
      WHERE OrderNumber = :input.Consecutivo_pedido
      LIMIT 1
    ];
    order.Pedido_creado_ERP__c = input.Pedido_creado_ERP;
    order.Estado_Pedido_en_ERP__c = input.Estado_Pedido_en_ERP;
    return order;
  }

  webService static List<Output> modificar(List<ModificarInput> inputList) {
    List<Output> outputs = new List<Output>();

    List<Order> dbRecords = new List<Order>();

    for (ModificarInput input : inputList) {
      Output output = new Output();

      try {
        Order dbRecord = convertToModificarDbRecord(input);
        dbRecords.add(dbRecord);

        output.error = '';
        output.mnsjRta = 'Operación exitosa';
        output.idSF = dbRecord.Id;
      } catch (Exception ex) {
        output.error = ex.getMessage();
        output.mnsjRta = 'Operación fallida';
        output.idSF = '';
      }

      outputs.add(output);
    }

    if (dbRecords.size() > 0) {
      List<Database.SaveResult> saveResults = Database.update(dbRecords, false);

      Integer i = 0;
      for (Database.SaveResult saveResult : saveResults) {
        Order dbRecord = dbRecords.get(i);

        while (outputs[i].error != '') {
          // operacion fallida
          i++;
        }
        Output output = outputs[i];

        if (saveResult.isSuccess()) {
          // update associated opportunity line item's properties
          String exceptionMessage = updateOLI(dbRecord);
          if (exceptionMessage != null) {
            output.MnsjRta = 'Operación fallida';
            output.error = exceptionMessage;
            output.idSF = dbRecord.Id;
          }
        } else {
          for (Database.Error error : saveResult.getErrors()) {
            output.error =
              'Error: ' +
              error.getMessage() +
              ' Campos ' +
              error.getFields() +
              ' StatusCode ' +
              error.getStatusCode();
            output.idSF = dbRecord.id;
            output.MnsjRta = 'Operación fallida';
          }
        }

        i++;
      }
    }

    return outputs;
  }

  private static Order convertToModificarDbRecord(ModificarInput input) {
    // TODO: Document asks to use "Consecutivo_pedido__c", but consecutive in
    // SF is called OrderNumber
    Order orderObj = [
      SELECT Id, OrderNumber, OpportunityId
      FROM Order
      WHERE OrderNumber = :input.f430_num_docto_referencia
      LIMIT 1
    ];

    // TODO: UnitPrice suggested by document is not avaialble in Order, but OrderItem
    orderObj.Precio_de_vehiculo_IVA_incluido__c = input.f431_precio_unitario;

    // codigo_producto__c was not present in Order. I had to create it
    orderObj.Codigo_Producto__c = input.f431_referencia_item;

    // TODO: no se conoce el nombre en input
    // orderObj.ID_de_pedido_ERP__c = input.
    return orderObj;
  }

  private static String updateOLI(Order order) {
    try {
      OpportunityLineItem oli = [
        SELECT Id, Name
        FROM OpportunityLineItem
        WHERE OpportunityId = :order.OpportunityId
        LIMIT 1
      ];
      oli.UnitPrice = order.Precio_de_vehiculo_IVA_incluido__c;
      oli.Codigo_Producto__c = order.Codigo_Producto__c; // Field OpportunityLineItem.ProductCode is not writeable. Error thrown

      update oli;

      return null;
    } catch (Exception ex) {
      return ex.getMessage();
    }
  }
}