import Loading from './components/Loading.vue';
import LoadError from './components/LoadError.vue';
import Games from './components/Games.vue';
import Table from './components/table/Table.vue';
import Tiles from './components/Tiles.vue';

export const routes = [
    { path: '', component: Loading },
    { name: 'loading', path: '/boardgames/loading', component: Loading },
    { name: 'load-error', path: '/boardgames/load-error', component: LoadError },
    { name: 'data', path: '/boardgames/data', component: Games, children: [
         { path: '', component: Table },
         { name: 'table', path: 'table', component: Table },
         { name: 'tiles', path: 'tiles', component: Tiles },
         { path: '*', component: Table }
    ]},
    { path: '*', component: Games },
];
