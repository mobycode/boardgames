import Vue from 'vue';
import VueRouter from 'vue-router';

import { sync } from 'vuex-router-sync';
import App from './App.vue';
import routes from './routes';
import store from './store/store';

Vue.use(VueRouter);

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
