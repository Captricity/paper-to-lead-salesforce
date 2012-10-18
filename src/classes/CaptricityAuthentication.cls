public class CaptricityAuthentication {
    public static Boolean authenticated() {
        Captricity_Token__c capTokens = Captricity_Token__c.getOrgDefaults();
        if (capTokens.Captricity__API_Token__c != null) {
            return true;
        } else {
            return false;
        }
    }
    
    public static String newAuthorization() {
        if (Captricity_App_Info__c.getOrgDefaults().Client_Id__c == null) {
            CaptricityCalloutUtil.insertDefaultSettings();
        }
        String baseURL = CaptricityCalloutUtil.HOST + '/accounts/request-access/';
        Map<String, String> requestParams = new Map<String, String>();
        requestParams.put('third-party-id', String.valueof(Captricity_App_Info__c.getOrgDefaults().Client_Id__c.intvalue()));
        requestParams.put('return-url', 'https://'+ApexPages.currentPage().getHeaders().get('Host')+Page.Captricity_Management.getUrl());
        requestParams.put('signature', CaptricityAuthentication.signedRequest(requestParams));
        
        List<String> keys = new List<String>();
        keys.addAll(requestParams.keySet());
        String firstKey = keys.remove(0);
        String params = firstKey + '=' + EncodingUtil.urlEncode(requestParams.get(firstKey), 'UTF-8');
        for (String key : keys) {
            params += '&' + key + '=' + EncodingUtil.urlEncode(requestParams.get(key), 'UTF-8');
        }
        baseURL += '?' + params;
        return baseURL;
    }
    
    public static boolean verifyRequest(Map<String, String> params) {
        String checkSignature = params.get('signature');
        params.remove('signature');
        String signature = signedRequest(params);
        
        return checkSignature == signature;
    }
    
    private static String signedRequest(Map<String, String> kvPairs) {
        String signature = '';
        List<String> sortedKeys = new List<String>();
        sortedKeys.addAll(kvPairs.keySet());
        sortedKeys.sort();
        
        String firstKey = sortedKeys.remove(0);
        signature += firstKey + '=' + EncodingUtil.urlEncode(kvPairs.get(firstKey), 'UTF-8');
        for (String key : sortedKeys) {
            signature += '&' + key + '=' + EncodingUtil.urlEncode(kvPairs.get(key), 'UTF-8');
        }
        signature = Captricity_App_Info__c.getOrgDefaults().Client_Secret_Key__c + ':' + signature;
        
        return EncodingUtil.convertToHex(Crypto.generateDigest('SHA-256', Blob.valueOf(signature)));
    }
}