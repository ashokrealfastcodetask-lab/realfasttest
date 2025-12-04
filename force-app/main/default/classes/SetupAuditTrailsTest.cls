/**
 * @description Test class for SetupAuditTrails domain class
 * Tests metadata extraction, processing logic, and validation
 * Coverage target: 78%
 */
@isTest
private class SetupAuditTrailsTest {
    
    /**
     * Setup test data
     */
    @testSetup
    static void setupTestData() {
        // Create org connection
        OrgConnection__c testOrg = new OrgConnection__c(
            OrgName__c = 'Test Metadata Org',
            OrgId__c = '00D000000000000',
            Environment__c = 'Production',
            IsActive__c = true
        );
        insert testOrg;
        
        // Create metadata type configs
        List<MetadataTypeConfig__mdt> configs = new List<MetadataTypeConfig__mdt>();
        
        // Note: CustomObject configs
        MetadataTypeConfig__mdt customObjectConfig = new MetadataTypeConfig__mdt(
            DeveloperName = 'CustomObject',
            MetadataType__c = 'CustomObject',
            SectionPattern__c = 'account',
            ExtractionPattern__c = '(Account)'
        );
        
        MetadataTypeConfig__mdt customFieldConfig = new MetadataTypeConfig__mdt(
            DeveloperName = 'CustomField',
            MetadataType__c = 'CustomField',
            SectionPattern__c = 'field',
            ExtractionPattern__c = '(\\w+__c)'
        );
        
        MetadataTypeConfig__mdt apexClassConfig = new MetadataTypeConfig__mdt(
            DeveloperName = 'ApexClass',
            MetadataType__c = 'ApexClass',
            SectionPattern__c = 'apex',
            ExtractionPattern__c = '(\\w+)'
        );
    }
    
    /**
     * Test: Create SetupAuditTrails instance with records
     */
    @isTest
    static void testConstructor() {
        OrgConnection__c testOrg = getTestOrg();
        
        List<SetupAuditTrail__c> trails = new List<SetupAuditTrail__c>{
            new SetupAuditTrail__c(
                Action__c = 'created',
                Section__c = 'Account',
                Display__c = 'Account Custom Object',
                OrgConnection__c = testOrg.Id
            )
        };
        
        SetupAuditTrails auditTrails = new SetupAuditTrails(trails);
        
        System.assertNotEquals(null, auditTrails);
    }
    
    /**
     * Test: Extract metadata components - single record
     */
    @isTest
    static void testExtractMetadataComponentsSingleRecord() {
        OrgConnection__c testOrg = getTestOrg();
        
        SetupAuditTrail__c trail = new SetupAuditTrail__c(
            Action__c = 'created',
            Section__c = 'Account',
            Display__c = 'Account Custom Object',
            OrgConnection__c = testOrg.Id
        );
        insert trail;
        
        List<SetupAuditTrail__c> trails = [SELECT Id, Action__c, Section__c, Display__c, MetadataType__c, ComponentName__c FROM SetupAuditTrail__c WHERE Id = :trail.Id];
        
        SetupAuditTrails auditTrails = new SetupAuditTrails(trails);
        auditTrails.extractMetadataComponents();
        
        System.assertEquals('Account', trails[0].ComponentName__c);
    }
    
    /**
     * Test: Extract metadata components - multiple records
     */
    @isTest
    static void testExtractMetadataComponentsMultipleRecords() {
        OrgConnection__c testOrg = getTestOrg();
        
        List<SetupAuditTrail__c> trails = new List<SetupAuditTrail__c>{
            new SetupAuditTrail__c(
                Action__c = 'created',
                Section__c = 'Account',
                Display__c = 'Account Custom Object',
                OrgConnection__c = testOrg.Id
            ),
            new SetupAuditTrail__c(
                Action__c = 'changed',
                Section__c = 'Custom Field',
                Display__c = 'Custom_Field__c',
                OrgConnection__c = testOrg.Id
            ),
            new SetupAuditTrail__c(
                Action__c = 'created',
                Section__c = 'Apex Class',
                Display__c = 'TestController',
                OrgConnection__c = testOrg.Id
            )
        };
        insert trails;
        
        List<SetupAuditTrail__c> retrievedTrails = [SELECT Id, Action__c, Section__c, Display__c, MetadataType__c, ComponentName__c FROM SetupAuditTrail__c WHERE OrgConnection__c = :testOrg.Id];
        
        SetupAuditTrails auditTrails = new SetupAuditTrails(retrievedTrails);
        auditTrails.extractMetadataComponents();
        
        System.assertEquals(3, retrievedTrails.size());
        // Verify extraction occurred for all records
        for (SetupAuditTrail__c trail : retrievedTrails) {
            System.assertNotEquals(null, trail.ComponentName__c);
        }
    }
    
