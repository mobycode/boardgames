<script>
import {
  OWNER_ABBREVIATIONS,
} from '../store/store';

export default {
  filters: {
    filterOwner(owner) {
      return OWNER_ABBREVIATIONS[owner] || owner;
    },
  },
};
</script>
