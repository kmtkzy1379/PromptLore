import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static values = {
    url: String,
    type: String
  }

  static targets = [
    "installWebGuide",
    "installBashGuide",
    "installPsGuide",
    "useWebGuide",
    "useLocalGuide"
  ]

  async installWeb(event) {
    const btn = event.currentTarget
    const data = await this.fetchContent()
    if (!data) return

    let text
    if (this.typeValue === "repository") {
      text = `# ${data.filename}\n\n${data.content}`
    } else {
      text = data.files.map(f => `# ${f.filename}\n\n${f.content}`).join("\n\n---\n\n")
    }

    await this.copyAndGuide(btn, text, this.installWebGuideTarget)
  }

  async installLocalBash(event) {
    const btn = event.currentTarget
    const data = await this.fetchContent()
    if (!data) return

    const files = this.typeValue === "repository"
      ? [{ filename: data.filename, file_type: data.file_type, content: data.content }]
      : data.files

    const script = this.generateBashScript(files)
    await this.copyAndGuide(btn, script, this.installBashGuideTarget)
  }

  async installLocalPowershell(event) {
    const btn = event.currentTarget
    const data = await this.fetchContent()
    if (!data) return

    const files = this.typeValue === "repository"
      ? [{ filename: data.filename, file_type: data.file_type, content: data.content }]
      : data.files

    const script = this.generatePowershellScript(files)
    await this.copyAndGuide(btn, script, this.installPsGuideTarget)
  }

  async useWeb(event) {
    const btn = event.currentTarget
    const data = await this.fetchContent()
    if (!data) return

    let text
    if (this.typeValue === "repository") {
      text = `以下の${data.file_type === "claude_md" ? "CLAUDE.md" : "スキル"}の指示に従って作業してください。\n\n---\n${data.content}\n---`
    } else {
      const sections = data.files.map(f => {
        const label = f.file_type === "claude_md" ? "CLAUDE.md" : f.filename
        return `# ${label}\n${f.content}`
      }).join("\n\n---\n\n")
      text = `以下のCLAUDE.mdとスキルの指示に従って作業してください。\n\n---\n${sections}\n---`
    }

    await this.copyAndGuide(btn, text, this.useWebGuideTarget)
  }

  async useLocal(event) {
    const btn = event.currentTarget
    const data = await this.fetchContent()
    if (!data) return

    let text
    if (this.typeValue === "repository") {
      text = data.content
    } else {
      text = data.files.map(f => {
        const label = f.file_type === "claude_md" ? "CLAUDE.md" : f.filename
        return `# ${label}\n\n${f.content}`
      }).join("\n\n---\n\n")
    }

    await this.copyAndGuide(btn, text, this.useLocalGuideTarget)
  }

  // --- Private helpers ---

  async fetchContent() {
    if (this._cached) return this._cached
    try {
      const response = await fetch(this.urlValue, {
        headers: { "Accept": "application/json" }
      })
      if (!response.ok) return null
      this._cached = await response.json()
      return this._cached
    } catch {
      return null
    }
  }

  generateBashScript(files) {
    const lines = []
    const needsDir = files.some(f => f.file_type !== "claude_md")

    if (needsDir) {
      lines.push("mkdir -p .claude/commands")
    }

    files.forEach(f => {
      const path = this.targetPath(f.filename, f.file_type)
      const delimiter = this.safeDelimiter(f.content)
      lines.push(`cat > ${path} << '${delimiter}'`)
      lines.push(f.content)
      lines.push(delimiter)
    })

    const count = files.length
    const name = this.typeValue === "preset" ? ` from preset` : ""
    lines.push(`echo "Installed ${count} file(s)${name}"`)

    return lines.join("\n")
  }

  generatePowershellScript(files) {
    const lines = []
    const needsDir = files.some(f => f.file_type !== "claude_md")

    if (needsDir) {
      lines.push('New-Item -ItemType Directory -Force -Path ".claude\\commands" | Out-Null')
    }

    files.forEach(f => {
      const path = this.targetPath(f.filename, f.file_type).replace(/\//g, "\\")
      const escaped = f.content.replace(/"/g, '`"')
      lines.push(`@"`)
      lines.push(escaped)
      lines.push(`"@ | Set-Content -Path "${path}" -Encoding UTF8`)
    })

    const count = files.length
    lines.push(`Write-Host "Installed ${count} file(s)"`)

    return lines.join("\n")
  }

  targetPath(filename, fileType) {
    if (fileType === "claude_md") return "CLAUDE.md"
    const name = filename.replace(/\.md$/i, "").replace(/[^a-zA-Z0-9_\-]/g, "_")
    return `.claude/commands/${name}.md`
  }

  safeDelimiter(content) {
    let delimiter = "PROMPTLORE_EOF"
    let i = 1
    while (content.includes(`\n${delimiter}\n`) || content.startsWith(`${delimiter}\n`) || content.endsWith(`\n${delimiter}`)) {
      delimiter = `PROMPTLORE_EOF_${i}`
      i++
    }
    return delimiter
  }

  async copyAndGuide(btn, text, guideTarget) {
    try {
      await navigator.clipboard.writeText(text)
      const original = btn.textContent
      btn.textContent = "Copied!"
      btn.disabled = true
      setTimeout(() => {
        btn.textContent = original
        btn.disabled = false
      }, 2000)

      if (guideTarget) {
        guideTarget.style.display = "block"
      }
    } catch {
      const textarea = document.createElement("textarea")
      textarea.value = text
      textarea.style.position = "fixed"
      textarea.style.opacity = "0"
      document.body.appendChild(textarea)
      textarea.select()
      document.execCommand("copy")
      document.body.removeChild(textarea)

      if (guideTarget) {
        guideTarget.style.display = "block"
      }
    }
  }
}
