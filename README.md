# rpc
в config.toml
```
[rpc]
laddr = "tcp://127.0.0.1:26657"
cors_allowed_origins = []
```
(чтобы был пустой массив cors_allowed_origins)
проверить можно в браузере, ip + соотв порт

# grpc и grpc-web
в app.toml
```
[grpc]
enable = false
address = "0.0.0.0:9090"
[grpc-web]
enable = false
address = "0.0.0.0:9091"
```
grpc можно проверить в postman
grpc-web в браузере, ip + соотв порт


# json-rpc
для evm совместимых, везде где есть 18 нулей
```[json-rpc]
enable = false
address = "0.0.0.0:10545"
ws-address = "0.0.0.0:8546"
```
в app.toml
проверить можно в браузере, ip + соотв порт

# lcd = api = rest
в app.toml
```
[api]
enable = false
swagger = false
address = "tcp://0.0.0.0:1317"
```
