#!/bin/sh
set -e

# 时区
[ -n "$TZ" ] && ln -sf /usr/share/zoneinfo/$TZ /etc/localtime 2>/dev/null || true

# 默认启动页
export START_URL="${START_URL:-https://adsense.google.com}"

# 清理上次残留的 Chromium profile 锁（容器重建后 hostname 变化会导致锁失效）
rm -f /root/.config/chromium/Singleton* 2>/dev/null || true
rm -f /root/.config/chromium/Default/Singleton* 2>/dev/null || true

# VNC 密码支持
if [ -n "$VNC_PASSWORD" ]; then
    x11vnc -storepasswd "$VNC_PASSWORD" /tmp/.vncpass >/dev/null 2>&1
    sed -i "s|-nopw|-rfbauth /tmp/.vncpass|" /etc/supervisor/conf.d/supervisord.conf
fi

echo "=========================================="
echo " Alpine Chrome (lite)"
echo "  分辨率: ${SCREEN_WIDTH}x${SCREEN_HEIGHT}x${SCREEN_DEPTH}"
echo "  noVNC : http://<IP>:6080/vnc.html"
echo "  起始页: ${START_URL}"
echo "=========================================="

exec /usr/bin/supervisord -c /etc/supervisor/conf.d/supervisord.conf
