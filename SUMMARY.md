# Summary

## 前言

- [序言](README.md)

## 微服务架构

- [迎接新一代微服务架构](microservice/new-generation-microservices-architecture.md)

## 服务网格概述

- [服务网格介绍](servicemesh/introduction.md)
- [服务网格框架对比](servicemesh/framework-contrast.md)

## Istio 架构剖析

- [Istio 整体架构](architecture/istio-architecture.md)
- [数据平面](architecture/dataplane.md)
- [控制平面](architecture/controlplane.md)

## 安装与部署

- [Istio 安装](install/istio-install.md)
- [Istio 卸载](install/istio-uninstall.md)
- [部署 Bookinfo 示例](install/deploy-bookinfo-sample.md)
- [部署 Kiali](install/deploy-kiali.md)
- [升级](install/istio-upgrade.md)

## 流量管理

- [概述](traffic/index.md)
- [资源配置](traffic/crd/traffic-crd.md)
  - [VirtualService](traffic/crd/virtual-service.md)
  - [DestinationRule](traffic/crd/destination-rule.md)
  - [Gateway](traffic/crd/gateway.md)
  - [ServiceEntry](traffic/crd/service-entry.md)
  - [EnvoyFilter](traffic/crd/envoy-filter.md)
  - [Sidecar](traffic/crd/sidecar.md)
- [路由](traffic/route.md)
- [负载均衡](traffic/load-balancing.md)
- [流量镜像](traffic/traffic-shadow.md)
- [Ingress](traffic/ingress.md)
- [Egress](traffic/egress.md)
- [超时]()
- [重试]()
- [熔断](traffic/circuit-breaking.md)
- [限流]()
- [故障注入](traffic/fault-injection.md)
- [灰度发布](traffic/gray-release.md)

## 安全

- [资源配置](security/crd/security-crd.md)
  - [RequestAuthentication](security/crd/request-authentication.md)
  - [PeerAuthentication](security/crd/peer-authentication.md)
  - [AuthorizationPolicy](security/crd/authorization-policy.md)

## 可观测性

## 扩展性

- [基于 WASM 扩展 Envoy](extensibility/extending-envoy-proxy-with-webassembly.md)

## 集成

- [集成注册中心](integration/registry/integration-registry.md)
  - [集成 Consul](integration/registry/integration-consul.md)

## FAQ
