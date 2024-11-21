public with sharing class fan_AccountStateController {
  public class Summary {
    @AuraEnabled
    public String aux;
    @AuraEnabled
    public String document;
    @AuraEnabled
    public String docuDate;
    @AuraEnabled
    public String expirationDate;
    @AuraEnabled
    public String docuExpired;
    @AuraEnabled
    public String code;
    @AuraEnabled
    public String description;
    @AuraEnabled
    public String current;
    @AuraEnabled
    public String expiryAmountShort;
    @AuraEnabled
    public String expiryAmountMedium;
    @AuraEnabled
    public String expiryAmountLong;
    @AuraEnabled
    public String expiryAmountMax;
    @AuraEnabled
    public String total;
  }

  @AuraEnabled
  public static Summary[] getAccountState(String accountId) {
    try {
      String idTercero = fan_B2BUtils.resolveAccountNumber(accountId);
      fan_AccountState.row_element[] data = fan_AccountStateHandler.getData(
        idTercero
      );

      Summary[] summaries = new List<Summary>();
      Summary summary;
      String[] expDate;

      for (fan_AccountState.row_element summa : data) {
        summary = new summary();
        summary.aux = summa.AUXILIAR;       
        summary.document = summa.DOCUMENTO;
        summary.docuDate = summa.FECHA;
        summary.expirationDate = summa.FECHAVCTO;
        if (summary.expirationDate.contains('T')) {
          expDate = summary.expirationDate.split('T');
          summary.expirationDate = expDate[0];
        } else {
          summary.expirationDate = summa.FECHAVCTO;
        }
        summary.docuExpired = summa.VENC;
        summary.code = summa.CODIGO;
        summary.description = summa.DESCRIPCION;
        summary.current = summa.CORRIENTE != null ? summa.CORRIENTE : '0';
        summary.expiryAmountShort = summa.VENCIDO1A30 != null ? summa.VENCIDO1A30.trim() : '0';
        summary.expiryAmountMedium = summa.VENCIDO31A60 != null ? summa.VENCIDO31A60.trim() : '0';
        summary.expiryAmountLong = summa.VENCIDO61A90 != null ? summa.VENCIDO61A90.trim() : '0';
        summary.expiryAmountMax = summa.VENCIDO91MAS != null ? summa.VENCIDO91MAS.trim() : '0';
        summary.total = summa.TOTAL;
        summaries.add(summary);
      }

      return summaries;
    } catch (System.NullPointerException e) {
      return new List<summary>();
    } catch (Exception e) {
      throw new AuraHandledException(e.getMessage());
    }
  }
}