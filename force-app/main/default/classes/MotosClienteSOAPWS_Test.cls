@isTest
public class MotosClienteSOAPWS_Test {
    @testSetup 
    static void setUp() {
        //Crear Municipios
       // AM_Municipio__c[] municipios = TestDataUtilityClass.CrearMunicipios(1);      
    }
    
    private static testmethod void testearAddOK(){
        //mock to test soap call, in this case, will be a dml exception by a validation rule, Error: El nombre de la cuenta debe contener letras, número y ser mayor a 2 en cantidad de caracteres
        list<MotosClienteSOAPWS.ClienteWS> lstClientesWS= new list<MotosClienteSOAPWS.ClienteWS>();
        MotosClienteSOAPWS.ClienteWS accWSJuridico = new MotosClienteSOAPWS.ClienteWS();
        accWSJuridico.ADR6_SMTP_ADDR = 'jparrales@fastcloudconsulting.com';
        accWSJuridico.KNA1_ANRED='0002';
        accWSJuridico.KNA1_CEL_NUMBER='88885566';
        accWSJuridico.KNA1_KUNNR_KNA1_STCD1='';
        accWSJuridico.KNA1_LAND1='';
        accWSJuridico.KNA1_NAME1='Jonathan Parrales2020';
        accWSJuridico.KNA1_NAME3_SEGMENTO1='Jonathan';
        accWSJuridico.KNA1_NAME3_SEGMENTO2='Philip';
        accWSJuridico.KNA1_NAME4_SEGMENTO1='Parrales';
        accWSJuridico.KNA1_NAME4_SEGMENTO2='Duarte';
        accWSJuridico.KNA1_ORT01='12';
        accWSJuridico.KNA1_REGIO='0';
        accWSJuridico.KNA1_SKFTO='';
        accWSJuridico.KNA1_STCD1='123456789';
        accWSJuridico.KNA1_STCDT='13';
        accWSJuridico.KNA1_STREET='Calle de las Sirenas';
        accWSJuridico.KNA1_TELF1='2222222';
        accWSJuridico.KNA1_STKZN =''; //Marcar con X para persona natural
        
        List<AM_Municipio__c> mun = TestDataUtilityClass.crearMunicipios(1);
            accWSJuridico.KNA1_ORT01 = mun[0].ID_POBLACION_SAP__c; accWSJuridico.KNA1_REGIO = mun[0].ID_REGION_SAP__c;
        
        //MotosClienteSOAPWS.ClienteWS accWSJuridico1 = accWSJuridico;
        lstClientesWS.add(accWSJuridico);
        
        //MotosClienteSOAPWS.ClienteWS accWSNaturalSr = accWSJuridico;
        //accWSNaturalSr.KNA1_STKZN = 'X';
        //lstClientesWS.add(accWSNaturalSr);
        
        //MotosClienteSOAPWS.ClienteWS accWSNaturalSraTD22 = accWSNaturalSr;
        //accWSNaturalSraTD22.KNA1_ANRED ='0001';
        //accWSNaturalSraTD22.KNA1_STCDT ='22';
       // lstClientesWS.add(accWSNaturalSraTD22);
        
        //MotosClienteSOAPWS.ClienteWS accWSNaturalSritaTD21 = accWSNaturalSr;
        //accWSNaturalSritaTD21.KNA1_ANRED ='0004';
        //accWSNaturalSritaTD21.KNA1_STCDT ='21';
        //lstClientesWS.add(accWSNaturalSritaTD21);
        

        MotosClienteSOAPWS.clienteAdd(lstClientesWS );
        
        //Testear error de duplicate, enviando la misma cuenta
        MotosClienteSOAPWS.clienteAdd(lstClientesWS ); 
        
        system.debug('accWSJuridico' + accWSJuridico);
        
        //Enviar Cliente Natural
        accWSJuridico.KNA1_STKZN = 'X';
        MotosClienteSOAPWS.clienteAdd(lstClientesWS ); 
        
        //Crear otro municipio para el mismo departamento
        AM_Municipio__c a = new AM_Municipio__c();
            a.Name = 'Municipio777';
            a.AM_Nombre_departamento__c = 'Departamento1 ';
         	a.AM_Codigo_DANE_departamento__c = '0';
            a.AM_Codigo_DANE_municipio__c = '777';
            a.ID_REGION_SAP__c = '0';
            a.ID_POBLACION_SAP__c = '777';
            a.AM_Codigo_SIPRES_departamento__c = '0';
            a.AM_Codigo_SIPRES_municipio__c = '0';
        insert a; 
        
        MotosClienteSOAPWS.ClienteWS accWSMun1 = new MotosClienteSOAPWS.ClienteWS();
        accWSMun1.ADR6_SMTP_ADDR = 'jparralesmun@fastcloudconsulting.com';
        accWSMun1.KNA1_ANRED='0002';
        accWSMun1.KNA1_CEL_NUMBER='88885566';
        accWSMun1.KNA1_KUNNR_KNA1_STCD1='';
        accWSMun1.KNA1_LAND1='';
        accWSMun1.KNA1_NAME1='Cliente Juridico';
        //accWSMun1.KNA1_NAME3_SEGMENTO1='Jonathan';
        //accWSMun1.KNA1_NAME3_SEGMENTO2='Philip';
        //accWSMun1.KNA1_NAME4_SEGMENTO1='Parrales';
        //accWSMun1.KNA1_NAME4_SEGMENTO2='Duarte';
        accWSMun1.KNA1_ORT01='777';
        accWSMun1.KNA1_REGIO='0';
        accWSMun1.KNA1_SKFTO='';
        accWSMun1.KNA1_STCD1='123456789';
        accWSMun1.KNA1_STCDT='13';
        accWSMun1.KNA1_STREET='Calle de las Sirenas';
        accWSMun1.KNA1_TELF1='2222222';
        accWSMun1.KNA1_STKZN =''; //Marcar con X para persona natura
        lstClientesWS.add(accWSMun1);
        //system.debug([select id, AM_Codigo_DANE_municipio__c,AM_Codigo_DANE_departamento__c from AM_Municipio__c]);
        //lstClientesWS[0].KNA1_ORT01= '777'; system.debug('lstClientesWS: ' + lstClientesWS[0]); 
        //system.debug('lstClientesWS: ' + lstClientesWS[1]);
        MotosClienteSOAPWS.clienteAdd(lstClientesWS );
        

    	//Enviar Cliente Natural sin numero de documento pero si con tipo de documento
        accWSJuridico.KNA1_STKZN = 'X';
        accWSJuridico.KNA1_STCD1='';
        accWSJuridico.FNACIM = '2000-01-30';
        MotosClienteSOAPWS.clienteAdd(lstClientesWS ); 
        
        //Error de ciudad no encontrada
        accWSJuridico.KNA1_ORT01 = '778889995';
        MotosClienteSOAPWS.clienteAdd(lstClientesWS ); 
    }
    
