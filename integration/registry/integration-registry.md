# 集成注册中心

Istio 作为服务网格领域主流的开源框架，为微服务提供了零侵入的流量管理、服务可观测性等方面的服务治理能力，解决了传统微服务架构体系（如：Spring Cloud 技术体系）存在的高侵入性问题，彻底释放出业务开发人员无需过度关注服务治理的烦恼。

随着服务网格的推进，越来越多的项目尝试向服务网格转型，将传统微服务架构下的服务向服务网格迁移，为了降低迁移风险，大多采取阶段性、平滑迁移。一般先将所有服务容器化，迁移到 Kubernetes 上管理，再将服务纳入到网格管理。但面对庞大的存量微服务项目来说，往往为了能够快速迁移，以享受 Istio 提供的各种服务治理能力，采取服务上容器、Kubernetes、纳入网格，但服务注册仍采用原有的注册方式，如：Eureka、Consul、Nacos 等。为此，就需要考虑在 Istio 中如何集成第三方注册中心的问题，本节将针对 Istio 中的服务注册展开讨论，并为集成注册中心提供思路和方案，供参考使用。

## 1、Istio 服务注册发现机制

Istio 中服务的注册与发现是在控制平面实现，主要由 Pilot 组件完成，准确来说应该是[pilot-discovery](https://github.com/istio/istio/tree/master/pilot/cmd/pilot-discovery),负责所有服务的注册发现。

## 2、服务注册中心对接方式

## 3、总结

---

参考资料：

1. [如何将第三方服务中心注册集成到 Istio ？](https://www.servicemesher.com/blog/istio-service-registy-integration/)
