public class MYOB_FlowParam_SalesOrderLines {
    
    @AuraEnabled @InvocableVariable public Date Date_x; 
    @AuraEnabled @InvocableVariable public String Type_x; //Transaction/Header/Subtotal
    @AuraEnabled @InvocableVariable public String Description;
    @AuraEnabled @InvocableVariable public Boolean IsTaxInclusive;    
    @AuraEnabled @InvocableVariable public Decimal ShipQuantity; 
    @AuraEnabled @InvocableVariable public Decimal UnitPrice; 
    @AuraEnabled @InvocableVariable public Decimal DiscountPercent;
    @AuraEnabled @InvocableVariable public MYOB_FlowParam_Item Item;
    @AuraEnabled @InvocableVariable public MYOB_FlowParam_TaxCode TaxCode;
    
    

}