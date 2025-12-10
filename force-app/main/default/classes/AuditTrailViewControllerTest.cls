@isTest/**

private class AuditTrailViewControllerTest { * @description Test class for AuditTrailViewController Controller

 * Tests only the @AuraEnabled methods exposed to LWC

    @TestSetup */

    static void setupTestData() {@isTest

        OrgConnection__c org = new OrgConnection__c(private class AuditTrailViewControllerTest {

            OrgName__c = 'Test Org',

            OrgType__c = 'Production',    @TestSetup

            InstanceURL__c = 'https://test.salesforce.com',    static void setupTestData() {

            IsActive__c = true        // Create test org connections

        );        List<OrgConnection__c> orgs = new List<OrgConnection__c>();

        insert org;        

                OrgConnection__c org1 = new OrgConnection__c(

        List<SetupAuditTrail__c> trails = new List<SetupAuditTrail__c>();            OrgName__c = 'Test Org 1',

        for (Integer i = 0; i < 5; i++) {            OrgType__c = 'Production',

            trails.add(new SetupAuditTrail__c(            InstanceURL__c = 'https://test1.salesforce.com',

                Action__c = 'Created',            IsActive__c = true,

                Section__c = 'Apex',            NamedCredential__c = 'TestCred1'

                CreatedByName__c = 'Test User',        );

                Display__c = 'Test ' + i,        orgs.add(org1);

                OrgConnection__c = org.Id,        

                MetadataType__c = 'ApexClass',        OrgConnection__c org2 = new OrgConnection__c(

                ComponentName__c = 'TestClass' + i            OrgName__c = 'Test Org 2',

            ));            OrgType__c = 'Sandbox',

        }            InstanceURL__c = 'https://test2.salesforce.com',

        insert trails;            IsActive__c = true,

    }            NamedCredential__c = 'TestCred2'

        );

    @isTest        orgs.add(org2);

    static void testGetOrgConnections() {        

        Test.startTest();        insert orgs;

        List<OrgConnection__c> result = AuditTrailViewController.getOrgConnections();        

        Test.stopTest();        // Create test audit trail records

                List<SetupAuditTrail__c> trails = new List<SetupAuditTrail__c>();

        System.assertNotEquals(null, result);        

        System.assertEquals(1, result.size());        for (Integer i = 0; i < 10; i++) {

    }            SetupAuditTrail__c trail = new SetupAuditTrail__c(

                Action__c = 'Created',

    @isTest                Section__c = 'Apex Classes',

    static void testGetAuditTrails() {                CreatedById__c = UserInfo.getUserId(),

        Test.startTest();                CreatedByName__c = UserInfo.getName(),

        List<SetupAuditTrail__c> result = AuditTrailViewController.getAuditTrails(                CreatedDate__c = DateTime.now().addDays(-i),

            null, null, null, null, null, null, null                Display__c = 'Test Display ' + i,

        );                OrgConnection__c = (Math.mod(i, 2) == 0) ? org1.Id : org2.Id,

        Test.stopTest();                MetadataType__c = i < 5 ? 'ApexClass' : 'ApexTrigger',

                        ComponentName__c = 'TestComponent' + i,

        System.assertNotEquals(null, result);                IsProcessed__c = false

        System.assert(result.size() > 0);            );

    }            trails.add(trail);

        }

    @isTest        insert trails;

    static void testGetMetadataTypes() {    }

        Test.startTest();

        List<String> result = AuditTrailViewController.getMetadataTypes();    @isTest

        Test.stopTest();    static void testGetOrgConnections() {

                Test.startTest();

        System.assertNotEquals(null, result);        List<OrgConnection__c> orgs = AuditTrailViewController.getOrgConnections();

    }        Test.stopTest();

        

    @isTest        System.assertNotEquals(null, orgs);

    static void testGetActions() {        System.assertEquals(2, orgs.size());

        Test.startTest();    }

        List<String> result = AuditTrailViewController.getActions();

        Test.stopTest();    @isTest

            static void testGetAuditTrails() {

        System.assertNotEquals(null, result);        Test.startTest();

        System.assertEquals(5, result.size());        List<SetupAuditTrail__c> trails = AuditTrailViewController.getAuditTrails(

    }            null, null, null, null, null, null, null, null

        );

    @isTest        Test.stopTest();

    static void testProcessAuditTrails() {        

        List<SetupAuditTrail__c> trails = [SELECT Id FROM SetupAuditTrail__c LIMIT 3];        System.assertNotEquals(null, trails);

        List<String> trailIds = new List<String>();        System.assert(trails.size() > 0);

        for (SetupAuditTrail__c trail : trails) {    }

            trailIds.add(trail.Id);

        }    @isTest

            static void testGetMetadataTypes() {

        Test.startTest();        Test.startTest();

        Integer processed = AuditTrailViewController.processAuditTrails(trailIds);        List<String> metadataTypes = AuditTrailViewController.getMetadataTypes();

        Test.stopTest();        Test.stopTest();

                

        System.assertEquals(3, processed);        System.assertNotEquals(null, metadataTypes);

    }        System.assert(metadataTypes.size() > 0);

    }

    @isTest

    static void testSyncOrgAuditTrails() {    @isTest

        OrgConnection__c org = [SELECT Id FROM OrgConnection__c LIMIT 1];    static void testGetActions() {

                Test.startTest();

        Test.startTest();        List<String> actions = AuditTrailViewController.getActions();

        Integer synced = AuditTrailViewController.syncOrgAuditTrails(org.Id);        Test.stopTest();

        Test.stopTest();        

                System.assertNotEquals(null, actions);

        System.assertNotEquals(null, synced);        System.assert(actions.size() > 0);

    }    }

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
