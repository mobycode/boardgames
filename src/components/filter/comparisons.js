export const LESS_THAN = 'less-than'; // filter.value <= item.value
export const GREATER_THAN = 'greater-than'; // filter.value >= item.value
export const USER_RANGE = 'user-range'; // item.value >= filter.minValue & item.value <= filter.maxValue
export const DUAL_RANGE = 'dual-range'; // filter.minValue >= item.minValue && filter.maxValue <= item.maxValue;
export const NO_VALUE = 'no-value'; // item.value undefined
export const CONTAINS = 'contains'; // item.value is an array that contains filter.value
export const ITEM_RANGE = 'item-range'; // item.minValue >= filter.value & item.maxValue <= filter.value
