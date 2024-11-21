/**
 * Fanalca
 * @author           Olvin Abarca
 * Description:      Clase para enviar los datos a los reportes personalizados de Oportunidades
 *
 * Changes (Version)
 * -------------------------------------
 *           No.     Date            Author                  Description
 *           -----   ----------      --------------------    ---------------
 * @version  1.0     22/01/2021      Olvin Abarca            Refactor improvements
 * @version  1.1     01/03/2021      Olvin Abarca            Only count opp created by asesores
 * @version  1.2     31/03/2021      JP            			 Change method getOppListAsCSV to query inside the method to avoid apex heap size error
 * @version  1.3     04/05/2021      Olvin Abarca            Refactor to count holidays from day one until current day of month
 *********************************************************************************************************/
public with sharing class DatosReporteOportunidadesVentas {
  public List<Decimal> ventasOportunidades { get; set; }
  public String metaReporteOppProducto { get; set; }
  public String metaReporteOpp { get; set; }
  public String oppIds { get; set; }

  public DatosReporteOportunidadesVentas() {
    Date today = system.today();
    Integer numberOfDays = Date.daysInMonth(today.year(), today.month());
    Date lastDayOfMonth = Date.newInstance(
      today.year(),
      today.month(),
      numberOfDays
    );
    Date firstDayOfMonth = Date.newInstance(today.year(), today.month(), 1);

    Integer domingos = countNonLaborDays(
      firstDayOfMonth,
      lastDayOfMonth,
      today
    );

    Integer holidays = countHolidays(firstDayOfMonth, today);

    User user = [
      SELECT Id, Name, Profile.Name
      FROM User
      WHERE Id = :UserInfo.getUserId()
      LIMIT 1
    ];

    ventasOportunidades = getDatosVentasOportunidades(
      user,
      holidays,
      domingos,
      today
    );

    Decimal oppCount = ventasOportunidades[0];
    Decimal oppGoal = ventasOportunidades[1];
    Decimal usuarioEsAsesor = ventasOportunidades[2];

    if (oppGoal != 0 && ventasOportunidades[1] != null) {
      Decimal proporcion = (oppCount / oppGoal) * 100;
      ventasOportunidades.add(proporcion);
    } else {
      ventasOportunidades.add(0);
    }

    oppIds = getOppListAsCSV(null);

    List<String> reportsDeveloperName = new List<String>{
      Label.ReporteMetaOpportunidadesProductos, //'Meta_oportunidades_productos'
      Label.ReporteMetaOpportunidades
    };

    List<Report> reports = [
      SELECT Id, DeveloperName
      FROM Report
      WHERE DeveloperName IN :reportsDeveloperName
    ];

    for (Report report : reports) {
      if (Label.ReporteMetaOpportunidades == report.DeveloperName) {
        metaReporteOpp = report.Id;
      } else if (
        Label.ReporteMetaOpportunidadesProductos == report.DeveloperName
      ) {
        metaReporteOppProducto = report.Id;
      }
    }
  }

  public static Integer countHolidays(
    Date firstDayOfMonth,
    Date lastDayOfMonth
  ) {
    // must count all holidays from beginning of month until today
    List<Holiday> lstFeriados = [
      SELECT Id, ActivityDate
      FROM Holiday
      WHERE ActivityDate >= :firstDayOfMonth AND ActivityDate <= :lastDayOfMonth
    ];

    return lstFeriados.size();
  }

  public static Integer countNonLaborDays(
    Date firstDayOfMonth,
    Date lastDayOfMonth,
    Date today
  ) {
    Integer domingos = 0;
    Datetime dt = DateTime.newInstance(
      firstDayOfMonth,
      Time.newInstance(0, 0, 0, 0)
    );
    for (Integer i = 1; i <= today.day(); i++) {
      String dayOfWeek = dt.format('EEEE');
      if (dayOfWeek == 'Sunday') {
        domingos++;
      }
      dt = dt.addDays(1);
    }

    return domingos;
  }

  public static List<Decimal> getDatosVentasOportunidades(
    User user,
    Integer feriados,
    Integer domingos,
    Date today
  ) {
    Decimal oppCount = 0;
    Decimal oppGoal = 0;
    Decimal usuarioEsAsesor = 0;

    Id userId = user.Id;

    List<Miembro_de_Concesionario__c> miembrosDeConcesionario = [
      SELECT Id, Concesionario__c, Nombre_de_asesor__r.Name
      FROM Miembro_de_Concesionario__c
      WHERE Nombre_de_asesor__c = :userId
      /*WITH SECURITY_ENFORCED*/
    ];

    if (
      user.Profile.Name != null && user.Profile.Name.contains('Asesores motos')
    ) {
      usuarioEsAsesor = 1;

      if (miembrosDeConcesionario.size() > 0) {
        List<Opportunity> opportunities = [
          SELECT Name, StageName, CloseDate, Amount, Owner.Name, Owner.Username
          FROM Opportunity
          WHERE
            CreatedDate = THIS_MONTH
            AND OwnerId = :userId
            AND SyncedQuoteId != NULL
        ];

        Concesionario__c concesionario = [
          SELECT Id, Cuota_por_Asesor__c
          FROM Concesionario__c
          WHERE Id = :miembrosDeConcesionario[0].Concesionario__c
          LIMIT 1
        ];

        oppCount = opportunities.size();

        oppGoal =
          (today.day() - (domingos + feriados)) *
          concesionario.Cuota_por_Asesor__c;

        System.debug(
          'Asesor Name: ' +
          miembrosDeConcesionario[0].Nombre_de_asesor__r.Name +
          ' today.day(): ' +
          today.day() +
          ' domingos: ' +
          domingos +
          ' feriados: ' +
          feriados +
          ' oppGoal: ' +
          oppGoal
        );
      }
    } else {
      // usuario no es asesor

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

      // oportunidades del gerente/lider
      //List<Opportunity> opportunities = getOpportunitiesAsGerente();

      //oppCount = opportunities.size();
      oppCount = database.countQuery(
        'SELECT count()  FROM Opportunity ' +
        'WHERE CreatedDate = THIS_MONTH ' +
        'AND (Owner.Profile.Name LIKE \'%asesor%moto%\' ' +
        'OR Owner.Profile.Name LIKE \'%Asesor%moto%\') ' +
        ' AND SyncedQuoteId != NULL'
      );

      Set<Id> asesoresIds = new Set<Id>();

      for (
        Miembro_de_Concesionario__c miembroConcesionario : miembroConcesionariosAsesores
      ) {
        if (!asesoresIds.contains(miembroConcesionario.Nombre_de_asesor__c)) {
          if (
            miembroConcesionario.Nombre_de_asesor__r.Oportunidades_Objetivo__c !=
            null
          ) {
            oppGoal += miembroConcesionario.Nombre_de_asesor__r.Oportunidades_Objetivo__c;

            System.debug(
              'JefeAsesor Name: ' +
              miembroConcesionario.Nombre_de_asesor__r.Name +
              ' oppGoal: ' +
              miembroConcesionario.Nombre_de_asesor__r.Oportunidades_Objetivo__c
            );
          }

          asesoresIds.add(miembroConcesionario.Nombre_de_asesor__c);
        }
      }

      System.debug(
        'Miembros de Concesionarios regitrados: ' +
        miembrosDeConcesionario.size()
      );
      System.debug('Concesionarios regitrados: ' + concesionarioIds.size());
      System.debug(
        'Asesores subordinados: ' + miembroConcesionariosAsesores.size()
      );
    }

    return new List<Decimal>{ oppCount, oppGoal, usuarioEsAsesor };
  }
  /*
  private static List<Opportunity> getOpportunitiesAsGerente() {
    List<Opportunity> opportunities = [
      SELECT Id, Name, Account.Name, Owner.Name
      FROM Opportunity
      WHERE
        CreatedDate = THIS_MONTH
        AND (Owner.Profile.Name LIKE '%asesor%moto%'
        OR Owner.Profile.Name LIKE '%Asesor%moto%')
        AND SyncedQuoteId != NULL
      //WITH SECURITY_ENFORCED
    ];

    return opportunities;
  }
*/
  public static String getOppListAsCSV(List<Opportunity> opportunities) {
    String oppIds = '';
    if (opportunities == null) {
      for (
        Opportunity opp : [
          SELECT Id //, Name, Account.Name, Owner.Name
          FROM Opportunity
          WHERE
            CreatedDate = THIS_MONTH
            AND (Owner.Profile.Name LIKE '%asesor%moto%'
            OR Owner.Profile.Name LIKE '%Asesor%moto%')
            AND SyncedQuoteId != NULL
        ]
      ) {
        oppIds += '\'' + opp.Id + '\',';
      }
    } else {
      for (Opportunity opp : opportunities) {
        oppIds += '\'' + opp.Id + '\',';
      }
    }

    /* 
    if (opportunities == null) {
      opportunities = getOpportunitiesAsGerente();
    }

    String oppIds = '';
    for (Opportunity opp : opportunities) {
      oppIds += '\'' + opp.Id + '\',';
    }
    */

    return oppIds;
  }
}