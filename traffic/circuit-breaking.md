# 熔断

熔断（`Circuit Breaker`），是指当服务到达系统负载阈值时，为避免整个软件系统不可用，而采取的一种主动保护措施。例如，熔断应用于金融领域，指当股指波幅达到规定的熔断点时，交易所为控制风险采取的暂停交易措施。

对于微服务系统而言，熔断尤为重要，它可以使系统在遭遇某些模块故障时，通过服务降级等方式来提高系统核心功能的可用性，得以应对来自故障、潜在峰值或其他未知网络因素的影响。

在 Istio 中也具备了熔断的基本功能。

## 1、熔断实现

通过配置上游主机的 `DestinationRule` 来实现，当我们在`DestinationRule`中配置了熔断([`ConnectionPoolSettings`](https://istio.io/latest/zh/docs/reference/config/networking/destination-rule/#ConnectionPoolSettings)、[OutlierDetection](https://istio.io/latest/docs/reference/config/networking/destination-rule/#OutlierDetection)）时，上游服务的`Sidecar`代理将会根据配置进行阻止。

**`connectionPool`：**

控制请求的最大数量，挂起请求，重试或者超时等。通过设置连接池 `connectionPool`的各项配置，来完成熔断，其中分为 `TCP` 和 `HTTP` 两类：

* `TCP`：`HTTP` 和 `TCP` 上游连接的设置。
  * `MaxConnections`：到目标主机的 `HTTP/TCP` 最大连接数量。
  * `ConnectTimeout`：`TCP` 连接超时时间，默认单位秒。
  * `TcpKeepalive`
  
* `HTTP`：用于 `TCP1.1/HTTP2/gRPC` 连接的设置。

  * `Http1MaxPendingRequests`：`HTTP` 请求 `pending` 状态的最大请求数，从应用容器发来的 `HTTP` 请求的最大等待转发数，默认是1024。
  * `Http2MaxRequests`：后端请求的最大请求数，默认是1024。
  * `MaxRequestsPerConnection`：在一定时间内限制对后端服务发起的最大请求数，如果超过了这个限制，就会开启限流。如果将这一参数设置为 1 则会禁止 `keepalive` 特性。
  * `MaxRetries`：最大重试次数，默认为3。
  * `IdleTimeout`：上游连接池连接的空闲超时。空闲超时被定义为没有活动请求的时间段。如果未设置，则没有空闲超时。当达到空闲超时时，连接将被关闭。注意，基于请求的超时意味着`HTTP/2` `ping` 将无法保持有效连接。适用于 `HTTP1.1` 和 `HTTP2` 连接。
  * `H2UpgradePolicy`

**`outlierDetection`：**

用来控制从负载均衡池中剔除不健康的实例，可以设置最小逐出时间和最大逐出百分比。

* `consecutive5xxErrors`
* `interval`
* `baseEjectionTime`

## 2、示例

参考：<https://istio.io/latest/zh/docs/tasks/traffic-management/circuit-breaking/>

以官方[`httpbin`](https://github.com/istio/istio/tree/release-1.9/samples/httpbin) 示例验证。

1. 部署`httpbin` 示例。

   ```shell
   $ kubectl apply -f samples/httpbin/httpbin.yaml
   serviceaccount/httpbin unchanged
   service/httpbin created
   deployment.apps/httpbin created
   ```

2. 配置熔断器。

   创建一个`DestinationRule`，并配置熔断策略：

   ```shell
   $ kubectl apply -f - <<EOF
   apiVersion: networking.istio.io/v1alpha3
   kind: DestinationRule
   metadata:
     name: httpbin
   spec:
     host: httpbin
     trafficPolicy:
       connectionPool:
         tcp:
           maxConnections: 1
         http:
           http1MaxPendingRequests: 1
           maxRequestsPerConnection: 1
   EOF
   ```

3. 测试客户端。

   创建客户端程序以发送流量到 `httpbin` 服务。把 [`Fortio`](https://github.com/istio/fortio) 作为负载测试的客户端，其可以控制连接数、并发数及发送 `HTTP` 请求的延迟。通过 `Fortio` 能够有效的触发前面在 `DestinationRule` 中设置的熔断策略。

   （1）部署 `Fortio`：

   ```shell
   $ kubectl apply -f samples/httpbin/sample-client/fortio-deploy.yaml
   service/fortio created
   deployment.apps/fortio-deploy created 
   ```

   （2）登入客户端 Pod 并使用 `Fortio` 工具调用 `httpbin` 服务，验证是否请求成功。

   ```shell
   $ kubectl exec -it $(kubectl get pod | grep fortio | awk '{ print $1 }')  -c fortio -- /usr/bin/fortio curl -quiet  http://httpbin:8000/get
   HTTP/1.1 200 OK
   server: envoy
   date: Tue, 13 Apr 2021 :47:00 GMT
   content-type: application/json
   access-control-allow-origin: *
   access-control-allow-credentials: true
   content-length: 445
   x-envoy-upstream-service-time: 36
   
   {
     "args": {},
     "headers": {
       "Content-Length": "0",
       "Host": "httpbin:8000",
       "User-Agent": "istio/fortio-0.6.2",
       "X-B3-Sampled": "1",
       "X-B3-Spanid": "824fbd828d809bf4",
       "X-B3-Traceid": "824fbd828d809bf4",
       "X-Ot-Span-Context": "824fbd828d809bf4;824fbd828d809bf4;0000000000000000",
       "X-Request-Id": "1ad2de20-806e-9622-949a-bd1d9735a3f4"
     },
     "origin": "127.0.0.1",
     "url": "http://httpbin:8000/get"
   }
   ```

4. 触发熔断。

   在 `DestinationRule` 配置中，定义了 `maxConnections: 1` 和 `http1MaxPendingRequests: 1`。 这些规则意味着，如果并发的连接和请求数超过一个，在 `istio-proxy` 进行进一步的请求和连接时，后续请求或连接将被拒绝。

   发送并发数为 3 的连接（-c 3），请求 30 次（-n 30）：

   ```shell
   $ kubectl exec -it $(kubectl get pod | grep fortio | awk '{ print $1 }')  -c fortio -- /usr/bin/fortio load -c 3 -qps 0 -n 30 -loglevel Warning http://httpbin:8000/get
   Fortio 0.6.2 running at 0 queries per second, 2->2 procs, for 5s: http://httpbin:8000/get
   Starting at max qps with 3 thread(s) [gomax 2] for exactly 30 calls (10 per thread + 0)
   23:51:51 W http.go:617> Parsed non ok code 503 (HTTP/1.1 503)
   23:51:51 W http.go:617> Parsed non ok code 503 (HTTP/1.1 503)
   23:51:51 W http.go:617> Parsed non ok code 503 (HTTP/1.1 503)
   23:51:51 W http.go:617> Parsed non ok code 503 (HTTP/1.1 503)
   23:51:51 W http.go:617> Parsed non ok code 503 (HTTP/1.1 503)
   23:51:51 W http.go:617> Parsed non ok code 503 (HTTP/1.1 503)
   23:51:51 W http.go:617> Parsed non ok code 503 (HTTP/1.1 503)
   23:51:51 W http.go:617> Parsed non ok code 503 (HTTP/1.1 503)
   23:51:51 W http.go:617> Parsed non ok code 503 (HTTP/1.1 503)
   23:51:51 W http.go:617> Parsed non ok code 503 (HTTP/1.1 503)
   23:51:51 W http.go:617> Parsed non ok code 503 (HTTP/1.1 503)
   Ended after 71.05365ms : 30 calls. qps=422.22
   Aggregated Function Time : count 30 avg 0.0053360199 +/- 0.004219 min 0.000487853 max 0.018906468 sum 0.160080597
   # range, mid point, percentile, count
   >= 0.000487853 <= 0.001 , 0.000743926 , 10.00, 3
   > 0.001 <= 0.002 , 0.0015 , 30.00, 6
   > 0.002 <= 0.003 , 0.0025 , 33.33, 1
   > 0.003 <= 0.004 , 0.0035 , 40.00, 2
   > 0.004 <= 0.005 , 0.0045 , 46.67, 2
   > 0.005 <= 0.006 , 0.0055 , 60.00, 4
   > 0.006 <= 0.007 , 0.0065 , 73.33, 4
   > 0.007 <= 0.008 , 0.0075 , 80.00, 2
   > 0.008 <= 0.009 , 0.0085 , 86.67, 2
   > 0.009 <= 0.01 , 0.0095 , 93.33, 2
   > 0.014 <= 0.016 , 0.015 , 96.67, 1
   > 0.018 <= 0.0189065 , 0.0184532 , 100.00, 1
   # target 50% 0.00525
   # target 75% 0.00725
   # target 99% 0.0186345
   # target 99.9% 0.0188793
   Code 200 : 19 (63.3 %)
   Code 503 : 11 (36.7 %)
   Response Header Sizes : count 30 avg 145.73333 +/- 110.9 min 0 max 231 sum 4372
   Response Body/Total Sizes : count 30 avg 507.13333 +/- 220.8 min 217 max 676 sum 15214
   All done 30 calls (plus 0 warmup) 5.336 ms avg, 422.2 qps
   ```

   从上述结果来看，只有63.3 %的请求成功，其余全部熔断拦截。

   ```sh
   Code 200 : 19 (63.3 %)
   Code 503 : 11 (36.7 %)
   ```

   另外，通过查询 `istio-proxy` 状态以了解更多熔断详情:

   ```sh
   $ kubectl exec $(kubectl get pod | grep fortio | awk '{ print $1 }') -c istio-proxy -- pilot-agent request GET stats | grep httpbin | grep pending
   cluster.outbound|80||httpbin.springistio.svc.cluster.local.upstream_rq_pending_active: 0
   cluster.outbound|80||httpbin.springistio.svc.cluster.local.upstream_rq_pending_failure_eject: 0
   cluster.outbound|80||httpbin.springistio.svc.cluster.local.upstream_rq_pending_overflow: 11
   cluster.outbound|80||httpbin.springistio.svc.cluster.local.upstream_rq_pending_total: 20
   ```

   可以看到 `upstream_rq_pending_overflow` 值 11，这意味着，目前为止已有 11 个调用被标记为熔断。
