public class fan_BillReportController {

  public class Invoice {
    @auraEnabled
    public String billId;
    @auraEnabled
    public String buyingOrderId;
    @auraEnabled
    public String billDate;
    @auraEnabled
    public String expirationDate;
    @auraEnabled
    public String branchStore;
    @auraEnabled
    public String paymentCondition;
    @auraEnabled
    public String orderNumber;
    @auraEnabled
    public String netValue;
    @auraEnabled
    public String valorfactura;
    @auraEnabled
    public String operationCenter;
  }

  @AuraEnabled
  public static Invoice[] getInvoices(
    String idTercero,
    String startDate,
    String endDate
  ) {
    try {
      fan_GettingInvoice.row_element[] invoices = fan_GettingInvoiceHandler.getData(
        idTercero,
        startDate,
        endDate
      );

System.debug('Tercero ' + idTercero);
      Invoice[] invoicesToShow = new List<Invoice>();

      for (fan_GettingInvoice.row_element invoice : invoices) {
        Invoice inv = new Invoice();
        inv.billId = invoice.DOCUMENTO;
        inv.buyingOrderId = invoice.ORD_COMPRA;
        inv.billDate = invoice.FECHA;
        inv.expirationDate = invoice.FECHA_VENCIMIENTO;
        inv.branchStore = invoice.DES_SUC_FANALCA;
        inv.paymentCondition = invoice.DES_COND_PAGO;
        inv.orderNumber = invoice.PEDIDO;
        inv.netValue = invoice.VALOR_NETO;
        inv.valorfactura = invoice.ESTADO_DOCUMENTO;
        inv.operationCenter = invoice.CO;

        InvoicesToShow.add(inv);
      }

      return InvoicesToShow;
    } catch (System.NullPointerException e) {
      return new List<Invoice>();
    } catch (Exception e) {
      throw new AuraHandledException(e.getMessage());
    }
  }
}