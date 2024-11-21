@isTest
public class MotosProductosSOAPWS_Test {
    private static testmethod void testearAdd(){
        list<MotosProductosSOAPWS.ProductoWS> lstProductosWS= new list<MotosProductosSOAPWS.ProductoWS>();
        MotosProductosSOAPWS.ProductoWS productoWS = new MotosProductosSOAPWS.ProductoWS();
        ProductoWS.MARA_MATNR ='Code123';
        ProductoWS.MARA_SEGMENT ='Segmento alguno';
        ProductoWS.MARA_MKTXT ='Ref1';
        ProductoWS.AUSP_MODELO ='2020';
        ProductoWS.AUSP_COLOR ='Blanco';
        ProductoWS.AUSP_LINEA ='Familia1';
        ProductoWS.MARA_LVORM =''; //Estado, X para inactivo
        
    	lstProductosWS.add(ProductoWS);
        
        MotosProductosSOAPWS.productoAdd(lstProductosWS);
        
        //Reenviar el mismo producto para ocasionar error de codigo repetido
        MotosProductosSOAPWS.productoAdd(lstProductosWS);
        
        //Enviar producto vacío para ocasionar error que entra al catch
        MotosProductosSOAPWS.ProductoWS productoEmpty = new MotosProductosSOAPWS.ProductoWS();
        MotosProductosSOAPWS.productoAdd(new list<MotosProductosSOAPWS.ProductoWS>{productoEmpty});
    }
    
     private static testmethod void testearUpdate(){
        list<MotosProductosSOAPWS.ProductoWS> lstProductosWS= new list<MotosProductosSOAPWS.ProductoWS>();
        MotosProductosSOAPWS.ProductoWS productoWS = new MotosProductosSOAPWS.ProductoWS();
        ProductoWS.MARA_MATNR ='Code123';
        ProductoWS.MARA_SEGMENT ='Segmento alguno';
        ProductoWS.MARA_MKTXT ='Ref1';
        ProductoWS.AUSP_MODELO ='2020';
        ProductoWS.AUSP_COLOR ='Blanco';
        ProductoWS.AUSP_LINEA ='Familia1';
        ProductoWS.MARA_LVORM =''; //Estado, X para inactivo
        
    	lstProductosWS.add(ProductoWS);
        
        //Crea un producto para usarlo luego para Update
        MotosProductosSOAPWS.productoAdd(lstProductosWS);
         
        //Crea otro producto, uso el anterior como plantilla y le pongo otro codigo para que no salte duplicado
        //ProductoWS.MARA_MATNR ='Code1234'
        //MotosProductosSOAPWS.productoAdd(lstProductosWS);
         
        //Actualiza el producto con codigo Code1234
        MotosProductosSOAPWS.productoUpdate(lstProductosWS); 
        
        //Actualiza el producto utiliza un name de 256 caraceres
        ProductoWS.MARA_MKTXT = 'Product Name should be longer than 255 characters, how many characters do you think is this string? can you guess? come on, make a prediction or an estimation';
        ProductoWS.MARA_MKTXT =  ProductoWS.MARA_MKTXT + ProductoWS.MARA_MKTXT;
        MotosProductosSOAPWS.productoUpdate(lstProductosWS); 
         
        
        //Enviar producto vacío para ocasionar error que entra al catch
        MotosProductosSOAPWS.ProductoWS productoEmpty = new MotosProductosSOAPWS.ProductoWS();
        MotosProductosSOAPWS.productoUpdate(new list<MotosProductosSOAPWS.ProductoWS>{productoEmpty});
    }
}