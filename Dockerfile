FROM alpine:3.23

# 一次性安装所有组件，减少层数
RUN apk add --no-cache \
        # 显示与 VNC
        xvfb x11vnc \
        # Web VNC 访问
        novnc websockify \
        # 剪贴板双向同步
        autocutsel xclip \
        # 极简窗口管理器
        openbox \
        # 浏览器
        chromium \
        # 中英文字体(只需 noto-cjk + dejavu, noto-extra 多占 168MB 且对中文无增益)
        font-noto-cjk font-dejavu \
        # 进程管理与其他
        supervisor bash tzdata \
    && rm -rf /var/cache/apk/* /tmp/*

# 创建运行时目录
RUN mkdir -p /var/log/supervisor /root/.config /tmp/.X11-unix \
    && chmod 1777 /tmp/.X11-unix

ENV DISPLAY=:0 \
    SCREEN_WIDTH=1600 \
    SCREEN_HEIGHT=900 \
    SCREEN_DEPTH=24 \
    TZ=America/New_York \
    LANG=en_US.UTF-8

COPY fonts.conf /etc/fonts/local.conf
COPY supervisord.conf /etc/supervisor/conf.d/supervisord.conf
COPY start.sh /start.sh
RUN chmod +x /start.sh

EXPOSE 6080
CMD ["/start.sh"]
