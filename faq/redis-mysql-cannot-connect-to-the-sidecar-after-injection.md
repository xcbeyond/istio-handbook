# Redis、MySQL等注入边车后，无法访问问题

针对一些特殊协议的服务，注入网格后，是无法直接访问。

可以通过 DestinationRule 禁用 Redis Service 的 mTLS：

```yaml
apiVersion: networking.istio.io/v1alpha3
kind: DestinationRule
metadata:
  name: redis-disable-mtls
spec:
  host: redis.default.svc.cluster.local
  trafficPolicy:
    tls:
      mode: DISABLE

```

参考：

1. [Server First Protocols](https://istio.io/latest/docs/ops/deployment/requirements/#server-first-protocols)
2. [Istio 运维实战系列（2）：让人头大的『无头服务』-上](https://www.zhaohuabing.com/post/2020-09-11-headless-mtls/)