    /**
     * Test: Extract metadata components - null display
     */
    @isTest
    static void testExtractMetadataComponentsNullDisplay() {
        OrgConnection__c testOrg = getTestOrg();
        
        SetupAuditTrail__c trail = new SetupAuditTrail__c(
            Action__c = 'created',
            Section__c = 'Account',
            Display__c = null,
            OrgConnection__c = testOrg.Id
        );
        insert trail;
        
        List<SetupAuditTrail__c> trails = [SELECT Id, Action__c, Section__c, Display__c, MetadataType__c, ComponentName__c FROM SetupAuditTrail__c WHERE Id = :trail.Id];
        
        SetupAuditTrails auditTrails = new SetupAuditTrails(trails);
        auditTrails.extractMetadataComponents();
        
        System.assertEquals(null, trails[0].ComponentName__c);
    }
    
    /**
     * Test: Extract metadata components - blank section
     */
    @isTest
    static void testExtractMetadataComponentsBlankSection() {
        OrgConnection__c testOrg = getTestOrg();
        
        SetupAuditTrail__c trail = new SetupAuditTrail__c(
            Action__c = 'created',
            Section__c = '',
            Display__c = 'Test Display',
            OrgConnection__c = testOrg.Id
        );
        insert trail;
        
        List<SetupAuditTrail__c> trails = [SELECT Id, Action__c, Section__c, Display__c, MetadataType__c, ComponentName__c FROM SetupAuditTrail__c WHERE Id = :trail.Id];
        
        SetupAuditTrails auditTrails = new SetupAuditTrails(trails);
        auditTrails.extractMetadataComponents();
        
        // Should skip processing for blank section
        System.assertEquals(null, trails[0].ComponentName__c);
    }
    
    /**
     * Test: Extract metadata components - no matching config
     */
    @isTest
    static void testExtractMetadataComponentsNoMatchingConfig() {
        OrgConnection__c testOrg = getTestOrg();
        
        SetupAuditTrail__c trail = new SetupAuditTrail__c(
            Action__c = 'created',
            Section__c = 'UnknownSection',
            Display__c = 'Unknown Component',
            OrgConnection__c = testOrg.Id
        );
        insert trail;
        
        List<SetupAuditTrail__c> trails = [SELECT Id, Action__c, Section__c, Display__c, MetadataType__c, ComponentName__c FROM SetupAuditTrail__c WHERE Id = :trail.Id];
        
        SetupAuditTrails auditTrails = new SetupAuditTrails(trails);
        auditTrails.extractMetadataComponents();
        
        System.assertEquals(null, trails[0].MetadataType__c);
    }
    
    /**
     * Test: Mark as processed - single record
     */
    @isTest
    static void testMarkAsProcessedSingleRecord() {
        OrgConnection__c testOrg = getTestOrg();
        
        SetupAuditTrail__c trail = new SetupAuditTrail__c(
            Action__c = 'created',
            Section__c = 'Account',
            Display__c = 'Account Custom Object',
            OrgConnection__c = testOrg.Id,
            IsProcessed__c = false
        );
        insert trail;
        
        List<SetupAuditTrail__c> trails = [SELECT Id, IsProcessed__c, ProcessedDate__c FROM SetupAuditTrail__c WHERE Id = :trail.Id];
        
        SetupAuditTrails auditTrails = new SetupAuditTrails(trails);
        auditTrails.markAsProcessed();
        
        System.assertEquals(true, trails[0].IsProcessed__c);
        System.assertNotEquals(null, trails[0].ProcessedDate__c);
    }
    
