# yanxu-web

[![CI](https://github.com/yanxulang/yanxu-web/actions/workflows/ci.yml/badge.svg)](https://github.com/yanxulang/yanxu-web/actions/workflows/ci.yml)
[![License: MIT](https://img.shields.io/badge/license-MIT-blue.svg)](LICENSE)
[![Yanxu 1.1.4-A](https://img.shields.io/badge/言序-1.1.4--A-b33.svg)](https://github.com/yanxulang/yanxu/releases/tag/v1.1.4-A)

`yanxu-web` 是建立在[`yanxu-html`](https://github.com/yanxulang/yanxu-html)和[`yanxu-http`](https://github.com/yanxulang/yanxu-http)之上的轻量 Web 框架。它把协议请求交给路由、中间件和处理器，再统一生成安全 HTML、JSON、言据、文字、字节或静态文件响应。

```text
yanxu-web       应用 · 路由 · 上下文 · 中间件 · 静态文件 · 开发服务器
    ├── yanxu-html   节点 · 自动转义 · 组件 · 文档
    └── yanxu-http   HTTP/1.1 请求 · 响应 · Cookie · 连接处理
```

## 主要能力

- `Web应用`统一持有路由器、共享状态、中间件与错误处理器；
- 支持静态路径、`:参数`路径和末尾`*通配`路径；
- 自动区分 404 与 405，并为 405 设置`Allow`；
- 中间件使用`法（上下文，下一步）`洋葱式组合；
- 处理器通过`Web上下文`读取路径参数、查询、首部、Cookie 和应用状态；
- `HTML响应`只接受 HTML 节点并进入`yanxu-html`安全渲染；
- 静态文件服务拒绝绝对路径、反斜杠、NUL、`.`和`..`路径段；
- 提供串行、一连接一请求的本地开发服务器。

## 安装

仓库只保存自己的源码；`yanxu-html`和`yanxu-http`由言包按`言序.toml`与`言序.lock`安装：

```sh
git clone https://github.com/yanxulang/yanxu-web.git
yanbao --manifest-path yanxu-web install
```

在自己的项目中，用言包添加代码直接引用的包：

```sh
yanbao --manifest-path . add yanxu-web \
  --git https://github.com/yanxulang/yanxu-web.git \
  --rev main --version '^0.1'
yanbao --manifest-path . add yanxu-html \
  --git https://github.com/yanxulang/yanxu-html.git \
  --rev main --version '^0.1'
yanbao --manifest-path . install
```

框架自身声明的`yanxu-http`会作为传递依赖解析；应用若直接`引「包:yanxu-http」`，也应通过言包把它声明为顶层依赖。顶层锁文件中的同名依赖优先，确保整次检查和运行使用同一精确版本。

## 第一个应用

```yanxu
引「包:yanxu-web」为 Web；
引「包:yanxu-html」为 HTML；

法 首页（上下文）则
    归 Web.HTML响应（HTML.文档（
        HTML.元素（「html」，【HTML.属性（「lang」，「zh-CN」）】，【
            HTML.元素（「body」，【】，【
                HTML.元素（「h1」，【】，【HTML.文字（「言序 Web」）】）
            】）
        】）
    ））；
终

法 文章（上下文）则
    归 Web.JSON响应（{「id」：上下文.参数值（「id」）}）；
终

定 所应用 为 Web.应用（）；
所应用.取（「/」，首页）；
所应用.取（「/posts/:id」，文章）；
所应用.挂静态（「/static」，「static」）；

Web.开发服务器（所应用，「127.0.0.1:8080」）.运行（）；
```

运行前锁定依赖：

```sh
yanbao --manifest-path . install
yanbao --manifest-path . run
```

## 中间件与错误边界

```yanxu
法 安全首部（上下文，下一步）则
    定 响应 为 下一步（）；
    响应.设首部（「x-content-type-options」，「nosniff」）；
    归 响应；
终

法 错误响应（上下文，所误）则
    归 Web.JSON响应（{「error」：「internal_error」}）；
终

所应用.使用（安全首部）；
所应用.设错误处理器（错误响应）；
```

中间件与路由处理器都必须返回`yanxu-http`的`HTTP响应`。应用捕获路由处理期间的错误并交给统一错误处理器；错误处理器本身返回其他类型时会再次失败，避免静默生成无效响应。

## 当前边界

开发服务器继承`yanxu-http 0.1`的简单模型：HTTP/1.1、串行接受、一连接一请求、`Connection: close`。它用于本地开发、教学和集成验证，不包含 TLS、并发工作池、生产日志、优雅重启、长连接或反向代理信任管理。

静态文件处理只在路径层阻止目录穿越，默认`Cache-Control: no-cache`；生产静态资产建议由经过配置的前置服务器或对象存储提供。

## 文档

- [入门教程](docs/getting-started.md)
- [公开 API 参考](docs/api.md)
- [架构、请求生命周期与扩展点](docs/architecture.md)
- [言序文档站：Web 框架](https://docs.yanxu.dev/web/framework/)
- [完整博客示例](https://github.com/yanxulang/yanxu-webblog)

## 开发与验收

始终从言序总工作区根目录运行：

```sh
YANXU_BIN=yanxu-language-new/target/debug/yanxu yanbao/target/debug/yanbao --manifest-path yanxu-web install
yanxu-language-new/target/debug/yanxu 查 yanxu-web/src/言序Web.yx
yanxu-language-new/target/debug/yanxu 试 yanxu-web/tests --json
```

当前版本是 `0.1.0`，按 [MIT License](LICENSE) 发布。跨库路线图见[Web 栈安全与路线图](https://docs.yanxu.dev/web/security-roadmap/)。
