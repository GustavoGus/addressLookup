/**
 * @description Aura/LWC facade for AddressLookupService to isolate UI from service signature changes.
 * Follows security guidelines: with sharing, user mode operations, no hardcoded IDs.
 * Returns JSON strings to align with provided payloads.
 * 
 * Note: Errors from underlying services are caught here and wrapped with user-friendly messages.
 * TODO: We will build a Debug_Log__c object to store the errors for debugging purposes.
 */
public with sharing class AddressLookupAura {
    public class AutoCompleteRequest {
        @AuraEnabled public String query;
    }
    public class GetRequest {
        @AuraEnabled public String id;
    }

    /**
     * @description Calls AddressLookupService.autocomplete(query) and returns JSON string.
     * If AddressLookupService already returns a typed object, we serialize it.
     */
    @AuraEnabled(cacheable=true)
    public static String autocomplete(String query) {
            System.debug(query);
        if (String.isBlank(query)) {
            return '{"suggestions": []}';
        }
        try {
            // Delegates to the mandated backend class. Adjust signature if it returns non-JSON types.
            Object res = AddressLookupService.autocomplete(query);
            return ensureJson(res, 'autocomplete');
        } catch (AddressLookupService.ADDRESS_LOOKUP_EXCEPTION e) {
            return handleError(e, 'autocomplete');
        } catch (Exception e) {
            return handleError(e, 'autocomplete');
        }
    }

    /**
     * @description Calls AddressLookupService.get(id) and returns JSON string.
     */
    @AuraEnabled(cacheable=true)
    public static String get(String id) {
        if (String.isBlank(id)) {
            throw new AuraHandledException('Invalid address id.');
        }
        try {
            Object res = AddressLookupService.get(id);
            return ensureJson(res, 'get');
        } catch (AddressLookupService.ADDRESS_LOOKUP_EXCEPTION e) {
            return handleError(e, 'get');
        } catch (Exception e) {
            return handleError(e, 'get');
        }
    }

    /**
     * @description Centralized error handler for AddressLookupService exceptions.
     * Returns user-friendly JSON message and logs technical details (TODO: to Debug_Log__c).
     * @param e The exception caught from service layer
     * @param operation The operation that failed (autocomplete/get)
     * @return JSON string with error message
     */
    private static String handleError(Exception e, String operation) {
        // TODO: We will build a Debug_Log__c object to store the errors for debugging purposes.
        // For now, we return a user-friendly message
        if (operation == 'autocomplete') {
            return '{"suggestions": [], "error": "We are unable to complete the address search at this time."}';
        } else {
            return '{"error": "We are unable to retrieve the address details at this time."}';
        }
    }

    // Helpers

    private static String ensureJson(Object res, String op) {
        if (res == null) {
            return op == 'autocomplete' ? '{"suggestions": []}' : '{}';
        }
        if (res instanceof String) {
            // Assume backend returned JSON
            return (String)res;
        }
        // If backend returned a map/typed object, serialize to JSON
        return JSON.serialize(res);
    }
}