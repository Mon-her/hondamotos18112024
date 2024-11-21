({   
	handleClick: function(cmp, event, helper) {
       var eUrl= $A.get("e.force:navigateToURL");
        eUrl.setParams({
          "url": '/lightning/n/Referidos' 
        });
        eUrl.fire();
    },
    doInit : function(cmp, event, helper){       			
        
        var dEnd =	$A.localizationService.formatDate(new Date(), "YYYY-MM-DD");
        cmp.set("v.finalDate",dEnd );   
       	
       	var result = new Date();
		result.setDate(result.getDate() - 30);
		var today = $A.localizationService.formatDate(result, "YYYY-MM-DD");
		cmp.set("v.startDate",today );
        helper.getReferidos(cmp, helper);
    },
    
  })