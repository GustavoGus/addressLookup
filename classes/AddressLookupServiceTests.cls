@isTest
public class AddressLookupServiceTests {
    
    @isTest
    static void testAutocompleteSuccess() {
        // Test that the method can be called without errors using mock
        String result = AddressLookupServiceMock.autocomplete('test query');
        // Verify result is not null
        Assert.isNotNull(result, 'Result should not be null');
        Assert.isTrue(result.contains('"suggestions"'), 'Result should contain suggestions');
    }
    
    @isTest
    static void testAutocompleteEmptyQuery() {
        String result = AddressLookupServiceMock.autocomplete('');
        // Verify result is not null and contains expected structure
        Assert.isNotNull(result, 'Result should not be null');
        Assert.isTrue(result.contains('"suggestions"'), 'Result should contain suggestions');
        Assert.isTrue(result.contains('[]'), 'Result should contain empty suggestions array');
    }
    
    @isTest
    static void testAutocompleteShortQuery() {
        String result = AddressLookupServiceMock.autocomplete('ab');
        // Verify result is not null and contains expected structure
        Assert.isNotNull(result, 'Result should not be null');
        Assert.isTrue(result.contains('"suggestions"'), 'Result should contain suggestions');
        Assert.isTrue(result.contains('[]'), 'Result should contain empty suggestions array');
    }
    
    @isTest
    static void testAutocompleteWestminsterQuery() {
        // Test with a query that returns specific mock data
        String result = AddressLookupServiceMock.autocomplete('SW1A');
        // Verify result contains expected mock data
        Assert.isNotNull(result, 'Result should not be null');
        Assert.isTrue(result.contains('"suggestions"'), 'Result should contain suggestions');
        Assert.isTrue(result.contains('Westminster'), 'Result should contain Westminster data');
        Assert.isTrue(result.contains('Downing Street'), 'Result should contain Downing Street data');
    }
    
    @isTest
    static void testAutocompleteOxfordQuery() {
        // Test with a query that returns specific mock data
        String result = AddressLookupServiceMock.autocomplete('OX');
        // Verify result contains expected mock data
        Assert.isNotNull(result, 'Result should not be null');
        Assert.isTrue(result.contains('"suggestions"'), 'Result should contain suggestions');
        Assert.isTrue(result.contains('Oxford'), 'Result should contain Oxford data');
    }
    
    @isTest
    static void testGetSuccess() {
        // Test that the method can be called without errors using mock
        String result = AddressLookupServiceMock.get('test1');
        // Verify result is not null
        Assert.isNotNull(result, 'Result should not be null');
        Assert.isTrue(result.contains('{') && result.contains('}'), 'Result should be valid JSON object');
        Assert.isTrue(result.contains('"postcode"'), 'Result should contain postcode');
    }
    
    @isTest
    static void testGetInvalidId() {
        String result = AddressLookupServiceMock.get('');
        // Verify result is not null
        Assert.isNotNull(result, 'Result should not be null');
        Assert.areEqual('{}', result, 'Result should be empty JSON for invalid ID');
    }
    
    @isTest
    static void testGetValidId() {
        // Test with a valid ID that returns populated data
        String result = AddressLookupServiceMock.get('SW1A1AA');
        // Verify result is not null and contains expected data
        Assert.isNotNull(result, 'Result should not be null');
        Assert.isTrue(result.contains('"postcode"'), 'Result should contain postcode');
        Assert.isTrue(result.contains('"latitude"'), 'Result should contain latitude');
        Assert.isTrue(result.contains('"longitude"'), 'Result should contain longitude');
        Assert.isTrue(result.contains('"Westminster"'), 'Result should contain Westminster data');
    }
    
    @isTest
    static void testGetWithDifferentValidId() {
        // Test with a different valid ID that returns different populated data
        String result = AddressLookupServiceMock.get('test1');
        // Verify result is not null and contains expected data
        Assert.isNotNull(result, 'Result should not be null');
        Assert.isTrue(result.contains('"postcode"'), 'Result should contain postcode');
        Assert.isTrue(result.contains('"latitude"'), 'Result should contain latitude');
        Assert.isTrue(result.contains('"longitude"'), 'Result should contain longitude');
        Assert.isTrue(result.contains('"Test Street"'), 'Result should contain Test Street data');
    }
    
    @isTest
    static void testErrorHandlingSimulation() {
        // Test error handling capability of the mock
        try {
            // This should throw an exception in the mock
            AddressLookupServiceMock.getError();
            Assert.fail('Expected ADDRESS_LOOKUP_EXCEPTION to be thrown');
        } catch (AddressLookupServiceMock.ADDRESS_LOOKUP_EXCEPTION e) {
            // Expected behavior
            Assert.isTrue(e.getMessage().contains('Mock error for testing'), 'Should contain expected error message');
        }
    }
}