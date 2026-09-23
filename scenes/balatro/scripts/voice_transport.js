/* LiveKit browser voice. Credentials are issued by the authenticated game server. */
(() => {
  class BiscaVoiceTransport {
    constructor() {
      this.events=[];this.people=new Map();this.peers=new Map();this.volumes=new Map();
      this.room='';this.me='';this.master=1;this.enabled=false;this.muted=false;
      this.generation=0;this.requestId=0;
      this.unlock=()=>{
        this.context?.resume().catch(()=>{});
        this.session?.startAudio().catch(()=>this.status("Tocca il pannello per riprendere l'ascolto."));
      };
      document.addEventListener('pointerdown',this.unlock);
      document.addEventListener('keydown',this.unlock);
      window.addEventListener('pagehide',()=>this.stop());
    }
    event(value) {if(this.events.length<256)this.events.push(value);}
    drain() {return JSON.stringify(this.events.splice(0));}
    status(text) {
      this.message=text;this.refreshPanel();
      this.event({op:'status',text,enabled:this.enabled,muted:this.muted,pending:!!this.starting});
    }
    openPanel() {
      this.closePanel();
      const root=document.createElement('div');this.panel=root;
      root.style.cssText='position:fixed;inset:0;z-index:2147483647;background:#153536aa;display:grid;place-items:center;padding:12px;box-sizing:border-box';
      root.innerHTML=`<section role="dialog" aria-modal="true" aria-label="Chat vocale" style="box-sizing:border-box;width:min(480px,100%);max-height:90dvh;overflow:auto;background:#214f50;color:#fff0cc;border:3px solid #347667;border-radius:22px;padding:22px;font:600 16px system-ui"><h2 style="margin-top:0">CHAT VOCALE</h2><p>Premi ATTIVA AUDIO e consenti l'accesso nel browser. Anche i tuoi amici devono attivarla.</p><p data-status role="status"></p><div data-actions style="display:flex;gap:10px;flex-wrap:wrap"></div><div data-people></div><p style="font-size:13px">La partita continua mentre questo pannello e' aperto. Chiudere il pannello non spegne il microfono.</p></section>`;
      const actions=root.querySelector('[data-actions]');
      const button=(text,action)=>{const b=document.createElement('button');b.textContent=text;b.style.cssText='border:2px solid #fff0cc;border-radius:14px;padding:12px;background:#347667;color:#153536;font:bold 15px system-ui;cursor:pointer';b.onclick=action;actions.appendChild(b);return b;};
      // A real DOM click keeps microphone permission and AudioContext activation
      // in the browser's user gesture, rather than a later Godot frame.
      this.startButton=button('ATTIVA AUDIO',()=>this.enabled?this.stop():this.start());
      this.muteButton=button('SILENZIA MICROFONO',()=>this.setMuted(!this.muted));
      button('RIPRISTINA USCITA AUDIO',()=>this.repairOutput());
      button('CHIUDI',()=>this.closePanel());
      root.addEventListener('keydown',e=>{e.stopPropagation();if(e.key==='Escape')this.closePanel();if(e.key==='Tab'){const items=[...root.querySelectorAll('button:not(:disabled),input')];const first=items[0],last=items.at(-1);if(e.shiftKey&&document.activeElement===first){e.preventDefault();last.focus();}else if(!e.shiftKey&&document.activeElement===last){e.preventDefault();first.focus();}}});
      root.addEventListener('pointerdown',()=>this.unlock());
      for(const type of ['pointerdown','pointerup','click'])root.addEventListener(type,e=>e.stopPropagation());
      document.body.appendChild(root);this.refreshPanel();this.startButton.focus();
    }
    closePanel() {this.panel?.remove();this.panel=null;document.querySelector('canvas')?.focus();}
    refreshPanel() {
      if(!this.panel)return;
      this.panel.querySelector('[data-status]').textContent=!this.me ? 'Chat disponibile in una lobby multiplayer. Se sei gia\' in partita, aggiorna anche il server.' : (this.message || 'Chat vocale disattivata.');
      this.startButton.disabled=!!this.starting || !this.me;
      this.startButton.textContent=this.starting ? 'CONNESSIONE…' : this.enabled ? 'DISATTIVA AUDIO' : 'ATTIVA AUDIO';
      this.muteButton.disabled=!this.enabled;this.muteButton.textContent=this.muted?'RIATTIVA MICROFONO':'SILENZIA MICROFONO';
      const list=this.panel.querySelector('[data-people]');
      const signature=JSON.stringify([...this.people].map(([id,p])=>[id,p.name,this.peers.get(id)?.state||'off']));
      if(list.dataset.signature===signature)return;
      list.dataset.signature=signature;list.replaceChildren();
      for(const [id,person] of this.people){
        const row=document.createElement('label');row.style.cssText='display:block;margin:16px 0';
        const state=this.peers.get(id)?.state;
        row.append(document.createTextNode(`${person.name || 'Giocatore'} — ${state==='connected'?'connesso':state==='failed'?'connessione fallita':state?'connessione…':'chat non attiva'}`));
        const slider=document.createElement('input');slider.type='range';slider.min='0';slider.max='100';slider.value=String((this.volumes.get(id)??1)*100);slider.style.cssText='display:block;width:100%;accent-color:#347667';slider.setAttribute('aria-label',`Volume ${person.name || 'giocatore'}`);
        slider.oninput=()=>{this.setVolume(id,Number(slider.value)/100);this.event({op:'volume',id,value:Number(slider.value)});};row.appendChild(slider);list.appendChild(row);
      }
    }

    diagnostics() {
      return ['Voce LiveKit 2.22.3','Connessione: '+(this.session?.state||'disconnessa'),
        'Microfono: '+(this.stream?.active?'attivo':'spento'),
        'Audio: '+(this.context?.state||'spento'),'Partecipanti vocali: '+this.peers.size,
        'Fase: '+(this.stage||'inattiva'),'Ultimo errore: '+(this.lastError||'nessuno'),
        'Disconnessione: '+(this.disconnectReason??'nessuna'),
        'Sessione audio: '+(navigator.audioSession?.type||'gestita dal browser'),
        'Uscita: '+(this.outputNote||'predefinita di sistema')].join('\n');
    }
    prepareAudioSession() {
      // WebKit can retain an old handset route. Reset before capture, then
      // explicitly request duplex audio afterwards. Never force playback while
      // recording: that can prevent microphone capture on Safari.
      try {
        if(navigator.audioSession){
          this.previousAudioSession=navigator.audioSession.type;
          navigator.audioSession.type='auto';
        }
      } catch(_) {}
    }
    async repairOutput() {
      if(!this.stream){this.status('Attiva prima il microfono.');return;}
      const generation=this.generation;
      try {
        if(navigator.audioSession){
          navigator.audioSession.type='auto';
          navigator.audioSession.type='play-and-record';
        }
        // Where supported let the user choose explicitly, rather than guessing
        // device labels and accidentally overriding Bluetooth/headphones.
        if(navigator.mediaDevices.selectAudioOutput&&this.context?.setSinkId){
          const device=await navigator.mediaDevices.selectAudioOutput();
          if(generation!==this.generation)return;
          await this.context.setSinkId(device.deviceId);
          if(generation!==this.generation)return;
          this.outputNote='uscita selezionata';
        } else this.outputNote='ripristino richiesto; uscita fisica non verificabile';
        this.unlock();
        this.status('Uscita audio aggiornata: verifica da dove senti la voce.');
      } catch(_) {
        if(generation===this.generation)this.status('Uscita non cambiata: il browser non consente la selezione o e\' stata annullata.');
      }
    }
    update(room,me,list) {
      if(room!==this.room||me!==this.me){this.stop();this.volumes.clear();}
      this.room=room;this.me=me;
      this.people=new Map(list.filter(p=>p.id!==me&&!p.bot&&p.connected).map(p=>[p.id,p]));
      for(const id of [...this.peers.keys()])if(!this.people.has(id))this.closePeer(id);
      this.refreshPanel();
    }
    credentials(id,data) {
      if(this.waiting?.id!==id)return;
      const pending=this.waiting;this.waiting=null;clearTimeout(pending.timer);
      if(data.error)pending.reject(new Error(data.error));
      else if(!/^wss:\/\//.test(data.url)||typeof data.token!=='string')pending.reject(new Error('Configurazione LiveKit non valida.'));
      else pending.resolve(data);
    }
    requestCredentials() {
      return new Promise((resolve,reject)=>{
        const id=++this.requestId;
        const timer=setTimeout(()=>{
          if(this.waiting?.id===id){this.waiting=null;reject(new Error('Il server non risponde alla richiesta vocale. Aggiorna anche il server Bisca.'));}
        },12000);
        this.waiting={id,resolve,reject,timer};this.event({op:'token',id});
      });
    }
    async start() {
      if(this.starting)return;
      if(!this.room||!this.me){this.status('Entra prima in una lobby multiplayer.');return;}
      if(!window.LivekitClient){this.status('Modulo LiveKit mancante. Aggiorna il gioco.');return;}
      if(!window.isSecureContext||!navigator.mediaDevices?.getUserMedia){this.status('Apri il gioco tramite HTTPS in un browser aggiornato.');return;}
      this.stop();
      this.lastError='';this.disconnectReason=null;this.stage='microfono';
      const generation=this.generation;
      this.starting=true;this.status('Consenti il microfono: connessione a LiveKit…');
      this.prepareAudioSession();
      try {
        // Capture/resume in the actual DOM gesture, before asynchronous authorization.
        this.context=new (window.AudioContext||window.webkitAudioContext)({latencyHint:'interactive'});
        this.context.resume().catch(()=>{});
        const stream=await navigator.mediaDevices.getUserMedia({video:false,audio:{echoCancellation:true,noiseSuppression:true,autoGainControl:true}});
        if(generation!==this.generation){stream.getTracks().forEach(t=>t.stop());return;}
        this.stream=stream;
        try {if(navigator.audioSession)navigator.audioSession.type='play-and-record';} catch(_) {}
        stream.getAudioTracks()[0].onended=()=>{
          if(generation===this.generation){this.stop();this.status('Microfono scollegato. Premi ATTIVA AUDIO.');}
        };
        this.stage='autorizzazione server Bisca';
        const credentials=await this.requestCredentials();
        if(generation!==this.generation)return;
        const LK=window.LivekitClient;
        const session=new LK.Room({webAudioMix:{audioContext:this.context}});
        this.session=session;
        const active=()=>this.session===session&&generation===this.generation;
        const idOf=p=>p.identity.split('.')[0];
        session.on(LK.RoomEvent.TrackSubscribed,(track,_publication,participant)=>{
          if(!active()||track.kind!=='audio')return;
          const id=idOf(participant);if(!this.people.has(id))return;
          this.closePeer(id);
          const audio=track.attach();audio.hidden=true;audio.setAttribute('playsinline','');document.body.appendChild(audio);
          this.peers.set(id,{track,audio,state:'connected'});
          this.applyVolume(id);this.unlock();this.refreshPanel();
        });
        session.on(LK.RoomEvent.TrackUnsubscribed,(track,_publication,participant)=>{
          const id=idOf(participant);if(active()&&this.peers.get(id)?.track===track)this.closePeer(id);
        });
        session.on(LK.RoomEvent.ParticipantDisconnected,p=>{if(active())this.closePeer(idOf(p));});
        session.on(LK.RoomEvent.Reconnecting,()=>{if(active())this.status('Riconnessione vocale in corso…');});
        session.on(LK.RoomEvent.Reconnected,()=>{if(active()){this.unlock();this.status('Chat vocale connessa.');}});
        session.on(LK.RoomEvent.AudioPlaybackStatusChanged,()=>{
          if(active()&&!session.canPlaybackAudio)this.status("Tocca il pannello per attivare l'audio.");
        });
        session.on(LK.RoomEvent.Disconnected,(reason)=>{
          if(!active())return;
          this.disconnectReason=LK.DisconnectReason?.[reason]??reason??'non specificata';
          // connect/publish reject with the useful error. Do not invalidate their
          // generation here: that used to swallow authentication/network failures.
          if(this.starting)return;
          this.stop();this.status('Chat vocale disconnessa ('+this.disconnectReason+'). Premi ATTIVA AUDIO per riprovare.');
        });
        this.stage='connessione LiveKit';
        await session.connect(credentials.url,credentials.token,{autoSubscribe:true});
        if(!active()){await session.disconnect();return;}
        this.stage='pubblicazione microfono';
        await session.localParticipant.publishTrack(stream.getAudioTracks()[0],{source:LK.Track.Source.Microphone});
        if(!active()){await session.disconnect();return;}
        this.stage='connessa';
        this.enabled=true;this.starting=false;this.unlock();
        this.status('Chat vocale connessa. Anche gli altri giocatori devono attivarla.');
      } catch(error) {
        if(generation!==this.generation)return;
        // Never expose credentials or URLs that may carry access tokens.
        this.lastError=String(error?.message||error).replace(/(?:https?|wss?):\/\/\S+/g,'[indirizzo]').replace(/eyJ[A-Za-z0-9_-]+\.[A-Za-z0-9_-]+\.[A-Za-z0-9_-]+/g,'[token]').slice(0,400);
        this.stop();
        const message=error.name==='NotAllowedError'?'Microfono negato: abilitalo nei permessi del sito.':
          error.name==='NotFoundError'?'Nessun microfono trovato.':
          error.name==='NotReadableError'?'Microfono occupato: chiudi le altre app audio e riprova.':
          /^(LiveKit non configurato|Entra prima|Lobby non disponibile|Giocatore non disponibile|Accesso vocale|Attendi un momento|Il server non risponde|Configurazione LiveKit)/.test(error.message)?error.message:
          'Errore durante '+this.stage+': '+this.lastError;
        this.status(message);
      }
    }
    setMuted(value) {
      this.muted=!!value;this.stream?.getAudioTracks().forEach(t=>{t.enabled=!this.muted;});
      for(const publication of this.session?.localParticipant.audioTrackPublications.values()||[]){
        const operation=this.muted?publication.track?.mute():publication.track?.unmute();operation?.catch(()=>{});
      }
      this.status(this.muted?'Microfono silenziato. Puoi ascoltare gli altri.':'Chat vocale attiva.');
    }
    setVolume(id,value) {this.volumes.set(id,Math.max(0,Math.min(1,value)));this.applyVolume(id);}
    setMaster(value) {this.master=Math.max(0,Math.min(1,value));for(const id of this.peers.keys())this.applyVolume(id);}
    applyVolume(id) {
      // webAudioMix uses GainNode, including on iOS where audio.volume is limited.
      this.peers.get(id)?.track.setVolume((this.volumes.get(id)??1)*this.master);
    }
    closePeer(id) {
      const peer=this.peers.get(id);if(!peer)return;
      this.peers.delete(id);peer.track.detach().forEach(element=>element.remove());
      peer.audio?.remove();this.refreshPanel();
    }
    stop() {
      ++this.generation;this.starting=false;this.enabled=false;this.muted=false;
      if(this.waiting){clearTimeout(this.waiting.timer);this.waiting.reject(new Error('Annullato'));this.waiting=null;}
      const session=this.session;this.session=null;
      for(const id of [...this.peers.keys()])this.closePeer(id);
      this.stream?.getTracks().forEach(t=>{t.onended=null;t.stop();});this.stream=null;
      session?.disconnect().catch(()=>{});
      this.context?.close().catch(()=>{});this.context=null;
      try {
        if(this.previousAudioSession!==undefined&&navigator.audioSession)navigator.audioSession.type=this.previousAudioSession;
      } catch(_) {}
      this.previousAudioSession=undefined;
      this.status('Chat vocale disattivata.');
    }
    receive() {} // Ignore old P2P signals during rolling deployments.
  }
  window.BiscaVoiceTransport=BiscaVoiceTransport;
  window.BiscaVoice=new BiscaVoiceTransport();
})();