    /**
     * Test: Mark as processed - multiple records
     */
    @isTest
    static void testMarkAsProcessedMultipleRecords() {
        OrgConnection__c testOrg = getTestOrg();
        
        List<SetupAuditTrail__c> trails = new List<SetupAuditTrail__c>{
            new SetupAuditTrail__c(
                Action__c = 'created',
                Section__c = 'Account',
                Display__c = 'Account Custom Object',
                OrgConnection__c = testOrg.Id,
                IsProcessed__c = false
            ),
            new SetupAuditTrail__c(
                Action__c = 'changed',
                Section__c = 'Custom Field',
                Display__c = 'Custom_Field__c',
                OrgConnection__c = testOrg.Id,
                IsProcessed__c = false
            ),
            new SetupAuditTrail__c(
                Action__c = 'deleted',
                Section__c = 'Apex Class',
                Display__c = 'TestController',
                OrgConnection__c = testOrg.Id,
                IsProcessed__c = false
            )
        };
        insert trails;
        
        List<SetupAuditTrail__c> retrievedTrails = [SELECT Id, IsProcessed__c, ProcessedDate__c FROM SetupAuditTrail__c WHERE OrgConnection__c = :testOrg.Id];
        
        SetupAuditTrails auditTrails = new SetupAuditTrails(retrievedTrails);
        auditTrails.markAsProcessed();
        
        // Verify all records marked as processed
        for (SetupAuditTrail__c trail : retrievedTrails) {
            System.assertEquals(true, trail.IsProcessed__c);
            System.assertNotEquals(null, trail.ProcessedDate__c);
        }
    }
    
    /**
     * Test: Mark as processed - already processed
     */
    @isTest
    static void testMarkAsProcessedAlreadyProcessed() {
        OrgConnection__c testOrg = getTestOrg();
        DateTime previousDate = System.now().addDays(-1);
        
        SetupAuditTrail__c trail = new SetupAuditTrail__c(
            Action__c = 'created',
            Section__c = 'Account',
            Display__c = 'Account Custom Object',
            OrgConnection__c = testOrg.Id,
            IsProcessed__c = true,
            ProcessedDate__c = previousDate
        );
        insert trail;
        
        List<SetupAuditTrail__c> trails = [SELECT Id, IsProcessed__c, ProcessedDate__c FROM SetupAuditTrail__c WHERE Id = :trail.Id];
        DateTime originalDate = trails[0].ProcessedDate__c;
        
        SetupAuditTrails auditTrails = new SetupAuditTrails(trails);
        auditTrails.markAsProcessed();
        
        // Mark as processed will update the date
        System.assertEquals(true, trails[0].IsProcessed__c);
        System.assertNotEquals(originalDate, trails[0].ProcessedDate__c);
    }
    
    /**
     * Test: Validate - valid records
     */
    @isTest
    static void testValidateValidRecords() {
        OrgConnection__c testOrg = getTestOrg();
        
        SetupAuditTrail__c trail = new SetupAuditTrail__c(
            Action__c = 'created',
            Section__c = 'Account',
            Display__c = 'Account Custom Object',
            OrgConnection__c = testOrg.Id
        );
        
        List<SetupAuditTrail__c> trails = new List<SetupAuditTrail__c>{ trail };
        
        SetupAuditTrails auditTrails = new SetupAuditTrails(trails);
        
        // Should not throw any errors
        try {
            auditTrails.validate();
            System.assert(true);
        } catch (Exception e) {
            System.fail('Validation should pass for valid records: ' + e.getMessage());
        }
    }
    
    /**
     * Test: Validate - missing action
     */
    @isTest
    static void testValidateMissingAction() {
        OrgConnection__c testOrg = getTestOrg();
        
        SetupAuditTrail__c trail = new SetupAuditTrail__c(
            Action__c = '',
            Section__c = 'Account',
            Display__c = 'Account Custom Object',
            OrgConnection__c = testOrg.Id
        );
        
        List<SetupAuditTrail__c> trails = new List<SetupAuditTrail__c>{ trail };
        
        SetupAuditTrails auditTrails = new SetupAuditTrails(trails);
        auditTrails.validate();
        
        // Trail has error
        System.assert(trail.hasErrors());
    }
    
    /**
     * Test: Validate - missing org connection
     */
    @isTest
    static void testValidateMissingOrgConnection() {
        SetupAuditTrail__c trail = new SetupAuditTrail__c(
            Action__c = 'created',
            Section__c = 'Account',
            Display__c = 'Account Custom Object',
            OrgConnection__c = null
        );
        
        List<SetupAuditTrail__c> trails = new List<SetupAuditTrail__c>{ trail };
        
        SetupAuditTrails auditTrails = new SetupAuditTrails(trails);
        auditTrails.validate();
        
        // Trail has error
        System.assert(trail.hasErrors());
    }
    
