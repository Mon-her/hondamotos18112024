public class GenQuotePDF {
  private final Quote quote;
  public String vfpQuoteTemplateURL { get; set; }
  public String recordId { get; set; }
  public Boolean isQuoteDiscountApproved { get; set; }
  public Boolean isQuotePricesFetched { get; set; }
  public Boolean isOpportunityAutos { get; set; }
  public Boolean isOpportunityAutosUsados { get; set; }
  public Boolean isOpportunityAutosNuevos { get; set; }
  public Boolean isOpportunityAutosRenting { get; set; }
  public Boolean isCommunityProfile { get; set; }

  public GenQuotePDF(ApexPages.StandardController stdController) {
    this.recordId = ApexPages.currentPage().getParameters().get('id');
    String quoteId = recordId;

    this.quote = [
      SELECT
        Id,
        Account.RecordType.DeveloperName,
        Account.PersonEmail,
        OpportunityId,
        Opportunity.Contacto__r.Email, // used by autos
        Opportunity.Account.Name,
        Opportunity.Account.FirstName,
        Opportunity.Account.LastName,
        Opportunity.Account.Segundo_Nombre__c,
        Opportunity.Account.Segundo_Apellido__c,
        Opportunity.Account.RecordType.DeveloperName,
        Opportunity.RecordType.DeveloperName,
        Opportunity.Tipo_de_Oportunidad__c,
        Owner.Email,
        Contact.Email,
        RecordType.DeveloperName,
        Discount,
        DescuentoApro__c,
        Realizo_consulta_de_precios__c,
        Nodriza_URL_pre_visualizaci_n__c,
        Nodriza_URL_de_seguimiento__c,
        Descuento_Valor__c,
        Maximo_descuento_asesor__c
      FROM Quote
      WHERE Id = :quoteId
      LIMIT 1
    ];

    Profile profile = [
      SELECT Name
      FROM Profile
      WHERE Id = :UserInfo.getProfileId()
      LIMIT 1
    ];

    this.isOpportunityAutos =
      this.quote.opportunity.RecordType.DeveloperName ==
      Label.RTOportunidadAutos;
    this.isCommunityProfile = GenQuotePDF.isCommunityProfile(profile);

    this.isOpportunityAutosUsados =
      this.quote.opportunity.Tipo_de_Oportunidad__c == 'Usados';

    this.isOpportunityAutosNuevos =
      this.quote.opportunity.Tipo_de_Oportunidad__c == 'Nuevos';

    this.isOpportunityAutosRenting =
      this.quote.opportunity.Tipo_de_Oportunidad__c == 'Renting';

    String vfpPath = getVFPPath(
      this.isOpportunityAutos,
      this.isCommunityProfile
    );

    // permite crear pdf cuando es oportunidad de autos
    // aunque no se haya mandado a consultar precios
    this.isQuotePricesFetched =
      quote.Realizo_consulta_de_precios__c || this.isOpportunityAutos;
    this.isQuoteDiscountApproved = true;
    this.vfpQuoteTemplateURL =
      vfpPath +
      '/apex/quoteDiscountNotApproved?id=' +
      quote.Id+'&isMotoQuote=' + (!isOpportunityAutos);

    if (this.quote.Discount != null && (this.quote.Discount > 0 && this.quote.Descuento_Valor__c > this.quote.Maximo_descuento_asesor__c) ){
      this.isQuoteDiscountApproved = this.quote.DescuentoApro__c;
    }

    if (isQuoteDiscountApproved && isQuotePricesFetched) {
      if (this.isOpportunityAutos) {
        if (this.quote.opportunity.Tipo_de_Oportunidad__c == 'Nuevos') {
          this.vfpQuoteTemplateURL =
            vfpPath +
            '/apex/quoteAutoNuevoTemplate?id=' +
            quote.Id;
        } else if (this.quote.opportunity.Tipo_de_Oportunidad__c == 'Renting') {
          this.vfpQuoteTemplateURL =
            vfpPath +
            '/apex/quoteAutoRentingTemplate?id=' +
            quote.Id;
        } else {
          this.vfpQuoteTemplateURL =
            vfpPath +
            '/apex/quoteAutoUsadoTemplate?id=' +
            quote.Id;
        }
      } else {
        this.vfpQuoteTemplateURL =
          vfpPath +
          '/apex/quoteMotoTemplate1?id=' +
          quote.Id;
      }
    } else {
      if (this.isOpportunityAutos) {
        this.vfpQuoteTemplateURL =
          vfpPath +
          '/apex/quoteDiscountNotApproved?id=' +
          quote.Id+'&isMotoQuote=' + (!isOpportunityAutos);
      }
    }
  }

  public static Boolean isCommunityProfile(Profile profile) {
    Boolean isCommunityProfile = false;
    String[] communityProfiles = (Label.perfilesComunidadAutos +
      ',' +
      Label.perfilesComunidadMotos)
      .split(',');
    for (Integer i = 0; i < communityProfiles.size(); i++) {
      String communityProfile = communityProfiles[i];
      if (communityProfile == profile.Name) {
        isCommunityProfile = true;
      }
    }

    return isCommunityProfile;
  }

  private String getVFPPath(
    Boolean isOpportunityAutos,
    Boolean isCommunityProfile
  ) {
    String path = (isOpportunityAutos
      ? (isCommunityProfile ? Label.Autos_Community_Path : '')
      : (isCommunityProfile ? '' : ''));

    return path;
  }

  /**
   * @Method:     sendEmail
   * @Description: Send email with attached quote and attachments related on the quote.
   * @author     Raul Mora - 17-01-2019
   */
  public PageReference sendEmail() {
    Blob blbBody;

    List<Messaging.EmailFileAttachment> attachmentList = new List<Messaging.EmailFileAttachment>();
    Set<String> stOrderAttch = new Set<String>();
    List<ContentDocumentLink> lstOtherAtt = [
      SELECT Id, ContentDocumentId
      FROM ContentDocumentLink
      WHERE LinkedEntityId = :quote.Id
    ];
    if (!lstOtherAtt.isEmpty()) {
      for (ContentDocumentLink objCD : lstOtherAtt) {
        stOrderAttch.add(objCD.ContentDocumentId);
      }

      List<ContentVersion> lstConVer = [
        SELECT Id, VersionData, FileType, PathOnClient
        FROM ContentVersion
        WHERE ContentDocumentId IN :stOrderAttch
      ];
      if (!lstConVer.isEmpty()) {
        Messaging.EmailFileAttachment emailAttTemp = new Messaging.EmailFileAttachment();
        for (ContentVersion objCV : lstConVer) {
          emailAttTemp = new Messaging.EmailFileAttachment();
          emailAttTemp.setFileName(objCV.PathOnClient);
          emailAttTemp.setBody(objCV.VersionData);
          emailAttTemp.setContentType(obtainContentType(objCV.FileType));
          attachmentList.add(emailAttTemp);
        }
      }
    } else {
      PageReference vfpQuoteTemplate = new PageReference(vfpQuoteTemplateURL);

      blbBody = Test.isRunningTest()
        ? Blob.valueOf('foo')
        : vfpQuoteTemplate.getContentAsPDF();

      Messaging.EmailFileAttachment emailAtt = new Messaging.EmailFileAttachment();
      emailAtt.setFileName('Cotizacion.pdf');
      emailAtt.setBody(blbBody);
      emailAtt.setContentType('application/pdf');
      attachmentList.add(emailAtt);
    }

    List<String> toAddressList = new List<String>();
    toAddressList.add(quote.Owner.Email);

    System.debug('quote.Owner.Email: ' + quote.Owner.Email);
    System.debug(
      'Account.RecordType.DeveloperName: ' +
      quote.Account.RecordType.DeveloperName
    );

    if (
      quote.Account.RecordType.DeveloperName ==
      Label.MotosRecordTypeDevNameAccountJuridica
    ) {
      String contactEmail = (isOpportunityAutos ? quote.Opportunity.Contacto__r.Email : quote.Contact.Email);
      toAddressList.add(contactEmail);
      System.debug('contactEmail: ' + contactEmail);
    } else {
      toAddressList.add(quote.Account.PersonEmail);
      System.debug('quote.Account.PersonEmail: ' + quote.Account.PersonEmail);
    }

    String emailTemplateName = getEmailTemplateNameFor(
      this.quote,
      this.isOpportunityAutos
    );

    System.debug('emailTemplateName: ' + emailTemplateName);
    EmailTemplate objEmail = [
      SELECT Id, HtmlValue, Body, Subject, Name, DeveloperName
      FROM EmailTemplate
      WHERE DeveloperName = :emailTemplateName
    ];

    // Messaging.SingleEmailMessage email = new Messaging.SingleEmailMessage();
    String whoId = quote.Contact.Id;
    String whatId = quote.Id;
    Messaging.SingleEmailMessage email = Messaging.renderStoredEmailTemplate(objEmail.Id, whoId, whatId);

    // String accountName = getAccountName(
    //   quote.Opportunity.Account.Name,
    //   quote.Opportunity.Account.FirstName,
    //   quote.Opportunity.Account.Segundo_Nombre__c,
    //   quote.Opportunity.Account.LastName,
    //   quote.Opportunity.Account.Segundo_Apellido__c,
    //   quote.Opportunity.Account.RecordType.DeveloperName
    // );
    // String subject = objEmail.Subject.replace(
    //   '{!Opportunity.Account}',
    //   accountName
    // );

    String body = null;

    // email.setTargetObjectId(quote.Id);
    // email.setSubject(objEmail.Subject);
    email.setToAddresses(toAddressList);
    // if (objEmail.HtmlValue != null) {
    //   // body = objEmail.HtmlValue.replace('{!Opportunity.Account}', accountName);
    //   body = replaceEmailTemplateVariables(
    //     objEmail.HtmlValue,
    //     quote,
    //     accountName
    //   );
    //   email.setHtmlBody(body);
    // } else {
    //   // body = objEmail.Body.replace('{!Opportunity.Account}', accountName);
    //   body = replaceEmailTemplateVariables(objEmail.Body, quote, accountName);
    //   email.setPlainTextBody(body);
    // }

    if (
      quote.Nodriza_URL_de_seguimiento__c == null ||
      quote.Nodriza_URL_de_seguimiento__c == ''
    ) {
      // No enviar PDF cuando se tiene una URL de cotizacion de Nodriza
      email.setFileAttachments(attachmentList);
    }

    if (!test.isRunningTest()) {
      Messaging.SendEmailResult[] emailRes = Messaging.sendEmail(
        new List<Messaging.SingleEmailMessage>{ email }
      );
    }

    if (
      this.quote.Opportunity.RecordType.DeveloperName ==
      Label.RTOportunidadAutos
    ) {
      // se actualiza la etapa de la oportunidad a "Enviada al cliente" despues de usar el boton enviar email
      Quote q = new Quote(Id = this.quote.Id, Status = 'Enviada al Cliente');
      update q;
    }

    return quotePageReference('/' + this.quote.Id);
  }

  public String getEmailTemplateNameFor(
    Quote quote,
    Boolean isOpportunityAutos
  ) {
    String emailTemplateName = (isOpportunityAutos
      ? (quote.Opportunity.Tipo_de_Oportunidad__c == 'Nuevos'
          ? 'Send_Quote_Email_Template_Autos_Nuevos'
          : (quote.Opportunity.Tipo_de_Oportunidad__c == 'Usados'
              ? 'Send_Quote_Email_Template_Autos_Usados'
              : 'Send_Quote_Email_Template_Autos_Renting'))
      : 'Send_Quote_Email_Template');
    return emailTemplateName;
  }

  private String replaceEmailTemplateVariables(
    String body,
    Quote quote,
    String accountName
  ) {
    body = body.replace('{!Opportunity.Account}', accountName);
    body = body.replace(
      '{!Nodriza_URL_pre_visualizaci_n__c}',
      quote.Nodriza_URL_pre_visualizaci_n__c == null
        ? ''
        : quote.Nodriza_URL_pre_visualizaci_n__c
    );
    body = body.replace(
      '{!Nodriza_URL_de_seguimiento__c}',
      quote.Nodriza_URL_de_seguimiento__c == null
        ? ''
        : quote.Nodriza_URL_de_seguimiento__c
    );

    return body;
  }

  public static Quote genQuoteToSendToNodriza(String quoteId) {
    Quote quote = [
      SELECT
        Id,
        Name,
        QuoteNumber,
        Fecha_de_validez__c,
        CreatedDate,
        Creado_Prolibu__c,
        AM_Tipo_Renting__c,
        AM_Servicios_adicionales__c,
        Servicios_incluidos__c,
        ExpirationDate,
        //
        AM_Canon_Renting1__c,
        AM_Canon_Renting2__c,
        AM_Canon_Renting3__c,
        AM_Kilometraje_Renting1__c,
        AM_Kilometraje_Renting2__c,
        AM_Kilometraje_Renting3__c,
        AM_Plazo_Renting1__c,
        AM_Plazo_Renting2__c,
        AM_Plazo_Renting3__c, 
        AM_IVA_Canon_Renting1__c,
        AM_IVA_Canon_Renting2__c,
        AM_IVA_Canon_Renting3__c,
        //

        OpportunityId,
        Opportunity.RecordType.DeveloperName,
        Opportunity.Tipo_de_Oportunidad__c,
        Opportunity.Servicios_incluidos_Renting__c,
        Opportunity.AM_Servicios_adicionales__c,
        Opportunity.AM_Cantidad_de_vehiculos__c,
        Opportunity.AM_Tipo_Renting__c,
        //
        Opportunity.Account.PersonEmail,
        opportunity.Account.Phone,
        Opportunity.Account.PersonMobilePhone,
        Opportunity.Account.Name,
        Opportunity.Account.FirstName,
        Opportunity.Account.LastName,
        Opportunity.Account.Segundo_Nombre__c,
        Opportunity.Account.Segundo_Apellido__c,
        Opportunity.Account.AM_Numero_de_documento__c,
        Opportunity.Account.AM_Direccion__c,
        Opportunity.Account.AM_Ciudad__c,
        Opportunity.Account.RecordType.DeveloperName,
        //
        Opportunity.Account.IsPersonAccount,
        Opportunity.Contacto__r.FirstName,
        Opportunity.Contacto__r.LastName,
        Opportunity.Contacto__r.Email,
        //
        Opportunity.Owner.FirstName,
        Opportunity.Owner.LastName,
        Opportunity.Owner.Name,
        Opportunity.Owner.Title,
        Opportunity.Owner.Email,
        Opportunity.Owner.MobilePhone,
        //

        Opportunity.Vitrina__c,
        Opportunity.Vitrina__r.Direccion_de_agencia__c,
        Opportunity.Vitrina__r.Departamento__c,
        Opportunity.Vitrina__r.Name,
        //

        Opportunity.AM_Canon_Renting1__c,
        Opportunity.AM_Canon_Renting2__c,
        Opportunity.AM_Canon_Renting3__c,
        Opportunity.AM_Kilometraje_Renting1__c,
        Opportunity.AM_Kilometraje_Renting2__c,
        Opportunity.AM_Kilometraje_Renting3__c,
        Opportunity.AM_Plazo_Renting1__c,
        Opportunity.AM_Plazo_Renting2__c,
        Opportunity.AM_Plazo_Renting3__c,
        //
        RecordType.DeveloperName,
        //
        (
          SELECT
            Id,
            Entidad_Financiera__c,
            Plan_Financiero__c,
            Cuota_inicial__c,
            Saldo_a_financiar__c,
            Cuota_mensual__c,
            Plazo_en_meses__c,
            Tasa_de_interes__c,
            Entidad_Financiera2__c,
            Plan_Financiero2__c,
            Cuota_inicial2__c,
            Saldo_a_financiar2__c,
            Cuota_mensual2__c,
            Plazo_en_meses2__c,
            Tasa_de_interes2__c,
            Quantity,
            Descuento_valor__c,
            UnitPrice,
            //
            Product2.Name,
            Product2.Ano_modelo__c,
            Product2.Referencia_comercial__c
          FROM QuoteLineItems
        )
      FROM Quote
      WHERE Id = :quoteId
      LIMIT 1
    ];
    return quote;
  }

  public PageReference sendToNodriza() {
    Quote quote = genQuoteToSendToNodriza(this.quote.Id);
    // Opportunity opportunity = genOpportunityToSendToNodriza(
    //   quote.opportunityId
    // );

    Date quoteExpirationDate = quote.Fecha_de_validez__c != null ? quote.Fecha_de_validez__c : QuotePDFController.getLastWorkDayOfMonth(
      quote.CreatedDate
    );

    if(!Test.isRunningTest()){
      EnviarQuoteHaciaNodriza.send(quote, quoteExpirationDate);
    }

    return quotePageReference('/' + quote.Id);
  }

  // public String getAccountName(
  //   String name,
  //   String firstName,
  //   String secondName,
  //   String lastName,
  //   String secondLastName,
  //   String accountRTDevName
  // ) {
  //   String regExp = '\\s*null\\s*';
  //   String replacement = ' ';
  //   String businessAccountName = name;
  //   String personalAccountName = (firstName +
  //     ' ' +
  //     secondName +
  //     ' ' +
  //     lastName +
  //     ' ' +
  //     secondLastName)
  //     .replaceAll(regExp, replacement)
  //     .trim();

  //   String accountName = businessAccountName;
  //   if (accountRTDevName == Label.MotosRecordTypeDevNameAccountNatural) {
  //     accountName = personalAccountName;
  //   }
  //   return accountName;
  // }

  /**
   * @Method:     obtainContentType
   * @param:     String
   * @Description: Set content type based on content from file.
   * @author     Raul Mora - 20-03-2019
   */
  private String obtainContentType(String strContent) {
    Map<String, String> mpValue = new Map<String, String>();
    mpValue.put('PNG', 'image/png');
    mpValue.put('JPEG', 'image/jpeg');
    mpValue.put('JPG', 'image/jpeg');
    mpValue.put('PDF', 'application/pdf');
    String strReturn = mpValue.containsKey(strContent)
      ? mpValue.get(strContent)
      : (strContent.contains('WORD') || strContent.contains('word')
          ? 'application/msword'
          : (strContent.contains('POWER') || strContent.contains('power')
              ? 'application/vnd.ms-powerpoint'
              : ''));
    return strReturn;
  }

  public PageReference saveQuoteDocument() {
    PageReference vfpQuoteTemplate = new PageReference(vfpQuoteTemplateURL);
    vfpQuoteTemplate.getParameters().put('id', quote.Id);
    vfpQuoteTemplate.setRedirect(true);

    Blob blbBody;
    if (Test.isRunningTest()) {
      blbBody = Blob.valueOf('foo');
    } else {
      blbBody = vfpQuoteTemplate.getContentAsPDF();
    }

    QuoteDocument pdf = new QuoteDocument();
    pdf.document = blbBody;
    pdf.quoteId = quote.Id;
    insert pdf;

    Quote quote = new Quote(Id = quote.Id, Quote_PDF_Generado__c = true);
    update quote;

    return quotePageReference('/' + quote.Id);
  }

  private PageReference quotePageReference(String pathString) {
    PageReference prReturn = new PageReference(pathString);
    prReturn.setRedirect(true);
    return prReturn;
  }
}