/**
 * @description       : 
 * @author            : ChangeMeIn@UserSettingsUnder.SFDoc
 * @group             : 
 * @last modified on  : 08-19-2024
 * @last modified by  : ChangeMeIn@UserSettingsUnder.SFDoc
**/
public class Utilities {
    /////////////////////////////////////UTILITIES FOR WEB SERVICE ACCOUNT/////////////////////////////////////////////
	//This method returns the correspondent Tipo Documento picklist value in Salesforce based on codes in SAP campo STCDT
    public static String getTipoDocumentoSAP_To_SF(String Code){
        switch on Code {
            when '13' {	return 'Cédula de ciudadanía';        }	
            when '22' {	return 'Cédula de extranjería';       }
            when '42' {	return 'Código de NIT de extranjería';}
            when '31' {	return 'NIT';           }
            when '41' {	return 'Pasaporte';         }
            when '44' {	return 'Sociedad extranjera sin NIT'; }
            when '12' {	return 'Tarjeta de identidad';        }
            when '21' {	return 'Tarjeta de extranjería';      }
            when else {	return '';   }//NUIP No está codificado
		}
    }
    
    //This method returns the correspondent Tipo Documento Code in SAP based on picklist value in Salesforce campo STCDT
    public static String getTipoDocumentoSF_To_SAP(String Code){
        switch on Code {
            when 'Cédula de ciudadanía' 		{	return '13';}	
            when 'Cédula de extranjería' 		{	return '22';}
            when 'Código de NIT de extranjería' {	return '42';}
            when 'NIT' 							{	return '31';}
            when 'Pasaporte' 					{	return '41';}
            when 'Sociedad extranjera sin NIT' 	{	return '44';}
            when 'Tarjeta de identidad' 		{	return '12';}
            when 'Tarjeta de extranjería' 		{	return '21';}
            when else {	return '';   }//NUIP No está codificado
		}
    }
    
    //This method returns the correspondent Salutation picklist value in Salesforce based on codes in SAP, campo ANRED
    public static String getSalutationSAP_To_SF(String Code){
        switch on Code {
            when '0001'{ return 'Sra.';}//'Señora';   }	
            when '0002'{ return 'Sr.';}//'Señor';    }
            when '0003'{ return 'Empresa'; 	}
            when '0004'{ return 'Señorita';	}
            when else {	 return '';         }
		}
    }
    
    //This method returns the correspondent Salutation SAP Code based on picklist value in Salesforce, campo ANRED
    public static String getSalutationSF_To_SAP(String Salutation){
        switch on Salutation {
            when 'Sra.'	{ return '0001';   }	
            when 'Sr.'	{ return '0002';    }
            when 'Empresa'	{ return '0003'; 	}
            when 'Señorita'	{ return '0004';	}
            when else {	 return '';         }
		}
    }
    
    //METHODS FOR UNOEE
    //This method returns the correspondent Tipo Documento Code in UNOEE based on picklist value in Salesforce campo STCDT
    public static String getTipoDocumentoSF_To_UNOEE(String Code){
        switch on Code {
            when 'Cédula de ciudadanía' 		{	return 'C';}	
            when 'Cédula de extranjería' 		{	return 'E';}
            when 'Código de NIT de extranjería' {	return 'D';}
            when 'NIT' 							{	return 'N';}
            when 'Pasaporte' 					{	return 'P';}
            when 'Sociedad extranjera sin NIT' 	{	return 'X';}
            when 'Tarjeta de identidad' 		{	return 'T';}
            when 'Tarjeta de extranjería' 		{	return 'J';}
            when else {	return '';   }//NUIP No está codificado
		}
    }
    
    public static String getTipoDocumentoUNOEE_To_SF(String Code){
        switch on Code {
            when 'C' {	return 'Cédula de ciudadanía';        }	
            when 'E' {	return 'Cédula de extranjería';       }
            when 'D' {	return 'Código de NIT de extranjería';}
            when 'N' {	return 'NIT';           }
            when 'P' {	return 'Pasaporte';         }
            when 'X' {	return 'Sociedad extranjera sin NIT'; }
            when 'T' {	return 'Tarjeta de identidad';        }
            when 'J' {	return 'Tarjeta de extranjería';      }
            when else {	return '';   }//NUIP No está codificado
		}
    }
    
    /////////////////////////////////////END OF UTILITIES FOR WEB SERVICE ACCOUNT/////////////////////////////////////////////

    /**
     * Método para ingresar registros de logs en Salesforce
     */
    public static List<Database.SaveResult> insertLog(List<Log__c> logs) {
        return Database.insert(logs, false);
    }
}