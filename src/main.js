import Vue from 'vue';
import VueRouter from 'vue-router';
import VueResource from 'vue-resource';

import { sync } from 'vuex-router-sync';
import App from './App.vue';
import routes from './routes';
import store from './store/store';

Vue.use(VueRouter);
Vue.use(VueResource);

// firebase -> add project (vuejs-stock-trader)
// project -> database -> change read/write to true to allow read/write access for all (bad for prod)
// get database URL from database -> data
Vue.http.options.root = 'https://bgg-games.firebaseio.com/';

const router = new VueRouter({
  routes,
});

sync(store, router);

/* eslint-disable-next-line no-new */
new Vue({
  el: '#app',
  router,
  store,
  render: (h) => h(App),
});

// unsync();
