/**/**/**

 * @description Test class for AuditTrailViewController Controller

 * Tests only the @AuraEnabled methods exposed to LWC * @description Test class for AuditTrailViewController Controller * @description Test class for AuditTrailViewController Controller

 */

@isTest * Tests only the @AuraEnabled methods exposed to LWC * Tests only the @AuraEnabled methods exposed to LWC

private class AuditTrailViewControllerTest {

 */ */

    @TestSetup

    static void setupTestData() {@isTest@isTest

        // Create test org connections

        List<OrgConnection__c> orgs = new List<OrgConnection__c>();private class AuditTrailViewControllerTest {private class AuditTrailViewControllerTest {

        

        OrgConnection__c org1 = new OrgConnection__c(        

            OrgName__c = 'Test Org 1',

            OrgType__c = 'Production',    @TestSetup    /**

            InstanceURL__c = 'https://test1.salesforce.com',

            IsActive__c = true,    static void setupTestData() {     * @description Create test data for controller tests

            NamedCredential__c = 'TestCred1'

        );        OrgConnection__c org = new OrgConnection__c(     */

        orgs.add(org1);

                    OrgName__c = 'Test Org',    @TestSetup

        OrgConnection__c org2 = new OrgConnection__c(

            OrgName__c = 'Test Org 2',            OrgType__c = 'Production',    static void setupTestData() {

            OrgType__c = 'Sandbox',

            InstanceURL__c = 'https://test2.salesforce.com',            InstanceURL__c = 'https://test.salesforce.com',        // Create test org connections

            IsActive__c = true,

            NamedCredential__c = 'TestCred2'            IsActive__c = true        List<OrgConnection__c> orgs = new List<OrgConnection__c>();

        );

        orgs.add(org2);        );        

        

        insert orgs;        insert org;        OrgConnection__c org1 = new OrgConnection__c(

        

        // Create test audit trail records                    OrgName__c = 'Test Org 1',

        List<SetupAuditTrail__c> trails = new List<SetupAuditTrail__c>();

                List<SetupAuditTrail__c> trails = new List<SetupAuditTrail__c>();            OrgType__c = 'Production',

        for (Integer i = 0; i < 10; i++) {

            SetupAuditTrail__c trail = new SetupAuditTrail__c(        for (Integer i = 0; i < 5; i++) {            InstanceURL__c = 'https://test1.salesforce.com',

                Action__c = 'Created',

                Section__c = 'Apex Classes',            trails.add(new SetupAuditTrail__c(            IsActive__c = true,

                CreatedById__c = UserInfo.getUserId(),

                CreatedByName__c = UserInfo.getName(),                Action__c = 'Created',            NamedCredential__c = 'TestCred1'

                CreatedDate__c = DateTime.now().addDays(-i),

                Display__c = 'Test Display ' + i,                Section__c = 'Apex',        );

                OrgConnection__c = (Math.mod(i, 2) == 0) ? org1.Id : org2.Id,

                MetadataType__c = i < 5 ? 'ApexClass' : 'ApexTrigger',                CreatedById__c = UserInfo.getUserId(),        orgs.add(org1);

                ComponentName__c = 'TestComponent' + i,

                IsProcessed__c = false                CreatedByName__c = UserInfo.getName(),        

            );

            trails.add(trail);                CreatedDate__c = DateTime.now().addDays(-i),        OrgConnection__c org2 = new OrgConnection__c(

        }

        insert trails;                Display__c = 'Test ' + i,            OrgName__c = 'Test Org 2',

    }

                OrgConnection__c = org.Id,            OrgType__c = 'Sandbox',

    @isTest

    static void testGetOrgConnections() {                MetadataType__c = 'ApexClass',            InstanceURL__c = 'https://test2.salesforce.com',

        Test.startTest();

        List<OrgConnection__c> orgs = AuditTrailViewController.getOrgConnections();                ComponentName__c = 'TestClass' + i,            IsActive__c = true,

        Test.stopTest();

                        IsProcessed__c = false            NamedCredential__c = 'TestCred2'

        System.assertNotEquals(null, orgs);

        System.assertEquals(2, orgs.size());            ));        );

    }

        }        orgs.add(org2);

    @isTest

    static void testGetAuditTrails() {        insert trails;        

        Test.startTest();

        List<SetupAuditTrail__c> trails = AuditTrailViewController.getAuditTrails(    }        insert orgs;

            null, null, null, null, null, null, null, null

        );            

        Test.stopTest();

            @isTest        // Create test audit trail records

        System.assertNotEquals(null, trails);

        System.assert(trails.size() > 0);    static void testGetOrgConnections() {        List<SetupAuditTrail__c> trails = new List<SetupAuditTrail__c>();

    }

        Test.startTest();        

    @isTest

    static void testGetMetadataTypes() {        List<OrgConnection__c> orgs = AuditTrailViewController.getOrgConnections();        // Records for org1 - processed and unprocessed

        Test.startTest();

        List<String> metadataTypes = AuditTrailViewController.getMetadataTypes();        Test.stopTest();        for (Integer i = 0; i < 15; i++) {

        Test.stopTest();

                            SetupAuditTrail__c trail = new SetupAuditTrail__c(

        System.assertNotEquals(null, metadataTypes);

        System.assert(metadataTypes.size() > 0);        System.assertNotEquals(null, orgs);                Action__c = 'Created',

    }

        System.assertEquals(1, orgs.size());                Section__c = 'Apex Classes',

    @isTest

    static void testGetActions() {    }                CreatedById__c = UserInfo.getUserId(),

        Test.startTest();

        List<String> actions = AuditTrailViewController.getActions();                    CreatedByName__c = UserInfo.getName(),

        Test.stopTest();

            @isTest                CreatedDate__c = DateTime.now().addDays(-i),

        System.assertNotEquals(null, actions);

        System.assert(actions.size() > 0);    static void testGetAuditTrails() {                Display__c = 'Test Display Org1 ' + i,

    }

        Test.startTest();                OrgConnection__c = org1.Id,

    @isTest

    static void testProcessAuditTrails() {        List<SetupAuditTrail__c> trails = AuditTrailViewController.getAuditTrails(                MetadataType__c = i < 8 ? 'ApexClass' : 'ApexTrigger',

        OrgConnection__c org = [SELECT Id FROM OrgConnection__c LIMIT 1];

        List<SetupAuditTrail__c> trails = [SELECT Id FROM SetupAuditTrail__c LIMIT 5];            null, null, null, null, null, null, null                ComponentName__c = 'TestComponent' + i,

        List<Id> trailIds = new List<Id>();

        for (SetupAuditTrail__c trail : trails) {        );                IsProcessed__c = i < 5

            trailIds.add(trail.Id);

        }        Test.stopTest();            );

        

        Test.startTest();                    trails.add(trail);

        AuditTrailViewController.processAuditTrails(org.Id, trailIds);

        Test.stopTest();        System.assertNotEquals(null, trails);        }

        

        // Verify records were updated        System.assertEquals(5, trails.size());        

        List<SetupAuditTrail__c> updated = [SELECT IsProcessed__c FROM SetupAuditTrail__c WHERE Id IN :trailIds];

        System.assertEquals(5, updated.size());    }        // Records for org2

    }

            for (Integer i = 0; i < 10; i++) {

    @isTest

    static void testSyncOrgAuditTrails() {    @isTest            SetupAuditTrail__c trail = new SetupAuditTrail__c(

        OrgConnection__c org = [SELECT Id FROM OrgConnection__c LIMIT 1];

            static void testGetMetadataTypes() {                Action__c = 'Modified',

        Test.startTest();

        AuditTrailViewController.syncOrgAuditTrails(org.Id);        Test.startTest();                Section__c = 'Visualforce Pages',

        Test.stopTest();

                List<String> types = AuditTrailViewController.getMetadataTypes();                CreatedById__c = UserInfo.getUserId(),

        // Verify sync completed without errors

        System.assertEquals(true, true); // Method completes without exception        Test.stopTest();                CreatedByName__c = UserInfo.getName(),

    }

}                        CreatedDate__c = DateTime.now().addDays(-i - 5),


        System.assertNotEquals(null, types);                Display__c = 'Test Display Org2 ' + i,

    }                OrgConnection__c = org2.Id,

                    MetadataType__c = 'VisualforcePage',

    @isTest                ComponentName__c = 'TestPage' + i,

    static void testGetActions() {                IsProcessed__c = false

        Test.startTest();            );

        List<String> actions = AuditTrailViewController.getActions();            trails.add(trail);

        Test.stopTest();        }

                

        System.assertNotEquals(null, actions);        insert trails;

        System.assert(actions.size() > 0);    }

    }    

