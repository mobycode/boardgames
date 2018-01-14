<template>
<div class="row">
    <div class="col" :class="{mobile:mobile,desktop:desktop,scrollingHack:scrollingHack,'not-scrolling':!scrolling}">
        <app-table-toolbar></app-table-toolbar>
        <app-table-header></app-table-header>
        <app-table-body></app-table-body>
        <app-table-footer></app-table-footer>
    </div>
</div>
</template>

<script>
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
            scrollingHeight: undefined,
            scrolling: false,
            tbody: undefined,
            scrollingHeight: undefined,
            desktop
        }
    },
    computed: {
        desktopSite() {
            return this.$store.getters.desktopSite;
        },
        mobile() {
            return this.$store.getters.mobile;
        },
        filteredItems() {
            return this.$store.getters.filteredItems;
        },
        scrollingHack() {
            //console.log("   Table::scrollingHack: this.tbody = " + this.tbody);
            if (this.tbody) {
                setTimeout(() => {
                    let el = this.tbody.$el;
                    //console.log("   Table::scrolling: scrolling = el['scrollHeight'] > el['clientHeight'] = " + (el['scrollHeight'] > el['clientHeight']));
                    this.scrolling = !this.mobile && el['scrollHeight'] > el['clientHeight'];
                }, 100);
            }
            return this.tbody && this.filteredItems.length > 0 && this.scrollingHeight > 0;
        }
    },
    methods: {
        resize() {
            let children = this.$children,
                bodyStyle = window.getComputedStyle(document.body),
                height = parseInt(bodyStyle.marginTop, 10) + parseInt(bodyStyle.marginBottom, 10),
                tbody, rect;

            for (let child of children) {
                if (child.$el) {
                    if (child.$el.classList.contains('tbody')) {
                        tbody = child;
                    } else {
                        rect = child.$el.getBoundingClientRect();
                        if (rect && rect.height) {
                            console.log('<> resizeBody: height += ' + rect.height);
                            height += rect.height;
                        }
                    }
                }
            }

            if (/iPad/.test(navigator.userAgent)) {
                height += 75;
            } else if (/iPhone/.test(navigator.userAgent)) {
                height += this.desktopSite ? 200 : 75;
            }

            console.log('<> resizeBody: tbody.style.height = calc(100vh - ' + height + 'px');
            tbody.$el.style.maxHeight = 'calc(100vh - ' + height + 'px)'; // 15px body margin-top/bottom

            this.tbody = tbody;
            this.scrollingHeight = height;
        }
    },
    mounted() {
        this.resize();
    },
    watch: {}
}
</script>

<style>
</style>
