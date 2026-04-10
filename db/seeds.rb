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
admin = User.find_by(email: "kmt.ps037@gmail.com")
if admin
  admin.update!(admin: true)
  puts "Admin set: #{admin.email}"
else
  puts "Warning: kmt.ps037@gmail.com not found. Sign up first, then run seeds again."
end
