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

import BuildController from "./controllers/build_controller"
import BuildsController from "./controllers/builds_controller"
import ChartsController from "./controllers/charts_controller"
import PipelinesController from "./controllers/pipelines_controller"
import ProjectsController from "./controllers/projects_controller"
import ReposController from "./controllers/repos_controller"
import TagsController from "./controllers/tags_controller"

const application = Application.start()
application.register("build", BuildController)
application.register("builds", BuildsController)
application.register("charts", ChartsController)
application.register("pipelines", PipelinesController)
application.register("projects", ProjectsController)
application.register("repos", ReposController)
application.register("tags", TagsController)

// Import local files
//
// Local files can be imported directly using relative
// paths "./socket" or full ones "web/static/js/socket".

$('[data-toggle="tooltip"]').tooltip();

$(".project-card").click(function() {
  window.location.href = $(this).data("url")
})

// Add class .active to current link
$('.sidebar-elements').find('a').each(function(_, element) {
  let cUrl = String(window.location).split('?')[0];
  element = $(element)

  if (cUrl.substr(cUrl.length - 1) == '#') {
    cUrl = cUrl.slice(0,-1);
  }

  if (cUrl.includes(element[0].href)) {
    element.addClass('active');

    element.parents('ul').add(element).each(function(){
      element.parent().addClass('active');
    });
  }
});

if ($("#aside").hasClass("page-aside")) {
  $(".alert").addClass("aci-aside")
}

const 
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
