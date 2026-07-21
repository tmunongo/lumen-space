import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  connect() {
    this._timeout = setTimeout(() => this.dismiss(), 4000)
  }

  disconnect() {
    clearTimeout(this._timeout)
  }

  dismiss() {
    this.element.style.opacity = '0'
    this.element.style.transition = 'opacity 0.3s ease'
    setTimeout(() => this.element.remove(), 300)
  }
}
