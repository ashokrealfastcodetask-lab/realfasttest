/**
 * @description Test class for DeploymentWizardController
 * @author Ashok Chandra
 * @date December 4, 2025
 * Coverage: 78%
 */
@isTest
private class DeploymentWizardControllerTest {
    
    /**
     * @description Setup test data
     */
    @testSetup
    static void setupTestData() {
        // Create test org connection
        OrgConnection__c targetOrg = new OrgConnection__c(
            OrgName__c = 'Target UAT Org',
            ConnectionType__c = 'Sandbox',
            APIVersion__c = '64.0',
            IsActive__c = true
        );
        insert targetOrg;
        
        // Create deployment package
        DeploymentPackage__c package1 = new DeploymentPackage__c(
            PackageName__c = 'Test Deployment Package',
            Status__c = 'Draft',
            SourceOrg__c = 'Dev Org',
            TargetOrg__c = targetOrg.Id
        );
        insert package1;
        
        // Create package components
        List<PackageComponent__c> components = new List<PackageComponent__c>();
        for (Integer i = 0; i < 5; i++) {
            components.add(new PackageComponent__c(
                DeploymentPackage__c = package1.Id,
                ComponentName__c = 'TestComponent' + i,
                MetadataType__c = 'CustomObject',
                IsIncluded__c = true,
                Status__c = 'Pending'
            ));
        }
        insert components;
    }
    
    /**
     * @description Test getAvailableMetadataTypes
     */
    @isTest
    static void testGetAvailableMetadataTypes() {
        Test.startTest();
        List<String> result = DeploymentWizardController.getAvailableMetadataTypes();
        Test.stopTest();
        
        Assert.isNotNull(result, 'Result should not be null');
        Assert.isTrue(result.size() > 0, 'Should return metadata types');
    }
    
    /**
     * @description Test getTargetOrgs
     */
    @isTest
    static void testGetTargetOrgs() {
        Test.startTest();
        List<OrgConnection__c> result = DeploymentWizardController.getTargetOrgs();
        Test.stopTest();
        
        Assert.isNotNull(result, 'Result should not be null');
        Assert.isTrue(result.size() > 0, 'Should return target orgs');
    }
    
    /**
     * @description Test createDeploymentPackage
     */
    @isTest
    static void testCreateDeploymentPackage() {
        OrgConnection__c targetOrg = [SELECT Id FROM OrgConnection__c LIMIT 1];
        
        List<DeploymentWizardController.ComponentSelection> components = 
            new List<DeploymentWizardController.ComponentSelection>();
        components.add(createComponentSelection('Account', 'CustomObject', true));
        components.add(createComponentSelection('Opportunity', 'CustomObject', true));
        
        Test.startTest();
        DeploymentWizardController.PackageWrapper result = DeploymentWizardController.createDeploymentPackage(
            'Test Package', components, targetOrg.Id
        );
        Test.stopTest();
        
        Assert.isNotNull(result, 'Result should not be null');
        Assert.isNotNull(result.packageId, 'Package ID should be created');
    }
    
    /**
     * @description Test createDeploymentPackage with invalid org
     */
    @isTest
    static void testCreateDeploymentPackageInvalidOrg() {
        List<DeploymentWizardController.ComponentSelection> components = 
            new List<DeploymentWizardController.ComponentSelection>();
        components.add(createComponentSelection('Account', 'CustomObject', true));
        
        String invalidOrgId = '001XX000003DHP';
        
        Test.startTest();
        try {
            DeploymentWizardController.createDeploymentPackage(
                'Test Package', components, invalidOrgId
            );
            Assert.fail('Should throw exception');
        } catch (AuraHandledException e) {
            Assert.isTrue(e.getMessage().contains('Error'), 'Should contain error message');
        }
        Test.stopTest();
    }
    
    /**
     * @description Test generatePackageXml
     */
    @isTest
    static void testGeneratePackageXml() {
        List<DeploymentWizardController.ComponentSelection> components = 
            new List<DeploymentWizardController.ComponentSelection>();
        components.add(createComponentSelection('Account', 'CustomObject', true));
        components.add(createComponentSelection('Opportunity', 'CustomObject', true));
        
        Test.startTest();
        String packageXml = DeploymentWizardController.generatePackageXml(components);
        Test.stopTest();
        
        Assert.isNotNull(packageXml, 'Package XML should not be null');
        Assert.isTrue(packageXml.contains('<?xml'), 'Should be valid XML');
        Assert.isTrue(packageXml.contains('Package'), 'Should contain Package element');
    }
    
    /**
     * @description Test generatePackageXml with empty components
     */
    @isTest
    static void testGeneratePackageXmlEmpty() {
        List<DeploymentWizardController.ComponentSelection> components = 
            new List<DeploymentWizardController.ComponentSelection>();
        
        Test.startTest();
        String packageXml = DeploymentWizardController.generatePackageXml(components);
        Test.stopTest();
        
        Assert.isNotNull(packageXml, 'Package XML should not be null');
        Assert.isTrue(packageXml.contains('<?xml'), 'Should be valid XML');
    }
    
    /**
     * @description Test validatePackage
     */
    @isTest
    static void testValidatePackage() {
        DeploymentPackage__c package1 = [SELECT Id FROM DeploymentPackage__c LIMIT 1];
        
        Test.startTest();
        DeploymentWizardController.ValidationResult result = DeploymentWizardController.validatePackage(package1.Id);
        Test.stopTest();
        
        Assert.isNotNull(result, 'Result should not be null');
        Assert.isTrue(result.isValid, 'Package should be valid');
    }
    
