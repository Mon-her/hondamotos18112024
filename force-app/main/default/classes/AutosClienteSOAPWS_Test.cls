/**
* Fanalca
* @author           Juan Ansaldi
* Description:      Test class for AutosClienteSOAPWS integration.
*
* Changes (Version)
* -------------------------------------
*           No.     Date            Author                  Description
*           -----   ----------      --------------------    ---------------
* @version  1.0     05/11/2020      Juan Ansaldi            Class definition.
* @version  1.1     06/11/2020      Juan Ansaldi            Class finished testing succesfully 100% class AutosClienteSOAPWS.
*********************************************************************************************************/
@isTest
public class AutosClienteSOAPWS_Test {
    
    //Method for creating test data
    @testSetup 
    static void setUp() {
        //Create Municipios
        List<AM_Municipio__c> municipios = TestDataUtilityClass.CrearMunicipios(9); 
        //Create Cuentas
        /*String pjRecordTypeID = [SELECT id FROM RecordType WHERE developerName = 'AM_CUE_Cuenta_empresarial' and sobjecttype ='Account'].Id;
        String pnRecordTypeID = [SELECT id FROM RecordType WHERE developerName = 'AM_CUE_Persona_natural' and sobjecttype ='Account'].Id;*/
        List<Account> cuentaPJ = TestDataUtilityClass.crearCuentasAutos(2, Label.AutosRecordTypeDevNameAccountJuridica);
        List<Account> cuentaPN = TestDataUtilityClass.crearCuentasAutos(2, Label.AutosRecordTypeDevNameAccountNatural);
    }
    
    private static testmethod void TestCrearCliente(){
		list<AutosClienteSOAPWS.AutosClienteWS> lstClientesWS = new list<AutosClienteSOAPWS.AutosClienteWS>();
        //PERSONA JURIDICA
        AutosClienteSOAPWS.AutosClienteWS accWSJuridico = new AutosClienteSOAPWS.AutosClienteWS();
        
        accWSJuridico.F201_ID_SF = '123';
        accWSJuridico.F200_IND_TIPO_TERCERO = '2';
        accWSJuridico.F207_ID_CRITERIO_MAYOR = 'Si';
        accWSJuridico.F201_IND_ESTADO_ACTIVO = '0';
        accWSJuridico.F200_ID_TIPO_IDENT = 'N';
        accWSJuridico.F200_ID = '714569732';
        accWSJuridico.F200_RAZON_SOCIAL = 'Chips Ajoy';
        accWSJuridico.F015_TELEFONO = '754896324';
        accWSJuridico.F015_EMAIL = 'jansaldi@fastcloudconsulting.com';
        accWSJuridico.F015_ID_PAIS = '169';
        accWSJuridico.F015_ID_DEPTO = '10';
        accWSJuridico.F015_ID_CIUDAD = '10';
        accWSJuridico.F015_DIRECCION1 = 'Dirección en Cali';
        accWSJuridico.F015_CELULAR = '3785487921';       
        accWSJuridico.F200_FECHA_NACIMIENTO = '19971230';
        accWSJuridico.F201_ID_SUCURSAL = '158';
        accWSJuridico.F200_IND_ESTADO = '0';

        AutosClienteSOAPWS.AutosClienteWS accWSJuridico1 = accWSJuridico;
        lstClientesWS.add(accWSJuridico1);
        
        AutosClienteSOAPWS.AutosClienteWS accWSJuridico2 = accWSJuridico;
        accWSJuridico.F200_RAZON_SOCIAL = 'Chips Ajoy 1';
        accWSJuridico.F200_ID = '714569731';
        accWSJuridico.F201_IND_ESTADO_ACTIVO = '1';
        accWSJuridico.F200_IND_ESTADO = '1';
        lstClientesWS.add(accWSJuridico2);
        
        AutosClienteSOAPWS.AutosClienteWS accWSJuridico3 = accWSJuridico;
        accWSJuridico.F015_CELULAR = '478548792'; 
        accWSJuridico.F200_ID = '714569731';
        lstClientesWS.add(accWSJuridico3);
        
        //PERSONA NATURAL
        AutosClienteSOAPWS.AutosClienteWS accWSNatural = new AutosClienteSOAPWS.AutosClienteWS();
        
        accWSNatural.F200_IND_TIPO_TERCERO = '1';
        accWSNatural.F207_ID_CRITERIO_MAYOR = 'No';
        accWSNatural.F201_IND_ESTADO_ACTIVO = '0';
        accWSNatural.F200_ID_TIPO_IDENT = 'C';
        accWSNatural.F200_ID = '479453';
        accWSNatural.F200_NOMBRES = 'Jorge Luis';
        accWSNatural.F200_APELLIDO1 = 'Perez';
        accWSNatural.F200_APELLIDO2 = 'Casal';
        accWSNatural.F015_TELEFONO = '4964782';
        accWSNatural.F015_EMAIL = 'jansaldi@fastcloudconsulting.com';
        accWSNatural.F015_ID_PAIS = '169';
        accWSNatural.F015_ID_DEPTO = '1';
        accWSNatural.F015_ID_CIUDAD = '1';
        accWSNatural.F015_DIRECCION1 = 'Dirección en Cali';
        accWSNatural.F015_CELULAR = '3847596127';
        accWSNatural.F200_FECHA_NACIMIENTO = '19971230';
        accWSNatural.F201_ID_SUCURSAL = '001';
        accWSNatural.F200_IND_ESTADO = '0';

        AutosClienteSOAPWS.AutosClienteWS accWSNatural1 = accWSNatural;
        accWSNatural.F015_CELULAR = '478548792';
        lstClientesWS.add(accWSNatural);
        
        AutosClienteSOAPWS.AutosClienteWS accWSNatural2 = accWSNatural;
        accWSNatural.F015_CELULAR = '478548792';
        accWSNatural.F200_FECHA_NACIMIENTO = '19971230';
        lstClientesWS.add(accWSNatural2);

        AM_Municipio__c a = new AM_Municipio__c();
            a.Name = 'Municipio 11';
            a.AM_Nombre_departamento__c = 'Departamento1';
            a.AM_Codigo_DANE_departamento__c = '1';
            a.AM_Codigo_DANE_municipio__c = '10';
            a.AM_Codigo_SIPRES_departamento__c = '0' ;
            a.AM_Codigo_SIPRES_municipio__c = '0';
        insert a;
        AutosClienteSOAPWS.CrearCliente(lstClientesWS);
        AutosClienteSOAPWS.CrearCliente(lstClientesWS);
        
        //Test Catch
        list<AutosClienteSOAPWS.AutosClienteWS> lstClientesWSVacia = new list<AutosClienteSOAPWS.AutosClienteWS>();
        AutosClienteSOAPWS.AutosClienteWS catchEx = new AutosClienteSOAPWS.AutosClienteWS();
        lstClientesWSVacia.add(catchEx);
        AutosClienteSOAPWS.CrearCliente(lstClientesWSVacia);
    }
    
