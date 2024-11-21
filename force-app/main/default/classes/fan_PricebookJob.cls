global class fan_PricebookJob implements Database.Batchable<fan_Pricebook.row_element>, Database.Stateful, Database.AllowsCallouts {

    static final String DISCOUNT_PRICE_BOOK_SUFFIX = ' DISTRIBUIDOR';
    static final String FIRST_PAGE_NUMBER = '1';
    static final String[] PRICEBOOK_NAMES = new String[] { 'RMT', 'REM', 'EMM', 'COU', 'AIR' };

    String pageNumber;
    Integer pricebookIndex;
    final Integer batchSize;

    Map<String, Id> productIdByIdProductUnoee = new Map<String, Id>();
    Map<String, Id> pricebookIdByName = new Map<String, Id>();

    global fan_PricebookJob(Integer batchSize) {
        this(batchSize, 0, FIRST_PAGE_NUMBER);
    }
    
    fan_PricebookJob(Integer batchSize, Integer pricebookIndex, String pageNumber) {
        this.batchSize = batchSize;
        this.pricebookIndex = pricebookIndex;
        this.pageNumber = pageNumber;
    }

    global Iterable<fan_Pricebook.row_element> start(Database.BatchableContext bc) {

        String pricebookName = PRICEBOOK_NAMES[pricebookIndex];
        fan_Pricebook.row_element[] rowElements = fan_PricebookHandler.getPricebookEntries(pricebookName, pageNumber);

        if(rowElements == null) {
            rowElements = new List<fan_Pricebook.row_element>();
        }
        
        if(rowElements.isEmpty()) {
            // Skip to next price book.
            pageNumber = null;
        } else {
            pageNumber = rowElements[rowElements.size() - 1].DESC_DETALLE_EXT_1;

            productIdByIdProductUnoee = getProductIdByIdProductUnoee(rowElements);
            pricebookIdByName = getPricebookIdByName(pricebookName);
        }
        return rowElements;
    }

    global void execute(Database.BatchableContext BC, fan_Pricebook.row_element[] rowElements) {

        PricebookEntry[] pricebookEntries = new List<PricebookEntry>();

        for(fan_Pricebook.row_element rowElement : rowElements){

            String pricebookName = rowElement.LISTA;
            String pricebookId = pricebookIdByName.get(pricebookName);
            String productId = productIdByIdProductUnoee.get(rowElement.ITEM);
            String externalId = buildPricebookEntryExternalId(pricebookName, rowElement.ITEM);

            if(String.isEmpty(pricebookId) || String.isEmpty(productId)) {
                continue;
            }
            Decimal price = Decimal.valueOf(rowElement.PRECIO);
            // List price book.
            pricebookEntries.add(buildPricebookEntry(externalId, price, pricebookId, productId));

            // Discount price book.
            pricebookName += DISCOUNT_PRICE_BOOK_SUFFIX;
            pricebookId = pricebookIdByName.get(pricebookName);
            if(String.isNotEmpty(pricebookId)) {
                externalId = buildPricebookEntryExternalId(pricebookName, rowElement.ITEM);
                Decimal discountRate = Decimal.valueOf(rowElement.PORCENTAJE);
                Decimal discountPrice = price * (1 - discountRate); 

                pricebookEntries.add(buildPricebookEntry(externalId, discountPrice, pricebookId, productId));
            }
        }
        UPSERT pricebookEntries fan_ExternalId__c;
    }

    global void finish( Database.BatchableContext BC ) {

        fan_PricebookJob pricebookJob;

        if(String.isNotEmpty(pageNumber)) {
            // Skip to next page.
            pricebookJob = new fan_PricebookJob(batchSize, pricebookIndex, pageNumber);
        } else if(++pricebookIndex < PRICEBOOK_NAMES.size()) {
            // Skip to next price book.
            pricebookJob = new fan_PricebookJob(batchSize, pricebookIndex, FIRST_PAGE_NUMBER);
        }

        if(pricebookJob != null) {
            Database.executeBatch(pricebookJob, batchSize);
        }
    }

    Map<String, String> getProductIdByIdProductUnoee(fan_Pricebook.row_element[] rowElements) {

        Set<String> unoeeProductIds = new Set<String>();
        Map<String, Id> products = new Map<String, Id>();

        for (fan_Pricebook.row_element rowElement : rowElements) {
            unoeeProductIds.add(rowElement.ITEM);
        }

        for(Product2 product : [SELECT IdProductoUNOEE__c FROM Product2 WHERE IdProductoUNOEE__c IN :unoeeProductIds]){
            products.put(product.IdProductoUNOEE__c, product.Id);
        }
        return products;
    }

    Map<String, String> getPricebookIdByName(String pricebookName) {

        String[] pricebookNames = new String[] { pricebookName, pricebookName + DISCOUNT_PRICE_BOOK_SUFFIX };
        Map<String, String> pricebooks = new Map<String, String>();

        for(Pricebook2 pricebook : [SELECT Name FROM Pricebook2 WHERE Name = :pricebookNames]){
            pricebooks.put(pricebook.Name, pricebook.Id);
        }
        return pricebooks;
    }

    String buildPricebookEntryExternalId(String pricebookName, String idProductUnoee) {
        return idProductUnoee + '-' + pricebookName;
    }

    PricebookEntry buildPricebookEntry(String externalId, Decimal unitPrice, String pricebookId, String productId) {
        return new PricebookEntry(
            fan_ExternalId__c = externalId,
            UnitPrice = unitPrice,
            Pricebook2Id = pricebookId,
            Product2Id = productId,
            IsActive = true
        );
    }
}