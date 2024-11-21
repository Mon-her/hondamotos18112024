public with sharing class fan_ConsultaExtractosController {

    @AuraEnabled
    public static List<Movement> getMovements(String nitCliente, String startDate, String endDate){
        try {
            List<Movement> movements = new List<Movement>();

            for (fan_ConsultaExtractos.row_element row : fan_ConsultaExtractosHandler.getData(nitCliente, startDate, endDate)) {
                Movement movement = new Movement();
                movement.nit = row.NIT;
                movement.businessName = row.RAZON_SOCIAL;
                movement.document = row.DOCUMENTO;
                movement.documentDate = row.FECHA;
                movement.crossingDocument = row.DOCTO_CRUCE;
                movement.expirationDate = row.VCTO;
                movement.documentValue = Decimal.valueOf(row.VALOR_DOCUMENTO);
                movement.initialBalance = Decimal.valueOf(row.SALDO_INICIAL);
                movement.appliedValue = Decimal.valueOf(row.VALOR_APLICADO);
                movement.endingBalance = Decimal.valueOf(row.SALDO);
                movement.subsidiary= row.AUXILIAR;
                movements.add(movement);
            }
            return movements;
        } catch (NullPointerException e) {
            return new List<Movement>();
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }

    @AuraEnabled(cacheable = true)
    public static Map<String, Object> getAccountInformation(String id){
        try {
            Account account = getAccount(id);

            return new Map<String, Object> {
                'nit' => account.AccountNumber,
                'name' => account.Name,
                'billingCity' => account.BillingCity,
                'billingCountry' => account.BillingCountry,
                'billingState' => account.BillingState,
                'billingStreet' => account.BillingStreet,
                'corporation' => getCorporation()
            };
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }

    @TestVisible
    static Map<String, String> getCorporation() {
        Fan_CorporationInformation__c corporationInformation = fan_CorporationInformation__c.getOrgDefaults();

        return new Map<String, String> {
            'name' => corporationInformation.fan_Name__c,
            'phone' => corporationInformation.fan_Phone__c,
            'currency' => corporationInformation.fan_Currency__c,
            'address' => corporationInformation.fan_Address__c
        };
    }

    @TestVisible
    static Account getAccount(String id) {
        Account account = [SELECT AccountNumber, Name, BillingCity, BillingCountry, BillingState, BillingStreet,
                            Parent.AccountNumber, Parent.Name, Parent.BillingCity, Parent.BillingCountry, Parent.BillingState, Parent.BillingStreet
                            FROM Account WHERE Id =: id];

        return account.ParentId == null ? account : account.Parent;
    }

    @TestVisible
    class Movement {
        @AuraEnabled
        public String nit;
        @AuraEnabled
        public String businessName;
        @AuraEnabled
        public String documentDate;
        @AuraEnabled
        public String document;
        @AuraEnabled
        public String crossingDocument;
        @AuraEnabled
        public String expirationDate;
        @AuraEnabled
        public Decimal documentValue;
        @AuraEnabled
        public Decimal initialBalance;
        @AuraEnabled
        public Decimal appliedValue;
        @AuraEnabled
        public Decimal endingBalance;
        @AuraEnabled
        public String subsidiary;
    }
}