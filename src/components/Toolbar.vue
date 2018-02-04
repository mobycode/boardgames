<template>
<div class="container-fluid">
    <div class="row">
        <div class="col">
            <div class="row">
                <div class="col toolbar">
                    <div style="display: inline-block; vertical-align: middle;">
                        <button type="button" class="settings-menu btn" @click="expandCollapseSettings">
                            <div :class="{ dropup: settingsExpanded, dropdown: !settingsExpanded }" :title="settingsExpanded ? 'Hide settings' : 'Show settings'">
                                <i class="fas fa-cogs" :class="{'fa-lg': !smallIcons}"></i>
                                <i class="fas" :class="{ 'fa-lg': !smallIcons, 'fa-caret-down': !settingsExpanded, 'fa-caret-up': settingsExpanded}"></i>
                            </div>
                        </button>
                    </div>
                    <div class="reset-filter" :class="{'reset-filter-disabled': !filtered}" style="display: inline-block; vertical-align: middle;" title="Reset filters">
                        <button type="button" class="btn" :disabled="!filtered" @click="resetSettings">
                            <span class="fas fa-stack" :class="{'fa-lg': !smallIcons}">
                                <i class="fas fa-filter fa-filter-clear fa-stack-1x"></i>
                                <i class="fas fa-ban fa-stack-1x"></i>
                            </span>
                        </button>
                    </div>
                    <div class="btn-toolbar view-toggle" role="toolbar" aria-label="Toolbar with button groups">
                        <div class="btn-group mr-2" role="group" aria-label="First group">
                            <button type="button" class="btn" :class="{'btn-outline-secondary': viewName !== 'table'}" :disabled="viewName === 'table'" @click="onTable" :title="viewName !== 'table' ? 'Switch to table view' : ''"><i class="fas fa-table" :class="{'fa-lg': !smallIcons}"></i></button>
                            <button type="button" class="btn" :class="{'btn-outline-secondary': viewName !== 'tiles'}" :disabled="viewName === 'tiles'" @click="onTiles" :title="viewName !== 'tiles' ? 'Switch to tile view' : ''"><i class="fas fa-th" :class="{'fa-lg': !smallIcons}"></i></button>
                            <button type="button" class="btn" :class="{'btn-outline-secondary': viewName !== 'image'}" :disabled="viewName === 'image'" @click="onImage" :title="viewName !== 'image' ? 'Switch to picture view' : ''"><i class="fas fa-images" :class="{'fa-lg': !smallIcons}"></i></button>
                        </div>
                    </div>
                    <div style="display: inline-block; vertical-align: middle;">
                        <div class="desktop-site-toggle" @click="toggleDesktopSite" :title="desktopSite ? 'Request moble site' : 'Request desktop site'">
                            <i class="fa" :class="{'fa-lg': !smallIcons, 'fa-mobile-alt': desktopSite, 'fa-desktop': !desktopSite}"></i>
                        </div>
                    </div>
                </div>
                <div class="col-5 col-sm-5 col-md-4 col-lg-3 col-xl-3">
                    <div class="input-group" :class="{'input-group-sm': smallIcons}">
                        <input class="form-control" id="search" placeholder="Search names" v-model="searchString" type="text">
                        <div class="input-group-append">
                            <button class="btn btn-outline-secondary" :disabled="searchString === ''" type="button" @click="searchString = ''"><i class="fas fa-times"></i></button>
                        </div>
                    </div>
                </div>
            </div>
            <transition name="fade" mode="out-in">
                <div class="settings" v-show="settingsExpanded">
                    <ul class="nav" v-if="deviceSizeValue > 0">
                        <li class="nav-item">
                            <a class="nav-link" :class="{active: activeSettings === SETTINGS_FILTERS}" href="javascript:void(0)" @click="setActiveSettings(SETTINGS_FILTERS)" :title="activeSettings !== SETTINGS_FILTERS ? 'Show filter settings' : ''">Filters</a>
                        </li>
                        <li class="nav-item">
                            <a class="nav-link" :class="{active: activeSettings === SETTINGS_PLAYS}" href="javascript:void(0)" @click="setActiveSettings(SETTINGS_PLAYS)" :title="activeSettings !== SETTINGS_PLAYS ? 'Show plays logged settings' : ''">Plays</a>
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
            activeSettings: SETTINGS_FILTERS
        }
    },
    computed: {
        searchString: {
            get() {
                return this.$store.state.searchString;
            },
            set(value) {
                this.$store.dispatch('updateSearch', {
                    searchString: value,
                    router: this.$router // pass router so store can update query
                });
            }
        },
        deviceSizeValue() {
            return this.$store.getters.deviceSizeValue;
        },
        desktopSite() {
            return this.$store.getters.desktopSite;
        },
        smallIcons() {
            return this.deviceSizeValue < 2;
        },
        viewName() {
            return this.$route.name;
        },
        filtered() {
            let entries = Object.entries(this.$route.query);
            let filtered = entries.filter((entry) => {
                return entry[1] !== undefined;
            });
            console.warn(`entries [${entries.length}] -> filtered [${filtered.length}]`);
            return filtered.length !== 0;
        }
    },
    methods: {
        expandCollapseSettings() {
            this.settingsExpanded = !this.settingsExpanded;
            this.activeSettings = SETTINGS_FILTERS;
        },
        setActiveSettings(selected) {
            this.activeSettings = selected;
        },
        onTable() {
            this.$router.push({
                name: 'table'
            });
        },
        onTiles() {
            this.$router.push({
                name: 'tiles'
            });
        },
        onImage() {
            this.$router.push({
                name: 'image'
            });
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
                }, 100);
            } else {
                viewport.setAttribute('content', '');
            }
            */

            // hack to update device deviceSize
            this.$parent.$parent.setDeviceSize();
        },
        resetSettings() {
            this.searchString = '';
            this.$children.forEach((child) => {
                child.reset();
            });
        }
    },
    updated() {
        if (this.oldActiveSettings !== this.activeSettings) {
            this.oldActiveSettings = this.activeSettings;
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
.desktop .desktop-site-toggle
    display: none

.toolbar
    color: #333
    border-color: #ddd
    padding-bottom: 8px
    overflow: visible

    .settings-menu .dropup
        color: #0056b3

    .btn
        box-shadow: none !important
        background: none
        border: 0px
        padding-right: 8px
        padding-left: 8px
    .settings-menu.btn
        padding-left: 0px
    .reset-filter.reset-filter-disabled>span>i
        color: #333
    .view-toggle
        display: inline
        .btn + .btn
            padding-left: 0px
        .btn
            box-shadow: none !important
        .btn:focus
            i
                color: #0056b3
        .btn,
        .btn:focus,
        .btn:active,
        .btn.active
            background-color: #fff
            color: #0056b3
        .btn.btn-outline-secondary
            color: #000
            border: 0

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

.nav-link.active
    color: #333
    font-weight: bold

.settings
    margin-bottom: 8px

// TODO: fixme
.toolbar
    .col-sm
        .section
            .row + .row
                margin-top: 50px

body.kb-nav-used .view-toggle .btn:focus i
    outline: -webkit-focus-ring-color auto 5px

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

.fas.fa-stack
    width: 1rem
    height: 1rem
    line-height: 1rem
    font-size: 1rem
.fas.fa-filter-clear
   color: transparent
   -webkit-text-stroke-width: 2px
   -webkit-text-stroke-color: #333

</style>
