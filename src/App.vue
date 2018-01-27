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
import moment from 'moment'

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
            'sm': 'device-sm d-none d-sm-block',
            'md': 'device-md d-none d-md-block',
            'lg': 'device-lg d-none d-lg-block',
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
        let name = this.$route.name;
        this.$router.push({
            name: 'loading'
        });
        this.$store.dispatch('loadStore').then((data) => {
            if (name) {
                this.$router.push({
                    name: name
                });
            } else {
                this.$router.push({
                    name: 'data'
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
                el;

            //console.log("-> App::setDeviceSize");

            for (const size in this.DEVICE_SIZES) {
                el = document.querySelector('.device-detector.device-' + size);
                if (el) {
                    //console.log("   App::setDeviceSize: size [" + size + "] display [" + getComputedStyle(el).getPropertyValue("display") + "]");
                    if (getComputedStyle(el).getPropertyValue("display") === 'block') {
                        deviceSize = size;
                    }
                    this.classObject['device-' + deviceSize] = false;
                }
            }

            //console.log("   App::setDeviceSize: " + this.$store.getters.deviceSize + " !== " + deviceSize);
            if (this.$store.getters.deviceSize !== deviceSize) {
                this.classObject['device-' + deviceSize] = true;
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
.debug-info.mobile-height
    top: 150px
    left: 0px
.debug-info.device-size
    top: 200px
    left: 0px
.dev .debug-info
    display: block
</style>
