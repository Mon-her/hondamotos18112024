/**
 * Fanalca
 * @author           Olvin Abarca
 * Description:
 *
 * Changes (Version)
 * -------------------------------------
 *           No.     Date            Author                  Description
 *           -----   ----------      --------------------    ---------------
 * @version  1.0     ??/??/????      ???                     Class definition.
 * @version  1.1     12/21/2020      Olvin Abarca            added method updateQuoteFlagIfDiscountsAndPricesChanged
 *********************************************************************************************************/

trigger QuoteLineSyncTrigger on QuoteLineItem(
  before insert,
  before update,
  after insert,
  after update
) {
  //
  if (Trigger.isAfter && Trigger.isUpdate) {
    if (TriggerStopper.consultaDePreciosEntered == false) {
      TriggerStopper.consultaDePreciosEntered = true;
      updateQuoteFlagIfDiscountsAndPricesChanged();
    }

    return;
  }

  if (Trigger.isBefore && Trigger.isInsert) {
    updatePrecioListaAntesDeImpuesto();
    if (QuoteSyncUtil.isRunningTest) {
      for (QuoteLineItem qli : Trigger.new) {
        QuoteSyncUtil.populateRequiredFields(qli);
      }
    }
    return;
  }
    
    if (Trigger.isBefore && Trigger.isUpdate) {
    updatePrecioListaAntesDeImpuesto();
    return;
  }

  if (TriggerStopper.stopQuoteLine)
    return;

  Set<String> quoteLineFields = QuoteSyncUtil.getQuoteLineFields();
  List<String> oppLineFields = QuoteSyncUtil.getOppLineFields();

  String qliFields = QuoteSyncUtil.getQuoteLineFieldsString();

  String oliFields = QuoteSyncUtil.getOppLineFieldsString();

  String qliIds = '';
  for (QuoteLineItem qli : Trigger.new) {
    if (qliIds != '')
      qliIds += ', ';
    qliIds += '\'' + qli.Id + '\'';
  }

  String qliQuery =
    'select Id, QuoteId, PricebookEntryId, UnitPrice, Quantity, Discount, ServiceDate, SortOrder' +
    qliFields +
    ' from QuoteLineItem where Id in (' +
    qliIds +
    ') order by QuoteId, SortOrder ASC';
  //System.debug(qliQuery);

  List<QuoteLineItem> qlis = Database.query(qliQuery);

  Map<Id, List<QuoteLineItem>> quoteToQliMap = new Map<Id, List<QuoteLineItem>>();

  for (QuoteLineItem qli : qlis) {
    List<QuoteLineItem> qliList = quoteToQliMap.get(qli.QuoteId);
    if (qliList == null) {
      qliList = new List<QuoteLineItem>();
    }
    qliList.add(qli);
    quoteToQliMap.put(qli.QuoteId, qliList);
  }

  Set<Id> quoteIds = quoteToQliMap.keySet();
  Map<Id, Quote> quotes = new Map<Id, Quote>(
    [
      SELECT id, OpportunityId, isSyncing, CreatedDate
      FROM Quote
      WHERE Id IN :quoteIds
    ]
  );

  DateTime dtNow = System.now();
  DateTime dtNow5 = dtNow.addSeconds(-5);

  String oppIds = '';
  Set<Id> filterQuoteIds = new Set<Id>();
  for (Quote quote : quotes.values()) {
    // Only sync quote line item that are inserted for a new Quote or on a isSyncing Quote
    //if ((trigger.isInsert && QuoteSyncUtil.isNewQuote(quote.Id)) || quote.isSyncing) {
    if ((Trigger.isInsert && (quote.CreatedDate > dtNow5)) || quote.isSyncing) {
      if (oppIds != '')
        oppIds += ', ';
      oppIds += '\'' + quote.OpportunityId + '\'';
    } else {
      filterQuoteIds.add(quote.Id);
    }
  }

  //System.debug('Filter quote ids: ' + filterQuoteIds);

  quoteIds.removeAll(filterQuoteIds);
  for (Id id : filterQuoteIds) {
    quotes.remove(id);
    quoteToQliMap.remove(id);
  }

  if (oppIds != '') {
    String oliQuery =
      'select Id, OpportunityId, PricebookEntryId, UnitPrice, Quantity, Discount, ServiceDate, SortOrder' +
      oliFields +
      ' from OpportunityLineItem where OpportunityId in (' +
      oppIds +
      ') order by OpportunityId, SortOrder ASC';
    //System.debug(qliQuery);

    List<OpportunityLineItem> olis = Database.query(oliQuery);

    Map<Id, List<OpportunityLineItem>> oppToOliMap = new Map<Id, List<OpportunityLineItem>>();

    for (OpportunityLineItem oli : olis) {
      List<OpportunityLineItem> oliList = oppToOliMap.get(oli.OpportunityId);
      if (oliList == null) {
        oliList = new List<OpportunityLineItem>();
      }
      oliList.add(oli);
      oppToOliMap.put(oli.OpportunityId, oliList);
    }

    Set<OpportunityLineItem> updateOlis = new Set<OpportunityLineItem>();
    Set<QuoteLineItem> updateQlis = new Set<QuoteLineItem>();

    for (Quote quote : quotes.values()) {
      List<OpportunityLineItem> opplines = oppToOliMap.get(quote.OpportunityId);

      // for quote line insert, there will not be corresponding opp line
      if (opplines == null)
        continue;

      Set<OpportunityLineItem> matchedOlis = new Set<OpportunityLineItem>();

      for (QuoteLineItem qli : quoteToQliMap.get(quote.Id)) {
        boolean updateOli = false;
        QuoteLineItem oldQli = null;

        if (Trigger.isUpdate) {
          oldQli = Trigger.oldMap.get(qli.Id);
          //System.debug('Old qli: ' + oldQli.UnitPrice + ', ' + oldQli.Quantity + ', ' + oldQli.Discount + ', ' + oldQli.ServiceDate);
          //System.debug('New qli: ' + qli.UnitPrice + ', ' + qli.Quantity + ', ' + qli.Discount + ', ' + qli.ServiceDate);

          if (
            qli.UnitPrice == oldQli.UnitPrice &&
            qli.Quantity == oldQli.Quantity &&
            qli.Discount == oldQli.Discount &&
            qli.ServiceDate == oldQli.ServiceDate &&
            qli.SortOrder == oldQli.SortOrder
          )
            updateOli = true;
        }

        boolean hasChange = false;
        boolean match = false;

        for (OpportunityLineItem oli : opplines) {
           system.debug('oli: ' + oli);
             system.debug('qli: ' + qli);
          if (
            oli.pricebookentryid == qli.pricebookentryId &&
            oli.UnitPrice == qli.UnitPrice &&
            oli.Quantity == qli.Quantity &&
            oli.Discount == qli.Discount &&
            oli.ServiceDate == qli.ServiceDate &&
            oli.SortOrder == qli.SortOrder
          ) {
            if (updateOlis.contains(oli) || matchedOlis.contains(oli))
              continue;

            matchedOlis.add(oli);

            for (String qliField : quoteLineFields) {
              String oliField = QuoteSyncUtil.getQuoteLineFieldMapTo(qliField);
              Object oliValue = oli.get(oliField);
              Object qliValue = qli.get(qliField);
              if (oliValue != qliValue) {
                if (
                  Trigger.isInsert &&
                  (qliValue == null ||
                  (qliValue instanceof Boolean && !Boolean.valueOf(qliValue)))
                ) {
                  //System.debug('Insert trigger, isSyncing: ' + quote.isSyncing + ', new quote ids: ' + QuoteSyncUtil.getNewQuoteIds());

                  // If it's a newly created Quote, don't sync the "Description" field value,
                  // because it's already copied from Opportunity Line Item on create.
                  //if (quote.isSyncing || (QuoteSyncUtil.isNewQuote(quote.Id) && !qliField.equalsIgnoreCase('description'))) {
                  if (
                    quote.isSyncing ||
                    ((quote.CreatedDate > dtNow5) &&
                    !qliField.equalsIgnoreCase('description'))
                  ) {
                    qli.put(qliField, oliValue);
                    hasChange = true;
                  }
                } else if (
                  Trigger.isUpdate && !updateOli /*&& oldQli != null*/
                ) {
                  //Object oldQliValue = oldQli.get(qliField);
                  //if (qliValue == oldQliValue) {
                  if (oliValue == null)
                    qli.put(qliField, null);
                  else
                    qli.put(qliField, oliValue);
                  hasChange = true;
                  //}
                } else if (Trigger.isUpdate && updateOli) {
                  if (qliValue == null)
                    oli.put(oliField, null);
                  else
                    oli.put(oliField, qliValue);
                  hasChange = true;
                }
              }
            }

            if (hasChange) {
              if (Trigger.isInsert || (Trigger.isUpdate && !updateOli)) {
                updateQlis.add(qli);
              } else if (Trigger.isUpdate && updateOli) {
                updateOlis.add(oli);
              }
            }

            match = true;
            break;
          }
        }

        // NOTE: this cause error when there is workflow field update that fired during record create
        //if (trigger.isUpdate && updateOli) System.assert(match, 'No matching oppline');
      }
    }

    TriggerStopper.stopOpp = true;
    TriggerStopper.stopQuote = true;
    TriggerStopper.stopOppLine = true;
    TriggerStopper.stopQuoteLine = true;

    if (!updateOlis.isEmpty()) {
      List<OpportunityLineItem> oliList = new List<OpportunityLineItem>();
      oliList.addAll(updateOlis);

      Database.update(olilist);
    }

    if (!updateQlis.isEmpty()) {
      List<QuoteLineItem> qliList = new List<QuoteLineItem>();
      qliList.addAll(updateQlis);

      Database.update(qliList);
    }

    if (Trigger.isInsert) {
      QuoteSyncUtil.removeAllNewQuoteIds(quoteIds);
    }

    TriggerStopper.stopOpp = false;
    TriggerStopper.stopQuote = false;
    TriggerStopper.stopOppLine = false;
    TriggerStopper.stopQuoteLine = false;
  }
    
  public void updatePrecioListaAntesDeImpuesto() {
      list<QuoteLineItem> newListQlis = (list<QuoteLineItem>) Trigger.New;
      if (newListQlis.size()!=1) return;
      List<Quote> lstQuote = [Select Id, OpportunityId,RecordType.DeveloperName from Quote where Id =: Trigger.New[0].QuoteId];
      if (lstQuote[0].RecordType.DeveloperName != Label.RTQuoteAutos) return; //This method applies only to Autos Quotes
      
      List<Opportunity> lstOppty = [Select Id, Tipo_de_Oportunidad__c, Valor_Utilidad__c from Opportunity where Id =: lstQuote[0].OpportunityId];
      for(QuoteLineItem qli : Trigger.New){
          if(lstOppty.size()>0){
              if(lstOppty[0].Tipo_de_Oportunidad__c == 'Usados'){
                  if(lstOppty[0].Valor_Utilidad__c != null){
                      qli.Precio_de_lista_antes_de_impuesto__c = qli.UnitPrice - (lstOppty[0].Valor_Utilidad__c);
                  }	else {
                      qli.Precio_de_lista_antes_de_impuesto__c = qli.UnitPrice;
                  }
              }else {
                  Decimal porcentaje = Integer.valueOf(Label.Hipoconsumo) + Integer.valueOf(Label.Iva);
                  Decimal dec = 0.0;
                  dec = porcentaje/100;
                  dec = qli.UnitPrice * dec;
                  qli.Precio_de_lista_antes_de_impuesto__c = qli.UnitPrice - dec;
              }
          }
      }
  }

  /**
   * Quote PDFs must not be generated when agent
   * manually updates discounts and prices after
   * executing button 'Consultar Descuentos y Precios'.
   */
  public void updateQuoteFlagIfDiscountsAndPricesChanged() {
    System.debug('updateQuoteFlagIfDiscountsAndPricesChanged');

    List<String> importantFields = new List<String>{
      'Descuento_Valor__c',
      'Quantity',
      'Valor_matrcula__c',
      'Tarifa_soat__c',
      'Valor_soat__c',
      'Valor_seguro_robo__c',
      'Cuota_Inicial__c',
      'Product2Id'
    };

    Map<Id, QuoteLineItem> newQuoteLineItemMap = (Map<Id, QuoteLineItem>) Trigger.NewMap;
    Map<Id, QuoteLineItem> oldQuoteLineItemMap = (Map<Id, QuoteLineItem>) Trigger.OldMap;

    Map<Id, Quote> quoteMap = new Map<Id, Quote>();
    List<QuoteLineItem> qlisToUpdate = new List<QuoteLineItem>();

    for (Id key : newQuoteLineItemMap.keySet()) {
      QuoteLineItem newQli = newQuoteLineItemMap.get(key);

      System.debug(
        'newQli.integracion_by_pass__c: ' + newQli.integracion_by_pass__c
      );

      if (newQli.integracion_by_pass__c == false) {
        for (String importantField : importantFields) {
          Boolean fieldIsSet = newQli.isSet(importantField);
          System.debug(
            'importantField: ' +
            importantField +
            ' fieldIsSet: ' +
            fieldIsSet
          );

          if (fieldIsSet) {
            if (quoteMap.get(newQli.QuoteId) == null) {
              quoteMap.put(
                newQli.QuoteId,
                new Quote(
                  Id = newQli.QuoteId,
                  Realizo_consulta_de_precios__c = false,
                  Quote_PDF_Generado__c = false
                )
              );
            }
          }
        }
      } else {
        qlisToUpdate.add(
          new QuoteLineItem(Id = newQli.Id, integracion_by_pass__c = false)
        );
      }
    }

    update quoteMap.values();
    update qlisToUpdate;
  }
}