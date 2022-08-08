# EnvoyFilter

EnvoyFilter 提供了一种机制来定制 Istio Pilot 生成的 Envoy 配置。使用 EnvoyFilter 来修改某些字段的值，添加特定的过滤器，甚至添加全新的 listener、cluster 等。这个功能必须谨慎使用，因为不正确的配置可能破坏整个网格的稳定性。与其他 Istio 网络对象不同，EnvoyFilter 对应用是累加生效的。对于特定命名空间中的特定工作负载，可以存在任意数量的 EnvoyFilter，并累加生效。这些 EnvoyFilter 的生效顺序如下：配置[根命名空间](https://istio.io/latest/zh/docs/reference/config/istio.mesh.v1alpha1/#MeshConfig)中的所有 EnvoyFilter，其次是工作负载命名空间中的所有匹配 EnvoyFilter。

注意：

* 该 API 的某些方面与 Istio 网络子系统的内部实现以及 Envoy 的 xDS API 有很深的关系。虽然 EnvoyFilter API 本身将保持向后兼容，但通过该机制提供的任何 Envoy 配置应在 Istio 代理版本升级时仔细审查，以确保废弃的字段被适当地删除和替换。

* 当多个 EnvoyFilter 被绑定到特定命名空间的同一个工作负载时，所有补丁将按照创建顺序处理。如果多个 EnvoyFilter 的配置相互冲突，则其行为将无法确定。

* 要将 EnvoyFilter 资源应用于系统中的所有工作负载（sidecar 和 gateway）上，请在 config 根命名空间中定义该资源，不要使用 workloadSelector。

## 1、配置项

下图是 EnvoyFilter 的资源配置项：

![EnvoyFilter 资源配置项](envoyfilter-configuration.png)

## 2、示例

### 2.1 前提准备

#### 2.1.1 开启注入

服务需注入边车，对其运行命名空间添加自动注入标签 `istio-injection=enabled`：

```sh
kubectl label namespace samples istio-injection=enabled
```

#### 2.1.2 服务准备

通过服务 `sleep` 发起请求，调用服务 `helloworld` 的 `/hello` 完成相应功能的验证。

1. sleep。

   `kubectl apply -f samples/sleep/sleep.yaml -n samples`

2. helloworld。

   1）部署服务 helloworld。

   `kubectl apply -f samples/helloworld/helloworld.yaml -n samples`

   2）部署 helloworld gateway。

   `kubectl apply -f samples/helloworld/helloworld-gateway.yaml -n samples`

### 2.2 添加 HTTP 响应头

在应用程序中添加 HTTP 响应头可以提高 Web 应用程序的安全性。本示例介绍如何通过定义 EnvoyFilter 添加HTTP 响应头。

OWASP(Open Web Application Security Project) 提供了最佳实践指南和编程框架，描述了如何使用安全响应头保护应用程序的安全。HTTP 响应头的基准配置如下：

| HTTP响应头 |	默认值 | 描述 |
| --- | --- | --- |
| Content-Security-Policy | frame-ancestors none; | 防止其他网站进行Clickjacking攻击。|
| X-XSS-Protection |	1;mode=block |	激活浏览器的XSS过滤器（如果可用），检测到XSS时阻止渲染。|
| X-Content-Type-Options |	Nosniff | 禁用浏览器的内容嗅探。|
| Referrer-Policy	| no-referrer | 禁用自动发送引荐来源。|
| X-Download-Options | noopen | 禁用旧版本IE中的自动打开下载功能。|
| X-DNS-Prefetch-Control | off |	禁用对页面上的外部链接的推测性DNS解析。|
| Server | envoy | 由Istio的入口网关自动设置。|
| X-Powered-by | 无默认值 | 去掉该值来隐藏潜在易受攻击的应用程序服务器的名称和版本。|
| Feature-Policy | camera ‘none’; microphone ‘none’;geolocation ‘none’;encrypted-media ‘none’;payment ‘none’;speaker ‘none’;usb ‘none’; | 控制可以在浏览器中使用的功能和API。|

#### 2.2.1 边车

具体服务上生效。

1. 创建 Envoyfilter。

   `kubectl apply -f samples/envoyfilter/ef-add-response-headers-into-sidecar.yaml -n samples`

   > 注：与服务在相同的 namespace。

   ```yaml
   apiVersion: networking.istio.io/v1alpha3
   kind: EnvoyFilter
   metadata:
      name: ef-add-response-headers-into-sidecar
   spec:
   workloadSelector:
      # select by label in the same namespace
      labels:
         app: helloworld
   configPatches:
      # The Envoy config you want to modify
   - applyTo: HTTP_FILTER
      match:
         context: SIDECAR_INBOUND
         proxy:
         proxyVersion: '^1\.9.*'
         listener:
         filterChain:
            filter:
               name: "envoy.filters.network.http_connection_manager"
               subFilter:
               name: "envoy.filters.http.router"
      patch:
         operation: INSERT_BEFORE
         value: # lua filter specification
         name: envoy.lua
         typed_config:
            "@type": "type.googleapis.com/envoy.extensions.filters.http.lua.v3.Lua"
            inlineCode: |-
               function envoy_on_response(response_handle)
                  function hasFrameAncestors(rh)
                  s = rh:headers():get("Content-Security-Policy");
                  delimiter = ";";
                  defined = false;
                  for match in (s..delimiter):gmatch("(.-)"..delimiter) do
                     match = match:gsub("%s+", "");
                     if match:sub(1, 15)=="frame-ancestors" then
                     return true;
                     end
                  end
                  return false;
                  end
                  if not response_handle:headers():get("Content-Security-Policy") then
                  csp = "frame-ancestors none;";
                  response_handle:headers():add("Content-Security-Policy", csp);
                  elseif response_handle:headers():get("Content-Security-Policy") then
                  if not hasFrameAncestors(response_handle) then
                     csp = response_handle:headers():get("Content-Security-Policy");
                     csp = csp .. ";frame-ancestors none;";
                     response_handle:headers():replace("Content-Security-Policy", csp);
                  end
                  end
                  if not response_handle:headers():get("X-Frame-Options") then
                  response_handle:headers():add("X-Frame-Options", "deny");
                  end
                  if not response_handle:headers():get("X-XSS-Protection") then
                  response_handle:headers():add("X-XSS-Protection", "1; mode=block");
                  end
                  if not response_handle:headers():get("X-Content-Type-Options") then
                  response_handle:headers():add("X-Content-Type-Options", "nosniff");
                  end
                  if not response_handle:headers():get("Referrer-Policy") then
                  response_handle:headers():add("Referrer-Policy", "no-referrer");
                  end
                  if not response_handle:headers():get("X-Download-Options") then
                  response_handle:headers():add("X-Download-Options", "noopen");
                  end
                  if not response_handle:headers():get("X-DNS-Prefetch-Control") then
                  response_handle:headers():add("X-DNS-Prefetch-Control", "off");
                  end
                  if not response_handle:headers():get("Feature-Policy") then
                  response_handle:headers():add("Feature-Policy",
                                                   "camera 'none';"..
                                                   "microphone 'none';"..
                                                   "geolocation 'none';"..
                                                   "encrypted-media 'none';"..
                                                   "payment 'none';"..
                                                   "speaker 'none';"..
                                                   "usb 'none';");
                  end
                  if response_handle:headers():get("X-Powered-By") then
                  response_handle:headers():remove("X-Powered-By");
                  end
               end

   ```

2. 验证。

   1）进入 sleep 服务容器内。

   ```sh
   $ kubectl exec -it $(kubectl get pod -n samples -l app=sleep -o jsonpath='{.items[0].metadata.name}') -c sleep  -n samples sh
   ```

   2）调用 `/hello` 接口。接口响应头中包含额外添加的响应头，则说明创建的 EnvoyFilter 生效。

   ```sh
   $ curl -i helloworld:5000/hello
    HTTP/1.1 200 OK
    content-type: text/html; charset=utf-8
    content-length: 60
    server: envoy
    date: Wed, 03 Aug 2022 08:06:59 GMT
    x-envoy-upstream-service-time: 163
    content-security-policy: frame-ancestors none;
    x-frame-options: deny
    x-xss-protection: 1; mode=block
    x-content-type-options: nosniff
    referrer-policy: no-referrer
    x-download-options: noopen
    x-dns-prefetch-control: off
    feature-policy: camera 'none';microphone 'none';geolocation 'none';encrypted-media 'none';payment 'none';speaker 'none';usb 'none';
   
    Hello version: v1, instance: helloworld-v1-6874cd9dcd-ddnrh
   
   ```

#### 2.2.2 istio-ingress

ingress 上生效。

1. 创建 Envoyfilter。

   `kubectl apply -f samples/envoyfilter/ef-add-response-headers-into-ingressgateway.yaml -n istio-system`

   ```yaml
   apiVersion: networking.istio.io/v1alpha3
   kind: EnvoyFilter
   metadata:
      name: ef-add-response-headers-into-ingressgateway
   spec:
   workloadSelector:
      # select by label in the same namespace
      labels:
         istio: ingressgateway
   configPatches:
      # The Envoy config you want to modify
   - applyTo: HTTP_FILTER
      match:
         context: GATEWAY
         proxy:
         proxyVersion: '^1\.9.*'
         listener:
         filterChain:
            filter:
               name: "envoy.filters.network.http_connection_manager"
               subFilter:
               name: "envoy.filters.http.router"
      patch:
         operation: INSERT_BEFORE
         value: # lua filter specification
         name: envoy.lua
         typed_config:
            "@type": "type.googleapis.com/envoy.extensions.filters.http.lua.v3.Lua"
            inlineCode: |-
               function envoy_on_response(response_handle)
                  function hasFrameAncestors(rh)
                  s = rh:headers():get("Content-Security-Policy");
                  delimiter = ";";
                  defined = false;
                  for match in (s..delimiter):gmatch("(.-)"..delimiter) do
                     match = match:gsub("%s+", "");
                     if match:sub(1, 15)=="frame-ancestors" then
                     return true;
                     end
                  end
                  return false;
                  end
                  if not response_handle:headers():get("Content-Security-Policy") then
                  csp = "frame-ancestors none;";
                  response_handle:headers():add("Content-Security-Policy", csp);
                  elseif response_handle:headers():get("Content-Security-Policy") then
                  if not hasFrameAncestors(response_handle) then
                     csp = response_handle:headers():get("Content-Security-Policy");
                     csp = csp .. ";frame-ancestors none;";
                     response_handle:headers():replace("Content-Security-Policy", csp);
                  end
                  end
                  if not response_handle:headers():get("X-Frame-Options") then
                  response_handle:headers():add("X-Frame-Options", "deny");
                  end
                  if not response_handle:headers():get("X-XSS-Protection") then
                  response_handle:headers():add("X-XSS-Protection", "1; mode=block");
                  end
                  if not response_handle:headers():get("X-Content-Type-Options") then
                  response_handle:headers():add("X-Content-Type-Options", "nosniff");
                  end
                  if not response_handle:headers():get("Referrer-Policy") then
                  response_handle:headers():add("Referrer-Policy", "no-referrer");
                  end
                  if not response_handle:headers():get("X-Download-Options") then
                  response_handle:headers():add("X-Download-Options", "noopen");
                  end
                  if not response_handle:headers():get("X-DNS-Prefetch-Control") then
                  response_handle:headers():add("X-DNS-Prefetch-Control", "off");
                  end
                  if not response_handle:headers():get("Feature-Policy") then
                  response_handle:headers():add("Feature-Policy",
                                                   "camera 'none';"..
                                                   "microphone 'none';"..
                                                   "geolocation 'none';"..
                                                   "encrypted-media 'none';"..
                                                   "payment 'none';"..
                                                   "speaker 'none';"..
                                                   "usb 'none';");
                  end
                  if response_handle:headers():get("X-Powered-By") then
                  response_handle:headers():remove("X-Powered-By");
                  end
               end
   ```

2. 验证。

   1）确认 ingress 地址。

   ```sh
   $ kubectl cluster-info
    Kubernetes control plane is running at https://192.168.1.1:16443
   
    To further debug and diagnose cluster problems, use 'kubectl cluster-info dump'.
   
   $ kubectl get svc -n istio-system 
    NAME                   TYPE           CLUSTER-IP       EXTERNAL-IP   PORT(S)                                                                      AGE
    istio-egressgateway    ClusterIP      10.111.176.85    <none>        80/TCP,443/TCP,15443/TCP                                                     5d4h
    istio-ingressgateway   LoadBalancer   10.101.141.144   <pending>     15021:31873/TCP,80:31064/TCP,443:30191/TCP,31400:30943/TCP,15443:31029/TCP   5d4h
    istiod                 ClusterIP      10.105.147.56    <none>        15010/TCP,15012/TCP,443/TCP,15014/TCP                                        5d4h
    
   ```

   从上述结果中得知，ingress 地址为 http://192.168.1.1:31064。

   2）通过 ingress 访问 hello 接口。接口响应头中包含额外添加的响应头，则说明创建的 EnvoyFilter 生效。

   ```sh
   $ curl -i http://192.168.1.1:31064/hello
    HTTP/1.1 200 OK
    content-type: text/html; charset=utf-8
    content-length: 60
    server: istio-envoy
    date: Wed, 03 Aug 2022 07:43:03 GMT
    x-envoy-upstream-service-time: 159
    content-security-policy: frame-ancestors none;
    x-frame-options: deny
    x-xss-protection: 1; mode=block
    x-content-type-options: nosniff
    referrer-policy: no-referrer
    x-download-options: noopen
    x-dns-prefetch-control: off
    feature-policy: camera 'none';microphone 'none';geolocation 'none';encrypted-media 'none';payment 'none';speaker 'none';usb 'none';
   
    Hello version: v1, instance: helloworld-v1-6874cd9dcd-ddnrh
   
   ```

### 2.3 添加直接响应

对于发往指定服务的指定路径的http请求，不再向服务转发请求，而是立即返回固定的响应内容。

1. 创建EnvoyFilter。

   `kubectl apply -f samples/envoyfilter/ef-envoy-direct-response.yaml -n samples`

   ```yaml
   apiVersion: networking.istio.io/v1alpha3
   kind: EnvoyFilter
   metadata:
      name: ef-envoy-direct-response.yaml
   spec:
   workloadSelector:
      labels:
         app: helloworld
   configPatches:
   - applyTo: NETWORK_FILTER
      match:
         context: SIDECAR_INBOUND
         listener:
         filterChain:
            filter:
               name: "envoy.filters.network.http_connection_manager"
      patch:
         operation: REPLACE
         value:
         name: envoy.filters.network.http_connection_manager
         typed_config:
            "@type": type.googleapis.com/envoy.extensions.filters.network.http_connection_manager.v3.HttpConnectionManager
            stat_prefix: hello
            route_config:
               name: my_first_route
               virtual_hosts:
               - name: direct_response_service
               domains: ["helloworld.samples"]
               routes:
               - match:
                     prefix: "/"
                  direct_response:
                     status: 200
                     body:
                     inline_string: "envoy direct response."
            http_filters:
            - name: envoy.filters.http.router
               typed_config:
               "@type": type.googleapis.com/envoy.extensions.filters.http.router.v3.Router
   ```

2. 验证。

   1）进入 sleep 服务容器内。

   ```sh
   $ kubectl exec -it $(kubectl get pod -n samples -l app=sleep -o jsonpath='{.items[0].metadata.name}') -c sleep  -n samples sh
   ```

   2）调用 `/hello` 接口。返回结果为 envoy direct response，则说明创建的 EnvoyFilter 生效。

   ```sh
   $ curl -i http://192.168.1.1:31064/hello
    HTTP/1.1 200 OK
    content-type: text/html; charset=utf-8
    content-length: 60
    server: istio-envoy
    date: Wed, 03 Aug 2022 07:43:03 GMT
    x-envoy-upstream-service-time: 3
   
    envoy direct response.
   ```

## 参考

1. [Envoy Filter](https://istio.io/latest/zh/docs/reference/config/networking/envoy-filter/)
2. [在ASM中通过EnvoyFilter添加HTTP响应头](https://help.aliyun.com/document_detail/158520.html)