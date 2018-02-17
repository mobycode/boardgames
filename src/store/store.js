import Vue from 'vue'
import Vuex from 'vuex'


Vue.use(Vuex)


const itemMapToArray = (item, propName, toInt) => {
    // convert property value from maps to array
    let arr = [];
    if (item[propName]) {
        Object.keys(item[propName]).forEach(val => {
            if (toInt) {
                val = parseInt(val, 10);
            }
            arr.push(val);
        });
    }
    arr.sort();
    item[propName] = arr;
};

const formatOwners = (owners) => {
    return (owners || []).join(", ");
};

const formatRange = (array) => {
    let str = '';
    if (Array.isArray(array)) {
        for (var ranges = [], rend, i = 0; i < array.length;) {
            ranges.push((rend = array[i]) + ((function(rstart) {
                while (++rend === array[++i]);
                return --rend === rstart;
            })(rend) ? '' : '-' + rend));
        }
        str = ranges.join(',');
    }
    return str;
};

const filterItems = (state) => {
    console.log('-> store::filterItems');
    const filters = Object.values(state.filters).filter(filter => filter.enabled);
    state.filteredItems = state.items.filter(item => {
        for (let filterId in filters) {
            if (!filters[filterId].matches(item)) {
                return false;
            }
        }
        return true;
    });
    console.log('   store::filterItems: post-filter length: '+state.filteredItems.length);
    searchItems(state);
    console.log('   store::filterItems: post-search length: '+state.filteredItems.length);
    sortItems(state);
    console.log('<- store::filterItems: '+state.items.length+' -> '+state.filteredItems.length);
};

const searchItems = (state) => {
    if (state.searchString !== '') {
        console.log('-> store::searchItems');
        const searchStrings = state.searchString.toLowerCase().split('|').filter(str => str !== '');
        const preSearchLength = state.filteredItems.length;
        const searchStringsLength = searchStrings.length;
        let i;
        state.filteredItems = state.filteredItems.filter((item) => {
            let match = false;
            for (i=0; i<searchStringsLength && !match; i++) {
                match = item.name.toLowerCase().indexOf(searchStrings[i]) !== -1;
            }
            return match;
        });
        console.log('<- store::searchItems: '+preSearchLength+' -> '+state.filteredItems.length);
    }
};

const sortValue = (a, b, type, order) => {
    let rc;
    if (type === 'string') {
        rc = a.localeCompare(b) * order;
    } else if (type === 'number') {
        if (a === -1) {
            if (b === -1) {
                rc = 0;
            } else {
                rc = 1; // always sort -1 at the end (regardless of sort order)
            }
        } else {
            if (b === -1) {
                rc = -1; // always sort -1 at the end (regardless of sort order)
            } else {
                rc = (a-b) * order;
            }
        }
    }
    return rc;
}

const sortItem = (itemA, itemB, state) => {
    const sort = state.sort;
    let i = 0,
        a, b, rc;
    for (const property of sort.properties) {
        a = itemA[property];
        b = itemB[property];
        if (property === 'numplays') {
            a = a ? a[state.selectedOwner] || -1 : -1;
            b = b ? b[state.selectedOwner] || -1 : -1;
        }
        rc = sortValue(a, b, sort.types[i++], sort.ascending ? 1 : -1);
        if (rc !== 0) {
            return rc;
        }
    }
    return 0;
};

const sortItems = (state) => {
    if (state.sort) {
        console.log('-> store::sortItems');

        let properties = state.sort.properties,
            types = state.sort.types,
            ascending = state.sort.ascending;

        console.log('   store::sortItems: properties ['+properties.join(',')+']');
        console.log('   store::sortItems: types ['+types.join(',')+']');
        console.log('   store::sortItems: ascending ['+ascending+']');

        state.filteredItems = state.filteredItems.sort((itemA, itemB) => {
            return sortItem(itemA, itemB, state);
        });
        // for (i=0; i<10; i++) {
        //     let item = state.filteredItems[i];
        //     console.log(`${item.rank}  ${item.name}`)
        // }
        console.log('<- store::sortItems: '+state.filteredItems.length);
    }
}

const OWNER_IAN = 'Ian';
const OWNER_JASON = 'Jason';
const OWNER_JOE = 'Joe';
const OWNER_JUSTIN = 'Justin';
const ALL_OWNERS = [
    OWNER_IAN,
    OWNER_JASON,
    OWNER_JOE,
    OWNER_JUSTIN,
];

const MOBILE = true || /android|iphone|ipad/i.test(navigator.userAgent);
const DEVICE_SIZES = ['sm', 'md', 'lg', 'xl'];

