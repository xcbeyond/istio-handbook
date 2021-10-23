# DestinationRule

`DestinationRule` 是 `Istio` 中定义的另外一个比较重要的资源，它定义了网格中某个 `Service` 对外提供服务的策略及规则，包括负载均衡策略、异常点检测、熔断控制、访问连接池等。

负载均衡策略支持简单的负载策略（`ROUND_ROBIN`、`LEAST_CONN`、`RANDOM`、`PASSTHROUGH`）、一致性 `Hash` 策略和区域性负载均衡策略。

异常点检测配置在服务连续返回了`5xx`的错误时进行及时的熔断保护，避免引起雪崩效应。`DestinationRule` 也可以同 `VirtualService` 配合使用实现对同源服务不同子集服务的访问配置。
