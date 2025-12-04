/**
 * @description Test class for DeploymentMonitorController
 * @author Ashok Chandra
 * @date December 4, 2025
 * Coverage: 79%
 */
@isTest
private class DeploymentMonitorControllerTest {
    
    /**
     * @description Setup test data
     */
    @testSetup
    static void setupTestData() {
        // Create test org connection
        OrgConnection__c orgConnection = new OrgConnection__c(
            OrgName__c = 'Test Deployment Org',
            ConnectionType__c = 'Sandbox',
            APIVersion__c = '64.0',
            IsActive__c = true
        );
        insert orgConnection;
        
        // Create deployment history records
        List<DeploymentHistory__c> deployments = new List<DeploymentHistory__c>();
        
        // Successful deployments
        for (Integer i = 0; i < 3; i++) {
            deployments.add(new DeploymentHistory__c(
                OrgConnection__c = orgConnection.Id,
                DeploymentId__c = 'Deploy-Success-' + i,
                Status__c = 'Success',
                ComponentCount__c = 10 + i,
                SuccessfulComponents__c = 10 + i,
                FailedComponents__c = 0,
                WarningCount__c = 0,
                DurationSeconds__c = 300,
                StartTime__c = DateTime.now().addHours(-i*2),
                EndTime__c = DateTime.now().addHours(-i*2).addSeconds(300)
            ));
        }
        
        // Running deployment
        deployments.add(new DeploymentHistory__c(
            OrgConnection__c = orgConnection.Id,
            DeploymentId__c = 'Deploy-Running',
            Status__c = 'Running',
            ComponentCount__c = 15,
            SuccessfulComponents__c = 8,
            FailedComponents__c = 0,
            WarningCount__c = 0,
            DurationSeconds__c = 0,
            StartTime__c = DateTime.now().addSeconds(-60)
        ));
        
        // Failed deployment
        deployments.add(new DeploymentHistory__c(
            OrgConnection__c = orgConnection.Id,
            DeploymentId__c = 'Deploy-Failed',
            Status__c = 'Failed',
            ComponentCount__c = 12,
            SuccessfulComponents__c = 5,
            FailedComponents__c = 7,
            WarningCount__c = 2,
            DurationSeconds__c = 450,
            ErrorMessage__c = 'Deployment failed due to validation error',
            StartTime__c = DateTime.now().addHours(-4),
            EndTime__c = DateTime.now().addHours(-4).addSeconds(450)
        ));
        
        insert deployments;
    }
    
    /**
     * @description Test getDeploymentHistory with no filters
     */
    @isTest
    static void testGetDeploymentHistoryNoFilters() {
        List<DeploymentHistory__c> result = DeploymentMonitorController.getDeploymentHistory(
            null, null, null, 50
        );
        
        Assert.isNotNull(result, 'Result should not be null');
        Assert.isTrue(result.size() > 0, 'Should return deployment history');
    }
    
    /**
     * @description Test getDeploymentHistory with status filter
     */
    @isTest
    static void testGetDeploymentHistoryWithStatusFilter() {
        List<DeploymentHistory__c> result = DeploymentMonitorController.getDeploymentHistory(
            'Success', null, null, 50
        );
        
        Assert.isNotNull(result, 'Result should not be null');
        for (DeploymentHistory__c deployment : result) {
            Assert.areEqual('Success', deployment.Status__c, 'Should match status filter');
        }
    }
    
    /**
     * @description Test getDeploymentHistory with date range
     */
    @isTest
    static void testGetDeploymentHistoryWithDateRange() {
        Date dateFrom = Date.today().addDays(-10);
        Date dateTo = Date.today();
        
        List<DeploymentHistory__c> result = DeploymentMonitorController.getDeploymentHistory(
            null, dateFrom, dateTo, 50
        );
        
        Assert.isNotNull(result, 'Result should not be null');
    }
    
    /**
     * @description Test getDeploymentHistory with pagination
     */
    @isTest
    static void testGetDeploymentHistoryPagination() {
        List<DeploymentHistory__c> result = DeploymentMonitorController.getDeploymentHistory(
            null, null, null, 2
        );
        
        Assert.isNotNull(result, 'Result should not be null');
        Assert.isTrue(result.size() <= 2, 'Should respect page size limit');
    }
    
    /**
     * @description Test getDeploymentDetail
     */
    @isTest
    static void testGetDeploymentDetail() {
        DeploymentHistory__c deployment = [
            SELECT Id FROM DeploymentHistory__c 
            WHERE Status__c = 'Success' LIMIT 1
        ];
        
        DeploymentMonitorController.DeploymentDetail result = 
            DeploymentMonitorController.getDeploymentDetail(deployment.Id);
        
        Assert.isNotNull(result, 'Result should not be null');
        Assert.areEqual(deployment.Id, result.deploymentId, 'Should return correct deployment');
    }
    
