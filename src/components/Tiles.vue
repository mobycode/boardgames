<template>
<div class="flex-page-item flex-page-content flex-page-item-grow" data-simplebar>
    <div class="flex-page-item-grow">
        <div class="container-fluid tbody">
            <div class="row">
                <div v-if="filteredItems.length === 0" class="col no-matches">
                    <div class="row tr">
                        <div class="col td text-center">No matches</div>
                    </div>
                </div>
                <div v-else v-for="(item, idx) in filteredItems" class="col-6 col-sm-4 col-md-4 col-lg-2 text-center card-parent">
                    <div class="card">
                        <div class="rank">{{item.rank}}</div>
                        <div class="card-img-top"><img class="img-fluid" :src="item.thumbnail"></div>
                        <div class="card-body">
                            <a :href="item | formatHref" :title="item.name" target="_blank">{{ item.name }}</a>
                        </div>
                        <div class="card-footer">
                            <span class="players">{{ item | formatPlayers }}<i class="fa-users" :class="iconClassObject"></i></span>
                            <span class="time">{{ item.maxplaytime > 0 ? item.maxplaytime : item.minplaytime }}<i class="fa-clock" :class="iconClassObject"></i></span>
                        </div>
                    </div>
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
    computed: {
        deviceSizeValue() {
            return this.$store.getters.deviceSizeValue;
        },
        filteredItems() {
            return this.$store.getters.filteredItems;
        },
        selectedOwner() {
            return this.$store.getters.selectedOwner;
        },
        iconClassObject() {
            let o = {
                fa: true
            }
            if (this.deviceSizeValue < 2) {
                o['fa-sm'] = true;
                //} else if (this.deviceSizeValue > 2) {
                //    o['fa-lg'] = true;
            }
            return o;
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
        formatPlayers(item) {
            return item.minplayers + "-" + item.maxplayers;
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

<style lang="sass" scoped>
.flex-page-content
    padding-top: 8px
    padding-bottom: 8px
.card-parent
    padding-bottom: 10px
    .card
        padding-top: 12px
        //min-height: 275px
        .card-img-top
            height: 150px
        .card-body
            flex-grow: 0
            padding: 8px
            a
                overflow: hidden
                text-overflow: ellipsis
                display: -webkit-box
                -webkit-box-orient: vertical
                -webkit-line-clamp: 2 /* number of lines to show */
                line-height: 24px     /* fallback */
                max-height: 48px      /* fallback (2*line-height) + padding */
                height: 48px
        .rank
            position: absolute
            top: 12px
            left: 50%
            transform: translateX(-50%)
            color: white
            text-align: center
            //text-shadow: 2px 2px 0 #000,-2px -2px 0 #000,2px -2px 0 #000,-2px 2px 0 #000,0px 2px 0 #000,2px 0px 0 #000,0px -2px 0 #000,-2px 0px 0 #000,2px 2px 5px #000
            text-shadow: 1px 1px 0 #000,-1px -1px 0 #000,1px -1px 0 #000,-1px 1px 0 #000,0px 1px 0 #000,1px 0px 0 #000,0px -1px 0 #000,-1px 0px 0 #000,1px 1px 5px #000
        .card-footer
            background: #fff
            border-top: 0px
            padding: 0px 8px 8px 8px
            i
                padding-left: 4px
            .players
                float: left
            .time
                float: right

.device-xs, .device-sm, .device-md
    .card-parent .card
        padding-top: 8px
        .card-body
            padding: 8px 8px 8px 8px
        .card-footer
            padding: 0px 8px 6px 8px

//.card-body
//    overflow: hidden
//    a
//        text-overflow: ellipsis
</style>