const state = {
    desktopSite: !MOBILE,
    deviceSize: 'xs',
    mobileHeight: -1,
    loadError : false,
    items: [],
    time: -1,
    selectedOwner: OWNER_JUSTIN,
    ownersWithPlays: [],
    searchString: '',
    filters: {},
    filteredItems: [],
    sort: {
        id: 'rank',
        properties: ['rank'],
        types: ['number'],
        ascending: true
    }
};

const mutations = {
    'TOGGLE_DESKTOP_SITE' (state) {
        //console.log("<> store::TOGGLE_DESKTOP_SITE: "+!state.desktopSite);
        state.desktopSite = !state.desktopSite;
    },
    'SET_MOBILE_HEIGHT' (state, mobileHeight) {
        //console.log("<> store::SET_MOBILE_HEIGHT: "+mobileHeight);
        state.mobileHeight = mobileHeight;
    },
    'SET_DEVICE_SIZE' (state, deviceSize) {
        //console.log("<> store::SET_DEVICE_SIZE: "+deviceSize);
        state.deviceSize = deviceSize;
    },
    'LOAD_ERROR' (state, response) {
        console.log("-> store::LOAD_ERROR");
        state.loadError = true;
        console.log("<- store::LOAD_ERROR");
    },
    'FROM_QUERY' (state) {
        const query = state.route.query;

        console.log(`-> store::FROM_QUERY: query ${query}`);
        if (query) {
            console.log(`<> store::FROM_QUERY: query.search ${query.search}`);
            if (query.search !== undefined) {
                if (Array.isArray(query.serach)) {
                    state.searchString = query.search;
                } else {
                    state.searchString = query.search.join('|');
                }
                console.log(`<> store::FROM_QUERY: search ${state.searchString}`);
            }
            if (query.selectedOwner !== undefined && this.getters.allOwners.includes(query.selectedOwner)) {
                state.selectedOwner = query.selectedOwner;
                console.log(`<> store::FROM_QUERY: selectedOwner ${state.selectedOwner}`);
            }
        }
        console.log("<- store::FROM_QUERY");
    },
    'SET_ITEMS' (state, itemsMap) {
        console.log("-> store::SET_ITEMS");

        // create store items from itemMap items
        let items = [],
        item;

        Object.keys(itemsMap).forEach( (objectid) => {
            item = itemsMap[objectid];
            //console.log("   store::SET_ITEMS: -> itemsMap.forEach: item.name ["+item.name+"]");

            item.objectid = objectid;

            // convert owners/prevowners from maps to arrays
            itemMapToArray(item, "owners");
            itemMapToArray(item, "prevowners");
            item.playersString = formatRange([item.minplayers,item.maxplayers]);
            item.bestplayersString = item.bestplayers ? formatRange(item.bestplayers) : 'None';
            item.recplayersString = item.recplayers ? formatRange(item.recplayers) : 'None';
            item.ownersString = formatOwners(item.owners);

            items.push(item);
            //console.log("   store::SET_ITEMS: <- itemsMap.forEach");
        });

        state.ownersWithPlays = ALL_OWNERS.filter( (o) => ( items.some( (item) => (item.numplays || {})[o] !== undefined ) ) );
        state.items = items;
        console.log("   store::SET_ITEMS: set");
        filterItems(state);
        console.log("   store::SET_ITEMS: filtered");
        sortItems(state);
        console.log("   store::SET_ITEMS: sortred");

        console.log("<- store::SET_ITEMS");
    },
    'SET_TIME' (state, time) {
        state.time = time;
    },
    'SET_SORT' (state, sort) {
        console.log('-> store::SET_SORT');

        let id, properties, types, ascending;

        if (typeof sort === 'string') {
            id = sort,
            properties = [sort];
            types = ['number'];
            ascending = id === state.sort.id ? (!state.sort.ascending) : true;
        } else {
            id = sort.id;
            properties = Array.isArray(sort.properties) ? sort.properties : sort.property ? [sort.property] : [sort.id];
            if (sort.types || sort.type) {
                types = Array.isArray(sort.types) ? sort.types : [sort.type];
            } else {
                types = [];
                for (let i=0; i<properties.length; i++) {
                    types.push('number');
                }
            }
            ascending = typeof sort.ascending === 'boolean' ? sort.ascending : (id === state.sort.id ? (!state.sort.ascending) : true);
        }

        if (!properties.includes('rank')) {
            properties = properties.concat(['rank']);
            types = types.concat('number');
        }

        state.sort = {
            id,
            properties,
            types,
            ascending
        };
        sortItems(state);
        console.log('<- store::SET_SORT');
    },
    'UPDATE_FILTERS' (state, filters) {
        console.log('-> store::UPDATE_FILTERS');
        filters.forEach((filter) => {
            state.filters[filter.id] = filter;
        });
        filterItems(state);
        console.log('<- store::UPDATE_FILTERS');
    },
    'UPDATE_SEARCH' (state, update) {
        console.log('-> store::UPDATE_SEARCH');
        const {searchString,router} = update;
        state.searchString = searchString;
        router.push({
            query: Object.assign({}, state.route.query, {
                search: searchString === '' ? undefined : searchString.split('|').filter(str => str !== '')
            })
        });
        filterItems(state);
        console.log('<- store::UPDATE_SEARCH');
    },
    'SELECT_OWNER' (state, update) {
        console.log('-> store::SELECT_OWNER('+update+')');
        const {owner,router} = update;
        state.selectedOwner = owner;
        router.push({
            query: Object.assign({}, state.route.query, {
                selectedOwner: owner === '' ? undefined : owner
            })
        });
        if (state.sort && state.sort.properties[0] === 'numplays') {
            sortItems(state);
        }
        console.log('<- store::SELECT_OWNER');
    }
};

