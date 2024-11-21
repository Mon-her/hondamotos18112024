/**
* Fanalca
* @author           Juan Ansaldi
* Description:      Test class for AutosClienteSOAPWS integration.
*
* Changes (Version)
* -------------------------------------
*           No.     Date            Author                  Description
*           -----   ----------      --------------------    ---------------
* @version  1.0     11/11/2020      Juan Ansaldi            Class definition.
* @version  1.1     12/11/2020      Juan Ansaldi            Class finished testing succesfully 100% class AutosProductosSOAPWS.
*********************************************************************************************************/
@isTest
public class AutosProductosSOAPWS_Test {
    @isTest
    private static void TestCrearProducto(){
        list<AutosProductosSOAPWS.AutosProductoWS> lstProductosWS = new list<AutosProductosSOAPWS.AutosProductoWS>();
        AutosProductosSOAPWS.AutosProductoWS ProductoWS = new AutosProductosSOAPWS.AutosProductoWS();
        
        ProductoWS.f120_descripcion_corta = 'Honda CRV 12';
        ProductoWS.f121_ind_estado = '0';
        ProductoWS.f120_id = '008670';
        ProductoWS.f120_descripcion = 'La mejor camioneta del mundo';
        ProductoWS.f120_referencia = 'Alguna referencia';
        //objProProductoWS.f125_id_plan;
        ProductoWS.f200_linea = 'Honda';
        ProductoWS.f300_grupo = 'Nuevo';
        ProductoWS.f350_ancho = 'Testing';
        ProductoWS.f400_forma = '2020';
        ProductoWS.f500_subclase = '2000';
        ProductoWS.f550_largo = '5';
        ProductoWS.H30_Honda_modelos_autos = 'Linea 1';
        ProductoWS.H40_familia_de_vehiculos = 'Familia 1';
        ProductoWS.H80_Honda_proveedores = 'Test origen';
        ProductoWS.I01_Alto_y_Origen = 'Test';
        ProductoWS.SGA_Hac_Prod_Subsegmento = 'Test';
        ProductoWS.TVA_Hac_prod_tipo_venta = 'Test';
        ProductoWS.ZAD_Hac_prod_Color = 'Blanco';     
        ProductoWS.f104_id_vehiculo = 'Test';
        ProductoWS.f104_id_motor = 'Test';
        ProductoWS.f104_id_chasis = 'Test';
        ProductoWS.f104_id_caja = 'Test';
        ProductoWS.f104_id_modelo = '121';
        ProductoWS.f104_id_pasajeros = '4';
        ProductoWS.f104_id_servicio = 'Test';
        ProductoWS.f104_id_fasecolda = 'Test';
        ProductoWS.f104_id_fecha_compra = '04/02/2020';
        ProductoWS.f104_id_combustible = 'Test';
        ProductoWS.f104_id_traccion = 'Test';
        ProductoWS.f104_id_placa = 'Test'; 
		ProductoWS.f104_id_marca = 'Test'; 
        ProductoWS.f104_id_linea = 'Test'; 
        ProductoWS.f104_id_carroceria = 'Test'; 
        ProductoWS.f104_id_cilindraje = 'Test'; 
        ProductoWS.f104_id_extension_color = 'Test'; 
        ProductoWS.referencia_comercial = 'Test';
        
    	lstProductosWS.add(ProductoWS);
        
        AutosProductosSOAPWS.CrearProducto(lstProductosWS);
        
        //Reenviar el mismo producto para ocasionar error de codigo repetido
        lstProductosWS[0].f121_ind_estado = '1';
        AutosProductosSOAPWS.CrearProducto(lstProductosWS);
        
        AutosProductosSOAPWS.AutosProductoWS ProductoWS1 = ProductoWs;
        ProductoWS1.f104_id_modelo = '1111111111111111111111111111';
        AutosProductosSOAPWS.CrearProducto(lstProductosWS);
        
        //Enviar producto vacío para ocasionar error que entra al catch
        AutosProductosSOAPWS.AutosProductoWS productoVacio = new AutosProductosSOAPWS.AutosProductoWS();
        AutosProductosSOAPWS.CrearProducto(new list<AutosProductosSOAPWS.AutosProductoWS>{productoVacio});
    }
    
