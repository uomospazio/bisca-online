(() => {
  if (window.BiscaMicTest) return;
  window.BiscaMicTest = {
    level: 0, failed: false, generation: 0,
    async start() {
      this.stop(); this.failed = false;
      const generation = this.generation;
      try {
        const stream = await navigator.mediaDevices.getUserMedia({audio: true, video: false});
        if (generation !== this.generation) { stream.getTracks().forEach(t => t.stop()); return; }
        this.stream = stream;
        this.context = new (window.AudioContext || window.webkitAudioContext)();
        await this.context.resume();
        if (generation !== this.generation) return;
        const source = this.context.createMediaStreamSource(stream);
        const analyser = this.context.createAnalyser();
        source.connect(analyser);
        const data = new Float32Array(analyser.fftSize);
        this.timer = setInterval(() => {
          analyser.getFloatTimeDomainData(data);
          this.level = Math.min(1, Math.max(...data.map(Math.abs)) * 4);
        }, 50);
      } catch (_) { if (generation === this.generation) { this.stop(); this.failed = true; } }
    },
    stop() {
      ++this.generation;
      clearInterval(this.timer);
      this.stream?.getTracks().forEach(t => t.stop()); this.stream = null;
      this.context?.close().catch(() => {}); this.context = null;
      this.level = 0;
    }
  };
  window.addEventListener('pagehide', () => window.BiscaMicTest.stop());
  document.addEventListener('visibilitychange', () => { if (document.hidden) window.BiscaMicTest.stop(); });
})();
