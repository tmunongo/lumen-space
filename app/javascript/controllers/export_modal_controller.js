import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["modal", "output", "copyButton"]

  connect() {
    this.boundKeydown = this.handleKeydown.bind(this)
    window.addEventListener("keydown", this.boundKeydown)
  }

  disconnect() {
    window.removeEventListener("keydown", this.boundKeydown)
  }

  handleKeydown(event) {
    if (event.key === "Escape") {
      this.close()
    }
  }

  open(event) {
    if (event) event.preventDefault()
    if (this.hasModalTarget) {
      this.modalTarget.classList.add("modal--open")
    }
  }

  close(event) {
    if (event) event.preventDefault()
    if (this.hasModalTarget) {
      this.modalTarget.classList.remove("modal--open")
    }
  }

  copy(event) {
    if (event) event.preventDefault()
    if (!this.hasOutputTarget) return

    const text = this.outputTarget.value || this.outputTarget.innerText
    navigator.clipboard.writeText(text).then(() => {
      if (this.hasCopyButtonTarget) {
        const originalText = this.copyButtonTarget.innerHTML
        this.copyButtonTarget.innerHTML = "✓ Copied!"
        this.copyButtonTarget.classList.add("btn--success")
        setTimeout(() => {
          this.copyButtonTarget.innerHTML = originalText
          this.copyButtonTarget.classList.remove("btn--success")
        }, 2000)
      }
    })
  }
}
