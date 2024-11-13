/*
* Author:         	Bricoleur Technologies
* Created Date:    August 8, 2023
* Description:     Apex Class for MYOB Outbound Post Sales Order callout Invoked from Flow
* Test Class:      N/A
* History:         August 8, 2023 - Creation
*/
public class MYOB_PostOrderRequestFlow {
    
     private class MYOB_PostOrderRequestFlowAsync implements Queueable, Database.AllowsCallouts
    {

        private String paramString;
        
		public void setParamString(String paramString)
        {
            this.paramString = paramString;
        }
        
        public void execute(QueueableContext context)
        {
            MYOB_FlowParam_SalesOrder params = (MYOB_FlowParam_SalesOrder)JSON.deserialize(this.paramString, MYOB_FlowParam_SalesOrder.class);
            MYOB_FlowParam_Customer customerParams = params.Customer;
            MYOB_API_Setting__mdt apiSettings = [SELECT Client_ID__c, Endpoint__c,Company_File_ID__c 
                                                 FROM MYOB_API_Setting__mdt
                                                 WHERE DeveloperName = 'Default'];
            String clientID = apiSettings?.Client_ID__c;
            String endpoint = apiSettings?.Endpoint__c;
            String companyFileID = apiSettings?.Company_File_ID__c;
            String salesOrderRequestBodyString = '';
            
            if(apiSettings == NULL || clientID == NULL || endpoint == NULL) return;
            
            Map<String , String> requestHeader = MYOB_RequestUtilities.ConstructRequestHeaders(clientID);
            
            if(String.isBlank(customerParams.UID)){
                
                MYOB_RestResponseCollection.Contact myobContact = SearchContactFromMYOB(requestHeader, endpoint, companyFileID, customerParams);
                if(myobContact != null && myobContact?.UID != null){
                    Account accountRecord = new Account();
                    accountRecord.Id = customerParams.AccountSFID;
                    accountRecord.MYOB_GUID__c = myobContact?.UID;
                    accountRecord.MYOB_RowVersion__c = myobContact?.RowVersion;

                    String requestBodyString = '';                    
                    MYOB_RestRequestCollection.CustomerRequestBodyUpdate requestBody = SetPutContactBody(customerParams, myobContact?.UID, myobContact?.RowVersion);
                    requestBodyString = JSON.serialize(requestBody);
                    system.debug('requestBodyString ' + requestBodyString);
                    
                    params.Customer.UID = myobContact?.UID;
                    MYOB_RestRequestCollection.SalesOrderRequestBody salesOrderRequestBody = SetPostSalesOrderBody(params);
                    salesOrderRequestBodyString = JSON.serialize(salesOrderRequestBody);
                    Map<String , String> requestBodyReplacementList = new Map<String , String>{MYOB_CONSTANTS.INTEGRATION_KEY_TYPE_X => MYOB_CONSTANTS.INTEGRATION_KEY_TYPE,
                        MYOB_CONSTANTS.INTEGRATION_KEY_DATE_X => MYOB_CONSTANTS.INTEGRATION_KEY_DATE,
                        MYOB_CONSTANTS.INTEGRATION_KEY_NUMBER_X => MYOB_CONSTANTS.INTEGRATION_KEY_NUMBER};   
                            salesOrderRequestBodyString =  MYOB_RequestUtilities.FormatJSONBodyString(salesOrderRequestBodyString , requestBodyReplacementList);
                    
                    try{
                        
                        HttpResponse postResponse = RestHandler.ExecuteRequest(requestHeader , endpoint + '/' + companyFileID + MYOB_CONSTANTS.INTEGRATION_MYOB_ENDPOINT_CONTACT_CUSTOMER+ '/' + params.UID, requestBodyString, MYOB_CONSTANTS.INTEGRATION_REST_METHOD_PUT); 
                        HttpResponse postOrderResponse = RestHandler.ExecuteRequest(requestHeader , endpoint + '/' + companyFileID + MYOB_CONSTANTS.INTEGRATION_MYOB_ENDPOINT_ORDERS_ITEM, salesOrderRequestBodyString, MYOB_CONSTANTS.INTEGRATION_REST_METHOD_POST); 

                        Database.update(accountRecord);
                        Utilities.CreateRequestResponseLog(MYOB_CONSTANTS.INTEGRATION_REST_METHOD_PUT, requestBodyString, postResponse?.getBody(), postResponse?.getStatusCode(), MYOB_CONSTANTS.INTEGRATION_MYOB_ENDPOINT_CONTACT_CUSTOMER);
                        Utilities.CreateRequestResponseLog(MYOB_CONSTANTS.INTEGRATION_REST_METHOD_POST, salesOrderRequestBodyString, postOrderResponse?.getBody(), postOrderResponse?.getStatusCode(), MYOB_CONSTANTS.INTEGRATION_MYOB_ENDPOINT_ORDERS_ITEM);

                    }catch(Exception err){
                        
                        Utilities.CreateExceptionLog(err,'MYOB_PostOrderRequestFlow - Account Record Update');
                    }
                }else{
                    
                    String requestBodyString = '';
                    
                    MYOB_RestRequestCollection.CustomerRequestBody requestBody = SetPostContactBody(customerParams);
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
                                
                                params.Customer.UID = UID;
                                MYOB_RestRequestCollection.SalesOrderRequestBody salesOrderRequestBody = SetPostSalesOrderBody(params);
                                salesOrderRequestBodyString = JSON.serialize(salesOrderRequestBody);
                                Map<String , String> requestBodyReplacementList = new Map<String , String>{MYOB_CONSTANTS.INTEGRATION_KEY_TYPE_X => MYOB_CONSTANTS.INTEGRATION_KEY_TYPE,
                                    MYOB_CONSTANTS.INTEGRATION_KEY_DATE_X => MYOB_CONSTANTS.INTEGRATION_KEY_DATE,
                                    MYOB_CONSTANTS.INTEGRATION_KEY_NUMBER_X => MYOB_CONSTANTS.INTEGRATION_KEY_NUMBER};   
                                        salesOrderRequestBodyString =  MYOB_RequestUtilities.FormatJSONBodyString(salesOrderRequestBodyString , requestBodyReplacementList);
                                HttpResponse postOrderResponse = RestHandler.ExecuteRequest(requestHeader , endpoint + '/' + companyFileID + MYOB_CONSTANTS.INTEGRATION_MYOB_ENDPOINT_ORDERS_ITEM, salesOrderRequestBodyString, MYOB_CONSTANTS.INTEGRATION_REST_METHOD_POST); 
                                Utilities.CreateRequestResponseLog(MYOB_CONSTANTS.INTEGRATION_REST_METHOD_POST, salesOrderRequestBodyString, postOrderResponse?.getBody(), postOrderResponse?.getStatusCode(), MYOB_CONSTANTS.INTEGRATION_MYOB_ENDPOINT_ORDERS_ITEM);

                                Account accountRecord = new Account();
                                accountRecord.Id = customerParams.AccountSFID;
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
                MYOB_RestResponseCollection.Contact myobContact = SearchContactFromMYOBByUID(requestHeader, endpoint, companyFileID, customerParams);
                
                MYOB_RestRequestCollection.SalesOrderRequestBody salesOrderRequestBody = SetPostSalesOrderBody(params);
                salesOrderRequestBodyString = JSON.serialize(salesOrderRequestBody);
                Map<String , String> requestBodyReplacementList = new Map<String , String>{MYOB_CONSTANTS.INTEGRATION_KEY_TYPE_X => MYOB_CONSTANTS.INTEGRATION_KEY_TYPE,
                    MYOB_CONSTANTS.INTEGRATION_KEY_DATE_X => MYOB_CONSTANTS.INTEGRATION_KEY_DATE,
                    MYOB_CONSTANTS.INTEGRATION_KEY_NUMBER_X => MYOB_CONSTANTS.INTEGRATION_KEY_NUMBER};   
                        salesOrderRequestBodyString =  MYOB_RequestUtilities.FormatJSONBodyString(salesOrderRequestBodyString , requestBodyReplacementList);
                HttpResponse postOrderResponse = RestHandler.ExecuteRequest(requestHeader , endpoint + '/' + companyFileID + MYOB_CONSTANTS.INTEGRATION_MYOB_ENDPOINT_ORDERS_ITEM, salesOrderRequestBodyString, MYOB_CONSTANTS.INTEGRATION_REST_METHOD_POST); 
                
                system.debug('myobContact SearchContactFromMYOBByUID ' + myobContact);
                if(myobContact?.RowVersion != null){
                    MYOB_RestRequestCollection.CustomerRequestBodyUpdate requestBody = SetPutContactBody(customerParams,customerParams.UID,myobContact?.RowVersion);
                    requestBodyString = JSON.serialize(requestBody);
                    postResponse = RestHandler.ExecuteRequest(requestHeader , endpoint + '/' + companyFileID + MYOB_CONSTANTS.INTEGRATION_MYOB_ENDPOINT_CONTACT_CUSTOMER+ '/' + customerParams.UID, requestBodyString, MYOB_CONSTANTS.INTEGRATION_REST_METHOD_PUT); 
                    
                   
                    Account accountRecord = new Account();
                    accountRecord.Id = customerParams.AccountSFID;
                    accountRecord.MYOB_RowVersion__c = myobContact?.RowVersion;
                    update accountRecord;
                    Utilities.CreateRequestResponseLog(MYOB_CONSTANTS.INTEGRATION_REST_METHOD_PUT, requestBodyString, postResponse?.getBody(), postResponse?.getStatusCode(), MYOB_CONSTANTS.INTEGRATION_MYOB_ENDPOINT_CONTACT_CUSTOMER);
                }
            }
        }
    }

