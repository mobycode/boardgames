<template>
<div class="row">
    <div class="col">
        <div class="row justify-content-center">
            <div class="col-10 col-sm-8 col-md-6 col-lg-4 alert alert-danger load-error" role="alert">
                <h5 class="alert-heading">Error loading games</h5>
                <hr>
                <p>An error occurred retrieving games from the database. This is probably your fault.</p>
                <p>Ensure your browser is not blocking database requests and <a href="/">try again</a>.</p>
                <p class="mb-0">Again, I blame you. Bad, user! Bad!</p>
            </div>
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

<style lang="sass"  scoped>
.load-error
    margin-bottom: 0px
</style>
