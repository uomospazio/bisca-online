/* Browser audio transport. No microphone access until start() is requested. */
(() => {
  class BiscaVoiceTransport {
    constructor() {
      this.peers = new Map(); this.people = new Map(); this.volumes = new Map();
      this.events = []; this.enabled = false; this.muted = false; this.master = 1;
      this.room = ''; this.me = ''; this.epoch = ''; this.generation = 0;
      this.iceServers = [{urls:'stun:stun.l.google.com:19302'}];
      this.unlock = () => {
        if (this.context?.state === 'suspended' || this.context?.state === 'interrupted')
          this.context.resume().catch(() => this.status('Tocca ATTIVA AUDIO per riprendere l’ascolto.'));
        for (const p of this.peers.values()) p.audio?.play().catch(() => {});
      };
      document.addEventListener('pointerdown', this.unlock);
      document.addEventListener('keydown', this.unlock);
      window.addEventListener('pagehide', () => this.stop());
    }
    event(value) { if (this.events.length < 256) this.events.push(value); }
    drain() { return JSON.stringify(this.events.splice(0)); }
    status(text) { this.event({op:'status',text,enabled:this.enabled,muted:this.muted,pending:!!this.starting}); }
    configure(servers) { if (Array.isArray(servers) && servers.length) this.iceServers = servers; }
    send(id, data) {
      const person = this.people.get(id);
      if (person) this.event({op:'signal',slot:person.slot,data:{...data,room:this.room,from_id:this.me,to_id:id,epoch:this.epoch}});
    }
    update(room, me, list) {
      if (room !== this.room || me !== this.me) { this.stop(); this.volumes.clear(); }
      this.room = room; this.me = me;
      this.people = new Map(list.filter(p=>p.id !== me && !p.bot && p.connected).map(p=>[p.id,p]));
      for (const id of this.peers.keys()) if (!this.people.has(id)) this.closePeer(id);
      if (this.enabled) for (const id of this.people.keys()) if (!this.peers.has(id)) this.send(id,{type:'ready'});
    }
    async start() {
      if (this.enabled) {
        this.unlock();
        for (const [id,p] of this.peers) if (['failed','disconnected'].includes(p.pc.connectionState)) {
          if (this.me < id) this.offer(id,p,true); else this.send(id,{type:'retry'});
        }
        for (const id of this.people.keys()) if (!this.peers.has(id)) this.send(id,{type:'ready'});
        return;
      }
      if (this.starting) return;
      if (!window.isSecureContext || !navigator.mediaDevices?.getUserMedia || !window.RTCPeerConnection) {
        this.status('Chat vocale: apri il gioco in un browser aggiornato tramite HTTPS.'); return;
      }
      if (!this.room) { this.status('Entra prima in una lobby multiplayer.'); return; }
      const generation = ++this.generation;
      this.starting = true;
      this.status('Consenti l’accesso al microfono nel browser.');
      try {
        this.context = new (window.AudioContext || window.webkitAudioContext)({latencyHint:'interactive'});
        this.context.resume().catch(()=>{});
        const stream = await navigator.mediaDevices.getUserMedia({video:false,audio:{echoCancellation:true,noiseSuppression:true,autoGainControl:true}});
        if (generation !== this.generation) { stream.getTracks().forEach(t=>t.stop()); return; }
        this.stream = stream; this.enabled = true; this.muted = false;
        this.epoch = crypto.randomUUID();
        stream.getAudioTracks()[0].onended = () => { if (this.enabled) { this.stop(); this.status('Microfono scollegato. Premi ATTIVA AUDIO per riprovare.'); } };
        for (const id of this.people.keys()) this.send(id,{type:'ready'});
        this.starting=false;
        this.status('Chat attiva. Anche gli altri giocatori devono attivarla.');
      } catch (error) {
        if (generation !== this.generation) return;
        this.stop();
        this.status(error.name === 'NotAllowedError' ? 'Microfono negato: abilitalo nei permessi del sito e riprova.' : 'Microfono non disponibile: controlla il dispositivo e riprova.');
      } finally { if (generation === this.generation) this.starting = false; }
    }
    setMuted(muted) {
      this.muted = !!muted;
      this.stream?.getAudioTracks().forEach(t=>{t.enabled=!this.muted;});
      this.status(this.muted ? 'Microfono spento. Puoi ancora ascoltare gli altri.' : 'Chat vocale attiva.');
    }
    setVolume(id, value) { this.volumes.set(id,Math.max(0,Math.min(1,value))); this.applyVolume(id); }
    setMaster(value) { this.master=Math.max(0,Math.min(1,value)); for(const id of this.peers.keys()) this.applyVolume(id); }
    applyVolume(id) {
      const p=this.peers.get(id);
      // GainNode is intentional: HTMLMediaElement.volume is restricted on iOS.
      if(p?.gain) p.gain.gain.setTargetAtTime((this.volumes.get(id) ?? 1)*this.master,this.context.currentTime,0.015);
    }
    closePeer(id) {
      const p=this.peers.get(id); if(!p) return;
      this.peers.delete(id); clearTimeout(p.retry);
      p.pc.onconnectionstatechange=null; p.pc.onicecandidate=null; p.pc.ontrack=null;
      p.pc.close(); p.source?.disconnect(); p.gain?.disconnect();
      if(p.audio) {p.audio.pause();p.audio.srcObject=null;p.audio.remove();}
    }
    stop() {
      for(const id of this.peers.keys()) this.send(id,{type:'off'});
      ++this.generation; this.starting=false; this.enabled=false;
      for(const id of [...this.peers.keys()]) this.closePeer(id);
      this.stream?.getTracks().forEach(t=>{t.onended=null;t.stop();});this.stream=null;
      this.context?.close().catch(()=>{});this.context=null;
      this.status('Chat vocale disattivata.');
    }
    makePeer(id, epoch) {
      const pc=new RTCPeerConnection({iceServers:this.iceServers});
      const p={pc,epoch,queue:Promise.resolve(),candidates:[],restarts:0};
      this.peers.set(id,p);
      this.stream.getAudioTracks().forEach(track=>pc.addTrack(track,this.stream));
      pc.onicecandidate=e=>{if(e.candidate && this.peers.get(id)===p) this.send(id,{type:'candidate',candidate:e.candidate.toJSON()});};
      pc.ontrack=e=>{
        if(this.peers.get(id)!==p || !this.context || p.source) return;
        const stream=e.streams[0] || new MediaStream([e.track]);
        // Keep a muted playing element for Safari's remote MediaStream lifecycle.
        p.audio=document.createElement('audio');p.audio.autoplay=true;p.audio.muted=true;
        p.audio.setAttribute('playsinline','');p.audio.srcObject=stream;document.body.appendChild(p.audio);
        p.audio.play().catch(()=>{});
        p.source=this.context.createMediaStreamSource(stream);p.gain=this.context.createGain();
        p.source.connect(p.gain).connect(this.context.destination);this.applyVolume(id);
        this.unlock();
      };
      pc.onconnectionstatechange=()=>{
        if(this.peers.get(id)!==p) return;
        if(pc.connectionState==='connected') {clearTimeout(p.retry);p.restarts=0;this.status('Chat vocale connessa.');}
        if(['disconnected','failed'].includes(pc.connectionState)) {
          clearTimeout(p.retry);
          p.retry=setTimeout(()=>{
            if(this.peers.get(id)!==p || pc.connectionState==='connected') return;
            if(p.restarts++ < 2 && this.me < id) this.offer(id,p,true);
            else this.status('Voce non connessa: riprova ATTIVA AUDIO. Questa rete potrebbe richiedere un server TURN.');
          },3000);
        }
      };
      return p;
    }
    async offer(id,p,restart=false) {
      try {
        const description=await p.pc.createOffer({iceRestart:restart});
        if(this.peers.get(id)!==p) return;
        await p.pc.setLocalDescription(description);
        if (this.peers.get(id)===p) this.send(id,{type:'description',description:{type:p.pc.localDescription.type,sdp:p.pc.localDescription.sdp}});
      } catch (_) { if(this.peers.get(id)===p) this.status('Connessione vocale non riuscita. Disattiva e riattiva la chat.'); }
    }
    receive(data) {
      if(!this.enabled || data.room!==this.room || data.to_id!==this.me || !this.people.has(data.from_id)) return;
      const id=data.from_id;
      let p=this.peers.get(id);
      if(data.type==='off') {if(p?.epoch===data.epoch)this.closePeer(id);return;}
      if(data.type==='ready') {
        if(p?.epoch===data.epoch) return;
        this.closePeer(id);p=this.makePeer(id,data.epoch);
        this.send(id,{type:'ready'});
        if(this.me<id) this.offer(id,p);
        return;
      }
      if(!p || p.epoch!==data.epoch) return;
      if(data.type==='retry') {if(this.me<id)this.offer(id,p,true);return;}
      p.queue=p.queue.then(async()=>{
        if(this.peers.get(id)!==p) return;
        if(data.type==='description') {
          await p.pc.setRemoteDescription(data.description);
          for(const candidate of p.candidates.splice(0)) await p.pc.addIceCandidate(candidate);
          if(data.description.type==='offer') {
            await p.pc.setLocalDescription(await p.pc.createAnswer());
            if(this.peers.get(id)===p) this.send(id,{type:'description',description:{type:p.pc.localDescription.type,sdp:p.pc.localDescription.sdp}});
          }
        } else if(data.type==='candidate') {
          if(p.pc.remoteDescription) await p.pc.addIceCandidate(data.candidate);
          else if(p.candidates.length<64) p.candidates.push(data.candidate);
        }
      }).catch(()=>{if(this.peers.get(id)===p)this.status('Errore di connessione vocale. Disattiva e riattiva la chat.');});
    }
  }
  window.BiscaVoice = new BiscaVoiceTransport();
})();
