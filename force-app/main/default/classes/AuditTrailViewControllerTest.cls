/**
 * @description Test class for AuditTrailViewController
 * @author Ashok Chandra
 * @date December 4, 2025
 * Coverage: 76%
 */
@isTest
private class AuditTrailViewControllerTest {
    
    /**
     * @description Setup test data
     */
    @testSetup
    static void setupTestData() {
        // Create test org connection
        OrgConnection__c orgConnection = new OrgConnection__c(
            OrgName__c = 'Test Dev Org',
            ConnectionType__c = 'Sandbox',
            APIVersion__c = '64.0',
            IsActive__c = true
        );
        insert orgConnection;
        
        // Create test audit trails
        List<SetupAuditTrail__c> auditTrails = new List<SetupAuditTrail__c>();
        for (Integer i = 0; i < 10; i++) {
            auditTrails.add(new SetupAuditTrail__c(
                OrgConnection__c = orgConnection.Id,
                Action__c = 'Created',
                Section__c = 'Custom Object',
                ComponentName__c = 'TestComponent__c',
                MetadataType__c = 'CustomObject',
                Display__c = 'Test Display ' + i,
                IsProcessed__c = false,
                CreatedDate__c = Date.today().addDays(-i),
                CreatedByName__c = 'Test User'
            ));
        }
        insert auditTrails;
    }
    
    /**
     * @description Test getAuditTrails with no filters
     */
    @isTest
    static void testGetAuditTrailsNoFilters() {
        List<SetupAuditTrail__c> result = AuditTrailViewController.getAuditTrails(
            null, null, null, null, null, null, false
        );
        
        Assert.isNotNull(result, 'Result should not be null');
        Assert.isTrue(result.size() > 0, 'Should return audit trails');
    }
    
    /**
     * @description Test getAuditTrails with org filter
     */
    @isTest
    static void testGetAuditTrailsWithOrgFilter() {
        OrgConnection__c org = [SELECT Id FROM OrgConnection__c LIMIT 1];
        
        List<SetupAuditTrail__c> result = AuditTrailViewController.getAuditTrails(
            org.Id, null, null, null, null, null, false
        );
        
        Assert.isNotNull(result, 'Result should not be null');
        Assert.isTrue(result.size() > 0, 'Should return filtered audit trails');
        for (SetupAuditTrail__c trail : result) {
            Assert.areEqual(org.Id, trail.OrgConnection__c, 'Should match org filter');
        }
    }
    
    /**
     * @description Test getAuditTrails with action filter
     */
    @isTest
    static void testGetAuditTrailsWithActionFilter() {
        List<SetupAuditTrail__c> result = AuditTrailViewController.getAuditTrails(
            null, 'Created', null, null, null, null, false
        );
        
        Assert.isNotNull(result, 'Result should not be null');
        for (SetupAuditTrail__c trail : result) {
            Assert.areEqual('Created', trail.Action__c, 'Should match action filter');
        }
    }
    
    /**
     * @description Test getAuditTrails with metadata type filter
     */
    @isTest
    static void testGetAuditTrailsWithMetadataTypeFilter() {
        List<SetupAuditTrail__c> result = AuditTrailViewController.getAuditTrails(
            null, null, 'CustomObject', null, null, null, false
        );
        
        Assert.isNotNull(result, 'Result should not be null');
        for (SetupAuditTrail__c trail : result) {
            Assert.areEqual('CustomObject', trail.MetadataType__c, 'Should match metadata type filter');
        }
    }
    
    /**
     * @description Test getAuditTrails with search term
     */
    @isTest
    static void testGetAuditTrailsWithSearchTerm() {
        List<SetupAuditTrail__c> result = AuditTrailViewController.getAuditTrails(
            null, null, null, 'TestComponent', null, null, false
        );
        
        Assert.isNotNull(result, 'Result should not be null');
    }
    
    /**
     * @description Test getAuditTrails with date range
     */
    @isTest
    static void testGetAuditTrailsWithDateRange() {
        Date dateFrom = Date.today().addDays(-10);
        Date dateTo = Date.today();
        
        List<SetupAuditTrail__c> result = AuditTrailViewController.getAuditTrails(
            null, null, null, null, dateFrom, dateTo, false
        );
        
        Assert.isNotNull(result, 'Result should not be null');
    }
    
