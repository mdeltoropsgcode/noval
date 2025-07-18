public class CaseChecklistController {
    public List<Categoria> categorias { get; set; }
    
    public class Categoria {
        public String Name { get; set; }
        public List<Criterios_de_Checklist__c> criterios { get; set; }
    }
    
    
    public Post_Sale_Form__c caso {
        get {
            if (standardCtrl == null) return null;
            return (Post_Sale_Form__c)standardCtrl.getRecord();
        }
    }
    private ApexPages.StandardController standardCtrl;
    
    public Integer CantLlavesPrincipal {
        get {
            if (caso != null) return Integer.valueOf(caso.PSG_Number_of_Main_Door_Keys__c);
            return 0;
        }
        set {
            if (caso != null) caso.PSG_Number_of_Main_Door_Keys__c = value;
        }
    }
    public Integer CantLlavesInterior {
        get {
            if (caso != null) return Integer.valueOf(caso.PSG_Number_of_Interior_Door_Keys__c);
            return 0;
        }
        set {
            if (caso != null) caso.PSG_Number_of_Interior_Door_Keys__c = value;
        }
    }
    public Integer CantOtrasLlaves {
        get {
            if (caso != null) return Integer.valueOf(caso.PSG_Other_Keys__c);
            return 0;
        }
        set {
            if (caso != null) caso.PSG_Other_Keys__c = value;
        }
    }
    public Integer CantTotalLlaves {
        get {
            return (CantLlavesPrincipal==null?0:CantLlavesPrincipal) + (CantLlavesInterior==null?0:CantLlavesInterior) + (CantOtrasLlaves==null?0:CantOtrasLlaves);
        }
    }
    
    public CaseChecklistController(ApexPages.StandardController stdCtrl) {
        if (stdCtrl == null) return;
        if(!Test.isRunningTest()) stdCtrl.addFields(new List<String>{'PSG_Number_of_Main_Door_Keys__c','PSG_Number_of_Interior_Door_Keys__c','PSG_Other_Keys__c','PSG_SIGN_1__c','PSG_SIGN_2__c','PSG_SIGN_3__c','PSG_SIGN_4__c','Listing__r.pba__Property__c'});
        standardCtrl = stdCtrl;
        
        Map<String, List<Criterios_de_Checklist__c>> criteriosMap = new Map<String, List<Criterios_de_Checklist__c>>();

        for (Criterios_de_Checklist__c criterio : [SELECT Id, Name, Condicion__c, Categoria__c, Aprobacion__c, Observacion__c FROM Criterios_de_Checklist__c WHERE Caso__c = :caso.Id]) {
            List<Criterios_de_Checklist__c> criteriosList;
            if (criteriosMap.containsKey(criterio.Categoria__c)) criteriosList = criteriosMap.get(criterio.Categoria__c);
            else criteriosList = new List<Criterios_de_Checklist__c>();
            criteriosList.add(criterio);
            criteriosMap.put(criterio.Categoria__c, criteriosList);
        }
        if (criteriosMap.isEmpty()) {
            Id configChecklist;
            for (Config_de_Checklist__mdt config : [SELECT Id FROM Config_de_Checklist__mdt WHERE DeveloperName =:caso.PSG_Property_Formula__c OR DeveloperName = 'DEFAULT' LIMIT 1])
                configChecklist = config.Id;
            if (configChecklist != null) {
                for (Criterio_de_checklist__mdt config : [SELECT Id, Criterio__c, Categoria__c, Condicion_de_aceptacion__c FROM Criterio_de_checklist__mdt WHERE Configuracion__c = :configChecklist]) {
                    if (String.isBlank(config.Categoria__c)) continue;
                    List<Criterios_de_Checklist__c> criteriosList;
                    if (criteriosMap.containsKey(config.Categoria__c)) criteriosList = criteriosMap.get(config.Categoria__c);
                    else criteriosList = new List<Criterios_de_Checklist__c>();
                    Criterios_de_Checklist__c criterio = new Criterios_de_Checklist__c();
                    criterio.Categoria__c = config.Categoria__c;
                    criterio.Condicion__c = config.Condicion_de_aceptacion__c;
                    criterio.Name = config.Criterio__c;
                    criterio.Caso__c = caso.Id;
                    criteriosList.add(criterio);
                    criteriosMap.put(config.Categoria__c, criteriosList);
                }
            }
        }
        categorias = new List<Categoria>();
        for (String cat : criteriosMap.keySet()) {
            Categoria catObj = new Categoria();
            catObj.Name = cat;
            catObj.criterios = criteriosMap.get(cat);
            categorias.add(catObj);
        }
    }
    
    public String sign1 {
        get {
            if (caso != null) return caso.PSG_SIGN_1__c;
            return '';
        }
        set {
            if (caso != null) caso.PSG_SIGN_1__c = value;
        }
    }
    public String sign2 {
        get {
            if (caso != null) return caso.PSG_SIGN_2__c;
            return '';
        }
        set {
            if (caso != null) caso.PSG_SIGN_2__c = value;
        }
    }
    public String sign3 {
        get {
            if (caso != null) return caso.PSG_SIGN_3__c;
            return '';
        }
        set {
            if (caso != null) caso.PSG_SIGN_3__c = value;
        }
    }
    public String sign4 {
        get {
            if (caso != null) return caso.PSG_SIGN_4__c;
            return '';
        }
        set {
            if (caso != null) caso.PSG_SIGN_4__c = value;
        }
    }
    
    public PageReference setFechaEntrega() {
        if (caso.PSG_Approve_to_receive_the_property__c == 'Sí') caso.PSG_Delivery_Reception_Date__c = Date.today();
        else caso.PSG_Delivery_Reception_Date__c = null;
        return null;
    }
    
    public PageReference customSave() {
        if (caso == null) return null;
        
        Map<String, Attachment> attachments = new Map<String, Attachment>();
        for (Attachment a : [SELECT Id, Name FROM Attachment WHERE ParentId = :caso.Id]) attachments.put(a.Name, a);
        List<Attachment> attachmentsToDelete = new List<Attachment>();
        
        System.debug(sign1);
        if (String.isNotBlank(sign1) && sign1.contains(',')) {
            Blob myBlob = EncodingUtil.base64Decode(sign1.substringAfter(','));
            Attachment a;
            String attachmentName = 'sign1';
            if (attachments.containsKey(attachmentName)) {
                a = attachments.get(attachmentName);
                a.Body=myBlob;
            } else a = new Attachment(ParentId=caso.Id,Name=attachmentName,Body=myBlob);
            attachments.put(attachmentName, a);
        } else if (attachments.containsKey('sign1')) {
            attachmentsToDelete.add(attachments.get('sign1'));
            attachments.remove('sign1');
        }
        
        if (String.isNotBlank(sign2) && sign2.contains(',')) {
            Blob myBlob = EncodingUtil.base64Decode(sign2.substringAfter(','));
            Attachment a;
            String attachmentName = 'sign2';
            if (attachments.containsKey(attachmentName)) {
                a = attachments.get(attachmentName);
                a.Body=myBlob;
            } else a = new Attachment(ParentId=caso.Id,Name=attachmentName,Body=myBlob);
            attachments.put(attachmentName, a);
        } else if (attachments.containsKey('sign2')) {
            attachmentsToDelete.add(attachments.get('sign2'));
            attachments.remove('sign2');
        }
        
        if (String.isNotBlank(sign3) && sign3.contains(',')) {
            Blob myBlob = EncodingUtil.base64Decode(sign3.substringAfter(','));
            Attachment a;
            String attachmentName = 'sign3';
            if (attachments.containsKey(attachmentName)) {
                a = attachments.get(attachmentName);
                a.Body=myBlob;
            } else a = new Attachment(ParentId=caso.Id,Name=attachmentName,Body=myBlob);
            attachments.put(attachmentName, a);
        } else if (attachments.containsKey('sign3')) {
            attachmentsToDelete.add(attachments.get('sign3'));
            attachments.remove('sign3');
        }
        
        if (String.isNotBlank(sign4) && sign4.contains(',')) {
            Blob myBlob = EncodingUtil.base64Decode(sign4.substringAfter(','));
            Attachment a;
            String attachmentName = 'sign4';
            if (attachments.containsKey(attachmentName)) {
                a = attachments.get(attachmentName);
                a.Body=myBlob;
            } else a = new Attachment(ParentId=caso.Id,Name=attachmentName,Body=myBlob);
            attachments.put(attachmentName, a);
        } else if (attachments.containsKey('sign4')) {
            attachmentsToDelete.add(attachments.get('sign4'));
            attachments.remove('sign4');
        }
        
        upsert attachments.values();
        if (attachmentsToDelete.size() > 0) delete attachmentsToDelete;
        
        List<Criterios_de_Checklist__c> criterios = new List<Criterios_de_Checklist__c>();
        for (Categoria cat : categorias) criterios.addAll(cat.criterios);
        upsert criterios;
        return standardCtrl.save();
    }
    
    public String UITheme {
        get {
            return UserInfo.getUiThemeDisplayed();
        }
    }
}