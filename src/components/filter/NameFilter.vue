<template>
<div class="row" :data-filtered="filtered">
  <div class="col">
    <div class="input-group" :class="{'input-group-sm': deviceSizeValue < 2, 'input-group-xs': deviceSizeValue < 0}">
      <div class="input-group-prepend">
        <div class="input-group-text">
          <input type="checkbox" v-model="enabled" id="nameFilterCheckbox" aria-label="Enable name filter" @change="focusInput">
          <label class="d-sm-none form-check-label pl-1" for="nameFilterCheckbox">Name</label>
        </div>
        <div class="input-group-text label d-none d-sm-flex">Name</div>
        <span>
          <button type="button" :id="dropdowns[0].id" :class="{ show: dropdowns[0].open }" class="btn btn-secondary dropdown-toggle" data-toggle="dropdown-name" aria-haspopup="true" :aria-expanded="dropdowns[0].open" @click="toggleDropdown(dropdowns[0].id)">{{ actionText }}</button>
          <div class="dropdown-menu" :class="{ show: dropdowns[0].open }">
            <a v-for="(action, index) in actions" :key="index" class="dropdown-item" href="javascript:void(0);" @click="setAction(index, $event)">{{ action.text }}</a>
          </div>
        </span>
      </div>
      <input id="value" placeholder="Name" v-model="value" @keyup="autoEnable" type="text" class="form-control">
    </div>
  </div>
</div>
</template>

<script>
import Filter from './Filter.vue';

const DROPDOWN_ID = 'nameDropdownButtonGroup';

export default {
  mixins: [Filter],
  data() {
    const actions = [{
      text: 'contains',
      method: 'includes',
    }, {
      text: 'is',
    }, {
      text: 'starts with',
      method: 'startsWith',
    }, {
      text: 'ends with',
      method: 'endsWith',
    }];

    const dropdowns = [{
      id: DROPDOWN_ID,
      open: false,
    }];

    return {
      id: 'name',
      value: '',
      dropdowns,
      actionIndex: 0,
      actions,
    };
  },
  computed: {
    action() {
      return this.actions[this.actionIndex];
    },
    actionText() {
      return this.actions[this.actionIndex].text;
    },
    filteredString() {
      const str = `${this.actionIndex}_${this.enabled}_${this.value}`;
      console.log(`<> NameFilter::filteredString: ${str}`);
      return str;
    },
  },
  methods: {
    matches(item) {
      const { method } = this.action;
      let matches = true;

      if (this.enabled) {
        if (method === undefined) {
          matches = (this.value.toLowerCase() === item.name.toLowerCase());
        } else {
          matches = item.name.toLowerCase()[method](this.value.toLowerCase());
        }
        if (item.objectid === '174430') {
          console.log(`<> NameFilter::matches: name [${item.name}] ? ${matches}`);
        }
      }

      return matches;
    },
    setAction(actionIndex, evt) {
      const oldActionIndex = this.actionIndex;
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
        const elem = this.$el.querySelector('input[type=text]');
        if (elem) {
          elem.focus();
        }
      }
    },
    autoEnable() {
      this.enabled = (this.value !== '');
      // console.log("<> NameFilter::autoEnable: "+this.enabled);
    },
    toQuery() {
      let val; let
        idx;

      if (this.enabled && this.value !== '') {
        val = this.value;
        idx = this.actionIndex;
      }

      if ((this.$route.query.name !== val) || (this.$route.query.nameIdx !== idx)) {
        this.$router.push({
          query: {
            ...this.$route.query,
            name: val,
            nameIdx: idx,
          },
        });
      }
    },
    fromQuery() {
      const { query } = this.$route;

      if (query && query.name && query.nameIdx) {
        this.value = query.name;
        this.actionIndex = query.nameIdx;
        this.enabled = true;

        console.log(`<> NameFilter::fromQuery: ${this.actionIndex} ${this.value}`);
      }
    },
    reset() {
      this.enabled = false;
      this.value = '';
      this.actionIndex = 0;
    },
  },
};
</script>

<style lang="sass">
</style>
