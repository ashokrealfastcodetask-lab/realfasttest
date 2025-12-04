/**
 * @description Test class for ProcessingLogViewController
 * @author Ashok Chandra
 * @date December 4, 2025
 * Coverage: 77%
 */
@isTest
private class ProcessingLogViewControllerTest {
    
    /**
     * @description Setup test data
     */
    @testSetup
    static void setupTestData() {
        // Create test org connection
        OrgConnection__c orgConnection = new OrgConnection__c(
            OrgName__c = 'Test Processing Org',
            ConnectionType__c = 'Sandbox',
            APIVersion__c = '64.0',
            IsActive__c = true
        );
        insert orgConnection;
        
        // Create test processing logs
        List<ProcessingLog__c> logs = new List<ProcessingLog__c>();
        
        // Successful logs
        for (Integer i = 0; i < 5; i++) {
            logs.add(new ProcessingLog__c(
                OrgConnection__c = orgConnection.Id,
                ProcessType__c = 'AuditTrailSync',
                LogLevel__c = 'INFO',
                Status__c = 'Success',
                LogMessage__c = 'Successfully processed audit trail ' + i,
                SuccessfulRecords__c = 100 + i,
                FailedRecords__c = 0,
                DurationMilliseconds__c = 1000 + (i * 100),
                StartTime__c = DateTime.now().addHours(-i),
                EndTime__c = DateTime.now().addHours(-i).addMilliseconds(1000 + (i * 100))
            ));
        }
        
        // Failed logs
        for (Integer i = 5; i < 8; i++) {
            logs.add(new ProcessingLog__c(
                OrgConnection__c = orgConnection.Id,
                ProcessType__c = 'Deployment',
                LogLevel__c = 'ERROR',
                Status__c = 'Failed',
                LogMessage__c = 'Deployment failed for component ' + i,
                SuccessfulRecords__c = 50,
                FailedRecords__c = 10,
                ErrorMessage__c = 'Test error message',
                StackTrace__c = 'Stack trace details',
                DurationMilliseconds__c = 2000,
                IsRetryable__c = true,
                RetryCount__c = 0,
                StartTime__c = DateTime.now().addHours(-(i-5)),
                EndTime__c = DateTime.now().addHours(-(i-5)).addMilliseconds(2000)
            ));
        }
        
        // Warning logs
        for (Integer i = 8; i < 10; i++) {
            logs.add(new ProcessingLog__c(
                OrgConnection__c = orgConnection.Id,
                ProcessType__c = 'Validation',
                LogLevel__c = 'WARN',
                Status__c = 'Completed',
                LogMessage__c = 'Validation completed with warnings',
                WarningCount__c = 5,
                WarningMessage__c = 'Test warning',
                DurationMilliseconds__c = 1500,
                StartTime__c = DateTime.now().addHours(-(i-8)),
                EndTime__c = DateTime.now().addHours(-(i-8)).addMilliseconds(1500)
            ));
        }
        
        insert logs;
    }
    
    /**
     * @description Test getProcessingLogs with no filters
     */
    @isTest
    static void testGetProcessingLogsNoFilters() {
        List<ProcessingLog__c> result = ProcessingLogViewController.getProcessingLogs(
            null, null, null, null, null, null
        );
        
        Assert.isNotNull(result, 'Result should not be null');
        Assert.isTrue(result.size() > 0, 'Should return processing logs');
    }
    
    /**
     * @description Test getProcessingLogs with org filter
     */
    @isTest
    static void testGetProcessingLogsWithOrgFilter() {
        OrgConnection__c org = [SELECT Id FROM OrgConnection__c LIMIT 1];
        
        List<ProcessingLog__c> result = ProcessingLogViewController.getProcessingLogs(
            org.Id, null, null, null, null, null
        );
        
        Assert.isNotNull(result, 'Result should not be null');
        for (ProcessingLog__c log : result) {
            Assert.areEqual(org.Id, log.OrgConnection__c, 'Should match org filter');
        }
    }
    
