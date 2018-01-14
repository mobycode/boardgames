<template>
<div class="row" :data-filtered="filtered">
    <div class="col">
        <div class="input-group" :class="{'input-group-sm': deviceSizeValue < 2}">
            <span class="input-group-addon">
                 <input type="checkbox" v-model="enabled" for="playerCountFilterCheckbox" aria-label="Enable players filter" @change="focusInput">
                 <label class="d-sm-none form-check-label pl-1" for="playerCountFilterCheckbox">Player count</label>
            </span>
            <span class="input-group-addon label d-none d-sm-flex">Players</span>
            <div class="input-group-btn" :id="dropdowns[0].id" :class="{ show: dropdowns[0].open }">
                <button type="button" class="btn btn-secondary dropdown-toggle" data-toggle="dropdown-players" aria-haspopup="true" :aria-expanded="dropdowns[0].open" @click="toggleDropdown(dropdowns[0].id)">{{ actionText }}</button>
                <div class="dropdown-menu" :class="{ show: dropdowns[0].open }">
                    <a v-for="(action, index) in actions" class="dropdown-item" href="javascript:void(0);" @click="setPlayerCountAction(index, $event)">{{ action.text }}</a>
                </div>
            </div>
            <input placeholder="Player count" v-show="valueCount === 1" v-model.number="value" type="number" class="form-control" :class="{'is-invalid': $v.value.$error}" @input="$v.value.$touch(); autoEnable($event);" :disabled="valueCount !== 1">
            <input placeholder="Min" v-show="valueCount === 2" v-model.number="minValue" type="number" class="form-control" :class="{'is-invalid': $v.minValue.$error}" @input="$v.minValue.$touch(); autoEnable($event);" :disabled="valueCount !== 2">
            <span class="input-group-addon" v-show="valueCount === 2">{{ deviceSizeValue < 2 ? '&' : 'and' }}</span>
            <input placeholder="Max" v-show="valueCount === 2" v-model.number="maxValue" type="number" class="form-control" :class="{'is-invalid': $v.maxValue.$error}" @input="$v.maxValue.$touch(); autoEnable($event);" :disabled="valueCount !== 2">
        </div>
    </div>
</div>
</template>

<script>
import NumberFilter from './NumberFilter.vue';
import * as comparisons from './comparisons'

const DROPDOWN_ID = 'playerCountDropdownButtonGroup';

export default {
    mixins: [NumberFilter],
    data() {
        let actions = [{
                text: 'supports',
                comparison: comparisons.ITEM_RANGE
            },
            {
                text: 'best with',
                comparison: comparisons.CONTAINS
            },
            {
                text: 'recommended for',
                comparison: comparisons.CONTAINS
            },
            {
                text: 'between',
                comparison: comparisons.DUAL_RANGE
            }
        ];

        let dropdowns = [{
            id: DROPDOWN_ID,
            open: false
        }];

        return {
            id: 'player-count',
            enabled: false,
            value: undefined,
            minValue: undefined,
            maxValue: undefined,
            dropdowns,
            actionIndex: 0,
            actions,
            valueProperty: 'bestplayers',
            minValueProperty: 'minplayers',
            maxValueProperty: 'maxplayers'
        }
    },
    methods: {
        setPlayerCountAction(actionIndex, evt) {
            this.valueProperty = actionIndex === 1 ? 'bestplayers' : 'recplayers';
            this.setAction(actionIndex, evt);
        }
    }
}
</script>

<style lang="sass">
</style>
