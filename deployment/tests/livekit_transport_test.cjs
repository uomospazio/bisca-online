// Deterministic lifecycle tests; mock network/media, never opens a microphone.
const assert = require('node:assert/strict');
const fs = require('node:fs');
const vm = require('node:vm');
const { EventEmitter } = require('node:events');
const events = Object.fromEntries(['TrackSubscribed','TrackUnsubscribed','ParticipantDisconnected','Reconnecting','Reconnected','AudioPlaybackStatusChanged','Disconnected'].map(x=>[x,x]));
let getMedia, connectGate;
class Room extends EventEmitter {
  constructor(options) {
    super(); this.options=options; this.state='disconnected';
    this.localParticipant={audioTrackPublications:new Map(),publishTrack:async track=>{this.published=track;}};
  }
  async connect(url,token) {this.url=url;this.token=token;await connectGate;this.state='connected';}
  async disconnect(){this.state='disconnected';this.emit(events.Disconnected);}
  async startAudio() {}
}
class Context {constructor(){this.state='running';} async resume(){} async close(){this.state='closed';}}
global.window={addEventListener(){},isSecureContext:true,AudioContext:Context,LivekitClient:{Room,RoomEvent:events,Track:{Source:{Microphone:'microphone'}}}};
global.document={addEventListener(){},body:{appendChild(){}}};
Object.defineProperty(global,'navigator',{value:{mediaDevices:{getUserMedia:()=>getMedia()}},configurable:true});
vm.runInThisContext(fs.readFileSync('scenes/balatro/scripts/voice_transport.js','utf8'));
const turn=()=>new Promise(resolve=>setImmediate(resolve));
const stream=()=>{const track={enabled:true,stopped:false,stop(){this.stopped=true;}};return {active:true,track,getAudioTracks:()=>[track],getTracks:()=>[track]};};
const voice=window.BiscaVoice;
const roster=[{id:'me',connected:true},{id:'other',name:'Other',connected:true},{id:'bot',bot:true,connected:true}];
const authorize=async()=>{await turn();const e=JSON.parse(voice.drain()).find(e=>e.op==='token');assert(e);voice.credentials(e.id,{url:'wss://test.invalid',token:'dummy'});};
(async()=>{
  voice.update('room','me',roster);
  assert.equal(voice.people.size,1);
  let media=stream();getMedia=async()=>media;
  let starting=voice.start();await authorize();await starting;
  assert(voice.enabled);assert.equal(voice.session.published,media.track);
  assert.equal(voice.session.options.webAudioMix.audioContext,voice.context);
  const track={kind:'audio',volume:1,attach:()=>({setAttribute(){},remove(){}}),detach:()=>[],setVolume(v){this.volume=v;}};
  voice.session.emit(events.TrackSubscribed,track,{}, {identity:'other.session'});
  voice.setVolume('other',0.4);voice.setMaster(0.5);assert.equal(track.volume,0.2);
  voice.setVolume('other',0);assert.equal(track.volume,0);
  voice.setMuted(true);assert.equal(media.track.enabled,false);
  voice.setMuted(false);assert.equal(media.track.enabled,true);
  voice.session.emit(events.Reconnecting);assert.match(voice.message,/Riconnessione/);
  voice.session.emit(events.Reconnected);assert.match(voice.message,/connessa/);
  const old=voice.session;
  voice.update('second','me',roster);assert(!voice.enabled&&media.track.stopped);assert.equal(voice.peers.size,0);
  old.emit(events.TrackSubscribed,track,{}, {identity:'other.old'});assert.equal(voice.peers.size,0);
  media=stream();getMedia=async()=>media;
  starting=voice.start();await turn();const request=JSON.parse(voice.drain()).find(e=>e.op==='token');
  voice.credentials(request.id+1,{url:'wss://test.invalid',token:'stale'});assert(voice.waiting);
  voice.stop();await starting;assert(media.track.stopped&&!voice.enabled);
  media=stream();getMedia=async()=>media;
  starting=voice.start();await turn();const denied=JSON.parse(voice.drain()).find(e=>e.op==='token');
  voice.credentials(denied.id,{error:'LiveKit non configurato: imposta URL e chiavi sul server Bisca.'});
  await starting;assert.match(voice.message,/non configurato/);assert(media.track.stopped);
  getMedia=async()=>{throw Object.assign(new Error('denied'),{name:'NotAllowedError'});};
  await voice.start();assert.match(voice.message,/Microfono negato/);assert(!voice.starting);
  let resolveMedia;getMedia=()=>new Promise(resolve=>{resolveMedia=resolve;});
  starting=voice.start();voice.stop();media=stream();resolveMedia(media);await starting;
  assert(media.track.stopped&&!voice.enabled);
  let finishConnect;connectGate=new Promise(resolve=>{finishConnect=resolve;});
  media=stream();getMedia=async()=>media;starting=voice.start();await authorize();await turn();
  voice.stop();finishConnect();await starting;assert(media.track.stopped&&!voice.enabled);
  console.log('PASS: LiveKit lifecycle, audio-only publish, gain, mute, reconnect, room isolation, stale tokens, cancellation, permission errors');
})().catch(error=>{console.error(error);process.exitCode=1;});
