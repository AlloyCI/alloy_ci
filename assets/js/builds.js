import socket from "./socket"

var Ansi = require("ansi-to-html")
var ansi = new Ansi()

// Now that you are connected, you can join channels with a topic:
if(document.querySelector("#output")) {
  window.output = $("#output")

  $(".build-get").click(function(e) {
    e.preventDefault
    $(this).tooltip("hide")
    $("a.active").removeClass("active")
    $(this).addClass("active")

    let id = $(this).data("id")
    let project_id = $(this).data("project-id")
    let build_name = $(this).data("name")

    let trace_update = data => {
      if(data.trace == "") {
        var contents = "Build is pending"
      } else {
        var contents = ansi.toHtml(data.trace)
      }
      output.html("<h3>"+build_name+"</h3>"+contents.replace(/\n/g, "<br />"))
      $(window).scrollTop(0)
    }

    let output = window.output.attr("id","output-"+id)

    $.ajax({
      type: "GET",
      url: "/projects/" + project_id + "/builds/" + id,
      success: trace_update,
      dataType: "json"
    })

    let channel = socket.channel("builds:"+id, {})
    channel.join()
      .receive("ok", data => { console.log("Joined successfully", data) })
      .receive("error", data => { console.log("Unable to join", data) })

    channel.on("append_trace", data => {
      $("#output-"+id).append(ansi.toHtml(data.trace).replace(/\n/g, "<br/>"))
      $(window).scrollTop($(document).height())
    })

    channel.on("replace_trace", data => {
      setTimeout(function(){
        window.location.reload(true)
        $(this).click()
      }, 1500)
    })
  })
}
