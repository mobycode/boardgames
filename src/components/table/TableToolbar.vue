<template>
<div class="row toolbar">
    <div class="col">
        <div class="row">
            <div class="col">
                <div style="display: inline-block; vertical-align: middle;">
                    <div :class="{ dropup: settingsExpanded, dropdown: !settingsExpanded }" @click="expandCollapseSettings">
                        <i class="fa fa-cogs" :class="{'fa-lg': !smallIcons}"></i>
                        <i class="fa" :class="{ 'fa-lg': !smallIcons, 'fa-caret-down': !settingsExpanded, 'fa-caret-up': settingsExpanded}"></i>
                    </div>
                </div>
                <div style="display: inline-block; vertical-align: middle;">
                    <div class="desktop-site-toggle ml-3" @click="toggleDesktopSite" :title="desktopSite ? 'Request moble site' : 'Request desktop site'">
                        <i class="fa" :class="{'fa-lg': !smallIcons, 'fa-mobile-alt': desktopSite, 'fa-desktop': !desktopSite}"></i>
                    </div>
                </div>
            </div>
            <div class="col-6 col-sm-5 col-md-4 col-lg-3 col-xl-3">
                <div class="input-group" :class="{'input-group-sm': smallIcons}">
                    <input class="form-control" id="search" placeholder="Search names" v-model="searchString" @keyup="updateSearch" type="text">
                    <div class="input-group-btn">
                        <button class="btn btn-outline-secondary" :disabled="searchString === ''" type="button" @click="clearSearch"><i class="fa fa-times"></i></button>
                    </div>
                </div>
            </div>
        </div>
        <transition name="fade" mode="out-in" v-on:after-enter="expandAfterEnter" v-on:after-leave="expandAfterLeave">
            <div class="settings" v-show="settingsExpanded">
                <ul class="nav" v-if="deviceSizeValue > 0">
                    <li class="nav-item">
                        <a class="nav-link" :class="{active: activeSettings === SETTINGS_FILTERS}" href="javascript:void(0)" @click="setActiveSettings(SETTINGS_FILTERS)">Filters</a>
                    </li>
                    <li class="nav-item">
                        <a class="nav-link" :class="{active: activeSettings === SETTINGS_PLAYS}" href="javascript:void(0)" @click="setActiveSettings(SETTINGS_PLAYS)">Plays</a>
                    </li>
                </ul>
                <div>
                    <div class="section" v-if="activeSettings === SETTINGS_FILTERS">
                        <app-filter-settings></app-filter-settings>
                    </div>
                    <div class="section" v-else>
                        <app-plays-settings></app-plays-settings>
                    </div>
                </div>
            </div>
        </transition>
    </div>
</div>
</template>

<script>
import FilterSettings from './settings/FilterSettings.vue';
import PlaysSettings from './settings/PlaysSettings.vue';

const SETTINGS_FILTERS = 'filters';
const SETTINGS_PLAYS = 'plays';

export default {
    components: {
        appFilterSettings: FilterSettings,
        appPlaysSettings: PlaysSettings
    },
    data() {
        return {
            SETTINGS_FILTERS: SETTINGS_FILTERS,
            SETTINGS_PLAYS: SETTINGS_PLAYS,
            settingsExpanded: false,
            activeSettings: SETTINGS_FILTERS,
            searchString: ''
        }
    },
    computed: {
        deviceSizeValue() {
            return this.$store.getters.deviceSizeValue;
        },
        desktopSite() {
            return this.$store.getters.desktopSite;
        },
        smallIcons() {
            return this.deviceSizeValue < 2;
        }
    },
    methods: {
        expandAfterEnter(el) {
            this.resizeTable();
        },
        expandAfterLeave(el) {
            this.resizeTable();
        },
        resizeTable() {
            this.$parent.resize();
        },
        expandCollapseSettings() {
            this.settingsExpanded = !this.settingsExpanded;
            this.activeSettings = SETTINGS_FILTERS;
        },
        setActiveSettings(selected) {
            this.activeSettings = selected;
        },
        toggleDesktopSite() {
            let content = 'width=device-width, initial-scale=1',
                viewport = document.querySelector('meta[name=viewport]');

            this.$store.dispatch('toggleDesktopSite');

            document.querySelector('meta[name=viewport]').setAttribute('content', this.desktopSite ? '' : 'width=device-width, initial-scale=1');

            /* toggling from mobile to desktop leaves page zoomed in;  need to zoom out some way
            if (this.desktopSite) {
                //viewport.setAttribute('content', content + ', maximum-scale=1, minimum-scale=1'); // force zoom-out
                viewport.content = 'initial-scale=1';
                viewport.content = 'width=device-width';
                setTimeout(() => {
                    //viewport.setAttribute('content', content);
                    //this.resizeTable();
                }, 100);
            } else {
                viewport.setAttribute('content', '');
            }
            */

            // hack to update device deviceSize
            this.$parent.$parent.setDeviceSize();
            this.resizeTable();
        },
        updateSearch() {
            if (this._oldSearchString !== this.searchString) {
                this._oldSearchString = this.searchString;
                this.$store.dispatch('updateSearch', {
                    searchString: this.searchString
                });

            }
        },
        clearSearch() {
            if (this.searchString !== '') {
                this.searchString = '';
                this.updateSearch();
            }
        }
    },
    updated() {
        if (this.oldActiveSettings !== this.activeSettings) {
            this.oldActiveSettings = this.activeSettings;
            this.resizeTable();
        }
    },
    watch: {
        deviceSizeValue(newValue) {
            if (newValue < 1) {
                this.activeSettings = SETTINGS_FILTERS;
            }
        }
    }
}
</script>

<style lang="sass">
$scrollbarWidth: 18px

.desktop .desktop-site-toggle
    display: none

.toolbar
    color: #333
    border-color: #ddd
    padding-top: 8px
    padding-bottom: 8px

    .nav-link.active
        color: #333
        font-weight: bold

    *[role=search]
        .btn-outline-secondary,
        .btn-outline-secondary:disabled
            border: 1px solid #ced4da
            i
                color: #333
        .btn-outline-secondary:disabled
                opacity: 1
                i
                    opacity:.65

    .settings
        margin-top: 8px
        margin-bottom: 8px

// TODO: fixme
.toolbar
    .col-sm
        .section
            .row + .row
                margin-top: 50px

.fade-enter-active
    animation: fade-in 200ms ease-out forwards
.fade-leave-active
    animation: fade-out 200ms ease-out forwards
@keyframes fade-in
    from
        opacity: 0
    to
        opacity: 1
@keyframes fade-out
    from
        opacity: 1
    to
        opacity: 0
</style>