const actions = {
    toggleDesktopSite({commit}) {
        console.log('-> store::toggleDesktopSite');
        commit('TOGGLE_DESKTOP_SITE');
        console.log('<- store::toggleDesktopSite');
    },
    setDeviceSize({commit}, update) {
        console.log('-> store::setDeviceSize');
        commit('SET_DEVICE_SIZE', update.deviceSize);
        console.log('<- store::setDeviceSize');
    },
    setMobileHeight({commit}, update) {
        console.log('-> store::setMobileHeight');
        commit('SET_MOBILE_HEIGHT', update.mobileHeight);
        console.log('<- store::setMobileHeight');
    },
    updateFilters({commit}, update) {
        console.log('-> store::updateFilter');
        commit('UPDATE_FILTERS', update.filters);
        console.log('<- store::updateFilter');
    },
    updateSearch({commit}, update) {
        console.log('-> store::updateSearch');
        commit('UPDATE_SEARCH', update);
        console.log('<- store::updateSearch');
    },
    setSort({commit}, update) {
        console.log('-> store::setSort');
        commit('SET_SORT', update.sort);
        console.log('<- store::setSort');
    },
    setSelectedOwner({commit}, update) {
        console.log('-> store::setSelectedOwner');
        commit('SELECT_OWNER', update);
        console.log('<- store::setSelectedOwner');
    },
    toggleSelectedOwner({commit, state}, update) {
        console.log('-> store::toggleSelectedOwner');
        update.owner = state.ownersWithPlays[(state.ownersWithPlays.indexOf(state.selectedOwner)+1) % state.ownersWithPlays.length];
        commit('SELECT_OWNER', update);
        console.log('<- store::toggleSelectedOwner');
    },
    resetSelectedOwner({commit}, update) {
        console.log('-> store::resetSelectedOwner');
        update.owner = OWNER_JUSTIN;
        commit('SELECT_OWNER', update);
        console.log('<- store::resetSelectedOwner');
    },
    loadStore({commit}) {
        commit('FROM_QUERY');

        return new Promise((resolve, reject) => {
            Vue.http.get('data.json')
                .then(response => response.json())
                .then(data => {
                    if (data) {
                        const items = data.items;
                        const time = data.time;
                        console.log("-> store::loadStore: items ["+Object.keys(items).length+"] time ["+time+"]");
                        commit('SET_ITEMS', items);
                        commit('SET_TIME', time);
                        resolve(data);
                        console.log("<- store::loadStore");
                    }
                }, response => {
                    console.log('<> store::loadStore error')
                    commit('LOAD_ERROR', response)
                    reject(response);
                    console.log(response)
                });
        })
    }
};

const getters = {
    desktopSite(state) {
        return state.desktopSite;
    },
    mobile(state) {
        return MOBILE;
    },
    deviceSizes(state) {
        return DEVICE_SIZES;
    },
    mobileHeight(state) {
        return state.mobileHeight;
    },
    deviceSize(state) {
        return state.deviceSize;
    },
    deviceSizeValue(state) {
        let val = DEVICE_SIZES.indexOf(state.deviceSize);
        //console.log(`<> store::deviceSizeValue: ${state.deviceSize} -> ${val}`);
        return val;
    },
    loadError(state) {
        return state.loadError;
    },
    items(state) {
        return state.items;
    },
    time(state) {
        return state.time;
    },
    selectedOwner(state) {
        console.log('<> store::selectedOwner = '+state.selectedOwner)
        return state.selectedOwner;
    },
    filteredItems(state) {
        return state.filteredItems;
    },
    sortId(state) {
        return state.sort.id;
    },
    isSortAscending(state) {
        return state.sort.ascending;
    },
    isSortDescending(state) {
        return !state.sort.ascending;
    },
    allOwners(state) {
        //console.log('<> store::selectedOwner = '+state.selectedOwner)
        return ALL_OWNERS;
    }
};

export default new Vuex.Store({
    state,
    mutations,
    actions,
    getters
});
