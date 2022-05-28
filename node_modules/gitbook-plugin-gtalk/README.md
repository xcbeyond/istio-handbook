# gitbook-plugin-gtalk

![](https://img.shields.io/npm/dt/gitbook-plugin-gtalk.svg)

GitBook Plugin. A modern comment component based on GitHub Issue and Preact.

## Usage

Add it to your `book.json`:

```json
{
  "plugins": ["gtalk"],
  "pluginsConfig": {
    "gtalk": {
      "clientID": "GitHub Application Client ID",
      "clientSecret": "GitHub Application Client Secret",
      "repo": "GitHub repo",
      "owner": "GitHub repo owner",
      "admin": ["GitHub repo owner and collaborators, only these guys can initialize github issues"]
    }
  }
}
```

Get more information about [options](https://www.npmjs.com/package/gitalk).
