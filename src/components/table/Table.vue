<template>
<div class="row">
    <div class="col" :class="classObject">
        <div class="flex-table-container">
            <div class="flex-table-item">
                <app-table-toolbar></app-table-toolbar>
            </div>
            <div class="flex-table-item">
                <app-table-header></app-table-header>
            </div>
            <div class="flex-table-item flex-table-body flex-table-item-grow" data-simplebar>
                <div class="flex-table-item-grow">
                    <app-table-body></app-table-body>
                </div>
            </div>
            <div class="flex-table-item">
                <app-table-footer></app-table-footer>
            </div>
        </div>
    </div>
</div>
</template>

<script>
import SimpleBar from 'SimpleBar';
import TableToolbar from './TableToolbar.vue';
import TableHeader from './TableHeader.vue';
import TableBody from './TableBody.vue';
import TableFooter from './TableFooter.vue';

export default {
    name: 'app',
    components: {
        appTableToolbar: TableToolbar,
        appTableHeader: TableHeader,
        appTableBody: TableBody,
        appTableFooter: TableFooter,
    },
    data() {
        const desktop = !(/android|iphone/i.test(navigator.userAgent) || (/ipad/i.test(navigator.userAgent) && window.innerWidth < 768));
        return {
            desktop
        }
    },
    computed: {
        classObject() {
            return {
                mobile: this.mobile,
                desktop: this.desktop,
                desktopSite: this.desktopSite
            };
        },
        desktopSite() {
            return this.$store.getters.desktopSite;
        },
        mobile() {
            return this.$store.getters.mobile;
        }
    }
}
</script>

<style lang="sass">
*, *:before, *:after
    -moz-box-sizing: border-box
    -webkit-box-sizing: border-box
    box-sizing: border-box

html
    height: 100vh
    margin: 0px
body
    margin: 15px

.mobile
    .flex-table-container
        height: calc(100vh - 105px)
.mobile.desktopSite
    .flex-table-container
        height: calc(100vh - 230px)
.flex-table-container
    height: calc(100vh - 30px)
    box-sizing: border-box
    display: flex
    flex-direction: column
    justify-content: flex-start /* align items in Main Axis */
    align-items: stretch /* align items in Cross Axis */
    align-content: stretch /* Extra space in Cross Axis */
    .flex-table-item
        background: rgba(255, 255, 255, .1)
    .flex-table-item-grow
        /* let body grow to fill page if needed */
        flex-shrink: 1
        flex-grow: 0
        flex-basis: auto

    .flex-table-body
        flex-direction: row
        justify-content: flex-start /* align items in Main Axis */
        align-items: stretch /* align items in Cross Axis */
        align-content: stretch /* Extra space in Cross Axis */
        overflow-y: auto
        min-height: 32px
</style>
