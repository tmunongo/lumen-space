import { Controller } from "@hotwired/stimulus"
import * as pdfjsLib from "pdfjs-dist"

// PDF.js worker — must match the version pinned in importmap.rb
pdfjsLib.GlobalWorkerOptions.workerSrc =
  "https://cdnjs.cloudflare.com/ajax/libs/pdf.js/4.4.168/pdf.worker.min.mjs"

export default class extends Controller {
  static targets = [
    "loading", "error", "errorMsg", "pages", "toolbar",
    "currentPage", "totalPages", "prevBtn", "nextBtn", "zoomLabel"
  ]
  static values = { url: String, title: String }

  async connect() {
    this._scale = 1.5
    this._currentPage = 1
    this._totalPages = 0
    this._pdf = null

    await this.loadPdf()
  }

  disconnect() {
    if (this._pdf) {
      this._pdf.destroy()
      this._pdf = null
    }
  }

  get storageKey() {
    return this.urlValue ? `lumen_pdf_page_${this.urlValue}` : null
  }

  saveCurrentPage() {
    if (this.storageKey) {
      localStorage.setItem(this.storageKey, this._currentPage.toString())
    }
  }

  async loadPdf() {
    try {
      const loadingTask = pdfjsLib.getDocument({
        url: this.urlValue,
        cMapUrl: "https://cdnjs.cloudflare.com/ajax/libs/pdf.js/4.4.168/cmaps/",
        cMapPacked: true
      })

      this._pdf = await loadingTask.promise
      this._totalPages = this._pdf.numPages

      this.hideLoading()
      this.showPages()

      if (this.hasTotalPagesTarget) this.totalPagesTarget.textContent = this._totalPages
      this.updatePageInfo()
      this.updateNavButtons()

      // Render all pages sequentially into canvases
      for (let i = 1; i <= this._totalPages; i++) {
        await this.renderPage(i)
      }

      // Restore saved page position
      const savedPage = this.storageKey ? localStorage.getItem(this.storageKey) : null
      if (savedPage) {
        const pageNum = parseInt(savedPage, 10)
        if (pageNum > 1 && pageNum <= this._totalPages) {
          this._currentPage = pageNum
          this.updatePageInfo()
          this.updateNavButtons()
          this.scrollToPage(pageNum)
        }
      }
    } catch (err) {
      console.error("PDF.js load error:", err)
      this.showError(err.message || "Could not load PDF.")
    }
  }

  async renderPage(pageNum) {
    const page = await this._pdf.getPage(pageNum)
    const viewport = page.getViewport({ scale: this._scale })

    const wrapper = document.createElement("div")
    wrapper.className = "pdf-viewer__page"
    wrapper.dataset.pageNum = pageNum

    const canvas = document.createElement("canvas")
    canvas.width = viewport.width
    canvas.height = viewport.height

    const pageLabel = document.createElement("div")
    pageLabel.className = "pdf-viewer__page-label"
    pageLabel.textContent = `Page ${pageNum}`

    wrapper.appendChild(canvas)
    wrapper.appendChild(pageLabel)
    this.pagesTarget.appendChild(wrapper)

    const ctx = canvas.getContext("2d")
    await page.render({ canvasContext: ctx, viewport }).promise
    page.cleanup()
  }

  // Scroll-based page tracking (fires on pagesTarget scroll)
  onScroll() {
    if (!this._totalPages) return
    const pages = this.pagesTarget.querySelectorAll(".pdf-viewer__page")
    const containerTop = this.pagesTarget.scrollTop

    let closestPage = 1
    let closestDist = Infinity
    pages.forEach((el, idx) => {
      const dist = Math.abs(el.offsetTop - containerTop)
      if (dist < closestDist) { closestDist = dist; closestPage = idx + 1 }
    })

    if (closestPage !== this._currentPage) {
      this._currentPage = closestPage
      this.updatePageInfo()
      this.updateNavButtons()
      this.saveCurrentPage()
    }
  }

  prevPage() {
    if (this._currentPage <= 1) return
    this._currentPage--
    this.scrollToPage(this._currentPage)
    this.updatePageInfo()
    this.updateNavButtons()
    this.saveCurrentPage()
  }

  nextPage() {
    if (this._currentPage >= this._totalPages) return
    this._currentPage++
    this.scrollToPage(this._currentPage)
    this.updatePageInfo()
    this.updateNavButtons()
    this.saveCurrentPage()
  }

  zoomIn() {
    this._scale = Math.min(this._scale + 0.25, 3.0)
    this.rerender()
  }

  zoomOut() {
    this._scale = Math.max(this._scale - 0.25, 0.5)
    this.rerender()
  }

  async rerender() {
    if (!this._pdf) return
    if (this.hasZoomLabelTarget) {
      this.zoomLabelTarget.textContent = `${Math.round(this._scale * 100)}%`
    }
    const savedPage = this._currentPage
    this.pagesTarget.innerHTML = ""
    for (let i = 1; i <= this._totalPages; i++) {
      await this.renderPage(i)
    }
    this.scrollToPage(savedPage)
  }

  scrollToPage(pageNum) {
    const el = this.pagesTarget.querySelector(`[data-page-num="${pageNum}"]`)
    if (el) el.scrollIntoView({ behavior: "smooth", block: "start" })
  }

  // --- Helpers ---
  updatePageInfo() {
    if (this.hasCurrentPageTarget) this.currentPageTarget.textContent = this._currentPage
  }

  updateNavButtons() {
    if (this.hasPrevBtnTarget) this.prevBtnTarget.disabled = this._currentPage <= 1
    if (this.hasNextBtnTarget) this.nextBtnTarget.disabled = this._currentPage >= this._totalPages
  }

  hideLoading() {
    if (this.hasLoadingTarget) this.loadingTarget.style.display = "none"
  }

  showPages() {
    if (this.hasPagesTarget) this.pagesTarget.style.display = "flex"
    if (this.hasToolbarTarget) this.toolbarTarget.style.display = "flex"
  }

  showError(msg) {
    this.hideLoading()
    if (this.hasErrorTarget) this.errorTarget.style.display = "flex"
    if (this.hasErrorMsgTarget) this.errorMsgTarget.textContent = msg || "Could not load PDF."
  }
}
