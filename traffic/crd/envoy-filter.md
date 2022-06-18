# EnvoyFilter

EnvoyFilter 提供了一种机制来定制 Istio Pilot 生成的 Envoy 配置。使用 EnvoyFilter 来修改某些字段的值，添加特定的过滤器，甚至添加全新的 listener、cluster 等。这个功能必须谨慎使用，因为不正确的配置可能破坏整个网格的稳定性。与其他 Istio 网络对象不同，EnvoyFilter 对应用是累加生效的。对于特定命名空间中的特定工作负载，可以存在任意数量的 EnvoyFilter，并累加生效。这些 EnvoyFilter 的生效顺序如下：配置[根命名空间](https://istio.io/latest/zh/docs/reference/config/istio.mesh.v1alpha1/#MeshConfig)中的所有 EnvoyFilter，其次是工作负载命名空间中的所有匹配 EnvoyFilter。

注意：

* 该 API 的某些方面与 Istio 网络子系统的内部实现以及 Envoy 的 xDS API 有很深的关系。虽然 EnvoyFilter API 本身将保持向后兼容，但通过该机制提供的任何 Envoy 配置应在 Istio 代理版本升级时仔细审查，以确保废弃的字段被适当地删除和替换。

* 当多个 EnvoyFilter 被绑定到特定命名空间的同一个工作负载时，所有补丁将按照创建顺序处理。如果多个 EnvoyFilter 的配置相互冲突，则其行为将无法确定。

* 要将 EnvoyFilter 资源应用于系统中的所有工作负载（sidecar 和 gateway）上，请在 config 根命名空间中定义该资源，不要使用 workloadSelector。

## 配置项

下图是 EnvoyFilter 的资源配置项：

![EnvoyFilter 资源配置项](envoyfilter-configuration.png)

## 示例


## 参考

1. [Envoy Filter](https://istio.io/latest/zh/docs/reference/config/networking/envoy-filter/)