/**
	* Fanalca
	* @author           Juan Pablo Rodríguez
    * Description:      Clase de integración para crear y actualizar productos en Salesforce con protocolo SOAP.
    *
    * Versión de Cambios
    * -------------------------------------
    *           No.     Date            Author                  Description
    *           -----   ----------      --------------------    ---------------
    * @version  1.0     16/08/2024      Juan Pablo Rodríguez    Definición de clase
    * @version  1.#     ##/08/2020      Juan Pablo Rodríguez    Desarrollo finalizado y probado, apto para consumo desde herramientas externas 
*********************************************************************************************************/
global with sharing class AutosTallerProductosSOAPWS {
    // Propiedades globales 
    private static final String RT_VEHICULO_TALLER = 'Vehiculos_Taller';
    private static final Integer QUERY_LIMITS = 5000;
	
    global class AutosProductoWS {
        webservice Boolean activo { get; set; } // Product2.IsActive 
        webservice String codigoProducto { get; set; } // Product2.Codigo_de_producto__c OR Product2.ProductCodeRT__c
        webservice String descripcion { get; set; } // Product2.Description
        webservice String nombre { get; set; } // Product2.Name
        webservice String referencia { get; set; } // Product2.Referencia__c
        webservice String referenciaComercial { get; set; } // Product2.Referencia_comercial__c
        webservice List<InventarioBodegaWS> inventarioBodegas { get; set; }
    }

    global class InventarioBodegaWS {
        webservice Decimal cantidad { get; set; } // ProductItem.QuantityOnHand 
        webservice String codigoBodega { get; set; } // Location.codigoBodega__c 
    }

    webservice static AutosProductoResultWS sendProduct(List<AutosProductoWS> productosRecibidos) {
        Set<String> codigoProductos = new Set<String>();
        Set<Id> idProductos = new Set<Id>();
        List<Product2> productosUpsert = new List<Product2>();

        // Variables para almacenar el resultado de final de las transacciones consolidadas.
        Integer cantidadProductosExitosos = 0;
        Integer cantidadProductosNoExitosos = 0;
        Boolean inventarioExitoso = false;

        // Se almacena la colección de valores como resultado de las operaciones.
        AutosProductoResultWS resultadoOperacion = new AutosProductoResultWS();

        try {
            System.debug('Productos recibidos');
            System.debug(productosRecibidos);
            // Validaciones para los datos enviados
            if(productosRecibidos.isEmpty()) {
                resultadoOperacion.operacionExitosa = false;
                resultadoOperacion.mensaje = 'La colección de productos recibida está vacía, favor envíe datos válidos.';
                resultadoOperacion.resultadoProductos = new List<ProductoResultWS>();

                return resultadoOperacion;
            }

            // Almacenar los códigos de productos para vertificar si ya existen en Salesforce.
            for(AutosProductoWS ap : productosRecibidos) { codigoProductos.add(ap.codigoProducto); }

            // Crear colección de productos a ingresar/actualizar.
            for(AutosProductoWS ap : productosRecibidos) {
                Product2 nuevoProducto = new Product2(
                    RecordTypeId = Schema.SObjectType.Product2.getRecordTypeInfosByDeveloperName().get(RT_VEHICULO_TALLER).getRecordTypeId(),
                    IsActive = ap.activo,
                    Codigo_de_producto__c = ap.codigoProducto,
                    ProductCode = ap.codigoProducto,
                    Description = ap.descripcion,
                    Name = ap.nombre,
                    Referencia__c = ap.referencia,
                    Referencia_comercial__c = ap.referenciaComercial
                );

                // Agregar el producto a ingresar o actualizar 
                productosUpsert.add(nuevoProducto);
            }
            System.debug('Productos a ingresar');
            System.debug(productosUpsert);

            Schema.DescribeFieldResult productField = Product2.Codigo_de_producto__c.getDescribe();
            Schema.sObjectField extIdProductField = productField.getSobjectField();
            List<Database.UpsertResult> resultadosProductos = DomainLocalProduct2.upsertProducts(productosUpsert, extIdProductField);
            List<Database.Error> erroresProductos = new List<Database.Error>();

            for(Database.UpsertResult ur : resultadosProductos) {
                if(!ur.isSuccess()) { cantidadProductosNoExitosos += 1; erroresProductos.addAll(ur.getErrors()); }
                if(ur.isSuccess()) { cantidadProductosExitosos += 1; idProductos.add(ur.getId()); }
            }
            System.debug('Resultados productos');
            System.debug(resultadosProductos);
            System.debug('Ids de productos');
            System.debug(idProductos);
            System.debug('Prouctos no exitosos: ' + cantidadProductosNoExitosos);
            System.debug('Productos exitosos: ' + cantidadProductosExitosos);

            // Realizar operaciones de upsert sobre el inventario de los productos ingresados
            if(cantidadProductosExitosos > 0 && !idProductos.isEmpty()) {
                inventarioExitoso = upsertInventory(productosRecibidos, idProductos);
            }
            System.debug('Inventario exitoso: ' + inventarioExitoso);

            List<ProductoResultWS> resultadoProductos = new List<ProductoResultWS>();
            if(cantidadProductosNoExitosos == 0 && inventarioExitoso) {
                resultadoOperacion.mensaje = 'Productos ingresados/actualizados con éxito.';
                resultadoOperacion.operacionExitosa = true;
            } else {
                resultadoOperacion.mensaje = (!inventarioExitoso ? 'Se produjeron errores al tratar de ingresar inventario de los productos.' : 'Se produjeron errores al tratar de ingresar registros de productos.');
                resultadoOperacion.operacionExitosa = false;
            }
            System.debug('Resultado operacion');
            System.debug(resultadoOperacion);

            // Completar errores de resultados sobre colección de productos.
            for(Integer i = 0; i < resultadosProductos.size(); i++) {
                ProductoResultWS prws = new ProductoResultWS();

                System.debug('Registro exitoso');
                System.debug(resultadosProductos[i]?.isSuccess());
                System.debug(resultadosProductos[i]?.getId() != null);

                prws.recordId = (resultadosProductos[i]?.isSuccess() ? resultadosProductos[i]?.getId() : null);
                prws.error = (resultadosProductos[i]?.isSuccess() ? false : true);
                prws.mensaje = (resultadosProductos[i]?.isSuccess() ? 'Operación exitosa' : 'Operación fallida');
                System.debug('Mensajes de errores');
                System.debug(resultadosProductos[i]?.getErrors());

                if(resultadosProductos[i]?.isSuccess()) {
                    prws.recordId = resultadosProductos[i]?.getId();
                    prws.codigoProducto = productosUpsert[i]?.Codigo_de_producto__c;
                    prws.nombre = productosUpsert[i]?.Name;
                    prws.error = false;
                    prws.mensaje = 'Operación exitosa';
                } else {
                    prws.recordId = null;
                    prws.codigoProducto = productosUpsert[i]?.Codigo_de_producto__c;
                    prws.nombre = productosUpsert[i]?.Name;
                    prws.error = true;
                    prws.mensaje = getErrorDetails(resultadosProductos[i]?.getErrors());
                }

                // Agregar resultado de la operación a la colección de resultados 
                resultadoProductos.add(prws);
            }
            System.debug('Resultado productos');
            System.debug(resultadoProductos);

            resultadoOperacion.resultadoProductos = resultadoProductos;
        } catch(Exception ex) {
            System.debug(ex);
            resultadoOperacion.operacionExitosa = false;
            resultadoOperacion.mensaje = ex.getMessage();
            resultadoOperacion.resultadoProductos = new List<ProductoResultWS>();
        } finally {
            Log__c log = new Log__c(
                Body__c = JSON.serialize(productosRecibidos),
                Response__c = JSON.serialize(resultadoOperacion),
                Web_Service__c = 'AutosTallerProductosSOAPWS.sendProduct'
            );
            if(!Test.isRunningTest()) { Utilities.insertLog(new List<Log__c>{log}); }
        }

        return resultadoOperacion;
    }

    private static Boolean upsertInventory(List<AutosProductoWS> productosRecibidos, Set<Id> idProductos) {
        Map<String, List<ProductItem>> productItemsMapa = new Map<String, List<ProductItem>>();
        Map<String, List<ProductItem>> productSinInventario = new Map<String, List<ProductItem>>();
        Map<String, List<ProductItem>> productConInventario = new Map<String, List<ProductItem>>();
        List<ProductItem> inventarioActualizar = new List<ProductItem>();
        List<ProductItem> inventarioIngresar = new List<ProductItem>();
        Boolean operacionesExitosas = false;
        Integer totalOperacionesExitosas = 0;
        Integer totalOperacionesFallidas = 0;

        // Consultar el iventario de los productos confirmados en Salesforce
        productItemsMapa = SelectorLocalProductItem.getProductItemsByProductId(idProductos, QUERY_LIMITS);
        System.debug('Inventario de productos');
        System.debug(productItemsMapa);

        if(!productItemsMapa.isEmpty()) {
            for(String prodCode : productItemsMapa.keySet()) {
                List<ProductItem> productItems = (List<ProductItem>)productItemsMapa.get(prodCode);

                if(!productItems.isEmpty()) { productConInventario.put(prodCode, productItems); }
                else { productSinInventario.put(prodCode, new List<ProductItem>()); }
            }
        }
        System.debug('Productos con inventario');
        System.debug(productConInventario);
        System.debug('Productos sin inventario');
        System.debug(productSinInventario);

        // Tratar los productos enviados para procesar su inventario
        for(AutosProductoWS ap : productosRecibidos) {
            System.debug('Producto recibido');
            System.debug(ap);
            if(productConInventario.containsKey(ap.codigoProducto)) {
                List<ProductItem> productItems = (List<ProductItem>)productConInventario.get(ap.codigoProducto);

                for(InventarioBodegaWS ib : ap.inventarioBodegas) {
                    Boolean bodegaEncontrada = false;
                    for(ProductItem pi : productItems) {
                        if(ib?.codigoBodega == pi?.Location?.codigoBodega__c) {
                            ProductItem upProdItem = new ProductItem();
                            upProdItem.Id = pi.Id;
                            upProdItem.QuantityOnHand = ib.cantidad;
                            //upProdItem.LocationId = pi.LocationId;
                            //upProdItem.Product2Id = pi.Product2Id;

                            inventarioActualizar.add(upProdItem);
                            bodegaEncontrada = true;
                            break;
                        }
                    }

                    if(!bodegaEncontrada) {
                        ProductItem upProdItem = new ProductItem();

                        upProdItem.QuantityOnHand = ib.cantidad;
                        upProdItem.Location = new Schema.Location(codigoBodega__c = ib?.codigoBodega);
                        upProdItem.Product2 = new Product2(Codigo_de_producto__c = ap?.codigoProducto);

                        inventarioIngresar.add(upProdItem);
                    }
                }
            }

            if(productSinInventario.containsKey(ap.codigoProducto)) {
                for(InventarioBodegaWS ib : ap.inventarioBodegas) {
                    ProductItem upProdItem = new ProductItem();

                    upProdItem.QuantityOnHand = ib.cantidad;
                    upProdItem.Location = new Schema.Location(codigoBodega__c = ib.codigoBodega);
                    upProdItem.Product2 = new Product2(Codigo_de_producto__c = ap.codigoProducto);

                    inventarioIngresar.add(upProdItem);
                }
            }
        }

        // Upsert inventario
        List<ProductItem> upsertInventario = new List<ProductItem>();
        upsertInventario.addAll(inventarioActualizar);
        upsertInventario.addAll(inventarioIngresar);
        
        System.debug('Upsert inventario');
        System.debug(upsertInventario);
        List<Database.UpsertResult> results = new List<Database.UpsertResult>();
        if(!upsertInventario.isEmpty()) { results = DomainLocalProductItem.upsertProductItems(upsertInventario); }

        // Verificar todas las operaciones
        for(Database.UpsertResult ur : results) {
            if(ur.isSuccess()) { totalOperacionesExitosas += 1; }
            if(!ur.isSuccess()) { totalOperacionesFallidas += 1; }
        }
        System.debug('Results');
        System.debug(results);

        // Se determina si fallo al menos una operación upsert 
        operacionesExitosas = (totalOperacionesFallidas == 0);

        return operacionesExitosas;
    }

    private static String getErrorDetails(List<Database.Error> errors) {
        String errorMessage = '';

        for(Database.Error err : errors) {
            errorMessage += 'Error: ' + err.getMessage() + ', Campos: ' + err.getFields() + ', Código de estado: ' + err.getStatusCode() + '\n';
        }
        System.debug('Mensaje de Error');
        System.debug(errorMessage);

        return errorMessage;
    }

    global class AutosProductoResultWS {
        webservice Boolean operacionExitosa { get; set; }
        webservice String mensaje { get; set; }
        webservice List<ProductoResultWS> resultadoProductos { get; set; }
    }

    global class ProductoResultWS {
        webservice String codigoProducto { get; set; }
        webservice String nombre { get; set; }
        webservice String recordId { get; set; }
        webservice Boolean error { get; set; }
        webservice String mensaje { get; set; }
    }
    
}