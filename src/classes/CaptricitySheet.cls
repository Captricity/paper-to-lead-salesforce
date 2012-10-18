public with sharing class CaptricitySheet {
    public String id { get; set; }
    public String pageNumber { get; set; }
    public List<CaptricityField> fields { get; set; }
    
    public CaptricitySheet() { this.fields = new List<CaptricityField>(); }
    
    public String sheetInfo() {
        return id + ':' + pageNumber;
    }
    
    public static List<CaptricitySheet> parseSheetListJSON(JSONParser parser) {
        // Parses a JSON list as a list of CaptricitySheet. parser.getCurrentToken() must be a START_ARRAY token.
        // Will return with the parser's token at an END_ARRAY token that represents the end of the list.
        if (parser.getCurrentToken() == null) parser.nextToken(); // If we are at the very beginning of the parsing, get the first token
        List<CaptricitySheet> newSheets = new List<CaptricitySheet>();
        while (parser.nextToken() != JSONToken.END_ARRAY) {
            if (parser.getCurrentToken() == JSONToken.START_OBJECT) {
                newSheets.add(CaptricitySheet.parseSheetJSON(parser));
            }
        }
        return newSheets;
    }
 
    
    public static CaptricitySheet parseSheetJson(JSONParser parser) {
        // Parses a JSON object as a CaptricityJob. parser.getCurrentToken() must be a START_OBJECT token.
        // Will return with the parser's token at an END_OBJECT token that represents the end of the job JSON.
        if (parser.getCurrentToken() == null) parser.nextToken(); // If we are at the very beginning of the parsing, get the first token
        CaptricitySheet newSheet = new CaptricitySheet();
        String jsonFieldName;
        JSONToken currentToken;
        while (parser.nextToken() != JSONToken.END_OBJECT && parser.getCurrentToken() != null) {
            currentToken = parser.getCurrentToken();
            if (currentToken == JSONToken.FIELD_NAME) {
                jsonFieldName = parser.getText();
                if (jsonFieldName == 'id') {
                    parser.nextToken();
                    newSheet.id = parser.getText();
                } else if (jsonFieldName == 'page_number') {
                    parser.nextToken();
                    newSheet.pageNumber = parser.getText();
                } else if (jsonFieldName == 'fields') {
                    parser.nextToken();
                    newSheet.fields.addAll(CaptricityField.parseFieldListJSON(parser));
                }
            } else if (currentToken == JSONToken.START_OBJECT) {
                CaptricityJSONParseUtil.ignoreJSONObject(parser);
            } else if (currentToken == JSONToken.START_ARRAY) {
                CaptricityJSONParseUtil.ignoreJSONArray(parser);
            }
        }
        return newSheet;
    }
}