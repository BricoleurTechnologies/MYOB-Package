/*
 * Author: Bricoleur Technologies
 * Created Date: Jan. 05, 2021
 * Description: Handler class for Use cases with Apex REST Request
 * Test Class: N/A
 * History: 	January 05, 2021 - Creation
 * 				March 25, 2020   - Changed return type of SendRequest method from Object to HttpResponse,
 * 								   this will allow the developer to access attributes of the response.
 *                               - Added null checkers for RequestBody and RequestHeaders.
 */
public class RestHandler 
{
	private static HttpRequest Request;
    
    public void SetRequest(Map<String , String> requestHeaders , String requestEndpoint , String requestBody , String methodName)
    {
        Request = new HttpRequest();
        
        Request.setEndpoint(requestEndpoint);
        Request.setMethod(methodName);
        
        if(requestHeaders != null)
        {
            for(String requestKey : requestHeaders.keySet())
            {
                String requestValue = requestHeaders.get(requestKey);
                Request.setHeader(requestKey, requestValue);
            }
        }
        
        if(requestBody != null) Request.setBody(requestBody);
    }
    
    public HttpResponse SendRequest()
    {
        HttpResponse requestResponse;
        
        if(Request != null)
        {
            try
            {
                Http httpObject = new Http();
				Request.setTimeout(20000);
                requestResponse = httpObject.send(Request);
                if(requestResponse.getStatusCode() != 200 && requestResponse.getStatusCode() != 201){
                    Utilities.CreateExceptionLog(null,'Status Code: ' + requestResponse.getStatusCode() + 
                                                 ' Request Endpoint: ' + Request.getEndpoint() +
                                                 ' Response Body: ' + requestResponse.getBody());
                }              
            }
            catch(Exception err)
            {
                Utilities.CreateExceptionLog(err,null);
            }
        }
        else
        {
            ExceptionCollection.GenericException error = new ExceptionCollection.GenericException(MYOB_CONSTANTS.ERROR_REQUEST_NOT_SET);
            Throw error;
        }
        
        return requestResponse;
    }
    
    public static HttpResponse ExecuteRequest(Map<String , String> requestHeader , String requestEndpoint , String requestBody, String restMethod)
    {
        RestHandler handler = new RestHandler();
        
        handler.setRequest(requestHeader, requestEndpoint, requestBody, restMethod);
        return handler.SendRequest();
    }
}