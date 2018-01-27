<template>
<div>
    <form class="row" v-on:submit.prevent>
        <div class="col-12 col-md-6 col-lg-6 mb-2">
            <app-rank-filter></app-rank-filter>
        </div>
        <div class="col-12 col-md-6 col-lg-6 mb-2">
            <app-name-filter></app-name-filter>
        </div>
        <div class="col-12 col-md-6 col-lg-6 mb-2">
            <app-weight-filter></app-weight-filter>
        </div>
        <div class="col-12 col-md-6 col-lg-6 mb-2">
            <app-player-count-filter></app-player-count-filter>
        </div>
        <div class="col-12 col-md-6 col-lg-6 mb-2">
            <app-owner-filter></app-owner-filter>
        </div>
        <div class="col-12 col-md-6 col-lg-6 mb-2">
            <app-expansion-filter></app-expansion-filter>
        </div>
    </form>
</div>
</template>

<script>
import RankFilter from '../filter/RankFilter.vue';
import NameFilter from '../filter/NameFilter.vue';
import WeightFilter from '../filter/WeightFilter.vue';
import PlayerCountFilter from '../filter/PlayerCountFilter.vue';
import OwnerFilter from '../filter/OwnerFilter.vue';
import ExpansionFilter from '../filter/ExpansionFilter.vue';

export default {
    components: {
        appRankFilter: RankFilter,
        appNameFilter: NameFilter,
        appWeightFilter: WeightFilter,
        appPlayerCountFilter: PlayerCountFilter,
        appOwnerFilter: OwnerFilter,
        appExpansionFilter: ExpansionFilter
    },
    data() {
        return {};
    },
    computed: {},
    methods: {}
}
</script>

<style lang="sass">
//.col-12 + .col-12
//    margin-top: 10px

.settings
    .multi-row.input-group-sm
        .input-group-addon
            border-right: 1px solid #ced4da
            border-bottom: 0
            border-radius: 0
        .input-group-addon:first-child
            border-top-left-radius: .2rem
            border-top-right-radius: .2rem
        .input-group-addon:last-child
            border-bottom-left-radius: .2rem
            border-bottom-right-radius: .2rem
            border-bottom: 1px solid #ced4da
        .input-group-addon.only-visible-child
            border-top-left-radius: .2rem
            border-top-right-radius: .2rem
            border-bottom-left-radius: .2rem
            border-bottom-right-radius: .2rem
            border-bottom: 1px solid #ced4da

        .form-control
            border-top: 0
            border-top-left-radius: 0
            border-top-right-radius: 0
        .input-group-btn
            margin-left: 1px
            margin-right: -1px
            .btn
                width: 100%
                border-radius: 0
        .input-group-btn:last-child
            .btn
                border-bottom-left-radius: .2rem
                border-bottom-right-radius: .2rem

    .input-group-sm
        .input-group-addon.label
            min-width: 65px
        .input-group-btn button,
        .input-group-addon.info
            min-width: 85px
    .input-group-addon.label
        min-width: 80px
        background-color: #fff
    .input-group-btn button,
    .input-group-addon.info
        min-width: 110px
        text-align: left
    .input-group.input-group-sm
        .input-group-addon
            label
                text-align: left
                min-width: 85px
        .input-group-addon.only-visible-child
            //border-top-left-radius: .2rem
            border-top-right-radius: .2rem
            border-bottom-right-radius: .2rem
            border-right: 1px solid #ced4da

.btn .caret
    margin-left: 0
.dropup .caret, .navbar-fixed-bottom .dropdown .caret
    content: ""
    border-top: 0
    border-bottom: 4px dashed
    border-bottom: 4px solid\9
.caret
    display: inline-block
    width: 0
    height: 0
    margin-left: 2px
    vertical-align: middle
    border-top: 4px dashed
    border-top: 4px solid\9
    border-right: 4px solid transparent
    border-left: 4px solid transparent
</style>
