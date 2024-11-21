/**
 * Fanalca
 * @author           Olvin Abarca
 * Description:      Batch class that updates Oportunidades_Objetivo__c for every user.
 *
 * Changes (Version)
 * -------------------------------------
 *           No.     Date            Author                  Description
 *           -----   ----------      --------------------    ---------------
 * @version  1.0     12/15/2021      Olvin Abarca            Class definition.
 * @version  1.1     04/05/2021      Olvin Abarca            Refactor to count holidays from day one until current day of month
 *********************************************************************************************************/
public with sharing class UserOppGoalsBatchable implements Database.Batchable<sObject> {
  public UserOppGoalsBatchable() {
  }

  public Database.QueryLocator start(Database.BatchableContext bc) {
    String limitString = '';
    if (Test.isRunningTest()) {
      limitString = 'LIMIT 20';
    }
    String query =
      'SELECT Id, Name, Profile.Name FROM User WHERE IsActive = true ' +
      limitString;
    return Database.getQueryLocator(query);
  }

  public void execute(Database.BatchableContext BC, List<User> users) {
    Date today = system.today();
    Integer numberOfDays = Date.daysInMonth(today.year(), today.month());
    Date lastDayOfMonth = Date.newInstance(
      today.year(),
      today.month(),
      numberOfDays
    );
    Date firstDayOfMonth = Date.newInstance(today.year(), today.month(), 1);

    Integer domingos = DatosReporteOportunidadesVentas.countNonLaborDays(
      firstDayOfMonth,
      lastDayOfMonth,
      today
    );

    Integer holidays = DatosReporteOportunidadesVentas.countHolidays(
      firstDayOfMonth,
      today
    );

    List<Id> userIds = userListToIdList(users);
    List<Meta_de_venta__c> lstForecast = getForecasts(userIds);

    for (User user : users) {
      List<Decimal> results = DatosReporteOportunidadesVentas.getDatosVentasOportunidades(
        user,
        holidays,
        domingos,
        today
      );

      System.debug('user: ' + user.Name + ' results[2]: ' + results[2]);

      if (results[2] == 1) {
        // usuario es asesor

        user.Oportunidades_Objetivo__c = results[1];

        Decimal cuota = getForecastFor(user.Id, lstForecast);
        user.Cuota__c = Integer.valueOf(cuota);

        update user;
      }
    }
  }

  private List<Id> userListToIdList(List<User> users) {
    List<Id> ids = new List<Id>();
    for (User user : users) {
      ids.add(user.Id);
    }
    return ids;
  }

  private List<Meta_de_venta__c> getForecasts(List<Id> userIds) {
    String hoy = String.valueOf(date.today());
    String traerAnio = hoy.left(4);
    String traerMes = '';

    String monthIndex = hoy.left(7).right(2);
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

    traerMes = meses.get(monthIndex);

    List<Meta_de_Venta__c> lstForecast = [
      SELECT Id, Mes__c, Anio__c, Asesor__c, Cuota__c
      FROM Meta_de_Venta__c
      WHERE Asesor__c = :userIds AND Anio__c = :traerAnio AND Mes__c = :traerMes
    ];
    return lstForecast;
  }

  private Decimal getForecastFor(
    Id userId,
    List<Meta_de_Venta__c> lstForecast
  ) {
    for (Meta_de_Venta__c meta : lstForecast) {
      if (meta.Asesor__c == userId) {
        return meta.Cuota__c;
      }
    }
    return 0;
  }

  public void finish(Database.BatchableContext BC) {
  }
}