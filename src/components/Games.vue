<template>
<div class="row">
    <div class="col page-col">
        <div class="flex-page-container" :style="heightStyle">
            <div class="flex-page-item">
                <app-toolbar></app-toolbar>
            </div>
            <router-view v-on:showModal="showModal"></router-view>
            <div class="flex-page-item">
                <app-footer></app-footer>
            </div>
        </div>
    </div>
    <!-- Modal -->
    <div class="game-modal">
        <input type="checkbox" id="modal-switch" />
        <div class="modal fade" id="myModal" tabindex="-1" role="dialog" aria-labelledby="myModalLabel">
            <label for="modal-switch" class="modal-backdrop fade"></label>
            <div class="modal-dialog" role="document">
                <div class="modal-content">
                    <label for="modal-switch" class="modal-close" role="button" data-toggle="modal" data-target="#myModal" @click="onClickUnzoom($event)">
                        <i class="fa fa-lg fa-times"></i>
                    </label>
                    <div class="modal-body">
                        <img src=""></img>
                    </div>
                </div>
            </div>
        </div>
    </div>
</div>
</template>

<script>
import Toolbar from './Toolbar.vue';
import Footer from './Footer.vue';
import ItemFiltersMixin from './ItemFiltersMixin.vue';


export default {
    mixins: [ItemFiltersMixin],
    components: {
        appToolbar: Toolbar,
        appFooter: Footer
    },
    computed: {
        mobileHeight() {
            return this.$store.getters.mobileHeight;
        },
        heightStyle() {
            let style = '';
            if (/iphone|ipad/i.test(navigator.userAgent)) {
                style = 'height:' + this.mobileHeight + 'px;'
                //alert(style);
            }
            return style;
        }
    },
    methods: {
        showModal(item) {
            const modal = document.body.querySelector('.modal-body');
            modal.classList.add(item.picture ? 'pic-picture' : 'pic-thumbnail');
            modal.querySelector('img').src = this.$options.filters.formatItemPictureSrc(item);
        },
        hideModal() {
            const modal = this.$el.querySelector('.modal-body');
            modal.classList.remove('pic-picture', 'pic-thumbnail');
            modal.querySelector('img').src = '';
        }
    }
}
</script>

<style lang="sass">
$verticalMargin: 15px

// iPhone X
@media only screen and (max-width : 450px)
    .page-col
        //padding: 0px

.desktop .flex-page-container
    height: calc(100vh - #{$verticalMargin * 2})
.flex-page-container,
.flex-container
    box-sizing: border-box
    display: flex
    flex-direction: column
    justify-content: flex-start /* align items in Main Axis */
    align-items: stretch /* align items in Cross Axis */
    align-content: stretch /* Extra space in Cross Axis */
    .flex-page-item
        display: flex
        flex-direction: column
        flex-grow: 0
        flex-shrink: 0
        flex-basis: auto
        background: rgba(255, 255, 255, 0.1)
    .flex-page-item-grow
        /* let body grow to fill page if needed */
        display: flex
        flex-direction: column
        flex-shrink: 1
        flex-grow: 0
        flex-basis: auto
        min-height: 0
        //width: 100%

    .flex-page-content
        flex-direction: row
        justify-content: flex-start /* align items in Main Axis */
        align-items: stretch /* align items in Cross Axis */
        align-content: stretch /* Extra space in Cross Axis */

.flex-page-item > .container-fluid > .row > .col,
.flex-page-item-grow > .container-fluid > .row > .col,
    padding-right: 0px
    padding-left: 0px


.device-xl .game-modal .modal-dialog
    max-width: calc(50vw)
.device-lg .game-modal .modal-dialog
    max-width: calc(66vw)
.device-md .game-modal .modal-dialog
    max-width: calc(85vw)
.device-sm .game-modal .modal-dialog
    max-width: calc(100vw - 15px)

.game-modal
    position: absolute

    .modal
        display: block

        .modal-backdrop
            margin: 0

        .modal-dialog
            box-sizing: border-box
            margin: 30

            .modal-close
                display: block
                position: absolute
                top: 30px
                right: 35px
                z-index: 1001
                text-shadow: 1px 1px 0 #000,-1px -1px 0 #000,1px -1px 0 #000,-1px 1px 0 #000,0px 1px 0 #000,1px 0px 0 #000,0px -1px 0 #000,-1px 0px 0 #000,1px 1px 5px #000
                //text-shadow: 1px 1px 1px black
                color: white

            .modal-body
                img
                    width: 100%

    #modal-switch
        display: none

    #modal-switch:not(:checked) ~ .modal
        // In Bootstrap Model is hidden by `display: none`.
        // Unfortunately I couldn't get this option to work with css transitions
        // (they are disabled when `display: none` is present).
        // We need other way to hide the modal, e.g. with `max-width`.
        max-width: 0

    #modal-switch:checked ~ .fade,
    #modal-switch:checked ~ .modal .fade
        opacity: 1

    #modal-switch:not(:checked) ~ .modal .modal-backdrop
        display: none

    #modal-switch:checked ~ .modal .modal-backdrop
        filter: alpha(opacity=50)
        opacity: 0.7

    /* DIALOG */
    #modal-switch ~ .modal .modal-dialog
        transition: transform .3s ease-out
        transform: translate(0, -50%)

    #modal-switch:checked ~ .modal .modal-dialog
        transform: translate(0, 15px)
        z-index: 1050

label.show-game-modal
    background-color: transparent
    border: none
    margin: 0px
    padding: 0px
    position: absolute
    top: 4px
    right: 8px
    text-shadow: 1px 1px 0 #000,-1px -1px 0 #000,1px -1px 0 #000,-1px 1px 0 #000,0px 1px 0 #000,1px 0px 0 #000,0px -1px 0 #000,-1px 0px 0 #000,1px 1px 5px #000
    //text-shadow: 1px 1px 1px black
    color: white
</style>
