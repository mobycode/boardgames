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
    computed: {
        deviceSizeValue() {
            return this.$store.getters.deviceSizeValue;
        },
    },
    methods: {
        reset() {
            this.$children.forEach(child => {
                child.reset();
            });
            this.$store.dispatch('updateFilters', {
                filters: this.$children
            });
            this.$router.push({
                query: {}
            });
        }
    }
}
</script>

<style lang="sass">
//.col-12 + .col-12
//    margin-top: 10px

.settings
    .input-group-append
        margin-left: 0px
    .input-group>.input-group-prepend>span,
    .input-group>.input-group-append>span
        display: inline-block
        position: relative
    .input-group>.input-group-prepend>:not(:first-child)>.btn,
    .input-group>.input-group-append>:not(:last-child)>.btn
        border-top-right-radius: 0
        border-bottom-right-radius: 0
        border-top-left-radius: 0
        border-bottom-left-radius: 0
    .input-group>.input-group-prepend:not(.input-group-insert) .btn
        border-top-right-radius: 0
        border-bottom-right-radius: 0
    .input-group>.input-group-append:not(.input-group-insert) .btn
        border-top-left-radius: 0
        border-bottom-left-radius: 0
    .input-group>.input-group-prepend.only-visible-child .btn
        border-top-right-radius: .2rem
        border-bottom-right-radius: .2rem
    .input-group-sm>.input-group-prepend>span,
    .input-group-sm>.input-group-append>span
        .btn
            padding: .25rem .5rem
            font-size: .875rem
            line-height: 1.5
            border-radius: .2rem
    .input-group>.input-group-prepend.only-visible-child>.input-group-text,
    .input-group>.input-group-append.only-visible-child>.input-group-text
        border-top-right-radius: .2rem
        border-bottom-right-radius: .2rem

    .input-group-sm.input-group-xs
        .input-group-text
            min-width: 90px
    .input-group-sm
        .input-group-text.label
            min-width: 65px
    .input-group-text.label
        min-width: 80px
        background-color: #fff
    span button,
        min-width: 90px
        text-align: left

.input-group-text.label
    background-color: white
.input-group-append.input-group-insert,
.input-group-btn.input-group-insert button.btn
    border-radius: 0

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
.button-row
    margin-top: 8px
    .btn + .btn
        margin-left: 8px
</style>
