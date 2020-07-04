<template>
<div class="container-fluid" :class="classObject">
    <div class="debug-info mobile-height">{{ mobileHeight }}</div>
    <div class="debug-info device-size">
        <span v-for="(value, key, index) in DEVICE_SIZES" :key="key" class="device-detector" :class="value">{{key+': '+index}}&nbsp;&nbsp;</span>
    </div>
    <router-view></router-view>
</div>
</template>

<script>
import Vue from 'vue'
import fixOutline from 'fix-outline'
import {
    VueMasonryPlugin
} from 'vue-masonry';

Vue.use(VueMasonryPlugin)

fixOutline();
window.addEventListener('click', () => {
    document.body.classList.remove('kb-nav-used');
});
window.addEventListener('keydown', (evt) => {
    if (["Tab", "ArrowDown", "ArrowUp", "ArrowLeft", "ArrowRight"].includes(evt.key)) {
        document.body.classList.add('kb-nav-used');
    }
}, true);

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
        this.$store.dispatch('loadStore').then(() => {
            if (name && !(name === 'loading' || name === 'load-error')) {
                this.$router.push({
                    name: name
                });
            } else {
                this.$router.push({
                    name: 'table'
                });
            }
        }, () => {
            this.$router.push({
                name: 'load-error'
            });
        });
        //}, 10000);
        this.classObject.mobile = this.mobile;
        this.classObject.desktopSite = this.desktopSite;

        window.addEventListener('resize', () => {
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
            classObject['device-xs'] = false;
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
            if ((this.$route.path !== to.path) && (to.path !== from.path)) {
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

/* shrink bootstrap gutters to 4px for xs and 8px for sm */
$gutterMap: ( "xs": ( "bootstrap": "", "min": 0px, "max": 576px, "gutter": 4px ), "sm": ( "bootstrap": "-sm", "min": 576px, "max": 768px, "gutter": 8px ) )
@each $id, $props in $gutterMap
  $min: map-get($props, "min")
  $max: map-get($props, "max")
  $gutter: map-get($props, "gutter")
  $bootstrap: map-get($props, "bootstrap")

  @media (min-width: $min) and (max-width: $max)
    .device-#{$id}
      &.container-fluid,
      .container-fluid,
      .col,
      .col#{$bootstrap}
        padding-right: $gutter
        padding-left: $gutter
      @for $i from 0 through 6
        .col#{$bootstrap}-#{$i}
          padding-left: $gutter
          padding-right: $gutter
      .row
        margin-right: -$gutter
        margin-left: -$gutter

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

// .dev [class="row"]
//       outline: 1px dotted rgba(0, 0, 0, 0.25)
// .dev [class*="col-"]
//       background-color: rgba(255, 0, 0, 0.2)
//       outline: 1px dotted rgba(0, 0, 0, 0.5)

</style>
