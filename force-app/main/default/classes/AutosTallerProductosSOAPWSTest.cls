/**
* Fanalca
* @author           Juan Pablo Rodríguez
* Description:      Test class for AutosTallerProductosSOAPWS integration.
*
* Changes (Version)
* -------------------------------------
*           No.     Date            Author                  Description
*           -----   ----------      --------------------    ---------------
* @version  1.0     21/08/2024      Juan Pablo Rodríguez    Class definition.
* @version  1.1     ##/08/2024      Juan Pablo Rodríguez    Class finished testing succesfully 97% class AutosTallerProductosSOAPWS.
*********************************************************************************************************/
@isTest
private class AutosTallerProductosSOAPWSTest {
    static final String RT_VEHICULO_TALLER = 'Vehiculos_Taller';
    static List<Schema.Location> warehouses;
    static List<Product2> newProducts;
    static List<ProductItem> newInventory;
    
    @TestSetup
    static void dataFactory() {
        // Insert warehouses
        warehouses = new List<Schema.Location> {
            new Schema.Location(
                Name = 'Main Warehouse',
                LocationType = 'Warehouse',
                codigoBodega__c = '99999999',
                IsInventoryLocation = true
            ),
            new Schema.Location(
                Name = 'Virtual Warehouse 99999998',
                LocationType = 'Virtual',
                codigoBodega__c = '99999998',
                IsInventoryLocation = true,
                IsMobile = true
            ),
            new Schema.Location(
                Name = 'Virtual Warehouse 99999997',
                LocationType = 'Virtual',
                codigoBodega__c = '99999997',
                IsInventoryLocation = true,
                IsMobile = true
            ),
            new Schema.Location(
                Name = 'Virtual Warehouse 99999996',
                LocationType = 'Virtual',
                codigoBodega__c = '99999996',
                IsInventoryLocation = true,
                IsMobile = true
            ),
            new Schema.Location(
                Name = 'Virtual Warehouse 99999995',
                LocationType = 'Virtual',
                codigoBodega__c = '99999995',
                IsInventoryLocation = true,
                IsMobile = true
            )
        };
        Insert warehouses;

        // Enable standard pricebook2
        Id pricebookId = Test.getStandardPricebookId();
        Pricebook2 standardPricebook = new Pricebook2(
            Id = pricebookId,
            IsActive = true
        );
        update standardPricebook;

        // Insert new products 
        newProducts = new List<Product2>{
            new Product2(
                RecordTypeId = Schema.SObjectType.Product2.getRecordTypeInfosByDeveloperName().get(RT_VEHICULO_TALLER).getRecordTypeId(),
                IsActive = true,
                Codigo_de_producto__c = '9999980',
                ProductCode = '9999980',
                Description = 'Descripción del producto 9999980',
                Name = 'Producto 9999980',
                Referencia__c = 'Referenia 9999980',
                Referencia_comercial__c = 'Referencia comercial 9999980'
            ),
            new Product2(
                RecordTypeId = Schema.SObjectType.Product2.getRecordTypeInfosByDeveloperName().get(RT_VEHICULO_TALLER).getRecordTypeId(),
                IsActive = true,
                Codigo_de_producto__c = '9999981',
                ProductCode = '9999981',
                Description = 'Descripción del producto 9999981',
                Name = 'Producto 9999981',
                Referencia__c = 'Referenia 9999981',
                Referencia_comercial__c = 'Referencia comercial 9999981'
            )
        };
        Insert newProducts;

        // Insert inventory 
        newInventory = new List<ProductItem>{
            new ProductItem(
                QuantityOnHand = 10,
                LocationId = warehouses.get(0).Id,
                Product2Id = newProducts.get(0).Id
            ),
            new ProductItem(
                QuantityOnHand = 10,
                LocationId = warehouses.get(1).Id,
                Product2Id = newProducts.get(1).Id
            )
        };
        Insert newInventory;
    }

    @IsTest
    static void sendProductEmpty() {
        AutosTallerProductosSOAPWS.AutosProductoResultWS result = new AutosTallerProductosSOAPWS.AutosProductoResultWS();
        Test.startTest();
            result = AutosTallerProductosSOAPWS.sendProduct(new List<AutosTallerProductosSOAPWS.AutosProductoWS>());
        Test.stopTest();
        
        // Assertions
        Assert.areEqual(false, result.operacionExitosa);
        Assert.isTrue(result.mensaje.containsIgnoreCase('La colección de productos recibida está vacía'));
    }

