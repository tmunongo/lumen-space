import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["progress", "scroll", "highlightToolbar", "selectedText", "highlightForm"]

  connect() {
    this._selectedStyle = 'yellow'
    this._selectionHandler = () => this.onSelectionChange()
    document.addEventListener('selectionchange', this._selectionHandler)

    // Restore saved scroll position / reading progress
    this.restoreScrollPosition()

    // Preserve scroll position when Turbo updates content
    this._beforeRenderHandler = (e) => this.preserveScrollPosition(e)
    document.addEventListener("turbo:before-stream-render", this._beforeRenderHandler)
  }

  disconnect() {
    document.removeEventListener('selectionchange', this._selectionHandler)
    if (this._beforeRenderHandler) {
      document.removeEventListener("turbo:before-stream-render", this._beforeRenderHandler)
    }
  }

  get artifactId() {
    return this.element.dataset.artifactId
  }

  get storageKey() {
    return this.artifactId ? `lumen_reader_scroll_${this.artifactId}` : null
  }

  restoreScrollPosition() {
    if (!this.hasScrollTarget || !this.storageKey) return
    const savedScroll = localStorage.getItem(this.storageKey)
    if (savedScroll !== null) {
      this.scrollTarget.scrollTop = parseFloat(savedScroll)
    }
    this.updateProgressBar()
  }

  preserveScrollPosition(event) {
    if (!this.hasScrollTarget) return
    const currentScroll = this.scrollTarget.scrollTop
    requestAnimationFrame(() => {
      if (this.hasScrollTarget) {
        this.scrollTarget.scrollTop = currentScroll
      }
    })
  }

  onScroll() {
    const el = this.scrollTarget
    if (!el) return
    this.updateProgressBar()
    if (this.storageKey) {
      localStorage.setItem(this.storageKey, el.scrollTop.toString())
    }
  }

  updateProgressBar() {
    if (!this.hasProgressTarget || !this.hasScrollTarget) return
    const el = this.scrollTarget
    const maxScroll = el.scrollHeight - el.clientHeight
    if (maxScroll <= 0) {
      this.progressTarget.style.width = '0%'
      return
    }
    const progress = Math.min(Math.max(el.scrollTop / maxScroll, 0), 1)
    this.progressTarget.style.width = `${(progress * 100).toFixed(1)}%`
  }

  preventDeselect(e) {
    // Prevent mouse clicks on tooltip controls from deselecting document text
    e.preventDefault()
  }

  onSelectionChange() {
    const selection = window.getSelection()
    const text = selection?.toString().trim()

    if (text && text.length > 0 && this.element.contains(selection.anchorNode)) {
      if (this.hasHighlightToolbarTarget) this.highlightToolbarTarget.style.display = 'flex'
      if (this.hasSelectedTextTarget) this.selectedTextTarget.value = text
    } else {
      // Do not hide toolbar if focus/activeElement is inside toolbar
      if (this.hasHighlightToolbarTarget && this.highlightToolbarTarget.contains(document.activeElement)) {
        return
      }
      if (this.hasHighlightToolbarTarget) this.highlightToolbarTarget.style.display = 'none'
    }
  }

  setHighlightStyle(e) {
    e.preventDefault()
    this._selectedStyle = e.currentTarget.dataset.style
    const hiddenInput = this.element.querySelector('input[name="artifact_highlight[style]"]')
    if (hiddenInput) hiddenInput.value = this._selectedStyle
    this.element.querySelectorAll('.highlight-color').forEach(btn => btn.classList.remove('active'))
    e.currentTarget.classList.add('active')
  }

  onHighlightSubmitted() {
    if (this.hasHighlightToolbarTarget) {
      this.highlightToolbarTarget.style.display = 'none'
    }
    if (this.hasSelectedTextTarget) {
      this.selectedTextTarget.value = ''
    }
    window.getSelection()?.removeAllRanges()
  }
}
