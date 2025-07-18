public class Logger {

    List<LogEntry__c> logEntries;
    public Logger(){
        this.logEntries = new List<LogEntry__c>();
    }

    @future
    public static void createLog(String process, String apexClass, String method, String message, String type) {
        LogEntry__c logEntry = new LogEntry__c(
            Process__c = process,
            ApexClass__c = apexClass,
            Method__c = method,
            Message__c = message,
            Type__c = type
        );
        
        try {
            insert logEntry;
        } catch (DmlException e) {
            System.debug('Error creating log entry: ' + e.getMessage());
        }
    }

    public void StashLog(String process, String apexClass, String method, String message, String type) {
        LogEntry__c logEntry = new LogEntry__c(
            Process__c = process,
            ApexClass__c = apexClass,
            Method__c = method,
            Message__c = message,
            Type__c = type
        );

        this.logEntries.add(logEntry);
    }

    public void FlushLog() {
        try {
            insert this.logEntries;
        } catch (DmlException e) {
            System.debug('Error creating log entry: ' + e.getMessage());
        }
    }
}