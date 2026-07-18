# 言枢

[![CI](https://github.com/yanxulang/yanxu-web/actions/workflows/ci.yml/badge.svg)](https://github.com/yanxulang/yanxu-web/actions/workflows/ci.yml)
[![License: MIT](https://img.shields.io/badge/license-MIT-blue.svg)](LICENSE)
[![Yanxu 1.1.12](https://img.shields.io/badge/言序-1.1.12-b33.svg)](https://github.com/yanxulang/yanxu)

言枢是言序的 Web 应用框架，技术包名为`yanxu-web`。它把`yanxu-http`的协议对象、`yanxu-html`的安全节点、言据数据交换和言标模板组织成显式、可测试的服务端 API。

当前稳定版本为`1.0.0`：受预算约束的路由与中间件、JSON/言据协商、Cookie、可注入会话存储、同源双提交 CSRF、条件与范围静态响应、显式 OpenAPI 元数据边界，以及与言访互通的无端口测试传输均进入稳定兼容面。

## 安装

最低言序版本为`1.1.12`。当前发布线可这样安装：

```sh
yanbao add web --version '^1.0'
```

言包会锁定`yanxu-http 1.0.0`、`yanxu-html 1.0.0`、`yanju 1.2.0`和`yanxu-request 1.0.0`及其传递依赖。框架本身不申请出站网络、进程或原生扩展权限；开发服务器只申请清单列出的回环监听地址，静态文件与模板访问受文件权限约束。

## 五分钟示例

```yanxu
引「包:web」为 言枢；

法 首页（上下文） 则
    归 言枢.协商响应（上下文，{
        「服务」：「言枢」，
        「文章」：上下文.反向（「文章详情」，{「id」：「first」}）
    }）；
终

法 文章（上下文） 则
    归 言枢.JSON响应（{「id」：上下文.参数值（「id」）}）；
终

定 应用 为 言枢.创建应用（
    言枢.配置（）
        .设应用名（「我的服务」）
        .设最大请求正文字节（1048576）
）；

应用.取（「/」，首页）；
应用.命名取（「/posts/:id」，「文章详情」，文章）；

定 响应 为 言枢.测试客户端（应用）.取（「/posts/first」）；
若 （响应.状态码 不等于 200） 则
    抛 「示例请求失败」；
终

言枢.服务器（应用，「127.0.0.1:8080」）.运行（）；
```

无需监听端口的言访集成入口位于`包:web/言访测试`：

```yanxu
引「包:web/言访测试」为 言访测试；

定 客户端 为 言访测试.客户端（应用）；
定 响应 为 客户端.取（「/posts/first」）.发送（）.确保成功（）；
```

完整可执行版本见[无端口言访示例](examples/无端口言访.yx)。

## 主要能力

- 有序静态路由、`:参数`、末尾`*通配`、命名路由、反向 URL 和路由组；
- 洋葱式中间件、404/405 分流、统一错误处理和请求/响应正文预算；
- JSON、规范言据、内容协商、文字、字节、HTML、言标和重定向响应；
- 可注入会话存储协议、编号轮换、空闲过期与安全 Cookie；
- 同源检查、双提交令牌和可配置可信来源的 CSRF 中间件；
- 静态路径隔离、媒体类型、ETag、Last-Modified、条件请求和单范围响应；
- 显式接口登记、稳定操作标识、隔离快照和可注入 OpenAPI 3.1 提供器；
- 任意请求首部、字节正文和 Cookie 的无端口测试客户端；
- 言访自定义传输，保留重定向、HEAD 语义和重复`Set-Cookie`；
- 言标自动转义、条件、循环、包含、继承和显式可信 HTML 边界。

## 会话与 CSRF

言枢不隐藏全局会话存储。应用必须显式提供实现`会话存储协议`的对象，或用`会话存储适配器（读取法，写入法，删除法）`包装回调：

```yanxu
定 会话项 为 言枢.会话配置（）
    .设Cookie名（「__Host-yanxu-session」）
    .设安全（真）
    .设仅HTTP（真）
    .设同站（「Lax」）；

应用.使用（言枢.会话中间件（会话项，存储））；
```

CSRF 防护采用同源来源检查与双提交 Cookie。它不是认证或授权机制；令牌必须与登录会话、权限校验和 HTTPS 部署共同使用。完整不变量见[安全模型](docs/SECURITY_MODEL.md)。

## OpenAPI 扩展边界

普通路由不会被自动反射。只有`接口路由/命名接口路由/接口取/接口发`显式登记的操作才进入隔离快照：

```yanxu
定 说明 为 言枢.接口说明（「users.get」）
    .设摘要（「读取用户」）
    .设标签（【「用户」】）
    .设响应（{「200」：{「说明」：「成功」}}）；

应用.接口取（「/users/:id」，说明，读取用户）；
定 文档 为 应用.生成OpenAPI（提供器）；
应用.挂OpenAPI（「/openapi.json」，提供器）；
```

框架只负责登记、隔离、预算和 HTTP 输出，不猜测 Schema，也不把普通处理器源码反射为规范。提供器负责把框架快照转换成 OpenAPI 文档。

## 错误处理

领域错误使用稳定前缀，例如`WEB_ROUTE`、`YANSHU_YANJU_BODY`、`YANSHU_SESSION_*`、`YANSHU_CSRF_*`、`YANSHU_STATIC_*`和`YANSHU_OPENAPI_*`。程序判断应读取`错误详情（错误）【「代码」】`，不要匹配中文消息。

默认错误处理器不会把内部异常详情写入 HTTP 响应。生产应用仍需注入结构化日志、请求编号、认证、授权、速率限制和敏感数据脱敏。

## 开发验证

从言序多仓总工作区执行：

```sh
/tmp/yanxu-v1.1.12/target/release/yanxu 查 yanxu-libraries-workspace/repos/yanxu-web/src/言序Web.yx
/tmp/yanxu-v1.1.12/target/release/yanxu 查 yanxu-libraries-workspace/repos/yanxu-web/src/言访测试.yx
/tmp/yanxu-v1.1.12/target/release/yanxu 试 yanxu-libraries-workspace/repos/yanxu-web/tests --并发 1 --json
YANXU_BIN=/tmp/yanxu-v1.1.12/target/release/yanxu yanbao build --manifest-path yanxu-libraries-workspace/repos/yanxu-web --release
```

包解析、锁文件和共享缓存操作必须串行执行。示例与基准命令见[使用指南](docs/GUIDE.md)和[性能说明](docs/PERFORMANCE.md)。

## 已知限制

内建服务器是开发与集成边界：串行接受连接、每连接处理一个 HTTP/1.1 请求并关闭。它不提供 TLS、HTTP/2/3、长连接工作池、流式上传、生产代理信任、跨进程会话、分布式限流或优雅重启。生产部署应由成熟前置服务器终止 TLS，并按[架构说明](docs/ARCHITECTURE.md)处理这些职责。

OpenAPI 是扩展边界而非内建全自动生成器；会话存储是协议而非内置数据库；言访测试传输把任意 HTTP(S) 主机映射到同一个内存应用，不模拟 DNS、TLS 或网络时延。

## 文档

- [使用指南](docs/GUIDE.md)
- [公开 API](docs/API.md)
- [完整机器 API 参考](docs/API_REFERENCE.md)
- [架构](docs/ARCHITECTURE.md)
- [迁移到 1.0](docs/MIGRATION.md)
- [兼容矩阵](COMPATIBILITY.md)
- [安全模型](docs/SECURITY_MODEL.md)
- [性能与基准](docs/PERFORMANCE.md)
- [言标语法](docs/yanbiao.md)
- [贡献指南](CONTRIBUTING.md)

言枢按[MIT License](LICENSE)发布。安全问题请按[安全策略](SECURITY.md)私下报告。
