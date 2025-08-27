## build

```
bundle exec rbwasm build -o app.wasm
```

## pack

```
bundle exec rbwasm pack ruby.wasm --dir ./src::/src -o app.wasm
```

## run

```
ruby -run -e httpd
```
