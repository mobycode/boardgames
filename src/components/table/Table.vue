<template>
<div class="flex-page-item flex-page-content flex-page-item-grow">
    <div class="flex-page-item">
        <app-table-header></app-table-header>
    </div>
    <div class="flex-page-item-grow table-body" :data-simplebar="useSimpleBar">
        <app-table-body></app-table-body>
    </div>
</div>
</template>

<script>
import SimpleBar from 'simplebar';
import TableHeader from './TableHeader.vue';
import TableBody from './TableBody.vue';

export default {
    name: 'app',
    data() {
        return {
          useSimpleBar: true
        }
    },
    components: {
        appTableHeader: TableHeader,
        appTableBody: TableBody
    }
}
</script>

<style lang="sass" scoped>
.flex-page-content
    flex-direction: column
//.flex-page-content .flex-page-item-grow
//    width: 100%
span
    display: flex
    flex-direction: column
</style>
