import { Controller } from "stimulus"
import socket from "../socket"

export default class extends Controller {
  static targets = [ "input" ]

  connect() {
    let channel = socket.channel(`repos:${this.data.get("user")}`, {})
    channel.join()
      .receive("ok", data => { console.log("Joined successfully", data) })
      .receive("error", data => { console.log("Unable to join", data) })

    channel.on("repos_ready", data => {
      $("#repos-container").html(data.html)
    })
  }

  filter() {
    let filter = this.inputTarget.value.toUpperCase()

    $(".filter").each(function(_, element) {
      element = $(element)
      let id = element.data("id")
      let card = $(`#card-${id}`)

      if(element.text().toUpperCase().includes(filter)) {
        card.show()
      } else {
        card.hide()
      }
    })
  }
}
