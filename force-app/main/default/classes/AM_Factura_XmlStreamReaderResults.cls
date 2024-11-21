public class AM_Factura_XmlStreamReaderResults {

    // Create a class Facturacion for processing
    public class Facturacion {
    
        String ordenResultado;
        String compania;
        String tipo_docto;
        String nro_docto;
        String nit;
        String cliente;
        String sucursal;
        String fecha;
        String co;
        String concepto;
        String item;
        String nombre_item;
        String cantidad;
        String valor_bruto;
        String valor_neto;
        String estado;

        String etapaSF;
        String razonNoComprarSF;
        String numeroFacturaSF;

        public String getordenResultado(){return ordenResultado;}
        public String getcompania(){return compania;}
        public String gettipo_docto(){return tipo_docto;}
        public String getnro_docto(){return nro_docto;}
        public String getnit(){return nit;}
        public String getcliente(){return cliente;}
        public String getsucursal(){return sucursal;}
        public String getfecha(){return fecha;}
        public String getco(){return co;}
        public String getconcepto(){return concepto;}
        public String getitem(){return item;}
        public String getnombre_item(){return nombre_item;}
        public String getcantidad(){return cantidad;}
        public String getvalor_bruto(){return valor_bruto;}
        public String getvalor_neto(){return valor_neto;}
        public String getestado() {return estado;}

        
        //etapa
        public String getestadoSF() {
            /*
            When:
            Estado Aprobado (1) >SF> Facturacion
            Estado Devolucion (DV) >SF> No Compra
            Estado Anulado (2) >SF> No Compra
            */
            Map<String, String> m1 = new Map<String, String>();
            m1.put('1', 'Facturación');
            m1.put('DV', 'No compra');
            m1.put('2', 'No compra');

            this.estado = this.estado.trim();
            if (this.estado == '1' || this.estado == 'DV' || this.estado == '2')
                this.etapaSF = m1.get(this.estado);
            else
                this.etapaSF = NULL;

            /*
            When:
            Etapa = Aprobado (1) >SF> Razon para no comprar = ''
            Etapa = Anulado (2) >SF> Razon para no comprar = 'Anulación'
            Etapa = Devolucion (DV) >SF> Razon para no comprar = 'Devolución'
            */
            Map<String, String> m2 = new Map<String, String>();
            m2.put('1', '');
            m2.put('2', 'Anulación');
            m2.put('DV', 'Devolución');
            
            if (this.estado == '1' || this.estado == 'DV' || this.estado == '2')
                this.razonNoComprarSF = m2.get(this.estado);
            else
                this.razonNoComprarSF = NULL;

            return etapaSF;
        }

        //razon para no comprar. see getestadoSF().
        public String getrazonNoComprarSF() {
            return razonNoComprarSF;
        }

        //numero de factura. concatenate fields CO + Tipo de documento + Numero. ex. SCP-100-5661
        public String getnumeroFacturaSF() {
            if (this.estado == '1' || this.estado == 'DV' || this.estado == '2')
                this.numeroFacturaSF = this.co.trim()+'-'+this.tipo_docto.trim()+'-'+this.nro_docto.trim();
            else
                this.numeroFacturaSF = NULL;
                
            return numeroFacturaSF;
        }

    }

    public Facturacion[] parsefacts(XmlStreamReader reader) {
        Facturacion[] facts = new Facturacion[0];
        boolean isSafeToGetNextXmlElement = true;
        while(isSafeToGetNextXmlElement) {
            // Start at the beginning of the facturacion and make sure that it is a Resultado
            if (reader.getEventType() == XmlTag.START_ELEMENT) {
                if ('Resultado' == reader.getLocalName()) {
                    // Pass the onefact to the parseBook method (below) 
                    Facturacion onefact = parsefact(reader);
                    facts.add(onefact);
                }
            }
            // Always use hasNext() before calling next() to confirm 
            // that we have not reached the end of the stream
            if (reader.hasNext()) {
                reader.next();
            } else {
                isSafeToGetNextXmlElement = false;
                break;
            }
        }
        return facts;
    }

    // Parse through the XML, determine the author and the characters
    private Facturacion parsefact(XmlStreamReader reader) {
        Facturacion fact = new Facturacion();
        fact.ordenResultado = reader.getAttributeValue(null, 'id').trim();
        boolean isSafeToGetNextXmlElement = true;
        while(isSafeToGetNextXmlElement) {
            //System.debug('==============>'+ reader.getLocalName());
            

            if (reader.getEventType() == XmlTag.START_ELEMENT && reader.getLocalName() == 'COMPANIA') {
                reader.next();
                if (reader.getEventType() == XmlTag.CHARACTERS) {
                    fact.compania = reader.getText().trim();
                    //System.debug('--------------->'+ fact.compania);                    
                }
            }
            if (reader.getEventType() == XmlTag.START_ELEMENT && reader.getLocalName() == 'TIPO_DOCTO') {
                reader.next();
                if (reader.getEventType() == XmlTag.CHARACTERS) {
                    fact.tipo_docto = reader.getText().trim();
                    //System.debug('--------------->'+ fact.tipo_docto);                    
                }
            }   
            if (reader.getEventType() == XmlTag.START_ELEMENT && reader.getLocalName() == 'NRO__DOCTO') {
                reader.next();
                if (reader.getEventType() == XmlTag.CHARACTERS) {
                    fact.nro_docto = reader.getText().trim();
                    //System.debug('--------------->'+ fact.nro_docto);                    
                }
            }   
            if (reader.getEventType() == XmlTag.START_ELEMENT && reader.getLocalName() == 'NIT') {
                reader.next();
                if (reader.getEventType() == XmlTag.CHARACTERS) {
                    fact.nit = reader.getText().trim();
                    //System.debug('--------------->'+ fact.nit);                    
                }
            }    
            if (reader.getEventType() == XmlTag.START_ELEMENT && reader.getLocalName() == 'CLIENTE') {
                reader.next();
                if (reader.getEventType() == XmlTag.CHARACTERS) {
                    fact.cliente = reader.getText().trim();
                    //System.debug('--------------->'+ fact.cliente);                    
                }
            }  
            if (reader.getEventType() == XmlTag.START_ELEMENT && reader.getLocalName() == 'SUCURSAL') {
                reader.next();
                if (reader.getEventType() == XmlTag.CHARACTERS) {
                    fact.sucursal = reader.getText().trim();
                    //System.debug('--------------->'+ fact.sucursal);                    
                }
            }   
            if (reader.getEventType() == XmlTag.START_ELEMENT && reader.getLocalName() == 'FECHA') {
                reader.next();
                if (reader.getEventType() == XmlTag.CHARACTERS) {
                    fact.fecha = reader.getText().trim();
                    //System.debug('--------------->'+ fact.sucursal);                    
                }
            }  
            if (reader.getEventType() == XmlTag.START_ELEMENT && reader.getLocalName() == 'CO') {
                reader.next();
                if (reader.getEventType() == XmlTag.CHARACTERS) {
                    fact.co = reader.getText().trim();
                    //System.debug('--------------->'+ fact.sucursal);                    
                }
            }  
            if (reader.getEventType() == XmlTag.START_ELEMENT && reader.getLocalName() == 'CONCEPTO') {
                reader.next();
                if (reader.getEventType() == XmlTag.CHARACTERS) {
                    fact.concepto = reader.getText().trim();
                    //System.debug('--------------->'+ fact.sucursal);                    
                }
            }  
            if (reader.getEventType() == XmlTag.START_ELEMENT && reader.getLocalName() == 'ITEM') {
                reader.next();
                if (reader.getEventType() == XmlTag.CHARACTERS) {
                    fact.item = reader.getText().trim();
                    //System.debug('--------------->'+ fact.sucursal);                    
                }
            }  
            if (reader.getEventType() == XmlTag.START_ELEMENT && reader.getLocalName() == 'NOMBRE_ITEM') {
                reader.next();
                if (reader.getEventType() == XmlTag.CHARACTERS) {
                    fact.nombre_item = reader.getText().trim();
                    //System.debug('--------------->'+ fact.sucursal);                    
                }
            }  
            if (reader.getEventType() == XmlTag.START_ELEMENT && reader.getLocalName() == 'CANTIDAD') {
                reader.next();
                if (reader.getEventType() == XmlTag.CHARACTERS) {
                    fact.cantidad = reader.getText().trim();
                    //System.debug('--------------->'+ fact.sucursal);                    
                }
            }  
            if (reader.getEventType() == XmlTag.START_ELEMENT && reader.getLocalName() == 'VALOR_BRUTO') {
                reader.next();
                if (reader.getEventType() == XmlTag.CHARACTERS) {
                    fact.valor_bruto = reader.getText().trim();
                    //System.debug('--------------->'+ fact.sucursal);                    
                }
            }  
            if (reader.getEventType() == XmlTag.START_ELEMENT && reader.getLocalName() == 'VALOR_NETO') {
                reader.next();
                if (reader.getEventType() == XmlTag.CHARACTERS) {
                    fact.valor_neto = reader.getText().trim();
                    //System.debug('--------------->'+ fact.sucursal);                    
                }
            }  
            if (reader.getEventType() == XmlTag.START_ELEMENT && reader.getLocalName() == 'ESTADO') {
                reader.next();
                if (reader.getEventType() == XmlTag.CHARACTERS) {
                    fact.estado = reader.getText().trim();
                    //System.debug('--------------->'+ fact.sucursal);                    
                }
            }  
            if (reader.getEventType() == XmlTag.END_ELEMENT && reader.getLocalName() == 'RESULTADO') {
                break;
            }

            if (reader.hasNext()) {
                reader.next();
            } else {
                isSafeToGetNextXmlElement = false;
                break;
            }
        }
        return fact;
    }
}