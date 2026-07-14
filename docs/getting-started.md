# yanxu-web 入门

本教程建立一个包含安全 HTML 页面、路径参数、JSON 接口、中间件和静态文件的最小应用。

## 1. 准备项目

用言包添加框架，以及应用源码直接使用的 HTML 包：

```sh
yanbao --manifest-path . add yanxu-web \
  --git https://github.com/yanxulang/yanxu-web.git \
  --rev main --version '^0.1'
yanbao --manifest-path . add yanxu-html \
  --git https://github.com/yanxulang/yanxu-html.git \
  --rev main --version '^0.1'
yanbao --manifest-path . install
```

上述命令维护`言序.toml`并生成`言序.lock`。框架清单负责声明`yanxu-http`传递依赖；顶层应用若直接引用 HTTP 包，再用同样方式显式添加它。应用仍需按实际能力声明权限：

```toml
[权限]
文件 = ["."]
网络 = []
TCP监听 = ["127.0.0.1", "::1", "localhost"]
UDP绑定 = []
环境 = []
进程 = false
```

## 2. 页面与路由

```yanxu
引「包:yanxu-web」为 Web；
引「包:yanxu-html」为 HTML；

法 首页（上下文）则
    定 名称：文? 为 上下文.查询值（「name」）；
    令 显示名：文 为「访客」；
    若 名称 是 文 则 置 显示名 为 名称；终

    归 Web.HTML响应（HTML.文档（HTML.元素（「html」，【】，【
        HTML.元素（「body」，【】，【
            HTML.元素（「h1」，【】，【HTML.文字（「你好，」加 显示名）】）
        】）
    】）））；
终

法 文章接口（上下文）则
    归 Web.JSON响应（{
        「id」：上下文.参数值（「id」），
        「source」：上下文.状态值（「source」）
    }）；
终

定 应用 为 Web.应用（）；
置 应用.状态【「source」】为「yanxu-web」；
应用.取（「/」，首页）；
应用.取（「/api/posts/:id」，文章接口）；
```

访问`/?name=<script>`时，查询值最终进入`HTML.文字`，因此会自动转义。路由模式必须以`/`开头；`:id`匹配单个非空路径段。

## 3. 中间件

```yanxu
法 响应首部（上下文，下一步）则
    定 响应 为 下一步（）；
    响应.设首部（「x-content-type-options」，「nosniff」）；
    响应.设首部（「referrer-policy」，「same-origin」）；
    归 响应；
终

应用.使用（响应首部）；
```

中间件按注册顺序进入，调用`下一步（）`后再逆序返回。可以在调用前修改上下文，也可以在调用后修改响应。若中间件不调用`下一步`，它就会短路后续链。

## 4. 统一错误处理

```yanxu
法 错误处理（上下文，所误）则
    归 Web.JSON响应（{「error」：「internal_error」}）；
终

应用.设错误处理器（错误处理）；
```

默认错误处理器返回纯文字 500，且不会向客户端泄露错误细节。开发日志应在中间件或自定义错误处理器中记录，但响应仍应使用稳定、无敏感信息的内容。

## 5. 静态文件

把文件放在`static/`，再挂载：

```yanxu
应用.挂静态（「/static」，「static」）；
```

`/static/app.css`映射为`static/app.css`。通配路径中出现绝对路径、空段、`.`、`..`、反斜杠或 NUL 时返回 404。支持常用 HTML、CSS、JS、JSON、图片、字体和文字媒体类型，其余类型回退到`application/octet-stream`。

## 6. 运行

```yanxu
Web.开发服务器（应用，「127.0.0.1:8080」）.运行（）；
```

```sh
yanbao --manifest-path . install
yanbao --manifest-path . run
```

自动化测试可以不打开 TCP，直接用`HTTP.解析请求头`构造请求，再调用`应用.处理（请求）`。完整做法见[`tests/路由与中间件.yx`](../tests/路由与中间件.yx)和[`yanxu-webblog`](https://github.com/yanxulang/yanxu-webblog)。
