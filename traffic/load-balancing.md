# 负载均衡

`Istio` 中的负载均衡是基于 `Sidecar` 实现，并通过 [DestinationRule](./crd/destination-rule.md) 中的 [`loadBalancer`](https://istio.io/latest/docs/reference/config/networking/destination-rule/#LoadBalancerSettings) 完成负载均衡的配置，目前支持以下负载均衡算法：

- 标准算法：
  - `ROUND_ROBIN`：轮询算法，默认。
  - `LEAST_CONN`：权重最小请求算法。该算法选择两个随机的健康主机，并选择活动请求较少的主机。
  - `RANDOM`：随机算法。该算法选择一个随机的健康主机。如果未配置运行状况检查策略，则随机负载均衡器的性能通常比轮询更好。
  - `PASSTHROUGH`：该算法将连接转发到调用者请求的原始 IP 地址，而不进行任何形式的负载平衡。需谨慎使用，它适用于特殊场景。
- [`consistentHash`](https://istio.io/latest/docs/reference/config/networking/destination-rule/#LoadBalancerSettings-ConsistentHashLB)：一致 `Hash` 算法。该算法可提供基于 `HTTP` 头、`Cookie` 等一致 `Hash` 算法，仅适用于`HTTP` 请求，**常作为基于会话保持的负载均衡算法**。
- [`localityLbSetting`](https://istio.io/latest/docs/reference/config/networking/destination-rule/#LocalityLoadBalancerSetting)：地域负载均衡。提供了地域感知的能力，简单说来，就是在分区部署的较大规模的集群，或者公有云上，`Istio` 负载均衡可以根据节点的区域标签，对调用目标做出就近选择。这些区域是使用任意标签指定的，这些标签以`{region} / {zone} / {sub-zone}`形式指定区域的层次结构。

更多关于 `DestinationRule` 中的 `loadBalancer` 具体配置说明可参考：[`LoadBalancerSettings`](https://istio.io/latest/docs/reference/config/networking/destination-rule/#LoadBalancerSettings)。

例如，采用 `ROUND_ROBIN` 轮询负载均衡策略将流量转发到 `ratings` 服务。

```yaml
apiVersion: networking.istio.io/v1alpha3
kind: DestinationRule
metadata:
  name: bookinfo-ratings
spec:
  host: ratings.prod.svc.cluster.local
  trafficPolicy:
    loadBalancer:
      simple: ROUND_ROBIN
```
