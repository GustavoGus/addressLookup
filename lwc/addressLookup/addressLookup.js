import { LightningElement, track, api, wire } from 'lwc';
import { getRecord } from 'lightning/uiRecordApi';
import { updateRecord } from 'lightning/uiRecordApi';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { notifyRecordUpdateAvailable } from 'lightning/uiRecordApi';
import autocomplete from '@salesforce/apex/AddressLookupAura.autocomplete';
import getAddress from '@salesforce/apex/AddressLookupAura.get';

export default class LightningExampleInputSearch extends LightningElement {
    @api objectApiName;
    @api postalCodeApiFieldName;
    @api streetApiFieldName;
    @api cityApiFieldName;
    @api countyApiFieldName;
    @api countryApiFieldName;
    @api title;
    @api recordId;

    queryTerm = '';
    selectedSuggestionId = null;
    fieldApiNames = '';
    isLoading = false;

    // Raw suggestions as received from service
    @track addressSuggestions = [];

    // Selected/Resolved address details
    @track addressDetail = {
        postcode: '',
        street: '',
        city: '',
        county: '',
        country: ''
    };

    // Error message from service
    @track errorMessage = '';

    // Computed options for lightning-combobox
    get suggestionOptions() {
        // Map to combobox option shape: { label, value }
        return (this.addressSuggestions || []).map(s => ({
            label: s.address,
            value: s.id
        }));
    }

    connectedCallback() {
        // Initialize fieldApiNames when component connects
        this.fieldApiNames = [
            this.objectApiName.trim() + '.' + this.postalCodeApiFieldName,
            this.objectApiName.trim() + '.' + this.streetApiFieldName,
            this.objectApiName.trim() + '.' + this.cityApiFieldName,
            this.objectApiName.trim() + '.' + this.countyApiFieldName,
            this.objectApiName.trim() + '.' + this.countryApiFieldName
        ].filter(name => name && name.trim() !== '');
    }

    // Wire adapter to get record data
    @wire(getRecord, { recordId: '$recordId', fields: '$fieldApiNames' })
    wiredRecord({ error, data }) {
        if (data) {
            // Set field values based on individual field names
            if (this.postalCodeApiFieldName && data.fields[this.postalCodeApiFieldName]) {
                this.addressDetail.postcode = data.fields[this.postalCodeApiFieldName].value || '';
            }
            if (this.streetApiFieldName && data.fields[this.streetApiFieldName]) {
                this.addressDetail.street = data.fields[this.streetApiFieldName].value || '';
            }
            if (this.cityApiFieldName && data.fields[this.cityApiFieldName]) {
                this.addressDetail.city = data.fields[this.cityApiFieldName].value || '';
            }
            if (this.countyApiFieldName && data.fields[this.countyApiFieldName]) {
                this.addressDetail.county = data.fields[this.countyApiFieldName].value || '';
            }
            if (this.countryApiFieldName && data.fields[this.countryApiFieldName]) {
                this.addressDetail.country = data.fields[this.countryApiFieldName].value || '';
            }
        } else if (error) {
            console.error('Error loading record:', error);
        }
    }

    // Handle search when user presses Enter
    async handleKeyUp(evt) {
        console.log('handleKeyUp');
        const isEnterKey = evt.keyCode === 13;
        if (isEnterKey) {
            const value = evt.target.value ? evt.target.value.trim() : '';
            this.queryTerm = value;
            this.selectedSuggestionId = null;
            this.errorMessage = ''; // Clear previous errors

            if (!value) {
                this.addressSuggestions = [];
                return;
            }

            // Set loading state
            this.isLoading = true;
            
            // URL encode the search query to handle special characters
            const encodedValue = encodeURIComponent(value);
            
            // Call AddressLookupAura.autocomplete(query) which returns JSON string: {"suggestions":[...]}
            try {
                const json = await autocomplete({ query: encodedValue });
                const parsed = JSON.parse(json || '{"suggestions": []}');
                
                // Check for error in response
                if (parsed.error) {
                    this.errorMessage = parsed.error;
                    this.addressSuggestions = [];
                    return;
                }
                
                const list = Array.isArray(parsed.suggestions) ? parsed.suggestions : [];
                // Expecting each suggestion to have: { address, url, id }
                this.addressSuggestions = list.map(s => ({
                    address: s.address,
                    url: s.url,
                    id: s.id
                }));
            } catch (e) {
                // On error, clear suggestions to keep UI stable
                this.addressSuggestions = [];
                // Handle different types of errors
                if (e && e.status === 429) {
                    this.errorMessage = 'Too many requests. Please wait before trying again.';
                } else if (e && e.message && e.message.includes('429')) {
                    this.errorMessage = 'Too many requests. Please wait before trying again.';
                } else {
                    this.errorMessage = 'An unexpected error occurred during address search.';
                }
            } finally {
                // Always reset loading state
                this.isLoading = false;
            }
        }
    }

