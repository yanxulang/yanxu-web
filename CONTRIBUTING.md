# 贡献指南

## 环境

- 言序 1.1.12；
- 言包可执行文件；
- Ruby 3.x，用于文档结构门禁；
- Git。

在言序多仓工作区中始终从总根目录运行命令。独立克隆时可把示例中的仓库前缀替换为`.`。

## 安装依赖

包解析、锁文件生成和共享 Git 缓存操作必须串行：

```sh
YANXU_BIN=/tmp/yanxu-v1.1.12/target/release/yanxu \
  yanbao install \
  --manifest-path yanxu-libraries-workspace/repos/yanxu-web
```

不得手工伪造锁文件提交、校验和或依赖修订。清单变化后运行离线锁验证：

```sh
/tmp/yanxu-v1.1.12/target/release/yanxu 包 锁 --离线 \
  yanxu-libraries-workspace/repos/yanxu-web
```

## 编辑范围

- 路由、中间件、会话、CSRF、静态文件和 OpenAPI 核心位于`src/言序Web.yx`；
- 言访适配器位于`src/言访测试.yx`，默认入口不得反向导入它；
- 言标实现位于`src/言标.yx`；
- 每个行为变化必须有聚焦规格；
- 不复制`yanxu-http`、`yanju`、`yanxu-html`或`yanxu-request`已提供的协议逻辑。

## 格式与静态检查

```sh
/tmp/yanxu-v1.1.12/target/release/yanxu 格 --写 \
  yanxu-libraries-workspace/repos/yanxu-web/src/言序Web.yx

/tmp/yanxu-v1.1.12/target/release/yanxu 查 \
  yanxu-libraries-workspace/repos/yanxu-web/src/言序Web.yx

/tmp/yanxu-v1.1.12/target/release/yanxu 查 \
  yanxu-libraries-workspace/repos/yanxu-web/src/言访测试.yx
```

修改过的`.yx`文件都必须格式化并单独静态检查。

## 规格

```sh
/tmp/yanxu-v1.1.12/target/release/yanxu 试 \
  yanxu-libraries-workspace/repos/yanxu-web/tests \
  --并发 1 --json
```

规格至少覆盖正常、边界、错误、无效输入、资源上限和副本隔离。协议或安全变化还应覆盖失败原子性，确认失败登记不会留下半写状态。

## 示例与基准

```sh
/tmp/yanxu-v1.1.12/target/release/yanxu \
  yanxu-libraries-workspace/repos/yanxu-web/examples/无端口言访.yx

/tmp/yanxu-v1.1.12/target/release/yanxu \
  yanxu-libraries-workspace/repos/yanxu-web/benchmarks/路由与言访.yx -- 10
```

基准必须校验业务结果，并输出轮数、耗时和校验和。不要提交只打印速度但不验证正确性的负载。

## 机器 API 与文档

```sh
/tmp/yanxu-v1.1.12/target/release/yanxu 文 --json \
  yanxu-libraries-workspace/repos/yanxu-web/src/言序Web.yx \
  /tmp/yanxu-web-api.json

/tmp/yanxu-v1.1.12/target/release/yanxu 文 --json \
  yanxu-libraries-workspace/repos/yanxu-web/src/言访测试.yx \
  /tmp/yanxu-web-request-api.json

ruby yanxu-libraries-workspace/repos/yanxu-web/scripts/generate_api_reference.rb \
  /tmp/yanxu-web-api.json /tmp/yanxu-web-request-api.json \
  yanxu-libraries-workspace/repos/yanxu-web/docs/API_REFERENCE.md --check

ruby yanxu-libraries-workspace/repos/yanxu-web/scripts/verify_docs.rb \
  /tmp/yanxu-web-api.json /tmp/yanxu-web-request-api.json \
  yanxu-libraries-workspace/repos/yanxu-web
```

新增公开声明必须同步 API 语义文档和生成参考。

## 构建

```sh
YANXU_BIN=/tmp/yanxu-v1.1.12/target/release/yanxu \
  yanbao build \
  --manifest-path yanxu-libraries-workspace/repos/yanxu-web \
  --release
```

构建结果必须来自当前锁图。不要提交`build/`、`.yanxu/`或编辑器临时文件。

## 提交

一个提交只包含一个可独立验证的功能、修复、文档或门禁变化。提交前运行`git diff --check`并审阅暂存补丁；测试失败时不要提交或发布。
