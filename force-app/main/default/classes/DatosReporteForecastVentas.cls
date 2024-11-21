/**
 * Fanalca
 * @author           Olvin Abarca
 * Description:      Clase para guardar el forecast de venta de cada asesor y gerente.
 *
 * Changes (Version)
 * -------------------------------------
 *           No.     Date            Author                  Description
 *           -----   ----------      --------------------    ---------------
 * @version  1.0     22/01/2021      Olvin Abarca            Class definition.
 * @version  1.0     23/01/2021      Juan Ansaldi            Update initForecasts().
 *********************************************************************************************************/
public with sharing class DatosReporteForecastVentas {
  public List<Decimal> output { get; set; }
  public String reportId { get; set; }
  private Map<Id, Meta_de_Venta__c> forecasts;

  public DatosReporteForecastVentas() {
    output = new List<Decimal>();
    List<Report> lstReporte = [
      SELECT Id, DeveloperName
      FROM Report
      WHERE DeveloperName = 'Cuota_oportunidades_productos'
      LIMIT 1
    ];
    if (lstReporte.size() > 0) {
      reportId = lstReporte[0].Id;
    }

    forecasts = initForecasts();

    Decimal oppCount = 0;
    Decimal oppGoal = 0;
    Integer usuarioEsAsesor = 0;

    User user = [
      SELECT Id, Profile.Name
      FROM User
      WHERE Id = :UserInfo.getUserId()
    ];
    if (user.Profile.Name.contains('Asesores motos')) {
      usuarioEsAsesor = 1;

      List<Opportunity> opportunities = [
        SELECT Name, StageName, CloseDate, Amount, Owner.Name, Owner.Username
        FROM Opportunity
        WHERE
          CloseDate = THIS_MONTH
          AND OwnerId = :UserInfo.getUserId()
          AND StageName = 'Vendida'
      ];
      oppCount = opportunities.size();

      Meta_de_Venta__c forecast = forecasts.get(UserInfo.getUserId());

      if (forecast != null) {
        oppGoal = forecast.Cuota__c;
      }
    } else {
      // usuario no es asesor

      String userId = user.Id;
      List<Miembro_de_Concesionario__c> miembrosDeConcesionario = [
        SELECT Id, Concesionario__c, Nombre_de_asesor__r.Name
        FROM Miembro_de_Concesionario__c
        WHERE Nombre_de_asesor__c = :userId
        /*WITH SECURITY_ENFORCED*/
      ];

      List<Id> concesionarioIds = new List<Id>();
      for (Miembro_de_Concesionario__c mdc : miembrosDeConcesionario) {
        concesionarioIds.add(mdc.Concesionario__c);
      }
      List<Miembro_de_Concesionario__c> miembroConcesionariosAsesores = [
        SELECT
          Id,
          Name,
          Nombre_de_asesor__c,
          Concesionario__c,
          Nombre_de_asesor__r.Name,
          Nombre_de_asesor__r.Oportunidades_Objetivo__c
        FROM Miembro_de_Concesionario__c
        WHERE
          Concesionario__c IN :concesionarioIds
          AND Nombre_de_asesor__c != :userId
          AND Nombre_de_asesor__r.Profile.Name = 'Asesores motos'
      ];

      Map<Id, Miembro_de_Concesionario__c> miembroConcesionariosAsesoresMap = new Map<Id, Miembro_de_Concesionario__c>();
      for (Miembro_de_Concesionario__c mdc : miembroConcesionariosAsesores) {
        miembroConcesionariosAsesoresMap.put(mdc.Nombre_de_asesor__c, mdc);
      }

      List<Opportunity> allOpportunities = [
        SELECT
          Id,
          StageName,
          OwnerId,
          Owner.Name,
          Owner.Oportunidades_Objetivo__c
        FROM Opportunity
        WHERE
          CloseDate = THIS_MONTH
          AND (Owner.Profile.Name LIKE '%asesor%moto%'
          OR Owner.Profile.Name LIKE '%Asesor%moto%'
          OR Owner.Profile.Name LIKE '%líder%moto%'
          OR Owner.Profile.Name LIKE '%Lider%moto%'
          OR Owner.Profile.Name LIKE '%gerente%moto%'
          OR Owner.Profile.Name LIKE '%Gerente%moto%')
        WITH SECURITY_ENFORCED
      ];

      //for (Opportunity op : allOpportunities) {
      //  if (op.StageName == 'Vendida') {
      //    oppCount++;
      //  }
      //}

      Set<Id> asesoresIds = new Set<Id>();

      for (Opportunity opportunity : allOpportunities) {
        if (opportunity.StageName == 'Vendida') {
          oppCount++;
        }
          
        Miembro_de_Concesionario__c mdc = miembroConcesionariosAsesoresMap.get(
          opportunity.OwnerId
        );

        if (mdc != null) {
          if (!asesoresIds.contains(opportunity.OwnerId)) {
            Meta_de_Venta__c forecast = forecasts.get(opportunity.OwnerId);

            Decimal cuota = 0;
            if (forecast != null && forecast.Cuota__c != null) {
              cuota = forecast.Cuota__c;
            }

            oppGoal += cuota;

            asesoresIds.add(opportunity.OwnerId);
          }
        }
      }
    }

    output.add(oppCount);
    if (oppGoal != null && oppGoal > 0) {
      Decimal proporcion = 0.0;
      proporcion = (oppCount / oppGoal) * 100;

      output.add(oppGoal);
      output.add(usuarioEsAsesor);
      output.add(proporcion);
    } else {
      output.add(0);
      output.add(usuarioEsAsesor);
      output.add(0);
    }
  }

  private Map<Id, Meta_de_Venta__c> initForecasts() {
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

    List<Meta_de_Venta__c> lstQuota = [
      SELECT Id, Mes__c, Anio__c, Asesor__c, Cuota__c
      FROM Meta_de_Venta__c
      WHERE Anio__c = :traerAnio AND Mes__c = :traerMes
    ];

    Map<Id, Meta_de_Venta__c> quotaMap = new Map<Id, Meta_de_Venta__c>();
    for (Meta_de_Venta__c meta : lstQuota) {
      quotaMap.put(meta.Asesor__c, meta);
    }
    return quotaMap;
  }
}