    @IsTest
    static void sendProductValidProducts() {
        List<AutosTallerProductosSOAPWS.InventarioBodegaWS> inv1 = new List<AutosTallerProductosSOAPWS.InventarioBodegaWS>();
        AutosTallerProductosSOAPWS.InventarioBodegaWS invItem1 = new AutosTallerProductosSOAPWS.InventarioBodegaWS();
        invItem1.cantidad = 10;
        invItem1.codigoBodega = '99999999';
        AutosTallerProductosSOAPWS.InventarioBodegaWS invItem2 = new AutosTallerProductosSOAPWS.InventarioBodegaWS();
        invItem2.cantidad = 5;
        invItem2.codigoBodega = '99999998';
        inv1.add(invItem1);
        inv1.add(invItem2);

        List<AutosTallerProductosSOAPWS.AutosProductoWS> products = new List<AutosTallerProductosSOAPWS.AutosProductoWS>();
        AutosTallerProductosSOAPWS.AutosProductoWS product1 = new AutosTallerProductosSOAPWS.AutosProductoWS();
        product1.activo = true;
        product1.codigoProducto = '9999999';
        product1.descripcion = 'Descripción producto 9999999';
        product1.nombre = 'Producto 9999999';
        product1.referencia = 'Referencia producto 9999999';
        product1.referenciaComercial = 'Referencia comercial 9999999';
        product1.inventarioBodegas = inv1;
        AutosTallerProductosSOAPWS.AutosProductoWS product2 = new AutosTallerProductosSOAPWS.AutosProductoWS();
        product2.activo = true;
        product2.codigoProducto = '9999989';
        product2.descripcion = 'Descripción producto 9999989';
        product2.nombre = 'Producto 9999989';
        product2.referencia = 'Referencia producto 9999989';
        product2.referenciaComercial = 'Referencia comercial 9999989';
        product2.inventarioBodegas = inv1;
        AutosTallerProductosSOAPWS.AutosProductoWS product3 = new AutosTallerProductosSOAPWS.AutosProductoWS();
        product3.activo = true;
        product3.codigoProducto = '9999981';
        product3.descripcion = 'Descripción producto 9999981';
        product3.nombre = 'Producto 9999981';
        product3.referencia = 'Referencia producto 9999981';
        product3.referenciaComercial = 'Referencia comercial 9999981';
        product3.inventarioBodegas = inv1;

        products.add(product1);
        products.add(product2);
        products.add(product3);
        AutosTallerProductosSOAPWS.AutosProductoResultWS result = new AutosTallerProductosSOAPWS.AutosProductoResultWS();

        Test.startTest();
            result = AutosTallerProductosSOAPWS.sendProduct(products);
        Test.stopTest();

        // Assertions
        Assert.areEqual(true, result.operacionExitosa);
        Assert.isTrue(result.mensaje.containsIgnoreCase('Productos ingresados/actualizados con éxito'));
    }

    @IsTest
    static void sendProductInvalidInventory() {
        List<AutosTallerProductosSOAPWS.InventarioBodegaWS> inv1 = new List<AutosTallerProductosSOAPWS.InventarioBodegaWS>();
        List<AutosTallerProductosSOAPWS.InventarioBodegaWS> inv2 = new List<AutosTallerProductosSOAPWS.InventarioBodegaWS>();
        AutosTallerProductosSOAPWS.InventarioBodegaWS invItem1 = new AutosTallerProductosSOAPWS.InventarioBodegaWS();
        invItem1.cantidad = 10;
        invItem1.codigoBodega = '99999999';
        AutosTallerProductosSOAPWS.InventarioBodegaWS invItem2 = new AutosTallerProductosSOAPWS.InventarioBodegaWS();
        invItem2.cantidad = 5;
        invItem2.codigoBodega = '99989998';
        inv1.add(invItem1);
        inv2.add(invItem2);

        List<AutosTallerProductosSOAPWS.AutosProductoWS> products = new List<AutosTallerProductosSOAPWS.AutosProductoWS>();
        AutosTallerProductosSOAPWS.AutosProductoWS product1 = new AutosTallerProductosSOAPWS.AutosProductoWS();
        product1.activo = true;
        product1.codigoProducto = '9999999';
        product1.descripcion = 'Descripción producto 9999999';
        product1.nombre = 'Producto 9999999';
        product1.referencia = 'Referencia producto 9999999';
        product1.referenciaComercial = 'Referencia comercial 9999999';
        product1.inventarioBodegas = inv1;
        AutosTallerProductosSOAPWS.AutosProductoWS product2 = new AutosTallerProductosSOAPWS.AutosProductoWS();
        product2.activo = true;
        product2.codigoProducto = '9999989';
        product2.descripcion = 'Descripción producto 9999989';
        product2.nombre = 'Producto 9999989';
        product2.referencia = 'Referencia producto 9999989';
        product2.referenciaComercial = 'Referencia comercial 9999989';
        product2.inventarioBodegas = inv1;
        AutosTallerProductosSOAPWS.AutosProductoWS product3 = new AutosTallerProductosSOAPWS.AutosProductoWS();
        product3.activo = true;
        product3.codigoProducto = '9999981';
        product3.descripcion = 'Descripción producto 9999981';
        product3.nombre = 'Producto 9999981';
        product3.referencia = 'Referencia producto 9999981';
        product3.referenciaComercial = 'Referencia comercial 9999981';
        product3.inventarioBodegas = inv2;

        products.add(product1);
        products.add(product2);
        products.add(product3);
        AutosTallerProductosSOAPWS.AutosProductoResultWS result = new AutosTallerProductosSOAPWS.AutosProductoResultWS();

        Test.startTest();
            result = AutosTallerProductosSOAPWS.sendProduct(products);
        Test.stopTest();

        // Assertions
        Assert.areEqual(false, result.operacionExitosa);
        Assert.isTrue(result.mensaje.containsIgnoreCase('Se produjeron errores al tratar de ingresar inventario'));
    }

