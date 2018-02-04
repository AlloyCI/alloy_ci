import { Controller } from "stimulus"

export default class extends Controller {
  static targets = [ "input", "container", "prototype" ]

  addTag() {
    let value = this.inputTarget.value
    if(value) {
      this.inputTarget.value = ""
      let element = $(this.prototypeTarget).data("prototype").replace(/gen_new_id/g, Math.random().toString(36).substring(5))
      $(this.containerTarget).append(element.replace(/replace_me/g, value))
    }
  }

  addTagOnEnter(e) {
    if(e.keyCode == 13) {
      e.preventDefault()
      this.addTag()
    }
  }

  removeTag(e) {
    let id = $(e.target).data("id")
    $(`#${id}`).remove()
  }
}
