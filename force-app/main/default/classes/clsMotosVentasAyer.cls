public with sharing class clsMotosVentasAyer {
    @AuraEnabled(cacheable=true)
    public static string getDatos(){
        try {
            //Obtener los Concesionarios en los que está el usuario logueado
            set<String> setConcesionarios = new set<String>();
            String Rol = [select UserRole.Name from User where Id=:UserInfo.getUserId() limit 1].UserRole.Name;
            system.debug(Rol);
            switch on Rol {
                when 'Gerente de Zona Centro Norte' {		// Zona Centro Norte
                    for (Miembro_de_Concesionario__c mc: [select Concesionario__r.Autonumerico__c from Miembro_de_Concesionario__c where Concesionario__r.Zona__c = 'Centro Norte' with SECURITY_ENFORCED]){
                        setConcesionarios.add(mc.Concesionario__r.Autonumerico__c);
                    }
                }	
                when 'Gerente de Zona Sur' {		// Zona Sur
                    for (Miembro_de_Concesionario__c mc: [select Concesionario__r.Autonumerico__c from Miembro_de_Concesionario__c where Concesionario__r.Zona__c = 'Sur' with SECURITY_ENFORCED]){
                        setConcesionarios.add(mc.Concesionario__r.Autonumerico__c);
                    }
                }
                when else {		  // si no es de los gerentes de zona, entonces halar solo los concesionarios donde es miembro
                    
                    for (Miembro_de_Concesionario__c mc: [select Concesionario__r.Autonumerico__c from Miembro_de_Concesionario__c where Nombre_de_asesor__c=:UserInfo.getUserId() with SECURITY_ENFORCED]){
                        setConcesionarios.add(mc.Concesionario__r.Autonumerico__c);
                    }
                }
            } 
            system.debug('concesionarios'+ setConcesionarios);
            Integer total = [select count() from Opportunity where Concesionario__r.Autonumerico__c in:setConcesionarios and CreatedDate=YESTERDAY and SyncedQuoteId!=null];
            system.debug('total'+ total);

            DatosOppsLastMonth datos = new DatosOppsLastMonth();
            datos.totalOppsYestarday = total;
            //datos.codigosConcesionariosUsuario = new List<String>{'Florencia','Ceiba'};
            datos.codigosConcesionariosUsuario = new List<String>(setConcesionarios);
            return JSON.serialize(datos);
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }

    public class DatosOppsLastMonth{
        public  Integer totalOppsYestarday;
        public  list<String> codigosConcesionariosUsuario;
    }
}