<template>
</template>

<script>
import Filter from './Filter.vue';
import * as comparisons from './comparisons'

import {
    required,
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
            dropdowns: [],
            actionIndex: 1,
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
            let str = this._oldFilteredString;
            if (!this.invalid) {
                str = `${this.actions.indexOf(this.action)}_${this.enabled}`;
                if (this.valueCount === 1) {
                    str += `_${this.value}`;
                } else if (this.valueCount === 2) {
                    str += `_${this.minValue}_${this.maxValue}`;
                }
                this._oldFilteredString = str;
                console.log(`<> NumberFilter::filteredString: ${str}`);
            }
            return str;
        }
    },
    validations: {
        // Vuelidate - validations property must use same name as property bound to with v-momdel
        value: {
            required: requiredIf(function(nestedModel) {
                return (this.valueCount === 1);
            }),
            number: number,
            minVal: minValue(1)
        },
        minValue: {
            required: requiredIf(function(nestedModel) {
                return (this.valueCount === 2);
            }),
            number,
            minValue: minValue(1)
        },
        maxValue: {
            required: requiredIf(function(nestedModel) {
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
                itemValue = item[this.valueProperty],
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
                        matches = (this.value >= itemMinValue && this.value <= itemMaxValue);
                        break;
                    case comparisons.USER_RANGE:
                        matches = (itemMinValue >= this.minValue && itemMaxValue <= this.maxValue);
                        break;
                    case comparisons.DUAL_RANGE:
                        matches = (this.minValue >= itemMinValue && this.maxValue <= itemMaxValue);
                        break;
                    case comparisons.NO_VALUE:
                        matches = (itemValue === -1);
                        break;
                }
                if (item.objectid === "174430") {
                    console.log('<> NumberFilter::matches: name [' + item.name + '] ? ' + matches);
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
        autoEnable(evt) {
            if (!this.invalid) {
                this.enabled = true;
                console.log(`<> NumberFilter::autoEnable`);
            }
        }
    }
}
</script>

<style lang="sass">
</style>
