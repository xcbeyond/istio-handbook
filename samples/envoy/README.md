# envoy

## 事先准备

### 安装 func-e 工具

我们将使用一个名为 [func-e](https://func-e.io/) 的命令行工具。func-e 允许我们选择和使用不同的 Envoy 版本。

可以通过运行以下命令下载 func-e CLI。

```sh
curl https://func-e.io/install.sh | sudo bash -s -- -b /usr/local/bin
```

可以用我们创建的配置运行 Envoy：

```sh
func-e run -c envoy-direct-response.yaml
```
