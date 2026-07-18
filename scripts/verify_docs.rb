# frozen_string_literal: true

require "json"
require "pathname"

default_api_path = Pathname(ARGV.fetch(0)).expand_path
request_api_path = Pathname(ARGV.fetch(1)).expand_path
root = Pathname(ARGV.fetch(2, ".")).expand_path

required_files = %w[
  README.md
  LICENSE
  CHANGELOG.md
  COMPATIBILITY.md
  SECURITY.md
  CONTRIBUTING.md
  docs/API.md
  docs/API_REFERENCE.md
  docs/GUIDE.md
  docs/ARCHITECTURE.md
  docs/MIGRATION.md
  docs/PERFORMANCE.md
  docs/SECURITY_MODEL.md
  docs/RELEASE_NOTES_1.0.0.md
  examples/无端口言访.yx
  benchmarks/路由与言访.yx
]

missing_files = required_files.reject do |path|
  file = root / path
  file.file? && !file.zero?
end
abort "缺少文档或验收资产：#{missing_files.join('、')}" unless missing_files.empty?

apis = [JSON.parse(default_api_path.read), JSON.parse(request_api_path.read)]
expected_modules = { "言序Web" => 73, "言访测试" => 3 }

apis.each do |api|
  abort "API 清单格式必须是 1" unless api.fetch("format_version") == 1
  abort "API 清单语言必须是 yanxu" unless api.fetch("language") == "yanxu"
  module_name = api.fetch("module")
  expected_count = expected_modules.fetch(module_name) { abort "未知 API 模块：#{module_name}" }
  actual_count = api.fetch("declarations").length
  abort "#{module_name}顶层声明应为 #{expected_count}，实际为 #{actual_count}" unless actual_count == expected_count
end

default_api = apis.find { |api| api.fetch("module") == "言序Web" }
default_members = default_api.fetch("declarations").flat_map do |item|
  item.fetch("fields", []) + item.fetch("methods", [])
end
abort "言序Web公开成员应为 217，实际为 #{default_members.length}" unless default_members.length == 217

all_items = apis.flat_map do |api|
  api.fetch("declarations").flat_map do |item|
    [item] + item.fetch("fields", []) + item.fetch("methods", [])
  end
end
invalid_names = all_items.reject { |item| item["name"].is_a?(String) && !item["name"].empty? }
abort "API 清单含无效公开名称" unless invalid_names.empty?

semantic_api = (root / "docs/API.md").read
critical_names = %w[
  创建应用 言据正文 言据值响应 会话存储协议 会话中间件 CSRF中间件
  静态配置 接口说明 生成OpenAPI 请求字节为 请求Cookie 言访测试
]
missing_semantics = critical_names.reject { |name| semantic_api.include?("`#{name}") }
abort "API 语义文档缺少：#{missing_semantics.join('、')}" unless missing_semantics.empty?

readme = (root / "README.md").read
required_readme_terms = %w[安装 五分钟示例 主要能力 权限 兼容 错误处理 已知限制 文档 MIT]
missing_readme = required_readme_terms.reject { |term| readme.include?(term) }
abort "README 缺少章节语义：#{missing_readme.join('、')}" unless missing_readme.empty?

markdown_files = root.glob("**/*.md")
unbalanced_fences = markdown_files.reject do |file|
  file.read.lines.count { |line| line.start_with?("```") }.even?
end
unless unbalanced_fences.empty?
  abort "代码围栏不成对：#{unbalanced_fences.map { |file| file.relative_path_from(root) }.join('、')}"
end

broken_links = []
markdown_files.each do |file|
  file.read.scan(/\[[^\]]+\]\(([^)]+)\)/).flatten.each do |link|
    next if link.match?(/\A(?:https?:|mailto:|#)/)

    relative = link.split("#", 2).first
    next if relative.empty?

    target = file.dirname / relative
    broken_links << "#{file.relative_path_from(root)}: #{link}" unless target.exist?
  end
end
abort "失效链接：\n#{broken_links.join("\n")}" unless broken_links.empty?

forbidden_placeholders = ["TODO", "FIXME", "计划完成", "理论支持", "预计成功"]
placeholder_hits = markdown_files.map do |file|
  hit = forbidden_placeholders.find { |placeholder| file.read.include?(placeholder) }
  "#{file.relative_path_from(root)}: #{hit}" if hit
end.compact
abort "文档含占位陈述：\n#{placeholder_hits.join("\n")}" unless placeholder_hits.empty?

stale_paths = %w[docs/api.md docs/architecture.md docs/getting-started.md docs/migration-0.2.md]
stale_hits = markdown_files.map do |file|
  hit = stale_paths.find { |path| file.read.include?(path) }
  "#{file.relative_path_from(root)}: #{hit}" if hit
end.compact
abort "文档仍引用旧路径：\n#{stale_hits.join("\n")}" unless stale_hits.empty?

puts "文档通过：#{markdown_files.length} 个 Markdown，76 个顶层声明，217 个默认模块成员"
