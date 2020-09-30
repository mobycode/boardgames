<script>
import {
  validationMixin,
} from 'vuelidate';

export default {
  mixins: [validationMixin],
  data() {
    return {
      id: '',
      enabled: false,
      dropdowns: [],
    };
  },
  computed: {
    deviceSizeValue() {
      return this.$store.getters.deviceSizeValue;
    },
    filtered() {
      const oldValue = this.oldfiltered;
      const newValue = this.filteredString;
      console.log(`<> Filter::filtered: ${oldValue} -> ${newValue}`);
      if (oldValue !== newValue) {
        // eslint-disable-next-line vue/no-side-effects-in-computed-properties
        this.oldfiltered = newValue;
        this.filterChanged();
      }
      return newValue;
    },
  },
  validations: {},
  created() {
    this.fromQuery();

    if (this.enabled) {
      this.filterChanged();
    }

    if (this.dropdowns && this.dropdowns.length > 0) {
      window.addEventListener('click', this.windowHandler);
    }
  },
  methods: {
    matches() {
      console.log(`${this.id} must implement matches`);
      return true;
    },
    toQuery() {
      console.log(`${this.id} must implement toQuery`);
    },
    fromQuery() {
      console.log(`${this.id} must implement fromQuery`);
    },
    reset() {
      console.log(`${this.id} must implement reset`);
    },
    filterChanged() {
      this.toQuery();
      this.$store.dispatch('updateFilters', {
        filters: [this],
      });
    },
    toggleDropdown(id) {
      if (this.dropdowns) {
        this.dropdowns.forEach((dropdown) => {
          if (dropdown.id === id) {
            // eslint-disable-next-line no-param-reassign
            dropdown.open = !dropdown.open;
          }
        });
      }
    },
    windowHandler(evt) {
      this.dropdowns.forEach((dropdown) => {
        const elem = document.getElementById(dropdown.id);
        if (!elem || !elem.contains(evt.target)) {
          // eslint-disable-next-line no-param-reassign
          dropdown.open = false;
        }
      });
    },
  },
};
</script>

<style lang="sass">
</style>
