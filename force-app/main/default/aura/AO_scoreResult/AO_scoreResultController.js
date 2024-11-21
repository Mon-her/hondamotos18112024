({
	init : function(component, event, helper) {
    var today = $A.localizationService.formatDate(new Date(), "YYYY-MM-DD");       
   // component.set('v.finalDate', today);
    //component.set('v.startDate', date.setDate(today + 30));
	},
     VfpageCall : function(component, event, helper) {        
       var vfUrl = '/apex/AO_ExcelDocument_pag';
       window.parent.location =vfUrl;
    },
})