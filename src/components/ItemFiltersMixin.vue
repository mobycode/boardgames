<template>
</template>

<script>
export default {
    filters: {
        filterItemRank(item) {
            const rank = item.rank;
            return rank === -1 ? '' : rank;
        },

        filterItemHref(item) {
            return 'https://boardgamegeek.com/boardgame/' + item.objectid + '/';
        },

        filterItemWeight(item) {
            return item.weight.toFixed(2);
        },

        filterItemPlayers(item, deviceSizeValue) {
            return item.minplayers + (deviceSizeValue && deviceSizeValue < 1 ? "-" : " - ") + item.maxplayers;
        },

        filterItemPlays(item, selectedOwner) {
            const numplays = item.numplays || {};
            return numplays[selectedOwner] || '';
        },

        filterItemPlayTime(item, deviceSizeValue) {
            let str = "",
                min = item.minplaytime,
                max = item.maxplaytime;
            if (!(min === -1 && max === -1)) {
                if (item.minplaytime === item.maxplaytime) {
                    str = item.maxplaytime;
                } else {
                    str = item.minplaytime + (deviceSizeValue < 0 ? "-" : " - ") + item.maxplaytime;
                }
            }
            return str;
        },

        formatItemPictureSrc(item) {
            let src;
            if (item.picture) {
                src = '//cf.geekdo-images.com/images/pic' + item.picture + '_md.' + (item.pictureext || 'jpg');
            } else {
                src = item.thumbnail;
            }
            return src;
        }
    }
}
</script>

<style lang="sass">
</style>
