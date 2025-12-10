/**
 * @description Base selector class for SOQL queries. Provides a common query builder
 * and abstract methods for SObject type, field list, and optional ORDER BY.
 *
 * Usage:
 *  - Extend this class and implement getSObjectType(), getSObjectFieldList(), and optionally getOrderBy()
 *  - Call buildQueryString(alias, whereClause) to generate a SOQL query string
 *
 * Notes:
 *  - Child classes should only pass safe, pre-escaped values into whereClause
 *  - Use String.escapeSingleQuotes on dynamic string values
 */
public abstract class ApplicationSelector {

    /**
     * @description Return the SObject type for the selector (e.g., Account.SObjectType)
     */
    public abstract Schema.SObjectType getSObjectType();

    /**
     * @description Return the list of fields to select
     */
    public abstract List<Schema.SObjectField> getSObjectFieldList();

    /**
     * @description Return an ORDER BY clause (without the keyword) or null/empty for none
     */
    public virtual String getOrderBy() {
        return null;
    }

    /**
     * @description Builds a SOQL query string using the provided alias and where clause.
     * @param alias Optional SOQL alias for the object (e.g., 'dp'); pass null for none
     * @param whereClause Optional WHERE clause without the keyword (e.g., "Status__c = 'Ready'")
     * @return A complete SOQL query string
     */
    protected String buildQueryString(String alias, String whereClause) {
        // Resolve API name for SObject type
        String sobjectName = String.valueOf(getSObjectType());

        // Build SELECT fields
        List<String> fieldApiNames = new List<String>();
        for (Schema.SObjectField f : getSObjectFieldList()) {
            fieldApiNames.add(f.getDescribe().getName());
        }

        String aliasPrefix = String.isNotBlank(alias) ? alias + '.' : '';
        List<String> selectFields = new List<String>();
        for (String fieldName : fieldApiNames) {
            selectFields.add(aliasPrefix + fieldName);
        }
        String selectClause = 'SELECT ' + String.join(selectFields, ', ');

        String fromClause = ' FROM ' + sobjectName;
        if (String.isNotBlank(alias)) {
            fromClause += ' ' + alias;
        }

        String query = selectClause + fromClause;

        if (String.isNotBlank(whereClause)) {
            // Allow callers to pass either full "WHERE ..." or just the expression; normalize here
            String normalized = whereClause.trim();
            if (!normalized.toUpperCase().startsWith('WHERE ')) {
                query += ' WHERE ' + normalized;
            } else {
                query += ' ' + normalized;
            }
        }

        String orderBy = getOrderBy();
        if (String.isNotBlank(orderBy)) {
            // Do not duplicate ORDER BY if caller appended one manually
            String upper = orderBy.trim().toUpperCase();
            if (!upper.startsWith('ORDER BY')) {
                query += ' ORDER BY ' + orderBy;
            } else {
                query += ' ' + orderBy;
            }
        }

        return query;
    }
}
