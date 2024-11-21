public with sharing class fan_InsertCorePedido {

    @TestVisible
    static FulFillmentOrder[] testFulFillmentOrders;
    
    @InvocableMethod(
        label = 'Insertar Pedidos en Core de Negocio'
        description = ''
        callout = true
        Category = 'B2B Commerce'
    )
    public static void validateCreditLine(List<String> fulfillmentOrderIdList) {

        final Integer bodyJsonLength = SObjectType.OrderSummary.fields.fan_Body_Json__c.length;
        Product2 shippingProduct = [SELECT IdProductoUNOEE__c, fan_aplicaIVA__c, fan_aplicaIVAC__c, fan_Classification__c FROM Product2 WHERE ProductCode = :fan_InfoFletes__mdt.getInstance('producto').Label WITH SECURITY_ENFORCED];
        Map<String, fan_IdTienda__mdt> idTiendaMdt = fan_IdTienda__mdt.getAll();
        Map<String,fan_Impuesto__mdt> taxesTypes = fan_Impuesto__mdt.getAll();
        Map<String,fan_OrderSegmentation__mdt> orderSegmentation = fan_OrderSegmentation__mdt.getAll();
        Map<String, OrderSummary> orderSummaries = new Map<String, OrderSummary>();

        for(FulFillmentOrder fulFillmentOrder : Test.isRunningTest() ? testFulFillmentOrders :
                                                [SELECT OrderSummary.AccountId, OrderSummary.SalesStoreId, OrderSummary.OrderNumber, OrderSummary.fan_TipoPedido__c,
                                                        OrderSummary.fan_OrderFormaPago__c, OrderSummary.OriginalOrder.fan_EsAnticipo__c, 
                                                        Account.AccountNumber, Account.Parent.AccountNumber, FulfillmentOrderNumber, Account.ParentId,
                                                        Account.fan_aplicaIVA__c, Account.fan_aplicaIVAC__c, FulFilledFromLocation.ExternalReference,
                                                    (SELECT UnitPrice, TotalPrice, TotalAdjustmentAmount, Quantity, CreatedDate, Product2.IdProductoUNOEE__c,
                                                        Product2.fan_aplicaIVA__c, Product2.fan_aplicaIVAC__c, Product2.fan_Classification__c, OrderItemSummary.fan_FormattedPaymentCondition__c,
                                                        OrderItemSummary.fan_OrderSegmentationGroup__c, OrderItemSummary.OrderDeliveryGroupSummary.OriginalOrderDeliveryGroup.fan_Code__c
                                                    FROM FulFillmentOrderLineItems WHERE OrderItemSummary.TypeCode = :fan_Constants.OrderItemSummaryTypeCode.PRODUCT.name())
                                                FROM FulFillmentOrder WHERE Id IN :fulfillmentOrderIdList]){

            Set<String> productIds = new Set<String>();
            fan_ShippingCalculator.Product[] products = new List<fan_ShippingCalculator.Product>();

            OrderSummary os = fulFillmentOrder.OrderSummary;
            FulfillmentOrderLineItem[] lstOrder = fulFillmentOrder.FulFillmentOrderLineItems;
            Request req = new Request();
            List<cls_Lines> lstLines = new List<cls_Lines>();

            FulfillmentOrderLineItem fulfillmentOrderLineItem = lstOrder[0];

            String accountNumber = String.isNotBlank(fulfillmentOrder.Account.ParentId) ? fulfillmentOrder.Account.Parent.AccountNumber : fulfillmentOrder.Account.AccountNumber;
            String pricebook = fulfillmentOrder.OrderSummary.fan_TipoPedido__c.split('_')[0];
            String co = getCO(idTiendaMdt, fulFillmentOrder.OrderSummary.SalesStoreId, lstOrder);
            String[] deliveryTo = getCode(fulfillmentOrderLineItem.OrderItemSummary.OrderDeliveryGroupSummary.OriginalOrderDeliveryGroup.fan_Code__c, accountNumber);
            String orderSegmentationGroup = fulfillmentOrderLineItem.OrderItemSummary.fan_OrderSegmentationGroup__c;
            String paymentCondition = fulfillmentOrderLineItem.OrderItemSummary.fan_FormattedPaymentCondition__c;

            for(FulfillmentOrderLineItem forder : lstOrder){
                Decimal discount = forder.TotalAdjustmentAmount / forder.Quantity;
                lstLines.add(buildLine(accountNumber, co, pricebook, deliveryTo, orderSegmentationGroup, paymentCondition, discount, fulFillmentOrder, forder.Product2, forder.CreatedDate, forder.Quantity, forder.UnitPrice, taxesTypes, orderSegmentation));
                productIds.add(forder.Product2Id);
                products.add(new fan_ShippingCalculator.Product(forder));
            }

            Decimal shippingCost = getShippingCost(os, productIds, products);
            if(shippingCost > 0) {
                lstLines.add(buildLine(accountNumber, co, pricebook, deliveryTo, orderSegmentationGroup, paymentCondition, 0, fulFillmentOrder, shippingProduct, fulfillmentOrderLineItem.CreatedDate, 1, shippingCost, taxesTypes, orderSegmentation));
            }
            req.Lines = lstLines;

            String requestBody = JSON.serialize(req);
            System.debug('Request Body: ' + requestBody);
            
            HttpRequest httpRequest = new HttpRequest();  
            httpRequest.setMethod('POST');
            httpRequest.setHeader('Content-Type', 'application/json');
            httpRequest.setEndpoint('callout:Fanalca/RESTAdapter/WMS/DynamicInsert');
            httpRequest.setBody(requestBody);
            
            new Http().send(httpRequest);

            os.fan_Body_Json__c = requestBody.left(bodyJsonLength);
            orderSummaries.put(os.Id, os);
        }

        if(!Test.isRunningTest()) UPDATE orderSummaries.values();
    }

    static Decimal getShippingCost(OrderSummary orderSummary, Set<String> productIds, fan_ShippingCalculator.Product[] products) {

        fan_ShippingCalculator shippingCalculator;

        if(orderSummary.SalesStoreId == fan_IdTienda__mdt.getInstance(fan_Constants.StoreDeveloperName.POSVENTA.name().toLowerCase()).fan_IdTienda__c) {
            shippingCalculator = new fan_PosventaShippingCalculator();
        } else if(orderSummary.SalesStoreId == fan_IdTienda__mdt.getInstance(fan_Constants.StoreDeveloperName.MOTOS.name().toLowerCase()).fan_IdTienda__c) {
            shippingCalculator = new fan_MotosShippingCalculator();
        }

        if(shippingCalculator == null) {
            return null;
        }
        Map<String, Decimal> shippingCosts = shippingCalculator.calculateShipping(orderSummary.AccountId, orderSummary.SalesStoreId, productIds, products);

        return shippingCosts.isEmpty() ? 0 : shippingCosts.values()[0];
    }

    public static String getCO(Map<String, fan_IdTienda__mdt> idTiendaMdt, String webStoreId, FulfillmentOrderLineItem[] fulfillmentOrderLineItems) {
        String co;

        for(FulfillmentOrderLineItem fulfillmentOrderLineItem : fulfillmentOrderLineItems) {
            if(idTiendaMdt.get(fan_Constants.StoreDeveloperName.POSVENTA.name().toLowerCase()).fan_IdTienda__c == webStoreId) {
                co = fan_Constants.OperationCenter.HRC.name();
            } else if(idTiendaMdt.get(fan_Constants.StoreDeveloperName.MOTOS.name().toLowerCase()).fan_IdTienda__c == webStoreId) {
                if(fulfillmentOrderLineItem.Product2.fan_Classification__c == fan_Constants.MotorcycleClassifaction.CKD.name()) {
                    co = fan_Constants.OperationCenter.HMC.name();
                } else if(fulfillmentOrderLineItem.Product2.fan_Classification__c == fan_Constants.MotorcycleClassifaction.CBU.name()) {
                    co = fan_Constants.OperationCenter.HOC.name();
                }
            }

            if(co != null) {
                break;
            }
        }
        return co;
    }

    static String getPaymentCondition(OrderSummary orderSummary, String paymentCondition){
        return orderSummary.fan_OrderFormaPago__c == fan_Constants.FormaPago.CREDITO.name()
            ? paymentCondition
            : 'CON';
    }

    private static String[] getCode(String code, String accNumber){
        System.debug('>>>>>>>>>>>> ' + code);

        String[] result = new String[] {};
        code = code.replace('PS-', '');
        code = code.replace('PB-', '');//Added to delete this prefix (PB)
        code = code.replace('B-', '');
        code = code.replace('S-', '');
        code = code.replace(accNumber, '');
        System.debug('>>>>>>>>>>>> ' + accNumber);
        System.debug('>>>>>>>>>>>>code.length() ' + code.length());
        if(code.length() == 3 && code.length() > 0){
            result.add(code); //PUNTO_ENVIO
            result.add('001'); //DESPACHAR_A
        } else if(code.length() == 6 && code.length() > 0) {
            result.add(code.substring(3, 6)); //PUNTO_ENVIO
            result.add(code.substring(0, 3)); //DESPACHAR_A
        }
        System.debug('>>>>>>>>>>>> ' + result);
        return result;
    }
    
    private static String getCargue(OrderSummary orderSummary, String orderSegmentationGroup, Map<String,fan_OrderSegmentation__mdt> orderSegmentation){
        String result = 'NORMAL';

        if(orderSummary.fan_TipoPedido__c.split('_').get(1) == result){
            for(String key : orderSegmentation.keySet()){
                
                if(orderSegmentation.get(key).fan_PlanPRM__c == orderSegmentationGroup){
                    result = orderSegmentation.get(key).fan_Cargue__c;
                }
            }
        } else {
            result = orderSummary.fan_TipoPedido__c.split('_').get(1).toUpperCase();
        }

        return result;
    }

    private static String getIva(Product2 product, Account account, Map<String, fan_Impuesto__mdt> taxType){
        Decimal ivaValue = 0;

        ivaValue += account.fan_aplicaIVA__c == true && product.fan_aplicaIVA__c == true ? taxType.get('Impuesto_IVA').fan_Valor__c : 0;

        return String.valueOf(ivaValue);
    }

    private static String getIvaC(Product2 product, Account account, Map<String, fan_Impuesto__mdt> taxType){
        Decimal ivacValue = 0;

        ivacValue += account.fan_aplicaIVAC__c == true && product.fan_aplicaIVAC__c == true ? taxType.get('Impuesto_IVAC').fan_Valor__c : 0;


        return String.valueOf(ivacValue);
    }

    public static cls_Fields buildField(String name, String value){
        cls_Fields field = new cls_Fields();
        
        field.Name = name;
        field.Value = value;
        
        return field;
    }

    static cls_Lines buildLine(String accountNumber, String co, String pricebook, String[] deliveryTo, String orderSegmentationGroup, String paymentCondition, Decimal discount,
                                FulFillmentOrder fulFillmentOrder, Product2 product, Datetime createdDate, Decimal quantity, Decimal unitPrice, Map<String, fan_Impuesto__mdt> taxesTypes,
                            Map<String, fan_OrderSegmentation__mdt> orderSegmentation) {

        cls_Lines line = new cls_Lines();
        //Validate if a Order was pay with Anticipo
        String newNUMERO_OC_OS =  fulFillmentOrder.OrderSummary.OriginalOrder.fan_EsAnticipo__c == true ? fulFillmentOrder.OrderSummary.OrderNumber + ' PAGO CON ANTICIPO' : fulFillmentOrder.OrderSummary.OrderNumber;
        line.Fields = new cls_Fields[] {
            buildField('CO', co),
            buildField('FACTURAR_A', accountNumber),
            buildField('DESPACHAR_A', deliveryTo[1]), // validar
            buildField('CONDICION_PAGO', getPaymentCondition(fulFillmentOrder.OrderSummary, paymentCondition)),
            buildField('ENTREGA_DIAS', '0'),
            buildField('NUMERO_OC', fulFillmentOrder.FulfillmentOrderNumber),
            buildField('NUMERO_OC_OS', newNUMERO_OC_OS),
            buildField('CARGUE', getCargue(fulFillmentOrder.OrderSummary, orderSegmentationGroup, orderSegmentation)),
            buildField('PUNTO_ENVIO', deliveryTo[0]), // validar
            buildField('ITEM', product.IdProductoUNOEE__c),
            buildField('BODEGA', fulfillmentOrder.FulfilledFromLocation.ExternalReference),
            buildField('BACKORDER', '0'),
            buildField('CANTIDAD', String.valueOf(quantity)),
            buildField('FECHA_PEDIDO', createdDate.format('dd/MM/yyy')),
            buildField('LISTA_PRECIOS', pricebook),
            buildField('PRECIO', String.valueOf(unitPrice)),
            buildField('DESCUENTO_VLR', String.valueOf(Math.abs(discount))),
            buildField('IVA', getIva(product, fulfillmentOrder.Account, taxesTypes)),
            buildField('IVAC', getIvaC(product, fulfillmentOrder.Account, taxesTypes))
        };
        return line;
    }
    
    class Request {
        public String TableName;	//INTG_WMS.B2B_PEDIDO
        public cls_Lines[] Lines;
        public Request(){
            TableName = 'INTG_WMS.B2B_PEDIDO';
            Lines = new List<cls_Lines>();
        }
    }
    
    class cls_Lines {
        public cls_Fields[] Fields;
        public cls_Lines(){
            Fields = new List<cls_Fields>();
        }
    }
    
    class cls_Fields {
        public String Name;	//CO
        public String Value;	//HMC
        public cls_Fields(){
            Name = '';
            Value = '';
        }
    }
    
}