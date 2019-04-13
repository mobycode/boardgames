<template>
<div class="container-fluid thead" :class="{ 'sort-descending': isSortDescending }">
    <div class="row">
        <div class="th sortable d-none d-sm-block col-sm col-md col-lg-1 col-xl-1" @click="sortBy('rank')"><span :class="{ sorted: isSorted('rank') }">Rank</span></div>
        <div class="th sortable col-6 col-sm-5 col-md-4 col-lg-3 col-xl-3" @click="sortBy('name')"><span :class="{ sorted: isSorted('name') }">Name</span></div>
        <div class="th sortable d-none d-sm-block col-sm col-md col-lg-1 col-xl-1" @click="sortBy('weight')"><span :class="{ sorted: isSorted('weight') }">Wei<wbr>ght</span></div>
        <div class="th d-none d-lg-block col-lg col-xl">
            <div class="row">
                <div class="col">Players</div>
            </div>
            <div class="row">
                <div class="sortable col-6" @click="sortBy('minplayers')"><span :class="{ sorted: isSorted('minplayers') }">Min</span></div>
                <div class="sortable col-6" @click="sortBy('maxplayers')"><span :class="{ sorted: isSorted('maxplayers') }">Max</span></div>
            </div>
        </div>
        <div class="th sortable col-3 col-sm col-md d-lg-none" @click="sortBy('players')"><span :class="{ sorted: isSorted('players') }">Play<wbr>ers</span></div>
        <div class="th sortable d-none d-md-block col-md col-lg-1 col-xl-1" @click="sortBy('bestplayers')"><span :class="{ sorted: isSorted('bestplayers') }">Best</span></div>
        <div class="th sortable d-none d-lg-block col-lg col-xl-1" @click="sortBy('recplayers')"><span :class="{ sorted: isSorted('recplayers') }">Recom<wbr>mended</span></div>
        <div class="th sortable col-3 col-sm col-md col-lg col-xl-1" @click="sortBy('maxplaytime')"><span :class="{ sorted: isSorted('maxplaytime') }">Play<br>Time</span></div>
        <div class="th sortable d-none d-md-block col-md col-lg-1 col-xl-1" @click="sortBy('numplays')" v-if="showNumPlays"><span :class="{ sorted: isSorted('numplays') }">Plays<br><a href="javascript:void(0)" @click.stop="toggleOwner()">{{ selectedOwner }}</a></span></div>
        <div class="th sortable d-none d-md-block col-md col-lg col-xl-1" @click="sortBy('lastplayed')" v-else><span :class="{ sorted: isSorted('lastplayed') }">Played<br><a href="javascript:void(0)" @click.stop="toggleOwner()">{{ selectedOwner }}</a></span></div>
        <div class="th sortable d-none d-lg-block col-lg col-xl" @click="sortBy('owners')"><span :class="{ sorted: isSorted('owners') }">Owners</span></div>
    </div>
</div>
</template>

<script>
import {
    mapGetters,
    mapActions
} from 'vuex'

const SORTS = {
    rank: 'rank',
    name: {
        id: 'name',
        type: 'string'
    },
    weight: {
        id: 'weight',
        property: 'weightString',
        type: 'string'
    },
    minplayers: 'minplayers',
    maxplayers: 'maxplayers',
    players: {
        id: 'players',
        properties: ['minplayers', 'maxplayers']
    },
    bestplayers: {
        id: 'bestplayers',
        property: 'bestplayersString',
        type: 'string'
    },
    recplayers: {
        id: 'recplayers',
        property: 'recplayersString',
        type: 'string'
    },
    maxplaytime: 'maxplaytime',
    numplays: 'numplays',
    lastplayed: 'lastplayed',
    owners: {
        id: 'owners',
        property: 'ownersString',
        type: 'string'
    }
}


export default {
    data() {
        return {}
    },
    computed: {
        showNumPlays() {
            return this.$store.getters.showNumPlays;
        },
        sortId() {
            return this.$store.getters.sortId;
        },
        isSortDescending() {
            return this.$store.getters.isSortDescending;
        },
        selectedOwner() {
            return this.$store.getters.selectedOwner;
        }
    },
    methods: {
        sortBy(id) {
            this.$store.dispatch('setSort', {
                sort: SORTS[id]
            });
        },
        isSorted(id) {
            return this.sortId === id;
        },
        toggleOwner() {
            this.$store.dispatch('toggleSelectedOwner', {
                router: this.$router // pass router so store can update query
            });
        }
    }
}
</script>

<style lang="sass">

.thead
    color: #333
    /*background-color: #f5f5f5*/
    border-color: #ddd
    /* border-top: 1px solid #e9ecef*/
    border-bottom: 2px solid #e9ecef
    padding-top: 8px
    padding-bottom: 8px

    .th
        display: inline-block
        font-weight: bold
        overflow: hidden
        text-overflow: ellipsis

    .sortable
        cursor: pointer

        span
            position: relative
        span.sorted::after
            display: block
            position: absolute
            right: -15px
            top: 4px
            /* copied styles for .fas */
            font-weight: 900
            font-family: Font Awesome\ 5 Free
            -moz-osx-font-smoothing: grayscale
            -webkit-font-smoothing: antialiased
            display: inline-block
            font-style: normal
            font-variant: normal
            text-rendering: auto
            line-height: 1
            content: "\f0d7"

.thead.sort-descending
    .sortable
        span.sorted::after
            content: "\f0d8"
</style>
