public with sharing class CaptricitySetupExtractionController {
    private final Captricity_Document__c document;
    public String selectedField { get; set; }
    public String selectedFieldRelation { get; set; }
    
    public CaptricitySetupExtractionController(ApexPages.StandardController stdController) {
        document = (Captricity_Document__c)stdController.getRecord();
    }
    
    public List<SelectOption> getFields() {
        List<Captricity_Field__c> fields = [select id, Field_Name__c from Captricity_Field__c where Captricity_Document__c = :document.id];
        List<SelectOption> options = new List<SelectOption>();
        options.add(new SelectOption('', '--None--'));
        for (Captricity_Field__c field : fields) {
            options.add(new SelectOption(field.id, field.Field_Name__c));
        }
        return options;
    }
    
    public void quickSaveField() {
        update document.captricity_field_relations__r;
    }
}