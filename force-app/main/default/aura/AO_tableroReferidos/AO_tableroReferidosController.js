({
   doInit : function(component, event, helper){       			
        
        var dEnd =	$A.localizationService.formatDate(new Date(), "YYYY-MM-DD");
        component.set("v.finalDate",dEnd );   
       	
       	var result = new Date();
		result.setDate(result.getDate() - 30);
		var today = $A.localizationService.formatDate(result, "YYYY-MM-DD");
		component.set("v.startDate",today );            
        helper.getColumn(component);
        helper.getReferidos(component, helper);
    },
    refresh : function(component, event, helper) {        
        $A.get('e.force:refreshView').fire();         
    },
    // this function call on click on the next page button 
    handleNext : function(component, event, helper) { 
        var pageNumber = component.get("v.pageNumber");
        component.set("v.pageNumber", pageNumber+1);
        helper.getReferidos(component, helper);
    },
    // this function call on click on the previous page button  
    handlePrev : function(component, event, helper) {        
        var pageNumber = component.get("v.pageNumber");
        component.set("v.pageNumber", pageNumber-1);
        helper.getReferidos(component, helper);
    },   
    onValueChange : function(component, event, helper) {         
        helper.getReferidos(component, helper); 
    },
     VfpageCall : function(component, event, helper) {  
         var vStart = component.get("v.startDate" );
         var vEnd = component.get("v.finalDate" );
         var vfUrl = '/apex/AO_ExcelDocument_pag?start='+vStart+'&end='+vEnd;
       	 window.parent.location =vfUrl;       
    },
});