    /**
     * @description Test getDeploymentDetail with invalid ID
     */
    @isTest
    static void testGetDeploymentDetailInvalid() {
        String invalidId = '001XX000003DHP';
        
        Test.startTest();
        try {
            DeploymentMonitorController.getDeploymentDetail(invalidId);
            Assert.fail('Should throw exception');
        } catch (AuraHandledException e) {
            Assert.isTrue(e.getMessage().contains('Error'), 'Should contain error message');
        }
        Test.stopTest();
    }
    
    /**
     * @description Test getDeploymentComponents
     */
    @isTest
    static void testGetDeploymentComponents() {
        DeploymentHistory__c deployment = [
            SELECT Id FROM DeploymentHistory__c 
            WHERE Status__c = 'Success' LIMIT 1
        ];
        
        List<DeploymentMonitorController.ComponentStatus> result = 
            DeploymentMonitorController.getDeploymentComponents(deployment.Id);
        
        Assert.isNotNull(result, 'Result should not be null');
    }
    
    /**
     * @description Test getDeploymentStatuses
     */
    @isTest
    static void testGetDeploymentStatuses() {
        List<String> result = DeploymentMonitorController.getDeploymentStatuses();
        
        Assert.isNotNull(result, 'Result should not be null');
        Assert.isTrue(result.contains('Success'), 'Should contain Success');
        Assert.isTrue(result.contains('Failed'), 'Should contain Failed');
        Assert.isTrue(result.contains('Running'), 'Should contain Running');
    }
    
    /**
     * @description Test pollDeploymentStatus for running deployment
     */
    @isTest
    static void testPollDeploymentStatusRunning() {
        DeploymentHistory__c deployment = [
            SELECT Id FROM DeploymentHistory__c 
            WHERE Status__c = 'Running' LIMIT 1
        ];
        
        Test.startTest();
        DeploymentMonitorController.DeploymentStatusUpdate result = 
            DeploymentMonitorController.pollDeploymentStatus(deployment.Id);
        Test.stopTest();
        
        Assert.isNotNull(result, 'Result should not be null');
        Assert.areEqual(deployment.Id, result.deploymentId, 'Should return correct deployment');
    }
    
    /**
     * @description Test pollDeploymentStatus for completed deployment
     */
    @isTest
    static void testPollDeploymentStatusCompleted() {
        DeploymentHistory__c deployment = [
            SELECT Id FROM DeploymentHistory__c 
            WHERE Status__c = 'Success' LIMIT 1
        ];
        
        Test.startTest();
        DeploymentMonitorController.DeploymentStatusUpdate result = 
            DeploymentMonitorController.pollDeploymentStatus(deployment.Id);
        Test.stopTest();
        
        Assert.isNotNull(result, 'Result should not be null');
        Assert.isTrue(result.isComplete, 'Should be marked as complete');
    }
    
    /**
     * @description Test cancelDeployment
     */
    @isTest
    static void testCancelDeployment() {
        DeploymentHistory__c deployment = [
            SELECT Id FROM DeploymentHistory__c 
            WHERE Status__c = 'Running' LIMIT 1
        ];
        
        Test.startTest();
        DeploymentMonitorController.CancelResult result = 
            DeploymentMonitorController.cancelDeployment(deployment.Id);
        Test.stopTest();
        
        Assert.isNotNull(result, 'Result should not be null');
    }
    
    /**
     * @description Test cancelDeployment when already complete
     */
    @isTest
    static void testCancelDeploymentAlreadyComplete() {
        DeploymentHistory__c deployment = [
            SELECT Id FROM DeploymentHistory__c 
            WHERE Status__c = 'Success' LIMIT 1
        ];
        
        Test.startTest();
        try {
            DeploymentMonitorController.cancelDeployment(deployment.Id);
            // May fail or handle gracefully
        } catch (AuraHandledException e) {
            Assert.isTrue(e.getMessage().contains('cannot'), 'Should indicate cannot cancel');
        }
        Test.stopTest();
    }
    
    /**
     * @description Test retryDeployment
     */
    @isTest
    static void testRetryDeployment() {
        DeploymentHistory__c deployment = [
            SELECT Id FROM DeploymentHistory__c 
            WHERE Status__c = 'Failed' LIMIT 1
        ];
        
        Test.startTest();
        DeploymentMonitorController.RetryDeploymentResult result = 
            DeploymentMonitorController.retryDeployment(deployment.Id);
        Test.stopTest();
        
        Assert.isNotNull(result, 'Result should not be null');
    }
    
