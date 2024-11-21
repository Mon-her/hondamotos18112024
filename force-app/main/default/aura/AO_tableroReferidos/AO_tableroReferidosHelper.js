({   
    getColumn : function(component) {        
        component.set('v.columns', [
            {label: 'Tipo registro', fieldName: 'wTipo', type: 'text'}, 
            {label: 'Agencia', fieldName: 'wAgencia', type: 'text'},
            {label: 'Fecha de creación del contacto o cuenta', fieldName: 'wFechaCreacion', type: 'text'},
            {label: 'Asesor Comercial', fieldName: 'wAsesorComercial', type: 'text'},
            {label: 'Quien refiere es(CH-CNH)', fieldName: 'wQuienRefiere', type: 'text'},       
            {label: 'No. Cedula del Referidor', fieldName: 'wCedulaReferidor', type: 'text'},
            {label: 'Nombre del referidor', fieldName: 'wNombreReferidor', type: 'text'},
            {label: 'Mail del referidor', fieldName: 'wMailReferidor', type: 'email'},
            {label: 'Teléfono del referidor', fieldName: 'wPhoneReferidor', type: 'phone'},            
            {label: 'Cedula REFERIDO', fieldName: 'wCedulaReferido', type: 'text'},         
            {label: 'Nombre REFERIDO (Ya sea como contacto ó como cuenta)', fieldName: 'wNombreReferidoId', type: 'url',	typeAttributes: {label: { fieldName: 'wNombreReferido' }, target: '_blank'}},
            {label: 'Teléfono REFERIDO', fieldName: 'wTelefonoReferido', type: 'phone'},
			{label: 'No. Cotización(Nuevo, usado ó Renting)', fieldName: 'wNoCotizacionId', type: 'url',	typeAttributes: {label: { fieldName: 'wNoCotizacion' }, target: '_blank'}},
            {label: 'Tipo de cotización', fieldName: 'wTipoCotizacion', type: 'text'},
            {label: 'Línea de interés', fieldName: 'wLineaInteresId', type: 'url',	typeAttributes: {label: { fieldName: 'wLineaInteres' }, target: '_blank'}},
            {label: 'Fecha estimada de compra)', fieldName: 'wFechaEstimadaCompra', type: 'text'},
            {label: 'Estado de prospección', fieldName: 'wEstadoProspeccion', type: 'text'},
            {label: 'Fecha de factura', fieldName: 'wFechaFactura', type: 'text'},
            {label: 'VIN', fieldName: 'wVIN', type: 'text'} ,
            {label: 'PLACA', fieldName: 'wPlaca', type: 'text'},           
            {label: '#Factura', fieldName: 'wNoFactura', type: 'text'}
        ]);
    },
     
    getReferidos : function(component, helper) {
        var action = component.get("c.getWrpReferidos");
        var pageSize = component.get("v.pageSize").toString();
        var pageNumber = component.get("v.pageNumber").toString();
        var dStart = component.get("v.startDate");
        var dEnd = component.get("v.finalDate");
         // set the parameters to method  
        action.setParams({
            'pageSize' : pageSize,
            'pageNumber' : pageNumber,
            'dStart': dStart,
            'dEnd' : dEnd
        });
        action.setCallback(this,function(response){
            // store the response return value 
            var state = response.getState();
            if (state === "SUCCESS") {
                var resultData = response.getReturnValue();
                if(resultData.length < component.get("v.pageSize")){
                    component.set("v.isLastPage", true);
                } else{
                    component.set("v.isLastPage", false);
                }
                component.set("v.dataSize", resultData.lstwReferidos.length);              
                component.set("v.cntContactos",resultData.wReferidosContactos );
                component.set("v.cntCuentas",resultData.wReferidosCuentas );                
                component.set("v.cntRenting",resultData.wCotizacioRenting );
                component.set("v.cntNuevos", resultData.wCotizacioNuevos );
                component.set("v.cntUsados", resultData.wCotizacioUsuados );
                component.set("v.cntReferidosTotales", resultData.wReferidosContactos + resultData.wReferidosCuentas ); 
                var records =resultData.lstwReferidos;
                records.forEach(function(record){
                	record.wNombreReferidoId = '/'+record.wNombreReferidoId;
                    if( record.wNoCotizacionId != null ){
                      record.wNoCotizacionId = '/'+record.wNoCotizacionId;  
                    }
                    if( record.wLineaInteresId != null ){
                        record.wLineaInteresId = '/'+record.wLineaInteresId;  
                    }
                    
                });                
                component.set("v.data", records);
            }
        });
        $A.enqueueAction(action);
    },   
})