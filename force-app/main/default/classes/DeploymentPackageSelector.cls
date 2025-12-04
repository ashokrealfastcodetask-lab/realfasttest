/**
 * @description Selector for DeploymentPackage__c object
 */
public class DeploymentPackageSelector extends ApplicationSelector {
    
    public override Schema.SObjectType getSObjectType() {
        return DeploymentPackage__c.SObjectType;
    }
    
    public override List<Schema.SObjectField> getSObjectFieldList() {
        return new List<Schema.SObjectField> {
            DeploymentPackage__c.Id,
            DeploymentPackage__c.Name,
            DeploymentPackage__c.PackageName__c,
            DeploymentPackage__c.Version__c,
            DeploymentPackage__c.APIVersion__c,
            DeploymentPackage__c.SourceOrg__c,
            DeploymentPackage__c.TargetOrg__c,
            DeploymentPackage__c.PackageXML__c,
            DeploymentPackage__c.Status__c,
            DeploymentPackage__c.ComponentCount__c,
            DeploymentPackage__c.IsTemplate__c,
            DeploymentPackage__c.CreatedDate
        };
    }
    
    public override String getOrderBy() {
        return 'Version__c DESC, CreatedDate DESC';
    }
    
    /**
     * @description Select packages by status
     */
    public List<DeploymentPackage__c> selectByStatus(String status, Integer limitRows) {
        String whereClause = 'Status__c = :status';
        String query = buildQueryString(null, whereClause);
        
        if (limitRows != null && limitRows > 0) {
            query += ' LIMIT ' + limitRows;
        }
        
        return Database.query(query);
    }
    
    /**
     * @description Select latest package versions
     */
    public List<DeploymentPackage__c> selectLatestVersions(String packageName, Integer limitRows) {
        String whereClause = 'PackageName__c = :packageName';
        String query = buildQueryString(null, whereClause);
        
        if (limitRows != null && limitRows > 0) {
            query += ' LIMIT ' + limitRows;
        }
        
        return Database.query(query);
    }
    
    /**
     * @description Select package templates for reuse
     */
    public List<DeploymentPackage__c> selectTemplates() {
        String whereClause = 'IsTemplate__c = true';
        return Database.query(buildQueryString(null, whereClause));
    }
}
