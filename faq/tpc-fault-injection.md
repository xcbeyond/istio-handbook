# TCP协议服务故障注入（如：redis）

目前istio故障注入是通过VS实现对http协议的故障，针对TCP协议还未直接支持。

为了解决TCP协议类服务的故障注入，可以采取以下两种方式实现：

1. 基于 Envoy 的 [RedisProxy能力](https://www.envoyproxy.io/docs/envoy/latest/intro/arch_overview/other_protocols/redis#arch-overview-redis) ，网格内的 Redis 流量将经由 Envoy 代理，通过配置EnvoyFilter来实现。(待验证)

2. 通过 VS 将匹配到redis端口, 路由到一个未知的service 来实现。

  ```yaml
    apiVersion: networking.istio.io/v1alpha3
    kind: VirtualService
    metadata:
        name: redis-route
        namespace: redis
    spec:
        hosts:
        - devops-redis.redis.svc.cluster.local
        tcp:
            match:
            - port: 6379
            route:
              destination:
                host: devops-redis-unknown.redis.svc.cluster.local
                port:
                  number: 6379
  ```
  
参考：

1. [Help: Is it possible to inject faults in Redis with Envoy Redis Proxy?](https://github.com/istio/istio/issues/27064)
2. [Redis 流量管理](https://github.com/aeraki-mesh/aeraki/blob/master/docs/zh/redis.md)
3. [https://stackoverflow.com/questions/66941477/redis-fault-injection-using-istio-and-envoy-filter](redis fault injection using istio and envoy filter)
4. [How to Fault Injection for redis](https://discuss.istio.io/t/how-to-fault-injection-for-redis/2668)