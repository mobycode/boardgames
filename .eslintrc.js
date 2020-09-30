module.exports = {
  root: true,
  env: {
    node: true,
  },
  extends: [
    'plugin:vue/essential',
    '@vue/airbnb',
  ],
  parserOptions: {
    parser: 'babel-eslint',
  },
  rules: {
    'func-names': 'off',
    'max-len': 'off',
    'no-console': 'off',
    'no-debugger': process.env.NODE_ENV === 'production' ? 'warn' : 'off',
    'no-plusplus': 'off',
    'no-minusminus': 'off',
    "vue/max-len": ["error", {
      "code": 150,
      "template": 300,
      "tabWidth": 2,
      "comments": 150,
  }]
},
};
