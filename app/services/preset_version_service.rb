class PresetVersionService
  MAX_UNPINNED = 5
  MAX_PINNED = 3

  def create_version!(preset)
    next_number = (preset.versions.maximum(:version_number) || 0) + 1

    repo_refs = preset.preset_repositories.order(:position).map do |pr|
      { "id" => pr.repository_id, "position" => pr.position }
    end

    version = preset.versions.build(
      version_number: next_number,
      name: preset.name,
      description: preset.description,
      visibility: preset.visibility_before_type_cast,
      official: preset.official,
      tag_names: preset.tags.pluck(:name),
      category_names: preset.categories.pluck(:name),
      repository_refs: repo_refs
    )

    version.save!

    preset.preset_items.order(:position).each do |item|
      next unless item.file.attached?
      vi = version.preset_version_items.create!(
        file_type: item.file_type_before_type_cast,
        position: item.position,
        subdirectory: item.subdirectory
      )
      vi.file.attach(item.file.blob)
    end

    enforce_limit!(preset)
    version
  end

  def restore_version!(preset, version)
    create_version!(preset)

    preset.update!(
      name: version.name,
      description: version.description,
      visibility: version.visibility,
      official: version.official
    )

    # Restore tags
    tags = version.tag_names.map { |n| Tag.find_or_create_by!(name: n) }
    preset.tags = tags

    # Restore categories
    cats = version.category_names.filter_map { |n| Category.find_by(name: n) }
    preset.categories = cats

    # Restore preset_items
    preset.preset_items.destroy_all
    version.preset_version_items.order(:position).each do |vi|
      next unless vi.file.attached?
      item = preset.preset_items.create!(
        file_type: vi.file_type,
        position: vi.position,
        subdirectory: vi.subdirectory
      )
      item.file.attach(vi.file.blob)
    end

    # Re-detect skill package status
    preset.detect_skill_package!
    preset.save!

    # Restore preset_repositories
    preset.preset_repositories.destroy_all
    skipped = []
    (version.repository_refs || []).each do |ref|
      repo = Repository.find_by(id: ref["id"])
      if repo.nil?
        skipped << ref["id"]
        next
      end
      preset.preset_repositories.create!(
        repository_id: repo.id,
        position: ref["position"]
      )
    end

    skipped
  end

  def toggle_pin!(version)
    if version.pinned?
      version.update!(pinned: false)
      true
    else
      if version.preset.versions.pinned.count >= MAX_PINNED
        false
      else
        version.update!(pinned: true)
        true
      end
    end
  end

  def update_memo!(version, memo)
    version.update!(memo: memo.presence)
  end

  private

  def enforce_limit!(preset)
    unpinned = preset.versions.unpinned.order(version_number: :asc)
    excess_count = unpinned.count - MAX_UNPINNED
    if excess_count > 0
      unpinned.limit(excess_count).destroy_all
    end
  end
end