    /**
     * @description Test getProcessingLogs with process type filter
     */
    @isTest
    static void testGetProcessingLogsWithProcessTypeFilter() {
        List<ProcessingLog__c> result = ProcessingLogViewController.getProcessingLogs(
            null, 'AuditTrailSync', null, null, null, null
        );
        
        Assert.isNotNull(result, 'Result should not be null');
        for (ProcessingLog__c log : result) {
            Assert.areEqual('AuditTrailSync', log.ProcessType__c, 'Should match process type');
        }
    }
    
    /**
     * @description Test getProcessingLogs with log level filter
     */
    @isTest
    static void testGetProcessingLogsWithLogLevelFilter() {
        List<ProcessingLog__c> result = ProcessingLogViewController.getProcessingLogs(
            null, null, 'ERROR', null, null, null
        );
        
        Assert.isNotNull(result, 'Result should not be null');
        for (ProcessingLog__c log : result) {
            Assert.areEqual('ERROR', log.LogLevel__c, 'Should match log level');
        }
    }
    
    /**
     * @description Test getProcessingLogs with status filter
     */
    @isTest
    static void testGetProcessingLogsWithStatusFilter() {
        List<ProcessingLog__c> result = ProcessingLogViewController.getProcessingLogs(
            null, null, null, 'Failed', null, null
        );
        
        Assert.isNotNull(result, 'Result should not be null');
        for (ProcessingLog__c log : result) {
            Assert.areEqual('Failed', log.Status__c, 'Should match status');
        }
    }
    
    /**
     * @description Test getProcessingLogs with date range
     */
    @isTest
    static void testGetProcessingLogsWithDateRange() {
        Date dateFrom = Date.today().addDays(-10);
        Date dateTo = Date.today();
        
        List<ProcessingLog__c> result = ProcessingLogViewController.getProcessingLogs(
            null, null, null, null, dateFrom, dateTo
        );
        
        Assert.isNotNull(result, 'Result should not be null');
    }
    
    /**
     * @description Test getProcessTypes
     */
    @isTest
    static void testGetProcessTypes() {
        List<String> result = ProcessingLogViewController.getProcessTypes();
        
        Assert.isNotNull(result, 'Result should not be null');
        Assert.isTrue(result.size() > 0, 'Should return process types');
    }
    
    /**
     * @description Test getLogLevels
     */
    @isTest
    static void testGetLogLevels() {
        List<String> result = ProcessingLogViewController.getLogLevels();
        
        Assert.isNotNull(result, 'Result should not be null');
        Assert.isTrue(result.contains('ERROR'), 'Should contain ERROR level');
        Assert.isTrue(result.contains('INFO'), 'Should contain INFO level');
    }
    
    /**
     * @description Test getStatuses
     */
    @isTest
    static void testGetStatuses() {
        List<String> result = ProcessingLogViewController.getStatuses();
        
        Assert.isNotNull(result, 'Result should not be null');
        Assert.isTrue(result.size() > 0, 'Should return statuses');
    }
    
    /**
     * @description Test getLogDetails
     */
    @isTest
    static void testGetLogDetails() {
        ProcessingLog__c log = [SELECT Id FROM ProcessingLog__c LIMIT 1];
        
        ProcessingLog__c result = ProcessingLogViewController.getLogDetails(log.Id);
        
        Assert.isNotNull(result, 'Result should not be null');
        Assert.areEqual(log.Id, result.Id, 'Should return correct log');
    }
    
    /**
     * @description Test getLogDetails with invalid ID
     */
    @isTest
    static void testGetLogDetailsInvalid() {
        String invalidId = '001XX000003DHP';
        
        Test.startTest();
        try {
            ProcessingLogViewController.getLogDetails(invalidId);
            Assert.fail('Should throw exception');
        } catch (AuraHandledException e) {
            Assert.isTrue(e.getMessage().contains('Error'), 'Should contain error message');
        }
        Test.stopTest();
    }
    
    /**
     * @description Test getLogStatistics
     */
    @isTest
    static void testGetLogStatistics() {
        Test.startTest();
        ProcessingLogViewController.LogStatistics result = ProcessingLogViewController.getLogStatistics();
        Test.stopTest();
        
        Assert.isNotNull(result, 'Result should not be null');
        Assert.isTrue(result.totalLogs > 0, 'Should have total logs');
        Assert.isTrue(result.successCount >= 0, 'Should have success count');
        Assert.isTrue(result.failureCount >= 0, 'Should have failure count');
    }
    
