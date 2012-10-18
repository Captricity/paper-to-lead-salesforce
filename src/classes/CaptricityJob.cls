public class CaptricityJob {
    public String id { get; set; }
    public String name { get; set; }
    public Boolean extracted { get; set; }
    public Boolean readyToBeExtracted { get; set; }
    public String document_id { get; set; }
    
    public static List<CaptricityJob> fetchCaptricityJobs() {
        // Fetches the list of newest jobs from the Captricity server
    
        // Obtains the job list json from Captricity
        String jobsJSON =  CaptricityCalloutUtil.fetchJobs();
        if (jobsJSON == null) return null;
        
        JSONParser parser = JSON.createParser(jobsJSON);
        List<CaptricityJob> newJobs = parseJobListJSON(parser);
        
        Set<String> extractedJobs = new Set<String>();
        for (Captricity_Job__c job: [select Id__c from Captricity_Job__c order by Id__c desc limit 5000]) extractedJobs.add(String.valueof(job.Id__c.intValue()));
        Set<String> requiredLeadFields = new Set<String>();
        requiredLeadFields.add('Last Name');
        requiredLeadFields.add('Company');
        Map<String, Integer> documentFieldRelationCount = new Map<String, Integer>();
        for (Captricity__c fr : [select Captricity_Document__r.Id__c, Captricity_Field__c, Corresponding_Field_Name__c from Captricity__c where Object_Name__c='Lead']) {
            if (requiredLeadFields.contains(fr.Corresponding_Field_Name__c) && fr.Captricity_Field__c != null) {
                String key = String.valueof(fr.Captricity_Document__r.Id__c.intValue());
                Integer oldCount = documentFieldRelationCount.get(key);
                if (oldCount == null) {
                    documentFieldRelationCount.put(key, 1);
                }
                else {
                    documentFieldRelationCount.put(key, oldCount + 1);
                }
            }
        }
        
        for (CaptricityJob job : newJobs) {
            if (extractedJobs.contains(job.id)) {
                job.extracted = true;
            } else {
                job.extracted = false;
            }
            if (documentFieldRelationCount.get(job.document_id) == null || documentFieldRelationCount.get(job.document_id) < 2) {
                job.readyToBeExtracted = false;
            } else {
                job.readyToBeExtracted = true;
            }
        }
        
        return newJobs;
    }
    
    public static List<CaptricityJob> parseJobListJSON(JSONParser parser) {
        // Parses a JSON list as a list of CaptricityJob. parser.getCurrentToken() must be a START_ARRAY token.
        // Will return with the parser's token at an END_ARRAY token that represents the end of the list.
        if (parser.getCurrentToken() == null) parser.nextToken(); // If we are at the very beginning of the parsing, get the first token
        List<CaptricityJob> newJobs = new List<CaptricityJob>();
        while (parser.nextToken() != JSONToken.END_ARRAY && parser.getCurrentToken() != null) {
            if (parser.getCurrentToken() == JSONToken.START_OBJECT) {
                newJobs.add(CaptricityJob.parseJobJSON(parser));
            }
        }
        return newJobs;
    }
    
    public static CaptricityJob parseJobJSON(JSONParser parser) {
        // Parses a JSON object as a CaptricityJob. parser.getCurrentToken() must be a START_OBJECT token.
        // Will return with the parser's token at an END_OBJECT token that represents the end of the job JSON.
        if (parser.getCurrentToken() == null) parser.nextToken(); // If we are at the very beginning of the parsing, get the first token
        CaptricityJob newJob = new CaptricityJob();
        String jsonFieldName;
        JSONToken currentToken;
        while (parser.nextToken() != JSONToken.END_OBJECT) {
            currentToken = parser.getCurrentToken();
            if (currentToken == JSONToken.FIELD_NAME) {
                jsonFieldName = parser.getText();
                if (jsonFieldName == 'id') {
                    parser.nextToken();
                    newJob.id = parser.getText();
                } else if (jsonFieldName == 'name') {
                    parser.nextToken();
                    newJob.name = parser.getText();
                } else if (jsonFieldName == 'document_id') {
                    parser.nextToken();
                    newJob.document_id = parser.getText();
                }
            } else if (currentToken == JSONToken.START_OBJECT) {
                CaptricityJSONParseUtil.ignoreJSONObject(parser);
            } else if (currentToken == JSONToken.START_ARRAY) {
                CaptricityJSONParseUtil.ignoreJSONArray(parser);
            }
        }
        return newJob;
    }
}