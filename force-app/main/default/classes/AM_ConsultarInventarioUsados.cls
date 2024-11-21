public  with sharing class AM_ConsultarInventarioUsados {
	@AuraEnabled(cacheable=true)
    public static list<Inventario_de_Usados__c> consultar(Decimal precioMenor, Decimal precioMayor, String producto, Integer anioModelo, Integer kilometraje, String placa){
        try{
            string query = 'select Fotos_FINECAR__c, Fotos_TucarroCom__c,Name,Id,Nombre_De_Producto__c,Agencia__c, Estado_Del_Vehiculo__c, Marca__c, Linea__c,  Version__c, Cilindraje__c, Caja__c, Traccion__c, Color__c,  Ano__c, Kilometraje__c, Precio_Venta__c, Origen__c, Placas__c from Inventario_de_Usados__c ';
            string queryWhere='Estado_Del_Vehiculo__c != \'FACTURADO\'  and Estado_Del_Vehiculo__c != \'CONSIG. RETIRADO\' ';           
            string order=' order by Marca__c asc, Linea__c asc,  Version__c asc, Ano__c asc';
            if (precioMenor!=null && precioMenor!=0) queryWhere = 'Precio_Venta__c >= ' + precioMenor;
            if (precioMayor!=null && precioMayor!=0) queryWhere += addAnd(queryWhere) + 'Precio_Venta__c <= ' + precioMayor;
            if (!String.isBlank(producto)) queryWhere += addAnd(queryWhere) + 'Nombre_De_Producto__c like \'%'+ String.escapeSingleQuotes(producto) +'%\' ';
            if (anioModelo!=null) queryWhere += addAnd(queryWhere) + 'Ano__c = \'' + anioModelo + '\'';
            if (kilometraje!=null) queryWhere += addAnd(queryWhere) + 'Kilometraje__c = \'' + kilometraje + '\'';
            if (!String.isBlank(placa)) queryWhere += addAnd(queryWhere) + 'Placas__c like \'%'+ String.escapeSingleQuotes(placa) +'%\' ';
                       system.debug(queryWhere);
            String queryFull = query;
            if (queryWhere!='') queryFull = queryFull + ' where ' + queryWhere;
           queryFull += order;
            return Database.query(queryFull)    ;
        }catch (Exception ex){ throw new AuraHandledException(ex.getMessage()); }
    }
  
    private static String addAnd(String whereQuery){
        if (whereQuery!='') return ' and '; else return '';
    }
/*
  public static boolean isAutosProfile(Profile profile) {
    Boolean isAutosProfile =
      profile.Name.indexOf('Autos') > -1 ||
      profile.Name.indexOf('autos') > -1;
    //return isAutosProfile;
    return true;
  }
    */
}