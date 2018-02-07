exports.config = {
  // See http://brunch.io/#documentation for docs.
  files: {
    javascripts: {
      joinTo: "js/app.js"

      // To use a separate vendor.js bundle, specify two files path
      // http://brunch.io/docs/config#-files-
      // joinTo: {
      //  "js/app.js": /^(web\/static\/js)/,
      //  "js/vendor.js": /^(web\/static\/vendor)|(deps)/
      // }
      //
      // To change the order of concatenation of files, explicitly mention here
      // order: {
      //   before: [
      //     "web/static/vendor/js/jquery-2.1.1.js",
      //     "web/static/vendor/js/bootstrap.min.js"
      //   ]
      // }
    },
    stylesheets: {
      joinTo: {
        "css/app.css": path => !path.includes('kit'),
        "css/kit.css": path => path.includes('kit')
      },
      order: {
        after: ["css/app.css"] // concat app.css last
      }
    },
    templates: {
      joinTo: "js/app.js"
    }
  },

  conventions: {
    // This option sets where we should place non-css and non-js assets in.
    // By default, we set this to "/web/static/assets". Files in this directory
    // will be copied to `paths.public`, which is "priv/static" by default.
    assets: /^(static)/
  },

  // Phoenix paths configuration
  paths: {
    // Dependencies and current project directories to watch
    watched: ["static", "css", "js", "vendor"],

    // Where to compile files to
    public: "../priv/static"
  },

  // Configure your plugins
  plugins: {
    babel: {
      plugins: ["transform-class-properties"],
      // Do not use ES6 compiler in vendor code
      ignore: [/vendor/]
    },
    copycat: {
      "fonts": [
        "node_modules/font-awesome/fonts"
      ] // copy */* to priv/static/fonts/
    },
    sass: {
      options: {
        includePaths: [
          "node_modules/bootstrap/scss",
          "node_modules/font-awesome/css"
        ], // tell sass-brunch where to look for files to @import
        precision: 8 // minimum precision required by bootstrap-sass
      }
    },
    uglify: {
      mangle: false
    }
  },

  modules: {
    autoRequire: {
      "js/app.js": ["js/app"]
    }
  },

  npm: {
    enabled: true,
    globals: { // bootstrap JavaScript requires both '$' and 'jQuery' in global scope
      $: 'jquery',
      jQuery: 'jquery',
      Tether: 'tether',
      bootstrap: 'bootstrap'
    }
  }
};
