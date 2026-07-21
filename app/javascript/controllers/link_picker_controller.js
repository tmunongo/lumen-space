import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["picker"]

  toggle() {
    const picker = this.pickerTarget
    picker.style.display = (picker.style.display === 'none' || picker.style.display === '') ? 'block' : 'none'
  }
}
