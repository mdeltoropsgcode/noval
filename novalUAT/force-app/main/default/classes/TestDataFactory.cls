@isTest
public class TestDataFactory {
	
    public static List<Lead> generateLeads (Integer numberToGenerate){
        List<Lead> leads = new List<Lead>();
        for(Integer i = 0; i < numberToGenerate; i++){
            Lead record = new Lead();
            record.FirstName = 'TestFName'+i;
            record.LastName = i+'TestLName';
            record.Email = 'test'+i+'@psgcode.com';
            record.Phone = '829774263'+i;
            record.Rating = 'Hot';
            record.Company = 'PSG Code';
            leads.Add(record);
        }
        return leads;
    }
    
     public static List<Lead> generateDuplicateLeads (Integer numberToGenerate){
        List<Lead> leads = new List<Lead>();
        for(Integer i = 0; i < numberToGenerate; i++){
            Lead record = new Lead();
            record.FirstName = 'TestFName';
            record.LastName = 'TestLName';
            record.Email = 'test@psgcode.com';
            record.Phone = '8297742633';
            record.Rating = 'Hot';
            record.Company = 'PSG Code';
            leads.Add(record);
        }
        return leads;
    }
    
 /*   public static List<Contact> generateDuplicateContacts (Integer numberToGenerate){
        List<Contact> contacts = new List<Contact>();
        
        Account ac = new Account();
        ac.Name = 'PSG Code';
        insert ac;
        
        for(Integer i = 0; i < numberToGenerate; i++){
            Contact record = new Contact();
            record.FirstName = 'TestFName';
            record.LastName = 'TestLName';
            record.Email = 'test@psgcode.com';
            record.Phone = '8297742633';
            record.AccountId = ac.Id;
            contacts.Add(record);
        }
        return contacts;
    }*/   
    
    public static List<User> generateUsers(Integer numberToGenerate, String profileName) {
    List<User> users = new List<User>();

    // Intentar encontrar el Profile exacto
    Profile userProfile;
    List<Profile> profiles = [SELECT Id FROM Profile WHERE Name = :profileName LIMIT 1];
    
    if (profiles.isEmpty()) {
        // Si no lo encuentra, buscar uno que contenga 'Admin' o 'Standard' en el nombre
        profiles = [SELECT Id FROM Profile WHERE Name LIKE '%Admin%' OR Name LIKE '%Standard%' LIMIT 1];
    }

    if (!profiles.isEmpty()) {
        userProfile = profiles[0];
    } else {
        // Si aún no encuentra nada, lanzar error para saber que no hay perfil
        throw new AuraHandledException('No se encontró un Profile válido para crear el User de prueba.');
    }

    for (Integer i = 0; i < numberToGenerate; i++) {
        String uniqueSuffix = String.valueOf(System.currentTimeMillis()) + i; // Para asegurar que siempre sea único
        User testUser = new User(
            FirstName = 'Test',
            LastName = 'User' + i,
            Alias = ('usr' + i).left(8),
            Email = 'user' + uniqueSuffix + '@test.com',
            Username = 'user' + uniqueSuffix + '@test.com',
            ProfileId = userProfile.Id,
            TimeZoneSidKey = 'America/New_York',
            LocaleSidKey = 'en_US',
            EmailEncodingKey = 'UTF-8',
            LanguageLocaleKey = 'en_US'
        );
        users.add(testUser);
    }

    return users;
}


	

    public static List<Account> generateAccounts(Integer numberToGenerate) {
        List<Account> accounts = new List<Account>();
        for (Integer i = 0; i < numberToGenerate; i++) {
            Account acc = new Account(Name = 'Test Account ' + i);
            accounts.add(acc);
        }
        return accounts;
    }

    
    public static List<Contact> generateContacts(Integer numberToGenerate, List<Account> accounts) {
        List<Contact> contacts = new List<Contact>();
        for (Integer i = 0; i < numberToGenerate; i++) {
            Contact con = new Contact(
                FirstName = 'Test Contact ' + i,
                LastName = 'LastName' + i,
                Phone = '8297742633',
                AccountId = accounts[i].Id,
                Email = 'test@psgcode.com'
            );
            contacts.add(con);
        }
        return contacts;
    }
	
   public static List<Opportunity> generateOpportunities(Integer numberToGenerate,  List<User> owners, List<User> agents) {
   // public static List<Opportunity> generateOpportunities(Integer numberToGenerate, List<Account> accounts, List<User> owners, List<User> agents) {
        
       List<Opportunity> opportunities = new List<Opportunity>();
    
        for (Integer i = 0; i < numberToGenerate; i++) {
            Opportunity opp = new Opportunity(
                Name = 'Test Opportunity ' + i,
                CloseDate = Date.today(),
                StageName = 'Prospecting',
                OwnerId = owners[0].Id//, 
              //  AccountId = accounts[0].Id,
              // psg_agent_2__c = agents.isEmpty() ? null : agents[0].Id 
            );
            opportunities.add(opp);
        }
        return opportunities;
    }

	 // Generar múltiples Commissions
    public static List<psg_Commission__c> generateCommissions(Integer numberToGenerate, List<Opportunity> opportunities) {
        List<psg_Commission__c> commissions = new List<psg_Commission__c>();
        for (Integer i = 0; i < numberToGenerate; i++) {
            psg_Commission__c commission = new psg_Commission__c(
                psg_Opportunity__c = opportunities[i].Id
            );
            commissions.add(commission);
        }
        return commissions;
    }
}