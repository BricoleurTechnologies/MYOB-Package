/*
 * Author: 			Bricoleur Technologies
 */
public class RunMYOBBatchCtrl {
    
    @AuraEnabled
    public static void runMYOBGetContactsBatch()
    {
        Database.executeBatch(new MYOB_GetContactsBatch(''));
    }
    
    @AuraEnabled
    public static void runMYOBGetInvoicesBatch()
    {
        Database.executeBatch(new MYOB_GetInvoicesBatch(''));
    }

}