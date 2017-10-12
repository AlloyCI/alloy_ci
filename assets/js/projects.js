$(document).on("click", ".remove-tag", function(e) {
  let id = $(this).data("id")
  $("#"+id).remove()
})

$("#add-tag").click(function(e) {
  let value = $("#tag-input").val()
  if(value) {
    $("#tag-input").val("")
    let element = $(this).data("prototype").replace(/gen_new_id/g, Math.random().toString(36).substring(5))
    $("#tags-container").append(element.replace(/replace_me/g, value))
  }
})

$(document).on("keypress", "#tag-input", function(args) {
  if (args.keyCode == 13) {
    $("#add-tag").click()
    return false
  }
})

if(document.querySelector(".chart")) {
  function scales(ctx) {
    let result = {}

    if(ctx.data("type") === "line"){
      result =
        {
          xAxes: [{
            display: true,
            scaleLabel: {
              display: true,
              labelString: ctx.data("label")
            }
          }],
          yAxes: [{
            display: true,
            scaleLabel: {
              display: true,
              labelString: ctx.data("axis")
            }
          }]
        }
    }
    return result
  }

  function options(ctx) {
    let result =
      {
        responsive: true,
        title: {
          display:true,
          text: ctx.data("title")
        },
        tooltips: {
          mode: 'index',
          intersect: false,
        },
        hover: {
          mode: 'nearest',
          intersect: true
        }
      }

    let scale = scales(ctx)

    if(!$.isEmptyObject(scale)){
      result["scales"] = scale
    }
    return result
  }

  document.querySelectorAll('.chart').forEach(function(e) {
    let ctx = $(e)
    let data = ctx.data("set")

    let chart = new Chart(ctx, {
      // The type of chart we want to create
      type: ctx.data("type"),
      data: data,
      // Configuration options go here
      options: options(ctx)
    })
  })
}
