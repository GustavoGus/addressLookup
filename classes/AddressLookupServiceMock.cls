/**
 * @description Mock implementation of AddressLookupService for unit testing.
 * This class implements the same interface as AddressLookupService but returns
 * predefined test data instead of making external API calls.
 */
public with sharing class AddressLookupServiceMock {
    
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
     * @description Mock implementation of autocomplete method that returns test data
     * instead of making external API calls.
     * @param query Free-text postcode or address fragment.
     * @return JSON string matching { "suggestions": [ { "address", "url", "id" }, ... ] }
     */
    @TestVisible
    public static String autocomplete(String query) {
        AutocompleteResponse res = new AutocompleteResponse();
        res.suggestions = new List<Suggestion>();
        
        // Return mock data based on query
        if (String.isBlank(query) || query.trim().length() < 2) {
            return JSON.serialize(res);
        }
        
        // Mock some sample suggestions for testing
        if (query.startsWith('SW1A')) {
            // Mock data for Westminster area
            Suggestion s1 = new Suggestion();
            s1.address = 'Westminster, London SW1A 1AA';
            s1.url = '/get/SW1A1AA';
            s1.id = 'SW1A1AA';
            res.suggestions.add(s1);
            
            Suggestion s2 = new Suggestion();
            s2.address = 'Downing Street, London SW1A 2AA';
            s2.url = '/get/SW1A2AA';
            s2.id = 'SW1A2AA';
            res.suggestions.add(s2);
        } else if (query.startsWith('OX')) {
            // Mock data for Oxford area
            Suggestion s1 = new Suggestion();
            s1.address = 'Oxford, OX1 1AA';
            s1.url = '/get/OX11AA';
            s1.id = 'OX11AA';
            res.suggestions.add(s1);
        } else if (query.startsWith('test')) {
            // Mock data for test queries
            Suggestion s1 = new Suggestion();
            s1.address = 'Test Address 1, Test City';
            s1.url = '/get/test1';
            s1.id = 'test1';
            res.suggestions.add(s1);
        }
        
        return JSON.serialize(res);
    }

    /**
     * @description Mock implementation of get method that returns test data
     * instead of making external API calls.
     * @param id The suggestion id returned by autocomplete (or token required by provider).
     * @return JSON string matching the provided address shape.
     */
    @TestVisible
    public static String get(String id) {
        if (String.isBlank(id)) {
            return '{}';
        }
        
        // Return mock data based on ID
        if (id == 'SW1A1AA') {
            AddressResponse addr = new AddressResponse();
            addr.postcode = 'SW1A 1AA';
            addr.latitude = 51.5010;
            addr.longitude = -0.1416;
            addr.thoroughfare = 'Westminster';
            addr.town_or_city = 'London';
            addr.county = 'Greater London';
            addr.country = 'United Kingdom';
            addr.residential = true;
            addr.formatted_address = new List<String>{'Westminster', 'London', 'Greater London', 'United Kingdom'};
            return JSON.serialize(addr);
        } else if (id == 'test1') {
            AddressResponse addr = new AddressResponse();
            addr.postcode = 'TEST 1AA';
            addr.latitude = 51.5000;
            addr.longitude = -0.1300;
            addr.thoroughfare = 'Test Street';
            addr.town_or_city = 'Test City';
            addr.county = 'Test County';
            addr.country = 'United Kingdom';
            addr.residential = true;
            addr.formatted_address = new List<String>{'Test Street', 'Test City', 'Test County', 'United Kingdom'};
            return JSON.serialize(addr);
        } else if (id == 'invalid') {
            // Return empty JSON for invalid IDs
            return '{}';
        }
        
        // Default response for unknown IDs
        return '{}';
    }
    
    /**
     * @description Helper method to simulate an error condition for testing error handling
     */
    @TestVisible
    public static String getError() {
        throw new ADDRESS_LOOKUP_EXCEPTION('Mock error for testing');
    }
}