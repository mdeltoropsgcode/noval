@IsTest(SeeAllData=False)
public class VF_Messages_AbstractTest {
    
	private class ImpClass extends VF_Messages_Abstract {}
    public static testmethod void Test1() {
        Test.startTest();
        ImpClass inst = new ImpClass();
        String atype = inst.alertType;
        String msg = inst.errorMessage;
        inst.createError(ApexPages.Severity.FATAL, 'Test');
        msg = inst.errorMessage;
        atype = inst.alertType;
        Test.stopTest();
    }
}