    private static testmethod void TestModificarCliente(){
		list<AutosClienteSOAPWS.AutosClienteWS> lstClientesWS = new list<AutosClienteSOAPWS.AutosClienteWS>();

        //PERSONA JURIDICA        
        for (Account acc: [select Id, RecordType.DeveloperName, recordTypeID, Name, AM_Numero_de_documento__c,
                           MC_Correo_electronico_Empresa__c, Phone, DireccionERP__c, PersonMobilePhone, Sucursal__c,
                           MC_Autoriza_tratardatos_personales__c
                           from Account where RecordType.DeveloperName = 'AM_CUE_Cuenta_empresarial']) {
                               AutosClienteSOAPWS.AutosClienteWS accWSJuridico = new AutosClienteSOAPWS.AutosClienteWS();
                               accWSJuridico.F201_ID_SF = acc.Id;
                               accWSJuridico.F200_IND_TIPO_TERCERO = '2';
                               accWSJuridico.F207_ID_CRITERIO_MAYOR = 'Si';
                               accWSJuridico.F201_IND_ESTADO_ACTIVO = '0';
                               accWSJuridico.F200_ID_TIPO_IDENT = 'N';
                               accWSJuridico.F200_ID = acc.AM_Numero_de_documento__c;
                               accWSJuridico.F200_RAZON_SOCIAL = acc.Name;
                               accWSJuridico.F015_TELEFONO = acc.Phone;
                               accWSJuridico.F015_EMAIL = acc.MC_Correo_electronico_Empresa__c;
                               accWSJuridico.F015_ID_PAIS = '169';
                               accWSJuridico.F015_ID_DEPTO = '1';
                               accWSJuridico.F015_ID_CIUDAD = '1';
                               accWSJuridico.F015_DIRECCION1 = acc.DireccionERP__c;
                               accWSJuridico.F015_CELULAR = acc.PersonMobilePhone;       
                               accWSJuridico.F200_FECHA_NACIMIENTO = '19971230';
                               accWSJuridico.F201_ID_SUCURSAL = acc.Sucursal__c;
                               accWSJuridico.F200_IND_ESTADO = '0';
                               AutosClienteSOAPWS.AutosClienteWS accWSJuridico1 = accWSJuridico;
                               lstClientesWS.add(accWSJuridico1); 
                               
                           }
        
        lstClientesWS[1].F201_IND_ESTADO_ACTIVO = '1';
        lstClientesWS[1].F200_IND_ESTADO = '1';
        lstClientesWS[1].F015_ID_DEPTO = '10';
        lstClientesWS[1].F015_ID_CIUDAD = '10';
        lstClientesWS[1].F200_ID_TIPO_IDENT = 'N';
        lstClientesWS[1].F200_ID = lstClientesWS[0].F200_ID;
        lstClientesWS[1].F201_ID_SUCURSAL = lstClientesWS[0].F201_ID_SUCURSAL;

        //PERSONA NATURAL
        for (Account acc: [select Id, RecordType.DeveloperName, recordTypeID, Name, AM_Numero_de_documento__c,
                           PersonEmail, Phone, DireccionERP__c, PersonMobilePhone, Sucursal__c, AM_Estado__c,
                           MC_Autoriza_tratardatos_personales__c, FirstName, LastName, Segundo_Apellido__c
                           from Account where RecordType.DeveloperName = 'AM_CUE_Persona_natural']) {
                               AutosClienteSOAPWS.AutosClienteWS accWSNatural = new AutosClienteSOAPWS.AutosClienteWS();
                               accWSNatural.F201_ID_SF = acc.Id;
                               accWSNatural.F200_IND_TIPO_TERCERO = '1';
                               accWSNatural.F207_ID_CRITERIO_MAYOR = 'No';
                               accWSNatural.F201_IND_ESTADO_ACTIVO = '0';
                               accWSNatural.F200_ID_TIPO_IDENT = '';
                               accWSNatural.F200_ID = acc.AM_Numero_de_documento__c;
                               accWSNatural.F200_RAZON_SOCIAL = '';
                               accWSNatural.F200_NOMBRES = acc.FirstName;
                               accWSNatural.F200_APELLIDO1 = acc.LastName;
                               accWSNatural.F200_APELLIDO2 = acc.Segundo_Apellido__c;
                               accWSNatural.F015_TELEFONO = acc.Phone;
                               accWSNatural.F015_EMAIL = acc.PersonEmail;
                               accWSNatural.F015_ID_PAIS = '169';
                               accWSNatural.F015_ID_DEPTO = '1';
                               accWSNatural.F015_ID_CIUDAD = '1';
                               accWSNatural.F015_DIRECCION1 = 'Dirección en Cali';
                               accWSNatural.F015_CELULAR = '478548792';//acc.PersonMobilePhone;
                               accWSNatural.F200_FECHA_NACIMIENTO = '19971230';
                               accWSNatural.F201_ID_SUCURSAL = acc.Sucursal__c;
                               accWSNatural.F200_IND_ESTADO = '0';
                               lstClientesWS.add(accWSNatural);
                           }
        
        AM_Municipio__c a = new AM_Municipio__c();
            a.Name = 'Municipio 11';
            a.AM_Nombre_departamento__c = 'Departamento1';
            a.AM_Codigo_DANE_departamento__c = '1';
            a.AM_Codigo_DANE_municipio__c = '10';
            a.AM_Codigo_SIPRES_departamento__c = '0' ;
            a.AM_Codigo_SIPRES_municipio__c = '0';
        insert a;
        
        lstClientesWS[3].F200_FECHA_NACIMIENTO = null;

        AutosClienteSOAPWS.ModificarCliente(lstClientesWS);
        //AutosClienteSOAPWS.ModificarCliente(lstClientesWS);
        
        //Test Catch
        list<AutosClienteSOAPWS.AutosClienteWS> lstClientesWSVacia1 = new list<AutosClienteSOAPWS.AutosClienteWS>();
        AutosClienteSOAPWS.AutosClienteWS catchEx = new AutosClienteSOAPWS.AutosClienteWS();
        lstClientesWSVacia1.add(catchEx);
        AutosClienteSOAPWS.ModificarCliente(lstClientesWSVacia1);
    }
}