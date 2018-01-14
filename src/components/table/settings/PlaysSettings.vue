<template>
<div class="row">
    <div class="col">
        <div :class="[ deviceSizeValue < 0 ? 'input-group-sm' : 'input-group']">
            <span class="input-group-addon label">Plays logged by</span>
            <div class="input-group-btn" id="playsDropdownButtonGroup" :class="{ show: dropdownOpen }">
                <button type="button" class="btn btn-secondary dropdown-toggle" data-toggle="dropdown-plays" aria-haspopup="true" :aria-expanded="dropdownOpen" @click="toggleDropdown">{{ selectedOwner }}</button>
                <div class="dropdown-menu" :class="{ show: dropdownOpen }">
                    <a v-for="owner in allOwners " class="dropdown-item " href="javascript:void(0);" @click="setSelectedOwner(owner) ">{{ owner }}</a>
                </div>
            </div>
        </div>
    </div>
</div>
</template>

<script>
export default {
    data() {
        return {
            dropdownOpen: false
        }
    },
    computed: {
        deviceSizeValue() {
            return this.$store.getters.deviceSizeValue;
        },
        allOwners() {
            return this.$store.getters.allOwners;
        },
        selectedOwner() {
            return this.$store.getters.selectedOwner;
        }
    },
    methods: {
        toggleDropdown() {
            //console.log("<> NameFilter::toggleDropdown");
            this.dropdownOpen = !this.dropdownOpen;
        },
        setSelectedOwner(owner) {
            let oldOwner = this.selectedOwner;
            this.dropdownOpen = false;
            if (oldOwner !== owner) {
                this.$store.dispatch('setSelectedOwner', {
                    owner: owner
                });
            }
        }
    },
    created() {
        window.addEventListener('click', (evt) => {
            let elem = document.getElementById('playsDropdownButtonGroup');
            if (!elem || !elem.contains(evt.target)) {
                this.dropdownOpen = false;
            }
        })
    }
}
</script>

<style lang="sass">
</style>
