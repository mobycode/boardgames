<template>
  <!-- eslint-disable max-len -->
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
                  <input class="form-check-input" type="radio" v-model="owned" value="human" @click="setOwned">Owned
                </label>
              </div>
              <div class="form-check dropdown-item" v-for="human of allHumans" :key="human">
                <label class="form-check-label" style="margin-left: 25px;">
                  <input type="checkbox" class="form-check-input" @click="clickOwner" v-model="owners" v-bind:value="human" :disabled="!isOwnerHuman">{{ human }}
                </label>
              </div>
              <div class="form-check dropdown-item">
                <label class="form-check-label">
                  <input class="form-check-input" type="radio" v-model="owned" value="online" @click="setOwned">Online
                </label>
              </div>
              <div class="form-check dropdown-item" v-for="site of allSites" :key="site">
                <label class="form-check-label" style="margin-left: 25px;">
                  <input type="checkbox" class="form-check-input" @click="clickOwner" v-model="owners" v-bind:value="site" :disabled="!isOwnerOnline">{{ site }}
                </label>
              </div>
              <div class="form-check dropdown-item">
                <label class="form-check-label">
                  <input class="form-check-input" type="radio" v-model="owned" value="none" @click="setOwned">Not available
                </label>
              </div>
            </div>
          </span>
        </div>
      </div>
    </div>
  </div>
  <!-- eslint-enable max-len -->
</template>

<script>
import Filter from './Filter.vue';

const OWNER_IAN = 'Ian';
const OWNER_JASON = 'Jason';
const OWNER_JOE = 'Joe';
const OWNER_JUSTIN = 'Justin';
const OWNER_BGA = 'BGA';
const OWNER_BAJ = 'BaJ';
const OWNER_YUCATA = 'Yucata';

const DROPDOWN_ID = 'ownerDropdownButtonGroup';

export default {
  mixins: [Filter],
  data() {
    const dropdowns = [{
      id: DROPDOWN_ID,
      open: false,
    }];
    const allHumans = [
      OWNER_IAN,
      OWNER_JASON,
      OWNER_JOE,
      OWNER_JUSTIN,
    ];
    const allSites = [
      OWNER_BGA,
      OWNER_BAJ,
      OWNER_YUCATA,
    ];

    return {
      id: 'owner',
      enabled: true,
      owned: 'human',
      owners: allHumans.slice(),
      sites: allSites.slice(),
      allHumans,
      allSites,
      dropdowns,
    };
  },
  computed: {
    isOwnerHuman() {
      return this.owned === 'human';
    },
    isOwnerOnline() {
      return this.owned === 'online';
    },
    ownerText() {
      let str = '';
      if (this.owned === 'none') {
        str = 'no one';
      } else {
        const len = this.owners.length;
        let all = this.allHumans;
        let allLabel = 'anyone';
        if (this.owned === 'online') {
          all = this.allSites;
          allLabel = 'online';
        }
        if (len > 0 && len < all.length) {
          str = this.owners.join(', ');
        } else {
          str = allLabel;
        }
      }
      return str;
    },
    filteredString() {
      const str = `${this.enabled}_${this.ownerText}`;
      console.log(`<> OwnerFilter::filteredString: ${str}`);
      return str;
    },
  },
  methods: {
    matches(item) {
      let matches = true;

      if (this.enabled) {
        if (this.owned !== 'none') {
          if (this.owners.length === 0) {
            matches = (item.owners.some((owner) => this.allHumans.includes(owner)));
          } else {
            matches = (item.owners.length > 0 && item.owners.some((owner) => this.owners.includes(owner)));
          }
        } else {
          matches = item.owners.length === 0;
        }
      }
      return matches;
    },
    setOwned(evt) {
      if (evt.target.value === 'human') {
        this.owners = this.allHumans.slice();
      } else if (evt.target.value === 'online') {
        this.owners = this.allSites.slice();
      } else if (evt.target.value === 'none') {
        this.owners = [];
      }
    },
    clickOwner(evt) {
      const { value } = evt.target;
      const { checked } = evt.target;
      const idx = this.owners.indexOf(value);
      if (checked && idx === -1) {
        this.owners.push(value);
      } else if (!checked && idx !== -1) {
        this.owners.splice(idx, 1);
      }
    },
    toQuery() {
      const query = {};
      let update = false;
      let owners;

      const ownersChanged = (oldOwners, newOwners) => {
        const valueToComparable = (value) => {
          let array = value;
          if (array && !Array.isArray(array)) {
            array = [array];
          }
          return JSON.stringify(array);
        };
        return valueToComparable(oldOwners) !== valueToComparable(newOwners);
      };

      if (this.enabled) {
        if (this.owned !== 'none') {
          if (this.owned === 'human') {
            if (this.owners.length !== this.allHumans.length) {
              owners = this.owners.slice();
            }
          } else {
            owners = this.owners.slice();
          }
          update = ownersChanged(this.$route.query[this.id], owners);
        } else {
          owners = 'none';
          update = (this.$route.query[this.id] !== owners);
        }
      } else {
        owners = undefined;
        update = (this.$route.query[this.id] !== owners);
      }

      query[this.id] = owners;

      if (update) {
        this.$router.push({
          query: { ...this.$route.query, ...query },
        });
      }
    },
    fromQuery() {
      const { query } = this.$route;
      let val;

      if (query) {
        val = query[this.id];
        if (val !== undefined) {
          this.enabled = true;
          if (val === 'none') {
            this.owned = 'none';
            this.owners = [];
          } else {
            if (!Array.isArray(val)) {
              val = [val];
            }
            this.owned = this.allSites.includes(val[0]) ? 'online' : 'human';
            this.owners = val.slice();
          }

          console.log(`<> OwnerFilter::fromQuery: ${this.owned} ${this.owners}`);
        }
      }
    },
    reset() {
      this.enabled = true;
      this.owned = 'human';
      this.owners = this.allHumans.slice();
    },
  },
};
</script>

<style lang="sass">
</style>
