# 如何规范定义服务的协议类型

istio 包括 HTTP、HTTPS、gRPC 和原始 TCP 协议等，默认可以自动检测 HTTP 和 HTTP2 流量。对于无法自动识别的协议，将被视为普通 TCP 流量。为了正确识别协议类型，提供额外的功能，在数据平面中必须规范定义服务的协议类型。

本文介绍如何规范定义服务的协议类型。

## 背景

istio 常见的协议类型包括 HTTP、HTTP2、HTTPS、TCP、TLS、gRPC、gRPC-Web、Mongo、MySQL 和 Redis。

为了规范定义服务协议，可以采取以下两种定义方式。

## 方式一：使用服务端口名称时指定协议类型

在 Service 的 ports 中，port 的 name 需设置为 `{协议名称}或{协议名称}-{自定义后缀}`。例如：服务的 9090 端口是 gRPC 协议类型，可以设置 port 的 name 为 `grpc-demo`；服务的 3306 端口是 MySQL 数据库协议，可以设置 port 的 name 为 mysql。

YAML 示例如下：

```yaml
kind: Service
metadata:
  name: myservice
spec:
  ports:
  - port: 9090
    name: grpc-demo
  - port: 3306
    name: mysql
```

## 方式二：使用服务端口的appProtocol指定协议类型

可以使用 Service 的 appProtocol 指定协议类型。

指定协议类型为 HTTPS 的 YAML 示例如下：

```yaml
kind: Service
metadata:
  name: myservice
spec:
  ports:
   -port: 3306
    name: database
    appProtocol: https
```

**注：`ports.appProtocol` 的生效优先级高于 `ports.name`。**

参考：

1. [Protocol Selection](https://istio.io/latest/docs/ops/configuration/traffic-management/protocol-selection/#automatic-protocol-selection)
