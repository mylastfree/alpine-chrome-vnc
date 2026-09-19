# alpine-chrome-vnc

[![Build and Publish](https://github.com/mylastfree/alpine-chrome-vnc/actions/workflows/build.yml/badge.svg)](https://github.com/mylastfree/alpine-chrome-vnc/actions/workflows/build.yml)
[![GHCR](https://img.shields.io/badge/ghcr.io-alpine--chrome--vnc-2496ED?logo=docker&logoColor=white)](https://github.com/mylastfree/alpine-chrome-vnc/pkgs/container/alpine-chrome-vnc)
[![Image Size](https://img.shields.io/badge/image%20size-1.2%20GB-blue)](https://github.com/mylastfree/alpine-chrome-vnc/pkgs/container/alpine-chrome-vnc)
[![Base](https://img.shields.io/badge/base-alpine%203.23-0D597F?logo=alpinelinux&logoColor=white)](https://alpinelinux.org/)
[![Chromium](https://img.shields.io/badge/chromium-149-4285F4?logo=googlechrome&logoColor=white)](https://www.chromium.org/)
[![License](https://img.shields.io/badge/license-MIT-green.svg)](LICENSE)

基于 Alpine Linux 的极简远程 Chromium 容器，专为小内存 VPS（1核1G）优化。

浏览器打开 noVNC 页面即可使用完整 Chromium，支持中日韩字体与**双向剪贴板同步**。

## 为什么做这个

主流远程浏览器镜像的框架开销太大，在小 VPS 上很吃力：

| 镜像 | 大小 | 运行时内存 | 框架开销 |
|---|---|---|---|
| `linuxserver/chrome` | 3.21 GB | 367 MB | python3 (Selkies/WebRTC) 168 MB + labwc 100 MB |
| `kasmweb/chrome` | 1.36 GB | 很大 | 完整 Kasm 工作区 |
| **本项目** | **1.2 GB** | **~235 MB** | websockify 7.3 MB + x11vnc 5.6 MB |

Chromium 本身只占约 100 MB，其余全是远程桌面框架的开销。
本项目用 **X11 + x11vnc + noVNC** 替换掉 Selkies/WebRTC + Wayland。

结果：**镜像小 63%**，**内存省 36%**，功能完全一样。

## 特性

- **Alpine 3.23** 基础镜像（8.4 MB），成品 1.2 GB
- **Chromium 149**（Alpine musl 构建）
- **中文字体** — Noto CJK 共 30 个字体，界面语言 `--lang=zh-CN`
- **双向剪贴板** — `autocutsel` 同步 X11 CLIPBOARD ↔ PRIMARY，经 noVNC 可用
- **无需客户端** — 浏览器直接打开 `http://<主机>:6080/vnc.html`
- **低端设备模式** — `--enable-low-end-device-mode` 进一步降低内存
- **supervisord 管理** — 7 个进程，失败自动重启

## 从镜像仓库拉取

每次推送到 `main` 都会自动构建并发布到 GHCR：

```bash
docker pull ghcr.io/mylastfree/alpine-chrome-vnc:latest

docker run -d --name chrome-lite \
  --restart unless-stopped \
  -e TZ=Asia/Shanghai \
  -e VNC_PASSWORD=change-me-please \
  -e START_URL=https://example.com \
  -p 6080:6080 \
  -v "$PWD/config:/root/.config" \
  --shm-size=256m --memory=600m --memory-swap=1000m \
  ghcr.io/mylastfree/alpine-chrome-vnc:latest
```

打 tag（`v*`）时还会额外发布 `:<version>` 和 `:<major>.<minor>` 标签。

### Docker Hub（可选）

`publish-dockerhub` 这个 job 默认关闭。要启用：添加仓库 secrets
`DOCKERHUB_USERNAME` + `DOCKERHUB_TOKEN`，并把仓库变量 `DOCKERHUB_ENABLED`
设为 `true`（Settings → Secrets and variables → Actions）。
## 快速开始

### docker-compose（推荐）

```yaml
services:
  chrome:
    build: .
    image: chrome-alpine:latest
    container_name: chrome-lite
    restart: unless-stopped
    environment:
      TZ: Asia/Shanghai
      SCREEN_WIDTH: "1600"
      SCREEN_HEIGHT: "900"
      VNC_PASSWORD: change-me-please
      START_URL: https://example.com
    ports:
      - "6080:6080"
    volumes:
      - ./config:/root/.config
    shm_size: 256m
    mem_limit: 600m
    memswap_limit: 1000m
```

```bash
docker compose up -d --build
```

### docker run

```bash
docker build -t chrome-alpine .

docker run -d --name chrome-lite \
  --restart unless-stopped \
  -e TZ=Asia/Shanghai \
  -e SCREEN_WIDTH=1600 -e SCREEN_HEIGHT=900 \
  -e VNC_PASSWORD=change-me-please \
  -e START_URL=https://example.com \
  -p 6080:6080 \
  -v "$PWD/config:/root/.config" \
  --shm-size=256m \
  --memory=600m --memory-swap=1000m \
  chrome-alpine
```

然后打开 **`http://<你的主机>:6080/vnc.html`**，输入 `VNC_PASSWORD`。

## 配置项

| 环境变量 | 默认值 | 说明 |
|---|---|---|
| `SCREEN_WIDTH` | `1600` | 虚拟显示宽度 |
| `SCREEN_HEIGHT` | `900` | 虚拟显示高度 |
| `SCREEN_DEPTH` | `24` | 色深 |
| `VNC_PASSWORD` | *(无)* | VNC 密码。**务必设置** |
| `START_URL` | `https://adsense.google.com` | 启动时打开的页面 |
| `TZ` | `America/New_York` | 容器时区 |

## 实测数据

测试环境：1核1G KVM VPS（AMD EPYC-Milan），Chromium 149

| 指标 | 数值 |
|---|---|
| 容器内存（空白页） | 303 MB |
| 容器内存（重度 SPA） | 235–335 MB |
| 镜像大小 | 1.2 GB |
| noVNC 可访问 | HTTP 200 |
| 剪贴板往返 | 已验证（`xclip` 写入后能读回） |

### CPU 取决于你访问的页面，与本容器无关

| 页面 | 容器 CPU |
|---|---|
| `about:blank` | **0.26%** |
| `https://www.example.com` | **0.20%** |
| `https://adsense.google.com` | **14%** |

本容器里的 Chromium 空闲时 CPU 远低于 1%。重度 SPA（分析后台、广告控制台）
的 CPU 是页面自己吃掉的，任何容器镜像都避免不了。

**建议**：不用时执行 `docker stop chrome-lite`，内存直接归零、CPU 归零。

## 架构

```
Alpine 3.23
└─ supervisord
   ├─ Xvfb            虚拟 X 显示（SCREEN_WIDTH x SCREEN_HEIGHT x 24）
   ├─ openbox         极简窗口管理器
   ├─ autocutsel x2   同步 CLIPBOARD ↔ PRIMARY  →  双向剪贴板
   ├─ x11vnc          VNC 服务，监听 :5900
   ├─ websockify      noVNC Web 桥接，监听 :6080
   └─ chromium        浏览器本体
```

## 安全

**默认没有 TLS**，noVNC 走明文 HTTP。除可信内网外，请任选一种加固方式：

1. **SSH 隧道**（最简单，不暴露端口）：
   ```bash
   ssh -N -L 6080:127.0.0.1:6080 user@host
   # 然后浏览器打开 http://localhost:6080/vnc.html
   ```
   同时把端口映射改成 `-p 127.0.0.1:6080:6080`，端口就不出主机。

2. **反向代理加 TLS** — 前面挂 Caddy/nginx 终止 HTTPS。

3. **Cloudflare Tunnel** — 用 `cloudflared` 暴露并配合 Access 策略。

另外：**公网接口上绝不能不设 `VNC_PASSWORD`**。

## 注意事项

- 容器内必须用 `--no-sandbox`（没有 user namespace）。只访问可信内容，或自行加 seccomp。
- Chromium 会输出无害的 `dbus` / `gcm` 报错 —— 容器里没有 D-Bus。
- Chromium 配置目录在 `/root/.config/chromium`（挂载出来可保留登录态）。
  `start.sh` 启动时会清理残留的 `Singleton*` 锁文件，否则容器重建后会卡在
  「profile appears to be in use」无法启动。

## 许可证

MIT