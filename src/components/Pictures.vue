<template>
<div class="flex-page-item flex-page-content flex-page-item-grow" v-on:scroll="onScroll">
    <div class="flex-page-item-grow">
        <div v-if="filteredItems.length === 0" class="container-fluid tbody">
            <div class="row">
                <div class="col no-matches">
                    <div class="row tr">
                        <div class="col td text-center">No matches</div>
                    </div>
                </div>
            </div>
        </div>
        <div v-else class="container-fluid tbody">
            <div class="row">
                <div class="col">
                    <div v-masonry transition-duration="0.3s" item-selector=".pic-parent">
                        <div v-masonry-tile v-for="(item, idx) in displayedItems" class="pic-parent">
                            <div class="pic">
                                <div class="rank">
                                    <a :href="item | formatHref" :title="item.name" target="_blank">{{item.rank | formatRank}}</a>
                                </div>
                                <div :class="{'pic-picture': !!item.picture, 'pic-thumbnail': !item.picture}">
                                    <img :src="item | formatImgSrc"></img>
                                </div>
                                <div class="name">
                                    <a :href="item | formatHref" :title="item.name" target="_blank">{{item.name}}</a>
                                </div>
                            </div>
                        </div>
                    </div>
                </div>
            </div>
        </div>
    </div>
</div>
</template>

<script>
import SimpleBar from 'SimpleBar';

import {
    mapGetters,
    mapActions
} from 'vuex'


export default {
    data() {
        return {
            loaded: 30
        };
    },
    computed: {
        deviceSizeValue() {
            return this.$store.getters.deviceSizeValue;
        },
        displayedItems() {
            return this.filteredItems.slice(0, this.displayed);
        },
        filteredItems() {
            return this.$store.getters.filteredItems;
        },
        displayed() {
            return Math.min(this.loaded, this.filteredItems.length);
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
    methods: {
        onResize(evt) {
            this.cardsPerRow = undefined;
            this.onScrollEnd();
        },
        onScroll(evt) {
            if (this.scrollHandler) {
                clearTimeout(this.scrollHandler);
            }
            this.scrollHandler = setTimeout(() => {
                this.onScrollEnd();
            }, 100);
        },
        onScrollEnd(evt) {
            let cards = this.$el.querySelectorAll('.pic-parent img'),
                card, item, i, src, div, img;

            if (this.displayed >= this.filteredItems.length) {
                return;
            }
            /*
                        if (cards.length > 0 && (this.cardsPerRow === undefined || this.cardsPerRow === 1)) {
                            let x1 = cards[0].getBoundingClientRect().left,
                                x2;
                            for (i = 1; i < this.displayed && this.cardsPerRow === undefined; i++) {
                                x2 = cards[i].getBoundingClientRect().left;
                                if (x1 < x2) {
                                    x1 = x2;
                                } else {
                                    this.cardsPerRow = i;
                                }
                            }
                            console.log(`<> Pictures::onScrollEnd: this.cardsPerRow [${this.cardsPerRow}]`);
                        }
            */
            if (this.scroller.scrollTop >= (this.scroller.scrollHeight - this.scroller.getBoundingClientRect().height - 500)) {
                let pre = this.loaded;
                //this.loaded = Math.min(this.filteredItems.length, this.loaded + (20 * this.cardsPerRow)); // TODO: FIX cardsPerRow
                this.loaded = Math.min(this.filteredItems.length, this.loaded + 30);
                console.log(`<> Pictures::onScrollEnd: loading updated from ${pre} -> ${this.loaded}`);
            }

            this.$redrawVueMasonry()
            this.simplebar.recalculate();
        },
    },
    beforeMount() {
        this.$store.dispatch('setSort', {
            sort: {
                id: 'rank',
                property: 'rank',
                type: 'number',
                ascending: true
            }
        });
    },
    mounted() {
        console.log(`<> Pictures::mounted`);
        this.simplebar = new SimpleBar(this.$el);
        this.scroller = this.$el.querySelector('.simplebar-scroll-content');
        this.scroller.addEventListener('scroll', this.onScroll);

        window.addEventListener('resize', this.onResize);
        this.onScrollEnd();
    },
    beforeDestroy() {
        console.log(`<> Pictures::beforeDestroy`);
        window.removeEventListener('resize', this.onResize);
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
        },
        formatImgSrc(item) {
            let src;
            if (item.picture) {
                src = '//cf.geekdo-images.com/images/pic' + item.picture + '_md.' + (item.pictureext || 'jpg');
            } else {
                src = item.thumbnail;
            }
            return src;
        }
    }
}
</script>

<style lang="sass" scoped>
.flex-page-content
    padding-top: 8px
    padding-bottom: 8px

.pic-parent
    .pic
        position: relative
        .rank a,
        .name a
            font-size: 12px
            color: white
            position: absolute
            transform: translateX(-50%)
            color: white
            text-decoration: none
            text-align: center
            //text-shadow: 2px 2px 0 #000,-2px -2px 0 #000,2px -2px 0 #000,-2px 2px 0 #000,0px 2px 0 #000,2px 0px 0 #000,0px -2px 0 #000,-2px 0px 0 #000,2px 2px 5px #000
            text-shadow: 1px 1px 0 #000,-1px -1px 0 #000,1px -1px 0 #000,-1px 1px 0 #000,0px 1px 0 #000,1px 0px 0 #000,0px -1px 0 #000,-1px 0px 0 #000,1px 1px 5px #000
        .rank a
            top: 4px
            left: 50%
        .name a
            bottom: 4px
            left: 50%

        .pic-picture,
        .pic-thumbnail
            //width: 500px
        .pic-picture img
            width: 100%

        .pic-thumbnail img
            //transform-origin: left
            //transform: translateX(250px) translateX(-50%)

.device-xl .pic-parent .pic
    .name a,
    .pic-picture,
    .pic-thumbnail
        width: 360px
.device-lg .pic-parent .pic
    .name a,
    .pic-picture,
    .pic-thumbnail
        width: 320px
.device-md .pic-parent .pic
    .name a,
    .pic-picture,
    .pic-thumbnail
        width: 240px
.device-sm .pic-parent .pic
    .rank a,
    .name a
        font-size: 10px
    .pic-picture,
    .pic-thumbnail
        width: 230px
.device-xs .pic-parent .pic
    .rank a,
    .name a
        font-size: 10px
    .name a,
    .pic-picture,
    .pic-thumbnail
        width: 190px

</style>
