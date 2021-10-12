# Istio 卸载

在某些场景下，我们需要卸载 Istio,可参考本文进行卸载。

要从集群中完整卸载 Istio，运行下面卸载命令：

```sh
istioctl x uninstall --purge
```

> 可选的 `--purge` 参数将删除所有的 Istio 资源，包括可能被其他 Istio 控制平面共享的、集群范围的资源。

或者，只删除指定的 Istio 控制平面，运行以下命令：

```sh
istioctl x uninstall <your original installation options>
```

或

```sh
istioctl manifest generate <your original installation options> | kubectl delete -f -
```

控制平面的命名空间（例如：`istio-system`）默认不会删除， 如果确认不再需要，用下面命令删除它：

```sh
kubectl delete namespace istio-system
```
