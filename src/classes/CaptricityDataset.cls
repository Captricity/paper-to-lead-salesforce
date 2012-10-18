public with sharing class CaptricityDataset {
    public static Integer extractLeads(String jobId, String documentId) {
        // Extracts leads from this job. Returns number of leads inserted.
        // If there is an error, will return -1
        String csvContent = CaptricityCalloutUtil.fetchResults(jobId);
        if (csvContent == null) return -1;
        
        return CaptricityDataset.parseDatasetResponseToLead(csvContent, documentId);
    }
        
    private static List<String> cleanCSVRow(String csvRow) {
        List<String> cleanFields = new List<String>();
        Boolean makeCompositeField = false;
        String compositeField;
        for (String field : csvRow.split(',')) {
            if (field.startsWith('"') && field.endsWith('"')) {
                cleanFields.add(field.replaceAll('DBLQT', '"'));
            }
            else if (field.startsWith('"')) {
                makeCompositeField = true;
                compositeField = field;
            }
            else if (field.endsWith('"')) {
                compositeField += ',' + field;
                cleanFields.add(compositeField.replaceAll('DBLQT', '"'));
                makeCompositeField = false;
            }
            else if (makeCompositeField) {
                compositeField += ',' + field;
            }
            else {
                cleanFields.add(field.replaceAll('DBLQT', '"'));
            }
        }
        return cleanFields;
    }
    
    public static Integer parseDatasetResponseToLead(String csvContent, String documentId) {
        csvContent = csvContent.replaceAll(',"""', ',"DBLQT').replaceall('""",','DBLQT",');
        csvContent = csvContent.replaceAll('""', 'DBLQT');
        List<String> lines = new List<String>();
        lines = csvContent.split('(\r\n|\n)');
        Captricity__c[] fieldRelations = [select Corresponding_Field_Name__c, Captricity_Field__r.CSV_Label__c from Captricity__c where Captricity__c.Captricity_Document__r.Id__c = :Decimal.valueof(documentId) and Captricity__c.Object_Name__c = 'Lead'];
        Integer emailIndex = null, firstNameIndex = null, lastNameIndex = null, companyIndex = null, phoneNumberIndex = null;
        
        List<String> fieldHeaders = cleanCSVRow(lines[0]);
        Integer index = 0;
        for (String fieldHeader : fieldHeaders) {
            for (Captricity__c fieldRelation : fieldRelations) {
                if (fieldRelation.Captricity_Field__r.CSV_Label__c == fieldHeader) {
                    if (fieldRelation.Corresponding_Field_Name__c == 'Email') emailIndex = index;
                    else if (fieldRelation.Corresponding_Field_Name__c == 'First Name') firstNameIndex = index;
                    else if (fieldRelation.Corresponding_Field_Name__c == 'Last Name') lastNameIndex = index;
                    else if (fieldRelation.Corresponding_Field_Name__c == 'Company') companyIndex = index;
                    else if (fieldRelation.Corresponding_Field_Name__c == 'Phone Number') phoneNumberIndex = index;
                    break;
                }
            }
            index += 1;
        }
        lines.remove(0);
        
        String pat = '[a-zA-Z0-9\\.\\!\\#\\$\\%\\&\\*\\/\\=\\?\\^\\_\\+\\-\\`\\{\\|\\}\\~\'._%+-]+@[a-zA-Z0-9\\-.-]+\\.[a-zA-Z]+';
        List<Lead> newLeads = new List<Lead>();
        for (String line : lines) {
            List<String> fields = cleanCSVRow(line);
            String lastName, firstname, company, email, phoneNum;
            if (lastNameIndex != null) {
                lastName = fields[lastNameIndex];
            }
            if (firstNameIndex != null) {
                firstName = fields[firstNameIndex];
            }
            if (emailIndex != null && Pattern.matches(pat, fields[emailIndex])) {
                email = fields[emailIndex];
            }
            if (companyIndex != null) {
                company = fields[companyIndex];
            }
            if (phoneNumberIndex != null) {
                phoneNum = fields[phoneNumberIndex];
            }
            newLeads.add(new Lead(LastName=lastName, FirstName=firstName, Company=company, Email=email, Phone=phoneNum));
        }
        insert newLeads;
        
        return newLeads.size();
    }
}