    @IsTest
    static void sendProductWithoutCode() {
        List<AutosTallerProductosSOAPWS.InventarioBodegaWS> inv1 = new List<AutosTallerProductosSOAPWS.InventarioBodegaWS>();
        AutosTallerProductosSOAPWS.InventarioBodegaWS invItem1 = new AutosTallerProductosSOAPWS.InventarioBodegaWS();
        invItem1.cantidad = 10;
        invItem1.codigoBodega = '99999999';
        AutosTallerProductosSOAPWS.InventarioBodegaWS invItem2 = new AutosTallerProductosSOAPWS.InventarioBodegaWS();
        invItem2.cantidad = 5;
        invItem2.codigoBodega = '99999998';
        inv1.add(invItem1);
        inv1.add(invItem2);

        List<AutosTallerProductosSOAPWS.AutosProductoWS> products = new List<AutosTallerProductosSOAPWS.AutosProductoWS>();
        AutosTallerProductosSOAPWS.AutosProductoWS product1 = new AutosTallerProductosSOAPWS.AutosProductoWS();
        product1.activo = true;
        product1.codigoProducto = '9999999';
        product1.descripcion = 'Descripción producto 9999999';
        product1.nombre = 'Producto 9999999';
        product1.referencia = 'Referencia producto 9999999';
        product1.referenciaComercial = 'Referencia comercial 9999999';
        product1.inventarioBodegas = inv1;
        AutosTallerProductosSOAPWS.AutosProductoWS product2 = new AutosTallerProductosSOAPWS.AutosProductoWS();
        product2.activo = true;
        product2.codigoProducto = '9999989';
        product2.descripcion = 'Descripción producto 9999989';
        product2.nombre = 'Producto 9999989';
        product2.referencia = 'Referencia producto 9999989';
        product2.referenciaComercial = 'Referencia comercial 9999989';
        product2.inventarioBodegas = inv1;
        AutosTallerProductosSOAPWS.AutosProductoWS product3 = new AutosTallerProductosSOAPWS.AutosProductoWS();
        product3.activo = true;
        product3.codigoProducto = '';
        product3.descripcion = 'Descripción producto 9999981';
        product3.nombre = 'Producto 9999981';
        product3.referencia = 'Referencia producto 9999981';
        product3.referenciaComercial = 'Referencia comercial 9999981';
        product3.inventarioBodegas = inv1;

        products.add(product1);
        products.add(product2);
        products.add(product3);
        AutosTallerProductosSOAPWS.AutosProductoResultWS result = new AutosTallerProductosSOAPWS.AutosProductoResultWS();

        Test.startTest();
            result = AutosTallerProductosSOAPWS.sendProduct(products);
        Test.stopTest();

        // Assertions
        Assert.areEqual(false, result.operacionExitosa);
        Assert.isTrue(result.mensaje.containsIgnoreCase('Se produjeron errores al tratar de ingresar registros de productos'));
    }

    @IsTest
    static void sendProductNullProperties() {
        List<AutosTallerProductosSOAPWS.InventarioBodegaWS> inv1 = new List<AutosTallerProductosSOAPWS.InventarioBodegaWS>();
        AutosTallerProductosSOAPWS.InventarioBodegaWS invItem1 = new AutosTallerProductosSOAPWS.InventarioBodegaWS();
        invItem1.cantidad = 10;
        invItem1.codigoBodega = '99999999';
        AutosTallerProductosSOAPWS.InventarioBodegaWS invItem2 = new AutosTallerProductosSOAPWS.InventarioBodegaWS();
        invItem2.cantidad = 5;
        invItem2.codigoBodega = '99999998';
        inv1.add(invItem1);
        inv1.add(invItem2);

        List<AutosTallerProductosSOAPWS.AutosProductoWS> products; // = new List<AutosTallerProductosSOAPWS.AutosProductoWS>();
        AutosTallerProductosSOAPWS.AutosProductoWS product1 = new AutosTallerProductosSOAPWS.AutosProductoWS();
        product1.activo = true;
        product1.codigoProducto = '';
        product1.descripcion = '';
        product1.nombre = '';
        product1.referencia = '';
        product1.referenciaComercial = '';
        product1.inventarioBodegas = inv1;

        //products.add(product1);
        AutosTallerProductosSOAPWS.AutosProductoResultWS result = new AutosTallerProductosSOAPWS.AutosProductoResultWS();

        Test.startTest();
            result = AutosTallerProductosSOAPWS.sendProduct(products);
        Test.stopTest();

        // Assertions
        Assert.areEqual(false, result.operacionExitosa);
    }

}