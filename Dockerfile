FROM debian:bookworm-slim
RUN apt-get update && apt-get install -y --no-install-recommends \
    ca-certificates curl unzip nginx libfontconfig1 libx11-6 libxcursor1 \
    libxinerama1 libxi6 libxrandr2 libgl1 libasound2 libpulse0 \
    && rm -rf /var/lib/apt/lists/*
RUN curl -fL --retry 3 https://github.com/godotengine/godot-builds/releases/download/4.7.2-stable/Godot_v4.7.2-stable_linux.x86_64.zip -o /tmp/godot.zip \
    && echo 'cadd3204e728a35d3f13adb7fd0d7902636b79f6b95c40c265eb73b6c35329e4  /tmp/godot.zip' | sha256sum -c - \
    && unzip /tmp/godot.zip -d /usr/local/bin \
    && mv /usr/local/bin/Godot_v4.7.2-stable_linux.x86_64 /usr/local/bin/godot \
    && chmod +x /usr/local/bin/godot && rm /tmp/godot.zip
WORKDIR /app
COPY deployment/server/ ./
COPY scenes/balatro/scripts/network_session.gd scenes/balatro/scripts/match_rules.gd scenes/balatro/scripts/bot_policy.gd scenes/balatro/scripts/avatar_data.gd ./scenes/balatro/scripts/
COPY scenes/balatro/scripts/livekit_auth.gd ./scenes/balatro/scripts/
COPY deployment/nginx.conf ./nginx.conf
COPY deployment/start-server.sh ./start-server.sh
ENV GODOT_WS_PORT=8911
EXPOSE 10000
CMD ["bash", "/app/start-server.sh"]
