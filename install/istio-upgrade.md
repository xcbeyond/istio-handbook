# 升级

众所周知，Istio 目前属于快速发展时期，版本的更新也是很快，Istio 框架升级也是必须要考虑的一个重要环节。目前，Istio 官方也给出多种升级方法供大家根据实际情况选择。

*以 Istio 1.9.0 版本向 1.10.0 版本升级为例进行说明。*

## 1、金丝雀升级

**金丝雀升级，是一种渐进式的升级方式，可以让新老版本的 `istiod` 同时存在，并可通过流量控制先将一小部分流量路由到新版本的 `istiod` 上管控，逐步完成新版本的升级。** 该种方式比较安全，也是大家比较推荐的升级方法。

首先需 [下载新版本的 Istio](https://github.com/istio/istio/releases)，将其上传至服务器，并切换到新版本的目录。

> **注意：接下来一定要使用新版本的 `istioctl` 命令，否则将会升级失败！**（可参考 [Istio 安装](./istio-install.md) 中修改 `istioctl` `path` 环境变量，或根据 `istioctl` 的路径使用，如：`./bin/istioctl`）

### 1.1 控制平面升级

安装灰度 `canary` 版本，将 `revision` 字段设置为 `canary`：

```sh
istioctl install --set revision=canary --set values.global.hub=192.168.162.47/istio -y
```

> 根据 `istiotcl` 版本来决定升级的 `canary` 版本，所以需确保执行 `istiotcl` 命令的版本为要升级 istio 的版本。

上述执行成功后，会部署一个新的 `istiod-canary`，即：新版本的控制平面，该新的控制平面并不会对原有的控制平面产生影响，此时会有新、旧两个控制平面同时存在：

```sh
$ kubectl get pods -n istio-system -l app=istiod
NAME                                    READY   STATUS    RESTARTS   AGE
istiod-786779888b-p9s5n                 1/1     Running   0          114m
istiod-canary-6956db645c-vwhsk          1/1     Running   0          1m
```

此外，也会同时存在 2 个 service 和  sidecar-injector：

```sh
$ kubectl get svc -n istio-system -l app=istiod
NAME     TYPE        CLUSTER-IP    EXTERNAL-IP   PORT(S)  AGE
istiod          ClusterIP   10.32.5.247   <none>    15010/TCP,15012/TCP,443/TCP,15014/TCP          33d
istiod-canary   ClusterIP   10.32.6.58    <none>        15010/TCP,15012/TCP,443/TCP,15014/TCP,53/UDP,853/TCP   12m
```

```sh
$ kubectl get mutatingwebhookconfigurations
NAME                            WEBHOOKS   AGE
istio-sidecar-injector          1          7m56s
istio-sidecar-injector-canary   1          3m18s
```

### 1.2 数据平面升级

只安装 `canary` 版本的控制平面 `istio-canary` 并不会对现有的代理造成影响，要升级数据平面，需将他们指向新的控制平面，需要在 namespace 中插入 `istio.io/rev` 标签。

例如，想要升级 `default` namespace 的数据平面，需要添加 `istio.io/rev` 标签以指向 `canary` 版本的控制平面，并删除 `istio-injection` 标签：

```sh
kubectl label namespace default istio-injection- istio.io/rev=canary
```

注意：`istio-injection` 标签必须删除，因为该标签的优先级高于 `istio.io/rev` 标签，保留该标签将导致无法升级数据平面。

在 namespace 的标签更新成功后，需要重启 Pod 来重新注入 Sidecar：

```sh
kubectl rollout restart deployment -n default
```

当重启成功后，该 namespace 的 Pod 将被配置指向新的 `istiod-canary` 控制平面，使用如下命令查看启用新代理的 Pod：

```sh
kubectl get pods -n default -l istio.io/rev=canary
```

同时可以使用如下命令 `istioctl proxy-status` 查看新 Pod 的控制平面是否为 `istiod-canary` 及是否为新版本号：

```sh
istioctl proxy-status
```

> 目前 `Istio` `1.10.0` 版本在金丝雀升级时，`istio-egressgateway` 并未升级，可能是该版本存在的 `bug`，期待后续版本更新。

### 1.3 卸载旧的控制平面

升级控制平面和数据平面之后，您可以卸载旧的控制平面。例如，以下命令可以卸载旧的控制平面 `1-9-0`：

```sh
istioctl x uninstall --revision 1-9-0
```

> 卸载前提是，旧版本的控制平面没有被使用。

如果旧的控制平面没有 `revision` 版本标签，请使用其原始安装选项将其卸载，例如：

```sh
istioctl x uninstall -f manifests/profiles/default.yaml
```

通过以下方式可以确认旧的控制平面已被移除，并且集群中仅存在新的控制平面：

```sh
$ kubectl get pods -n istio-system -l app=istiod
NAME                             READY   STATUS    RESTARTS   AGE
istiod-canary-55887f699c-t8bh8   1/1     Running   0          27m
```

请注意，以上说明仅删除了用于指定控制平面修订版的资源，而未删除与其他控制平面共享的群集作用域资源。要完全卸载 istio，请参阅[卸载](# 4.2 卸载)。

### 1.4 卸载金丝雀控制平面（回滚）

如果您想要回滚到旧的控制平面，而不是完成金丝雀升级，则可以卸载 Canary 版本：

```sh
istioctl x uninstall --revision=canary
```

但是，在这种情况下，您必须首先手动重新安装先前版本的网关，因为卸载命令不会自动还原先前升级的网关。

> 确保使用与 `istioctl` 旧控制平面相对应的版本来重新安装旧网关，并且为避免停机，请确保旧网关已启动并正在运行，然后再进行金丝雀卸载。

## 2、原地升级

通过 `istioctl upgrade` 命令将对 Istio 进行升级。在执行升级之前，它会检查 Istio 安装是否满足升级资格标准。另外，如果它检测到 Istio 版本之间的配置文件默认值有任何更改，也会警告用户。

> 目前原地升级有很大的概率通不过升级检测，导致无法升级，不推荐这种升级方式。期待后续版本更好的支持。

官方原地升级文档：[https://istio.io/latest/docs/setup/upgrade/in-place/](https://istio.io/latest/docs/setup/upgrade/in-place/)
