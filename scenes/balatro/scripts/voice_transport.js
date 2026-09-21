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
    status(text) { this.message=text; this.refreshPanel(); this.event({op:'status',text,enabled:this.enabled,muted:this.muted,pending:!!this.starting}); }
    openPanel() {
      this.closePanel();
      const root=document.createElement('div');this.panel=root;
      root.style.cssText='position:fixed;inset:0;z-index:2147483647;background:#14213daa;display:grid;place-items:center;padding:12px;box-sizing:border-box';
      root.innerHTML=`<section role="dialog" aria-modal="true" aria-label="Chat vocale" style="box-sizing:border-box;width:min(480px,100%);max-height:90dvh;overflow:auto;background:#48465f;color:#fde4b9;border:3px solid #74ab8e;border-radius:22px;padding:22px;font:600 16px system-ui"><h2 style="margin-top:0">CHAT VOCALE</h2><p>Premi ATTIVA MICROFONO e consenti l'accesso nel browser. Anche i tuoi amici devono attivarla.</p><p data-status role="status"></p><div data-actions style="display:flex;gap:10px;flex-wrap:wrap"></div><div data-people></div><p style="font-size:13px">La partita continua mentre questo pannello e' aperto. Chiudere il pannello non spegne il microfono.</p></section>`;
      const actions=root.querySelector('[data-actions]');
      const button=(text,action)=>{const b=document.createElement('button');b.textContent=text;b.style.cssText='border:2px solid #fde4b9;border-radius:14px;padding:12px;background:#74ab8e;color:#14213d;font:bold 15px system-ui;cursor:pointer';b.onclick=action;actions.appendChild(b);return b;};
      // A real DOM click keeps microphone permission and AudioContext activation
      // in the browser's user gesture, rather than a later Godot frame.
      this.startButton=button('ATTIVA MICROFONO',()=>this.start());
      this.muteButton=button('SILENZIA MICROFONO',()=>this.setMuted(!this.muted));
      this.stopButton=button('DISATTIVA CHAT',()=>this.stop());
      button('CHIUDI',()=>this.closePanel());
      root.addEventListener('keydown',e=>{e.stopPropagation();if(e.key==='Escape')this.closePanel();if(e.key==='Tab'){const items=[...root.querySelectorAll('button:not(:disabled),input')];const first=items[0],last=items.at(-1);if(e.shiftKey&&document.activeElement===first){e.preventDefault();last.focus();}else if(!e.shiftKey&&document.activeElement===last){e.preventDefault();first.focus();}}});
      for(const type of ['pointerdown','pointerup','click'])root.addEventListener(type,e=>e.stopPropagation());
      document.body.appendChild(root);this.refreshPanel();this.startButton.focus();
    }
    closePanel() {this.panel?.remove();this.panel=null;document.querySelector('canvas')?.focus();}
    refreshPanel() {
      if(!this.panel)return;
      this.panel.querySelector('[data-status]').textContent=!this.me ? 'Chat disponibile in una lobby multiplayer. Se sei gia\' in partita, aggiorna anche il server.' : (this.message || 'Chat vocale disattivata.');
      this.startButton.disabled=!!this.starting || !this.me;
      this.startButton.textContent=this.starting ? 'ATTENDO IL PERMESSO…' : this.enabled ? 'RICONNETTI AUDIO' : 'ATTIVA MICROFONO';
      this.muteButton.disabled=!this.enabled;this.muteButton.textContent=this.muted?'RIATTIVA MICROFONO':'SILENZIA MICROFONO';
      this.stopButton.disabled=!this.enabled&&!this.starting;
      const list=this.panel.querySelector('[data-people]');
      const signature=JSON.stringify([...this.people].map(([id,p])=>[id,p.name,this.peers.get(id)?.pc.connectionState||'off']));
      if(list.dataset.signature===signature)return;
      list.dataset.signature=signature;list.replaceChildren();
      for(const [id,person] of this.people){
        const row=document.createElement('label');row.style.cssText='display:block;margin:16px 0';
        const state=this.peers.get(id)?.pc.connectionState;
        row.append(document.createTextNode(`${person.name || 'Giocatore'} — ${state==='connected'?'connesso':state==='failed'?'connessione fallita':state?'connessione…':'chat non attiva'}`));
        const slider=document.createElement('input');slider.type='range';slider.min='0';slider.max='100';slider.value=String((this.volumes.get(id)??1)*100);slider.style.cssText='display:block;width:100%;accent-color:#74ab8e';slider.setAttribute('aria-label',`Volume ${person.name || 'giocatore'}`);
        slider.oninput=()=>{this.setVolume(id,Number(slider.value)/100);this.event({op:'volume',id,value:Number(slider.value)});};row.appendChild(slider);list.appendChild(row);
      }
    }
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
      this.refreshPanel();
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
      if (!this.room || !this.me) { this.status('Entra prima in una lobby multiplayer con un server aggiornato.'); return; }
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
        this.heartbeat=setInterval(()=>{for(const id of this.people.keys())if(!this.peers.has(id))this.send(id,{type:'ready'});},3000);
        this.status('Chat attiva. Anche gli altri giocatori devono attivarla.');
      } catch (error) {
        if (generation !== this.generation) return;
        this.stop();
        this.status(error.name === 'NotAllowedError' ? 'Microfono negato: abilitalo nei permessi del sito e riprova.' : error.name === 'NotFoundError' ? 'Nessun microfono trovato: collega un microfono e riprova.' : error.name === 'NotReadableError' ? 'Microfono occupato o bloccato dal sistema: chiudi le altre app audio e riprova.' : 'Microfono non disponibile: controlla il dispositivo e riprova.');
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
      this.peers.delete(id); clearTimeout(p.retry);clearTimeout(p.watchdog);
      p.pc.onconnectionstatechange=null; p.pc.onicecandidate=null; p.pc.ontrack=null;
      p.pc.close(); p.source?.disconnect(); p.gain?.disconnect();
      if(p.audio) {p.audio.pause();p.audio.srcObject=null;p.audio.remove();}
      this.refreshPanel();
    }
    stop() {
      for(const id of this.peers.keys()) this.send(id,{type:'off'});
      ++this.generation; this.starting=false; this.enabled=false;this.muted=false;clearInterval(this.heartbeat);
      for(const id of [...this.peers.keys()]) this.closePeer(id);
      this.stream?.getTracks().forEach(t=>{t.onended=null;t.stop();});this.stream=null;
      this.context?.close().catch(()=>{});this.context=null;
      this.status('Chat vocale disattivata.');
    }
    makePeer(id, epoch) {
      const pc=new RTCPeerConnection({iceServers:this.iceServers});
      const p={pc,epoch,queue:Promise.resolve(),candidates:[],restarts:0};
      this.peers.set(id,p);
      p.watchdog=setTimeout(()=>{
        if(this.peers.get(id)===p && pc.connectionState!=='connected')
          this.status('Connessione audio non completata. Premi RICONNETTI AUDIO. Se persiste su reti diverse, potrebbe servire un server TURN.');
      },15000);
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
        this.refreshPanel();
        if(pc.connectionState==='connected') {clearTimeout(p.retry);clearTimeout(p.watchdog);p.restarts=0;this.status('Chat vocale connessa.');}
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
