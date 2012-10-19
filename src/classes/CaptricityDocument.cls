/* Defines an Apex class to represent Captricity Documents */

public with sharing class CaptricityDocument {
    public String id { get; set; }
    public String name { get; set; }
    public List<CaptricitySheet> sheets { get; set; }
    
    public CaptricityDocument() { this.sheets = new List<CaptricitySheet>(); }
        
    public static List<CaptricityDocument> fetchCaptricityDocuments() {
        // Fetches the list of documents associated with the currently authorized user from the Captricity server
        String documentsJSON = CaptricityCalloutUtil.fetchDocuments();
        if (documentsJSON == null) return null;
        JSONParser parser = JSON.createParser(documentsJSON);
        return parseDocumentListJSON(parser);
    }
    
    public static Integer syncDocuments() {
        // convenience method for fetching captricity document objects, and inserting them into the salesforce DB
        List<CaptricityDocument> capDocs = fetchCaptricityDocuments();
        Map<Id, String> newDocumentIds = new Map<Id, String>();
        List<Captricity_Document__c> newDocuments = new List<Captricity_Document__c>();
        Set<String> syncedDocuments = new Set<String>();
        for (Captricity_Document__c doc: [select Id__c from Captricity_Document__c order by Id__c desc limit 5000]) syncedDocuments.add(String.valueof(doc.Id__c.intValue()));
        
        // book keeping counters
        Integer prospectiveCalloutCount = 0;
        Integer actualDocumentCount = 0;
 
        for (CaptricityDocument doc: capDocs) {
            actualDocumentCount++;
            if (!syncedDocuments.contains(doc.id)) {
                // Keep count of the prospective call out count, and limit to the number of callouts allowed
                prospectiveCalloutCount += 1;
                if (prospectiveCalloutCount < 10) {
                    newDocuments.add(new Captricity_Document__c(Name=doc.name, Id__c=Integer.valueof(doc.id)));
                    syncedDocuments.add(doc.id);
                } else {
                    break; // Since we only add one at a time, there is no prospect for passing condition later
                }
            }
        }
        
        insert newDocuments;
        List<Captricity__c> newFieldRelations = new List<Captricity__c>();
        for (Captricity_Document__c doc: newDocuments) {
            // initialize field relations (mapping from lead fields to captricity fields) for this document
            newFieldRelations.add(new Captricity__c(Corresponding_Field_Name__c='First Name', Captricity_Document__c=doc.id, Object_Name__c='Lead'));
            newFieldRelations.add(new Captricity__c(Corresponding_Field_Name__c='Last Name', Captricity_Document__c=doc.id, Object_Name__c='Lead'));
            newFieldRelations.add(new Captricity__c(Corresponding_Field_Name__c='Company', Captricity_Document__c=doc.id, Object_Name__c='Lead'));
            newFieldRelations.add(new Captricity__c(Corresponding_Field_Name__c='Email', Captricity_Document__c=doc.id, Object_Name__c='Lead'));
            newFieldRelations.add(new Captricity__c(Corresponding_Field_Name__c='Phone Number', Captricity_Document__c=doc.id, Object_Name__c='Lead'));
            newDocumentIds.put(doc.id, String.valueof(doc.Id__c.intValue()));
        }
        insert newFieldRelations;

        CaptricityField.fetchAndSyncFields(newDocumentIds);

        // Return the number of documents that still need to be synced
        return actualDocumentCount - syncedDocuments.size();
    }
    
    public static List<CaptricityDocument> parseDocumentListJSON(JSONParser parser) {
        // Parses a JSON list as a list of CaptricityDocument. parser.getCurrentToken() must be a START_ARRAY token.
        // Will return with the parser's token at an END_ARRAY token that represents the end of the list.
        if (parser.getCurrentToken() == null) parser.nextToken(); // If we are at the very beginning of the parsing, get the first token
        List<CaptricityDocument> newDocuments = new List<CaptricityDocument>();
        while (parser.nextToken() != JSONToken.END_ARRAY && parser.getCurrentToken() != null) {
            if (parser.getCurrentToken() == JSONToken.START_OBJECT) {
                newDocuments.add(CaptricityDocument.parseDocumentJSON(parser));
            }
        }
        return newDocuments;
    }
 
    
    public static CaptricityDocument parseDocumentJson(JSONParser parser) {
        // Parses a JSON object as a CaptricityDocument. parser.getCurrentToken() must be a START_OBJECT token.
        // Will return with the parser's token at an END_OBJECT token that represents the end of the job JSON.
        if (parser.getCurrentToken() == null) parser.nextToken(); // If we are at the very beginning of the parsing, get the first token
        CaptricityDocument newDocument = new CaptricityDocument();
        String jsonFieldName;
        JSONToken currentToken;
        while (parser.nextToken() != JSONToken.END_OBJECT) {
            currentToken = parser.getCurrentToken();
            if (currentToken == JSONToken.FIELD_NAME) {
                jsonFieldName = parser.getText();
                if (jsonFieldName == 'name') {
                    parser.nextToken();
                    newDocument.name = parser.getText();
                } else if (jsonFieldName == 'id') {
                    parser.nextToken();
                    newDocument.id = parser.getText();
                } else if (jsonFieldName == 'sheets') {
                    parser.nextToken();
                    newDocument.sheets.addAll(CaptricitySheet.parseSheetListJSON(parser));
                }
            } else if (currentToken == JSONToken.START_OBJECT) {
                System.debug('Ignoring object');
                CaptricityJSONParseUtil.ignoreJSONObject(parser);
            } else if (currentToken == JSONToken.START_ARRAY) {
                System.debug('Ignoring list');
                CaptricityJSONParseUtil.ignoreJSONArray(parser);
            }
        }
        return newDocument;
    }
}