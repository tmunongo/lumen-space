import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["menu"]

  connect() {
    this._clickOutside = (e) => {
      if (!this.element.contains(e.target)) this.close()
    }
    document.addEventListener("click", this._clickOutside)
  }

  disconnect() {
    document.removeEventListener("click", this._clickOutside)
  }

  toggle(e) {
    e.stopPropagation()
    const menu = this.menuTarget
    const isOpen = menu.style.display !== 'none' && menu.style.display !== ''
    if (isOpen) {
      this.close()
    } else {
      menu.style.display = 'block'
    }
  }

  close() {
    if (this.hasMenuTarget) this.menuTarget.style.display = 'none'
  }
}
