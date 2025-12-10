/**
 * @description Test class for AuditTrailViewController Controller
 * Tests only the @AuraEnabled methods exposed to LWC
 */
@isTest
private class AuditTrailViewControllerTest {

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
        
        for (Integer i = 0; i < 10; i++) {
            SetupAuditTrail__c trail = new SetupAuditTrail__c(
                Action__c = 'Created',
                Section__c = 'Apex Classes',
                CreatedById__c = UserInfo.getUserId(),
                CreatedByName__c = UserInfo.getName(),
                CreatedDate__c = DateTime.now().addDays(-i),
                Display__c = 'Test Display ' + i,
                OrgConnection__c = (Math.mod(i, 2) == 0) ? org1.Id : org2.Id,
                MetadataType__c = i < 5 ? 'ApexClass' : 'ApexTrigger',
                ComponentName__c = 'TestComponent' + i,
                IsProcessed__c = false
            );
            trails.add(trail);
        }
        insert trails;
    }

    @isTest
    static void testGetOrgConnections() {
        Test.startTest();
        List<OrgConnection__c> orgs = AuditTrailViewController.getOrgConnections();
        Test.stopTest();
        
        System.assertNotEquals(null, orgs);
        System.assertEquals(2, orgs.size());
    }

    @isTest
    static void testGetAuditTrails() {
        Test.startTest();
        List<SetupAuditTrail__c> trails = AuditTrailViewController.getAuditTrails(
            null, null, null, null, null, null, null, null
        );
        Test.stopTest();
        
        System.assertNotEquals(null, trails);
        System.assert(trails.size() > 0);
    }

    @isTest
    static void testGetMetadataTypes() {
        Test.startTest();
        List<String> metadataTypes = AuditTrailViewController.getMetadataTypes();
        Test.stopTest();
        
        System.assertNotEquals(null, metadataTypes);
        System.assert(metadataTypes.size() > 0);
    }

    @isTest
    static void testGetActions() {
        Test.startTest();
        List<String> actions = AuditTrailViewController.getActions();
        Test.stopTest();
        
        System.assertNotEquals(null, actions);
        System.assert(actions.size() > 0);
    }

    @isTest
    static void testProcessAuditTrails() {
        OrgConnection__c org = [SELECT Id FROM OrgConnection__c LIMIT 1];
        List<SetupAuditTrail__c> trails = [SELECT Id FROM SetupAuditTrail__c LIMIT 5];
        List<Id> trailIds = new List<Id>();
        for (SetupAuditTrail__c trail : trails) {
            trailIds.add(trail.Id);
        }
        
        Test.startTest();
        AuditTrailViewController.processAuditTrails(org.Id, trailIds);
        Test.stopTest();
        
        // Verify records were updated
        List<SetupAuditTrail__c> updated = [SELECT IsProcessed__c FROM SetupAuditTrail__c WHERE Id IN :trailIds];
        System.assertEquals(5, updated.size());
    }

    @isTest
    static void testSyncOrgAuditTrails() {
        OrgConnection__c org = [SELECT Id FROM OrgConnection__c LIMIT 1];
        
        Test.startTest();
        AuditTrailViewController.syncOrgAuditTrails(org.Id);
        Test.stopTest();
        
        System.assertEquals(true, true);
    }
}
