<template>
<div class="flex-page-item flex-page-content flex-page-item-grow" v-on:scroll="onScroll">
    <div class="flex-page-item-grow">
        <div v-if="filteredItems.length === 0" class="container-fluid tbody">
            <div class="row">
                <div class="col no-matches">
                    <div class="row tr">
                        <div class="col-12 td text-center">No matches</div>
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
                                    <span><a :href="item | filterItemHref" :title="item.name" target="_blank">{{item | filterItemRank}}</a></span>
                                </div>
                                <div :class="[!!item.picture ? 'pic-picture' : 'pic-thumbnail']">
                                    <img :src="item | formatItemPictureSrc"></img>
                                </div>
                                <div class="name">
                                    <span><a :href="item | filterItemHref" :title="item.name" target="_blank">{{item.name}}</a></span>
                                </div>
                                <label for="modal-switch" class="show-game-modal" role="button" data-toggle="modal" data-target="#myModal" @click="$emit('showModal', item)">
                                    <i class="fa fa-expand-arrows-alt"></i>
                                </label>
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
import SimpleBar from 'simplebar';
import ItemFiltersMixin from './ItemFiltersMixin.vue';

import {
    mapGetters,
    mapActions
} from 'vuex'


export default {
    mixins: [ItemFiltersMixin],
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
            if (this.resizeHandle) {
                clearTimeout(this.resizeHandle);
            }
            this.resizeHandle = setTimeout(() => {
                this.cardsPerRow = undefined;
                this.updateCards();
            }, 200);
        },
        onScroll(evt) {
            if (this.scrollHandler) {
                clearTimeout(this.scrollHandler);
            }
            this.scrollHandler = setTimeout(() => {
                this.updateCards();
            }, 100);
        },
        updateCards(evt) {
            let cards = this.$el.querySelectorAll('.pic-parent img'),
                card, item, i, src, div, img;

            if (this.displayed >= this.filteredItems.length) {
                return;
            }

            /* count cards per row so we can load x new rows of  cards
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
                            console.log(`<> Pictures::updateCards: this.cardsPerRow [${this.cardsPerRow}]`);
                        }
            */

            /* if scrollbar is within x px of bottom, load new cards */
            if (this.scroller.scrollTop >= (this.scroller.scrollHeight - this.scroller.getBoundingClientRect().height - 500)) {
                let pre = this.loaded;
                //this.loaded = Math.min(this.filteredItems.length, this.loaded + (20 * this.cardsPerRow)); // TODO: load x new rows of cards?
                this.loaded = Math.min(this.filteredItems.length, this.loaded + 30); // just load 30 new cards
                console.log(`<> Pictures::updateCards: loading updated from ${pre} -> ${this.loaded}`);
            }
        }
    },
    watch: {
        displayedItems(value) {
            // when # of displayed items changes, redraw masonry and update simplebar
            this.$redrawVueMasonry()
            this.simplebar.recalculate();
        }
    },
    beforeMount() {
        // always sort by rank for this view
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
        // create simple bar and add scroll/resize events
        this.simplebar = new SimpleBar(this.$el);
        this.scroller = this.simplebar.getScrollElement();
        this.scroller.addEventListener('scroll', this.onScroll);

        window.addEventListener('resize', this.onResize);
    },
    beforeDestroy() {
        // remove event listeners
        this.scroller.removeEventListener('scroll', this.onScroll);
        window.removeEventListener('resize', this.onResize);
    }
}
</script>

<style lang="sass">
.flex-page-content
    padding-top: 8px
    padding-bottom: 0

.pic-parent
    height: auto
    .pic
        position: relative
        .rank span,
        .name span
            position: absolute
            transform: translateX(-50%)
            text-align: center

            a
                font-size: 12px
                color: white
                text-decoration: none
                //text-shadow: 2px 2px 0 #000,-2px -2px 0 #000,2px -2px 0 #000,-2px 2px 0 #000,0px 2px 0 #000,2px 0px 0 #000,0px -2px 0 #000,-2px 0px 0 #000,2px 2px 5px #000
                text-shadow: 1px 1px 0 #000,-1px -1px 0 #000,1px -1px 0 #000,-1px 1px 0 #000,0px 1px 0 #000,1px 0px 0 #000,0px -1px 0 #000,-1px 0px 0 #000,1px 1px 5px #000

        .rank span
            top: 4px
            left: 50%
        .name span
            bottom: 4px
            left: 50%
            width: 100%
            height: auto

        .pic-picture img
            width: 100%
        .pic-thumbnail
            text-align: center

/* size pictures based on screen size */
.device-xl .pic-parent
    width: 33%
.device-lg .pic-parent
    width: 33%
.device-md .pic-parent
    width: 50%
.device-sm .pic-parent
    width: 50%
.device-xs .pic-parent
    width: 100%

/* shrink font size for smaller screens */
.device-sm .pic-parent,
.device-xs .pic-parent
    .rank a,
    .name a
        font-size: 10px

/* hide zoom on mobile */
.device-xs .pic-parent label.show-game-modal
    display: none
</style>
