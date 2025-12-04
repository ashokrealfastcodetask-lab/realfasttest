/**
 * @description Controller class for Deployment Wizard Lightning Web Component
 * Handles package creation, component selection, validation, and deployment initiation
 */
public with sharing class DeploymentWizardController {
    
    /**
     * @description Retrieves available metadata types for component selection
     * @return List of metadata type configurations
     */
    @AuraEnabled(cacheable=true)
    public static List<MetadataTypeConfig__mdt> getAvailableMetadataTypes() {
        try {
            MetadataTypeConfigSelector selector = MetadataTypeConfigSelector.getInstance();
            return selector.selectDeployable();
        } catch (Exception e) {
            throw new AuraHandledException('Error retrieving metadata types: ' + e.getMessage());
        }
    }
    
    /**
     * @description Retrieves org connections for deployment target selection
     * @return List of active org connections
     */
    @AuraEnabled(cacheable=true)
    public static List<OrgConnection__c> getTargetOrgs() {
        try {
            OrgConnectionSelector selector = new OrgConnectionSelector();
            return selector.selectActive();
        } catch (Exception e) {
            throw new AuraHandledException('Error retrieving target orgs: ' + e.getMessage());
        }
    }
    
    /**
     * @description Creates a new deployment package with selected components
     * @param packageName Name for the new package
     * @param description Package description
     * @param sourceOrgId Source org connection ID
     * @param targetOrgId Target org connection ID
     * @param selectedComponents List of metadata components to include
     * @return Package wrapper with ID and initial data
     */
    @AuraEnabled
    public static PackageWrapper createDeploymentPackage(
        String packageName,
        String description,
        String sourceOrgId,
        String targetOrgId,
        List<ComponentSelection> selectedComponents
    ) {
        try {
            if (String.isBlank(packageName) || selectedComponents.isEmpty()) {
                throw new IllegalArgumentException('Package name and components are required');
            }
            
            PackageWrapper result = new PackageWrapper();
            
            // Create deployment package
            DeploymentPackage__c deployPkg = new DeploymentPackage__c();
            deployPkg.Name = packageName;
            deployPkg.Description__c = description;
            deployPkg.SourceOrg__c = String.isNotBlank(sourceOrgId) ? sourceOrgId : null;
            deployPkg.TargetOrg__c = targetOrgId;
            deployPkg.Status__c = 'Draft';
            deployPkg.CreatedBy__c = UserInfo.getUserId();
            deployPkg.ComponentCount__c = selectedComponents.size();
            
            insert deployPkg;
            
            // Create package components
            List<PackageComponent__c> components = new List<PackageComponent__c>();
            Integer sequence = 1;
            
            for (ComponentSelection comp : selectedComponents) {
                PackageComponent__c pkgComp = new PackageComponent__c();
                pkgComp.DeploymentPackage__c = deployPkg.Id;
                pkgComp.MetadataType__c = comp.metadataType;
                pkgComp.ComponentName__c = comp.componentName;
                pkgComp.DisplayName__c = comp.displayName;
                pkgComp.DeploymentSequence__c = sequence;
                pkgComp.DeploymentStatus__c = 'Pending';
                pkgComp.IsIncluded__c = true;
                
                components.add(pkgComp);
                sequence++;
            }
            
            insert components;
            
            result.packageId = deployPkg.Id;
            result.packageName = deployPkg.Name;
            result.componentCount = components.size();
            result.status = deployPkg.Status__c;
            result.success = true;
            result.message = 'Deployment package created successfully';
            
            return result;
        } catch (Exception e) {
            throw new AuraHandledException('Error creating deployment package: ' + e.getMessage());
        }
    }
    
    /**
     * @description Generates package.xml for the deployment package
     * @param packageId ID of the deployment package
     * @return Generated package XML content
     */
    @AuraEnabled
    public static String generatePackageXml(String packageId) {
        try {
            if (String.isBlank(packageId)) {
                throw new IllegalArgumentException('Package ID is required');
            }
            
            // Get package components
            List<PackageComponent__c> components = [
                SELECT MetadataType__c, ComponentName__c, IsIncluded__c
                FROM PackageComponent__c
                WHERE DeploymentPackage__c = :packageId AND IsIncluded__c = true
                ORDER BY DeploymentSequence__c
            ];
            
            if (components.isEmpty()) {
                throw new IllegalArgumentException('No components selected for deployment');
            }
            
            // Build package XML
            PackageXmlBuilder builder = new PackageXmlBuilder(64.0);
            
            // Group components by metadata type
            Map<String, List<String>> componentsByType = new Map<String, List<String>>();
            
            for (PackageComponent__c comp : components) {
                if (!componentsByType.containsKey(comp.MetadataType__c)) {
                    componentsByType.put(comp.MetadataType__c, new List<String>());
                }
                componentsByType.get(comp.MetadataType__c).add(comp.ComponentName__c);
            }
            
            // Add members to builder
            for (String metadataType : componentsByType.keySet()) {
                builder.addMembers(metadataType, new Set<String>(componentsByType.get(metadataType)));
            }
            
            return builder.build();
        } catch (Exception e) {
            throw new AuraHandledException('Error generating package XML: ' + e.getMessage());
        }
    }
    
    /**
     * @description Validates deployment package before deployment
     * @param packageId ID of the deployment package
     * @return Validation result with issues if any
     */
    @AuraEnabled
    public static ValidationResult validatePackage(String packageId) {
        try {
            ValidationResult result = new ValidationResult();
            
            DeploymentPackage__c pkg = [
                SELECT Id, Name, Status__c, ComponentCount__c, TargetOrg__c
                FROM DeploymentPackage__c
                WHERE Id = :packageId
                LIMIT 1
            ];
            
            List<String> issues = new List<String>();
            
            // Validation checks
            if (pkg.ComponentCount__c == 0) {
                issues.add('Package contains no components');
            }
            
            if (String.isBlank(pkg.TargetOrg__c)) {
                issues.add('Target org must be specified');
            }
            
            List<PackageComponent__c> components = [
                SELECT Id, ComponentName__c
                FROM PackageComponent__c
                WHERE DeploymentPackage__c = :packageId AND IsIncluded__c = false
            ];
            
            if (components.size() > 0) {
                issues.add('Some components are marked as excluded');
            }
            
            result.isValid = issues.isEmpty();
            result.issues = issues;
            result.message = result.isValid 
                ? 'Package is valid for deployment' 
                : 'Package validation failed with ' + issues.size() + ' issues';
            
            return result;
        } catch (Exception e) {
            throw new AuraHandledException('Error validating package: ' + e.getMessage());
        }
    }
    
    /**
     * @description Initiates deployment of the package
     * @param packageId ID of the deployment package
     * @param deploymentOptions Options for deployment (async, testLevel, etc)
     * @return Deployment initiation result
     */
    @AuraEnabled
    public static DeploymentResult initiateDeployment(String packageId, DeploymentOptions options) {
        try {
            if (String.isBlank(packageId)) {
                throw new IllegalArgumentException('Package ID is required');
            }
            
            DeploymentResult result = new DeploymentResult();
            
            // Get package details
            DeploymentPackage__c pkg = [
                SELECT Id, Name, Status__c, TargetOrg__c, PackageXML__c
                FROM DeploymentPackage__c
                WHERE Id = :packageId
                LIMIT 1
            ];
            
            // Create deployment history record
            DeploymentHistory__c history = new DeploymentHistory__c();
            history.Name = 'Deployment - ' + pkg.Name;
            history.DeploymentPackage__c = packageId;
            history.SourceOrg__c = null; // Would be populated with actual source
            history.TargetOrg__c = pkg.TargetOrg__c;
            history.DeploymentStatus__c = 'Queued';
            history.RequestedBy__c = UserInfo.getUserId();
            history.DeploymentOptions__c = String.isNotEmpty(options.testLevel) 
                ? options.testLevel 
                : 'NoTestRun';
            history.RunTests__c = options.runTests != null ? options.runTests : false;
            
            insert history;
            
            // Update package status
            pkg.Status__c = 'Deployed';
            update pkg;
            
            result.deploymentId = history.Id;
            result.success = true;
            result.message = 'Deployment initiated successfully. Deployment ID: ' + history.Id;
            result.status = 'Queued';
            
            return result;
        } catch (Exception e) {
            throw new AuraHandledException('Error initiating deployment: ' + e.getMessage());
        }
    }
    
    /**
     * @description Retrieves components available from a specific metadata type
     * @param metadataType The metadata type to retrieve components for
     * @param orgConnectionId Optional org connection to retrieve from
     * @return List of available components
     */
    @AuraEnabled(cacheable=false)
    public static List<MetadataComponent> getComponentsForMetadataType(
        String metadataType,
        String orgConnectionId
    ) {
        try {
            List<MetadataComponent> components = new List<MetadataComponent>();
            
            // In a real implementation, this would call the Metadata API
            // For now, return empty list - this would be implemented with callouts
            
            return components;
        } catch (Exception e) {
            throw new AuraHandledException('Error retrieving components: ' + e.getMessage());
        }
    }
    
    /**
     * @description Updates component inclusion status in a package
     * @param componentId ID of the package component
     * @param isIncluded Whether to include the component in deployment
     * @return Update result
     */
    @AuraEnabled
    public static String updateComponentStatus(String componentId, Boolean isIncluded) {
        try {
            PackageComponent__c comp = new PackageComponent__c();
            comp.Id = componentId;
            comp.IsIncluded__c = isIncluded;
            
            update comp;
            
            return 'Component status updated successfully';
        } catch (Exception e) {
            throw new AuraHandledException('Error updating component status: ' + e.getMessage());
        }
    }
    
    // ==================== Inner Classes ====================
    
    /**
     * @description Wrapper for component selection data
     */
    public class ComponentSelection {
        @AuraEnabled public String metadataType {get; set;}
        @AuraEnabled public String componentName {get; set;}
        @AuraEnabled public String displayName {get; set;}
    }
    
    /**
     * @description Wrapper for deployment package response
     */
    public class PackageWrapper {
        @AuraEnabled public String packageId {get; set;}
        @AuraEnabled public String packageName {get; set;}
        @AuraEnabled public Integer componentCount {get; set;}
        @AuraEnabled public String status {get; set;}
        @AuraEnabled public Boolean success {get; set;}
        @AuraEnabled public String message {get; set;}
    }
    
    /**
     * @description Wrapper for package validation response
     */
    public class ValidationResult {
        @AuraEnabled public Boolean isValid {get; set;}
        @AuraEnabled public List<String> issues {get; set;}
        @AuraEnabled public String message {get; set;}
    }
    
    /**
     * @description Wrapper for deployment options
     */
    public class DeploymentOptions {
        @AuraEnabled public String testLevel {get; set;}
        @AuraEnabled public Boolean runTests {get; set;}
        @AuraEnabled public Boolean rollbackOnError {get; set;}
        @AuraEnabled public Boolean checkOnly {get; set;}
        @AuraEnabled public Boolean ignoreWarnings {get; set;}
    }
    
    /**
     * @description Wrapper for deployment initiation result
     */
    public class DeploymentResult {
        @AuraEnabled public String deploymentId {get; set;}
        @AuraEnabled public Boolean success {get; set;}
        @AuraEnabled public String message {get; set;}
        @AuraEnabled public String status {get; set;}
    }
    
    /**
     * @description Wrapper for metadata component
     */
    public class MetadataComponent {
        @AuraEnabled public String id {get; set;}
        @AuraEnabled public String name {get; set;}
        @AuraEnabled public String type {get; set;}
        @AuraEnabled public String status {get; set;}
    }
}
