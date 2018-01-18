<template>
<div class="container-fluid" :class="classObject">
    <div v-for="(value, key) in DEVICE_SIZES" class="device-detector" :class="value"></div>
    <router-view></router-view>
</div>
</template>

<script>
import moment from 'moment'
import Header from './components/Header.vue';
import Table from './components/table/Table.vue';


const DEVICE_SIZES = ['sm', 'md', 'lg', 'xl'];

export default {
    name: 'app',
    components: {
        appHeader: Header,
        appTable: Table
    },
    data() {
        return {
            DEVICE_SIZES: {
                'sm': 'device-sm d-none d-sm-block',
                'md': 'device-md d-none d-md-block',
                'lg': 'device-lg d-none d-lg-block',
                'xl': 'device-xl d-none d-xl-block'
            },
            classObject: {
                'device-sm': true
            }
        }
    },
    created() {
        this.$store.dispatch('loadStore');

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
                }
            }

            //console.log("   App::setDeviceSize: " + this.$store.getters.deviceSize + " !== " + deviceSize);
            if (this.$store.getters.deviceSize !== deviceSize) {
                this.classObject = {};
                this.classObject['device-' + deviceSize] = true;
                this.$store.dispatch('setDeviceSize', {
                    deviceSize: deviceSize
                });
                //console.log("   App::setDeviceSize: new DEVICE_SIZE = " + deviceSize);
            }

            //console.log("<- App::setDeviceSize");
        }
    }
}
</script>

<style>
</style>
