<template>
<div>
    <div class="row tfoot">
        <div class="td col-6">
            <span class="pull-left d-none d-md-block">{{ summary }}</span>
            <span class="pull-left d-md-none">{{ miniSummary }}</span>
        </div>
        <div class="td col-6">
            <span class="pull-right"><span class="d-none d-md-inline-block" v-if="time !== -1">Updated:&nbsp;</span>{{ time | formatDateTime }}</span>
        </div>
    </div>
</div>
</template>

<script>
export default {
    data() {
        return {}
    },
    computed: {
        total() {
            return this.$store.getters.items.length;
        },
        displayed() {
            return this.$store.getters.filteredItems.length;
        },
        miniSummary() {
            let str = this.displayed;
            if (this.total !== this.displayed) {
                str += ' of ' + this.total;
            }
            return str + ' items';
        },
        summary() {
            let str = 'Total: ' + this.total;
            if (this.total !== this.displayed) {
                str += " | Filtered: " + this.displayed;
            }
            //console.log(this.objectids);
            return str;
        },
        objectids() {
            let oids = [],
                j = -1;
            this.$store.getters.items.forEach((entry, i) => {
                if (i % 50 === 0) {
                    j++;
                    oids.push([]);
                }
                oids[j].push(entry.objectid);
            });
            oids.forEach((oid, i) => {
                oids[i] = oid.join(',');
            });
            return oids;
        },
        time() {
            return this.$store.getters.time;
        },
    },
    filters: {
        formatDateTime: function(value) {
            let ts = "";
            if (value !== -1) {
                ts = moment(value).format('MM/DD/YYYY hh:mm:ss')
            }
            //_log("<> formatDate(" + value + "): " + ts);
            return ts;
        }
    }
}
</script>

<style lang="sass">
$scrollbarWidth: 18px

.tfoot
    color: #333
    border-top: 2px solid #e9ecef
    border-bottom: 1px solid #e9ecef
    padding-top: 8px
    padding-bottom: 8px

    .td:last-child
        text-align: right
</style>