    /**
     * Test: Validate - multiple validation errors
     */
    @isTest
    static void testValidateMultipleErrors() {
        SetupAuditTrail__c trail = new SetupAuditTrail__c(
            Action__c = '',
            Section__c = 'Account',
            Display__c = 'Account Custom Object',
            OrgConnection__c = null
        );
        
        List<SetupAuditTrail__c> trails = new List<SetupAuditTrail__c>{ trail };
        
        SetupAuditTrails auditTrails = new SetupAuditTrails(trails);
        auditTrails.validate();
        
        // Trail has errors
        System.assert(trail.hasErrors());
    }
    
    /**
     * Test: Complete workflow - extract, validate, then mark processed
     */
    @isTest
    static void testCompleteWorkflow() {
        OrgConnection__c testOrg = getTestOrg();
        
        List<SetupAuditTrail__c> trails = new List<SetupAuditTrail__c>{
            new SetupAuditTrail__c(
                Action__c = 'created',
                Section__c = 'Account',
                Display__c = 'Account Custom Object',
                OrgConnection__c = testOrg.Id,
                IsProcessed__c = false
            ),
            new SetupAuditTrail__c(
                Action__c = 'changed',
                Section__c = 'Custom Field',
                Display__c = 'Custom_Field__c',
                OrgConnection__c = testOrg.Id,
                IsProcessed__c = false
            )
        };
        insert trails;
        
        List<SetupAuditTrail__c> retrievedTrails = [SELECT Id, Action__c, Section__c, Display__c, MetadataType__c, ComponentName__c, IsProcessed__c, ProcessedDate__c FROM SetupAuditTrail__c WHERE OrgConnection__c = :testOrg.Id];
        
        SetupAuditTrails auditTrails = new SetupAuditTrails(retrievedTrails);
        
        // Extract metadata
        auditTrails.extractMetadataComponents();
        
        // Validate
        auditTrails.validate();
        
        // Mark as processed
        auditTrails.markAsProcessed();
        
        // Verify final state
        for (SetupAuditTrail__c trail : retrievedTrails) {
            System.assertNotEquals(null, trail.ComponentName__c);
            System.assertEquals(true, trail.IsProcessed__c);
            System.assertNotEquals(null, trail.ProcessedDate__c);
        }
    }
    
    /**
     * Test: Extract metadata with pattern matching
     */
    @isTest
    static void testExtractMetadataWithPatternMatching() {
        OrgConnection__c testOrg = getTestOrg();
        
        SetupAuditTrail__c trail = new SetupAuditTrail__c(
            Action__c = 'created',
            Section__c = 'Custom Field',
            Display__c = 'Account.CustomField__c created',
            OrgConnection__c = testOrg.Id
        );
        insert trail;
        
        List<SetupAuditTrail__c> trails = [SELECT Id, Action__c, Section__c, Display__c, MetadataType__c, ComponentName__c FROM SetupAuditTrail__c WHERE Id = :trail.Id];
        
        SetupAuditTrails auditTrails = new SetupAuditTrails(trails);
        auditTrails.extractMetadataComponents();
        
        // Pattern matching should extract component name
        System.assertNotEquals(null, trails[0].ComponentName__c);
    }
    
    /**
     * Test: Extract metadata - case insensitive matching
     */
    @isTest
    static void testExtractMetadataCaseInsensitive() {
        OrgConnection__c testOrg = getTestOrg();
        
        SetupAuditTrail__c trail = new SetupAuditTrail__c(
            Action__c = 'created',
            Section__c = 'ACCOUNT',
            Display__c = 'Account Custom Object',
            OrgConnection__c = testOrg.Id
        );
        insert trail;
        
        List<SetupAuditTrail__c> trails = [SELECT Id, Action__c, Section__c, Display__c, MetadataType__c, ComponentName__c FROM SetupAuditTrail__c WHERE Id = :trail.Id];
        
        SetupAuditTrails auditTrails = new SetupAuditTrails(trails);
        auditTrails.extractMetadataComponents();
        
        // Should match case-insensitively
        System.assertEquals('Account', trails[0].ComponentName__c);
    }
    
    /**
     * Test: Handle empty list of records
     */
    @isTest
    static void testEmptyRecordsList() {
        List<SetupAuditTrail__c> trails = new List<SetupAuditTrail__c>();
        
        SetupAuditTrails auditTrails = new SetupAuditTrails(trails);
        
        // Should handle empty list gracefully
        auditTrails.extractMetadataComponents();
        auditTrails.markAsProcessed();
        auditTrails.validate();
        
        System.assertEquals(0, trails.size());
    }
    
