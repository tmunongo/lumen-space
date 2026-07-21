import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["input", "form", "hiddenInput"]

  add(e) {
    e.preventDefault()
    const tag = this.inputTarget.value.trim().toLowerCase()
    if (!tag || tag.length > 50) return
    this.hiddenInputTarget.value = tag
    this.formTarget.style.display = 'block'
    this.formTarget.requestSubmit()
    this.inputTarget.value = ''
    this.formTarget.style.display = 'none'
  }
}
