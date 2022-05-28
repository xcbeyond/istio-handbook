module.exports = {
  book: {
    assets: "./book",
    css: ["gtalk.css"]
  },

  hooks: {
    "page:before": function(page) {
      var footer = require('./book/gtalk');
      return footer(this, page);
    },
  }
};
