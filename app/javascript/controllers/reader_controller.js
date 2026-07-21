import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["progress", "scroll", "highlightToolbar", "selectedText", "highlightForm"]

  connect() {
    this._selectedStyle = 'yellow'
    this._selectionHandler = () => this.onSelectionChange()
    document.addEventListener('selectionchange', this._selectionHandler)
  }

  disconnect() {
    document.removeEventListener('selectionchange', this._selectionHandler)
  }

  onScroll() {
    const el = this.scrollTarget
    if (!el || el.scrollHeight <= el.clientHeight) return
    const progress = el.scrollTop / (el.scrollHeight - el.clientHeight)
    if (this.hasProgressTarget) {
      this.progressTarget.style.width = `${(progress * 100).toFixed(1)}%`
    }
  }

  onSelectionChange() {
    const selection = window.getSelection()
    const text = selection?.toString().trim()
    if (text && text.length > 0 && this.element.contains(selection.anchorNode)) {
      if (this.hasHighlightToolbarTarget) this.highlightToolbarTarget.style.display = 'flex'
      if (this.hasSelectedTextTarget) this.selectedTextTarget.value = text
    } else {
      if (this.hasHighlightToolbarTarget) this.highlightToolbarTarget.style.display = 'none'
    }
  }

  setHighlightStyle(e) {
    this._selectedStyle = e.currentTarget.dataset.style
    const hiddenInput = this.element.querySelector('input[name="artifact_highlight[style]"]')
    if (hiddenInput) hiddenInput.value = this._selectedStyle
    this.element.querySelectorAll('.highlight-color').forEach(btn => btn.classList.remove('active'))
    e.currentTarget.classList.add('active')
  }
}
