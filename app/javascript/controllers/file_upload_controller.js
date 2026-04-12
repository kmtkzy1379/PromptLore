import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["fileInput", "folderInput", "preview", "pathsField"]

  selectFiles() {
    this.fileInputTarget.click()
  }

  selectFolder() {
    this.folderInputTarget.click()
  }

  onFilesSelected(event) {
    const files = Array.from(event.target.files)
    if (files.length === 0) return
    // Individual files: no path info needed (all go to root)
    this.pathsFieldTarget.value = ""
    this.renderPreview(files.map(f => ({ subdirectory: "", filename: f.name })), false)
  }

  onFolderSelected(event) {
    const files = Array.from(event.target.files)
    if (files.length === 0) return

    // Build path info for every file (same order as FileList)
    const paths = []
    const displayFiles = []

    for (const file of files) {
      const relPath = file.webkitRelativePath || file.name
      const parts = relPath.split("/")
      // Strip root folder: "skill-creator/scripts/init.py" → "scripts/init.py"
      const withoutRoot = parts.slice(1).join("/")
      const lastSlash = withoutRoot.lastIndexOf("/")

      let subdirectory = ""
      let filename = withoutRoot

      if (lastSlash > -1) {
        subdirectory = withoutRoot.substring(0, lastSlash)
        filename = withoutRoot.substring(lastSlash + 1)
      }

      // Mark files to skip (hidden, __pycache__, etc.) but still include in paths array
      // Server will filter based on the "skip" flag
      const skip = filename.startsWith(".") ||
        subdirectory.split("/").some(s => s.startsWith(".")) ||
        subdirectory.includes("__pycache__") ||
        subdirectory.includes("node_modules")

      paths.push({ subdirectory, filename, skip })

      if (!skip) {
        displayFiles.push({ subdirectory, filename })
      }
    }

    // Store paths as JSON for the server
    this.pathsFieldTarget.value = JSON.stringify(paths)

    // Sort display files for preview
    displayFiles.sort((a, b) => {
      if (!a.subdirectory && b.subdirectory) return -1
      if (a.subdirectory && !b.subdirectory) return 1
      const aPath = a.subdirectory ? `${a.subdirectory}/${a.filename}` : a.filename
      const bPath = b.subdirectory ? `${b.subdirectory}/${b.filename}` : b.filename
      return aPath.localeCompare(bPath)
    })

    this.renderPreview(displayFiles, true)
  }

  renderPreview(files, isFolder) {
    if (files.length === 0) {
      this.previewTarget.innerHTML = ""
      return
    }

    const hasSkillMd = files.some(f => !f.subdirectory && f.filename.toLowerCase() === "skill.md")

    let html = `<div style="margin-top: 8px; padding: 10px; background: #f6f8fa; border: 1px solid #ddd; border-radius: 6px;">`

    if (hasSkillMd) {
      html += `<p style="margin: 0 0 6px; color: #2da44e; font-weight: bold;">Skill Package detected (SKILL.md found)</p>`
    }

    html += `<p style="margin: 0 0 6px; color: #555;">${files.length} file(s) selected:</p>`
    html += `<div style="font-family: monospace; font-size: 0.85em; line-height: 1.6;">`

    for (const f of files) {
      const dirPart = f.subdirectory ? `<span style="color: #666;">${f.subdirectory}/</span>` : ""
      html += `<div style="padding: 1px 0;">${dirPart}<strong>${f.filename}</strong></div>`
    }

    html += `</div></div>`
    this.previewTarget.innerHTML = html
  }
}
