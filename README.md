# What is Bitrix Push Server

Push Server is a NodeJS app built by [Bitrix Inc.](https://www.bitrix24.com) to handle realtime communications within Bitrix 
platform. It is usually installed as part of [Bitrix Environment](https://www.bitrix24.com/self-hosted/installation.php).

# Use case for this Docker image

If you'd like to run Bitrix24 in Docker on your own making realtime comms, i.e. chat and video calls to work is tricky.
This image contains Bitrix Push Server from original Bitrix Environment package and can easily be placed into your existing project. 
The image is tested to work with *Docker Compose* and *Docker Swarm*.

# How to use the image

You have to start [Redis](https://hub.docker.com/_/redis/) first.

```console
$ docker run --name bitrix-push-server --link redis:redis -d ikarpovich/bitrix-push-server
```

## ... in [`Docker Swarm`](https://docs.docker.com/engine/reference/commandline/stack_deploy/) or via [`Docker Compose`](https://github.com/docker/compose)

```
  redis:
    image: redis:6.0.5-alpine3.12_1
    container_name: redis
    restart: always

  push-pub:
    image: bx-push-server:2.0_1
    container_name: push-pub
    environment:
      - MODE=pub
    depends_on:
      - redis
    restart: always

  push-sub:
    image: bx-push-server:2.0_1
    container_name: push-sub
    environment:
      - MODE=sub
    depends_on:
      - redis
    restart: always

networks:
  default:
    external:
      name: bx
```

## Настройки в административной панели Битрикс24:

- **Настройка адреса для публикации команд со стороны сервера**: 
    - Путь для публикации команд: http://push-pub:8010/bitrix/pub/ 
    - Код-подпись для взаимодействия с сервером: IMbEDEnTANDiSPATERSIVeRptUGht
- **Настройка адреса для публикации команд со стороны клиента**:
    - Путь для публикации команд (HTTP): http://push-pub:8010/bitrix/sub
    - Путь для чтения команд (HTTPS): https://push-pub:8010/bitrix/sub

# Environment variables

### `LISTEN_HOSTNAME`

Hostname to bind daemon to, `0.0.0.0` by default

### `LISTEN_PORT`

Port to bind daemon to, `80` by default

### `REDIS_HOST`

Redis hostname, `redis` by default

### `REDIS_PORT`

Redis port, `6379` by default

### `SECURITY_KEY`

Security key, has to match one in *Push & Pull* system module settings

### `MODE`

Mode should be either `pub` or `sub`. You have to launch two containers with each mode to work.

### `NGINX conf`
Для работы модуля Push&Pull в конфиге Nginx:
```
location /bitrix/pub/ {
    # IM doesn't wait
    proxy_ignore_client_abort on;
    proxy_pass http://push-pub:8010;
}

location ~* ^/bitrix/subws/ {
    access_log off;
    proxy_pass http://push-sub:8010;
    # http://blog.martinfjordvald.com/2013/02/websockets-in-nginx/
    # 12h+0.5
    proxy_max_temp_file_size 0;
    proxy_read_timeout  43800;
    proxy_http_version 1.1;
    proxy_set_header Upgrade $replace_upgrade;
    proxy_set_header Connection $connection_upgrade;
}

location ~* ^/bitrix/sub/ {
    access_log off;
    rewrite ^/bitrix/sub/(.*)$ /bitrix/subws/$1 break;
    proxy_pass http://push-sub:8010;
    proxy_max_temp_file_size 0;
    proxy_read_timeout  43800;
}

location ~* ^/bitrix/rest/ {
    access_log off;
    proxy_pass http://push-pub:8010;
    proxy_max_temp_file_size 0;
    proxy_read_timeout  43800;
}
```

# License

License for this image is MIT.
Bitrix and Bitrix Environment, Bitri Push Server are products licensed by Bitrix Inc. under their license terms.
