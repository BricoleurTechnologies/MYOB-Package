/*
* Author:         	Bricoleur Technologies
* Created Date:    November 22, 2021
* Description:     Apex Class for MYOB Outbound Post Contact callout Invoked from Flow
* Test Class:      N/A
* History:         November 22, 2021 - Creation
*/
public class MYOB_PostContactRequestFlow   
{
    
     private class MYOB_PostContactRequestFlowAsync implements Queueable, Database.AllowsCallouts
    {

        private String paramString;
        
		public void setParamString(String paramString)
        {
            this.paramString = paramString;
        }
        
        public void execute(QueueableContext context)
        {
            
            MYOB_FlowParam_Customer params = (MYOB_FlowParam_Customer)JSON.deserialize(this.paramString, MYOB_FlowParam_Customer.class);
            MYOB_API_Setting__mdt apiSettings = [SELECT Client_ID__c, Endpoint__c,Company_File_ID__c 
                                                 FROM MYOB_API_Setting__mdt
                                                 WHERE DeveloperName = 'Default'];
            String clientID = apiSettings?.Client_ID__c;
            String endpoint = apiSettings?.Endpoint__c;
            String companyFileID = apiSettings?.Company_File_ID__c;
            
            if(apiSettings == NULL || clientID == NULL || endpoint == NULL) return;
            
            Map<String , String> requestHeader = MYOB_RequestUtilities.ConstructRequestHeaders(clientID);
            
            if(String.isBlank(params.UID)){
                
                MYOB_RestResponseCollection.Contact myobContact = SearchContactFromMYOB(requestHeader, endpoint, companyFileID, params);
                if(myobContact != null && myobContact?.UID != null){
                    Account accountRecord = new Account();
                    accountRecord.Id = params.AccountSFID;
                    accountRecord.MYOB_GUID__c = myobContact?.UID;
                    accountRecord.MYOB_RowVersion__c = myobContact?.RowVersion;

                    String requestBodyString = '';
                    
                    MYOB_RestRequestCollection.CustomerRequestBodyUpdate requestBody = SetPutContactBody(params, myobContact?.UID, myobContact?.RowVersion);
                    requestBodyString = JSON.serialize(requestBody);
                    system.debug('requestBodyString ' + requestBodyString);
                    
                    try{
                        
                        HttpResponse postResponse = RestHandler.ExecuteRequest(requestHeader , endpoint + '/' + companyFileID + MYOB_CONSTANTS.INTEGRATION_MYOB_ENDPOINT_CONTACT_CUSTOMER+ '/' + params.UID, requestBodyString, MYOB_CONSTANTS.INTEGRATION_REST_METHOD_PUT); 
                        system.debug('postResponse?.getBody:'+postResponse?.getBody());
                        Database.update(accountRecord);                         
                        Utilities.CreateRequestResponseLog(MYOB_CONSTANTS.INTEGRATION_REST_METHOD_PUT, requestBodyString, postResponse?.getBody(), postResponse?.getStatusCode(), MYOB_CONSTANTS.INTEGRATION_MYOB_ENDPOINT_CONTACT_CUSTOMER);

                    }catch(Exception err){
                        
                        Utilities.CreateExceptionLog(err,'MYOB_PostContactRequestFlow - Account Record Update');
                    }
                }else{
                    
                    String requestBodyString = '';
                    
                    MYOB_RestRequestCollection.CustomerRequestBody requestBody = SetPostContactBody(params);
                    requestBodyString = JSON.serialize(requestBody);
                    system.debug('requestBodyString ' + requestBodyString);
                    HttpResponse postResponse = RestHandler.ExecuteRequest(requestHeader , endpoint + '/' + companyFileID + MYOB_CONSTANTS.INTEGRATION_MYOB_ENDPOINT_CONTACT_CUSTOMER, requestBodyString, MYOB_CONSTANTS.INTEGRATION_REST_METHOD_POST); 
                    String postResponseBodyString = postResponse?.getBody();        
                    Integer postResponseStatusCode = postResponse?.getStatusCode();
                                      
                    if(postResponseStatusCode == MYOB_Constants.INTEGRATION_REST_RESPONSE_201){           
                        String myobLocation = postResponse?.getHeader(MYOB_CONSTANTS.INTEGRATION_HEADER_MYOB_LOCATION);
                        if(myobLocation != null && myobLocation != ''){
                            String UID = myobLocation?.substringAfterLast('/');
                            if(UID != null && UID != ''){                            
                                Account accountRecord = new Account();
                                accountRecord.Id = params.AccountSFID;
                                accountRecord.MYOB_GUID__c = UID;
                                update accountRecord;
                            }
                        }
                    }
                    
                    Utilities.CreateRequestResponseLog(MYOB_CONSTANTS.INTEGRATION_REST_METHOD_POST, requestBodyString, postResponseBodyString, postResponseStatusCode, MYOB_CONSTANTS.INTEGRATION_MYOB_ENDPOINT_CONTACT_CUSTOMER);
                }
            }else{
                
                String requestBodyString = '';
                HttpResponse postResponse;
                MYOB_RestResponseCollection.Contact myobContact = SearchContactFromMYOBByUID(requestHeader, endpoint, companyFileID, params);
                
                system.debug('myobContact SearchContactFromMYOBByUID ' + myobContact);
                if(myobContact?.RowVersion != null){
                    MYOB_RestRequestCollection.CustomerRequestBodyUpdate requestBody = SetPutContactBody(params,params.UID,myobContact?.RowVersion);
                    requestBodyString = JSON.serialize(requestBody);
                    postResponse = RestHandler.ExecuteRequest(requestHeader , endpoint + '/' + companyFileID + MYOB_CONSTANTS.INTEGRATION_MYOB_ENDPOINT_CONTACT_CUSTOMER+ '/' + params.UID, requestBodyString, MYOB_CONSTANTS.INTEGRATION_REST_METHOD_PUT); 
                    string response = postResponse?.getBody();
                    Account accountRecord = new Account();
                    accountRecord.Id = params.AccountSFID;
                    accountRecord.MYOB_RowVersion__c = myobContact?.RowVersion;
                    update accountRecord;
                    Utilities.CreateRequestResponseLog(MYOB_CONSTANTS.INTEGRATION_REST_METHOD_PUT, requestBodyString, postResponse?.getBody(), postResponse?.getStatusCode(), MYOB_CONSTANTS.INTEGRATION_MYOB_ENDPOINT_CONTACT_CUSTOMER);
                }
            }
        }
    }

