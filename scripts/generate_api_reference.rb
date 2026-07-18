# frozen_string_literal: true

require "json"
require "pathname"

def code(value)
  escaped = value.to_s.gsub("|", "\\|").gsub("`", "\\`")
  "`#{escaped}`"
end

def table(headers, rows)
  return ["_无。_"] if rows.empty?

  lines = []
  lines << "| #{headers.join(' | ')} |"
  lines << "| #{headers.map { '---' }.join(' | ')} |"
  rows.each { |row| lines << "| #{row.join(' | ')} |" }
  lines
end

def render_module(api)
  declarations = api.fetch("declarations")
  lines = []
  lines << "## 模块 #{code(api.fetch('module'))}"
  lines << ""
  lines << "顶层公开声明：#{declarations.length}。"
  lines << ""

  constants = declarations.select { |item| item.fetch("kind") == "constant" }
  functions = declarations.select { |item| item.fetch("kind") == "function" }
  containers = declarations.select { |item| %w[class protocol].include?(item.fetch("kind")) }

  lines << "### 常量"
  lines << ""
  lines.concat(table(["名称", "类型"], constants.map do |item|
    [code(item.fetch("name")), code(item.fetch("type", "任意"))]
  end))
  lines << ""
  lines << "### 顶层函数"
  lines << ""
  lines.concat(table(["名称", "签名"], functions.map do |item|
    [code(item.fetch("name")), code(item.fetch("signature"))]
  end))

  containers.each do |container|
    kind = container.fetch("kind") == "class" ? "类" : "协议"
    lines << ""
    lines << "### #{kind} #{code(container.fetch('name'))}"
    lines << ""
    if container.fetch("kind") == "class"
      superclass = container["superclass"]
      protocols = container.fetch("protocols", [])
      relations = []
      relations << "父类 #{code(superclass)}" if superclass
      relations << "协议 #{protocols.map { |name| code(name) }.join('、')}" unless protocols.empty?
      lines << (relations.empty? ? "无父类或公开协议关系。" : relations.join("；") + "。")
      lines << ""
    end

    fields = container.fetch("fields", [])
    lines.concat(table(["字段", "类型", "只读"], fields.map do |field|
      [code(field.fetch("name")), code(field.fetch("type")), field.fetch("readonly") ? "是" : "否"]
    end))
    lines << "" unless fields.empty?

    methods = container.fetch("methods", [])
    lines.concat(table(["方法", "签名"], methods.map do |method|
      [code(method.fetch("name")), code(method.fetch("signature"))]
    end))
  end

  lines
end

default_api_path = Pathname(ARGV.fetch(0)).expand_path
request_api_path = Pathname(ARGV.fetch(1)).expand_path
output_path = Pathname(ARGV.fetch(2)).expand_path
check = ARGV.include?("--check")

apis = [default_api_path, request_api_path].map { |path| JSON.parse(path.read) }

lines = [
  "# 言枢机器 API 参考",
  "",
  "> 本文件由`言序 文 --json`和`scripts/generate_api_reference.rb`生成。行为说明见[API.md](API.md)，不要手工编辑本文件。",
  ""
]

apis.each_with_index do |api, index|
  lines.concat(render_module(api))
  lines << "" if index < apis.length - 1
end

content = lines.join("\n").rstrip + "\n"

if check
  abort "API 参考不存在：#{output_path}" unless output_path.file?
  abort "API 参考不是由当前机器清单生成" unless output_path.read == content
  puts "API 参考通过：#{apis.sum { |api| api.fetch('declarations').length }} 个顶层声明"
else
  output_path.dirname.mkpath
  output_path.write(content)
  puts "已生成 API 参考：#{output_path}"
end
