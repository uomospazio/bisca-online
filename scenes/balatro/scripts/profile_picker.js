(() => {
  if (window.BiscaProfile) return;
  window.BiscaProfile = {
    result: '', generation: 0,
    drain() { const r = this.result; this.result = ''; return r; },
    stopCamera() {
      this.stream?.getTracks().forEach(track => track.stop()); this.stream = null;
      if (this.video) { this.video.pause(); this.video.srcObject = null; }
    },
    close() {
      ++this.generation; this.stopCamera(); this.root?.remove(); this.root = null;
      this.result = '';
    },
    open(name) {
      this.close(); const generation = this.generation;
      let encoded = '', working = false;
      const root = document.createElement('div'); this.root = root;
      root.style.cssText = 'position:fixed;inset:0;z-index:1000;background:#313145bb;display:grid;place-items:center;padding:12px;box-sizing:border-box;touch-action:auto;';
      root.innerHTML = `<style>
        .bisca-profile{background:#474660;color:#fde4b9;border:3px solid #74ab8e;border-radius:22px;box-shadow:5px 6px #313145;padding:22px;box-sizing:border-box;width:min(520px,94vw);max-height:94dvh;overflow:auto;text-align:center;font:700 17px system-ui;touch-action:auto}
        .bisca-profile [hidden]{display:none!important}.bisca-profile h2{margin:0 0 8px;font-size:25px}.bisca-profile p{margin:10px 0}.bisca-profile button{font:inherit;border:2px solid transparent;border-radius:14px;background:#74ab8e;color:#fde4b9;padding:12px 18px;cursor:pointer;box-shadow:3px 4px #313145;touch-action:manipulation}
        .bisca-profile button:hover{border-color:#fde4b9}.bisca-profile button:disabled{opacity:.5;cursor:default}.bisca-profile .photo{display:block;margin:14px auto;width:128px;height:128px;border-radius:50%;border:3px solid #313145;background:#d9d9d9;padding:0;overflow:hidden;color:#474660;font-size:40px;box-shadow:none}.bisca-profile .photo img{width:100%;height:100%;object-fit:cover}.bisca-profile .choices{display:flex;gap:12px;justify-content:center;flex-wrap:wrap}.bisca-profile small{font-weight:400;display:block;margin:12px 0}.bisca-profile video{width:160px;height:160px;object-fit:cover;border-radius:50%}
        @media(max-height:500px){.bisca-profile{padding:12px;width:min(720px,94vw);font-size:14px}.bisca-profile h2{font-size:20px}.bisca-profile .photo{width:88px;height:88px;margin:8px auto}.bisca-profile small{margin:8px 0}.bisca-profile button{padding:8px 14px}}
      </style><section class="bisca-profile" role="dialog" aria-modal="true" aria-label="Il tuo profilo">
        <h2>IL TUO PROFILO</h2><p class="name"></p>
        <button class="photo" aria-label="Scegli foto profilo">+</button>
        <div class="choices sources" hidden><button class="camera">SCATTA FOTO</button><button class="import">IMPORTA FOTO</button></div>
        <div class="capture" hidden><video autoplay muted playsinline></video><br><button class="take">SCATTA</button></div>
        <small>La foto sara' visibile ai giocatori della lobby.</small>
        <p class="status" role="status"></p>
        <div class="choices"><button class="skip">SALTA</button><button class="save" disabled>CONFERMA</button></div>
      </section>`;
      const q = selector => root.querySelector(selector);
      q('.name').textContent = name;
      const status = q('.status'), save = q('.save'), photo = q('.photo');
      const input = document.createElement('input'); input.type = 'file'; input.accept = 'image/*'; input.hidden = true; root.append(input);
      const cameraInput = document.createElement('input'); cameraInput.type = 'file'; cameraInput.accept = 'image/*'; cameraInput.setAttribute('capture','user'); cameraInput.hidden = true; root.append(cameraInput);
      const alive = () => this.generation === generation && this.root === root;
      const useImage = source => {
        const width = source.videoWidth || source.naturalWidth || source.width;
        const height = source.videoHeight || source.naturalHeight || source.height;
        if (!width || !height) throw Error('Foto non disponibile.');
        const canvas = document.createElement('canvas'); canvas.width = canvas.height = 192;
        const ctx = canvas.getContext('2d'); ctx.fillStyle='#d9d9d9'; ctx.fillRect(0,0,192,192);
        const side = Math.min(width,height);
        ctx.drawImage(source,(width-side)/2,(height-side)/2,side,side,0,0,192,192);
        let data = '';
        for (const quality of [.8,.65,.5,.35,.2]) { data=canvas.toDataURL('image/jpeg',quality); if(data.split(',')[1].length<=32768)break; }
        if(data.split(',')[1].length>32768)throw Error('Foto troppo complessa. Prova un’altra immagine.');
        encoded=data.split(',')[1]; const img=document.createElement('img'); img.src=data; img.alt='Anteprima profilo'; photo.replaceChildren(img);
        save.disabled=false; status.textContent=''; this.stopCamera(); q('.capture').hidden=true;
      };
      const importFile = async file => {
        if(!file || working)return;
        if(file.size>20*1024*1024){status.textContent='Scegli una foto inferiore a 20 MB.';return;}
        working=true; save.disabled=true; status.textContent='Preparazione foto...';
        const url=URL.createObjectURL(file);
        try { const img=new Image(); img.src=url; await img.decode(); if(alive())useImage(img); }
        catch { if(alive())status.textContent='Formato non supportato. Prova una foto JPG o PNG.'; }
        finally { URL.revokeObjectURL(url);working=false;if(alive())save.disabled=!encoded; }
      };
      input.onchange=()=>importFile(input.files[0]); cameraInput.onchange=()=>importFile(cameraInput.files[0]);
      q('.import').onclick=()=>{input.value='';input.click();};
      photo.onclick=()=>{q('.sources').hidden=false;q('.camera').focus();status.textContent='Scegli SCATTA FOTO oppure IMPORTA FOTO.';};
      q('.camera').onclick=async()=>{
        if(matchMedia('(pointer:coarse)').matches){cameraInput.value='';cameraInput.click();return;}
        q('.camera').disabled=true;this.stopCamera();status.textContent='Consenti l’accesso alla fotocamera.';
        try {
          const stream=await navigator.mediaDevices.getUserMedia({video:{facingMode:'user',width:640,height:640},audio:false});
          if(!alive()){stream.getTracks().forEach(t=>t.stop());return;}
          this.stream=stream;this.video=q('video');this.video.srcObject=stream;q('.capture').hidden=false;
          await this.video.play();if(alive())status.textContent='Premi SCATTA quando sei pronto.';
        } catch { if(alive()){this.stopCamera();status.textContent='Fotocamera non disponibile o permesso negato. Puoi importare una foto.';} }
        finally {if(alive())q('.camera').disabled=false;}
      };
      q('.take').onclick=()=>{try{useImage(this.video);}catch(e){status.textContent=e.message;}};
      const finish=data=>{this.close();this.result=JSON.stringify({avatar:data});document.getElementById('canvas')?.focus();};
      q('.skip').onclick=()=>finish('');save.onclick=()=>{if(encoded&&!working)finish(encoded);};
      root.onkeydown=e=>{e.stopPropagation();if(e.key==='Escape')finish('');if(e.key==='Tab'){const nodes=[...root.querySelectorAll('button:not(:disabled)')].filter(b=>b.getClientRects().length);const first=nodes[0],last=nodes.at(-1);if(e.shiftKey&&document.activeElement===first){last.focus();e.preventDefault();}else if(!e.shiftKey&&document.activeElement===last){first.focus();e.preventDefault();}}};
      document.body.append(root);photo.focus();
    }
  };
  window.addEventListener('pagehide',()=>window.BiscaProfile.close());
})();
