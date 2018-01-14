<template>
<div class="row">
    <div class="col">
        <div class="input-group" :class="{'input-group-sm': deviceSizeValue < 2}">
            <span class="input-group-addon only-visible-child">
                 <input type="checkbox" v-model="enabled" id="expansionFilterCheckbox" aria-label="Enable expansion filter">
                 <label class="d-sm-none form-check-label pl-1" for="expansionFilterCheckbox">Hide expansions</label>
            </span>
            <span class="input-group-addon label d-none d-sm-flex">Hide expansions</span>
        </div>
    </div>
</div>
</template>

<script>
import Filter from './Filter.vue';

export default {
    mixins: [Filter],
    data() {
        return {
            id: 'expansion',
            enabled: true
        }
    },
    methods: {
        matches(item) {
            let action = this.action,
                matches = true;

            if (this.enabled) {
                matches = item.subtype !== "boardgameexpansion";
                //console.log('<> ExpansionFilter::matches: name [' + item.name + '] ? ' + matches);
            }

            return matches;
        }
    },
    created() {
        if (this.enabled) {
            this.$store.dispatch('updateFilter', {
                filter: this
            });
        }
    },
    watch: {
        enabled(val) {
            this.filterChanged();
        }
    }
}
</script>

<style lang="sass">
</style>
