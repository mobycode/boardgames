<template>
<div class="row" :data-filtered="filtered">
  <div class="col">
    <div class="input-group" :class="{'input-group-sm': deviceSizeValue < 2, 'input-group-xs': deviceSizeValue < 0}">
      <div class="input-group-prepend">
        <div class="input-group-text">
          <input type="checkbox" v-model="enabled" for="playTimeFilterCheckbox" aria-label="Enable play time filter" @change="focusInput">
          <label class="d-sm-none form-check-label pl-1" for="playTimeFilterCheckbox">Play time</label>
        </div>
        <div class="input-group-text label d-none d-sm-flex">Play time</div>
        <span>
          <button type="button" :id="dropdowns[0].id" class="btn btn-secondary" data-toggle="dropdown-playTimes">{{ actionText }}</button>
        </span>
      </div>
      <input placeholder="Play time" v-if="valueCount === 1" v-model.number="value" type="number" class="form-control" :class="{'is-invalid': enabled && $v.value.$error}" @input="$v.value.$touch(); autoEnable($event);" :disabled="valueCount !== 1">
      <input placeholder="Min" v-if="valueCount === 2" v-model.number="minValue" type="number" class="form-control" :class="{'is-invalid': enabled && $v.minValue.$error}" @input="$v.minValue.$touch(); autoEnable($event);" :disabled="valueCount !== 2">
      <div class="input-group-append input-group-insert" v-if="valueCount === 2">
        <div class="input-group-text">{{ andText }}</div>
      </div>
      <input placeholder="Max" v-if="valueCount === 2" v-model.number="maxValue" type="number" class="form-control" :class="{'is-invalid': enabled && $v.maxValue.$error}" @input="$v.maxValue.$touch(); autoEnable($event);" :disabled="valueCount !== 2">
      <div class="input-group-append">
        <div class="input-group-text">minutes</div>
      </div>
    </div>
  </div>
</div>
</template>

<script>
import NumberFilter from './NumberFilter.vue';
import * as comparisons from './comparisons';

const DROPDOWN_ID = 'playTimeDropdownButtonGroup';

export default {
  mixins: [NumberFilter],
  data() {
    const actions = [{
      text: 'of',
      comparison: comparisons.ITEM_RANGE,
    }];

    const dropdowns = [{
      id: DROPDOWN_ID,
      open: false,
    }];

    return {
      id: 'playtime',
      dropdowns,
      actions,
      actionIndex: 0,
      valueProperty: 'minplaytime',
      minValueProperty: 'minplaytime',
      maxValueProperty: 'maxplaytime',
    };
  },
};
</script>

<style lang="sass" scoped>
#playTimeDropdownButtonGroup
  cursor: default
</style>
