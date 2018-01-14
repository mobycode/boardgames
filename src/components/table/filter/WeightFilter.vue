<template>
<div class="row" :data-filtered="filtered">
    <div class="col">
        <div class="input-group" :class="{'input-group-sm': deviceSizeValue < 2}">
            <span class="input-group-addon">
                 <input type="checkbox" v-model="enabled" id="weightFilterCheckbox" aria-label="Enable weight filter" @change="focusInput">
                 <label class="d-sm-none form-check-label pl-1" for="weightFilterCheckbox">Weight</label>
            </span>
            <span class="input-group-addon label d-none d-sm-flex">Weight</span>
            <div class="input-group-btn" :id="dropdowns[0].id" :class="{ show: dropdowns[0].open }">
                <button type="button" class="btn btn-secondary dropdown-toggle" data-toggle="dropdown-weights" aria-haspopup="true" :aria-expanded="dropdowns[0].open" @click="toggleDropdown(dropdowns[0].id)">{{ actionText }}</button>
                <div class="dropdown-menu" :class="{ show: dropdowns[0].open }">
                    <a v-for="(action, index) in actions" class="dropdown-item" href="javascript:void(0);" @click="setAction(index, $event)">{{ action.text }}</a>
                </div>
            </div>
            <input placeholder="Weight" v-show="valueCount === 1" v-model.number="value" type="number" step="0.01" class="form-control" :class="{'is-invalid': $v.value.$error}" @input="$v.value.$touch(); autoEnable($event);" :disabled="valueCount !== 1">
            <input placeholder="Min" v-show="valueCount === 2" v-model.number="minValue" type="number" step="0.01" class="form-control" :class="{'is-invalid': $v.minValue.$error}" @input="$v.minValue.$touch(); autoEnable($event);" :disabled="valueCount !== 2">
            <span class="input-group-addon" v-show="valueCount === 2">{{ deviceSizeValue < 2 ? '&' : 'and' }}</span>
            <input placeholder="Max" v-show="valueCount === 2" v-model.number="maxValue" type="number" step="0.01" class="form-control" :class="{'is-invalid': $v.maxValue.$error}" @input="$v.maxValue.$touch(); autoEnable($event);" :disabled="valueCount !== 2">
        </div>
    </div>
</div>
</template>

<script>
import NumberFilter from './NumberFilter.vue';
import * as comparisons from './comparisons'

const DROPDOWN_ID = 'weightDropdownButtonGroup';

export default {
    mixins: [NumberFilter],
    data() {
        let actions = [{
            text: 'at least',
            comparison: comparisons.GREATER_THAN
        }, {
            text: 'at most',
            comparison: comparisons.LESS_THAN
        }, {
            text: 'between',
            comparison: comparisons.USER_RANGE
        }];

        let dropdowns = [{
            id: DROPDOWN_ID,
            open: false
        }];

        return {
            id: 'weight',
            dropdowns,
            actions,
            valuePrecision: 2,
            valueProperty: 'weight'
        }
    }
}
</script>

<style lang="sass">
</style>