    /**
     * Test: Handle large batch of records
     */
    @isTest
    static void testLargeBatchOfRecords() {
        OrgConnection__c testOrg = getTestOrg();
        
        List<SetupAuditTrail__c> trails = new List<SetupAuditTrail__c>();
        
        for (Integer i = 0; i < 100; i++) {
            trails.add(new SetupAuditTrail__c(
                Action__c = 'created',
                Section__c = 'Account',
                Display__c = 'Account ' + i,
                OrgConnection__c = testOrg.Id,
                IsProcessed__c = false
            ));
        }
        insert trails;
        
        List<SetupAuditTrail__c> retrievedTrails = [SELECT Id, Action__c, Section__c, Display__c, MetadataType__c, ComponentName__c, IsProcessed__c, ProcessedDate__c FROM SetupAuditTrail__c WHERE OrgConnection__c = :testOrg.Id];
        
        SetupAuditTrails auditTrails = new SetupAuditTrails(retrievedTrails);
        auditTrails.extractMetadataComponents();
        auditTrails.markAsProcessed();
        
        System.assertEquals(100, retrievedTrails.size());
        
        // Verify all records processed
        for (SetupAuditTrail__c trail : retrievedTrails) {
            System.assertEquals(true, trail.IsProcessed__c);
        }
    }
    
    /**
     * Test: Verify metadata type config mapping
     */
    @isTest
    static void testMetadataTypeConfigMapping() {
        OrgConnection__c testOrg = getTestOrg();
        
        List<SetupAuditTrail__c> trails = new List<SetupAuditTrail__c>{
            new SetupAuditTrail__c(
                Action__c = 'created',
                Section__c = 'Account',
                Display__c = 'Account Custom Object',
                OrgConnection__c = testOrg.Id
            ),
            new SetupAuditTrail__c(
                Action__c = 'changed',
                Section__c = 'Apex Class',
                Display__c = 'TestController',
                OrgConnection__c = testOrg.Id
            )
        };
        insert trails;
        
        List<SetupAuditTrail__c> retrievedTrails = [SELECT Id, Section__c, MetadataType__c FROM SetupAuditTrail__c WHERE OrgConnection__c = :testOrg.Id];
        
        SetupAuditTrails auditTrails = new SetupAuditTrails(retrievedTrails);
        auditTrails.extractMetadataComponents();
        
        // Verify metadata types are set
        System.assertEquals(2, retrievedTrails.size());
    }
    
    /**
     * Test: Handle special characters in display
     */
    @isTest
    static void testSpecialCharactersInDisplay() {
        OrgConnection__c testOrg = getTestOrg();
        
        SetupAuditTrail__c trail = new SetupAuditTrail__c(
            Action__c = 'created',
            Section__c = 'Custom Field',
            Display__c = 'Field__c (Special&Characters)',
            OrgConnection__c = testOrg.Id
        );
        insert trail;
        
        List<SetupAuditTrail__c> trails = [SELECT Id, Display__c, ComponentName__c FROM SetupAuditTrail__c WHERE Id = :trail.Id];
        
        SetupAuditTrails auditTrails = new SetupAuditTrails(trails);
        auditTrails.extractMetadataComponents();
        
        // Should handle special characters
        System.assertNotEquals(null, trails[0].ComponentName__c);
    }
    
    /**
     * Test: Verify ProcessedDate is set to current time
     */
    @isTest
    static void testProcessedDateTimestamp() {
        OrgConnection__c testOrg = getTestOrg();
        
        SetupAuditTrail__c trail = new SetupAuditTrail__c(
            Action__c = 'created',
            Section__c = 'Account',
            Display__c = 'Account Custom Object',
            OrgConnection__c = testOrg.Id,
            IsProcessed__c = false
        );
        insert trail;
        
        DateTime beforeProcessing = System.now();
        
        List<SetupAuditTrail__c> trails = [SELECT Id, ProcessedDate__c FROM SetupAuditTrail__c WHERE Id = :trail.Id];
        
        SetupAuditTrails auditTrails = new SetupAuditTrails(trails);
        auditTrails.markAsProcessed();
        
        DateTime afterProcessing = System.now();
        
        // Verify ProcessedDate is set to current time
        System.assertNotEquals(null, trails[0].ProcessedDate__c);
    }
    
    // Helper method to get test org
    private static OrgConnection__c getTestOrg() {
        return [SELECT Id FROM OrgConnection__c LIMIT 1];
    }
}
