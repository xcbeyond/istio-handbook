# 故障注入

故障注入（`Fault Injection`），即：**故障测试**，是 `Istio` 提供了一种无侵入式的故障注入机制，让开发测试人员在不用调整服务程序的前提下，通过配置即可完成对服务的异常模拟，完成对系统的定向错误测试。

通过引入故障来模拟网络传输中的问题（如延迟）来验证系统的健壮性，方便完成系统的各类故障测试。通过配置上游主机的 `VirtualService` 来实现，当我们在 `VirtualService` 中配置了故障注入时，上游服务的 `Sidecar` 代理在拦截到请求之后就会做出相应的响应。

目前，`Istio` 提供两种类型的故障注入，`abort` 类型与 `delay` 类型。

* `abort`：非必配项，配置一个 `Abort` 类型的对象。用来注入**请求异常类故障**。简单的说，就是用来模拟上游服务对请求返回指定异常码时，当前的服务是否具备处理能力。它对应于 `Envoy` 过滤器中的 `config.filter.http.fault.v2.FaultAbort` 配置项，当 `VirtualService` 资源应用时，`Envoy` 将会该配置加载到过滤器中并处理接收到的流量。
* `delay`：非必配项，配置一个 `Delay` 类型的对象。用来注入**延时类故障**。通俗一点讲，就是人为模拟上游服务的响应时间，测试在高延迟的情况下，当前的服务是否具备容错容灾的能力。它对应于 `Envoy` 过滤器中的 `config.filter.fault.v2.FaultDelay` 配置型，同样也是在应用 `Istio` 的 `VirtualService` 资源时，`Envoy` 将该配置加入到过滤器中。

实际上，`Istio` 的故障注入是基于 `Envoy` 的 `config.filter.http.fault.v2.HTTPFault` 过滤器实现的，它的局限性也来自于 Envoy 故障注入机制的局限性。对于 `Envoy` 的 `HttpFault` 的详细介绍请参考[Envoy 文档](https://www.envoyproxy.io/docs/envoy/latest/api-v2/config/filter/http/fault/v2/fault.proto#envoy-api-msg-config-filter-http-fault-v2-httpfault)。对比 `Istio` 故障注入的配置项与 `Envoy` 故障注入的配置项，不难发现，`Istio` 简化了对于故障控制的手段，去掉了 `Envoy` 中通过 `HTTP header` 控制故障注入的配置。

**HTTPFaultInjection.Abort：**

* `httpStatus`：必配项，是一个整型的值。表示注入 HTTP 请求的故障状态码。

* `percentage`：非必配项，是一个 `Percent` 类型的值。表示对多少请求进行故障注入。如果不指定该配置，那么所有请求都将会被注入故障。

**HTTPFaultInjection.Delay：**

* `fixedDelay`：必配项，表示请求响应的模拟处理时间。格式为：`1h/1m/1s/1ms`， 不能小于 `1ms`。
* `percentage`：非必配项，是一个 `Percent` 类型的值。表示对多少请求进行故障注入。如果不指定该配置，那么所有请求都将会被注入故障。