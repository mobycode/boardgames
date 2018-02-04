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
                <div v-for="(item, idx) in filteredItems" class="row tr" :class="{'bg-light': idx%2===0}">
                    <div class="td d-none d-sm-block col-sm col-md col-lg-1 col-xl-1 rank"><span :title="item | filterItemRank">{{ item | filterItemRank }}</span></div>
                    <div class="td col-6 col-sm-5 col-md-4 col-lg-3 col-xl-3 name"><span><a :href="item | filterItemHref" :title="item.name" target="_blank">{{ item.name }}</a></span></div>
                    <div class="td d-none d-sm-block col-sm col-md col-lg-1 col-xl-1 weight"><span :title="item | filterItemWeight">{{ item | filterItemWeight }}</span></div>
                    <div class="td d-none d-lg-block col-lg col-xl players">
                        <div class="row">
                            <div class="col-6 minplayers"><span :title="item.minplayers">{{ item.minplayers }}</span></div>
                            <div class="col-6 maxplayers"><span :title="item.maxplayers">{{ item.maxplayers }}</span></div>
                        </div>
                    </div>
                    <div class="td col-3 col-sm col-md d-lg-none players"><span :title="item | filterItemPlayers">{{ item | filterItemPlayers(deviceSizeValue) }}</span></div>
                    <div class="td d-none d-md-block col-md col-lg-1 col-xl-1 bestplayers"><span :title="item.bestplayersString">{{ item.bestplayersString }}</span></div>
                    <div class="td d-none d-lg-block col-lg col-xl-1 recplayers"><span :title="item.recplayersString">{{ item.recplayersString }}</span></div>
                    <div class="td col-3 col-sm col-md col-lg col-xl-1 playtime">
                        <span :title="item | filterItemPlayTime(deviceSizeValue)">{{ item | filterItemPlayTime(deviceSizeValue) }}</span>
                    </div>
                    <div class="td d-none d-md-block col-md col-lg-1 col-xl-1 numplays"><span :title="item | filterItemPlays(selectedOwner)">{{ item | filterItemPlays(selectedOwner) }}</span></div>
                    <div class="td d-none d-lg-block col-lg col-xl owners"><span :title="item.ownersString">{{ item.ownersString }}</span></div>
                </div>
            </div>
        </div>
    </div>
</div>
</template>

<script>
import ItemFiltersMixin from '../ItemFiltersMixin.vue';

import {
    mapGetters,
    mapActions
} from 'vuex'


export default {
    mixins: [ItemFiltersMixin],
    data() {
        return {}
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
</style>