    /**
     * @description Test getAuditTrails with processed filter
     */
    @isTest
    static void testGetAuditTrailsWithProcessedFilter() {
        List<SetupAuditTrail__c> result = AuditTrailViewController.getAuditTrails(
            null, null, null, null, null, null, true
        );
        
        Assert.isNotNull(result, 'Result should not be null');
    }
    
    /**
     * @description Test getOrgConnections
     */
    @isTest
    static void testGetOrgConnections() {
        List<OrgConnection__c> result = AuditTrailViewController.getOrgConnections();
        
        Assert.isNotNull(result, 'Result should not be null');
        Assert.isTrue(result.size() > 0, 'Should return org connections');
    }
    
    /**
     * @description Test getMetadataTypes
     */
    @isTest
    static void testGetMetadataTypes() {
        List<String> result = AuditTrailViewController.getMetadataTypes();
        
        Assert.isNotNull(result, 'Result should not be null');
        Assert.isTrue(result.size() > 0, 'Should return metadata types');
    }
    
    /**
     * @description Test getActions
     */
    @isTest
    static void testGetActions() {
        List<String> result = AuditTrailViewController.getActions();
        
        Assert.isNotNull(result, 'Result should not be null');
        Assert.isTrue(result.size() > 0, 'Should return actions');
    }
    
    /**
     * @description Test processAuditTrails
     */
    @isTest
    static void testProcessAuditTrails() {
        List<SetupAuditTrail__c> trails = [SELECT Id FROM SetupAuditTrail__c LIMIT 2];
        List<Id> trailIds = new List<Id>{trails[0].Id, trails[1].Id};
        
        Test.startTest();
        AuditTrailViewController.ProcessingResult result = AuditTrailViewController.processAuditTrails(trailIds);
        Test.stopTest();
        
        Assert.isNotNull(result, 'Result should not be null');
        Assert.areEqual(2, result.processedCount, 'Should process 2 trails');
    }
    
    /**
     * @description Test processAuditTrails with empty list
     */
    @isTest
    static void testProcessAuditTrailsEmpty() {
        List<Id> trailIds = new List<Id>();
        
        Test.startTest();
        AuditTrailViewController.ProcessingResult result = AuditTrailViewController.processAuditTrails(trailIds);
        Test.stopTest();
        
        Assert.isNotNull(result, 'Result should not be null');
        Assert.areEqual(0, result.processedCount, 'Should process 0 trails');
    }
    
    /**
     * @description Test syncOrgAuditTrails
     */
    @isTest
    static void testSyncOrgAuditTrails() {
        OrgConnection__c org = [SELECT Id FROM OrgConnection__c LIMIT 1];
        
        Test.startTest();
        AuditTrailViewController.SyncResult result = AuditTrailViewController.syncOrgAuditTrails(org.Id);
        Test.stopTest();
        
        Assert.isNotNull(result, 'Result should not be null');
        Assert.isTrue(result.syncedCount >= 0, 'Should return synced count');
    }
    
    /**
     * @description Test syncOrgAuditTrails with invalid org
     */
    @isTest
    static void testSyncOrgAuditTrailsInvalid() {
        String invalidOrgId = '001XX000003DHP';
        
        Test.startTest();
        try {
            AuditTrailViewController.syncOrgAuditTrails(invalidOrgId);
            Assert.fail('Should throw exception');
        } catch (AuraHandledException e) {
            Assert.isTrue(e.getMessage().contains('Error'), 'Should contain error message');
        }
        Test.stopTest();
    }
    
    /**
     * @description Test multiple filters together
     */
    @isTest
    static void testGetAuditTrailsMultipleFilters() {
        OrgConnection__c org = [SELECT Id FROM OrgConnection__c LIMIT 1];
        Date dateFrom = Date.today().addDays(-10);
        Date dateTo = Date.today();
        
        List<SetupAuditTrail__c> result = AuditTrailViewController.getAuditTrails(
            org.Id, 'Created', 'CustomObject', 'Test', dateFrom, dateTo, false
        );
        
        Assert.isNotNull(result, 'Result should not be null');
    }
    
    /**
     * @description Test getAuditTrails caching
     */
    @isTest
    static void testGetAuditTrailsCaching() {
        Test.startTest();
        List<SetupAuditTrail__c> result1 = AuditTrailViewController.getAuditTrails(
            null, null, null, null, null, null, false
        );
        List<SetupAuditTrail__c> result2 = AuditTrailViewController.getAuditTrails(
            null, null, null, null, null, null, false
        );
        Test.stopTest();
        
        Assert.areEqual(result1.size(), result2.size(), 'Results should be consistent');
    }
}
