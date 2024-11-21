public class AM_Inventario_XmlStreamReaderResults {

    // Create a class Inventario for processing
    public class Inventario {
    
        String ordenResultado;
        String bodega;
        String descripcion_bodega;
        String disponible;
        String color;
        String plan;
        String modelo;
        String a_omodelo;

        public String getordenResultado(){return ordenResultado;}
        public String getbodega(){return bodega;}
        public String getdescripcion_bodega(){return descripcion_bodega;}
        public String getdisponible(){return disponible;}
        public String getcolor(){return color;}
        public String getplan(){return plan;}
        public String getmodelo(){return modelo;}
        public String geta_omodelo(){return a_omodelo;}

    }

    public Inventario[] parseinvs(XmlStreamReader reader) {
        Inventario[] invs = new Inventario[0];
        boolean isSafeToGetNextXmlElement = true;
        while(isSafeToGetNextXmlElement) {
            // Start at the beginning of the inv and make sure that it is a inv
            if (reader.getEventType() == XmlTag.START_ELEMENT) {
                if ('Resultado' == reader.getLocalName()) {
                    // Pass the inv to the parseBook method (below) 
                    Inventario inv = parseinv(reader);
                    invs.add(inv);
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
        return invs;
    }

    // Parse through the XML, determine the author and the characters
    private Inventario parseinv(XmlStreamReader reader) {
        Inventario inv = new Inventario();
        inv.ordenResultado = reader.getAttributeValue(null, 'id');
        boolean isSafeToGetNextXmlElement = true;
        while(isSafeToGetNextXmlElement) {
            System.debug('==============>'+ reader.getLocalName());
            

            if (reader.getEventType() == XmlTag.START_ELEMENT && reader.getLocalName() == 'BODEGA') {
                reader.next();
                if (reader.getEventType() == XmlTag.CHARACTERS) {
                    inv.bodega = reader.getText();
                    System.debug('--------------->'+ inv.bodega);                    
                }
            }
            if (reader.getEventType() == XmlTag.START_ELEMENT && reader.getLocalName() == 'DESCRIPCION_BODEGA') {
                reader.next();
                if (reader.getEventType() == XmlTag.CHARACTERS) {
                    inv.descripcion_bodega = reader.getText();
                    System.debug('--------------->'+ inv.descripcion_bodega);                    
                }
            }   
            if (reader.getEventType() == XmlTag.START_ELEMENT && reader.getLocalName() == 'DISPONIBLE') {
                reader.next();
                if (reader.getEventType() == XmlTag.CHARACTERS) {
                    inv.disponible = reader.getText();
                    System.debug('--------------->'+ inv.disponible);                    
                }
            }   
            if (reader.getEventType() == XmlTag.START_ELEMENT && reader.getLocalName() == 'COLOR') {
                reader.next();
                if (reader.getEventType() == XmlTag.CHARACTERS) {
                    inv.color = reader.getText();
                    System.debug('--------------->'+ inv.color);                    
                }
            }    
            if (reader.getEventType() == XmlTag.START_ELEMENT && reader.getLocalName() == 'PLAN') {
                reader.next();
                if (reader.getEventType() == XmlTag.CHARACTERS) {
                    inv.plan = reader.getText();
                    System.debug('--------------->'+ inv.plan);                    
                }
            }  
            if (reader.getEventType() == XmlTag.START_ELEMENT && reader.getLocalName() == 'MODELO') {
                reader.next();
                if (reader.getEventType() == XmlTag.CHARACTERS) {
                    inv.modelo = reader.getText();
                    System.debug('--------------->'+ inv.modelo);                    
                }
            }
            if (reader.getEventType() == XmlTag.START_ELEMENT && reader.getLocalName() == 'A_OMODELO') {
                reader.next();
                if (reader.getEventType() == XmlTag.CHARACTERS) {
                    inv.a_omodelo = reader.getText();
                    System.debug('--------------->'+ inv.a_omodelo);                    
                }
            }   
            if (reader.getEventType() == XmlTag.END_ELEMENT && reader.getLocalName() == 'Resultado') {
                break;
            }

            if (reader.hasNext()) {
                reader.next();
            } else {
                isSafeToGetNextXmlElement = false;
                break;
            }
        }
        return inv;
    }
}