    private static testmethod void testearAddErrorAccName(){
        //mock to test soap call, in this case, will be a dml exception by a validation rule, Error: El nombre de la cuenta debe contener letras, número y ser mayor a 2 en cantidad de caracteres
        MotosClienteSOAPWS.ClienteWS accWS = new MotosClienteSOAPWS.ClienteWS();
        MotosClienteSOAPWS.clienteAdd(new list<MotosClienteSOAPWS.ClienteWS> {accWS} );
    }
    
    private static testmethod void testearUpdateOK(){
        //mock to test soap call, in this case, will be a dml exception by a validation rule, Error: El nombre de la cuenta debe contener letras, número y ser mayor a 2 en cantidad de caracteres
        list<MotosClienteSOAPWS.ClienteWS> lstClientesWS= new list<MotosClienteSOAPWS.ClienteWS>();
        MotosClienteSOAPWS.ClienteWS accWSJuridico = new MotosClienteSOAPWS.ClienteWS();
       
        
        TestDataUtilityClass.crearClienteMotos(Label.MotosRecordTypeDevNameAccountJuridica, 2);
        TestDataUtilityClass.crearClienteMotos(Label.MotosRecordTypeDevNameAccountNatural, 1);    
        for (Account acc: [select Id, RecordType.DeveloperName, Name, MC_Correo_electronico_Empresa__c, 
                           Salutation, Primer_Nombre__c,FirstName,Segundo_Nombre__c,LastName,Primer_Apellido__c,Segundo_Apellido__c,
                           PersonEmail,AM_Tipo_de_documento__c,AM_Numero_de_documento__c,Phone,
                           AM_Ciudad__r.ID_POBLACION_SAP__c,AM_Ciudad__r.ID_REGION_SAP__c,DireccionERP__c,Fax,AM_Estado__c 
                          from Account]){
            MotosClienteSOAPWS.ClienteWS clientews = new MotosClienteSOAPWS.ClienteWS();
            system.debug('Test: dentro de for para enviar a update');
            clienteWS.KNA1_KUNNR_KNA1_STCD1 = acc.Id;
            clienteWS.KNA1_STCDT = Utilities.getTipoDocumentoSF_To_SAP(acc.AM_Tipo_de_documento__c);
            clienteWS.KNA1_STCD1 = acc.AM_Numero_de_documento__c;               
            clienteWS.KNA1_CEL_NUMBER = acc.Phone;
            clienteWS.KNA1_ORT01 = acc.AM_Ciudad__r.ID_POBLACION_SAP__c;
            clienteWS.KNA1_REGIO = acc.AM_Ciudad__r.ID_REGION_SAP__c;
            clienteWS.KNA1_STREET = acc.DireccionERP__c;
            clienteWS.KNA1_TELF1 = acc.Fax;
            if (acc.AM_Estado__c=='Inactivo')    clienteWS.KNA1_SKFTO='X';               
            clienteWS.KNA1_NAME1 = acc.Name; system.debug('acc Name ' + acc.Name);
            if (acc.RecordType.DeveloperName==Label.MotosRecordTypeDevNameAccountNatural){
                clienteWS.KNA1_STKZN = 'X';
                
                clienteWS.ADR6_SMTP_ADDR = acc.MC_Correo_electronico_Empresa__c; 
            }
            if (acc.RecordType.DeveloperName==Label.MotosRecordTypeDevNameAccountJuridica){
                acc.Salutation = Utilities.getSalutationSF_To_SAP(clienteWS.KNA1_ANRED); //mapeo, en el doc dice char 4 y en sf es un picklist señra,señor
                clienteWS.KNA1_NAME3_SEGMENTO1 = acc.Primer_Nombre__c;
                //clienteWS.KNA1_NAME3_SEGMENTO1 = acc.FirstName;
                clienteWS.KNA1_NAME3_SEGMENTO2 = acc.Segundo_Nombre__c;
                clienteWS.KNA1_NAME4_SEGMENTO1 = acc.LastName;
                //clienteWS.KNA1_NAME4_SEGMENTO1 = acc.Primer_Apellido__c;
                clienteWS.KNA1_NAME4_SEGMENTO2 = acc.Segundo_Apellido__c;
                clienteWS.ADR6_SMTP_ADDR = acc.PersonEmail;
            }
                              
            lstClientesWS.add(clienteWS);                  
        }
        
        
        MotosClienteSOAPWS.clienteUpdate(lstClientesWS );
     
        //Crear Error de duplicado por actualizacion
        lstClientesWS[0].KNA1_STCD1 = lstClientesWS[1].KNA1_STCD1; //se crearon 2 registros de juridicos primero, al primer registro le paso el numero de identificacion del 2do
        lstClientesWS[2].FNACIM = '2000-01-30';
        MotosClienteSOAPWS.clienteUpdate(lstClientesWS );
    
        //Para que entre en la linea del for de municipios cuando ya existe el departamento y entonces agrega otro municipio
        //Crear otro municipio para el mismo departamento
        AM_Municipio__c a = new AM_Municipio__c();
            a.Name = 'Municipio777';
            a.AM_Nombre_departamento__c = 'Departamento1 ';
        	a.ID_REGION_SAP__c = '0';
            a.ID_POBLACION_SAP__c = '777';
            a.AM_Codigo_DANE_departamento__c = '0';
            a.AM_Codigo_DANE_municipio__c = '777';
            a.AM_Codigo_SIPRES_departamento__c = '0';
            a.AM_Codigo_SIPRES_municipio__c = '0';
        insert a; 
        //system.debug([select id, AM_Codigo_DANE_municipio__c,AM_Codigo_DANE_departamento__c from AM_Municipio__c]);
        lstClientesWS[0].KNA1_ORT01= '777'; //system.debug('lstClientesWS: ' + lstClientesWS[0]); 
        //system.debug('lstClientesWS: ' + lstClientesWS[1]);
        MotosClienteSOAPWS.clienteUpdate(lstClientesWS );
        
        //Error de ciudad no encontrada
		lstClientesWS[0].KNA1_ORT01= '777888999'; 
        MotosClienteSOAPWS.clienteUpdate(lstClientesWS );
    }
    
    private static testmethod void testearUpdateErrorCatch(){
        list<MotosClienteSOAPWS.ClienteWS> lstClientesWS= new list<MotosClienteSOAPWS.ClienteWS>();
        MotosClienteSOAPWS.ClienteWS accWS = new MotosClienteSOAPWS.ClienteWS();
        lstClientesWS.add(accWS);
        MotosClienteSOAPWS.clienteUpdate(lstClientesWS );
    }
}