    @InvocableMethod(label = 'Sync Contact To MYOB' description = 'Sends Salesforce Account to MYOB to Sync with MYOB Contact.')
    public static void SendContactToMYOBFromFlow(List<MYOB_FlowParam_Customer> params)
    {
        if(params == NULL || params.isEmpty()) return; 
        
        MYOB_PostContactRequestFlow.MYOB_PostContactRequestFlowAsync postContact = new MYOB_PostContactRequestFlow.MYOB_PostContactRequestFlowAsync();
        postContact.setParamString(JSON.serialize(params[0]));        
        System.enqueueJob(postContact);
        
    }
    
            
    private static MYOB_RestRequestCollection.CustomerRequestBodyUpdate SetPutContactBody(MYOB_FlowParam_Customer params, String UID, String RowVersion)
    {
        
        MYOB_RestRequestCollection.CustomerRequestBodyUpdate requestBody = new MYOB_RestRequestCollection.CustomerRequestBodyUpdate();
         
        
        requestBody.CompanyName = params.CompanyName;
        requestBody.SellingDetails = params.SellingDetails;
        requestBody.IsIndividual = params.IsIndividual;
        requestBody.DisplayID = params.DisplayID;
        requestBody.Addresses = params.Addresses;
        requestBody.ABN = params.ABN;
        requestBody.Notes = params.Notes;
        requestBody.UID = UID;
        requestBody.RowVersion = RowVersion;
        return requestBody;
    }
    
        
    private static MYOB_RestRequestCollection.CustomerRequestBody SetPostContactBody(MYOB_FlowParam_Customer params)
    {
        
        MYOB_RestRequestCollection.CustomerRequestBody requestBody = new MYOB_RestRequestCollection.CustomerRequestBody();
        
        requestBody.CompanyName = params.CompanyName;
        requestBody.SellingDetails = params.SellingDetails;
        requestBody.IsIndividual = params.IsIndividual;
        requestBody.DisplayID = params.DisplayID;
        requestBody.Addresses = params.Addresses;
        requestBody.ABN = params.ABN;
        requestBody.Notes = params.Notes;
        
        return requestBody;
    }
    
