<template>
<div class="container-fluid" :class="classObject">
    <div class="debug-info mobile-height">{{ mobileHeight }}</div>
    <div class="debug-info device-size">
        <span v-for="(value, key, index) in DEVICE_SIZES" class="device-detector" :class="value">{{key+': '+index}}&nbsp;&nbsp;</span>
    </div>
    <router-view></router-view>
</div>
</template>

<script>
import Vue from 'vue'
import moment from 'moment'
import {
    VueMasonryPlugin
} from 'vue-masonry';

Vue.use(VueMasonryPlugin)

const DEVICE_SIZES = ['sm', 'md', 'lg', 'xl'];

var fixOutline = require('fix-outline');
fixOutline();
window.addEventListener('click', () => {
    document.body.classList.remove('kb-nav-used');
});

export default {
    name: 'app',
    components: {},
    data() {
        const DEVICE_SIZES = {
            'sm': 'device-sm d-none d-sm-block d-md-none',
            'md': 'device-md d-none d-md-block d-lg-none',
            'lg': 'device-lg d-none d-lg-block d-xl-none',
            'xl': 'device-xl d-none d-xl-block'
        };
        const desktop = !(/android|iphone/i.test(navigator.userAgent) || (/ipad/i.test(navigator.userAgent) && window.innerWidth < 768));
        return {
            DEVICE_SIZES,
            desktop,
            classObject: {
                desktop,
                'device-sm': true,
                'non-webapp': (window.navigator.standalone !== true),
                dev: location.port === "8080"
            }
        }
    },
    computed: {
        mobileHeight() {
            return this.$store.getters.mobileHeight;
        },
        desktopSite() {
            return this.$store.getters.desktopSite;
        },
        mobile() {
            return this.$store.getters.mobile;
        }
    },
    created() {
        //setTimeout(() => { // uncomment to test store loading
        let name = this.$route.name,
            query = this.$route.query;
        this.$router.push({
            name: 'loading',
            query // pass current query so store.state.route.query is defined in loadStore
        });
        this.$store.dispatch('loadStore').then((data) => {
            if (name && !(name === 'loading' || name === 'load-error')) {
                this.$router.push({
                    name: name
                });
            } else {
                this.$router.push({
                    name: 'table'
                });
            }
        }, (error) => {
            this.$router.push({
                name: 'load-error'
            });
        });
        //}, 10000);
        this.classObject.mobile = this.mobile;
        this.classObject.desktopSite = this.desktopSite;

        window.addEventListener('resize', (evt) => {
            this.setDeviceSize();
        });
    },
    mounted() {
        this.setDeviceSize();
    },
    methods: {
        setDeviceSize() {
            let deviceSize = 'xs',
                classObject = Object.assign({}, this.classObject),
                el;

            //console.log("-> App::setDeviceSize");

            for (const size in this.DEVICE_SIZES) {
                classObject['device-' + size] = false;
                el = document.querySelector('.device-detector.device-' + size);
                if (el) {
                    //console.log("   App::setDeviceSize: size [" + size + "] display [" + getComputedStyle(el).getPropertyValue("display") + "]");
                    if (getComputedStyle(el).getPropertyValue("display") === 'block') {
                        deviceSize = size;
                    }
                }
            }

            //console.log("   App::setDeviceSize: " + this.$store.getters.deviceSize + " !== " + deviceSize);
            classObject['device-' + deviceSize] = true;
            if (this.$store.getters.deviceSize !== deviceSize) {
                this.$store.dispatch('setDeviceSize', {
                    deviceSize: deviceSize
                });
                //console.log("   App::setDeviceSize: new DEVICE_SIZE = " + deviceSize);
            }

            if (/iphone|ipad/i.test(navigator.userAgent)) {
                let mobileHeight = window.innerHeight - 30;
                //alert(`<> App::setDeviceSize: inner ${window.innerHeight} outer ${window.outerHeight} body ${document.body.clientHeight}`);
                document.body.style.height = mobileHeight + 'px';
                this.$store.dispatch('setMobileHeight', {
                    mobileHeight
                });
            }

            this.classObject = Object.assign({}, classObject);

            //console.log("<- App::setDeviceSize");
        }
    },
    watch: {
        $route(to, from) {
            if (to.path != from.path) { // to prevent an infinite loop
                this.$router.replace({
                    query: from.query
                })
            }
        }
    }
}
</script>

<style lang="sass">
$verticalMargin: 15px

*, *:before, *:after
    -moz-box-sizing: border-box
    -webkit-box-sizing: border-box
    box-sizing: border-box

html
    overflow: hidden
body
    margin: $verticalMargin 0px
    padding: 0px
    //background-color: rgba(255,0,255,.1);
    //border: 1px solid grey;

.debug-info
    display: none
    position: fixed
    z-index: 999
    background-color: #fff
    text-align: right
.debug-info.mobile-height
    top: 150px
    right: 0px
.debug-info.device-size
    top: 200px
    right: 0px
.dev .debug-info
    display: block
</style>
