import Vue from 'vue'
import VueRouter from 'vue-router'
import VueResource from 'vue-resource'
import Vuex from 'vuex'

import App from './App.vue'
//TODO: routes
//import { routes } from './routes'
import store from './store/store'

Vue.use(VueRouter)
Vue.use(VueResource)

// firebase -> add project (vuejs-stock-trader)
// project -> database -> change read/write to true to allow read/write access for all (bad for prod)
// get database URL from database -> data
Vue.http.options.root = 'https://bgg-games.firebaseio.com/';

// trace/console.log utility methods
window._log = function(msg, error) {
    if (window.location.hostname === 'localhost') {
        console.log(msg);
        if (error) {
            console.error(error);
        }
    }
};
window.mapSize = (map) => {
    return Object.keys(map).length;
}
/*
Vue._log = _log; // TODO: better way to do this?
Vue.mixin({
    methods: {
        _log
    }
});
*/

// firebase -> add project (vuejs-stock-trader)
// project -> database -> change read/write to true to allow read/write access for all (bad for prod)
// get database URL from database -> data
//Vue.http.options.root = 'https://vuejs-stock-trader-782fd.firebaseio.com/';

//TODO: routes
//const router = new VueRouter({
//    mode: 'history',
//    routes: routes
//})

new Vue({
  el: '#app',
  //TODO: routes
  //routes,
  store,
  render: h => h(App)
})
