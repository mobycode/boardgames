<template>
<div class="flex-page-item flex-page-content flex-page-item-grow" v-on:scroll="onScroll" DELETEME-data-simplebar>
    <div class="flex-page-item-grow">
        <div class="container-fluid tbody" ref="nonSimpleBarScroller">
            <div class="row">
                <div v-if="filteredItems.length === 0" class="col no-matches">
                    <div class="row tr">
                        <div class="col td text-center">No matches</div>
                    </div>
                </div>
                <div v-else v-for="(item, idx) in filteredItems" class="col-6 col-sm-4 col-md-4 col-lg-2 text-center card-parent">
                    <div class="card">
                        <div class="rank">{{item | filterItemRank}}</div>
                        <label for="modal-switch" class="show-game-modal" role="button" data-toggle="modal" data-target="#myModal" @click="$emit('showModal', item)">
                            <i class="fa fa-image"></i>
                        </label>
                        <div class="card-img-top"><img class="img-fluid" :src="''"></div>
                        <div class="card-body">
                            <a :href="item | filterItemHref" :title="item.name" target="_blank">{{ item.name }}</a>
                        </div>
                        <div class="card-footer">
                            <span class="players">{{ item | filterItemPlayers }}<i class="fa-users" :class="iconClassObject"></i></span>
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
import SimpleBar from 'SimpleBar';
import ItemFiltersMixin from './ItemFiltersMixin.vue';

import {
    mapGetters,
    mapActions
} from 'vuex'


export default {
    mixins: [ItemFiltersMixin],
    data() {
        return {
          useSimpleBar: true
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
            let cards = this.$el.querySelectorAll('.card-parent'),
                card, item, i;
            if (cards.length > 0 && (this.cardHeight === undefined || this.cardsPerRow === undefined)) {
                if (this.cardHeight === undefined) {
                    this.cardHeight = cards[0].getBoundingClientRect().height;
                }
                if (this.cardsPerRow === undefined) {
                    let x1 = cards[0].getBoundingClientRect().left,
                        x2;
                    for (i = 1; i < cards.length && this.cardsPerRow === undefined; i++) {
                        x2 = cards[i].getBoundingClientRect().left;
                        if (x1 < x2) {
                            x1 = x2;
                        } else {
                            this.cardsPerRow = i;
                        }
                    }
                    if (this.cardsPerRow === undefined) {
                        this.cardsPerRow = i;
                    }
                }
                console.log(`<> Tiles::updateCards: this.cardHeight [${this.cardHeight}] this.cardsPerRow [${this.cardsPerRow}]`);
            }

            if (this.cardHeight === undefined || this.cardsPerRow === undefined) {
                return;
            }

            var scrollerRect, scrollerTop, scrollerHeight, minBottom, maxTop, cardRect, cardTop, img, src, done;

            if (this.useSimpleBar) {
                scrollerRect = this.scroller.getBoundingClientRect();
                scrollerTop = scrollerRect.top,
                scrollerHeight = scrollerRect.height;
            } else {
                scrollerTop = this.scroller.scrollTop;
                scrollerHeight = this.scroller.clientHeight;
            }
            minBottom = (scrollerTop - scrollerHeight);
            maxTop = (scrollerTop + (2 * scrollerHeight));

            //console.log(`<> Tiles::updateCards: minBottom [${minBottom}] maxTop [${maxTop}]`);

            for (i = 0; i < cards.length && i < this.filteredItems.length && !done; i++) {
                cardRect = cards[i].getBoundingClientRect();
                img = cards[i].querySelector('img');
                src = this.filteredItems[i].thumbnail;
                if (cardRect.bottom > minBottom) {
                    //console.log(`  cardRect.top [${cardRect.top}] passes ${this.filteredItems[i].rank}`);
                    if (cardRect.top < maxTop) {
                        //console.log(`  setting thumbnail for ${this.filteredItems[i].rank}`);
                        img.setAttribute('src', src);
                    } else {
                        //console.log(`  cardRect.bottom [${cardRect.bottom}] failed check ${this.filteredItems[i].rank}`);
                        done = true;
                    }
                } else {
                    img.setAttribute('src', src);
                }
            }
        }
    },
    watch: {
        filteredItems(value) {
            // when # of displayed items changes, update image src attributes and update simplebar
            this.updateCards();
            if (this.simplebar) {
                this.simplebar.recalculate();
            }
        }
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
        //console.log(`<> Tiles::mounted`);
        if (this.useSimpleBar) {
            this.simplebar = new SimpleBar(this.$el);
            this.scroller = this.simplebar.getScrollElement();
        } else {
            this.scroller = this.$refs.nonSimpleBarScroller;
        }
        this.scroller.addEventListener('scroll', this.onScroll);

        window.addEventListener('resize', this.onResize);
        this.updateCards();
    },
    beforeDestroy() {
        //console.log(`<> Tiles::beforeDestroy`);
        window.removeEventListener('resize', this.onResize);
    }
}
</script>

<style lang="sass" scoped>
.flex-page-content
    padding-top: 8px
    padding-bottom: 0
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
</style>
