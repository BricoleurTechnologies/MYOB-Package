global class MYOB_InvoiceBatchSchedulable implements Schedulable {
    
    global void execute(SchedulableContext ctx) {
        Database.executeBatch(new MYOB_GetInvoicesBatch(''));
    }


}