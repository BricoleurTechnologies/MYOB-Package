/*
* Author: Bricoleur Technologies
* Created Date: June 23, 2023
* Description: Apex class for all requests to MYOB 
*/

public class MYOB_RestRequestCollection {
    
    public class EmployeeRequestBody{
        
        public String UID; //(36)
        public String LastName; //(50)
        public String FirstName; //(20)
        public Boolean IsIndividual; 
        public String DisplayID; //(15)
        public Boolean IsActive; 
        public List<Address> Addresses; 
    }
    
    public class CustomerRequestBodyUpdate{
        public String UID; //(36)
        public String LastName; //(50)
        public String FirstName; //(20)
        public Boolean IsIndividual; 
        public String DisplayID; //(15)
        public String CompanyName; //(15)
        public String ABN; //(50)
        public String Notes; //(255)     
        public String RowVersion; //(50)
        public MYOB_FlowParam_SellingDetail SellingDetails;
        public List<MYOB_FlowParam_Address> Addresses;
    }
    
    public class CustomerRequestBody{
        public String LastName; //(50)
        public String FirstName; //(20)
        public Boolean IsIndividual; 
        public String DisplayID; //(15)
        public String CompanyName; //(15)
        public String ABN; //(50)
        public String Notes; //(255)        
        public MYOB_FlowParam_SellingDetail SellingDetails;
        public List<MYOB_FlowParam_Address> Addresses;
        
    }
    
     public class Customer{
        public String UID; //(36)
        public String Name; //(50)
        public String DisplayID; //(15)
    }
    
    public class Address{
        public Integer Location; 
        public String Street; //(255)
        public String City; //(255)
        public String State; // (255)
        public String PostCode; // (11)
        public String Country; // (255)
        public String Phone1; // (21)
        public String Phone2; // (21)
        public String Phone3; // (21)
        public String Fax; // (21)
        public String Email; // (255)
        public String Website; //(255)
        public String ContactName; // 25
        public String Salutation; // 15
    }
    
    public class SellingDetail{
        public TaxCode TaxCode;
        public TaxCode FreightTaxCode;
    }    
    
    public class TaxCode{
        public String UID;
    }
    
    public class SalesOrderRequestBody {
        
        public String UID; //required
        public Date Date_x; //required
        public String CustomerPurchaseOrderNumber;
        public MYOB_FlowParam_Customer Customer;
        public List<MYOB_FlowParam_SalesOrderLines> Lines;
        public Boolean IsTaxInclusive;
        
    }
   
    
    
}