// Brunch automatically concatenates all files in your
// watched paths. Those paths can be configured at
// config.paths.watched in "brunch-config.js".
//
// However, those files will only be executed if
// explicitly imported. The only exception are files
// in vendor, which are never wrapped in imports and
// therefore are always executed.

// Import dependencies
//
// If you no longer want to use a dependency, remember
// to also remove its path from "config.paths.watched".
import "phoenix_html"
import "ansi-to-html"

// Import local files
//
// Local files can be imported directly using relative
// paths "./socket" or full ones "web/static/js/socket".

// import socket from "./socket"
import "./core-ui"

var Ansi = require('ansi-to-html');
var ansi = new Ansi();

$('[data-submit="parent"]').click(function(e) {
  e.preventDefault;
  $(this).parent().submit();
});

$('.build-get').click(function(e) {
  e.preventDefault;
  var id = $(this).data('id');
  var project_id = $(this).data('project-id');

  $.ajax({
    type: "GET",
    url: '/projects/' + project_id + '/builds/' + id,
    success: function(data) {
      var contents = ansi.toHtml(data.trace);
      $('#output').replaceWith(contents.replace(/\n/g, "<br />"));
    },
    dataType: 'json'
  });
});
