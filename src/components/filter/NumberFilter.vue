<template>
  <div></div>
</template>

<script>
import Filter from './Filter.vue';
import * as comparisons from './comparisons'

import {
    requiredIf,
    minValue
} from 'vuelidate/lib/validators';

const number = function(val) {
    return this.valuePrecision === 0 ? Number.isInteger(val) : !Number.isNaN(val);
};

export default {
    mixins: [Filter],
    data() {
        return {
            value: undefined,
            minValue: undefined,
            maxValue: undefined,
            actionIndex: 0,
            actions: [],
            valuePrecision: 0,
            valueProperty: ''
        }
    },
    computed: {
        action() {
            return this.actions[this.actionIndex];
        },
        valueCount() {
            let count;
            switch (this.action.comparison) {
                case comparisons.USER_RANGE:
                case comparisons.DUAL_RANGE:
                    count = 2;
                    break;
                case comparisons.NO_VALUE:
                    count = 0;
                    break;
                case comparisons.GREATER_THAN:
                case comparisons.LESS_THAN:
                case comparisons.CONTAINS:
                case comparisons.ITEM_RANGE:
                default:
                    count = 1;
                    break;
            }
            return count;
        },
        actionText() {
            return this.action.text;
        },
        invalid() {
            let invalid;
            console.log(`<> NumberFilter::invalid: ${this.id} - ${this.valueCount} ${this.action}`);
            if (this.valueCount === 1) {
                invalid = this.$v.value.$invalid;
            } else if (this.valueCount === 2) {
                invalid = this.$v.range.$invalid;
            } else {
                invalid = false;
            }
            return invalid;
        },
        filteredString() {
            let str // = this._oldFilteredString;
            if (!this.invalid) {
                str = `${this.actions.indexOf(this.action)}_${this.enabled}`;
                if (this.valueCount === 1) {
                    str += `_${this.value}`;
                } else if (this.valueCount === 2) {
                    str += `_${this.minValue}_${this.maxValue}`;
                }
            } else {
                str = 'invalid';
            }
            //this._oldFilteredString = str; // eslint-disable-line vue/no-side-effects-in-computed-properties
            console.log(`<> NumberFilter::filteredString: ${this.id} - ${this.invalid} ${str}`);
            return str;
        },
        andText() {
            return this.deviceSizeValue < 2 ? '&' : 'and';
        }
    },
    validations: {
        // Vuelidate - validations property must use same name as property bound to with v-momdel
        value: {
            required: requiredIf(function() {
                return (this.valueCount === 1);
            }),
            number: number,
            minVal: minValue(1)
        },
        minValue: {
            required: requiredIf(function() {
                return (this.valueCount === 2);
            }),
            number,
            minValue: minValue(1)
        },
        maxValue: {
            required: requiredIf(function() {
                return (this.valueCount === 2);
            }),
            number,
            greaterThan(val) {
                return val >= this.minValue;
            }
        },
        range: ['minValue', 'maxValue']
    },
    methods: {
        matches(item) {
            let matches = true,
                valueProperty = this.action.valueProperty || this.valueProperty,
                itemValue = item[valueProperty],
                itemMinValue = item[this.minValueProperty || this.valueProperty],
                itemMaxValue = item[this.maxValueProperty || this.valueProperty];

            if (this.enabled && !this.invalid) {
                switch (this.action.comparison) {
                    case comparisons.GREATER_THAN:
                        matches = (itemValue !== -1 && itemValue >= this.value);
                        break;
                    case comparisons.LESS_THAN:
                        matches = (itemValue !== -1 && itemValue <= this.value);
                        break;
                    case comparisons.CONTAINS:
                        matches = (Array.isArray(itemValue) && itemValue.includes(this.value));
                        break;
                    case comparisons.ITEM_RANGE:
                        matches = (itemMinValue !== -1 && itemMaxValue !== -1 && this.value >= itemMinValue && this.value <= itemMaxValue);
                        break;
                    case comparisons.USER_RANGE:
                        matches = (itemMinValue !== -1 && itemMaxValue !== -1 && itemMinValue >= this.minValue && itemMaxValue <= this.maxValue);
                        break;
                    case comparisons.DUAL_RANGE:
                        matches = (itemMinValue !== -1 && itemMaxValue !== -1 && this.minValue >= itemMinValue && this.maxValue <= itemMaxValue);
                        break;
                    case comparisons.NO_VALUE:
                        matches = (itemValue === -1);
                        break;
                }
                if (item.objectid === "174430") {
                    console.log('<> NumberFilter::matches: ${this.id} - name [' + item.name + '] ? ' + matches);
                }
            }

            return matches;
        },
        setAction(actionIndex, evt) {
            let oldActionIndex = this.actionIndex;
            this.dropdowns[0].open = false;
            if (oldActionIndex !== actionIndex) {
                this.actionIndex = actionIndex;
            }
            setTimeout(() => {
                this.focusInput();
            }, 100);
            this.autoEnable(evt);
        },
        focusInput(evt) {
            if (!evt || evt.target.checked) {
                var elem = this.$el.querySelector("input[type=number]:not(:disabled)");
                if (elem) {
                    elem.focus();
                }
            }
        },
        autoEnable() {
            if (!this.invalid) {
                this.enabled = true;
                console.log(`<> NumberFilter::autoEnable: ${this.id}`);
            }
        },
        toQuery() {
            let query = {},
                idx, val, min, max;

            if (this.enabled && !this.invalid) {
                idx = this.actionIndex;
                if (this.valueCount === 1) {
                    val = this.value;
                } else if (this.valueCount === 2) {
                    min = this.minValue;
                    max = this.maxValue;
                }
            }

            query[this.id + 'Idx'] = idx;
            query[this.id + 'Val'] = val;
            query[this.id + 'Min'] = min;
            query[this.id + 'Max'] = max;

            if ((this.$route.query[this.id + 'Idx'] !== idx) ||
                (this.$route.query[this.id + 'Val'] !== val) ||
                (this.$route.query[this.id + 'Min'] !== min) ||
                (this.$route.query[this.id + 'Max'] !== max))
            {
                this.$router.push({
                    query: Object.assign({}, this.$route.query, query)
                });
            }
        },
        fromQuery() {
            let query = this.$route.query,
                parser = Number[this.valuePrecision === 0 ? 'parseInt' : 'parseFloat'],
                parseNumber = (val) => {
                    return val ? parser(val, 10) : undefined;
                };

            //console.log(`-> NumberFilter::fromQuery: ${this.id} ${query}`);

            if (query && query[this.id + 'Idx']) {
                this.value = parseNumber(query[this.id + 'Val']);
                this.minValue = parseNumber(query[this.id + 'Min']);
                this.maxValue = parseNumber(query[this.id + 'Max']);
                this.actionIndex = parseNumber(query[this.id + 'Idx']);

                this.$v.value.$touch();
                this.$v.minValue.$touch();
                this.$v.maxValue.$touch();

                this.enabled = true;
                console.log(`<> NumberFilter::fromQuery: ${this.id} - ${this.actionIndex} ${this.value} ${this.minValue} ${this.maxValue}`);
            }

            //console.log(`<- NumberFilter::fromQuery: ${this.id}`);
        },
        reset() {
            this.enabled = false;
            this.value = undefined;
            this.minValue = undefined;
            this.maxValue = undefined;
            this.actionIndex = 0;
        }
    }
}
</script>

<style lang="sass">
</style>
