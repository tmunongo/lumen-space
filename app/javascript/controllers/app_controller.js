import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["sidebar", "backdrop"]

  connect() {
    this.bindShortcuts()
  }

  disconnect() {
    document.removeEventListener("keydown", this._shortcutHandler)
  }

  toggleSidebar(e) {
    if (e) e.preventDefault()
    this.element.classList.toggle("app-shell--sidebar-open")
  }

  openSidebar(e) {
    if (e) e.preventDefault()
    this.element.classList.add("app-shell--sidebar-open")
  }

  closeSidebar(e) {
    if (e) e.preventDefault()
    this.element.classList.remove("app-shell--sidebar-open")
  }

  // Close sidebar on mobile when navigating/selecting item
  closeSidebarOnMobile(e) {
    if (window.innerWidth < 768) {
      this.closeSidebar()
    }
  }

  bindShortcuts() {
    this._shortcutHandler = (e) => {
      if (e.key === "Escape" && this.element.classList.contains("app-shell--sidebar-open")) {
        this.closeSidebar()
        return
      }

      if ((e.metaKey || e.ctrlKey) && e.key === "n") {
        e.preventDefault()
        const input = document.getElementById("new-project-input") || document.getElementById("url-input")
        input?.focus()
      }
    }
    document.addEventListener("keydown", this._shortcutHandler)
  }
}