    // Dispatch selected suggestion id to parent (if needed)
    async handleSelectChange(event) {
        const selectedId = event.detail.value;
        this.selectedSuggestionId = selectedId;
        this.errorMessage = ''; // Clear previous errors

        // Find selected suggestion so we can pass its id to Apex
        const selected = (this.addressSuggestions || []).find(s => s.id === selectedId) || null;

        if (!selected) {
            this.addressDetail = { postcode: '', street: '', city: '', county: '', country: '' };
            return;
        }

        try {
            // Call AddressLookupAura.get(id) which returns a JSON string with the detail payload
            const json = await getAddress({ id: selected.id });
            const detail = JSON.parse(json || '{}');

            // Check for error in response
            if (detail.error) {
                this.errorMessage = detail.error;
                this.addressDetail = { postcode: '', street: '', city: '', county: '', country: '' };
                return;
            }

            // Build street from concatenation of all non-empty line fields
            const lines = [
                detail.line_1,
                detail.line_2,
                detail.line_3,
                detail.line_4
            ].filter(l => !!l && l.trim().length > 0);

            this.addressDetail = {
                postcode: detail.postcode || '',
                street: lines.join(', '),
                city: detail.town_or_city || detail.district || '',
                county: detail.county || '',
                country: detail.country || ''
            };

            // Bubble event with raw payload if parent needs it
            this.dispatchEvent(
                new CustomEvent('suggestionselect', {
                    detail: {
                        id: selectedId,
                        suggestion: selected,
                        resolved: detail
                    },
                    bubbles: true,
                    composed: true
                })
            );
        } catch (e) {
            // Reset fields on error to avoid stale view
            this.addressDetail = { postcode: '', street: '', city: '', county: '', country: '' };
            // Check if this is a rate limit error (HTTP 429) and provide specific message
            if (e.status === 429) {
                this.errorMessage = 'Too many requests. Please wait before trying again.';
            } else {
                // Use the specific user-friendly error message for getAddress failures
                this.errorMessage = 'Address lookup service temporarily unavailable. Please contact your administrator or enter the address manually';
            }
        }
    }

    // Save button handler
    handleSave() {
        console.log('handleSave');
        
        // Validate all inputs using the standard Salesforce approach
        const allValid = [
            ...this.template.querySelectorAll('lightning-input'),
        ].reduce((validSoFar, inputCmp) => {
            inputCmp.reportValidity();
            return validSoFar && inputCmp.checkValidity();
        }, true);
        
        if (!allValid) {
            // Show error toast for invalid fields
            const toastEvent = new ShowToastEvent({
                title: 'Validation Error',
                message: 'Please update the invalid form entries and try again.',
                variant: 'error'
            });
            this.dispatchEvent(toastEvent);
            return;
        }
        
        // Create an object to hold the field updates
        const fieldUpdates = {};
        
        // Map the address fields to their respective API names using individual field properties
        if (this.postalCodeApiFieldName && this.addressDetail.postcode) {
            fieldUpdates[this.postalCodeApiFieldName] = this.addressDetail.postcode;
        }
        if (this.streetApiFieldName && this.addressDetail.street) {
            fieldUpdates[this.streetApiFieldName] = this.addressDetail.street;
        }
        if (this.cityApiFieldName && this.addressDetail.city) {
            fieldUpdates[this.cityApiFieldName] = this.addressDetail.city;
        }
        if (this.countyApiFieldName && this.addressDetail.county) {
            fieldUpdates[this.countyApiFieldName] = this.addressDetail.county;
        }
        if (this.countryApiFieldName && this.addressDetail.country) {
            fieldUpdates[this.countryApiFieldName] = this.addressDetail.country;
        }

        // If we have updates, call updateRecord
        if (Object.keys(fieldUpdates).length > 0) {
            const recordInput = {
                fields: {
                    Id: this.recordId,
                    ...fieldUpdates
                }
            };

            updateRecord(recordInput)
                .then(() => {
                    // Success handling - notify that record has been updated and show toast
                    notifyRecordUpdateAvailable([this.recordId]);
                    const toastEvent = new ShowToastEvent({
                        title: 'Success',
                        message: 'Address updated successfully',
                        variant: 'success'
                    });
                    this.dispatchEvent(toastEvent);
                })
                .catch(error => {
                    console.error('Error updating record:', error);
                    this.errorMessage = 'Failed to save address details.';
                    // Show error toast
                    const toastEvent = new ShowToastEvent({
                        title: 'Error',
                        message: 'Failed to save address details: ' + error.body.message,
                        variant: 'error'
                    });
                    this.dispatchEvent(toastEvent);
                });
        }

        // Dispatch event to notify parent component to save the record
        this.dispatchEvent(
            new CustomEvent('saveaddress', {
                detail: {
                    recordId: this.recordId,
                    objectApiName: this.objectApiName,
                    fieldUpdates: fieldUpdates
                },
                bubbles: true,
                composed: true
            })
        );
    }
}