    public static MYOB_RestResponseCollection.Contact SearchContactFromMYOBByUID( Map<String , String> requestHeader, String endpoint, String companyFileId, MYOB_FlowParam_Customer params){
               
            HttpResponse getResponse = RestHandler.ExecuteRequest(requestHeader, endpoint + '/' + companyFileId + MYOB_CONSTANTS.INTEGRATION_MYOB_ENDPOINT_CONTACT_CUSTOMER
                                                                 + '/' + params.UID, null, MYOB_CONSTANTS.INTEGRATION_REST_METHOD_GET);        
            String getResponseBodyString = getResponse?.getBody();   
            if(!MYOB_RequestUtilities.CheckResponseBodyValidity(getResponse?.getStatusCode() , getResponseBodyString)) return null;
            
            system.debug('getResponseBodyString :: ' + getResponseBodyString);
            
            MYOB_RestResponseCollection.Contact myobContactItem = (MYOB_RestResponseCollection.Contact)JSON.deserialize(getResponseBodyString, MYOB_RestResponseCollection.Contact.class);
            
            if(myobContactItem == NULL) return null;
            return myobContactItem;
        
    }    
    
    public static MYOB_RestResponseCollection.Contact SearchContactFromMYOB( Map<String , String> requestHeader, String endpoint, String companyFileId, MYOB_FlowParam_Customer params){
        String customerParam = '';
        
        customerParam = EncodingUtil.urlEncode(MYOB_CONSTANTS.INTEGRATION_MYOB_FILTER_COMPNAME + MYOB_CONSTANTS.GENERIC_SINGLE_QUOTE + params.CompanyName +  MYOB_CONSTANTS.GENERIC_SINGLE_QUOTE, 'UTF-8');
        
        
        system.debug('customerParam :: ' + customerParam);
        HttpResponse getResponse = RestHandler.ExecuteRequest(requestHeader, endpoint + '/' + companyFileId + MYOB_CONSTANTS.INTEGRATION_MYOB_ENDPOINT_CONTACT_CUSTOMER
                                                              + '?' + MYOB_CONSTANTS.INTEGRATION_MYOB_FILTER + customerParam, null, MYOB_CONSTANTS.INTEGRATION_REST_METHOD_GET);        
        String getResponseBodyString = getResponse?.getBody();  
        system.debug('getResponseBodyString :: ' + getResponseBodyString);
        if(!MYOB_RequestUtilities.CheckResponseBodyValidity(getResponse?.getStatusCode() , getResponseBodyString)) return null;
        
        
        
        MYOB_RestResponseCollection.ContactResponseBody myobContact = (MYOB_RestResponseCollection.ContactResponseBody)JSON.deserialize(getResponseBodyString, MYOB_RestResponseCollection.ContactResponseBody.class);
        MYOB_RestResponseCollection.Contact myobContactItem = new MYOB_RestResponseCollection.Contact();
        
        if(myobContact == NULL) return null;
        else if(myobContact.Items?.size() > 0 ){
            myobContactItem =  myobContact.Items[0];            
        }else{
            myobContactItem = null;
        }
        return myobContactItem;
        
    }    
}