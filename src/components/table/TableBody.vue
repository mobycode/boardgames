<template>
<div class="container-fluid tbody">
    <div class="row">
        <div class="col">
            <div v-if="filteredItems.length === 0" class="no-matches">
                <div class="row tr">
                    <div class="col td text-center">No matches</div>
                </div>
            </div>
            <div v-else>
                <div id="gameImagePopup" v-show="imagePopupSrc">
                    <img :src="imagePopupSrc"></src>
                </div>
                <div v-for="(item, idx) in filteredItems" class="row tr" :class="{'bg-light': idx%2===0}">
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
</div>
</template>

<script>
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
    computed: {
        deviceSizeValue() {
            return this.$store.getters.deviceSizeValue;
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
.tbody
    /*height: calc(100vh - 110px)*/
    overflow-y: auto
    margin-bottom: 0px

    .no-matches
        font-style: italic

    .tr
        padding-top: 4px
        padding-bottom: 4px
        .td
            text-align: left
            white-space: nowrap
            overflow: hidden
            text-overflow: ellipsis

    #gameImagePopup
        position: fixed
        top: 25%
        left: 50%
        transform: translate(-50%,-50%)
        z-index: 2
</style>
