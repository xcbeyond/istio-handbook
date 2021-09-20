# Sidecar

默认情况下，Istio 让每个 Envoy 代理都可以访问来自和它关联的应用服务的所有端口请求，然后转发到对应的应用服务。而通过 Sidecar 资源配置可以做更多的事情，如：

- 调整 Envoy 代理接受的端口和协议集。
- 限制 Envoy 代理可以访问的服务集合。

例如，下面的 Sidecar 配置将 bookinfo 命名空间中的所有服务配置为仅能访问运行在相同命名空间和 Istio 控制平面中的服务：

```yaml
apiVersion: networking.istio.io/v1alpha3
kind: Sidecar
metadata:
  name: default
  namespace: bookinfo
spec:
  egress:
    - hosts:
        - "./*"
        - "istio-system/*"
```
