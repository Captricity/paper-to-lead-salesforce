@isTest
private class CaptricityTest {
    static testMethod void testInstallScript() {
        CaptricityPostInstallScript postInstallScript = new CaptricityPostInstallScript();
        Test.testInstall(postInstallScript, null);
        Captricity_App_Info__c CapSettings = Captricity_App_Info__c.getOrgDefaults();
        System.assertNotEquals(CapSettings.Client_Id__c, null);
        System.assertNotEquals(CapSettings.Client_Secret_Key__c, null);
    }
    
    static testMethod void testReInstallScript() {
        CaptricityPostInstallScript postInstallScript = new CaptricityPostInstallScript();
        Test.testInstall(postInstallScript, new Version(1,0));
        Captricity_App_Info__c CapSettings = Captricity_App_Info__c.getOrgDefaults();
        System.assertEquals(CapSettings.Client_Id__c, null);
        System.assertEquals(CapSettings.Client_Secret_Key__c, null);
    }
    
    static testMethod void testAuthentication() {
        CaptricityAuthentication.newAuthorization();    
    }
    
    static testMethod void testCaptricityController() {
        PageReference currentPage = Page.Captricity;
        Test.setCurrentPage(currentPage);
        Captricity controller = new Captricity();
        
        controller.checkAuthorization();
        System.assertEquals(false, controller.authorized);
        
        System.assertEquals(null, controller.getCaptricityJobs()); // check to make sure this returns null, since user is not authenticated
        
        insertToken();
        controller.checkAuthorization();
        System.assertEquals(true, controller.authorized);
    }
    
    static testMethod void testAuthenticationController() {
        PageReference currentPage = Page.Captricity_Management;
        Test.setCurrentPage(currentPage);
        CaptricityManagementController controller = new CaptricityManagementController();
        
        controller.checkAuthorization();
        System.assertEquals(false, controller.authorized);
        
        String authURL = 'https://shreddr.captricity.com/accounts/request-access/?return-url=https%3A%2F%2Fnull%2Fapex%2Fcaptricity__captricity_management&signature=240bab0c25ab2a3f421496b40170664360d52aa9a7ec0c137b57c23de9c9c503&third-party-id=12';
        System.assertEquals(authURL, controller.authorize().getUrl());
        
        System.assertEquals(null, controller.completeAuthorization());
        
        ApexPages.currentPage().getParameters().put('token', '4e742cf417cc4a01aef1e0f46ed55560');
        ApexPages.currentPage().getParameters().put('request-granted', 'true');
        ApexPages.currentPage().getParameters().put('signature', '356cb4258a6600df042e9d28855b94468767d6ce55a16a757ba1206674b7ff4a');
        System.assertEquals(null, controller.completeAuthorization());
        
        ApexPages.currentPage().getParameters().remove('signature');
        CaptricityCalloutUtil.stubResponses.add(stubDocumentResponse);
        CaptricityCalloutUtil.stubResponses.add(stubDeepDocumentResponse);
        controller.checkAuthorization();
        System.assertEquals(true, controller.authorized);
    }
    
    static void insertToken() {
        Captricity__Captricity_Token__c newToken = new Captricity__Captricity_Token__c();
        newToken.Captricity__API_Token__c = 'token';
        insert newToken;
    }
    
    static testMethod void testSetupRequest() {
        insertToken();
        
        String dest = '/api/shreddr/job/';
        String accept = 'application/json';
        HttpRequest req = CaptricityCalloutUtil.setupCaptricityRequest('GET', dest, accept);
        System.assertEquals(req.getHeader('User-Agent'), 'Salesforce v0.1');
        System.assertEquals(req.getHeader('Captricity-API-Token'), 'token');
        System.assertEquals(req.getHeader('Accept'), accept);
        System.assertEquals(req.getEndpoint(), CaptricityCalloutUtil.HOST + dest);
    }
    
    static testMethod void testParseJobResponse() {
        insertToken();
        
        CaptricityCalloutUtil.stubResponses.add(stubJobResponse);
        
        System.Test.startTest();
        
        List<CaptricityJob> jobs = CaptricityJob.fetchCaptricityJobs();
        
        System.Test.stopTest();
        
        System.assertEquals(jobs.size(), 1);
        System.assertEquals(jobs[0].id, '2');
        System.assertEquals(jobs[0].name, 'Job 1');
        System.assertEquals(jobs[0].document_id, '2');
    }
    
