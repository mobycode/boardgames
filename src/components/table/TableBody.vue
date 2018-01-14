<template>
<div class="row tbody">
    <div class="col" :class="{loading: loading}">
        <div v-if="loading" class="text-center">
            <i class="fa fa-spinner fa-spin fa-2x fa-fw"></i>
            <span class="sr-only">Loading...</span>
        </div>
        <div v-else-if="loadError" class="row justify-content-center">
            <div class="col-10 col-sm-8 col-md-6 col-lg-4 alert alert-danger load-error" role="alert">
                <h5 class="alert-heading">Error loading games</h5>
                <hr>
                <p>An error occurred retrieving games from the database. This is probably your fault.</p>
                <p>Ensure your browser is not blocking database requests and reload the page.</p>
                <p class="mb-0">Again, I blame you. Bad, user! Bad!</p>
            </div>
        </div>
        <div v-else>
            <div id="gameImagePopup" v-show="imagePopupSrc">
                <img :src="imagePopupSrc"></src>
            </div>
            <div v-if="filteredItems.length === 0" class="row tr nomatches">
                <div class="td col-12 text-center text-muted">No matches</div>
            </div>
            <div v-for="(item, idx) in filteredItems" class="row tr" :class="{'bg-light': idx%2===0}" v-else>
                <div class="td d-none d-sm-block col-sm col-md col-lg-1 col-xl-1 rank"><span :title="item.rank | formatRank">{{ item.rank | formatRank }}</span></div>
                <div class="td col-6 col-sm-5 col-md-4 col-lg-3 col-xl-3 name"><span><a :href="item | formatHref" :title="item.name" target="_blank" @mouseenter="showImagePopup(item, $event)" @mouseout="hideImagePopup(item, $event)">{{ item.name }}</a></span></div>
                <div class="td d-none d-sm-block col-sm col-md col-lg-1 col-xl-1 weight"><span :title="item.weight | formatWeight">{{ item.weight | formatWeight }}</span></div>
                <div class="td d-none d-lg-block col-lg col-xl players">
                    <div class="row">
                        <div class="col-6 minplayers"><span :title="item.minplayers">{{ item.minplayers }}</span></div>
                        <div class="col-6 maxplayers"><span :title="item.maxplayers">{{ item.maxplayers }}</span></div>
                    </div>
                </div>
                <div class="td col-3 col-sm col-md d-lg-none players"><span :title="item | formatPlayers">{{ item | formatPlayers(deviceSizeValue) }}</span></div>
                <div class="td d-none d-md-block col-md col-lg-1 col-xl-1 bestplayers"><span :title="item.bestplayersString">{{ item.bestplayersString }}</span></div>
                <div class="td d-none d-lg-block col-lg col-xl-1 recplayers"><span :title="item.recplayersString">{{ item.recplayersString }}</span></div>
                <div class="td col-3 col-sm col-md col-lg col-xl-1 playtime">
                    <span :title="item | formatPlayTime">{{ item | formatPlayTime }}</span>
                </div>
                <div class="td d-none d-md-block col-md col-lg-1 col-xl-1 numplays"><span :title="item.numplays ? item.numplays[selectedOwner] : ''">{{ item.numplays ? item.numplays[selectedOwner] : "" }}</span></div>
                <div class="td d-none d-lg-block col-lg col-xl owners"><span :title="item.ownersString">{{ item.ownersString }}</span></div>
            </div>
        </div>
    </div>
</div>
</template>

<script>
import VueSlider from 'vue-slider-component';

import {
    mapGetters,
    mapActions
} from 'vuex'


export default {
    data() {
        return {
            imagePopupSrc: null
        }
    },
    components: {
        vueSlider: VueSlider
    },
    computed: {
        deviceSizeValue() {
            return this.$store.getters.deviceSizeValue;
        },
        loadError() {
            return this.$store.getters.loadError;
        },
        loading() {
            return !this.loadError && this.$store.getters.items.length === 0;
        },
        filteredItems() {
            return this.$store.getters.filteredItems;
        },
        selectedOwner() {
            return this.$store.getters.selectedOwner;
        }
    },
    methods: {
        showImagePopup(item, evt) {
            return; // temporarily disable
            let style = document.getElementById("gameImagePopup").style,
                x = evt.clientX,
                y = evt.clientY;

            if (this.imagePopupTimeout) {
                clearTimeout(this.imagePopupTimeout);
            }

            this.imagePopupTimeout = setTimeout(() => {
                this.imagePopupSrc = item.thumbnail;
            }, 250);
        },
        hideImagePopup(item, evt) {
            if (this.imagePopupTimeout) {
                clearTimeout(this.imagePopupTimeout);
            }

            if (this.imagePopupSrc === item.thumbnail) {
                this.imagePopupSrc = undefined;
            }
        }
    },
    filters: {
        formatRank(rank) {
            return rank === -1 ? '' : rank;
        },
        formatHref: function(item) {
            return 'https://boardgamegeek.com/boardgame/' + item.objectid + '/';
        },
        formatWeight(weight) {
            return weight.toFixed(2);
        },
        formatPlayers(item, deviceSizeValue) {
            return item.minplayers + (deviceSizeValue < 1 ? "-" : " - ") + item.maxplayers;
        },
        formatPlays(item) {
            return item.numplays || "";
        },
        formatPlayTime(item, deviceSizeValue) {
            let str = '',
                t = item.maxplaytime > 0 ? item.maxplaytime : item.minplaytime,
                h, m;

            if (t > 0) {
                h = Math.floor(t / 60);
                m = t % 60;
                str = '' + (h < 10 ? '0' : '') + h + ':' + (m < 10 ? '0' : '') + m;
            } else {
                console.log('formatPlayTime: ' + item.name + ' - ' + item.minplaytime + "-" + item.maxplaytime);
            }
            /*
                        let str = "",
                            min = item.minplaytime,
                            max = item.maxplaytime;
                        if (!(min === -1 && max === -1)) {
                            if (item.minplaytime === item.maxplaytime) {
                                str = item.maxplaytime;
                            } else {
                                str = item.minplaytime + (deviceSizeValue < 0 ? "-" : " - ") + item.maxplaytime;
                            }
                        }
            */
            return str;
        }
    }
}
</script>

<style lang="sass">
$miscHeight: 200px
$headerHeight: 56px
$scrollbarWidth: 18px

.tbody
    /*height: calc(100vh - 110px)*/
    overflow-y: auto
    margin-bottom: 0px

    .tr.nomatches
        font-style: italic
        padding-top: 8px
        padding-bottom: 8px

    .tr
        padding-top: 4px
        padding-bottom: 4px
        .td
            text-align: left
            white-space: nowrap
            overflow: hidden
            text-overflow: ellipsis
    .loading
        overflow-y: hidden
        padding: 8px 0px

    .alert.alert-danger.load-error
        margin-top: 1rem

    #gameImagePopup
        position: fixed
        top: 25%
        left: 50%
        transform: translate(-50%,-50%)
        z-index: 2
</style>
