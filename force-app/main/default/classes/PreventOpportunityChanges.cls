/**
 * Fanalca
 * @author           Olvin Abarca
 * Description:      Class that tells if an Opportunity is allowed to be updated.
 *                   By requirement, an Opportunity may not be updated when there is a related Order with an ERP code set.
 *
 * Changes (Version)
 * -------------------------------------
 *           No.     Date            Author                  Description
 *           -----   ----------      --------------------    ---------------
 * @version  1.0     12/21/2020      Olvin Abarca            Class definition.
 *********************************************************************************************************/
public class PreventOpportunityChanges {
  public static boolean areOpportunitiesUpdatable(
    List<Opportunity> opportunities
  ) {
    Map<Id, Opportunity> opportunityMap = opportunityListToMap(opportunities);
    List<Order> orders = getOpportunitiesOrders(opportunityMap);

    Boolean isUpdatable = true;
    for (Order order : orders) {
      if (
        order.Codigo_sap_cliente__c != null &&
        order.Codigo_sap_cliente__c != ''
      ) {
        isUpdatable = false;
      }
    }
    return orders.size() == 0 || isUpdatable;
  }

  private static List<Order> getOpportunitiesOrders(
    Map<Id, Opportunity> opportunities
  ) {
    return opportunities.keySet().size() <= 0 ? new List<Order>() : [
      SELECT Id, Codigo_sap_cliente__c
      FROM ORDER
      WHERE OpportunityId = :opportunities.keySet()
    ];
  }

  private static Map<Id, Opportunity> opportunityListToMap(
    List<Opportunity> opportunities
  ) {
    Map<Id, Opportunity> mapa = new Map<Id, Opportunity>();
    mapa.putAll(opportunities);
    return mapa;
  }
}