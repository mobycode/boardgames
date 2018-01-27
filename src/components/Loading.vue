<template>
<div class="row">
    <div class="col loading">
        <div class="text-center">
            <i class="fa fa-spinner fa-spin fa-2x fa-fw"></i>
            <span class="sr-only">Loading...</span>
        </div>
    </div>
</div>
</template>

<script>
export default {
    data() {
        return {}
    },
    computed: {}
}
</script>

<style lang="sass" scoped>
.container-fluid
    overflow-y: auto
    margin-bottom: 0px

    .loading
        overflow-y: hidden
        padding: 8px 0px
</style>
