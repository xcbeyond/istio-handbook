# 多协议

`Istio` 支持代理任何的 `TCP` 流量，其中包括 `HTTP`、`HTTPS`、`gRPC` 以及 `TCP` 协议。但为了提供其他的能力，比如路由和丰富的指标，使用什么协议必须被确定。协议可通过自动检测和手动配置方式来确定。

基于非 `TCP` 的协议（例如，`UDP`），不能被代理直接使用。在不受 `Istio` 代理的任何拦截下，这些协议仍可正常继续使用，但不能在仅代理的组件中（例如，`Ingress` 或 `Egress`）使用。

可通过以下两种方式配置确定：

**自动协议选择：**

`Istio` 可以自动检测 `HTTP` 和 `HTTP/2` 的流量。如果无法自动确定协议，则流量将会被当作普通 `TCP` 协议的流量对待。

这个特性是默认开启的。通过设置这些安装选项可以将其关闭：

（位于`istiod` `Pod` 中的 `pilot-discovery` 容器）

* `--set values.pilot.enableProtocolSniffingForOutbound=false` 为出站监听器禁用协议检测。
* `--set values.pilot.enableProtocolSniffingForInbound=false` 为入站监听器禁用协议检测。

**手动协议选择：**

可以在 `Service` 定义中手动指定协议。可以通过两种方式进行配置：

* 通过端口的名称：`name: <protocol>[-<suffix>]`。

* 在 Kubernetes 1.18+ 中，按 `appProtocol` 字段：`appProtocol: <protocol>`。

**`Service` 定义中**支持以下协议：

* `http`
* `http2`
* `https`
* `tcp`
* `tls`
* `grpc`
* `grpc-web`
* `mongo`
* `mysql*`
* `redis*`
* `udp`

标注 `*` 的这些协议默认是处于禁用状态，要启用它们，需配置相应的[Pilot环境变量](https://istio.io/latest/docs/reference/commands/pilot-discovery/#envvars)。

下面是一个 `Service`  定义示例，通过 `appProtocol`  定义 `mysql` 的端口、通过名称定义 `http` 的端口：

```yaml
kind: Service
metadata:
  name: myservice
spec:
  ports:
  - number: 3306
    name: database
    appProtocol: mysql
  - number: 80
    name: http-web
```

## 1、协议实现

`Istio` 的多协议是通过定义 `Service` 完成配置，并由 `Sidecar` （例如，`Envoy`）完成具体协议的实现。

## 2、示例