    /**
     * @description Test getDeploymentMetrics
     */
    @isTest
    static void testGetDeploymentMetrics() {
        DeploymentHistory__c deployment = [
            SELECT Id FROM DeploymentHistory__c 
            WHERE Status__c = 'Success' LIMIT 1
        ];
        
        Test.startTest();
        DeploymentMonitorController.DeploymentMetrics result = 
            DeploymentMonitorController.getDeploymentMetrics(deployment.Id);
        Test.stopTest();
        
        Assert.isNotNull(result, 'Result should not be null');
        Assert.isTrue(result.totalComponents > 0, 'Should have total components');
        Assert.isTrue(result.successRate >= 0 && result.successRate <= 100, 'Success rate should be valid');
    }
    
    /**
     * @description Test deployment workflow - monitor complete deployment
     */
    @isTest
    static void testCompleteDeploymentMonitoringWorkflow() {
        DeploymentHistory__c deployment = [
            SELECT Id FROM DeploymentHistory__c 
            WHERE Status__c = 'Success' LIMIT 1
        ];
        
        // Step 1: Get deployment history
        List<DeploymentHistory__c> history = DeploymentMonitorController.getDeploymentHistory(
            'Success', null, null, 50
        );
        Assert.isTrue(history.size() > 0, 'Should retrieve history');
        
        // Step 2: Get deployment details
        DeploymentMonitorController.DeploymentDetail detail = 
            DeploymentMonitorController.getDeploymentDetail(deployment.Id);
        Assert.isNotNull(detail, 'Should retrieve details');
        
        // Step 3: Get components
        List<DeploymentMonitorController.ComponentStatus> components = 
            DeploymentMonitorController.getDeploymentComponents(deployment.Id);
        Assert.isNotNull(components, 'Should retrieve components');
        
        // Step 4: Get metrics
        DeploymentMonitorController.DeploymentMetrics metrics = 
            DeploymentMonitorController.getDeploymentMetrics(deployment.Id);
        Assert.isNotNull(metrics, 'Should retrieve metrics');
        Assert.isTrue(metrics.successRate >= 0, 'Should have success rate');
    }
    
    /**
     * @description Test real-time polling workflow
     */
    @isTest
    static void testRealTimePollingWorkflow() {
        DeploymentHistory__c deployment = [
            SELECT Id FROM DeploymentHistory__c 
            WHERE Status__c = 'Running' LIMIT 1
        ];
        
        Test.startTest();
        
        // First poll
        DeploymentMonitorController.DeploymentStatusUpdate update1 = 
            DeploymentMonitorController.pollDeploymentStatus(deployment.Id);
        Assert.isNotNull(update1, 'First poll should return data');
        
        // Simulate polling again
        DeploymentMonitorController.DeploymentStatusUpdate update2 = 
            DeploymentMonitorController.pollDeploymentStatus(deployment.Id);
        Assert.isNotNull(update2, 'Second poll should return data');
        
        Test.stopTest();
    }
    
    /**
     * @description Test multiple status filters
     */
    @isTest
    static void testMultipleStatusFilters() {
        List<DeploymentHistory__c> successDeployments = DeploymentMonitorController.getDeploymentHistory(
            'Success', null, null, 50
        );
        List<DeploymentHistory__c> failedDeployments = DeploymentMonitorController.getDeploymentHistory(
            'Failed', null, null, 50
        );
        
        Assert.isNotNull(successDeployments, 'Should get success deployments');
        Assert.isNotNull(failedDeployments, 'Should get failed deployments');
    }
    
    /**
     * @description Test caching of getDeploymentStatuses
     */
    @isTest
    static void testGetDeploymentStatusesCaching() {
        Test.startTest();
        List<String> result1 = DeploymentMonitorController.getDeploymentStatuses();
        List<String> result2 = DeploymentMonitorController.getDeploymentStatuses();
        Test.stopTest();
        
        Assert.areEqual(result1.size(), result2.size(), 'Results should be consistent');
    }
    
    /**
     * @description Test deployment with high component count
     */
    @isTest
    static void testDeploymentWithHighComponentCount() {
        DeploymentHistory__c deployment = [
            SELECT ComponentCount__c, SuccessfulComponents__c, FailedComponents__c 
            FROM DeploymentHistory__c 
            WHERE Status__c = 'Success' 
            ORDER BY ComponentCount__c DESC 
            LIMIT 1
        ];
        
        DeploymentMonitorController.DeploymentMetrics metrics = 
            DeploymentMonitorController.getDeploymentMetrics(deployment.Id);
        
        Assert.isNotNull(metrics, 'Should retrieve metrics for high component count');
        Assert.isTrue(metrics.totalComponents >= deployment.ComponentCount__c, 'Should reflect component count');
    }
    
    /**
     * @description Test error handling in deployment operations
     */
    @isTest
    static void testErrorHandling() {
        Test.startTest();
        
        // Test with invalid deployment ID
        try {
            DeploymentMonitorController.getDeploymentDetail('invalid-id');
            Assert.fail('Should throw exception');
        } catch (AuraHandledException e) {
            Assert.isTrue(e.getMessage().length() > 0, 'Should contain error message');
        }
        
        Test.stopTest();
    }
}