    @InvocableMethod(label = 'Sync Order To MYOB' description = 'Sends Salesforce Order to MYOB to Sync with MYOB Sales Order.')
    public static void SendOrderToMYOBFromFlow(List<MYOB_FlowParam_SalesOrder> params)
    {
        if(params == NULL || params.isEmpty()) return; 
        
        MYOB_PostOrderRequestFlow.MYOB_PostOrderRequestFlowAsync postSalesOrder = new MYOB_PostOrderRequestFlow.MYOB_PostOrderRequestFlowAsync();
        postSalesOrder.setParamString(JSON.serialize(params[0]));        
        System.enqueueJob(postSalesOrder);
        
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
    
    private static MYOB_RestRequestCollection.SalesOrderRequestBody SetPostSalesOrderBody(MYOB_FlowParam_SalesOrder params)
    {
        
        MYOB_RestRequestCollection.SalesOrderRequestBody requestBody = new MYOB_RestRequestCollection.SalesOrderRequestBody();
        
        requestBody.Date_x = params.Date_x;
        requestBody.CustomerPurchaseOrderNumber = params.CustomerPurchaseOrderNumber;
        requestBody.Customer = params.Customer;
        requestBody.Lines = params.Lines;
        requestBody.IsTaxInclusive = params.IsTaxInclusive;        
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
        if(!MYOB_RequestUtilities.CheckResponseBodyValidity(getResponse?.getStatusCode() , getResponseBodyString)) return null;
        
        system.debug('getResponseBodyString :: ' + getResponseBodyString);
        
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