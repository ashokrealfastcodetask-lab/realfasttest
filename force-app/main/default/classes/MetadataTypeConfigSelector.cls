/**
 * @description Selector for MetadataTypeConfig__mdt custom metadata
 * Handles all queries for metadata type configuration records
 */
public class MetadataTypeConfigSelector {
    
    private static MetadataTypeConfigSelector instance;
    
    /**
     * @description Private constructor for singleton pattern
     */
    private MetadataTypeConfigSelector() {
    }
    
    /**
     * @description Get singleton instance of MetadataTypeConfigSelector
     * @return MetadataTypeConfigSelector instance
     */
    public static MetadataTypeConfigSelector getInstance() {
        if (instance == null) {
            instance = new MetadataTypeConfigSelector();
        }
        return instance;
    }
    
    /**
     * @description Select all active metadata type configurations
     * @return List of active MetadataTypeConfig__mdt records
     */
    public List<MetadataTypeConfig__mdt> selectAll() {
        return [
            SELECT 
                Id,
                DeveloperName,
                MasterLabel,
                MetadataType__c,
                SectionPattern__c,
                ExtractionPattern__c,
                DirectoryName__c,
                Suffix__c,
                IsActive__c,
                IsRetrievable__c,
                IsDeployable__c,
                ProcessingPriority__c,
                Description__c
            FROM MetadataTypeConfig__mdt
            WHERE IsActive__c = true
            ORDER BY ProcessingPriority__c ASC
        ];
    }
    
    /**
     * @description Select metadata type config by metadata type name
     * @param metadataType The metadata type name to search for
     * @return MetadataTypeConfig__mdt record or null if not found
     */
    public MetadataTypeConfig__mdt selectByMetadataType(String metadataType) {
        List<MetadataTypeConfig__mdt> configs = [
            SELECT 
                Id,
                DeveloperName,
                MasterLabel,
                MetadataType__c,
                SectionPattern__c,
                ExtractionPattern__c,
                DirectoryName__c,
                Suffix__c,
                IsActive__c,
                IsRetrievable__c,
                IsDeployable__c,
                ProcessingPriority__c,
                Description__c
            FROM MetadataTypeConfig__mdt
            WHERE MetadataType__c = :metadataType 
            AND IsActive__c = true
            LIMIT 1
        ];
        
        return configs.isEmpty() ? null : configs[0];
    }
    
    /**
     * @description Select metadata type configs by section pattern
     * @param section The section pattern to search for
     * @return List of MetadataTypeConfig__mdt records
     */
    public List<MetadataTypeConfig__mdt> selectBySection(String section) {
        return [
            SELECT 
                Id,
                DeveloperName,
                MasterLabel,
                MetadataType__c,
                SectionPattern__c,
                ExtractionPattern__c,
                DirectoryName__c,
                Suffix__c,
                IsActive__c,
                IsRetrievable__c,
                IsDeployable__c,
                ProcessingPriority__c,
                Description__c
            FROM MetadataTypeConfig__mdt
            WHERE SectionPattern__c = :section 
            AND IsActive__c = true
            LIMIT 1
        ];
    }
    
    /**
     * @description Get all retrievable metadata type configs
     * @return List of retrievable MetadataTypeConfig__mdt records
     */
    public List<MetadataTypeConfig__mdt> selectRetrievable() {
        return [
            SELECT 
                Id,
                DeveloperName,
                MasterLabel,
                MetadataType__c,
                SectionPattern__c,
                ExtractionPattern__c,
                DirectoryName__c,
                Suffix__c,
                IsActive__c,
                IsRetrievable__c,
                IsDeployable__c,
                ProcessingPriority__c,
                Description__c
            FROM MetadataTypeConfig__mdt
            WHERE IsActive__c = true 
            AND IsRetrievable__c = true
            ORDER BY ProcessingPriority__c ASC
        ];
    }
    
    /**
     * @description Get all deployable metadata type configs
     * @return List of deployable MetadataTypeConfig__mdt records
     */
    public List<MetadataTypeConfig__mdt> selectDeployable() {
        return [
            SELECT 
                Id,
                DeveloperName,
                MasterLabel,
                MetadataType__c,
                SectionPattern__c,
                ExtractionPattern__c,
                DirectoryName__c,
                Suffix__c,
                IsActive__c,
                IsRetrievable__c,
                IsDeployable__c,
                ProcessingPriority__c,
                Description__c
            FROM MetadataTypeConfig__mdt
            WHERE IsActive__c = true 
            AND IsDeployable__c = true
            ORDER BY ProcessingPriority__c ASC
        ];
    }
}
