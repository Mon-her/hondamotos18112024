({
	getReferidos : function(cmp,helper) {		
 		var action = cmp.get("c.getWrpReferidos");
        var pageSize = cmp.get("v.pageSize").toString();
        var pageNumber = cmp.get("v.pageNumber").toString();
        var dStart = cmp.get("v.startDate");
        var dEnd = cmp.get("v.finalDate"); 
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
                cmp.set("v.cntReferidosTotales", resultData.wReferidosContactos + resultData.wReferidosCuentas );                
            }
        });
        $A.enqueueAction(action);
    },   
})