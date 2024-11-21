public with sharing class GenOrderPDF {
  private final Order order;
  private final Opportunity opportunity;
  public String vfpQuoteTemplateURL { get; set; }

  public GenOrderPDF(ApexPages.StandardController stdController) {
    String orderId = ApexPages.currentPage().getParameters().get('id');
    this.order = [
      SELECT Id, OpportunityId, Opportunity.RecordType.DeveloperName
      FROM Order
      WHERE Id = :orderId
      LIMIT 1
    ];

    System.debug('odn:' + this.order.opportunity.RecordType.DeveloperName);
    System.debug('oau:' + Label.RTOportunidadAutos);
    Boolean isAutos =
      this.order.opportunity.RecordType.DeveloperName ==
      Label.RTOportunidadAutos;
    Boolean isCommunityProfile = GenOrderPDF.isCommunityProfile();
    String vfpPath = getVFPPath(isAutos, isCommunityProfile);

    this.vfpQuoteTemplateURL = vfpPath;

    if (isAutos) {

      Order order2 = [
        SELECT 
        Opportunity.Realizo_Best_Drive__c,
        Opportunity.Account.Actividad_economica__c,
        Opportunity.Account.AM_Ocupacion__pc,
        Opportunity.Forma_de_pago__c,
        Opportunity.Marca_retoma__c,
        Opportunity.Linea_retoma__c,
        Opportunity.Version_retoma__c,
        Opportunity.Modelo_retoma__c,
        Opportunity.Kilometraje_retoma__c,
        Opportunity.Color_retoma__c,
        Opportunity.Caja_retoma__c,
        Opportunity.Tipo_de_carroceria_retoma__c,
        Opportunity.Sitio_de_matricula_retoma__c,
        Opportunity.Placa_retoma__c,
        Opportunity.Avaluado_por_retoma__c,
        Opportunity.Avaluo_retoma__c,
        Opportunity.Contrato_retoma__c,

        Opportunity.Documentos_completos_pedido__c
        
        FROM Order
        WHERE Id = :orderId
        LIMIT 1
      ];

      Boolean isRetoma = order2.Opportunity.Forma_de_pago__c.contains('Retoma');
      Boolean areRetomaRequirementsMet = isRetoma ? (
        (order2.Opportunity.Marca_retoma__c != null)
        && (order2.Opportunity.Linea_retoma__c != null)
        && (order2.Opportunity.Version_retoma__c != null)
        && (order2.Opportunity.Modelo_retoma__c != null)
        && (order2.Opportunity.Kilometraje_retoma__c != null)
        && (order2.Opportunity.Color_retoma__c != null)
        && (order2.Opportunity.Caja_retoma__c != null)
        && (order2.Opportunity.Tipo_de_carroceria_retoma__c != null)
        && (order2.Opportunity.Sitio_de_matricula_retoma__c != null)
        && (order2.Opportunity.Placa_retoma__c != null)
        && (order2.Opportunity.Avaluado_por_retoma__c != null)
        && (order2.Opportunity.Avaluo_retoma__c != null)
        && (order2.Opportunity.Contrato_retoma__c != null)
      ) : true;

      Boolean isBestDriveOk = order2.Opportunity.Realizo_Best_Drive__c != null;
      Boolean isOcupacionOk = order2.Opportunity.Account.AM_Ocupacion__pc != null && order2.Opportunity.Account.AM_Ocupacion__pc != '';
      Boolean isActividadEconomicaOk = order2.Opportunity.Account.Actividad_economica__c != null && order2.Opportunity.Account.Actividad_economica__c != '';

      Boolean arePreconditionsMet = isBestDriveOk && isOcupacionOk && isActividadEconomicaOk && areRetomaRequirementsMet && order2.Opportunity.Documentos_completos_pedido__c;

      // se invierte el flag para hacer funcionar la logica de condicion del renderer 
      //String vfpPage = arePreconditionsMet ? 'invoiceRequestAutoTemplate?id=' + order.Id : 'invoiceRequestAutoPreconditions?isBestDriveOk='+(!isBestDriveOk)+'&isOcupacionOk='+(!isOcupacionOk)+'&areRetomaRequirementsMet='+(!areRetomaRequirementsMet)+'&Documentos_completos_pedido__c='+(!order2.Opportunity.Documentos_completos_pedido__c+'&isActividadEconomicaOk='+isActividadEconomicaOk);
	  String vfpPage = 'invoiceRequestAutoTemplate?id=' + order.Id;
      this.vfpQuoteTemplateURL += vfpPage;
    } else {
      this.vfpQuoteTemplateURL += 'invoiceRequestMotoTemplate?id=' + order.Id;
    }
  }

  public static Boolean isCommunityProfile() {
    return UserInfo.getUserType() == 'PowerPartner';
  }

  private String getVFPPath(Boolean isAutos, Boolean isCommunityProfile) {
    String path = (isAutos
      ? (isCommunityProfile ? Label.Autos_Community_Path + '/apex/' : '/apex/')
      : (isCommunityProfile
          ? System.Label.motoCommunityVPFbaseURL
          : System.Label.motoCommunityVPFbaseURL));

    return path;
  }
}