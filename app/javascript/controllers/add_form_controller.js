import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["panel"]

  connect() {
    // Ensure the first panel is active on connect
    if (!this.panelTargets.some(p => p.classList.contains('active'))) {
      const first = this.panelTargets[0]
      if (first) first.classList.add('active')
    }
  }

  showTab(e) {
    const tabName = e.currentTarget.dataset.tab
    // Update tabs
    this.element.querySelectorAll('.add-form__tab').forEach(t => t.classList.remove('active'))
    e.currentTarget.classList.add('active')
    // Update panels
    this.panelTargets.forEach(p => {
      p.classList.toggle('active', p.dataset.panel === tabName)
    })
  }

  setUrlTitle(e) {
    const urlInput = document.getElementById('url-input')
    const titleInput = document.getElementById('url-title-hidden')
    if (urlInput && titleInput && titleInput.value === '') {
      titleInput.value = urlInput.value
    }
  }
}
