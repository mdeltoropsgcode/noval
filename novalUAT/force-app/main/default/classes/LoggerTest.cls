@IsTest
public class LoggerTest {


    @IsTest
    static void testCreateLog_Success() {
        Test.startTest();
        
        Logger.createLog('Test Process', 'LoggerTest', 'testCreateLog_Success', 'This is a test log message', 'Info');
        
        Test.stopTest();
        
        LogEntry__c logEntry = [SELECT Id, Process__c, ApexClass__c, Method__c, Message__c, Type__c 
                                FROM LogEntry__c 
                                WHERE ApexClass__c = 'LoggerTest' 
                                AND Method__c = 'testCreateLog_Success' 
                                LIMIT 1];
                                
        System.assertNotEquals(null, logEntry, 'Log entry should have been created.');
        System.assertEquals('Test Process', logEntry.Process__c, 'Process name should match.');
        System.assertEquals('LoggerTest', logEntry.ApexClass__c, 'Class name should match.');
        System.assertEquals('testCreateLog_Success', logEntry.Method__c, 'Method name should match.');
        System.assertEquals('This is a test log message', logEntry.Message__c, 'Message should match.');
        System.assertEquals('Info', logEntry.Type__c, 'Type should be "Info".');
    }
    
    @IsTest
    static void testCreateLogCollection_Success() {
        Test.startTest();
        Logger log = new Logger();

        log.StashLog('Test Process', 'LoggerTest', 'testCreateLog_Success', 'This is a test log message', 'Info');
        log.FlushLog();
        Test.stopTest();
        
        LogEntry__c logEntry = [SELECT Id, Process__c, ApexClass__c, Method__c, Message__c, Type__c 
                                FROM LogEntry__c 
                                WHERE ApexClass__c = 'LoggerTest' 
                                AND Method__c = 'testCreateLog_Success' 
                                LIMIT 1];
                                
        System.assertNotEquals(null, logEntry, 'Log entry should have been created.');
        System.assertEquals('Test Process', logEntry.Process__c, 'Process name should match.');
        System.assertEquals('LoggerTest', logEntry.ApexClass__c, 'Class name should match.');
        System.assertEquals('testCreateLog_Success', logEntry.Method__c, 'Method name should match.');
        System.assertEquals('This is a test log message', logEntry.Message__c, 'Message should match.');
        System.assertEquals('Info', logEntry.Type__c, 'Type should be "Info".');
    }
}