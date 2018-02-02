<template>
<div class="row">
    <div class="col page-col">
        <div class="flex-page-container" :style="heightStyle">
            <div class="flex-page-item">
                <app-toolbar></app-toolbar>
            </div>
            <router-view></router-view>
            <div class="flex-page-item">
                <app-footer></app-footer>
            </div>
        </div>
    </div>
</div>
</template>

<script>
import Toolbar from './Toolbar.vue';
import Footer from './Footer.vue';


export default {
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
</style>
