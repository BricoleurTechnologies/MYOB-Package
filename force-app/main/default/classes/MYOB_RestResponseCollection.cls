/*
* Author: Bricoleur Technologies
* Created Date: June 23, 2023
* Description: Apex class for all responses from MYOB 
*/

public class MYOB_RestResponseCollection {

    
    public class ContactResponseBody{
        public List<Contact> Items;
        public String NextPageLink;
        public Integer count;
    }

    public class JobResponseBody{
        public List<Job> Items;
        public String NextPageLink;
        public Integer count;
    }
    
    public class InvoiceResponseBody{
        public List<Invoice> Items;
        public String NextPageLink;
        public Integer count;
    }
    
    public class Job {        
        public String UID;
        public String Name;
        public String Description;
        public String Number_x;   
    }
    
    public class Contact{
        public String UID;
        public String LastName;
        public String FirstName;
        public String Name;
        public String CompanyName;
        public Boolean IsIndividual;
        public String DisplayID;
        public Boolean IsActive;
        public List<Address> Addresses;
        public String Notes;
        public List<Identifier> Identifiers;
        public Decimal CurrentBalance;
        public SellingDetail SellingDetails;
        public PaymentDetail PaymentDetails;
        public ForeignCurrency ForeignCurrency;
        public DateTime LastModifiedDateTime;
        public String PhotoURIString;
        public String URIString;
        public String RowVersion;  
        public String PhotoURI; 
        public String URI;      
        public String ABN;   
        public CustomList CustomList2;
        public CustomList CustomList3;
    }
    
    public Class CustomList{
            
        public String Label;       
        public String Value;   
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

    public class Identifier{
        public String Label;
        public String Value;
    }

    public class SellingDetail{
        public String SaleLayout; //NoDefault;Service;Item;Professional;TimeBilling;Miscellaneous
        public String PrintedForm;
        public String InvoiceDelivery;
        public String ItemPriceLevel; //Base Selling Price;Level A;Level B;Level C;Level D;Level E;Level F;
        public IncomeAccount IncomeAccount;
        public String ReceiptMemo;
        public SalesPerson SalesPerson;
        public String SaleComment;
        public String ShippingMethod;
        public Decimal HourlyBillingRate;
        public String ABN; //14
        public String ABNBranch; //11
        public TaxCode TaxCode;
        public TaxCode FreightTaxCode;
        public Boolean UseCustomerTaxCode;
        public Term Terms;
        public Credit Credit;
        public String TaxIdNumber; //19
        public String Memo; //255
    }
  
    public class PaymentDetail{
        public String Method; //American Express;Bank Card;Barter Card;Cash;Cheque;Diners Club;EFTPOS;MasterCard;Money Order;Other;Visa
        public String CardNumber;
        public String NameOnCard;
        public String BSBNumber;
        public String BankAccountNumber;
        public String BankAccountName;
        public String Notes;
    }  
  
    public class ForeignCurrency{
        public String UID;
        public String Code;
        public String CurrencyName;
        public String URI;        
    }  
    
    public class IncomeAccount{
        public String UID;// (36)
        public String Name; // (30)
        public String Display;// (15)
        public String URI;
    }
    
     public class Account{
        public String UID;// (36)
        public String Name; // (30)
        public String DisplayID;// (15)
        public String URI;
    }

    public class SalesPerson{
        public String UID;// (36)
        public String Name; // (30)
        public String Display;// (15)
        public String URI;
    } 

    public class TaxCode{
        public String UID;
        public String Code;
        public String URI;
    } 

    public class Term{
        public String PaymentIsDue;
        public Integer DiscountDate;
        public Integer BalanceDueDate;
        public Decimal DiscountForEarlyPayment;
        public Decimal MonthlyChargeForLatePayment;
        public Decimal VolumeDiscount;
    }
    
    public class Credit{
        public Decimal Limit_x;
        public Decimal Available;
        public Decimal PastDue;
        public Boolean OnHold;
    } 
        
    public class Invoice{
        public String UID;
        public String Number_x;
        public String Date_x;
        public String CustomerPurchaseOrderNumber;
        public Contact Customer;
        public Contact Salesperson;
        public String PromisedDate;
        public Decimal BalanceDueAmount;
        public String Status;
        public String ShipToAddress;
        public Boolean IsTaxInclusive;
        public Decimal Subtotal;
        public Decimal TotalTax;
        public Decimal TotalAmount;
        public String Comment;
        public String JournalMemo;
        public String LastPaymentDate;
        public List<InvoiceLineItem> Lines;
        
    } 
    
    public class InvoiceLineItem{
        public Integer RowId;
        public Decimal ShipQuantity;
        public String Type_x;
        public String UnitOfMeasure;
        public String Description;
        public Decimal UnitPrice;
        public Decimal UnitCount;
        public Decimal DiscountPercent;
        public Decimal CostOfGoodsSold;
        public Decimal Total;
        public Item Item;
        public Account Account;
        public TaxCode TaxCode;   
    } 
    
     public class Item{
        public String UID;
        public String Number_x;
        public String Name;      
    } 
}