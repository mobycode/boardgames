import Vue from 'vue'
import VueRouter from 'vue-router'
import VueResource from 'vue-resource'

import App from './App.vue'
import { routes } from './routes'
import store from './store/store'
import { sync } from 'vuex-router-sync'

Vue.use(VueRouter)
Vue.use(VueResource)

// firebase -> add project (vuejs-stock-trader)
// project -> database -> change read/write to true to allow read/write access for all (bad for prod)
// get database URL from database -> data
Vue.http.options.root = 'https://bgg-games.firebaseio.com/';

const router = new VueRouter({
    routes: routes
})

sync(store, router);

new Vue({
  el: '#app',
  router,
  store,
  render: h => h(App)
})

//unsync();
