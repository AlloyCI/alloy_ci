import { Controller } from "stimulus"
import "codemirror/addon/edit/matchbrackets"
import "codemirror/addon/display/placeholder"
import "codemirror/mode/javascript/javascript"

export default class extends Controller {
  static targets = [ "input" ]

  connect() {
    let CodeMirror = require("codemirror")
    var myCodeMirror = 
      CodeMirror.fromTextArea(
        document.getElementById("project_secret_variables"),
        {
          lineNumbers: true,
          matchBrackets: true,
          mode: {name: "javascript", json: true},
          theme: "dracula",
          tabSize: 2
        }
      );
  }
}
