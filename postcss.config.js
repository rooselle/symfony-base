const purgecss = require('@fullhuman/postcss-purgecss');

module.exports = {
  plugins: [
    require('autoprefixer'),
    purgecss({
      content: ['./**/*.html.twig'],
      css: ['./public/build/*.css'],
      fontFace: true,
      safelist: ['alert-danger', 'alert-success'],
      variables: true,
    }),
  ],
};
