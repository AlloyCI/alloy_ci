import socket from "./socket"

$("#repo-filter").on("keyup", function() {
  let filter = $(this).val().toUpperCase()

  $(".filter").each(function(index) {
    if(($(this).text().toUpperCase().indexOf(filter) > -1)) {
      var id = $(this).data("id")
      $("#card-"+id).show()
    } else {
      var id = $(this).data("id")
      $("#card-"+id).hide()
    }
  })
})

$(".project-card").click(function(){
  window.location.href = $(this).data("url")
})

if(document.querySelector("#repos-container")) {
  let channel = socket.channel("repos:"+window.userID, {})
  channel.join()
    .receive("ok", data => { console.log("Joined successfully", data) })
    .receive("error", data => { console.log("Unable to join", data) })

  channel.on("repos_ready", data => {
    $("#repos-container").html(data.html)
  })
}
