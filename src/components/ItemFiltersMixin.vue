<template>
  <div></div>
</template>

<script>
import moment from 'moment'

export default {
    filters: {
        filterItemRank(item) {
            const rank = item.rank;
            return rank === -1 ? '' : rank;
        },

        filterItemHref(item) {
            return 'https://boardgamegeek.com/boardgame/' + item.objectid + '/';
        },

        filterItemPlayers(item, deviceSizeValue) {
            return item.minplayers + (deviceSizeValue !== undefined && deviceSizeValue < 1 ? "-" : " - ") + item.maxplayers;
        },

        filterItemPlays(item, selectedOwner) {
            const numplays = item.numplays || {};
            return numplays[selectedOwner] || '';
        },

        filterItemLastPlayed(item, selectedOwner, deviceSizeValue) {
            let lastplayed = item.lastplayed || {};
            lastplayed = lastplayed[selectedOwner] || '';
            let format = 'MM/YY';
            if (lastplayed) {
              if (deviceSizeValue !== undefined && deviceSizeValue > 3) {
                format = 'MM/DD/YYYY';
              }
              lastplayed = moment.unix(lastplayed).format(format)
            }
            return lastplayed;
        },

        filterItemPlayTime(item, deviceSizeValue) {
            let str = "",
                min = item.minplaytime,
                max = item.maxplaytime;
            if (!(min === -1 && max === -1)) {
                if (item.minplaytime === item.maxplaytime) {
                    str = item.maxplaytime;
                } else {
                    str = item.minplaytime + (deviceSizeValue !== undefined && deviceSizeValue < 1 ? "-" : " - ") + item.maxplaytime;
                }
            }
            return str;
        },

        formatItemPictureSrc(item) {
            let src = item.picture;
            if (src) {
                if (src.length > 2 && src.substring(0, 2) !== '//') {
                    src = '//cf.geekdo-images.com/images/pic' + src + '_md.' + (item.pictureext || 'jpg');
                }
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