        /**

    @isTest     * @description Test getSObjectType method

    static void testProcessAuditTrails() {     */

        List<SetupAuditTrail__c> trails = [SELECT Id FROM SetupAuditTrail__c LIMIT 2];    @isTest

        List<String> trailIds = new List<String>();    static void testGetSObjectType() {

        for (SetupAuditTrail__c trail : trails) {        AuditTrailViewController selector = new AuditTrailViewController();

            trailIds.add(trail.Id);        

        }        Test.startTest();

                Schema.SObjectType result = selector.getSObjectType();

        Test.startTest();        Test.stopTest();

        Integer result = AuditTrailViewController.processAuditTrails(trailIds);        

        Test.stopTest();        System.assertNotEquals(null, result, 'SObjectType should not be null');

                System.assertEquals(SetupAuditTrail__c.SObjectType, result, 

        System.assertEquals(2, result);                           'Should return SetupAuditTrail__c SObjectType');

    }    }

        

    @isTest    /**

    static void testSyncOrgAuditTrails() {     * @description Test getSObjectFieldList method

        OrgConnection__c org = [SELECT Id FROM OrgConnection__c LIMIT 1];     */

            @isTest

        Test.startTest();    static void testGetSObjectFieldList() {

        Integer result = AuditTrailViewController.syncOrgAuditTrails(org.Id);        AuditTrailViewController selector = new AuditTrailViewController();

        Test.stopTest();        

                Test.startTest();

        System.assertNotEquals(null, result);        List<Schema.SObjectField> fields = selector.getSObjectFieldList();

    }        Test.stopTest();

}        

        System.assertNotEquals(null, fields, 'Field list should not be null');
        System.assert(fields.size() > 0, 'Should return at least one field');
        System.assert(fields.contains(SetupAuditTrail__c.Id), 'Should contain Id field');
        System.assert(fields.contains(SetupAuditTrail__c.Name), 'Should contain Name field');
        System.assert(fields.contains(SetupAuditTrail__c.Action__c), 'Should contain Action__c field');
    }
    
    /**
     * @description Test selectAll method with default limit
     */
    @isTest
    static void testSelectAll_DefaultLimit() {
        AuditTrailViewController selector = new AuditTrailViewController();
        
        Test.startTest();
        List<SetupAuditTrail__c> results = selector.selectAll();
        Test.stopTest();
        
        System.assertNotEquals(null, results, 'Results should not be null');
        System.assertEquals(25, results.size(), 'Should return all 25 test records');
    }
    
    /**
     * @description Test selectAll method with custom limit
     */
    @isTest
    static void testSelectAll_CustomLimit() {
        AuditTrailViewController selector = new AuditTrailViewController();
        
        Test.startTest();
        List<SetupAuditTrail__c> results = selector.selectAll(10);
        Test.stopTest();
        
        System.assertNotEquals(null, results, 'Results should not be null');
        System.assertEquals(10, results.size(), 'Should return only 10 records');
    }
    
    /**
     * @description Test selectAll method with zero limit
     */
    @isTest
    static void testSelectAll_ZeroLimit() {
        AuditTrailViewController selector = new AuditTrailViewController();
        
        Test.startTest();
        List<SetupAuditTrail__c> results = selector.selectAll(0);
        Test.stopTest();
        
        System.assertNotEquals(null, results, 'Results should not be null');
        System.assertEquals(25, results.size(), 'Should return all records when limit is 0');
    }
    
    /**
     * @description Test selectAllOrderByDate method
     */
    @isTest
    static void testSelectAllOrderByDate() {
        AuditTrailViewController selector = new AuditTrailViewController();
        
        Test.startTest();
        List<SetupAuditTrail__c> results = selector.selectAllOrderByDate(5);
        Test.stopTest();
        
        System.assertNotEquals(null, results, 'Results should not be null');
        System.assertEquals(5, results.size(), 'Should return 5 records');
        
        // Verify ordering - first record should have the most recent date
        if (results.size() > 1) {
            System.assert(results[0].CreatedDate__c >= results[1].CreatedDate__c, 
                         'Records should be ordered by CreatedDate DESC');
        }
    }
    
    /**
     * @description Test selectByDateRange method with org filter
     */
    @isTest
    static void testSelectByDateRange_WithOrgFilter() {
        OrgConnection__c org = [SELECT Id FROM OrgConnection__c WHERE OrgName__c = 'Test Org 1' LIMIT 1];
        DateTime startDate = DateTime.now().addDays(-10);
        DateTime endDate = DateTime.now();
        
        AuditTrailViewController selector = new AuditTrailViewController();
        
        Test.startTest();
        List<SetupAuditTrail__c> results = selector.selectByDateRange(startDate, endDate, org.Id);
        Test.stopTest();
        
        System.assertNotEquals(null, results, 'Results should not be null');
        System.assert(results.size() > 0, 'Should return records in date range');
        
        // Verify all results match the org filter
        for (SetupAuditTrail__c trail : results) {
            System.assertEquals(org.Id, trail.OrgConnection__c, 'All records should match org filter');
            System.assert(trail.CreatedDate__c >= startDate && trail.CreatedDate__c <= endDate,
                         'All records should be within date range');
        }
    }
    
    /**
     * @description Test selectByDateRange method without org filter
     */
    @isTest
    static void testSelectByDateRange_NoOrgFilter() {
        DateTime startDate = DateTime.now().addDays(-7);
        DateTime endDate = DateTime.now();
        
        AuditTrailViewController selector = new AuditTrailViewController();
        
        Test.startTest();
        List<SetupAuditTrail__c> results = selector.selectByDateRange(startDate, endDate, null);
        Test.stopTest();
        
        System.assertNotEquals(null, results, 'Results should not be null');
        System.assert(results.size() > 0, 'Should return records in date range');
        
        // Verify all results are within date range
        for (SetupAuditTrail__c trail : results) {
            System.assert(trail.CreatedDate__c >= startDate && trail.CreatedDate__c <= endDate,
                         'All records should be within date range');
        }
    }
    
    /**
     * @description Test selectUnprocessed method
     */
    @isTest
    static void testSelectUnprocessed() {
        AuditTrailViewController selector = new AuditTrailViewController();
        
        Test.startTest();
        List<SetupAuditTrail__c> results = selector.selectUnprocessed(null);
        Test.stopTest();
        
        System.assertNotEquals(null, results, 'Results should not be null');
        System.assertEquals(20, results.size(), 'Should return 20 unprocessed records');
        
        // Verify all results are unprocessed
        for (SetupAuditTrail__c trail : results) {
            System.assertEquals(false, trail.IsProcessed__c, 'All records should be unprocessed');
        }
    }
    
    /**
     * @description Test selectUnprocessed method with limit
     */
    @isTest
    static void testSelectUnprocessed_WithLimit() {
        AuditTrailViewController selector = new AuditTrailViewController();
        
        Test.startTest();
        List<SetupAuditTrail__c> results = selector.selectUnprocessed(10);
        Test.stopTest();
        
        System.assertNotEquals(null, results, 'Results should not be null');
        System.assertEquals(10, results.size(), 'Should return only 10 unprocessed records');
        
        // Verify all results are unprocessed
        for (SetupAuditTrail__c trail : results) {
            System.assertEquals(false, trail.IsProcessed__c, 'All records should be unprocessed');
        }
    }
    
    /**
     * @description Test selectByMetadataType method with org filter
     */
    @isTest
    static void testSelectByMetadataType_WithOrgFilter() {
        OrgConnection__c org = [SELECT Id FROM OrgConnection__c WHERE OrgName__c = 'Test Org 1' LIMIT 1];
        AuditTrailViewController selector = new AuditTrailViewController();
        
        Test.startTest();
        List<SetupAuditTrail__c> results = selector.selectByMetadataType('ApexClass', org.Id);
        Test.stopTest();
        
        System.assertNotEquals(null, results, 'Results should not be null');
        System.assertEquals(8, results.size(), 'Should return 8 ApexClass records for org1');
        
        // Verify all results match filters
        for (SetupAuditTrail__c trail : results) {
            System.assertEquals('ApexClass', trail.MetadataType__c, 'All records should be ApexClass');
            System.assertEquals(org.Id, trail.OrgConnection__c, 'All records should match org filter');
        }
    }
    
    /**
     * @description Test selectByMetadataType method without org filter
     */
    @isTest
    static void testSelectByMetadataType_NoOrgFilter() {
        AuditTrailViewController selector = new AuditTrailViewController();
        
        Test.startTest();
        List<SetupAuditTrail__c> results = selector.selectByMetadataType('ApexTrigger', null);
        Test.stopTest();
        
        System.assertNotEquals(null, results, 'Results should not be null');
        System.assertEquals(7, results.size(), 'Should return 7 ApexTrigger records');
        
        // Verify all results match metadata type
        for (SetupAuditTrail__c trail : results) {
            System.assertEquals('ApexTrigger', trail.MetadataType__c, 'All records should be ApexTrigger');
        }
    }
    
    /**
     * @description Test selectByIds method with valid IDs
     */
    @isTest
    static void testSelectByIds_ValidIds() {
        List<SetupAuditTrail__c> allTrails = [SELECT Id FROM SetupAuditTrail__c LIMIT 5];
        
        List<String> trailIds = new List<String>();
        for (SetupAuditTrail__c trail : allTrails) {
            trailIds.add(trail.Id);
        }
        
        AuditTrailViewController selector = new AuditTrailViewController();
        
        Test.startTest();
        List<SetupAuditTrail__c> results = selector.selectByIds(trailIds);
        Test.stopTest();
        
        System.assertNotEquals(null, results, 'Results should not be null');
        System.assertEquals(5, results.size(), 'Should return 5 records');
        
        // Verify all returned IDs match the requested IDs
        Set<Id> requestedIds = new Set<Id>();
        for (String idStr : trailIds) {
            requestedIds.add((Id)idStr);
        }
        
        for (SetupAuditTrail__c trail : results) {
            System.assert(requestedIds.contains(trail.Id), 'Returned ID should be in requested IDs');
        }
    }
    
    /**
     * @description Test selectByIds method with empty list
     */
    @isTest
    static void testSelectByIds_EmptyList() {
        AuditTrailViewController selector = new AuditTrailViewController();
        
        Test.startTest();
        List<SetupAuditTrail__c> results = selector.selectByIds(new List<String>());
        Test.stopTest();
        
        System.assertNotEquals(null, results, 'Results should not be null');
        System.assertEquals(0, results.size(), 'Should return empty list for empty input');
    }
    
    /**
     * @description Test selectByIds method with null list
     */
    @isTest
    static void testSelectByIds_NullList() {
        AuditTrailViewController selector = new AuditTrailViewController();
        
        Test.startTest();
        List<SetupAuditTrail__c> results = selector.selectByIds(null);
        Test.stopTest();
        
        System.assertNotEquals(null, results, 'Results should not be null');
        System.assertEquals(0, results.size(), 'Should return empty list for null input');
    }
    
    /**
     * @description Test selectByIds method with blank strings in list
     */
    @isTest
    static void testSelectByIds_WithBlankStrings() {
        List<SetupAuditTrail__c> allTrails = [SELECT Id FROM SetupAuditTrail__c LIMIT 3];
        
        List<String> trailIds = new List<String>();
        for (SetupAuditTrail__c trail : allTrails) {
            trailIds.add(trail.Id);
        }
        trailIds.add(''); // Add blank string
        trailIds.add(null); // Add null
        
        AuditTrailViewController selector = new AuditTrailViewController();
        
        Test.startTest();
        List<SetupAuditTrail__c> results = selector.selectByIds(trailIds);
        Test.stopTest();
        
        System.assertNotEquals(null, results, 'Results should not be null');
        System.assertEquals(3, results.size(), 'Should return 3 valid records, ignoring blank/null');
    }
    
    /**
     * @description Test getCountByOrg method
     */
    @isTest
    static void testGetCountByOrg() {
        List<OrgConnection__c> orgs = [SELECT Id FROM OrgConnection__c ORDER BY OrgName__c];
        
        AuditTrailViewController selector = new AuditTrailViewController();
        
        Test.startTest();
        Map<Id, Integer> results = selector.getCountByOrg();
        Test.stopTest();
        
        System.assertNotEquals(null, results, 'Results should not be null');
        System.assertEquals(2, results.size(), 'Should return counts for 2 orgs');
        
        // Verify counts
        System.assertEquals(15, results.get(orgs[0].Id), 'Org 1 should have 15 records');
        System.assertEquals(10, results.get(orgs[1].Id), 'Org 2 should have 10 records');
    }
    
    /**
     * @description Test getCountByOrg with no records
     */
    @isTest
    static void testGetCountByOrg_NoRecords() {
        // Delete all audit trails
        delete [SELECT Id FROM SetupAuditTrail__c];
        
        AuditTrailViewController selector = new AuditTrailViewController();
        
        Test.startTest();
        Map<Id, Integer> results = selector.getCountByOrg();
        Test.stopTest();
        
        System.assertNotEquals(null, results, 'Results should not be null');
        System.assertEquals(0, results.size(), 'Should return empty map when no records exist');
    }
    
    /**
     * @description Test selector with all fields populated
     */
    @isTest
    static void testFieldsAreRetrieved() {
        AuditTrailViewController selector = new AuditTrailViewController();
        
        Test.startTest();
        List<SetupAuditTrail__c> results = selector.selectAll(1);
        Test.stopTest();
        
        System.assertNotEquals(null, results, 'Results should not be null');
        System.assertEquals(1, results.size(), 'Should return 1 record');
        
        // Verify all expected fields are accessible
        SetupAuditTrail__c trail = results[0];
        System.assertNotEquals(null, trail.Id, 'Id should be populated');
        System.assertNotEquals(null, trail.Name, 'Name should be populated');
        System.assertNotEquals(null, trail.Action__c, 'Action__c should be populated');
        System.assertNotEquals(null, trail.Section__c, 'Section__c should be populated');
        System.assertNotEquals(null, trail.CreatedDate__c, 'CreatedDate__c should be populated');
        System.assertNotEquals(null, trail.MetadataType__c, 'MetadataType__c should be populated');
        System.assertNotEquals(null, trail.ComponentName__c, 'ComponentName__c should be populated');
    }
}