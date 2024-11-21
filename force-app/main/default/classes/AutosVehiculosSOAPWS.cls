global class AutosVehiculosSOAPWS {
  global class VehiculosWS {
    webService string F926_ID { get; set; }
    webService string F926_ID_PROPIETARIO { get; set; }
    webService string F926_MATRICULA { get; set; }
    webService string F926_NRO_SERIE { get; set; }
    webService integer F926_ID_TIPO_VEHICULO { get; set; }
    webService string F926_NRO_CHASIS { get; set; }
    webService string F926_MODELO { get; set; }
    webService integer F926_ANO { get; set; }
    webService integer F926_IND_ESTADO_BLOQUEADO { get; set; }
    webService string F926_MOTIVO_BLOQUEO { get; set; }
    webService string F927_ID_PLAN_105 { get; set; } //Clase Vehiculo
    webService string F927_ID_MAYOR_105 { get; set; }
    webService string F927_ID_PLAN_106 { get; set; }
    webService string F927_ID_MAYOR_106 { get; set; } //Tipo de carrocería
    webService string F927_ID_PLAN_107 { get; set; }
    webService string F927_ID_MAYOR_107 { get; set; } //No Puertas
    webService string F927_ID_PLAN_109 { get; set; }
    webService string F927_ID_MAYOR_109 { get; set; } //Tipo Caja
    webService string F927_ID_PLAN_110 { get; set; }
    webService string F927_ID_MAYOR_110 { get; set; } //Color
    webService string F927_ID_PLAN_111 { get; set; }
    webService string F927_ID_MAYOR_111 { get; set; } //Tipo Motor
    webService string F927_ID_PLAN_112 { get; set; }
    webService string F927_ID_MAYOR_112 { get; set; } //Versión
    webService string F927_ID_PLAN_113 { get; set; }
    webService string F927_ID_MAYOR_113 { get; set; } //Tipo de Servicio
    webService string F927_ID_PLAN_H30 { get; set; }
    webService string F927_ID_MAYOR_H30 { get; set; } //Honda Modelo Autos
    //Name: H30 mayor + F927_ID_MAYOR_112 + F926_ANO
    //Cual campo ocupo para name? por confirmar: modelo f926 + version(anexo 2, 112, mayor 112) y año, solo tenemos año en la integraion para mientaras
    //F926_ID, está bien este campo que lo cree en asset?  le pongo como exclusivo? si lo pongo exclusivo no se repetirá realmente? no se repetirá algun codigo para motos?

    webService string MOTOR { get; set; }
    webService string CILINDRAJE { get; set; }
  }

  global class ClienteRta {
    webService String error { get; set; }
    webService String MnsjRta { get; set; }
    webService String idSF { get; set; }
  }

  webService static list<clienteRta> VehiculosAdd(list<VehiculosWS> lstWS) {
    system.debug('AutosVehiculosSOAPWS: Entrando a VehiculosAdd');
    list<clienteRta> lstclienteRta = new List<clienteRta>();
    list<Asset> lstInsertar = new List<Asset>();
    try {
      set<String> setClienteIdentificacion = new Set<String>();
      map<String, Account> mapClientes = new Map<String, Account>();
      for (VehiculosWS itemWS : lstWS) {
        setClienteIdentificacion.add(itemWS.F926_ID_PROPIETARIO);
      }
      for (Account a : [
        SELECT Id, AM_Numero_de_documento__c
        FROM account
        WHERE AM_Numero_de_documento__c IN :setClienteIdentificacion
      ]) {
        mapClientes.put(a.AM_Numero_de_documento__c, a);
      }

      RecordType rtAutosAsset = [
        SELECT id, DeveloperName
        FROM RecordType
        WHERE
          sobjecttype = 'Asset'
          AND isActive = TRUE
          AND DeveloperName = :Label.AutosRecordTypeDevNameAsset
        LIMIT 1
      ];
      for (VehiculosWS itemWS : lstWS) {
        System.debug(' ** REQUEST ** ' + itemWS);

        Asset objSF = new Asset();
        //De dónde saco el objSF.Name ='';
        //objSF.Name = ''+ itemWS.F927_ID_MAYOR_112 + itemWS.F926_ANO;
        objSF.Id_Vehiculo_ERP__c = itemWS.F926_ID;
        if (
          itemWS.F926_ID_PROPIETARIO != null &&
          itemWS.F926_ID_PROPIETARIO != '' &&
          mapClientes.containsKey(itemWS.F926_ID_PROPIETARIO)
        )
          objSF.AccountId = mapClientes.get(itemWS.F926_ID_PROPIETARIO).Id;
        objSF.Placa__c = itemWS.F926_MATRICULA;
        objSF.VIN__c = itemWS.F926_NRO_SERIE;
        objSF.Tipo_Vehiculo__c = itemWS.F926_ID_TIPO_VEHICULO == 1
          ? 'VEHICULOS HONDA'
          : (itemWS.F926_ID_TIPO_VEHICULO == 2 ? 'VEHICULOS OTRAS MARCA' : ''); 
        objSF.Name = itemWS.F926_MODELO + ' ' + itemWS.F927_ID_MAYOR_112 + ' ' + itemWS.F927_ID_MAYOR_109 + ' ' + itemWS.F926_ANO; //objSF.Tipo_Vehiculo__c + ' ' + objSF.Id_Vehiculo_ERP__c;
        objSF.Numero_Chasis__c = itemWS.F926_NRO_CHASIS;
        objSF.Modelo__c = itemWS.F926_MODELO;
        objSF.Ano__c = itemWS.F926_ANO;
        objSF.Estado_Bloqueado__c = itemWS.F926_IND_ESTADO_BLOQUEADO == 1
          ? true
          : false;
        objSF.Motivo_Bloqueo__c = itemWS.F926_MOTIVO_BLOQUEO;
        objSF.Plan_105__c = itemWS.F927_ID_PLAN_105;
        objSF.Mayor_105__c = itemWS.F927_ID_MAYOR_105;
        objSF.Plan_106__c = itemWS.F927_ID_PLAN_106;
        objSF.Mayor_106__c = itemWS.F927_ID_MAYOR_106;
        objSF.Plan_107__c = itemWS.F927_ID_PLAN_107;
        objSF.Mayor_107__c = itemWS.F927_ID_MAYOR_107;
        objSF.Plan_109__c = itemWS.F927_ID_PLAN_109;
        objSF.Mayor_109__c = itemWS.F927_ID_MAYOR_109;
        objSF.Plan_110__c = itemWS.F927_ID_PLAN_110;
        objSF.Mayor_110__c = itemWS.F927_ID_MAYOR_110;
        objSF.Plan_111__c = itemWS.F927_ID_PLAN_111;
        objSF.Mayor_111__c = itemWS.F927_ID_MAYOR_111;
        objSF.Plan_112__c = itemWS.F927_ID_PLAN_112;
        objSF.Mayor_112__c = itemWS.F927_ID_MAYOR_112;
        objSF.Plan_113__c = itemWS.F927_ID_PLAN_113;
        objSF.Mayor_113__c = itemWS.F927_ID_MAYOR_113;
        objSF.Plan_H30__c = itemWS.F927_ID_PLAN_H30;
        objSF.Mayor_H30__c = itemWS.F927_ID_MAYOR_H30;
        objSF.RecordTypeId = rtAutosAsset.Id;
        objSF.Motor__c = itemWS.MOTOR;
        objSF.Cilindraje__c = itemWS.CILINDRAJE;

        //objProducto.Name = producto.MARA_MKTXT;

        //objProducto.isActive = producto.MARA_LVORM =='X' ? false : true;
        lstInsertar.add(objSF);
      }

      if (lstInsertar.size() > 0) {
        system.debug(
          'AutosVehiculosSOAPWS: Hay Elementos que insertar: ' +
          lstInsertar.size()
        );
        list<Database.SaveResult> SaveResult = database.insert(
          lstInsertar,
          false
        );

        Integer i = 0;
        for (Database.SaveResult result : SaveResult) {
          Asset c = lstInsertar.get(i);
          clienteRta r = new clienteRta();
          if (result.isSuccess()) {
            r.MnsjRta = 'Operación exitosa';
            r.error = '';
            r.idSF = c.id;
          } else {
            for (Database.Error e : result.getErrors()) {
              r.error = 'Error: ' + e.getMessage();
              r.MnsjRta = 'Operación fallida';
              r.idSF = c.id;
            }
          }
          lstclienteRta.add(r);
          i += i;
        }
      }
    } catch (System.exception ex) {
      clienteRta crta = new clienteRta();
      crta.error = 'ERROR: ' + ex.getMessage();
      crta.mnsjRta = 'Problemas en la ejecución del webservice';
      crta.idSF = '';
      lstclienteRta.add(crta);
    }

    for (clienteRta rta : lstclienteRta) {
      System.debug(' ** ERROR WEB SERVICE PRODUCTOS ** ' + rta);
    }
    system.debug('AutosVehiculosSOAPWS: Saliendo de productoAdd');
    return lstclienteRta;
  }

  webService static list<clienteRta> VehiculosUpdate(list<VehiculosWS> lstWS) {
    system.debug('AutosVehiculosSOAPWS: Entrando a VehiculosAdd');
    list<clienteRta> lstclienteRta = new List<clienteRta>();
    list<Asset> lstActualizar = new List<Asset>();
    try {
      RecordType rtAutosAsset = [
        SELECT id, DeveloperName
        FROM RecordType
        WHERE
          sobjecttype = 'Asset'
          AND isActive = TRUE
          AND DeveloperName = :Label.AutosRecordTypeDevNameAsset
        LIMIT 1
      ];

      set<String> setClienteIdentificacion = new Set<String>();
      map<String, Account> mapClientes = new Map<String, Account>();
      set<String> setF926Ids = new Set<String>();
      map<String, Asset> mapAssets = new Map<String, Asset>();
      for (VehiculosWS itemWS : lstWS) {
        setClienteIdentificacion.add(itemWS.F926_ID_PROPIETARIO);
        setF926Ids.add(itemWS.F926_ID);
      }
      for (Account a : [
        SELECT Id, AM_Numero_de_documento__c
        FROM account
        WHERE AM_Numero_de_documento__c IN :setClienteIdentificacion
      ]) {
        mapClientes.put(a.AM_Numero_de_documento__c, a);
      }
      for (Asset a : [
        SELECT Id, Id_Vehiculo_ERP__c, AccountId
        FROM asset
        WHERE
          Id_Vehiculo_ERP__c IN :setF926Ids
          AND RecordTypeId = :rtAutosAsset.Id
      ]) {
        mapAssets.put(a.Id_Vehiculo_ERP__c, a);
      }

      for (VehiculosWS itemWS : lstWS) {
        System.debug(' ** REQUEST ** ' + itemWS);

        Asset objSF = new Asset();
        //De dónde saco el objSF.Name ='';
        if (
          itemWS.F926_ID_PROPIETARIO != null &&
          itemWS.F926_ID_PROPIETARIO != ''
        ) {
          if (mapClientes.containsKey(itemWS.F926_ID_PROPIETARIO))
            objSF.AccountId = mapClientes.get(itemWS.F926_ID_PROPIETARIO).Id;
          else
            throw new DmlException(
              'El Cliente con identificación ' +
              itemWS.F926_ID_PROPIETARIO +
              ' no fue encontrado'
            );
        } else {
          if (
            mapAssets.containsKey(itemWS.F926_ID) &&
            mapAssets.get(itemWS.F926_ID).AccountId != null
          )
            throw new DmlException(
              'El Propietario es requerido cuando el vehículo ya tenía uno asignado'
            );
        }
        objSF.AccountId = mapClientes.get(itemWS.F926_ID_PROPIETARIO).Id;
        if (
          itemWS.F926_ID != null &&
          itemWS.F926_ID != '' &&
          mapAssets.containsKey(itemWS.F926_ID)
        )
          objSF.Id = mapAssets.get(itemWS.F926_ID).Id;
        objSF.Placa__c = itemWS.F926_MATRICULA;
        objSF.VIN__c = itemWS.F926_NRO_SERIE;
        objSF.Tipo_Vehiculo__c = itemWS.F926_ID_TIPO_VEHICULO == 1
          ? 'VEHICULOS HONDA'
          : (itemWS.F926_ID_TIPO_VEHICULO == 2 ? 'VEHICULOS OTRAS MARCA' : '');
        objSF.Name = itemWS.F926_MODELO + ' ' + itemWS.F927_ID_MAYOR_112 + ' ' + itemWS.F927_ID_MAYOR_109 + ' ' + itemWS.F926_ANO;//objSF.Tipo_Vehiculo__c + ' ' + itemWS.F926_ID;
        objSF.Numero_Chasis__c = itemWS.F926_NRO_CHASIS;
        objSF.Modelo__c = itemWS.F926_MODELO;
        objSF.Ano__c = itemWS.F926_ANO;
        objSF.Estado_Bloqueado__c = itemWS.F926_IND_ESTADO_BLOQUEADO == 1
          ? true
          : false;
        objSF.Motivo_Bloqueo__c = itemWS.F926_MOTIVO_BLOQUEO;
        objSF.Plan_105__c = itemWS.F927_ID_PLAN_105;
        objSF.Mayor_105__c = itemWS.F927_ID_MAYOR_105;
        objSF.Plan_106__c = itemWS.F927_ID_PLAN_106;
        objSF.Mayor_106__c = itemWS.F927_ID_MAYOR_106;
        objSF.Plan_107__c = itemWS.F927_ID_PLAN_107;
        objSF.Mayor_107__c = itemWS.F927_ID_MAYOR_107;
        objSF.Plan_109__c = itemWS.F927_ID_PLAN_109;
        objSF.Mayor_109__c = itemWS.F927_ID_MAYOR_109;
        objSF.Plan_110__c = itemWS.F927_ID_PLAN_110;
        objSF.Mayor_110__c = itemWS.F927_ID_MAYOR_110;
        objSF.Plan_111__c = itemWS.F927_ID_PLAN_111;
        objSF.Mayor_111__c = itemWS.F927_ID_MAYOR_111;
        objSF.Plan_112__c = itemWS.F927_ID_PLAN_112;
        objSF.Mayor_112__c = itemWS.F927_ID_MAYOR_112;
        objSF.Plan_113__c = itemWS.F927_ID_PLAN_113;
        objSF.Mayor_113__c = itemWS.F927_ID_MAYOR_113;
        objSF.Plan_H30__c = itemWS.F927_ID_PLAN_H30;
        objSF.Mayor_H30__c = itemWS.F927_ID_MAYOR_H30;
        objSF.RecordTypeId = rtAutosAsset.Id;
        objSF.Motor__c = itemWS.MOTOR;
        objSF.Cilindraje__c = itemWS.CILINDRAJE;

        //objSF.isActive = ;
        lstActualizar.add(objSF);
      }

      if (lstActualizar.size() > 0) {
        system.debug(
          'AutosVehiculosSOAPWS: Hay Elementos que insertar: ' +
          lstActualizar.size()
        );
        list<Database.SaveResult> SaveResult = database.update(
          lstActualizar,
          false
        );

        Integer i = 0;
        for (Database.SaveResult result : SaveResult) {
          Asset c = lstActualizar.get(i);
          clienteRta r = new clienteRta();
          if (result.isSuccess()) {
            r.MnsjRta = 'Operación exitosa';
            r.error = '';
            r.idSF = c.id;
          } else {
            for (Database.Error e : result.getErrors()) {
              r.error = 'Error: ' + e.getMessage();
              r.MnsjRta = 'Operación fallida';
              r.idSF = c.id;
            }
          }
          lstclienteRta.add(r);
          i += i;
        }
      }
    } catch (System.exception ex) {
      clienteRta crta = new clienteRta();
      crta.error = 'ERROR: ' + ex.getMessage();
      crta.mnsjRta = 'Problemas en la ejecución del webservice';
      crta.idSF = '';
      lstclienteRta.add(crta);
    }

    for (clienteRta rta : lstclienteRta) {
      System.debug(' ** ERROR WEB SERVICE PRODUCTOS ** ' + rta);
    }
    system.debug('AutosVehiculosSOAPWS: Saliendo de productoAdd');
    return lstclienteRta;
  }
}