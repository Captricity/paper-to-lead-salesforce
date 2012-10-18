/* Controller for the management page which lists the Document objects */

public with sharing class CaptricityManagementController {
    public boolean authorized { get; set; }
    public String syncMessage { get; set; }
    public String selectedTab { get; set; }
    public String selectedDocumentId { get; set; }
    public List<Captricity_Document__c> documents { get; set; }
    
    public PageReference authorize() {
        String authURL = CaptricityAuthentication.newAuthorization();
        return new PageReference(authURL);  
    }
    
    public PageReference checkAuthorization() {
        // Check to see if the app is authorized to access the user's data
        String signature = ApexPages.currentPage().getParameters().get('signature'); 
        if (signature != null) {
            return completeAuthorization(); // Probably a callback, so "redirect"
        }
        
        // Check if there is an entry for the API token. If there is, we are authorized.
        this.authorized = CaptricityAuthentication.authenticated();
        
        // If we are authorized, automatically sync the documents
        if (this.authorized) {
            ApexPages.Message authorized = new ApexPages.Message(ApexPages.Severity.CONFIRM, System.Label.Authorized);
            ApexPages.addMessage(authorized);
            sync(); 
            this.selectedTab = 'recent_document_settings';
        } else {
            this.selectedTab = 'authentication_settings';
        }
        
        return null;
    }
    
    public PageReference completeAuthorization() {
        // Complete the authorization request. This code should only be triggered if the user lands here after granting (or denying) access to the app on the Captricity request access page
        String signature = ApexPages.currentPage().getParameters().get('signature'); 
        if (signature == null) {
            // No signature, so probably no request so continue with nothing
            return null;    
        }
        
        if (!CaptricityAuthentication.verifyRequest(ApexPages.currentPage().getParameters())) {
            ApexPages.Message phishingAlert = new ApexPages.Message(ApexPages.Severity.CONFIRM, System.Label.PHISHING_ALERT);
            ApexPages.addMessage(phishingAlert);
            return null;
        }
        
        String granted = ApexPages.currentPage().getParameters().get('request-granted');
        String denied = ApexPages.currentPage().getParameters().get('request-denied');
        if (granted == 'true') {
            // If there is an existing token, overwrite it. Otherwise create a new one.
            String token = ApexPages.currentPage().getParameters().get('token');
            Captricity_Token__c CapSettings = Captricity_Token__c.getOrgDefaults();
            if (CapSettings.Captricity__API_Token__c == null) {
                CapSettings.Captricity__API_Token__c = token;
                insert CapSettings;
            } else {
                CapSettings.Captricity__API_Token__c = token;
                update CapSettings;
            }
            
            ApexPages.Message authorizationAccepted = new ApexPages.Message(ApexPages.Severity.CONFIRM, System.Label.Authorization_Accepted);
            ApexPages.addMessage(authorizationAccepted);
            this.authorized = true;
        }
        else if (denied == 'true') {
            ApexPages.Message authorizationDenied = new ApexPages.Message(ApexPages.Severity.CONFIRM, System.Label.Authorization_Denied);
            ApexPages.addMessage(authorizationDenied);
            this.authorized = false;
        }
        
        return null;
    }
    
    public PageReference sync() {
        // Sync the documents, and let the user know how many more documents are left to sync
        Integer remainingSyncCount = CaptricityDocument.syncDocuments();
        if (remainingSyncCount > 0) {
            ApexPages.Message remainingSyncMessage = new ApexPages.Message(ApexPages.Severity.CONFIRM, String.format(System.Label.Remaining_Sync, new String[] {String.valueof(remainingSyncCount)}));
            ApexPages.addMessage(remainingSyncMessage);
        }
        this.documents = [select id, Name, Id__c from Captricity_Document__c order by Id__c desc limit 5000];
        return null;
    }
    
    // Navigate to the document view so that the user can define field mappings
    public PageReference navigateToView() {
        Captricity_Document__c doc;
        for (Captricity_Document__c d : this.documents) {
            if (d.id == selectedDocumentId) {
                doc = d;
                break;
            }
        }
        return new ApexPages.StandardController(doc).view();
    }
}
