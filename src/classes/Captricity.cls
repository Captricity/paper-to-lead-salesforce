public with sharing class Captricity {
    public boolean authorized { get; set; }
    public String jobId { get; set; }
    public String documentId { get; set; }

    public List<CaptricityJob> getCaptricityJobs() {
        return CaptricityJob.fetchCaptricityJobs();
    }
        
    public PageReference checkAuthorization() {
        this.authorized = CaptricityAuthentication.authenticated();
        return null;
    }
    
    public PageReference extractLeads() {
        Integer numExtracted = CaptricityDataset.extractLeads(jobId, documentId);
        
        if ([select id from Captricity_Job__c where Id__c=:Decimal.valueof(jobId)].size() == 0) {
            Captricity_Job__c newExtract = new Captricity_Job__c(Id__c=Decimal.valueof(jobId));
            insert newExtract;
        }
        
        PageReference selfPage = Page.Captricity;
        selfPage.setRedirect(true);
        
        return selfPage;
    }
}