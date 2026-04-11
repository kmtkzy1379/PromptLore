class RepositoryVersionService
  MAX_UNPINNED = 5
  MAX_PINNED = 3

  def create_version!(repository)
    next_number = (repository.versions.maximum(:version_number) || 0) + 1

    version = repository.versions.build(
      version_number: next_number,
      name: repository.name,
      description: repository.description,
      file_type: repository.file_type_before_type_cast,
      visibility: repository.visibility_before_type_cast,
      tag_names: repository.tags.pluck(:name),
      category_names: repository.categories.pluck(:name)
    )

    version.save!

    if repository.file.attached?
      version.file.attach(repository.file.blob)
    end

    enforce_limit!(repository)
    version
  end

  def restore_version!(repository, version)
    create_version!(repository)

    repository.update!(
      name: version.name,
      description: version.description,
      file_type: version.file_type,
      visibility: version.visibility
    )

    if version.file.attached?
      repository.file.attach(version.file.blob)
    end

    tags = version.tag_names.map { |n| Tag.find_or_create_by!(name: n) }
    repository.tags = tags

    cats = version.category_names.filter_map { |n| Category.find_by(name: n) }
    repository.categories = cats
  end

  def toggle_pin!(version)
    if version.pinned?
      version.update!(pinned: false)
      true
    else
      if version.repository.versions.pinned.count >= MAX_PINNED
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

  def enforce_limit!(repository)
    unpinned = repository.versions.unpinned.order(version_number: :asc)
    excess_count = unpinned.count - MAX_UNPINNED
    if excess_count > 0
      unpinned.limit(excess_count).destroy_all
    end
  end
end
