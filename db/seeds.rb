categories = [
  "Web開発",
  "データ分析",
  "DevOps",
  "AI/ML",
  "テスト",
  "ドキュメント",
  "モバイル",
  "セキュリティ",
  "インフラ",
  "その他"
]

categories.each do |name|
  Category.find_or_create_by!(name: name)
end

puts "Created #{Category.count} categories"

# Admin user
admin_email = ENV.fetch("ADMIN_EMAIL", nil)
if admin_email
  admin = User.find_by(email: admin_email)
  if admin
    admin.update!(admin: true)
    puts "Admin set: #{admin.email}"
  else
    puts "Warning: #{admin_email} not found. Sign up first, then run seeds again."
  end
end
