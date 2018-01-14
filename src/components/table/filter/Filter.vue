<template>
</template>

<script>
import {
    validationMixin
} from 'vuelidate'

import {
    mapGetters,
    mapActions
} from 'vuex'

export default {
    mixins: [validationMixin],
    data() {
        return {
            id: '',
            enabled: false,
            dropdowns: []
        }
    },
    computed: {
        deviceSizeValue() {
            return this.$store.getters.deviceSizeValue;
        },
        filtered() {
            let oldValue = this._oldfiltered,
                newValue = this.filteredString;
            console.log(`<> Filter::filtered: ${oldValue} -> ${newValue}`);
            if (oldValue !== newValue) {
                this._oldfiltered = newValue;
                this.filterChanged();
            }
            return newValue;
        }
    },
    validations: {},
    created() {
        if (this.enabled) {
            this.filterChanged();
        }
        if (this.dropdowns.length > 0) {
            window.addEventListener('click', (evt) => {
                for (let dropdown of this.dropdowns) {
                    let elem = document.getElementById(dropdown.id);
                    if (!elem || !elem.contains(evt.target)) {
                        dropdown.open = false;
                    }
                }
            });
        }
    },
    methods: {
        matches() {
            console.log("Extending filter must override Filter::matches");
            return true;
        },
        filterChanged() {
            this.$store.dispatch('updateFilter', {
                filter: this
            });
        },
        toggleDropdown(id) {
            if (this.dropdowns) {
                this.dropdowns.forEach((dropdown) => {
                    if (dropdown.id === id) {
                        dropdown.open = !dropdown.open;
                    }
                });
            }
        }
    }
}
</script>

<style lang="sass">
</style>
