import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static values = {
    url: String,
    type: String,
    skillPackage: { type: Boolean, default: false }
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
    } else if (data.is_skill_package) {
      text = this.generateWebMergedContent(data.skill_name, data.files)
    } else {
      text = data.files.map(f => `# ${f.filename}\n\n${f.content}`).join("\n\n---\n\n")
    }

    await this.copyAndGuide(btn, text, this.installWebGuideTarget)
  }

  async installLocalBash(event) {
    const btn = event.currentTarget
    const data = await this.fetchContent()
    if (!data) return

    let script
    if (this.typeValue === "repository") {
      const files = [{ filename: data.filename, file_type: data.file_type, content: data.content, subdirectory: "", content_type: "text/markdown" }]
      script = this.generateBashScript(files)
    } else if (data.is_skill_package) {
      script = this.generateSkillBashScript(data.skill_name, data.files)
    } else {
      const files = data.files.map(f => ({ ...f, subdirectory: "", content_type: f.content_type || "text/markdown" }))
      script = this.generateBashScript(files)
    }

    await this.copyAndGuide(btn, script, this.installBashGuideTarget)
  }

  async installLocalPowershell(event) {
    const btn = event.currentTarget
    const data = await this.fetchContent()
    if (!data) return

    let script
    if (this.typeValue === "repository") {
      const files = [{ filename: data.filename, file_type: data.file_type, content: data.content, subdirectory: "", content_type: "text/markdown" }]
      script = this.generatePowershellScript(files)
    } else if (data.is_skill_package) {
      script = this.generateSkillPowershellScript(data.skill_name, data.files)
    } else {
      const files = data.files.map(f => ({ ...f, subdirectory: "", content_type: f.content_type || "text/markdown" }))
      script = this.generatePowershellScript(files)
    }

    await this.copyAndGuide(btn, script, this.installPsGuideTarget)
  }

  async useWeb(event) {
    const btn = event.currentTarget
    const data = await this.fetchContent()
    if (!data) return

    let text
    if (this.typeValue === "repository") {
      text = `以下の${data.file_type === "claude_md" ? "CLAUDE.md" : "スキル"}の指示に従って作業してください。\n\n---\n${data.content}\n---`
    } else if (data.is_skill_package) {
      const merged = this.generateWebMergedContent(data.skill_name, data.files)
      text = `以下のスキルの指示に従って作業してください。\n\n---\n${merged}\n---`
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
    } else if (data.is_skill_package) {
      text = this.generateWebMergedContent(data.skill_name, data.files)
    } else {
      text = data.files.map(f => {
        const label = f.file_type === "claude_md" ? "CLAUDE.md" : f.filename
        return `# ${label}\n\n${f.content}`
      }).join("\n\n---\n\n")
    }

    await this.copyAndGuide(btn, text, this.useLocalGuideTarget)
  }

  // --- Helper: Separate CLAUDE.md files from skill files ---

  splitFiles(files) {
    const claudeFiles = files.filter(f => f.file_type === "claude_md")
    const skillFiles = files.filter(f => f.file_type !== "claude_md")
    return { claudeFiles, skillFiles }
  }

  // --- Skill Package: Web Merged Content ---

  generateWebMergedContent(skillName, files) {
    const { claudeFiles, skillFiles } = this.splitFiles(files)
    const sections = []

    // CLAUDE.md section (separate from skill)
    for (const f of claudeFiles) {
      if (this.isBinary(f.content_type)) continue
      sections.push(`# CLAUDE.md（プロジェクト直下に配置）\n\n${f.content}`)
    }

    sections.push(`# Skill: ${skillName}`)

    // Sort: SKILL.md first, then by path alphabetically
    const sorted = [...skillFiles].sort((a, b) => {
      const aIsSkillMd = !a.subdirectory && a.filename.toLowerCase() === "skill.md"
      const bIsSkillMd = !b.subdirectory && b.filename.toLowerCase() === "skill.md"
      if (aIsSkillMd && !bIsSkillMd) return -1
      if (!aIsSkillMd && bIsSkillMd) return 1
      // Root files before subdirectory files
      if (!a.subdirectory && b.subdirectory) return -1
      if (a.subdirectory && !b.subdirectory) return 1
      return this.fileDisplayPath(a).localeCompare(this.fileDisplayPath(b))
    })

    for (const f of sorted) {
      if (this.isBinary(f.content_type)) continue
      if (f.content && f.content.length > 50000) {
        sections.push(`> [除外: ${this.fileDisplayPath(f)} — ファイルサイズが大きいため省略]`)
        continue
      }

      const path = this.fileDisplayPath(f)

      if (!f.subdirectory && f.filename.toLowerCase() === "skill.md") {
        // SKILL.md content directly (it's the core)
        sections.push(f.content)
      } else if (this.isScriptFile(f.filename)) {
        const lang = this.scriptLanguage(f.filename)
        sections.push(`## ${path}\n\n\`\`\`${lang}\n${f.content}\n\`\`\``)
      } else if (f.filename.toLowerCase().endsWith(".md")) {
        sections.push(`## ${path}\n\n${f.content}`)
      } else {
        // Other text files (LICENSE, .json, .yaml, etc.)
        const lang = this.scriptLanguage(f.filename)
        sections.push(`## ${path}\n\n\`\`\`${lang}\n${f.content}\n\`\`\``)
      }
    }

    return sections.join("\n\n---\n\n")
  }

  isScriptFile(filename) {
    return /\.(py|sh|bash|rb|js|ts)$/i.test(filename)
  }

  // --- Skill Package: Bash Script ---

  generateSkillBashScript(skillName, files) {
    const { claudeFiles, skillFiles } = this.splitFiles(files)
    const lines = []

    // CLAUDE.md → project root
    for (const f of claudeFiles) {
      if (this.isBinary(f.content_type)) continue
      const delimiter = this.safeDelimiter(f.content)
      lines.push(`cat > CLAUDE.md << '${delimiter}'`)
      lines.push(f.content)
      lines.push(delimiter)
    }

    // Skill files → .claude/commands/skillName/
    const base = `.claude/commands/${skillName}`
    const dirs = new Set([base])

    for (const f of skillFiles) {
      if (this.isBinary(f.content_type)) continue
      if (f.subdirectory) dirs.add(`${base}/${f.subdirectory}`)
    }

    lines.push(`mkdir -p ${[...dirs].join(" ")}`)

    for (const f of skillFiles) {
      if (this.isBinary(f.content_type)) {
        lines.push(`# Skipped binary: ${this.fileDisplayPath(f)}`)
        continue
      }
      const subdir = f.subdirectory ? `${f.subdirectory}/` : ""
      const path = `${base}/${subdir}${f.filename}`
      const delimiter = this.safeDelimiter(f.content)
      lines.push(`cat > ${path} << '${delimiter}'`)
      lines.push(f.content)
      lines.push(delimiter)
      if (this.isScriptFile(f.filename)) {
        lines.push(`chmod +x ${path}`)
      }
    }

    const totalCount = claudeFiles.filter(f => !this.isBinary(f.content_type)).length +
                        skillFiles.filter(f => !this.isBinary(f.content_type)).length
    lines.push(`echo "Installed skill '${skillName}' (${totalCount} file(s))"`)
    return lines.join("\n")
  }

  // --- Skill Package: PowerShell Script ---

  generateSkillPowershellScript(skillName, files) {
    const { claudeFiles, skillFiles } = this.splitFiles(files)
    const lines = []

    // CLAUDE.md → project root
    for (const f of claudeFiles) {
      if (this.isBinary(f.content_type)) continue
      const escaped = f.content.replace(/"/g, '`"')
      lines.push(`@"`)
      lines.push(escaped)
      lines.push(`"@ | Set-Content -Path "CLAUDE.md" -Encoding UTF8`)
    }

    // Skill files → .claude\commands\skillName\
    const base = `.claude\\commands\\${skillName}`
    const dirs = new Set([base])

    for (const f of skillFiles) {
      if (this.isBinary(f.content_type)) continue
      if (f.subdirectory) dirs.add(`${base}\\${f.subdirectory}`)
    }

    for (const dir of dirs) {
      lines.push(`New-Item -ItemType Directory -Force -Path "${dir}" | Out-Null`)
    }

    for (const f of skillFiles) {
      if (this.isBinary(f.content_type)) {
        lines.push(`# Skipped binary: ${this.fileDisplayPath(f)}`)
        continue
      }
      const subdir = f.subdirectory ? `${f.subdirectory}\\` : ""
      const path = `${base}\\${subdir}${f.filename}`
      const escaped = f.content.replace(/"/g, '`"')
      lines.push(`@"`)
      lines.push(escaped)
      lines.push(`"@ | Set-Content -Path "${path}" -Encoding UTF8`)
    }

    const totalCount = claudeFiles.filter(f => !this.isBinary(f.content_type)).length +
                        skillFiles.filter(f => !this.isBinary(f.content_type)).length
    lines.push(`Write-Host "Installed skill '${skillName}' (${totalCount} file(s))"`)
    return lines.join("\n")
  }

  // --- Non-skill-package scripts (existing logic) ---

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

  targetPath(filename, fileType) {
    if (fileType === "claude_md") return "CLAUDE.md"
    const name = filename.replace(/\.md$/i, "").replace(/[^a-zA-Z0-9_\-]/g, "_")
    return `.claude/commands/${name}.md`
  }

  fileDisplayPath(f) {
    if (f.subdirectory) return `${f.subdirectory}/${f.filename}`
    return f.filename
  }

  isBinary(contentType) {
    if (!contentType) return false
    return /^(image|audio|video|font)\//i.test(contentType) ||
      contentType === "application/octet-stream" ||
      contentType === "application/zip"
  }

  scriptLanguage(filename) {
    if (filename.endsWith(".py")) return "python"
    if (filename.endsWith(".sh") || filename.endsWith(".bash")) return "bash"
    if (filename.endsWith(".json")) return "json"
    if (filename.endsWith(".yaml") || filename.endsWith(".yml")) return "yaml"
    if (filename.endsWith(".toml")) return "toml"
    return ""
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
