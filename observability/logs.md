# 日志

当今的容器化技术可以直接以 `stdout` 标准输出的形式来控制日志，这是目前比较推崇的做法。但在实际情况下，有可能会涉及到存量服务的迁移，而这些存量服务会将日志输出到文件，处理这些日志文件就没有那么简单，因为文件位于容器内部，从宿主机上不易访问。最简单的处理方式，就是在容器当中再单独 `run` 一个日志采集进程，这个进程就可以读取日志文件，以增量的形式将日志发送到日志中心，再进行聚合与存储，这是目前主流的处理方式，例如，`ELK`、`EFK`。

`Istio` 的核心设计理念之一就是为网格内的服务提供良好的可观测性，使开发与运维人员能够更好地监测到网格内的服务运行情况。`Istio` 可以监测到网格内的服务通信的流转情况，并生成详细的遥测日志数据，任何请求与事件的元信息都可以获取到。在 `Istio` 中，可以自定义 `schema` 来获取具有一定格式的日志信息，日志信息可以经过容器 `stdout` 标准输出，也可以通过第三方插件导出到特定的收集器，一切取决于实际情况。

本节主要讲解关于 `Istio` 中 `Sidecar` 的访问日志，以了解网格内服务通信的日志情况。

## 1、Envoy 访问日志

`Istio` 可以为网格内服务通信生成访问日志，并支持配置日志格式，其中包括时间、内容等，例如：

```sh
[2019-03-06T09:31:27.360Z] "GET /status/418 HTTP/1.1" 418 - "-" 0 135 5 2 "-" "curl/7.60.0" "d209e46f-9ed5-9b61-bbdd-43e22662702a" "httpbin:8000" "127.0.0.1:80" inbound|8000|http|httpbin.default.svc.cluster.local - 172.30.146.73:80 172.30.146.82:38618 outbound_.8000_._.httpbin.default.svc.cluster.local
```

**开启 `Envoy` 访问日志：**

修改 `Istio` 配置文件：

（`Istio` 安装时，`demo` 环境配置中已默认设置开启）

```sh
istioctl install --set meshConfig.accessLogFile=/dev/stdout
```

此外，还可以通过 `meshConfig.accessLogEncoding` 为 `JSON` 或 `TEXT` 的日志编码格式，默认为 `TEXT` 格式，即：单行格式，通过 `meshConfig.accessLogFormat` 来自定义访问日志的格式。

（也可通过 `kubectl edit` 命令修改。）

**日志格式：**

`envoy` 允许定制日志格式， 格式通过若干「`Command Operators`」组合，用于提取请求信息，`istio` 没有使用 `envoy` 默认的日志格式， `istio` 定制的访问日志格式如下：

```sh
[%START_TIME%] \"%REQ(:METHOD)% %REQ(X-ENVOY-ORIGINAL-PATH?:PATH)% %PROTOCOL%\" %RESPONSE_CODE% %RESPONSE_FLAGS% %RESPONSE_CODE_DETAILS% %CONNECTION_TERMINATION_DETAILS%
\"%UPSTREAM_TRANSPORT_FAILURE_REASON%\" %BYTES_RECEIVED% %BYTES_SENT% %DURATION% %RESP(X-ENVOY-UPSTREAM-SERVICE-TIME)% \"%REQ(X-FORWARDED-FOR)%\" \"%REQ(USER-AGENT)%\" \"%REQ(X-REQUEST-ID)%\"
\"%REQ(:AUTHORITY)%\" \"%UPSTREAM_HOST%\" %UPSTREAM_CLUSTER% %UPSTREAM_LOCAL_ADDRESS% %DOWNSTREAM_LOCAL_ADDRESS% %DOWNSTREAM_REMOTE_ADDRESS% %REQUESTED_SERVER_NAME% %ROUTE_NAME%\n
```

其中，比较关键项如下：

* `RESPONSE_CODE`：响应状态码，如，`200`。
* `RESPONSE_FLAGS`：很重要的信息，`envoy`  中自定义的响应标志位，可以认为是 `envoy` 附加的流量状态码。如 `NR` 表示找不到路由，`UH` 表示 `upstream cluster` 中没有健康的 `host`，`RL` 表示触发 `rate limit`，`UO` 触发断路器。`RESPONSE_FLAGS` 可选值有十几个，这些信息在调试中非常关键。
* `X-REQUEST-ID`：一次 `C` 端到 `S` 端的 `http` 请求，`Envoy` 会在 `C` 端生产 `request id`，并附加到 `header` 中，传递到 `S` 端，在 `2` 端的日志中都会记录该值， 因此可以通过这个 `ID` 关联请求的上下游。注意不要和全链路跟踪中的 `trace id` 混淆。
* `ROUTE_NAME`：匹配执行的路由名称。

通过访问日志可以快速的进行问题排查、分析。
