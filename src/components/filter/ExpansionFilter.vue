<template>
<div class="row">
    <div class="col">
        <div class="input-group" :class="{'input-group-sm': deviceSizeValue < 2, 'input-group-xs': deviceSizeValue < 0}">
            <div class="input-group-prepend only-visible-child">
                <div class="input-group-text">
                    <input type="checkbox" v-model="enabled" id="expansionFilterCheckbox" aria-label="Enable expansion filter">
                    <label class="d-sm-none form-check-label pl-1" for="expansionFilterCheckbox">Hide expansions</label>
                </div>
                <div class="input-group-text label d-none d-sm-flex">Hide expansions</div>
            </div>
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
            let matches = true;

            if (this.enabled) {
                matches = item.subtype !== "boardgameexpansion";
                //console.log('<> ExpansionFilter::matches: name [' + item.name + '] ? ' + matches);
            }

            return matches;
        },
        toQuery() {
            const exp = this.enabled ? undefined : "true"
            if (this.$route.query.exp !== exp) {
                this.$router.push({
                    query: Object.assign({}, this.$route.query, {
                        exp: exp
                    })
                });
            }
        },
        fromQuery() {
            let query = this.$route.query;
            if (query) {
                this.enabled = (query.exp !== "true");
                console.log(`<> ExpansionFilter::fromQuery: ${this.enabled}`);
            }
        },
        reset() {
            this.enabled = true;
        }
    },
    watch: {
        enabled() {
            this.toQuery();
            this.filterChanged();
        }
    }
}
</script>

<style lang="sass">
</style>
