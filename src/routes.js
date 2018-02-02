import Loading from './components/Loading.vue';
import LoadError from './components/LoadError.vue';
import Games from './components/Games.vue';
import Table from './components/table/Table.vue';
import Tiles from './components/Tiles.vue';
import Pictures from './components/Pictures.vue';

export const routes = [
    { path: '', component: Loading },
    { name: 'loading', path: '/loading', component: Loading },
    { name: 'load-error', path: '/load-error', component: LoadError },
    { path: '/data', component: Games, children: [
         { path: '', component: Table },
         { name: 'table', path: 'table', component: Table },
         { name: 'tiles', path: 'tiles', component: Tiles },
         { name: 'image', path: 'image', component: Pictures },
         { name: 'data', path: '*', component: Table }
    ]},
    { path: '*', component: Games },
];
