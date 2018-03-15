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

// Stimulus data
import { Application } from "stimulus"

import BuildsController from "./controllers/builds_controller"
import ChartsController from "./controllers/charts_controller"
import ProjectsController from "./controllers/projects_controller"
import ReposController from "./controllers/repos_controller"
import TagsController from "./controllers/tags_controller"

const application = Application.start()
application.register("builds", BuildsController)
application.register("charts", ChartsController)
application.register("projects", ProjectsController)
application.register("repos", ReposController)
application.register("tags", TagsController)

// Import local files
//
// Local files can be imported directly using relative
// paths "./socket" or full ones "web/static/js/socket".

$('[data-toggle="tooltip"]').tooltip();

$(".project-card").click(function(){
  window.location.href = $(this).data("url")
})

// Add class .active to current link
$('.sidebar-elements').find('a').each(function(){
  var cUrl = String(window.location).split('?')[0];

  if (cUrl.substr(cUrl.length - 1) == '#') {
    cUrl = cUrl.slice(0,-1);
  }

  if (cUrl.includes($($(this))[0].href)) {
    $(this).addClass('active');

    $(this).parents('ul').add(this).each(function(){
      $(this).parent().addClass('active');
    });
  }
});

var 
  collapsibleSidebarClass = "aci-collapsible-sidebar",
  collapsibleSidebarCollapsedClass = "aci-collapsible-sidebar-collapsed",
  sidebar = $(".aci-left-sidebar"),
  mainWrapper = $(".aci-wrapper");

$(".aci-toggle-left-sidebar").on("click", function() {
  if(mainWrapper.hasClass(collapsibleSidebarCollapsedClass)) {
    mainWrapper.removeClass(collapsibleSidebarCollapsedClass)
    $("li.open", sidebar).removeClass("open")
    $("li.active", sidebar).parents(".parent").addClass("active open")
  } else {
    mainWrapper.addClass(collapsibleSidebarCollapsedClass)
    $("li.active", sidebar).parents(".parent").removeClass("open")
    $("li.open", sidebar).removeClass("open")
  }
})