    static testMethod void testParseDocumentResponse() {
        insertToken();
        
        System.assertEquals([select id from Captricity_Document__c].size(), 0);
        System.assertEquals([select id from Captricity_Field__c].size(), 0);
        System.assertEquals([select id from Captricity__c].size(), 0);
        
        CaptricityCalloutUtil.stubResponses.add(stubDocumentResponse);
        CaptricityCalloutUtil.stubResponses.add(stubDeepDocumentResponse);
        
        System.Test.startTest();
        
        Integer remainingSyncCount = CaptricityDocument.syncDocuments();
        
        System.Test.stopTest();
        
        System.assertEquals(remainingSyncCount, 0);
        System.assertEquals([select id from Captricity_Document__c].size(), 1);
        System.assertEquals([select id from Captricity_Field__c].size(), 12);
        System.assertEquals([select id from Captricity__c].size(), 5);
    }
    
    static testMethod void testParseDatasetResponse() {
        insertToken();
        
        System.assertEquals([select id, LastName, FirstName, Company from Lead].size(), 0);
        
        CaptricityCalloutUtil.stubResponses.add(stubDatasetCSVResponse);
        
        Captricity_Document__c doc = new Captricity_Document__c(Name='Test', Id__c=1);
        insert doc;
        Captricity_Field__c emailField = new Captricity_Field__c(Name='1', Field_Name__c='Email', Captricity_Document__c=doc.id, CSV_Label__c='page1:Email');
        Captricity_Field__c fnameField = new Captricity_Field__c(Name='2', Field_Name__c='First Name', Captricity_Document__c=doc.id, CSV_Label__c='page1:First Name');
        Captricity_Field__c lnameField = new Captricity_Field__c(Name='3', Field_Name__c='Last Name', Captricity_Document__c=doc.id, CSV_Label__c='page1:Last Name');
        Captricity_Field__c phoneNumField = new Captricity_Field__c(Name='4', Field_Name__c='Phone Number', Captricity_Document__c=doc.id, CSV_Label__c='page1:Phone Number');
        Captricity_Field__c companyField = new Captricity_Field__c(Name='5', Field_Name__c='Company', Captricity_Document__c=doc.id, CSV_Label__c='page1:Company');
        insert emailField;
        insert fnameField;
        insert lnameField;
        insert phoneNumField;
        insert companyField;
        insert new Captricity__c(Corresponding_Field_Name__c='First Name', Captricity_Document__c=doc.id, Object_Name__c='Lead', Captricity_Field__c=fnameField.id);
        insert new Captricity__c(Corresponding_Field_Name__c='Last Name', Captricity_Document__c=doc.id, Object_Name__c='Lead', Captricity_Field__c=lnameField.id);
        insert new Captricity__c(Corresponding_Field_Name__c='Company', Captricity_Document__c=doc.id, Object_Name__c='Lead', Captricity_Field__c=companyField.id);
        insert new Captricity__c(Corresponding_Field_Name__c='Email', Captricity_Document__c=doc.id, Object_Name__c='Lead', Captricity_Field__c=emailField.id);
        insert new Captricity__c(Corresponding_Field_Name__c='Phone Number', Captricity_Document__c=doc.id, Object_Name__c='Lead', Captricity_Field__c=phoneNumField.id);
        
        CaptricityDataset.extractLeads('doesnt matter', String.valueof(Integer.valueof(doc.Id__c)));
        
        System.assertEquals([select id, LastName, FirstName, Company from Lead].size(), 2);

    }
    
    static testMethod void testParseDocumentLimit() {
        insertToken();
        
        System.assertEquals([select id from Captricity_Document__c].size(), 0);
        
        System.Test.startTest();
        
        CaptricityCalloutUtil.stubResponses.add(stubBigDocumentResponse);
        for (Integer i = 0; i < 10; i++) {
            CaptricityCalloutUtil.stubResponses.add(stubDeepDocumentResponse);
        }
        
        Integer remainingSyncCount = CaptricityDocument.syncDocuments();
        System.Test.stopTest();
        
        System.assertEquals(remainingSyncCount, 1);
        System.assertEquals([select id from Captricity_Document__c].size(), 9);

    }
    
