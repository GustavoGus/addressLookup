/**
 * @description Service that provides UK postcode/address lookup.
 * Calls external GET_ADDRESS_IO Named Credential for autocomplete and details.
 * Follows org rules: with sharing, no hardcoded org IDs, cacheable where appropriate.
 *
 * Prerequisites:
 * - Named Credential 'GET_ADDRESS_IO' configured to the API host (e.g. https://api.getaddress.io or your proxy),
 *   and with the API key stored securely (recommended as a custom header via Named Credential or parameter injection).
 * - If you choose to pass api-key as a query param, inject it from a protected custom setting/metadata, not hardcoded.
 */
public with sharing class AddressLookupService {

    public class ADDRESS_LOOKUP_EXCEPTION extends Exception {}

    public class Suggestion {
        public String address;
        public String url;
        public String id;
    }
    public class AutocompleteResponse {
        public List<Suggestion> suggestions;
    }

    public class AddressResponse {
        public String postcode;
        public Decimal latitude;
        public Decimal longitude;
        public List<String> formatted_address;
        public String thoroughfare;
        public String building_name;
        public String sub_building_name;
        public String sub_building_number;
        public String building_number;
        public String line_1;
        public String line_2;
        public String line_3;
        public String line_4;
        public String locality;
        public String town_or_city;
        public String county;
        public String district;
        public String country;
        public Boolean residential;
    }

    /**
     * @description Calls external autocomplete endpoint and returns payload passthrough.
     * @param query Free-text postcode or address fragment.
     * @return JSON string matching { "suggestions": [ { "address", "url", "id" }, ... ] }
     */
    @AuraEnabled(cacheable=true)
    public static String autocomplete(String query) {
        AutocompleteResponse res = new AutocompleteResponse();
        res.suggestions = new List<Suggestion>();

        if (String.isBlank(query) || query.trim().length() < 2) {
            return JSON.serialize(res);
        }

        try {
            HttpRequest req = new HttpRequest();
            req.setMethod('GET');

            // Prefer Named Credential-managed auth. Example for path structure:
            // Autocomplete path per user hint: /autocomplete/{query}?api-key={key}
            String endpointPath = '/autocomplete/' + query.trim();

            // If your Named Credential injects the api key as header, omit the query param.
            // Otherwise, append api-key param (not hardcoded in production).
            String apiKey = getApiKey(); // Secure retrieval; returns '' if not configured
            if (!String.isBlank(apiKey)) {
                endpointPath += '?api-key=' + EncodingUtil.urlEncode(apiKey, 'UTF-8');
            }

            System.debug(endpointPath);

            req.setEndpoint('callout:GET_ADDRESS_IO' + endpointPath);
            req.setTimeout(10000);

            Http http = new Http();
            HTTPResponse resp = http.send(req);

            if (resp.getStatusCode() >= 200 && resp.getStatusCode() < 300) {
                // Expecting provider to return JSON similar to the required structure
                return resp.getBody();
            }

            // On non-2xx, throw custom exception with technical but non-sensitive message
            throw new ADDRESS_LOOKUP_EXCEPTION('Address lookup autocomplete failed: upstream service returned a non-success status.');
        } catch (Exception e) {
            // Throw custom exception with a technical, non-sensitive message
            throw new ADDRESS_LOOKUP_EXCEPTION('Address lookup autocomplete failed: an unexpected error occurred while contacting the upstream service.');
        }
    }

    /**
     * @description Calls external details endpoint and returns payload passthrough.
     * @param id The suggestion id returned by autocomplete (or token required by provider).
     * @return JSON string matching the provided address shape.
     */
    @AuraEnabled(cacheable=false)
    public static String get(String id) {
        if (String.isBlank(id)) {
            return '{}';
        }

        try {
            HttpRequest req = new HttpRequest();
            req.setMethod('GET');

            // Depending on provider, this might be /get/{id} or a URL returned by autocomplete.suggestion.url
            // The prompt suggests ids like 'NDg5YmQ...' and example URLs beginning with '/get/'.
            // We'll honor the 'url' format if passed as id beginning with '/get/', else assume id path.
            String endpointPath;
            if (id.startsWith('/')) {
                endpointPath = id;
            } else {
                endpointPath = '/get/' + EncodingUtil.urlEncode(id, 'UTF-8');
            }

            // Append api-key if not injected by Named Credential
            String apiKey = getApiKey();
            if (!String.isBlank(apiKey)) {
                // Determine separator (already has query params?)
                String sep = endpointPath.contains('?') ? '&' : '?';
                endpointPath += sep + 'api-key=' + EncodingUtil.urlEncode(apiKey, 'UTF-8');
            }

            req.setEndpoint('callout:GET_ADDRESS_IO' + endpointPath);
            req.setTimeout(10000);

            Http http = new Http();
            HTTPResponse resp = http.send(req);

            if (resp.getStatusCode() >= 200 && resp.getStatusCode() < 300) {
                return resp.getBody();
            }

            // On non-2xx, throw custom exception with technical but non-sensitive message
            throw new ADDRESS_LOOKUP_EXCEPTION('Address lookup details retrieval failed: upstream service returned a non-success status.');
        } catch (Exception e) {
            // Throw custom exception with a technical, non-sensitive message
            throw new ADDRESS_LOOKUP_EXCEPTION('Address lookup details retrieval failed: an unexpected error occurred while contacting the upstream service.');
        }
    }

    // Secure API key retrieval using Custom Metadata getInstance by DeveloperName.
    // Throws ADDRESS_LOOKUP_EXCEPTION if the key is missing or record not found.
    @TestVisible private static String getApiKey() {
        Api_Keys__mdt rec;
        rec = Api_Keys__mdt.getInstance('GET_ADDRESS_IO');

        if (rec == null || String.isBlank(rec.Key__c)) {
            throw new ADDRESS_LOOKUP_EXCEPTION('Address lookup configuration error: API key is not configured.');
        }
        return rec.Key__c;
    }
}