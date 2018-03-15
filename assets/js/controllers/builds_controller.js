import { Controller } from "stimulus"
import socket from "../socket"

export default class extends Controller {

  connect() {
    let Ansi = require("ansi-to-html")
    const ansi = new Ansi()

    const buildName = this.data.get("name")
    const trace = this.data.get("trace")
    
    if (trace == "") {
      var contents = "Build is pending"
    } else {
      var contents = ansi.toHtml(trace)
    }

    $("#output").html(`<h3>${buildName}</h3>${contents.replace(/\n/g, "<br />")}`)

    let channel = socket.channel(`builds:${this.data.get("id")}`, {})
    channel.join()
      .receive("ok", data => { console.log("Joined successfully", data) })
      .receive("error", data => { console.log("Unable to join", data) })

    channel.on("append_trace", data => {
      $("#output").append(ansi.toHtml(data.trace).replace(/\n/g, "<br/>"))
      $(window).scrollTop($(document).height())
    })

    channel.on("replace_trace", data => {
      setTimeout(function(){
        window.location.reload(true)
      }, 1500)
    })
  }
}
