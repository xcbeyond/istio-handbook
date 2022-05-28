## gitbook-plugin-gitalks

- 之前一直用那个最高下载的,但是我拉他的插件总是报错..

```
info: installing plugin "mygitalk"
info: install plugin "mygitalk" (*) from NPM with version 0.2.6
fetchMetadata → network   ▄ ╢██████████████████████████████████████████████████████████████████████░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░╟
/Users/xzghua/.gitbook/versions/3.2.3/node_modules/npm/node_modules/aproba/index.js:25
    if (args[ii] == null) throw missingRequiredArg(ii)
                          ^

Error: Missing required argument #1
    at andLogAndFinish (/Users/xzghua/.gitbook/versions/3.2.3/node_modules/npm/lib/fetch-package-metadata.js:31:3)
    at fetchPackageMetadata (/Users/xzghua/.gitbook/versions/3.2.3/node_modules/npm/lib/fetch-package-metadata.js:51:22)
    at resolveWithNewModule (/Users/xzghua/.gitbook/versions/3.2.3/node_modules/npm/lib/install/deps.js:490:12)
    at /Users/xzghua/.gitbook/versions/3.2.3/node_modules/npm/lib/install/deps.js:491:7
    at /Users/xzghua/.gitbook/versions/3.2.3/node_modules/npm/node_modules/iferr/index.js:13:50
    at /Users/xzghua/.gitbook/versions/3.2.3/node_modules/npm/lib/fetch-package-metadata.js:37:12
    at addRequestedAndFinish (/Users/xzghua/.gitbook/versions/3.2.3/node_modules/npm/lib/fetch-package-metadata.js:67:5)
    at returnAndAddMetadata (/Users/xzghua/.gitbook/versions/3.2.3/node_modules/npm/lib/fetch-package-metadata.js:121:7)
    at pickVersionFromRegistryDocument (/Users/xzghua/.gitbook/versions/3.2.3/node_modules/npm/lib/fetch-package-metadata.js:138:20)
    at /Users/xzghua/.gitbook/versions/3.2.3/node_modules/npm/node_modules/iferr/index.js:13:50 {
  code: 'EMISSINGARG'
}
```

- 这个错误我解决不了(搞不懂node的依赖关系).. 于是我copy了代码, 删掉不需要的,再发布到npm上

## 如侵,请联系我删除

用法是一样的,参数都是一样的

使用步骤

1. 在你的gitbook项目的`book.json`里的`plugins`里添加 `gitalks`,并添加`pluginsConfig`配置

```
"plugins": ["gitalks"]
 "pluginsConfig": {
     "gitalks": {
          "clientID": "xxxxxxx",
          "clientSecret": "xxxxxxxsssssssssssss",
          "repo": "your repo",
          "owner": "your name",
          "admin": ["you admin"],
          "distractionFreeMode": false
        },
 }
```

2. 执行 `gitbook install` 即可

> 至于clientID 和 clientSecret 参考 https://github.com/gitalk/gitalk/blob/master/readme-cn.md 

