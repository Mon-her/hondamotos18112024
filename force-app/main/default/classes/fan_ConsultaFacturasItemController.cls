public class fan_ConsultaFacturasItemController {

    @TestVisible
    class InvoiceItem {
        @AuraEnabled
        public String document;
        @AuraEnabled
        public String reference;
        @AuraEnabled
        public String referenceDescription;
        @AuraEnabled
        public String issueDate;
        @AuraEnabled
        public String chassis;
        @AuraEnabled
        public String engine;
        @AuraEnabled
        public String color;
        @AuraEnabled
        public String model;
        @AuraEnabled
        public Decimal quantity;
        @AuraEnabled
        public Decimal unitPrice;
        @AuraEnabled
        public Decimal discountRate;
        @AuraEnabled
        public Decimal subtotal;
        @AuraEnabled
        public Decimal feeRate;
        @AuraEnabled
        public Decimal feeValue;
        @AuraEnabled
        public Decimal netValue;
    }

    @AuraEnabled
    public static List<InvoiceItem> getInvoiceItems(String factura) {
        try {
            List<InvoiceItem> items = new List<InvoiceItem>();

            for (fan_ConsultaFacturasItem.row_element row : fan_ConsultaFacturasItemHandler.getData(factura)) {
                InvoiceItem item = new InvoiceItem();
                item.document = row.DOCUMENTO;
                item.reference = row.REFERENCIA;
                item.referenceDescription = row.DES_REFERENCIA;
                item.issueDate = row.FECHA;
                item.chassis = row.CHASIS;
                item.engine = row.MOTOR;
                item.color = row.COLOR;
                item.model = row.MODELO;
                item.quantity = Decimal.valueOf(row.CANTIDAD);
                item.unitPrice = Decimal.valueOf(row.PR_UNITARIO);
                item.discountRate = Decimal.valueOf(row.POR_DESCUENTO);
                item.subtotal = Decimal.valueOf(row.VALOR_SUBTOTAL);
                item.feeRate = Decimal.valueOf(row.POR_IMPUESTOS);
                item.feeValue = Decimal.valueOf(row.VALOR_IMPUESTOS);
                item.netValue = Decimal.valueOf(row.VALOR_NETO);
                items.add(item);
            }
            return items;
        } catch (NullPointerException e) {
            return new List<InvoiceItem>();
        } catch(Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }
}