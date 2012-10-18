public with sharing class CaptricityCalloutUtil {
    public static final String HOST = 'https://shreddr.captricity.com';
    public static List<String> stubResponses = new List<String>();
    
    public static void insertDefaultSettings() {
        Captricity_App_Info__c CapSettings = Captricity_App_Info__c.getOrgDefaults();
        // Replace the client id, and secret key with your Captricity Third Party App information.
        // If you don't have one yet, you can easily sign up at http://captricity.com/api/
        CapSettings.Client_Id__c = 1;
        CapSettings.Client_Secret_Key__c = 'YOUR SECRET KEY';
        CapSettings.User_Agent_String__c = 'Salesforce v0.1';
        insert CapSettings;
    }
      
    public static HttpRequest setupCaptricityRequest(String method, String url, String accept) {
        Captricity_Token__c capToken = Captricity_Token__c.getOrgDefaults();
        Captricity_App_Info__c CapSettings = Captricity_App_Info__c.getOrgDefaults();
        String userAgentString = CapSettings.User_Agent_String__c;
        if (userAgentString == null) {
            userAgentString = 'Salesforce v0.1';
        }
        HttpRequest req = new HttpRequest();
        req.setMethod(method);
        if (accept != null)
            req.setHeader('Accept', accept);
        req.setHeader('User-Agent', userAgentString);
        req.setHeader('Captricity-API-Token', capToken.Captricity__API_token__c);
        req.setEndpoint(HOST + url);
        return req;
    }
 
    public static HttpResponse sendRequest(HttpRequest req) {
        HttpResponse res;
        if (system.Test.isRunningTest() && stubResponses.size() > 0) {
            res = new HttpResponse();
            res.setBody(stubResponses.remove(0));
        }
        else {
            Http h = new Http();
            res = h.send(req);
           
            // Cap redirect handling at retryCount
            Integer retryCount = 3;
            while (res.getStatusCode() == 301 && retryCount > 0) {
                req.setEndpoint(res.getHeader('Location'));
                res = h.send(req);
                retryCount --;
            }
            if (res.getStatusCode() == -1 || res.getStatusCode() == 301 || res.getStatusCode() == 404 || res.getStatusCode() == 400) {
                return null;
            }
        }
        return res;
    }
    
    private static String makeAPICall(String endPoint, String acceptFormat) {
        // Check if user has access. If not, return immediately
        if (!CaptricityAuthentication.authenticated()) return null;
        
        HttpRequest req = CaptricityCalloutUtil.setupCaptricityRequest('GET', endPoint, acceptFormat);
        HttpResponse res = CaptricityCalloutUtil.sendRequest(req);
        if (res == null) return null;
        
        return res.getBody();
    }
    
    public static String fetchResults(String jobId) {
        return makeAPICall('/api/v1/job/' + jobId + '/csv', 'text/csv');
    }
    
    public static String fetchJobs() {
        return makeAPICall('/api/v1/job/?status=completed', 'application/json');
    }
    
    public static String fetchDocuments() {
        return makeAPICall('/api/v1/document/', 'application/json');
    }
    
    public static String fetchDeepDocument(String documentId) {
        return makeAPICall('/api/v1/document/' + documentId + '/deep/', 'application/json');
    }
}