    static String stubJobResponse = '[    {        "status": "completed",        "user_id": 1,        "name": "Job 1",        "created": "2012-07-09T16:53:49.092",        "started": "2012-07-09T16:58:43.063",        "sheet_count": 1,        "modified": "2012-07-09T17:53:30.639",        "is_example": false,        "finished": "2012-07-09T17:53:30.638",        "percent_completed": 100,        "instance_set_count": 2,        "document_id":  2,        "id": 2    }]';
    static String stubDocumentResponse = '[ { "name": "Example School Survey Template", "created": "2012-10-11T14:07:29.878", "modified": "2012-10-11T14:07:29.878", "user_visible": true, "sheet_count": 2, "sheets": [ { "name": "Unnamed Sheet", "created": "2012-10-11T14:07:29.906", "modified": "2012-10-11T14:07:29.906", "page_number": 0, "image_file": "examplejob-template-acrobat-page-0000.png", "id": 122, "document_id": 75 }, { "name": "Unnamed Sheet", "created": "2012-10-11T14:07:30.034", "modified": "2012-10-11T14:07:30.034", "page_number": 1, "image_file": "examplejob-template-acrobat-page-0001.png", "id": 123, "document_id": 75 } ], "id": 75 } ]';
    static String stubDeepDocumentResponse = '{ "name": "Example School Survey Template", "created": "2012-10-11T14:07:29.878", "modified": "2012-10-11T14:07:29.878", "user_visible": true, "sheet_count": 2, "sheets": [ { "name": "Unnamed Sheet", "created": "2012-10-11T14:07:29.906", "fields": [ { "name": "school", "data_type": "S", "awaiting_rerun": false, "human_box": { "y": 0.15919999893, "x": 0.0842876887967, "id": 282, "w": 0.415904564315, "h": 0.0299165775401 }, "friendly_name": "Text", "column_id": 0, "widget_type": "T", "is_redacted": false, "shred_height": 115.178823529385, "shred_width": 1237.3160788371251, "rerun_description": "unk/unk", "instructions": "", "categorical_constraint": null, "id": 282, "constraints": [] }, { "name": "strengths", "data_type": "S", "awaiting_rerun": false, "human_box": { "y": 0.212622458824, "x": 0.0856694315353, "id": 283, "w": 0.835954356846, "h": 0.0609016042781 }, "friendly_name": "Text", "column_id": 0, "widget_type": "T", "is_redacted": false, "shred_height": 234.471176470685, "shred_width": 2486.9642116168498, "rerun_description": "unk/unk", "instructions": "Transcribe everything as well as you can. Don\'t worry about misspellings.", "categorical_constraint": null, "id": 283, "constraints": [] }, { "name": "homework", "data_type": "S", "awaiting_rerun": false, "human_box": { "y": 0.295961496257, "x": 0.0842876887967, "id": 284, "w": 0.21555186722, "h": 0.21475828877 }, "friendly_name": "Select one", "column_id": 0, "widget_type": "R", "is_redacted": false, "shred_height": 708.702352941, "shred_width": 549.657261411, "rerun_description": "unk/unk", "instructions": "", "categorical_constraint": [ "Much too much", "Somewhat too much", "Slightly too much", "About the right amount", "Slightly too little", "Somewhat too little", "Much too little", "Other (please specify)" ], "id": 284, "constraints": [ { "field_id": 284, "categories": "Much too much, Somewhat too much, Slightly too much, About the right amount, Slightly too little, Somewhat too little, Much too little, Other (please specify)", "data_type": "C", "id": 283 } ] }, { "name": "homework comments", "data_type": "S", "awaiting_rerun": false, "human_box": { "y": 0.502172191444, "x": 0.114686029046, "id": 285, "w": 0.425576763485, "h": 0.0373957219251 }, "friendly_name": "Text", "column_id": 0, "widget_type": "T", "is_redacted": false, "shred_height": 143.973529411635, "shred_width": 1266.090871367875, "rerun_description": "unk/unk", "instructions": "", "categorical_constraint": null, "id": 285, "constraints": [] }, { "name": "hours 1", "data_type": "S", "awaiting_rerun": false, "human_box": { "y": 0.586579678075, "x": 0.438013829876, "id": 286, "w": 0.467029045643, "h": 0.0389983957219 }, "friendly_name": "Select one", "column_id": 0, "widget_type": "R", "is_redacted": false, "shred_height": 128.69470588227, "shred_width": 1190.92406638965, "rerun_description": "unk/unk", "instructions": "1=left-most circle, 3=center circle, 5=right-most circle", "categorical_constraint": [ "1", "2", "3", "4", "5" ], "id": 286, "constraints": [ { "field_id": 286, "categories": "1, 2, 3, 4, 5", "data_type": "C", "id": 284 } ] }, { "name": "hours 2", "data_type": "S", "awaiting_rerun": false, "human_box": { "y": 0.625578073797, "x": 0.438013829876, "id": 287, "w": 0.467029045643, "h": 0.0389983957219 }, "friendly_name": "Select one", "column_id": 0, "widget_type": "R", "is_redacted": false, "shred_height": 128.69470588227, "shred_width": 1190.92406638965, "rerun_description": "unk/unk", "instructions": "1=left-most circle, 3=center circle, 5=right-most circle", "categorical_constraint": [ "1", "2", "3", "4", "5" ], "id": 287, "constraints": [ { "field_id": 287, "categories": "1, 2, 3, 4, 5", "data_type": "C", "id": 285 } ] }, { "name": "hours 3", "data_type": "S", "awaiting_rerun": false, "human_box": { "y": 0.664576469519, "x": 0.438013829876, "id": 288, "w": 0.467029045643, "h": 0.0389983957219 }, "friendly_name": "Select one", "column_id": 0, "widget_type": "R", "is_redacted": false, "shred_height": 128.69470588227, "shred_width": 1190.92406638965, "rerun_description": "unk/unk", "instructions": "1=left-most circle, 3=center circle, 5=right-most circle", "categorical_constraint": [ "1", "2", "3", "4", "5" ], "id": 288, "constraints": [ { "field_id": 288, "categories": "1, 2, 3, 4, 5", "data_type": "C", "id": 286 } ] }, { "name": "hours 4", "data_type": "S", "awaiting_rerun": false, "human_box": { "y": 0.703574865241, "x": 0.438013829876, "id": 289, "w": 0.467029045643, "h": 0.0389983957219 }, "friendly_name": "Select one", "column_id": 0, "widget_type": "R", "is_redacted": false, "shred_height": 128.69470588227, "shred_width": 1190.92406638965, "rerun_description": "unk/unk", "instructions": "1=left-most circle, 3=center circle, 5=right-most circle", "categorical_constraint": [ "1", "2", "3", "4", "5" ], "id": 289, "constraints": [ { "field_id": 289, "categories": "1, 2, 3, 4, 5", "data_type": "C", "id": 287 } ] } ], "image": "example-jobs/sample_job_1/examplejob-template-acrobat-page-0000.png", "image_name": "examplejob-template-acrobat-page-0000.png", "modified": "2012-10-11T14:07:29.906", "page_number": 0, "id": 122, "document_id": 75 }, { "name": "Unnamed Sheet", "created": "2012-10-11T14:07:30.034", "fields": [ { "name": "communicate", "data_type": "S", "awaiting_rerun": false, "human_box": { "y": 0.0993668438503, "x": 0.073233746888, "id": 290, "w": 0.190680497925, "h": 0.173088770053 }, "friendly_name": "Select many", "column_id": 0, "widget_type": "C", "is_redacted": false, "shred_height": 571.1929411749, "shred_width": 486.23526970875, "rerun_description": "unk/unk", "instructions": "", "categorical_constraint": [ "Postal mail", "Email", "Text messaging", "Phone calls", "Weblog posting", "Twitter", "Facebook", "etc" ], "id": 290, "constraints": [ { "field_id": 290, "categories": "Postal mail, Email, Text messaging, Phone calls, Weblog posting, Twitter, Facebook, etc", "data_type": "C", "id": 288 } ] }, { "name": "sid1", "data_type": "I", "awaiting_rerun": false, "human_box": { "y": 0.298098394652, "x": 0.0759972323651, "id": 291, "w": 0.11744813278, "h": 0.0224374331551 }, "friendly_name": "Number", "column_id": 0, "widget_type": "T", "is_redacted": false, "shred_height": 86.384117647135, "shred_width": 349.40819502050005, "rerun_description": "unk/unk", "instructions": "", "categorical_constraint": null, "id": 291, "constraints": [] }, { "name": "sid2", "data_type": "I", "awaiting_rerun": false, "human_box": { "y": 0.300235293048, "x": 0.215553248963, "id": 292, "w": 0.11744813278, "h": 0.0203005347594 }, "friendly_name": "Number", "column_id": 0, "widget_type": "T", "is_redacted": false, "shred_height": 78.15705882369001, "shred_width": 349.40819502050005, "rerun_description": "unk/unk", "instructions": "", "categorical_constraint": null, "id": 292, "constraints": [] }, { "name": "ssn", "data_type": "S", "awaiting_rerun": false, "human_box": { "y": 0.347247057754, "x": 0.0718520041494, "id": 293, "w": 0.277730290456, "h": 0.030985026738 }, "friendly_name": "Text", "column_id": 0, "widget_type": "T", "is_redacted": true, "shred_height": 119.29235294130001, "shred_width": 826.2476141066, "rerun_description": "unk/unk", "instructions": "", "categorical_constraint": null, "id": 293, "constraints": [] } ], "image": "example-jobs/sample_job_1/examplejob-template-acrobat-page-0001.png", "image_name": "examplejob-template-acrobat-page-0001.png", "modified": "2012-10-11T14:07:30.034", "page_number": 1, "id": 123, "document_id": 75 } ], "id": 75 }';
    static String stubDatasetCSVResponse = 'name,page1:First Name,page1:Last Name,page1:Company,page1:Address,page1:City,page1:State,page1:Zipcode,page1:Phone Number,page1:Email\nIMAG0171,YORIYASU,YANO,CAPTRICITY,--blank--,--blank--,--blank--,--blank--,6463799278,yoriy@captricity.com\nIMAG0172,Nick,Jalbert,"Jalberto, Inc",--blank--,--blank--,--blank--,--blank--,--blank--,nickj@jalbertonicky.com';
    
