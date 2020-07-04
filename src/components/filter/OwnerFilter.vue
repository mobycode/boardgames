<template>
<div class="row" :data-filtered="filtered">
    <div class="col">
        <div class="input-group" :class="{'input-group-sm': deviceSizeValue < 2, 'input-group-xs': deviceSizeValue < 0}">
            <div class="input-group-prepend">
                <div class="input-group-text">
                    <input type="checkbox" v-model="enabled" id="ownersFilterCheckbox" aria-label="Enable owner filter">
                    <label class="d-sm-none form-check-label pl-1" for="ownersFilterCheckbox">Owners</label>
                </div>
                <div class="input-group-text label d-none d-sm-flex">Owners</div>
            </div>
            <div class="input-group-append">
                <span :id="dropdowns[0].id">
                    <button type="button" :class="{ show: dropdowns[0].open }" class="btn btn-secondary dropdown-toggle form-control-sm" data-toggle="dropdown-owners" aria-haspopup="true" :aria-expanded="dropdowns[0].open" @click="toggleDropdown(dropdowns[0].id)">{{ ownerText }}</button>
                    <div class="dropdown-menu" :class="{ show: dropdowns[0].open }">
                        <div class="form-check dropdown-item">
                            <label class="form-check-label">
                                <input class="form-check-input" type="radio" v-model="owned" v-bind:value="true" @click="setOwned">Owned
                            </label>
                        </div>
                        <div class="form-check dropdown-item" v-for="owner of allOwners" :key="owner">
                            <label class="form-check-label" style="margin-left: 25px;">
                                <input type="checkbox" class="form-check-input" @click="clickOwner" v-model="owners" v-bind:value="owner" :disabled="!owned">{{ owner }}
                            </label>
                        </div>
                        <div class="form-check dropdown-item">
                            <label class="form-check-label">
                                <input class="form-check-input" type="radio" v-model="owned" v-bind:value="false" @click="setOwned">Unowned
                            </label>
                        </div>
                    </div>
                </span>
            </div>
        </div>
    </div>
</div>
</template>

<script>
import Filter from './Filter.vue';

const OWNER_IAN = 'Ian';
const OWNER_JASON = 'Jason';
const OWNER_JOE = 'Joe';
const OWNER_JUSTIN = 'Justin';

const DROPDOWN_ID = 'ownerDropdownButtonGroup';

export default {
    mixins: [Filter],
    data() {
        let dropdowns = [{
                id: DROPDOWN_ID,
                open: false
            }],
            allOwners = [
                OWNER_IAN,
                OWNER_JASON,
                OWNER_JOE,
                OWNER_JUSTIN,
            ];

        return {
            id: 'owner',
            enabled: true,
            owned: true,
            owners: allOwners.slice(),
            allOwners,
            dropdowns
        }
    },
    computed: {
        ownerText() {
            let str = '';
            if (this.owned) {
                let len = this.owners.length;
                if (len > 0 && len < this.allOwners.length) {
                    str = this.owners.join(', ');
                } else {
                    str = 'anyone';
                }
            } else {
                str = 'no one';
            }
            return str;
        },
        filteredString() {
            const str = `${this.enabled}_${this.ownerText}`;
            console.log(`<> OwnerFilter::filteredString: ${str}`);
            return str;
        }
    },
    methods: {
        matches(item) {
            let matches = true;

            if (this.enabled) {
                if (this.owned) {
                    if (this.owners.length === 0) {
                        matches = (item.owners.length > 0);
                    } else {
                        matches = (item.owners.length > 0 && item.owners.some(owner => this.owners.includes(owner)));
                    }
                } else {
                    matches = item.owners.length === 0;
                }
            }
            return matches;
        },
        setOwned(evt) {
            this.owners = evt.target.value === "true" ? this.allOwners.slice() : [];
        },
        clickOwner(evt) {
            const value = evt.target.value,
                checked = evt.target.checked,
                idx = this.owners.indexOf(value);
            if (checked && idx === -1) {
                this.owners.push(value);
            } else if (!checked && idx !== -1) {
                this.owners.splice(idx, 1);
            }
        },
        toQuery() {
            let query = {},
                owners;

            if (this.enabled) {
                if (this.owned) {
                    if (this.owners.length !== this.allOwners.length) {
                        owners = this.owners.slice();
                    }
                } else {
                    owners = "none";
                }
            } else {
                owners = "off";
            }

            query[this.id] = owners;

            if (this.$route.query[this.id] !== query[this.id]) {
                this.$router.push({
                    query: Object.assign({}, this.$route.query, query)
                  });
            }
        },
        fromQuery() {
            let query = this.$route.query,
                val;

            if (query) {
                val = query[this.id];
                if (val !== undefined) {
                    if (val === "off") {
                        this.enabled = false;
                    } else {
                        this.enabled = true;
                        if (val === "none") {
                            this.owned = false;
                        } else if (Array.isArray(val)) {
                            this.owners = val.slice();
                        } else {
                            this.owned = true;
                            this.owners = this.allOwners.slice();
                        }
                    }

                    console.log(`<> OwnerFilter::fromQuery: ${this.owned} ${this.owners}`);
                }
            }
        },
        reset() {
            this.enabled = true;
            this.owned = true;
            this.owners = this.allOwners.slice();
        }
    }
}
</script>

<style lang="sass">
</style>
