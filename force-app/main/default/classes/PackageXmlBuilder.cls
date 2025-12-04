/**
 * @description Utility class to build package.xml content
 */
public class PackageXmlBuilder {
    
    private Map<String, Set<String>> typeMembers;
    private Decimal apiVersion;
    
    /**
     * @description Constructor that initializes the builder with API version
     */
    public PackageXmlBuilder(Decimal apiVersion) {
        this.apiVersion = apiVersion;
        this.typeMembers = new Map<String, Set<String>>();
    }
    
    /**
     * @description Add a single member to the package
     */
    public PackageXmlBuilder addMember(String metadataType, String memberName) {
        if (!typeMembers.containsKey(metadataType)) {
            typeMembers.put(metadataType, new Set<String>());
        }
        typeMembers.get(metadataType).add(memberName);
        return this;
    }
    
    /**
     * @description Add multiple members for a metadata type
     */
    public PackageXmlBuilder addMembers(String metadataType, Set<String> memberNames) {
        for (String memberName : memberNames) {
            addMember(metadataType, memberName);
        }
        return this;
    }
    
    /**
     * @description Build and return the complete package.xml as string
     */
    public String build() {
        List<String> xmlLines = new List<String>();
        
        xmlLines.add('<?xml version="1.0" encoding="UTF-8"?>');
        xmlLines.add('<Package xmlns="http://soap.sforce.com/2006/04/metadata">');
        
        List<String> sortedTypes = new List<String>(typeMembers.keySet());
        sortedTypes.sort();
        
        for (String metadataType : sortedTypes) {
            List<String> sortedMembers = new List<String>(typeMembers.get(metadataType));
            sortedMembers.sort();
            
            xmlLines.add('    <types>');
            for (String member : sortedMembers) {
                xmlLines.add('        <members>' + escapeXml(member) + '</members>');
            }
            xmlLines.add('        <name>' + metadataType + '</name>');
            xmlLines.add('    </types>');
        }
        
        xmlLines.add('    <version>' + apiVersion.format() + '</version>');
        xmlLines.add('</Package>');
        
        return String.join(xmlLines, '\n');
    }
    
    private String escapeXml(String value) {
        return value.replaceAll('&', '&amp;')
                    .replaceAll('<', '&lt;')
                    .replaceAll('>', '&gt;')
                    .replaceAll('"', '&quot;')
                    .replaceAll('\'', '&apos;');
    }
}