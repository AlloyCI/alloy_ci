import { Controller } from "stimulus"
import socket from "../socket"

export default class extends Controller {

  connect() {
    window.output = $("#output")
  }

  fetchData(e) {
    e.preventDefault
    let Ansi = require("ansi-to-html")
    const ansi = new Ansi()
    
    const target = $(e.target)
    target.tooltip("hide")
    $("a.active").removeClass("active")
    target.addClass("active")

    const id = target.data("id")
    const buildUrl = target.data("build-url")
    const buildName = target.data("name")

    let output = window.output.attr("id",`output-${id}`)

    fetch(buildUrl, {credentials: 'include'})
      .then(response => response.json())
      .then(data => {
        if (data.trace == "") {
          var contents = "Build is pending"
        } else {
          var contents = ansi.toHtml(data.trace)
        }
        output.html(`<h3>${buildName}</h3>${contents.replace(/\n/g, "<br />")}`)
        $(window).scrollTop(0)
      })

    let channel = socket.channel(`builds:${id}`, {})
    channel.join()
      .receive("ok", data => { console.log("Joined successfully", data) })
      .receive("error", data => { console.log("Unable to join", data) })

    channel.on("append_trace", data => {
      $(`#output-${id}`).append(ansi.toHtml(data.trace).replace(/\n/g, "<br/>"))
      $(window).scrollTop($(document).height())
    })

    channel.on("replace_trace", data => {
      setTimeout(function(){
        window.location.reload(true)
      }, 1500)
    })
  }
}
