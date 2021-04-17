<template>
<div class="row">
  <div class="col">
    <div class="input-group" :class="{'input-group-sm': deviceSizeValue < 2, 'input-group-xs': deviceSizeValue < 0}">
      <div class="input-group-prepend only-visible-child">
        <div class="input-group-text">
          <input type="checkbox" v-model="enabled" id="playedFilterCheckbox" aria-label="Enable played filter">
          <label class="d-sm-none form-check-label pl-1" for="playedFilterCheckbox">Hide played</label>
        </div>
        <div class="input-group-text label d-none d-sm-flex">Hide played</div>
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
      id: 'played',
      enabled: false,
    };
  },
  computed: {
    selectedOwner() {
      return this.$store.getters.selectedOwner;
    },
  },
  methods: {
    matches(item) {
      let matches = true;

      if (this.enabled) {
        const usersNumPlays = item?.numplays?.[this.selectedOwner] || 0;
        matches = (usersNumPlays === 0);
        // console.log('<> UnplayedFilter::matches: name [' + item.name + '] ? ' + matches);
      }

      return matches;
    },
    toQuery() {
      const unplayed = this.enabled ? undefined : 'true';
      if (this.$route.query.unplayed !== unplayed) {
        this.$router.push({
          query: { ...this.$route.query, unplayed },
        });
      }
    },
    fromQuery() {
      const { query } = this.$route;
      if (query) {
        this.enabled = (query.unplayed === 'true');
        console.log(`<> UnplayedFilter::fromQuery: ${this.enabled}`);
      }
    },
    reset() {
      this.enabled = false;
    },
  },
  watch: {
    enabled() {
      this.toQuery();
      this.filterChanged();
    },
  },
};
</script>

<style lang="sass">
</style>
