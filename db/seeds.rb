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
