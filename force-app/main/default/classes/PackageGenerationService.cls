/**
 * @description Service for generating package.xml files
 * Handles the business logic for package creation and management
 */
public class PackageGenerationService {
    
    private static PackageGenerationService instance;
    
    public static PackageGenerationService getInstance() {
        if (instance == null) {
            instance = new PackageGenerationService();
        }
        return instance;
    }
    
    /**
     * @description Generate package.xml from audit trail records
     */
    public DeploymentPackage__c generatePackage(PackageGenerationRequest request) {
        // Validate request
        validateRequest(request);
        
        // Fetch audit trails based on criteria
        SetupAuditTrailSelector selector = new SetupAuditTrailSelector();
        List<SetupAuditTrail__c> auditTrails = selector.selectByDateRange(
            request.startDate,
            request.endDate,
            request.orgConnectionId
        );
        
        // Group components by metadata type
        Map<String, Set<String>> componentsByType = groupComponentsByType(auditTrails);
        
        // Generate package.xml content
        String packageXml = buildPackageXml(componentsByType, request.apiVersion);
        
        // Create deployment package record
        DeploymentPackage__c pkg = new DeploymentPackage__c(
            PackageName__c = request.packageName,
            Version__c = generateVersion(request.packageName),
            APIVersion__c = request.apiVersion,
            SourceOrg__c = request.orgConnectionId,
            PackageXML__c = packageXml,
            Status__c = 'Draft',
            ComponentCount__c = countComponents(componentsByType)
        );
        
        insert pkg;
        
        // Create component line items
        createPackageComponents(pkg.Id, componentsByType);
        
        return pkg;
    }
    
    /**
     * @description Generate rollback package from deployment history
     */
    public DeploymentPackage__c generateRollbackPackage(Id deploymentPackageId) {
        DeploymentPackageSelector selector = new DeploymentPackageSelector();
        List<DeploymentPackage__c> packages = selector.selectById(new Set<Id>{deploymentPackageId});
        
        if (packages.isEmpty()) {
            throw new PackageGenerationException('Deployment package not found');
        }
        
        DeploymentPackage__c originalPackage = packages[0];
        
        // Create destructive changes package
        DeploymentPackage__c rollbackPkg = new DeploymentPackage__c(
            PackageName__c = originalPackage.PackageName__c + '_Rollback',
            Version__c = originalPackage.Version__c + '.rollback',
            APIVersion__c = originalPackage.APIVersion__c,
            SourceOrg__c = originalPackage.SourceOrg__c,
            Status__c = 'Draft',
            IsRollback__c = true,
            ParentPackage__c = deploymentPackageId
        );
        
        // Generate destructiveChanges.xml
        rollbackPkg.PackageXML__c = generateDestructiveChanges(originalPackage);
        
        insert rollbackPkg;
        
        return rollbackPkg;
    }
    
    // Private helper methods
    
    private void validateRequest(PackageGenerationRequest request) {
        if (String.isBlank(request.packageName)) {
            throw new PackageGenerationException('Package name is required');
        }
        if (request.startDate == null || request.endDate == null) {
            throw new PackageGenerationException('Date range is required');
        }
        if (request.startDate > request.endDate) {
            throw new PackageGenerationException('Start date must be before end date');
        }
    }
    
    private Map<String, Set<String>> groupComponentsByType(List<SetupAuditTrail__c> auditTrails) {
        Map<String, Set<String>> componentsByType = new Map<String, Set<String>>();
        
        for (SetupAuditTrail__c trail : auditTrails) {
            if (String.isNotBlank(trail.MetadataType__c) && String.isNotBlank(trail.ComponentName__c)) {
                if (!componentsByType.containsKey(trail.MetadataType__c)) {
                    componentsByType.put(trail.MetadataType__c, new Set<String>());
                }
                componentsByType.get(trail.MetadataType__c).add(trail.ComponentName__c);
            }
        }
        
        return componentsByType;
    }
    
    private String buildPackageXml(Map<String, Set<String>> componentsByType, Decimal apiVersion) {
        PackageXmlBuilder builder = new PackageXmlBuilder(apiVersion);
        
        for (String metadataType : componentsByType.keySet()) {
            for (String componentName : componentsByType.get(metadataType)) {
                builder.addMember(metadataType, componentName);
            }
        }
        
        return builder.build();
    }
    
    private String generateVersion(String packageName) {
        DeploymentPackageSelector selector = new DeploymentPackageSelector();
        List<DeploymentPackage__c> latestPackages = selector.selectLatestVersions(packageName, 1);
        
        if (latestPackages.isEmpty()) {
            return '1.0';
        }
        
        String latestVersion = latestPackages[0].Version__c;
        List<String> versionParts = latestVersion.split('\\.');
        
        if (versionParts.size() >= 2) {
            Integer minor = Integer.valueOf(versionParts[1]) + 1;
            return versionParts[0] + '.' + minor;
        }
        
        return '1.0';
    }
    
    private Integer countComponents(Map<String, Set<String>> componentsByType) {
        Integer count = 0;
        for (Set<String> components : componentsByType.values()) {
            count += components.size();
        }
        return count;
    }
    
    private void createPackageComponents(Id packageId, Map<String, Set<String>> componentsByType) {
        List<PackageComponent__c> components = new List<PackageComponent__c>();
        
        for (String metadataType : componentsByType.keySet()) {
            for (String componentName : componentsByType.get(metadataType)) {
                components.add(new PackageComponent__c(
                    DeploymentPackage__c = packageId,
                    MetadataType__c = metadataType,
                    ComponentName__c = componentName,
                    IsIncluded__c = true
                ));
            }
        }
        
        if (!components.isEmpty()) {
            insert components;
        }
    }
    
    private String generateDestructiveChanges(DeploymentPackage__c originalPackage) {
        // Parse original package XML and create destructiveChanges.xml
        // This would contain the same components but for deletion
        return '<?xml version="1.0" encoding="UTF-8"?>\n' +
               '<Package xmlns="http://soap.sforce.com/2006/04/metadata">\n' +
               '    <version>' + originalPackage.APIVersion__c + '</version>\n' +
               '</Package>';
    }
    
    // Inner classes
    
    public class PackageGenerationRequest {
        public String packageName;
        public DateTime startDate;
        public DateTime endDate;
        public Id orgConnectionId;
        public Decimal apiVersion;
        public Set<String> includedTypes;
        public Set<String> excludedTypes;
        
        public PackageGenerationRequest() {
            this.apiVersion = 60.0;
            this.includedTypes = new Set<String>();
            this.excludedTypes = new Set<String>();
        }
    }
    
    public class PackageGenerationException extends Exception {}
}
