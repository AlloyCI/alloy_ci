import socket from "./socket"

if(document.querySelector("#repos-container")) {
  let channel = socket.channel("repos:"+window.userID, {})
  channel.join()
    .receive("ok", data => { console.log("Joined successfully", data) })
    .receive("error", data => { console.log("Unable to join", data) })

  channel.on("repos_ready", data => {
    $("#repos-container").html(data.html)
  })
}
