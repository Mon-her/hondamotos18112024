public with sharing class CuentaTriggerHandler {
  public static Boolean unaVez = true;

  public void onBeforeUpdate(
    List<Account> listNewAccount,
    List<Account> listViejoAccount
  ) {
    FrecuenciaDeActualizacion.isAccountFieldsUpdatedRecently(
      listNewAccount,
      listNewAccount,
      Label.maxDiasTelefonoCuenta,
      Label.maxDiasEmailCuenta
    );

    //CuentaService.verificarCuentasRelacionadas(
    //  listNewAccount,
    //  listViejoAccount
    //); Commented on January 28th, '21

    CuentaTriggerHandler.unaVez = true;
  }
}