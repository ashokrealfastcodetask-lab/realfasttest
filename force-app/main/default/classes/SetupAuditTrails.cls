/**
 * @description Domain class for SetupAuditTrail__c
 * Contains business logic for audit trail processing
 */
public class SetupAuditTrails {
    
    private List<SetupAuditTrail__c> records;
    
    public SetupAuditTrails(List<SetupAuditTrail__c> records) {
        this.records = records;
    }
    
    /**
     * @description Parse and extract metadata information from audit trails
     */
    public void extractMetadataComponents() {
        List<MetadataTypeConfig__mdt> configs = MetadataTypeConfigSelector.getInstance().selectAll();
        Map<String, MetadataTypeConfig__mdt> configMap = buildConfigMap(configs);
        
        for (SetupAuditTrail__c trail : records) {
            if (String.isBlank(trail.Section__c)) {
                continue;
            }
            
            MetadataTypeConfig__mdt config = findMatchingConfig(trail.Section__c, configMap);
            
            if (config != null) {
                trail.MetadataType__c = config.MetadataType__c;
                trail.ComponentName__c = extractComponentName(trail.Display__c, config);
            }
        }
    }
    
    /**
     * @description Mark records as processed
     */
    public void markAsProcessed() {
        for (SetupAuditTrail__c trail : records) {
            trail.IsProcessed__c = true;
            trail.ProcessedDate__c = System.now();
        }
    }
    
    /**
     * @description Validate audit trail records before processing
     */
    public void validate() {
        for (SetupAuditTrail__c trail : records) {
            if (String.isBlank(trail.Action__c)) {
                trail.addError('Action is required');
            }
            if (trail.OrgConnection__c == null) {
                trail.addError('Org Connection is required');
            }
        }
    }
    
    // Private helper methods
    
    private Map<String, MetadataTypeConfig__mdt> buildConfigMap(List<MetadataTypeConfig__mdt> configs) {
        Map<String, MetadataTypeConfig__mdt> configMap = new Map<String, MetadataTypeConfig__mdt>();
        for (MetadataTypeConfig__mdt config : configs) {
            configMap.put(config.SectionPattern__c.toLowerCase(), config);
        }
        return configMap;
    }
    
    private MetadataTypeConfig__mdt findMatchingConfig(String section, Map<String, MetadataTypeConfig__mdt> configMap) {
        String sectionLower = section.toLowerCase();
        
        for (String pattern : configMap.keySet()) {
            if (sectionLower.contains(pattern)) {
                return configMap.get(pattern);
            }
        }
        
        return null;
    }
    
    private String extractComponentName(String display, MetadataTypeConfig__mdt config) {
        if (String.isBlank(display) || config == null) {
            return null;
        }
        
        // Use regex pattern from config to extract component name
        if (String.isNotBlank(config.ExtractionPattern__c)) {
            Pattern p = Pattern.compile(config.ExtractionPattern__c);
            Matcher m = p.matcher(display);
            if (m.find() && m.groupCount() > 0) {
                return m.group(1);
            }
        }
        
        return display;
    }
}
