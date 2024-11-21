/**
 * Fanalca
 * @author           Olvin Abarca
 * Description:      Clase para generar informacion que se visualiza en VFP "CumplimientoEnMetaDeVentasAutos"
 *
 * Changes (Version)
 * -------------------------------------
 *           No.     Date            Author                  Description
 *           -----   ----------      --------------------    ---------------
 * @version  1.0     08/16/2021      Olvin Abarca            Class definition.
 * @version  1.1     09/23/2021      Olvin Abarca            Added "with sharing"
 *********************************************************************************************************/
public with sharing class DatosReporteForecastVentasAutos {
    public List<Decimal> output { get; set; }
    public String reportId { get; set; }
  
    public DatosReporteForecastVentasAutos() {

      String userId = UserInfo.getUserId();
      String reportId = null;
      output = new List<Decimal>();
  
      User user = [
        SELECT Id, Profile.Name
        FROM User
        WHERE Id = :userId
      ];

      Decimal oppCount = 0;
      Decimal oppGoal = 0;
      Integer usuarioEsAsesor = (user.Profile.Name == Label.Autos_Nombre_Perfil_Asesores_Autos || user.Profile.Name == Label.Autos_Nombre_Perfil_Asesores_Autos_Renting) ? 1 : 0;

      Map<String, Object> dataMap = getMapFor(UserInfo.getUserId(), user.Profile.Name);
      this.reportId = (String) dataMap.get('reportId');
      Object opportunityCount = dataMap.get('OpportunityCount');
      oppCount = (Decimal) (opportunityCount);

      oppGoal = getMetaCountFor(user.Id);

      Boolean isZeroOpportinities = oppCount == 0;
      Boolean isNoMetaDeVenta = oppGoal == 0;
      Boolean isShowingZeros = isZeroOpportinities || isNoMetaDeVenta;

      Decimal proporcion = isShowingZeros ? 0.0 : ((oppCount / oppGoal) * 100);

      output.add(oppCount);
      output.add(oppGoal);
      output.add(usuarioEsAsesor);
      output.add(proporcion);

    }

    public static Map<String, Object> getMapFor(String userId, String profileName){
        Map<String, Object> dataMap;

        if(profileName.indexOf('Analista de Mercadeo') == 0){
          profileName = 'Administrativo autos';
        }

        switch on ProfileName {
            when 'Administrativo autos' {
              dataMap = getMapForAdministrativaAutos(userId);
            }
            when 'Asesores autos' {
              dataMap = getMapForAsesoresAutos(userId);
            }
            when 'Asesores autos renting' {
                dataMap = getMapForAsesoresAutos(userId);
            }
            when 'Gerencias autos' {
              dataMap = getMapForGerenciasAutos(userId);
            }
            when 'Asesores Autos Test' {
                dataMap = getMapForAsesoresAutos(userId);
            }
            when 'Gerencias Autos Test' {
                dataMap = getMapForGerenciasAutos(userId);
            }
            when else {
                dataMap = getMapForGerenciaGeneralAutos(userId);
            //   dataMap = getMapForAsesoresAutos(userId);
            }
        }

        return dataMap;
    }
  
    public static Map<String, Object> getMapForAdministrativaAutos(String oppOwnerId){

      List<OpportunityLineItem> olis = [
        SELECT 
          Opportunity.StageName, 
          Opportunity.Vitrina__c,
          Meta_Manager__c
        FROM OpportunityLineItem
        WHERE
          Opportunity.Fecha_de_factura__c = THIS_MONTH
          AND Opportunity.StageName IN ('P5','PU')
          AND Opportunity.Tipo_de_Oportunidad__c IN ('Nuevos', 'Renting')
          AND (Opportunity.ManagerFilter__c = 1 OR Opportunity.RentingManagerFilter__c = 1 OR Opportunity.UserFilter__c = 1)
      ];

      OpportunityLineItem oli = new OpportunityLineItem();
      oli.Meta_Manager__c = olis.size() > 0 ? olis[0].Meta_Manager__c : oli.Meta_asesor__c;
      
      Meta_de_Venta__c metaDeVenta = getMetaDeVenta(oli.Meta_Manager__c);

      Set<Id> userConcesionarioIds = null;
      Map<String, Object> results = genMapFromOLIs(olis, metaDeVenta, System.Label.Autos_Reporte_Cumplimiento_Gerente, userConcesionarioIds);
      return results;
  }

    public static Map<String, Object> getMapForAsesoresAutos(String oppOwnerId){
        // String profileName = Label.Autos_Nombre_Perfil_Asesores_Autos Label.Autos_Nombre_Perfil_Asesores_Autos_Renting;
        List<OpportunityLineItem> olis = [
          SELECT 
                Opportunity.StageName,
                Opportunity.Vitrina__c,
                Meta_asesor__c
          FROM OpportunityLineItem
          WHERE
            Opportunity.Fecha_de_factura__c = THIS_MONTH
            AND Opportunity.StageName IN ('P5','PU')
            //AND Opportunity.OwnerId = :oppOwnerId
            AND Opportunity.Tipo_de_Oportunidad__c IN ('Nuevos', 'Renting')
            AND Opportunity.UserFilter__c = 1
            //AND SyncedQuoteId != NULL
        ];

        OpportunityLineItem oli = new OpportunityLineItem();
        oli.Meta_asesor__c = olis.size() > 0 ? olis[0].Meta_asesor__c : oli.Meta_asesor__c;

        Meta_de_Venta__c metaDeVenta = getMetaDeVenta(oli.Meta_asesor__c);

        Set<Id> userConcesionarioIds = null;
        Map<String, Object> results = genMapFromOLIs(olis, metaDeVenta, System.Label.Autos_Reporte_Cumplimiento_Asesor, userConcesionarioIds);
        return results;
    }

    public static Map<String, Object> getMapForGerenciasAutos(String oppOwnerId){
        // String profileName = Label.Autos_Nombre_Perfil_Gerentes_Autos;

        // List<User> subordinates = [SELECT Id FROM User WHERE ManagerId = :oppOwnerId];
        // Map<Id, User> subordinatesMap = new Map<Id, User>(subordinates);
        // subordinatesMap.put(oppOwnerId, null); // adding Manager himself 

        // // adding asesores that belong to same concesionario
        // List<Miembro_de_Concesionario__c> miembrosConcesionario = [SELECT Id, Concesionario__c FROM Miembro_de_Concesionario__c WHERE Nombre_de_asesor__c = :oppOwnerId];
        
        // Set<Id> userConcesionarioIds = new Set<Id>();
        // for(Miembro_de_Concesionario__c mc : miembrosConcesionario){
        //   userConcesionarioIds.add(mc.Concesionario__c);
        // }

        // List<Miembro_de_Concesionario__c> miembroConcesionariosAsesores = [SELECT Id, Nombre_de_asesor__c FROM Miembro_de_Concesionario__c WHERE Concesionario__c IN :userConcesionarioIds AND Asesor_de_renting2__c = true];
        // for(Miembro_de_Concesionario__c miembroDeConcesionario : miembroConcesionariosAsesores){
        //     subordinatesMap.put(miembroDeConcesionario.Nombre_de_asesor__c, null);
        // }

        List<OpportunityLineItem> olis = [
          SELECT 
            Opportunity.StageName, 
            Opportunity.Vitrina__c,
            Meta_Manager__c
          FROM OpportunityLineItem
          WHERE
            Opportunity.Fecha_de_factura__c = THIS_MONTH
            AND Opportunity.StageName IN ('P5','PU')
            // AND Opportunity.OwnerId IN :subordinatesMap.keySet()
            AND Opportunity.Tipo_de_Oportunidad__c IN ('Nuevos', 'Renting')
            AND (Opportunity.ManagerFilter__c = 1 OR Opportunity.RentingManagerFilter__c = 1 OR Opportunity.UserFilter__c = 1)
      
            //AND SyncedQuoteId != NULL
        ];

        OpportunityLineItem oli = new OpportunityLineItem();
        oli.Meta_Manager__c = olis.size() > 0 ? olis[0].Meta_Manager__c : oli.Meta_asesor__c;
        
        Meta_de_Venta__c metaDeVenta = getMetaDeVenta(oli.Meta_Manager__c);

        Set<Id> userConcesionarioIds = null;
        Map<String, Object> results = genMapFromOLIs(olis, metaDeVenta, System.Label.Autos_Reporte_Cumplimiento_Gerente, userConcesionarioIds);
        return results;
    }

    public static Map<String, Object> getMapForGerenciaGeneralAutos(String oppOwnerId){
        // String profileName = 'Gerencia General autos';

        // List<User> subordinates = [SELECT Id FROM User WHERE ManagerId = :oppOwnerId];
        // Map<Id, User> subordinatesMap = new Map<Id, User>(subordinates);
        // subordinatesMap.put(oppOwnerId, null); // adding Manager himself 

        List<OpportunityLineItem> olis = [
          SELECT 
            Opportunity.StageName,
            Opportunity.Vitrina__c,
            Meta_GerenteGeneral__c 
          FROM 
            OpportunityLineItem
          WHERE
            Opportunity.Fecha_de_factura__c = THIS_MONTH
            AND Opportunity.StageName IN ('P5','PU')
            AND Opportunity.Tipo_de_Oportunidad__c IN ('Nuevos', 'Renting')
            AND Opportunity.RecordType.DeveloperName = :System.Label.RTOportunidadAutos
            // AND Opportunity.SyncedQuoteId != NULL
            // AND Opportunity.OwnerId IN :subordinatesMap.keySet()
        ];

        OpportunityLineItem oli = new OpportunityLineItem();
        oli.Meta_GerenteGeneral__c = olis.size() > 0 ? olis[0].Meta_GerenteGeneral__c : oli.Meta_GerenteGeneral__c;

        Meta_de_Venta__c metaDeVenta = getMetaDeVenta(oli.Meta_Manager__c);

        Set<Id> userConcesionarioIds = null;
        Map<String, Object> results = genMapFromOLIs(olis, metaDeVenta, System.Label.Autos_Reporte_Cumplimiento_Gerente_General, userConcesionarioIds);
        return results;
    }


    public static Meta_de_Venta__c getMetaDeVenta(String metaDeVentaId){
        List<Meta_de_Venta__c> metasDeVenta = (metaDeVentaId == null) ? null : [
            SELECT 
                Id, 
                Asesor__c,
                Anio__c,
                Cuota__c,
                Mes__c,
                Name,
                UniqueKey__c,
                Version__c
            FROM
                Meta_de_Venta__c
            WHERE
                Id = :metaDeVentaId
        ];

        return (metasDeVenta != null && metasDeVenta.size() > 0) ? metasDeVenta[0] : null;
    }


    public static Map<String, Object> genMapFromOLIs(List<OpportunityLineItem> olis, Meta_de_Venta__c metaDeVenta, String reportId, Set<Id> userConcesionarioIds){

        Set<Id> opportunityIds = new Set<Id>();
        for(OpportunityLineItem oli : olis){
            if( !opportunityIds.contains(oli.OpportunityId)){
                System.debug('oid: ' + oli.OpportunityId);

                // if(userConcesionarioIds != null){
                //   // match concesionarion from Opportunity with 
                //   // concesionario from the user visualizing the report
                //   System.debug('m: ' + oli.OpportunityId);

                //   if(userConcesionarioIds.contains(oli.Opportunity.Vitrina__c)){
                //     System.debug('m2: ' + oli.OpportunityId);
                //     opportunityIds.add(oli.OpportunityId);
                //   }
                // }else{
                  opportunityIds.add(oli.OpportunityId);
                // }
            }
        }

        Map<String, Object> result = new Map<String, Object>();
        result.put('metaDeVenta', metaDeVenta);
        result.put('reportId', reportId);
        result.put('OpportunityLineItems', olis);
        result.put('OpportunityCount', opportunityIds.size());

        return result;
    }

    public static Decimal getMetaCountFor(String asesorId){
     String hoy = String.valueOf(date.today());
    String traerAnio = hoy.left(4);
    String traerMes = '';

    String mesNumeroString = hoy.left(7).right(2);

    Map<String, String> meses = new Map<String, String>();
    meses.put('01', 'Enero');
    meses.put('02', 'Febrero');
    meses.put('03', 'Marzo');
    meses.put('04', 'Abril');
    meses.put('05', 'Mayo');
    meses.put('06', 'Junio');
    meses.put('07', 'Julio');
    meses.put('08', 'Agosto');
    meses.put('09', 'Septiembre');
    meses.put('10', 'Octubre');
    meses.put('11', 'Noviembre');
    meses.put('12', 'Diciembre');

    traerMes = meses.get(mesNumeroString);
        List<Meta_de_Venta__c> metas = [SELECT Cuota__c FROM Meta_de_Venta__c 
                                        WHERE Asesor__c = :asesorId AND Version__c <> 'USADOS' 
                                        AND Anio__c = :traerAnio AND Mes__c = :traerMes];
        Decimal metaCount = 0;
        for(Meta_de_Venta__c meta : metas){
            metaCount += (meta.Cuota__c == null) ? 0 : meta.Cuota__c;
        }
        return metaCount;
    }

  }