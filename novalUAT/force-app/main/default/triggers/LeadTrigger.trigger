trigger LeadTrigger on Lead (before insert) {
    // Buscar el Id del lead duplicado a traves del correo
    Lead l = [SELECT Id, Name FROM Lead WHERE Email = :Trigger.new[0].Email LIMIT 1];
    
    CampaignMember member = new CampaignMember();
    member.CampaignId = '701D3000000iDqrIAE';
    member.LeadId = l.Id;
    insert member;

}