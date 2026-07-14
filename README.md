# yanxu-web

`yanxu-web` 建立在 [`yanxu-html`](https://github.com/YanXuLang/yanxu-html) 与 [`yanxu-http`](https://github.com/YanXuLang/yanxu-http) 之上，提供应用对象、路由器、路径参数、请求上下文、中间件、统一错误处理、HTML/JSON/言据响应、静态文件服务和本地开发服务器。

## 快速开始

```yanxu
引「包:yanxu-web」为 Web；
引「包:yanxu-html」为 HTML；

法 首页（上下文）则
    归 Web.HTML响应（HTML.元素（「h1」，【】，【HTML.文字（「言序 Web」）】））；
终

定 应用 为 Web.应用（）；
应用.取（「/」，首页）；
应用.挂静态（「/static」，「static」）；
Web.开发服务器（应用，「127.0.0.1:8080」）.运行（）；
```

中间件签名为 `法（上下文，下一步）`；调用 `下一步（）` 进入后续中间件或路由处理器。处理器必须返回 `yanxu-http` 的 `HTTP响应`。应用会捕获中间件与处理器错误，并交给统一错误处理器。

`HTML响应` 返回 200；需要自定义状态码时使用 `HTML状态响应（状态码，节点）`。

静态文件服务只接受根目录下的相对路径，拒绝绝对路径、反斜杠、零字节、`.` 与 `..` 路径段。开发服务器是串行、一连接一请求模型，仅用于本地开发和教学。

本地验收（从总工作区根目录执行）：

```sh
yanxu-language-new/target/debug/yanxu 包 锁 yanxu-web
yanxu-language-new/target/debug/yanxu 查 yanxu-web/src/言序Web.yx
yanxu-language-new/target/debug/yanxu 试 yanxu-web/tests --json
```

当前版本是 `0.1.0`，按 MIT License 发布。
