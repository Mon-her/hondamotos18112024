/**
 * Fanalca
 * @author           Olvin Abarca
 * Description:      Class that provides information to customLookup LWC
 *
 * Changes (Version)
 * -------------------------------------
 *           No.     Date            Author                  Description
 *           -----   ----------      --------------------    ---------------
 * @version  1.0     03/09/2021      Olvin Abarca            Class definition.
 *********************************************************************************************************/
public class CustomLookup {
  @AuraEnabled
  public static List<SObject> lookup(
    String objectApiName,
    String fieldApiName,
    String selectedFields,
    String term
  ) {
    String query =
      'SELECT ' +
      escape(selectedFields) +
      ' FROM ' +
      escape(objectApiName) +
      ' WHERE ' +
      escape(fieldApiName) +
      ' LIKE \'' +
      escape(term) +
      '%\'';

    List<SObject> rows = Database.query(query);
    return rows;
  }
  public static String escape(String str) {
    return String.escapeSingleQuotes(str.trim());
  }
}