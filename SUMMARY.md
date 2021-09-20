# Summary

## 前言

- [序言](README.md)

## 微服务架构

- [迎接新一代微服务架构](microservice/new-generation-microservices-architecture.md)

## Service Mesh 概述

- [Service Mesh 介绍](servicemesh/introduction.md)
- [Service Mesh 框架对比](servicemesh/framework-contrast.md)

## Istio 架构剖析

- [Istio 整体架构](architecture/istio-architecture.md)
- [数据平面](architecture/dataplane.md)
- [控制平面](architecture/controlplane.md)

## 安装与部署

- [Istio 安装](install/istio-install.md)
- [Istio 卸载](install/istio-uninstall.md)
- [部署示例](install/deployment-bookinfo-application.md)
- [升级](install/istio-upgrade.md)

## 流量管理

- [资源配置](traffic/config/index.md)
  - [VirtualService](traffic/config/virtual-service.md)
  - [DestinationRule](traffic/config/destination-rule.md)
  - [Gateway](traffic/config/gateway.md)
  - [ServiceEntry](traffic/config/service-entry.md)
  - [EnvoyFilter](traffic/config/envoy-filter.md)
  - [Sidecar](traffic/config/sidecar.md)

## 安全

## 可观测性

## 扩展性

- [基于 WASM 扩展 Envoy](extensibility/extending-envoy-proxy-with-webassembly.md)

## 集成

- 集成注册中心
  - [集成 Consul](integration/consul/integration-consul.md)
