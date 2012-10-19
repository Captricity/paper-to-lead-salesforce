/* Apex class to represent a Field object in Captricity */

public with sharing class CaptricityField {
    public String id { get; set; }
    public String name { get; set; }
    public String csvLabel { get; set; }
    public Id documentId { get; set; }
    
    @future (callout=true)
    public static void fetchAndSyncFields(Map<Id, String> documentIds) {
        // Fetch the document fields and sync by inserting in to the Salesforce DB
        List<CaptricityField> fieldList = new List<CaptricityField>();
        Set<String> existingFields = new Set<String>();
        // Limit "Existing Fields" to the 7000 newest fields
        for (Captricity_Field__c f : [select Name from Captricity_Field__c order by Name desc limit 7000]) existingFields.add(f.Name);

        for (Id documentId : documentIds.keyset()) {
            // The deep document resource in captricity contains ALL the fields of the document
            String deepDocumentJSON = CaptricityCalloutUtil.fetchDeepDocument(documentIds.get(documentId));
            if (deepDocumentJSON == null) continue; // Failed to fetch fields for this document, so do nothing
    
            JSONParser parser = JSON.createParser(deepDocumentJSON);
            CaptricityDocument document = CaptricityDocument.parseDocumentJSON(parser);
            for (CaptricitySheet sheet : document.sheets) {
                for (CaptricityField field: sheet.fields) {
                    field.csvLabel = 'page' + (Integer.valueof(sheet.pageNumber) + 1) + ':' + field.name;
                    field.documentId = documentId;
                    fieldList.add(field);
                }
            }
        }
            
        List<Captricity_Field__c> newFields = new List<Captricity_Field__c>();
        for (CaptricityField field : fieldList) {
            if (!existingFields.contains(field.id)) {
                newFields.add(new Captricity_Field__c(Name=field.id, Field_Name__c=field.name, Captricity_Document__c=field.documentId, CSV_Label__c=field.csvLabel));
                existingFields.add(field.id);
            }
        }
        insert newFields;
    }
        
    public static List<CaptricityField> parseFieldListJSON(JSONParser parser) {
        // Parses a JSON list as a list of CaptricityField. parser.getCurrentToken() must be a START_ARRAY token.
        // Will return with the parser's token at an END_ARRAY token that represents the end of the list.
        if (parser.getCurrentToken() == null) parser.nextToken(); // If we are at the very beginning of the parsing, get the first token
        List<CaptricityField> newFields = new List<CaptricityField>();
        while (parser.nextToken() != JSONToken.END_ARRAY) {
            if (parser.getCurrentToken() == JSONToken.START_OBJECT) {
                newFields.add(CaptricityField.parseFieldJSON(parser));
            }
        }
        return newFields;
    }
 
    
    public static CaptricityField parseFieldJson(JSONParser parser) {
        // Parses a JSON object as a CaptricityField. parser.getCurrentToken() must be a START_OBJECT token.
        // Will return with the parser's token at an END_OBJECT token that represents the end of the job JSON.
        if (parser.getCurrentToken() == null) parser.nextToken(); // If we are at the very beginning of the parsing, get the first token
        CaptricityField newField = new CaptricityField();
        String jsonFieldName;
        JSONToken currentToken;
        while (parser.nextToken() != JSONToken.END_OBJECT) {
            currentToken = parser.getCurrentToken();
            if (currentToken == JSONToken.FIELD_NAME) {
                jsonFieldName = parser.getText();
                if (jsonFieldName == 'id') {
                    parser.nextToken();
                    newField.id = parser.getText();
                } else if (jsonFieldName == 'name') {
                    parser.nextToken();
                    newField.name = parser.getText();
                }
            } else if (currentToken == JSONToken.START_OBJECT) {
                CaptricityJSONParseUtil.ignoreJSONObject(parser);
            } else if (currentToken == JSONToken.START_ARRAY) {
                CaptricityJSONParseUtil.ignoreJSONArray(parser);
            }
        }
        return newField;
    }
}