    static String stubBigDocumentResponse = '[{"name": "Template 5","created": "2012-10-04T11:13:53.417","modified": "2012-10-04T11:13:53.513","user_visible": true,"sheet_count": 1,"sheets": [{"name": "Unnamed Sheet","created": "2012-10-04T11:13:58.872","modified": "2012-10-04T11:13:59.458","page_number": 0,"image_file": "page1.JPG","id": 114,"document_id": 70 } ], "id": 70 }, { "name": "Template 3 revision 2", "created": "2012-09-18T11:07:36.771", "modified": "2012-09-18T11:07:36.845", "user_visible": true, "sheet_count": 1, "sheets": [ { "name": "Unnamed Sheet", "created": "2012-09-18T11:07:37.006", "modified": "2012-09-27T12:09:11.592", "page_number": 0, "image_file": "LibraryCardDesign_template-page-1.png", "id": 111, "document_id": 67 } ], "id": 67 }, { "name": "Template 3", "created": "2012-09-13T20:17:26.955", "modified": "2012-09-13T20:17:24.321", "user_visible": true, "sheet_count": 1, "sheets": [ { "name": "Unnamed Sheet", "created": "2012-09-13T20:17:23.946", "modified": "2012-09-13T20:17:24.318", "page_number": 0, "image_file": "LibraryCardDesign_template-page-1.png", "id": 110, "document_id": 66 } ], "id": 66 }, { "name": "Template 2", "created": "2012-09-11T09:59:40.258", "modified": "2012-09-11T09:59:40.341", "user_visible": true, "sheet_count": 1, "sheets": [ { "name": "Unnamed Sheet", "created": "2012-09-11T10:00:15.471", "modified": "2012-09-11T10:01:59.576", "page_number": 0, "image_file": "template.png", "id": 109, "document_id": 65 } ], "id": 65 }, { "name": "Template 1", "created": "2012-08-27T16:45:23.542", "modified": "2012-08-27T16:45:23.580", "user_visible": true, "sheet_count": 1, "sheets": [ { "name": "Unnamed Sheet", "created": "2012-08-27T16:45:34.175", "modified": "2012-09-10T10:38:19.316", "page_number": 0, "image_file": "template.png", "id": 102, "document_id": 61 } ], "id": 61 }, { "name": "Template 4", "created": "2012-08-06T10:56:10.523", "modified": "2012-08-06T10:56:10.531", "user_visible": true, "sheet_count": 3, "sheets": [ { "name": "Unnamed Sheet", "created": "2012-08-06T10:58:18.116", "modified": "2012-08-06T11:07:02.606", "page_number": 0, "image_file": "chief1.png", "id": 17, "document_id": 13 }, { "name": "Unnamed Sheet", "created": "2012-08-06T10:58:22.057", "modified": "2012-08-06T11:07:31.140", "page_number": 1, "image_file": "chief2.png", "id": 18, "document_id": 13 }, { "name": "Unnamed Sheet", "created": "2012-08-06T10:58:27.630", "modified": "2012-08-06T11:08:04.141", "page_number": 2, "image_file": "chief3.png", "id": 19, "document_id": 13 } ], "id": 13 }, { "name": "Are you here?", "created": "2012-08-02T16:11:15.884", "modified": "2012-08-03T14:51:18.594", "user_visible": true, "sheet_count": 1, "sheets": [ { "name": "8420817685048088842", "created": "2012-08-02T16:11:15.943", "modified": "2012-08-07T16:17:22.885", "page_number": 0, "image_file": "W-Omega.png", "id": 9, "document_id": 6 } ], "id": 6 }, { "name": "New Template", "created": "2012-08-02T16:11:15.598", "modified": "2012-08-02T16:11:15.598", "user_visible": true, "sheet_count": 1, "sheets": [ { "name": "image-491702", "created": "2012-08-02T16:11:15.658", "modified": "2012-08-07T20:49:31.674", "page_number": 0, "image_file": "W9.png", "id": 8, "document_id": 5 } ], "id": 5 }, { "name": "New Template", "created": "2012-08-02T16:09:41.985", "modified": "2012-08-02T16:09:41.985", "user_visible": true, "sheet_count": 2, "sheets": [ { "name": "2035775400677956823", "created": "2012-08-02T16:09:42.031", "modified": "2012-08-02T16:10:21.674", "page_number": 0, "image_file": "Example-Form-Page-1_1.png", "id": 5, "document_id": 3 }, { "name": "67429328260069227", "created": "2012-08-02T16:09:42.204", "modified": "2012-08-02T16:10:51.856", "page_number": 1, "image_file": "Example-Form-Page-2_1.png", "id": 6, "document_id": 3 } ], "id": 3 }, { "name": "Temp 1", "created": "2012-08-02T16:09:08.827", "modified": "2012-10-11T13:10:39.344", "user_visible": true, "sheet_count": 2, "sheets": [ { "name": "8445180291526420688", "created": "2012-08-02T16:09:08.862", "modified": "2012-08-02T16:09:24.038", "page_number": 0, "image_file": "Example-Form-Page-1.png", "id": 3, "document_id": 2 }, { "name": "726955568428402162", "created": "2012-08-02T16:09:09.060", "modified": "2012-08-02T16:09:34.510", "page_number": 1, "image_file": "Example-Form-Page-2.png", "id": 4, "document_id": 2 } ], "id": 2 }, { "name": "Example School Survey Template", "created": "2012-08-02T16:09:08.043", "modified": "2012-08-02T16:09:08.043", "user_visible": true, "sheet_count": 2, "sheets": [ { "name": "Unnamed Sheet", "created": "2012-08-02T16:09:08.046", "modified": "2012-08-02T16:09:08.046", "page_number": 0, "image_file": "examplejob-template-acrobat-page-0000.png", "id": 1, "document_id": 1 }, { "name": "Unnamed Sheet", "created": "2012-08-02T16:09:08.119", "modified": "2012-08-02T16:09:08.119", "page_number": 1, "image_file": "examplejob-template-acrobat-page-0001.png", "id": 2, "document_id": 1 } ], "id": 1 } ]';

}