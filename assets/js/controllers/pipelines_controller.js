import { Controller } from "stimulus"
import socket from "../socket"

export default class extends Controller {
  connect() {
    const id = this.data.get("id")
    let channel = socket.channel(`pipeline:${id}`, {})
    channel.join()
      .receive("ok", data => { console.log(`Joined successfully for pipeline ${id}`, data) })
      .receive("error", data => { console.log("Unable to join", data) })

    channel.on("update_status", data => {
      $(`#pipeline-${id}`).html(data.content)
    })
  }
}
