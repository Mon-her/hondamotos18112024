@isTest
public class AutosVehiculosSOAPWS_Test {
    private static testmethod void testearAdd(){
        Account a = new Account(); 
        a.AM_Numero_de_documento__c = '25974151';
        a.recordTypeID = [select Id from Recordtype where developerName = 'AM_CUE_Cuenta_empresarial' and sobjecttype ='Account'].Id;
        a.AM_Tipo_de_documento__c = 'NIT';                                     
        a.Name = 'Empresa';
        a.MC_Correo_electronico_Empresa__c = 'email@email.com';
        insert a;
        
        list<AutosVehiculosSOAPWS.VehiculosWS> lstWS = new list<AutosVehiculosSOAPWS.VehiculosWS>();
        AutosVehiculosSOAPWS.VehiculosWS v = new AutosVehiculosSOAPWS.VehiculosWS();
        v.F926_ID_PROPIETARIO = '25974151';
        v.F926_MATRICULA ='M0001';
        v.F926_NRO_SERIE = '123456'; //debe ser 6 digitos, si no marca error
        v.F926_ID_TIPO_VEHICULO = 1;
        v.F926_NRO_CHASIS = '1234567890';
        v.F926_MODELO ='Model1';
        v.F926_ANO = 2021;
        v.F926_IND_ESTADO_BLOQUEADO = 0;
        lstWS.add(v);
    
		//Falta ver de dónde sale el name ya que es requerido
        //Respuesta exitosa
        AutosVehiculosSOAPWS.VehiculosAdd(lstWS);
        
        //Respuesta de fallo, por VR de Vin o numero serie
        v.F926_NRO_SERIE = '1234567'; //debe ser 6 digitos, si no marca error
        AutosVehiculosSOAPWS.VehiculosAdd(lstWS);
        
        AutosVehiculosSOAPWS.VehiculosWS wsEmpty; //= new AutosVehiculosSOAPWS.VehiculosWS();
        AutosVehiculosSOAPWS.VehiculosAdd(new list<AutosVehiculosSOAPWS.VehiculosWS>{wsEmpty});
       /* 
        if (itemWS.F926_ID_PROPIETARIO!=null && itemWS.F926_ID_PROPIETARIO!='' && mapClientes.containsKey(itemWS.F926_ID_PROPIETARIO))  objSF.AccountId = mapClientes.get(itemWS.F926_ID_PROPIETARIO).Id;
        objSF.Placa__c = itemWS.F926_MATRICULA;
        objSF.VIN__c = itemWS.F926_NRO_SERIE;
        objSF.Tipo_Vehiculo__c = itemWS.F926_ID_TIPO_VEHICULO ==1 ? 'VEHICULOS HONDA' : (itemWS.F926_ID_TIPO_VEHICULO==2 ? 'VEHICULOS OTRAS MARCA' : '');
            objSF.Numero_Chasis__c = itemWS.F926_NRO_CHASIS;
        objSF.Modelo__c = itemWS.F926_MODELO;
        objSF.Ano__c = itemWS.F926_ANO;
        objSF.Estado_Bloqueado__c = itemWS.F926_IND_ESTADO_BLOQUEADO==1 ? true : false;
        objSF.Plan_105__c = itemWS.F927_ID_PLAN_105;
        objSF.Mayor_105__c = itemWS.F927_ID_MAYOR_105;
        objSF.Plan_106__c = itemWS.F927_ID_PLAN_106;
        objSF.Mayor_106__c = itemWS.F927_ID_MAYOR_106;
        objSF.Plan_107__c = itemWS.F927_ID_PLAN_107;
        objSF.Plan_110__c = itemWS.F927_ID_PLAN_110;
        objSF.Mayor_110__c = itemWS.F927_ID_MAYOR_110;
        objSF.Plan_111__c = itemWS.F927_ID_PLAN_111;
        objSF.Mayor_111__c = itemWS.F927_ID_MAYOR_111;
        objSF.Plan_112__c = itemWS.F927_ID_PLAN_112;
        objSF.RecordTypeId= rtAutosAsset.Id;
        */
    }
    
    private static testmethod void testearUpdate(){
        Account a = new Account(); 
        a.AM_Numero_de_documento__c = '25974151';
        a.recordTypeID = [select Id from Recordtype where developerName = 'AM_CUE_Cuenta_empresarial' and sobjecttype ='Account'].Id;
        a.AM_Tipo_de_documento__c = 'NIT';                                     
        a.Name = 'Empresa';
        a.MC_Correo_electronico_Empresa__c = 'email@email.com';
        insert a;
        
        list<AutosVehiculosSOAPWS.VehiculosWS> lstWS = new list<AutosVehiculosSOAPWS.VehiculosWS>();
        AutosVehiculosSOAPWS.VehiculosWS v = new AutosVehiculosSOAPWS.VehiculosWS();
        v.F926_ID='1234';
        v.F926_ID_PROPIETARIO = '25974151';
        v.F926_MATRICULA ='M0001';
        v.F926_NRO_SERIE = '123456'; //debe ser 6 digitos, si no marca error
        v.F926_ID_TIPO_VEHICULO = 1;
        v.F926_NRO_CHASIS = '1234567890';
        v.F926_MODELO ='Model1';
        v.F926_ANO = 2021;
        v.F926_IND_ESTADO_BLOQUEADO = 0;
        lstWS.add(v);
    
		//Agregar un vehiculo, para luego actualizarlo mediante el metodo de update del ws
        AutosVehiculosSOAPWS.VehiculosAdd(lstWS);
        
        AutosVehiculosSOAPWS.VehiculosUpdate(lstWS);
        
        //entra al error de update al mandar un numero de serie invalido
        lstWS[0].F926_NRO_SERIE='1234567';
        AutosVehiculosSOAPWS.VehiculosUpdate(lstWS);
        
        //Entra al catch al mandar un elemento vacío
        AutosVehiculosSOAPWS.VehiculosWS wsEmpty; 
        AutosVehiculosSOAPWS.VehiculosUpdate(new list<AutosVehiculosSOAPWS.VehiculosWS>{wsEmpty});
    }
}