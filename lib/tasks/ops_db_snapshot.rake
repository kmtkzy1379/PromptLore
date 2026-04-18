# frozen_string_literal: true

namespace :ops do
  desc "Print admin users and official presets (use from Fly: bin/rake ops:db_snapshot)"
  task db_snapshot: :environment do
    puts "=== admins (id, email, username) ==="
    p User.where(admin: true).pluck(:id, :email, :username)
    puts "=== official presets (id, name, user_id) ==="
    p Preset.where(official: true).pluck(:id, :name, :user_id)
  end

  desc "Grant admin + mark all that user's presets/repos/versions official (EMAIL=... bin/rake ops:promote_official_user)"
  task promote_official_user: :environment do
    email = ENV.fetch("EMAIL") { raise "Set EMAIL, e.g. EMAIL=user@example.com bin/rake ops:promote_official_user" }
    user = User.find_by(email: email)
    raise ActiveRecord::RecordNotFound, "No user with email #{email.inspect}" unless user

    now = Time.current
    ActiveRecord::Base.transaction do
      user.update!(admin: true)
      preset_ids = user.presets.pluck(:id)
      n_presets = user.presets.update_all(official: true, updated_at: now)
      n_versions = if preset_ids.empty?
        0
      else
        PresetVersion.where(preset_id: preset_ids).update_all(official: true, updated_at: now)
      end
      n_repos = user.repositories.update_all(official: true, updated_at: now)
      puts "OK: #{email} admin=true; presets official=#{n_presets}; preset_versions official=#{n_versions}; repositories official=#{n_repos}"
    end
  end
end
