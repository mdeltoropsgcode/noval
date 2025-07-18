public with sharing class PSG_LeadHelper{
    // si existe un lead asignarlo a la campaña correspondiente y enviar un correo
    // crear metodo que reciba los nuevos leads
    public static void assignLead(List<Lead> leads){

        List<CampaignMember> membersToAdd = new List<CampaignMember>();

        // este metodo va a verficiar si el lead esta duplicado

        List<PSG_LeadDuplicateChecker.DuplicateInfo> results = PSG_LeadDuplicateChecker.checkForDuplicateLeads(leads);

        for (PSG_LeadDuplicateChecker.DuplicateInfo info : results){
            if (info.isDuplicate){
                System.debug('Duplicado encontrado: ' + info);
            }

            // ver si el lead viene de una campaña, si tiene el proyecto lleno
            // si es asi busque los lead duplicado que existen

            if (info.existingRecordType == 'Contact'){
                System.debug('Es tipo contacto');
                Contact existingRecord = [SELECT Id, psg_web_project__c
                                          FROM Contact
                                          LIMIT 1];

                CampaignMember member = new CampaignMember();
                member.ContactId = existingRecord.Id;
                member.Status = 'Sent'; // revisar

                if (String.isNotEmpty(existingRecord.psg_web_project__c)){
                    System.debug('Tiene un project');

                    // buscar la campaña y agregar el que existe como member
                    List<Campaign> campaigns = [SELECT Id
                                                FROM Campaign
                                                WHERE Name = :existingRecord.psg_web_project__c
                                                LIMIT 1];
                    Campaign contactCampaign;

                    // si no existe la campaña crearla y ponerlo member
                    if (campaigns.isEmpty()){
                        System.debug('No se encontro la campaña');
                        contactCampaign = new Campaign(
                            Name = existingRecord.psg_web_project__c, 
                            IsActive = true
                        );
                        insert contactCampaign;
                    } else{
                        contactCampaign = campaigns[0];
                    }
                    member.CampaignId = contactCampaign.Id;

                } else{
                    System.debug('Buscar el default Campaign');
                    // si el web project viene vacio ponerlo como member el la default campaign
                    Campaign defaultCampaign = [SELECT Id
                                                FROM Campaign
                                                WHERE Name = 'Default Campaign'
                                                LIMIT 1];

                    member.CampaignId = defaultCampaign.Id;
                }

                membersToAdd.add(member);

                // LEAD
            } else{
                System.debug('Es tipo Lead');
                Lead existingRecord = [SELECT Id, psg_web_project__c
                                          FROM Lead
                                          LIMIT 1];

                CampaignMember member = new CampaignMember();
                member.leadId = existingRecord.Id;
                member.Status = 'Sent'; // revisar

                if (String.isNotEmpty(existingRecord.psg_web_project__c)){
                    System.debug('Tiene un project');

                    // buscar la campaña y agregar el que existe como member
                    List<Campaign> campaigns = [SELECT Id
                                                FROM Campaign
                                                WHERE Name = :existingRecord.psg_web_project__c
                                                LIMIT 1];
                    Campaign leadCampaign;

                    // si no existe la campaña crearla y ponerlo member
                    if (campaigns.isEmpty()){
                        System.debug('No se encontro la campaña');
                        leadCampaign = new Campaign(
                            Name = existingRecord.psg_web_project__c, 
                            IsActive = true
                        );
                        insert leadCampaign;
                    } else{
                        leadCampaign = campaigns[0];
                    }
                    member.CampaignId = leadCampaign.Id;

                } else{
                    System.debug('Buscar el default Campaign');
                    // si el web project viene vacio ponerlo como member el la default campaign
                    Campaign defaultCampaign = [SELECT Id
                                                FROM Campaign
                                                WHERE Name = 'Default Campaign'
                                                LIMIT 1];

                    member.CampaignId = defaultCampaign.Id;
                }

                membersToAdd.add(member);
            }
        }

        // Eliminar duplicados en las listas
        membersToAdd = removeDuplicateMembers(membersToAdd);
        System.debug('Listado de member a agregar');
        for (CampaignMember member : membersToAdd){
            System.debug(member);
        }

        try{
            insert membersToAdd;
            System.debug('Se insertaron los datos');
        } catch (Exception e){
            System.debug('Error occurred while inserting records: ' + e.getMessage());
            System.debug('Stack Trace: ' + e.getStackTraceString());
        }

        // enviar el correo al dueño
    }

    // Método para eliminar duplicados en la lista de miembros de campaña
    private static List<CampaignMember> removeDuplicateMembers(List<CampaignMember> members){
        Set<Id> memberIds = new Set<Id>();
        List<CampaignMember> uniqueMembers = new List<CampaignMember>();
        for (CampaignMember member : members){
            Id memberId = member.ContactId != null ? member.ContactId : member.LeadId;
            if (!memberIds.contains(memberId)){
                memberIds.add(memberId);
                uniqueMembers.add(member);
            }
        }
        return uniqueMembers;
    }

}