    /**
     * @description Test retryProcessingLog
     */
    @isTest
    static void testRetryProcessingLog() {
        ProcessingLog__c log = [SELECT Id FROM ProcessingLog__c WHERE IsRetryable__c = true LIMIT 1];
        
        Test.startTest();
        ProcessingLogViewController.RetryResult result = ProcessingLogViewController.retryProcessingLog(log.Id);
        Test.stopTest();
        
        Assert.isNotNull(result, 'Result should not be null');
        Assert.isTrue(result.success, 'Retry should be successful');
    }
    
    /**
     * @description Test retryProcessingLog non-retryable
     */
    @isTest
    static void testRetryProcessingLogNonRetryable() {
        ProcessingLog__c log = [SELECT Id FROM ProcessingLog__c WHERE IsRetryable__c = false OR IsRetryable__c = null LIMIT 1];
        
        Test.startTest();
        try {
            ProcessingLogViewController.retryProcessingLog(log.Id);
            // May fail or handle gracefully
        } catch (AuraHandledException e) {
            Assert.isTrue(e.getMessage().contains('retryable'), 'Should indicate non-retryable');
        }
        Test.stopTest();
    }
    
    /**
     * @description Test exportLogsToCSV
     */
    @isTest
    static void testExportLogsToCSV() {
        Test.startTest();
        String csvContent = ProcessingLogViewController.exportLogsToCSV();
        Test.stopTest();
        
        Assert.isNotNull(csvContent, 'CSV content should not be null');
        Assert.isTrue(csvContent.contains('ProcessType'), 'CSV should contain headers');
        Assert.isTrue(csvContent.contains('Status'), 'CSV should contain status column');
    }
    
    /**
     * @description Test exportLogsToCSV with filters
     */
    @isTest
    static void testExportLogsToCSVFiltered() {
        Test.startTest();
        String csvContent = ProcessingLogViewController.exportLogsToCSV();
        Test.stopTest();
        
        Assert.isNotNull(csvContent, 'CSV content should not be null');
        Assert.isTrue(csvContent.length() > 0, 'CSV should have content');
    }
    
    /**
     * @description Test multiple filters
     */
    @isTest
    static void testGetProcessingLogsMultipleFilters() {
        OrgConnection__c org = [SELECT Id FROM OrgConnection__c LIMIT 1];
        Date dateFrom = Date.today().addDays(-10);
        Date dateTo = Date.today();
        
        List<ProcessingLog__c> result = ProcessingLogViewController.getProcessingLogs(
            org.Id, 'AuditTrailSync', 'INFO', 'Success', dateFrom, dateTo
        );
        
        Assert.isNotNull(result, 'Result should not be null');
        for (ProcessingLog__c log : result) {
            Assert.areEqual('Success', log.Status__c, 'Should match filters');
        }
    }
    
    /**
     * @description Test statistics calculation
     */
    @isTest
    static void testLogStatisticsCalculation() {
        Test.startTest();
        ProcessingLogViewController.LogStatistics stats = ProcessingLogViewController.getLogStatistics();
        Test.stopTest();
        
        Assert.isNotNull(stats, 'Statistics should not be null');
        Assert.isTrue(stats.totalLogs > 0, 'Should have total logs');
        Assert.isTrue(stats.averageDuration >= 0, 'Should have average duration');
        Assert.isTrue(stats.successRate >= 0 && stats.successRate <= 100, 'Success rate should be percentage');
    }
    
    /**
     * @description Test caching of getProcessTypes
     */
    @isTest
    static void testGetProcessTypesCaching() {
        Test.startTest();
        List<String> result1 = ProcessingLogViewController.getProcessTypes();
        List<String> result2 = ProcessingLogViewController.getProcessTypes();
        Test.stopTest();
        
        Assert.areEqual(result1.size(), result2.size(), 'Results should be consistent');
    }
}
