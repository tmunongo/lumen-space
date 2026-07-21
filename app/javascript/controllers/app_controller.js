import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  connect() {
    this.bindShortcuts()
  }

  disconnect() {
    document.removeEventListener("keydown", this._shortcutHandler)
  }

  bindShortcuts() {
    this._shortcutHandler = (e) => {
      if ((e.metaKey || e.ctrlKey) && e.key === "n") {
        e.preventDefault()
        const input = document.getElementById("new-project-input") || document.getElementById("url-input")
        input?.focus()
      }
    }
    document.addEventListener("keydown", this._shortcutHandler)
  }
}
