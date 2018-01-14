<template>
<div class="row" :data-filtered="filtered">
    <div class="col">
        <div class="input-group" :class="{'input-group-sm': deviceSizeValue < 2}">
            <span class="input-group-addon">
                 <input type="checkbox" v-model="enabled" id="nameFilterCheckbox" aria-label="Enable name filter" @change="focusInput">
                 <label class="d-sm-none form-check-label pl-1" for="nameFilterCheckbox">Name</label>
            </span>
            <span class="input-group-addon label d-none d-sm-flex">Name</span>
            <div class="input-group-btn" :id="dropdowns[0].id" :class="{ show: dropdowns[0].open }">
                <button type="button" class="btn btn-secondary dropdown-toggle" data-toggle="dropdown-name" aria-haspopup="true" :aria-expanded="dropdowns[0].open" @click="toggleDropdown(dropdowns[0].id)">{{ actionText }}</button>
                <div class="dropdown-menu" :class="{ show: dropdowns[0].open }">
                    <a v-for="(obj, action) in actionInfo" class="dropdown-item" href="javascript:void(0);" @click="setAction(action, $event)">{{ obj.text }}</a>
                </div>
            </div>
            <input id="value" placeholder="Name" v-model="value" @keyup="autoEnable" type="text" class="form-control">
        </div>
    </div>
</div>
</template>

<script>
import Filter from './Filter.vue';

const ACTION_CONTAINS = 'contains';
const ACTION_EQUALS = 'equals';
const ACTION_STARTS_WITH = 'startsWith';
const ACTION_ENDS_WITH = 'endsWith';

const DROPDOWN_ID = 'nameDropdownButtonGroup';

export default {
    mixins: [Filter],
    data() {
        let actionInfo = {};
        actionInfo[ACTION_CONTAINS] = {
            text: 'contains',
            method: 'includes'
        };
        actionInfo[ACTION_EQUALS] = {
            text: 'is'
        };
        actionInfo[ACTION_STARTS_WITH] = {
            text: 'starts with',
            method: 'startsWith'
        };
        actionInfo[ACTION_ENDS_WITH] = {
            text: 'ends with',
            method: 'endsWith'
        };

        let dropdowns = [{
            id: DROPDOWN_ID,
            open: false
        }];

        return {
            id: 'name',
            value: '',
            dropdowns,
            action: ACTION_CONTAINS,
            actionInfo
        }
    },
    computed: {
        actionText() {
            return this.actionInfo[this.action].text;
        },
        filteredString() {
            const str = `${this.action}_${this.enabled}_${this.value}`;
            console.log(`<> NameFilter::filteredString: ${str}`);
            return str;
        }
    },
    methods: {
        matches(item) {
            let action = this.action,
                matches = true;

            if (this.enabled && this.action !== "") {
                if (action === ACTION_EQUALS) {
                    matches = (this.value.toLowerCase() === item.name.toLowerCase());
                } else {
                    matches = item.name.toLowerCase()[this.actionInfo[action].method](this.value.toLowerCase());
                }
                if (item.objectid === "174430") {
                    console.log('<> NameFilter::matches: name [' + item.name + '] ? ' + matches);
                }
            }

            return matches;
        },
        setAction(action, evt) {
            let oldAction = this.action;
            this.dropdowns[0].open = false;
            if (oldAction !== action) {
                this.action = action;
            }
            setTimeout(() => {
                this.focusInput();
            }, 100);
            this.autoEnable(evt);
        },
        focusInput(evt) {
            if (!evt || evt.target.checked) {
                var elem = this.$el.querySelector("input[type=text]");
                if (elem) {
                    elem.focus();
                }
            }
        },
        autoEnable(evt) {
            this.enabled = (this.value !== '');
            //console.log("<> NameFilter::autoEnable: "+this.enabled);
        }
    }
}
</script>

<style lang="sass">
</style>
