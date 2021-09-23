# 基于 WASM 扩展 Envoy

## Envoy WASM 介绍

[WebAssembly](http://webassembly.org.cn/) 是一种沙盒技术，可用于扩展 Istio 代理（Envoy）的能力。Proxy-Wasm 沙盒 API 取代了 Mixer 作为 Istio 主要的扩展机制。

WebAssembly 沙盒的目标：

- 效率：这是一种低延迟，低 CPU 和低内存开销的扩展机制。
- 功能：这是一种可以执行策略，收集遥测数据和执行有效负载变更的扩展机制。
- 隔离：一个插件中程序的错误或是崩溃不会影响其它插件。
- 配置：插件的使用与其它 Istio API 一致的 API 进行配置，可以动态的配置扩展。
- 运维：扩展可以仅日志，故障打开或者故障关闭的方式进行访问和部署。
- 扩展开发者：可以用多种编程语言编写。

## 基于 Go 语言实现 Istio Envoy 的扩展

本示例是基于[http_headers](https://github.com/tetratelabs/proxy-wasm-go-sdk/tree/main/examples/http_headers)示例，来学习如何基于 Go 语言实现 Envoy WASM 的扩展，并应用于服务网格 Istio。

### 环境准备

- 安装 go
  链接：[https://golang.org/doc/install](https://golang.org/doc/install)
- 安装 tinygo
  链接：[https://tinygo.org/getting-started/linux/](https://tinygo.org/getting-started/linux/)

> 提示：如果已有 go 环境，则不需要重复安装，tinygo 用于编译成 wasm 插件。tinygo 也可以从 github 直接下载解压，把解压后的 bin 目录加入到 PATH 目录。

下面以 MACOS 环境来安装 tinygo：

```sh
% brew tap tinygo-org/tools
% brew install tinygo
```

### 开发 WASM

开发 WASM 插件，理论上可以采用任何开发语言。目前已有不同语言实现的 Envoy Proxy WASM SDK 可供使用，如：

- [proxy-wasm-cpp-sdk](https://github.com/proxy-wasm/proxy-wasm-cpp-sdk)
- [proxy-wasm-rust-sdk](https://github.com/proxy-wasm/proxy-wasm-rust-sdk)
- [AssemblyScript](https://github.com/solo-io/proxy-runtime)
- [proxy-wasm-go-sdk](https://github.com/tetratelabs/proxy-wasm-go-sdk)

本文示例采用由 tetrate 开发的 Go SDK，以[http_headers](https://github.com/tetratelabs/proxy-wasm-go-sdk/tree/main/examples/http_headers)示例进行举例。

1. 下载[http_headers](https://github.com/tetratelabs/proxy-wasm-go-sdk/tree/main/examples/http_headers)示例代码。
2. 通过 TinyGo 编译生成 WASM 文件。

   在 http_headers 目录下执行 `tinygo` 命令编译，生成 http-headers.wasm。

   ```sh
   % tinygo build -o ./http-headers.wasm -scheduler=none -target=wasi ./main.go
   ```

### 挂载 WSAM 文件

将 WASM 文件挂载到目标 Pod 的 Sidecar(即：istio-proxy)容器中。

以文件的方式，创建 ConfigMap。

```sh
% kubectl create cm http-headers-wasm --from-file=http-headers.wasm
```

将 WASM 文件挂载到目标 Pod 的 Sidecar 容器中，即：修改 Deployment，为其添加如下注解：

```sh
sidecar.istio.io/userVolume: '[{"name":"wasmfilters-dir","configMap": {"name": "http-headers-wasm"}}]'
sidecar.istio.io/userVolumeMount: '[{"mountPath":"/var/local/lib/wasm-filters","name":"wasmfilters-dir"}]'
```

istiod 会依据这 2 个注解，将名为 http-headers-wasm 的 configmap，挂载到 istio-proxy 容器的 /var/local/lib/wasm-filters 目录下。

```sh
% kubectl patch deployment go-httpbin -p '{"spec":{"template":{"metadata":{"annotations":{"sidecar.istio.io/userVolume":"[{\"name\":\"wasmfilters-dir\",\"configMap\": {\"name\": \"http-headers-wasm\"}}]","sidecar.istio.io/userVolumeMount":"[{\"mountPath\":\"/var/local/lib/wasm-filters\",\"name\":\"wasmfilters-dir\"}]"}}}}}'
```

Pod 重新创建后，在 istio-proxy 的 /var/local/lib/wasm-filters 下可以查看到 http-headers.wasm 文件。

### 创建 EnvoyFilter

创建 EnvoyFilter 资源，用于加载 WASM 插件。

编写的 EnvoyFilter 如下：

```yaml
apiVersion: networking.istio.io/v1alpha3
kind: EnvoyFilter
metadata:
  name: http-headers-filter
spec:
  configPatches:
    - applyTo: HTTP_FILTER
      match:
        context: SIDECAR_INBOUND
        proxy:
          proxyVersion: ^1\.11.*
        listener:
          portNumber: 8080
          filterChain:
            filter:
              name: envoy.filters.network.http_connection_manager
              subFilter:
                name: envoy.filters.http.router
      patch:
        operation: INSERT_BEFORE
        value:
          name: envoy.filters.http.wasm
          typed_config:
            "@type": type.googleapis.com/udpa.type.v1.TypedStruct
            type_url: type.googleapis.com/envoy.extensions.filters.http.wasm.v3.Wasm
            value:
              config:
                # root_id: add_header
                vm_config:
                  code:
                    local:
                      filename: /var/local/lib/wasm-filters/http-headers.wasm
                  runtime: envoy.wasm.runtime.v8
                  # vm_id: "my_vm_id"
                  allow_precompiled: false
  workloadSelector:
    labels:
      app: go-httpbin
```

其中：

- proxyVersion 与 istio-proxy 版本保持一致。
- filename 需要与前面Deployment中的 Annotation 保持一致。
- workloadSelector 设置为目标 Pod 的 label。

### 验证

验证 Envoy扩展的WASM插件是否生效。

登录到其它服务网格的服务容器中，请求该服务中存在的URL，查看该服务的istio-proxy容器的日志。

---

参考资料：

1. [https://istio.io/latest/docs/concepts/wasm/](https://istio.io/latest/docs/concepts/wasm/)
2. [proxy-wasm-go-sdk](https://github.com/tetratelabs/proxy-wasm-go-sdk/)
3. [Extending Envoy Proxy with Golang WebAssembly](https://tufin.medium.com/extending-envoy-proxy-with-golang-webassembly-e51202809ba6)
