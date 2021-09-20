# 资源配置

Istio 的流量管理是通过一系列的 CRD（Kubernetes 的自定义资源）来实现的，包括以下这些资源：

- [VirtualService](virtual-service.md)：虚拟服务，用来定义路由规则，控制请求如何被路由到某个服务。
- [DestinationRule](destination-rule.md)：目标规则，用来配置请求策略。
- [Gateway](gateway.md)：网关，在网格的入口设置负载、控制流量等。
- [ServiceEntry](service-entry.md)：服务入口，用来定义外部如何访问服务网格。
- [EnvoyFilter](envoy-filter.md)：
- [Sidecar](sidecar.md)：