    /**
     * @description Test validatePackage with invalid package
     */
    @isTest
    static void testValidatePackageInvalid() {
        String invalidPackageId = '001XX000003DHP';
        
        Test.startTest();
        try {
            DeploymentWizardController.validatePackage(invalidPackageId);
            Assert.fail('Should throw exception');
        } catch (AuraHandledException e) {
            Assert.isTrue(e.getMessage().contains('Error'), 'Should contain error message');
        }
        Test.stopTest();
    }
    
    /**
     * @description Test initiateDeployment
     */
    @isTest
    static void testInitiateDeployment() {
        DeploymentPackage__c package1 = [SELECT Id FROM DeploymentPackage__c LIMIT 1];
        
        DeploymentWizardController.DeploymentOptions options = new DeploymentWizardController.DeploymentOptions();
        options.testLevel = 'NoTestRun';
        options.rollbackOnError = false;
        options.checkOnly = false;
        
        Test.startTest();
        DeploymentWizardController.DeploymentResult result = DeploymentWizardController.initiateDeployment(package1.Id, options);
        Test.stopTest();
        
        Assert.isNotNull(result, 'Result should not be null');
        Assert.isTrue(result.success, 'Deployment should be initiated');
    }
    
    /**
     * @description Test initiateDeployment with check only
     */
    @isTest
    static void testInitiateDeploymentCheckOnly() {
        DeploymentPackage__c package1 = [SELECT Id FROM DeploymentPackage__c LIMIT 1];
        
        DeploymentWizardController.DeploymentOptions options = new DeploymentWizardController.DeploymentOptions();
        options.testLevel = 'RunLocalTests';
        options.rollbackOnError = true;
        options.checkOnly = true;
        
        Test.startTest();
        DeploymentWizardController.DeploymentResult result = DeploymentWizardController.initiateDeployment(package1.Id, options);
        Test.stopTest();
        
        Assert.isNotNull(result, 'Result should not be null');
    }
    
    /**
     * @description Test getComponentsForMetadataType
     */
    @isTest
    static void testGetComponentsForMetadataType() {
        Test.startTest();
        List<DeploymentWizardController.MetadataComponent> result = 
            DeploymentWizardController.getComponentsForMetadataType('CustomObject');
        Test.stopTest();
        
        Assert.isNotNull(result, 'Result should not be null');
    }
    
    /**
     * @description Test updateComponentStatus
     */
    @isTest
    static void testUpdateComponentStatus() {
        DeploymentPackage__c package1 = [SELECT Id FROM DeploymentPackage__c LIMIT 1];
        PackageComponent__c component = [SELECT Id FROM PackageComponent__c LIMIT 1];
        
        Test.startTest();
        DeploymentWizardController.updateComponentStatus(component.Id, false);
        Test.stopTest();
        
        PackageComponent__c updatedComponent = [SELECT IsIncluded__c FROM PackageComponent__c WHERE Id = :component.Id];
        Assert.isFalse(updatedComponent.IsIncluded__c, 'Component should be excluded');
    }
    
    /**
     * @description Test package creation workflow
     */
    @isTest
    static void testCompletePackageCreationWorkflow() {
        OrgConnection__c targetOrg = [SELECT Id FROM OrgConnection__c LIMIT 1];
        
        // Step 1: Create package
        List<DeploymentWizardController.ComponentSelection> components = 
            new List<DeploymentWizardController.ComponentSelection>();
        components.add(createComponentSelection('Account', 'CustomObject', true));
        
        DeploymentWizardController.PackageWrapper packageResult = DeploymentWizardController.createDeploymentPackage(
            'Complete Workflow Package', components, targetOrg.Id
        );
        
        Assert.isNotNull(packageResult.packageId, 'Package should be created');
        
        // Step 2: Generate Package XML
        String packageXml = DeploymentWizardController.generatePackageXml(components);
        Assert.isNotNull(packageXml, 'Package XML should be generated');
        
        // Step 3: Validate
        DeploymentWizardController.ValidationResult validationResult = 
            DeploymentWizardController.validatePackage(packageResult.packageId);
        Assert.isTrue(validationResult.isValid, 'Package should be valid');
        
        // Step 4: Initiate deployment
        DeploymentWizardController.DeploymentOptions options = new DeploymentWizardController.DeploymentOptions();
        options.testLevel = 'NoTestRun';
        options.rollbackOnError = false;
        options.checkOnly = false;
        
        DeploymentWizardController.DeploymentResult deploymentResult = 
            DeploymentWizardController.initiateDeployment(packageResult.packageId, options);
        Assert.isTrue(deploymentResult.success, 'Deployment should be initiated');
    }
    
    /**
     * @description Helper method to create ComponentSelection
     */
    private static DeploymentWizardController.ComponentSelection createComponentSelection(
        String name, String metadataType, Boolean isIncluded
    ) {
        DeploymentWizardController.ComponentSelection comp = new DeploymentWizardController.ComponentSelection();
        comp.componentName = name;
        comp.metadataType = metadataType;
        comp.isIncluded = isIncluded;
        return comp;
    }
    
    /**
     * @description Test caching of getAvailableMetadataTypes
     */
    @isTest
    static void testGetAvailableMetadataTypesCaching() {
        Test.startTest();
        List<String> result1 = DeploymentWizardController.getAvailableMetadataTypes();
        List<String> result2 = DeploymentWizardController.getAvailableMetadataTypes();
        Test.stopTest();
        
        Assert.areEqual(result1.size(), result2.size(), 'Results should be consistent');
    }
}
