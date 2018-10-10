import { Controller } from "stimulus"
import "chart.js"

export default class extends Controller {
  connect() {
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
              ticks: {
                min: 0,
                stepSize: 2
              }, 
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
}
