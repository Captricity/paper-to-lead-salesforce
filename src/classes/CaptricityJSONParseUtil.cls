/* Helper module for ignoring JSON objects and JSON Arrays by advancing the parser */

public with sharing class CaptricityJSONParseUtil {
    public static void ignoreJSONObject(JSONParser parser) {
        // Advances the parser until the end of an object, given that the parser's current token is a START_OBJECT token
        while (parser.nextToken() != JSONToken.END_OBJECT) {
            CaptricityJSONParseUtil.ignoreJSONObjectOrArray(parser);
        }
    }
    public static void ignoreJSONArray(JSONParser parser) {
        // Advances the parser until the end of an array, given that the parser's current token is a START_ARRAY token
        while (parser.nextToken() != JSONToken.END_ARRAY) {
            CaptricityJSONParseUtil.ignoreJSONObjectOrArray(parser);
        }
    }
    
    private static void ignoreJSONObjectOrArray(JSONParser parser) {
        // Convenience method, that selects which ignore function to use based on what the current token is
        if (parser.getCurrentToken() == JSONToken.START_OBJECT) {
            CaptricityJSONParseUtil.ignoreJSONObject(parser);
        } else if (parser.getCurrentToken() == JSONToken.START_ARRAY) {
            CaptricityJSONParseUtil.ignoreJSONArray(parser);
        }   
    }
}
