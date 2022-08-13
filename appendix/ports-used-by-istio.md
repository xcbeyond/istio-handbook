# 使用端口和协议

在 istio 中，会默认占用一些端口，这些已占用端口在应用程序中应避免使用，否则将会发生端口冲突。

## 1、Sidecar 使用的端口和协议

Istio sidecar 代理（Envoy）使用以下端口和协议：

| 端口 | 协议 | 描述 | 仅限 Pod 内部 |
| --- | --- | --- | --- |
| 15000 | TCP | Envoy 管理端口 | Yes |
| 15001 | TCP | Envoy 出站端口 | No |
| 15004 | HTTP | 调试端口 | Yes |
| 15006 | TCP | Envoy 入站端口 | No |
| 15008 | H2 | HBONE mTLS 隧道端口 | No |
| 15009 | H2C | 用于安全网络的 HBONE 端口 | No |
| 15020 | HTTP | 从 Istio agent、Envoy 和应用程序合并的 Prometheus 指标采集端口 | No |
| 15021 | HTTP | 健康检查端口 | No |
| 15053 | DNS | DNS 端口，如果启用了将会占用 | Yes |
| 15090 | HTTP | Envoy Prometheus 遥测端口 | No |

## 2、控制平面（istiod）使用的端口和协议

Istio 控制平面 (istiod) 使用以下端口和协议：

| 端口 | 协议 | 描述 | 仅限本地主机 |
| --- | --- | --- | --- |
| 443 | HTTPS | Webhooks 服务端口 | No |
| 8080 | HTTP | 调试接口（已弃用，仅限容器端口）| No |
| 15010 | GRPC | XDS 和 CA 服务（纯文本，仅用于安全网络）| No |
| 15012 | GRPC | XDS 和 CA 服务（TLS 和 mTLS，推荐用于生产）| No |
| 15014 | HTTP | 控制平面监控 | No |
| 15017 | HTTPS | Webhook 容器端口，从 443 转发 | No |

## 3、服务器协议

| 协议 | 端口 |
| --- | --- |
| SMTP | 25 |
| DNS | 53 |
| MySQL | 3306 |
| MongoDB | 27017 |

参考：[Ports used by Istio](https://istio.io/latest/docs/ops/deployment/requirements/#ports-used-by-istio)