import { Controller } from "stimulus"
import socket from "../socket"

export default class extends Controller {
  static targets = [ "input" ]

  connect() {
    let channel = socket.channel(`repos:${window.userID}`, {})
    channel.join()
      .receive("ok", data => { console.log("Joined successfully", data) })
      .receive("error", data => { console.log("Unable to join", data) })

    channel.on("repos_ready", data => {
      console.log("Received data")
      $("#repos-container").html(data.html)
    })
  }

  filter() {
    let filter = this.inputTarget.value.toUpperCase()

    $(".filter").each(function(index) {
      if(($(this).text().toUpperCase().indexOf(filter) > -1)) {
        var id = $(this).data("id")
        $(`#card-${id}`).show()
      } else {
        var id = $(this).data("id")
        $(`#card-${id}`).hide()
      }
    })
  }
}
