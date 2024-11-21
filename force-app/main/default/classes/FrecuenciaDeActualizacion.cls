/**
 * Fanalca
 * @author           Olvin Abarca
 * Description:      Class for checking if account email and account phone are up to date.
 *
 * Changes (Version)
 * -------------------------------------
 *           No.     Date            Author                  Description
 *           -----   ----------      --------------------    ---------------
 * @version  1.0     12/03/2020      Olvin Abarca            Class definition
 * @version  1.1     12/16/2020      Olvin Abarca            Fix issue with SOQL limit exceptions when using data loader to insert opportunities
 * @version 1.2     05/21/2021      Olvin Abarca            Bypass these checks when more than one Account to validate. Also change position isUserFromMotosProfile to save one SQL query
 *********************************************************************************************************/

public with sharing class FrecuenciaDeActualizacion {
  public static Integer isAccountFieldsUpdatedRecently(
    List<Account> accounts,
    List<SObject> sobjects,
    String maxDiasTelefonoCuenta,
    String maxDiasEmailCuenta
  ) {
    Integer result = 0;

    if (accounts.size() > 1) {
      result = 3;
      return result;
    }

    Map<Id, Account> accountMap = accountListToMap(accounts);
    accountMap = accountListToMap(accounts);

    List<AccountHistory> historyList = getAccountHistoryFor(accountMap);

    for (Integer i = 0; i < accounts.size(); i++) {
      Account account = accounts[i];
      SObject obj = sobjects[i];

      AccountHistory accountPhoneHistory = null;
      AccountHistory accountEmailHistory = null;
      for (AccountHistory accountHistory : historyList) {
        if (accountHistory.field == 'PersonMobilePhone') {
          accountPhoneHistory = accountHistory;
        } else if (accountHistory.field == 'PersonEmail') {
          accountEmailHistory = accountHistory;
        }
      }

      accountPhoneHistory = account.PersonMobilePhone != null
        ? null
        : accountPhoneHistory;
      accountEmailHistory = account.PersonEmail != null
        ? null
        : accountPhoneHistory;

      Boolean isIntegrationUser = isUserIntegraciones(UserInfo.getUserId());
      Boolean isMotoUser = isUserFromMotosProfile(UserInfo.getUserId());

      boolean isPhoneUpToDate = checkIfUpdatedRecently(
        account,
        maxDiasTelefonoCuenta,
        accountPhoneHistory,
        'Número del móvil',
        isIntegrationUser,
        isMotoUser
      );

      if (!isPhoneUpToDate) {
        obj.addError(
          'Por favor actualizar telefono móvil de la cuenta relacionada.'
        );

        result = 1;
      }

      boolean isEmailUpToDate = checkIfUpdatedRecently(
        account,
        maxDiasEmailCuenta,
        accountEmailHistory,
        'Correo electrónico',
        isIntegrationUser,
        isMotoUser
      );

      if (!isEmailUpToDate) {
        obj.addError(
          'Por favor actualizar correo electrónico de la cuenta relacionada.'
        );

        result = 2;
      }
    }

    return result;
  }

  private static Map<Id, Account> accountListToMap(List<Account> accounts) {
    Map<Id, Account> accountMap = new Map<Id, Account>();
    accountMap.putAll(accounts);
    return accountMap;
  }

  private static List<AccountHistory> getAccountHistoryFor(
    Map<Id, Account> accountMap
  ) {
    return [
      SELECT
        AccountId,
        CreatedDate,
        Field,
        OldValue,
        NewValue,
        IsDeleted,
        Id,
        CreatedBy.Name
      FROM AccountHistory
      WHERE
        AccountId IN :accountMap.keySet()
        AND Field IN ('PersonMobilePhone', 'PersonEmail')
      ORDER BY CreatedDate DESC
    ];
  }

  public static boolean checkIfUpdatedRecently(
    Account account,
    String maxDiasString,
    AccountHistory accountHistory,
    String fieldName,
    Boolean isIntegrationUser,
    Boolean isMotoUser
  ) {
    if (accountHistory == null || isIntegrationUser || !isMotoUser) {
      // bypass validaciones para usuarios de integraciones o usuarios de autos
      return true;
    } else {
      Date updateDate = accountHistory.CreatedDate != null
        ? accountHistory.CreatedDate.date()
        : System.today();
      Date today = System.today();
      Integer daysBetween = updateDate.daysBetween(today);
      Integer maxDias = Integer.valueof(maxDiasString.trim());

      if (daysBetween >= maxDias) {
        account.addError(
          fieldName +
          ' no ha sido actualizado en ' +
          maxDias +
          ' días.'
        );

        return false;
      }

      return true;
    }
  }

  public static boolean isUserIntegraciones(String userId) {
    return Label.usuariosIntegracionesIds.contains(userId);
  }

  public static boolean isUserFromMotosProfile(String userId) {
    User user = [SELECT Profile.Name FROM User WHERE Id = :userId LIMIT 1];
    return (user.Profile.Name + '').toLowerCase().contains('motos');
  }
}