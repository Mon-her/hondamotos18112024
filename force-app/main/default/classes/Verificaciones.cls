public class Verificaciones {
	public String cliente {get;set;}  
    public String usuario {get;set;}  
    public String api {get;set;}      
    public String numero {get;set;}   //solo para verificacion de telefono
    public String mensaje {get;set;}   //solo para verificacion de telefono
    public String mail {get;set;}   //solo para verificacion de mail
    public String param2 {get;set;}  //solo para verificacion de mail
    public String param3 {get;set;}  
    public String param4 {get;set;}  
    public String param5 {get;set;}  
    
    public class Response{
        public Consulta Consulta {get;set;}
    }
    public class Consulta{
        	public integer resultado {get;set;}
            public String mensaje {get;set;} 
            public String codigo {get;set;}     
    }
    
    //Esto devuelven:
    /*
    {
        "Consulta": {
            "resultado": 1,
            "mensaje": "Email válido"
        }
    }
	*/

    public static Verificaciones.Response parseSuccessResponse(String json) {
       return (Verificaciones.Response) System.JSON.deserialize(json, Verificaciones.Response.class);
    }
   
}