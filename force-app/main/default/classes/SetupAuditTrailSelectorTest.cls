/**
 * @description Test class for SetupAuditTrailSelector
 * Provides comprehensive test coverage for audit trail selector methods
 */
@isTest
private class SetupAuditTrailSelectorTest {
    
    /**
     * @description Creates test data for selector tests
     */
    @TestSetup
    static void setupTestData() {
        // Create test org connections
        List<OrgConnection__c> orgs = new List<OrgConnection__c>();
        
        OrgConnection__c org1 = new OrgConnection__c(
            OrgName__c = 'Test Org 1',
            OrgType__c = 'Production',
            InstanceURL__c = 'https://test1.salesforce.com',
            IsActive__c = true,
            NamedCredential__c = 'TestCred1'
        );
        orgs.add(org1);
        
        OrgConnection__c org2 = new OrgConnection__c(
            OrgName__c = 'Test Org 2',
            OrgType__c = 'Sandbox',
            InstanceURL__c = 'https://test2.salesforce.com',
            IsActive__c = true,
            NamedCredential__c = 'TestCred2'
        );
        orgs.add(org2);
        
        insert orgs;
        
        // Create test audit trail records
        List<SetupAuditTrail__c> trails = new List<SetupAuditTrail__c>();
        
        // Records for org1 - processed and unprocessed
        for (Integer i = 0; i < 15; i++) {
            SetupAuditTrail__c trail = new SetupAuditTrail__c(
                Action__c = 'Created',
                Section__c = 'Apex Classes',
                CreatedById__c = UserInfo.getUserId(),
                CreatedByName__c = UserInfo.getName(),
                CreatedDate__c = DateTime.now().addDays(-i),
                Display__c = 'Test Display Org1 ' + i,
                OrgConnection__c = org1.Id,
                MetadataType__c = i < 8 ? 'ApexClass' : 'ApexTrigger',
                ComponentName__c = 'TestComponent' + i,
                IsProcessed__c = i < 5
            );
            trails.add(trail);
        }
        
        // Records for org2
        for (Integer i = 0; i < 10; i++) {
            SetupAuditTrail__c trail = new SetupAuditTrail__c(
                Action__c = 'Modified',
                Section__c = 'Visualforce Pages',
                CreatedById__c = UserInfo.getUserId(),
                CreatedByName__c = UserInfo.getName(),
                CreatedDate__c = DateTime.now().addDays(-i - 5),
                Display__c = 'Test Display Org2 ' + i,
                OrgConnection__c = org2.Id,
                MetadataType__c = 'VisualforcePage',
                ComponentName__c = 'TestPage' + i,
                IsProcessed__c = false
            );
            trails.add(trail);
        }
        
        insert trails;
    }
    
    /**
     * @description Test getSObjectType method
     */
    @isTest
    static void testGetSObjectType() {
        SetupAuditTrailSelector selector = new SetupAuditTrailSelector();
        
        Test.startTest();
        Schema.SObjectType result = selector.getSObjectType();
        Test.stopTest();
        
        System.assertNotEquals(null, result, 'SObjectType should not be null');
        System.assertEquals(SetupAuditTrail__c.SObjectType, result, 
                           'Should return SetupAuditTrail__c SObjectType');
    }
    
    /**
     * @description Test getSObjectFieldList method
     */
    @isTest
    static void testGetSObjectFieldList() {
        SetupAuditTrailSelector selector = new SetupAuditTrailSelector();
        
        Test.startTest();
        List<Schema.SObjectField> fields = selector.getSObjectFieldList();
        Test.stopTest();
        
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
        SetupAuditTrailSelector selector = new SetupAuditTrailSelector();
        
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
        SetupAuditTrailSelector selector = new SetupAuditTrailSelector();
        
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
        SetupAuditTrailSelector selector = new SetupAuditTrailSelector();
        
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
        SetupAuditTrailSelector selector = new SetupAuditTrailSelector();
        
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
        
        SetupAuditTrailSelector selector = new SetupAuditTrailSelector();
        
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
        
        SetupAuditTrailSelector selector = new SetupAuditTrailSelector();
        
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
        SetupAuditTrailSelector selector = new SetupAuditTrailSelector();
        
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
        SetupAuditTrailSelector selector = new SetupAuditTrailSelector();
        
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
        SetupAuditTrailSelector selector = new SetupAuditTrailSelector();
        
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
        SetupAuditTrailSelector selector = new SetupAuditTrailSelector();
        
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
        
        SetupAuditTrailSelector selector = new SetupAuditTrailSelector();
        
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
        SetupAuditTrailSelector selector = new SetupAuditTrailSelector();
        
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
        SetupAuditTrailSelector selector = new SetupAuditTrailSelector();
        
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
        
        SetupAuditTrailSelector selector = new SetupAuditTrailSelector();
        
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
        
        SetupAuditTrailSelector selector = new SetupAuditTrailSelector();
        
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
        
        SetupAuditTrailSelector selector = new SetupAuditTrailSelector();
        
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
        SetupAuditTrailSelector selector = new SetupAuditTrailSelector();
        
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