    private static testmethod void TestModificarProducto(){
        list<AutosProductosSOAPWS.AutosProductoWS> lstProductosWS = new list<AutosProductosSOAPWS.AutosProductoWS>();
        AutosProductosSOAPWS.AutosProductoWS productoWS = new AutosProductosSOAPWS.AutosProductoWS();
        
        ProductoWS.f120_descripcion_corta = 'Honda CRV 12';
        ProductoWS.f121_ind_estado = '0';
        ProductoWS.f120_id = '008670';
        ProductoWS.f120_descripcion = 'La mejor camioneta del mundo';
        ProductoWS.f120_referencia = 'Alguna referencia';
        //objProProductoWS.f125_id_plan;
        ProductoWS.f200_linea = 'Honda';
        ProductoWS.f300_grupo = 'Nuevo';
        ProductoWS.f350_ancho = 'Testing';
        ProductoWS.f400_forma = '2020';
        ProductoWS.f500_subclase = '2000';
        ProductoWS.f550_largo = '5';
        ProductoWS.H30_Honda_modelos_autos = 'Linea 1';
        ProductoWS.H40_familia_de_vehiculos = 'Familia 1';
        ProductoWS.H80_Honda_proveedores = 'Test origen';
        ProductoWS.I01_Alto_y_Origen = 'Test';
        ProductoWS.SGA_Hac_Prod_Subsegmento = 'Test';
        ProductoWS.TVA_Hac_prod_tipo_venta = 'Test';
        ProductoWS.ZAD_Hac_prod_Color = 'Blanco';     
        ProductoWS.f104_id_vehiculo = 'Test';
        ProductoWS.f104_id_motor = 'Test';
        ProductoWS.f104_id_chasis = 'Test';
        ProductoWS.f104_id_caja = 'Test';
        ProductoWS.f104_id_modelo = '121';
        ProductoWS.f104_id_pasajeros = '4';
        ProductoWS.f104_id_servicio = 'Test';
        ProductoWS.f104_id_fasecolda = 'Test';
        ProductoWS.f104_id_fecha_compra  = '04/02/2020';
        ProductoWS.f104_id_combustible = 'Test';
        ProductoWS.f104_id_traccion = 'Test';
        ProductoWS.f104_id_placa = 'Test'; 
        ProductoWS.f104_id_marca = 'Test'; 
        ProductoWS.f104_id_linea = 'Test'; 
        ProductoWS.f104_id_carroceria = 'Test'; 
        ProductoWS.f104_id_cilindraje = 'Test'; 
        ProductoWS.f104_id_extension_color = 'Test'; 
        ProductoWS.referencia_comercial = 'Test';
        
    	lstProductosWS.add(ProductoWS);
        
        AutosProductosSOAPWS.CrearProducto(lstProductosWS);
        
        ProductoWS.f120_id = '008670';
        ProductoWS.f121_ind_estado = '1';
        AutosProductosSOAPWS.ModificarProducto(lstProductosWS);
        
        ProductoWS.f120_id = '008670';
        ProductoWS.f121_ind_estado = '0';
        AutosProductosSOAPWS.ModificarProducto(lstProductosWS);
        
        ProductoWS.f120_id = '008672';
        ProductoWS.f121_ind_estado = '0';
        ProductoWS.f350_ancho = 'This field should be longer than 255 characters, how many characters do you think is this string? can you guess? come on, make a prediction or an estimation..................................................................................';
        AutosProductosSOAPWS.ModificarProducto(lstProductosWS);
        
        //Enviar producto vacío para ocasionar error que entra al catch
        AutosProductosSOAPWS.AutosProductoWS productoVacio = new AutosProductosSOAPWS.AutosProductoWS();
        AutosProductosSOAPWS.ModificarProducto(new list<AutosProductosSOAPWS.AutosProductoWS>{productoVacio});
    }
    
    private static testmethod void TestPrice(){
        //list<AutosProductosSOAPWS.PrecioWS> lstProductosWS = new list<AutosProductosSOAPWS.PrecioWS>();
        AutosProductosSOAPWS.PrecioWS PrecioWS = new AutosProductosSOAPWS.PrecioWS();
        
        Pricebook2 pricebk = new Pricebook2();
        pricebk.Name = 'PB test';
        pricebk.IsActive = true;
        insert pricebk;
        
        Pricebook2 standardPricebook = new Pricebook2(  
            Id = Test.getStandardPricebookId(),
            IsActive = true
        );
        
        //Execute an update DML on the Pricebook2 record, to make IsStandard to true
        
        Update standardPricebook;
         RecordType rtProductoAutos = [select Id, name from recordType where sobjecttype='Product2' and name like '%auto%' limit 1];
    
        Product2 producto = new Product2();
        producto.Name = 'Honda CRV Test';
        producto.ProductCode = '001';
        producto.IsActive = true;
        producto.RecordTypeId = rtProductoAutos.Id;
        insert producto;
         
        PrecioWS.f126_id_lista_precio = [select name from Pricebook2 where name = 'PB test' limit 1].Name;
        PrecioWS.f126_referencia_item = '001';
        PrecioWS.f126_precio = '1000000';
        PrecioWS.f126_fecha_activacion = '20201111';
        PrecioWS.f126_fecha_inactivacion = '';
        
        AutosProductosSOAPWS.setPriceAuto(PrecioWS);
        
        PrecioWS.f126_fecha_inactivacion = '20201112'; 
        AutosProductosSOAPWS.setPriceAuto(PrecioWS);
        
        PrecioWS.f126_precio =  '100000000000000000000';
        AutosProductosSOAPWS.setPriceAuto(PrecioWS);
        
        //Enviar producto vacío para ocasionar error que entra al catch
        AutosProductosSOAPWS.PrecioWS productoVacio = new AutosProductosSOAPWS.PrecioWS();
        AutosProductosSOAPWS.setPriceAuto(productoVacio);
    }
}