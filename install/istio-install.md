# Istio 安装

Istio 安装方式很多，本文采用 `istioctl` 命令安装，更多安装方式参考 [Installation Guides](https://istio.io/latest/docs/setup/install/)

> 以 Istio 1.9.0 版本为例说明。

## 1、Istio 下载

1. 在 `Istio release` 页面 [https://github.com/istio/istio/releases/tag/1.9.0](https://github.com/istio/istio/releases/tag/1.9.0) 下载 Istio 安装文件。

2. 将 `istio-1.9.0-linux-amd64.tar.gz` 上传到安装服务器上，并解压。

   ```sh
   tar -xvf istio-1.9.0-linux-amd64.tar.gz
   ```

3. 将 `istioctl` 客户端路径增加到 path 环境变量中，使得能够直接执行 `istioctl` 命令。

   修改当前用户的 `.bash_profile` 文件，将 istio 目录下的 `bin` 文件夹添加到 path 环境变量中，并使其生效（`source .bash_profile`）：

   ```sh
   # 进入当前用户目录
   $ cd ~

   # 修改.bash_profile文件，将istio目录下的bin文件夹添加到path中
   $ vi .bash_profile

   # 使其生效
   $ source .bash_profile
   ```

## 2、Istio 安装

对于本次安装，我们采用 `demo` 安装配置。 选择它是因为它包含了一组专为测试准备的功能集合，另外还有用于生产或性能测试的配置组合。

### 2.1 在线安装

安装命令如下：

```sh
istioctl install --set profile=demo -y
```

`istioctl install` 安装过程中需要下载相关镜像（最好能够**科学上网**），需耐心等待安装完成即可。

（安装失败，大多都是下载镜像失败所致，可确保能够正常下载镜像的情况下，再次执行上述安装命令。）

安装配置：

在安装 Istio 时所能够使用的内置配置文件，通过命令 `istioctl profile list` 可以查看有哪些内置配置。这些配置文件提供了对 Istio 控制平面和 Istio 数据平面 Sidecar 的定制内容。 您可以从 Istio 内置配置文件的其中一个开始入手，然后根据您的特定需求进一步自定义配置文件。当前提供以下几种内置配置文件：

- **default**: 根据默认的[安装选项](https://istio.io/latest/docs/reference/config/installation-options/)启用组件 (建议用于生产部署)。
- **demo**: 这一配置具有适度的资源需求，旨在展示 Istio 的功能。它适合运行 [Bookinfo](https://istio.io/latest/zh/docs/examples/bookinfo/) 应用程序和相关任务。 这是通过[快速开始](https://istio.io/latest/zh/docs/setup/getting-started/)指导安装的配置，但是您以后可以通过[自定义配置](https://istio.io/latest/zh/docs/setup/install/istioctl/#customizing-the-configuration) 启用其他功能来探索更高级的任务。此配置文件启用了高级别的追踪和访问日志，因此不适合进行性能测试。
- **minimal**：与默认配置文件相同，但仅安装控制平面组件。这允许您使用单独的配置文件配置控制平面和数据平面组件（例如，网关）。
- **external**: 用于配置一个远程集群，由一个外部控制平面或通过控制平面主集群的多集群网格。
- **empty**：不部署任何东西。这可以用作自定义配置的基本配置文件。
- **preview**：预览配置文件包含实验性功能。这是为了探索 Istio 的新功能。不保证稳定性、安全性和性能 - 使用风险自负。

组件对应关系表：

|  | default | demo | minimal  | external | empty | preview |
| --- | --- | --- | --- | --- | ---  | --- |
| istio-egressgateway | | ✅  | | | | |
| istio-ingressgateway | ✅  | ✅  | | | | ✅  |
| istiod | ✅  | ✅  | ✅  | | | ✅  |

### 2.2 离线安装

在受网络限制的环境下，需进行离线安装。

1. 准备所需镜像 tar 包。

   在具备下载镜像的环境下，通过 `docker pull` 、`docker save` 命令制作 docker 镜像 tar 包。

2. 导入镜像。

   在 Docker 私有镜像仓库，通过 `docker load` 、 `docker tag` 、 `docker push` 命令，将镜像 tar 包导入私有镜像仓库。

3. 离线安装。

   执行 `istioctl install` 命令，并指定镜像仓库参数：

   ```sh
   istioctl install --set profile=demo --set values.global.hub=192.168.161.100/istio -y
   ```

   > 参数 `--set values.global.hub=xx`，用于设置 istio 安装所需镜像的私有仓库。更多 `--set` 参数值参考[https://istio.io/latest/docs/reference/config/istio.operator.v1alpha1/#IstioOperatorSpec](https://istio.io/latest/docs/reference/config/istio.operator.v1alpha1/#IstioOperatorSpec)

   **对于ARM架构，截止2022年8月，isito 官方暂未提供相应的镜像，可将 `values.global.hub` 设置为 `ghcr.io/resf/istio` 进行安装。**

---

参考资料：

1. [Install with Istioctl](https://istio.io/latest/docs/setup/install/istioctl/)
2. [Installation Configuration Profiles
](https://istio.io/latest/docs/setup/additional-setup/config-profiles/)
