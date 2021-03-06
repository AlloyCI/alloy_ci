import { Controller } from "stimulus"
import socket from "../socket"

export default class extends Controller {
  connect() {
    const id = this.data.get("id")
    const token = this.data.get("token")
    let channel = socket.channel(`build:${id}`, {})
    
    channel.join()
      .receive("ok", data => { console.log(`Joined successfully for build ${id}`, data) })
      .receive("error", data => { console.log("Unable to join", data) })

    channel.on("update_status", data => {
      $(`#build-${id}`).html(data.content.replace(/data-csrf="{1}.*=="/g, `data-csrf="${token}"`))
    })
  }
}
