# Backup colori BISCA — 23 settembre 2026

Colori originali prima della modifica, incluse le modifiche locali. Palette nuova: smeraldo #288F64, petrolio #214F50, hover #347667, crema #FFF0CC, ombre #153536, oro #F6C85F e corallo #E85D68. Illustrazioni, foto e alpha invariati.


## scenes/balatro/scripts/button_shadow.gd

Riga 4
```text
PRIMA: const SHADOW_COLOR := Color("14213d")
DOPO: const SHADOW_COLOR := Color("153536")
```

## scenes/balatro/scripts/card.gd

Riga 34
```text
PRIMA: 	joker_arrow.color = Color("35c96a") if high else Color("ed4242")
DOPO: 	joker_arrow.color = Color("42c985") if high else Color("e85d68")
```

## scenes/balatro/scripts/card_info.gd

Riga 19
```text
PRIMA: 	shade.color = Color(0.19, 0.19, 0.27, 0.75)
DOPO: 	shade.color = Color(0.082353, 0.207843, 0.211765, 0.75)
```

## scenes/balatro/scripts/game_overlay.gd

Riga 54
```text
PRIMA: 	overlay_shade.color = Color(0.025, 0.06, 0.035, 0.55)
DOPO: 	overlay_shade.color = Color(0.082353, 0.207843, 0.211765, 0.55)
```

## scenes/balatro/scripts/lexispell_background.gd

Riga 15
```text
PRIMA: 	color = Color(0.341176, 0.509804, 0.423529, 1)
DOPO: 	color = Color(0.156863, 0.560784, 0.392157, 1)
```

Riga 19
```text
PRIMA: 	stars.color = Color(0.454902, 0.670588, 0.556863, 1)
DOPO: 	stars.color = Color(0.329412, 0.729412, 0.474510, 1)
```

## scenes/balatro/scripts/lexispell_style.gd

Riga 4
```text
PRIMA: const NORMAL := Color("474660")
DOPO: const NORMAL := Color("214f50")
```

Riga 5
```text
PRIMA: const HOVER := Color("74ab8e")
DOPO: const HOVER := Color("347667")
```

Riga 6
```text
PRIMA: const TEXT := Color("fde4b9")
DOPO: const TEXT := Color("fff0cc")
```

Riga 7
```text
PRIMA: const SHADOW := Color("313145")
DOPO: const SHADOW := Color("153536")
```

Riga 8
```text
PRIMA: const DISABLED := Color(0.38, 0.38, 0.38)
DOPO: const DISABLED := Color(0.345098, 0.435294, 0.4)
```

Riga 9
```text
PRIMA: const DISABLED_TEXT := Color(0.65, 0.65, 0.65)
DOPO: const DISABLED_TEXT := Color(0.760784, 0.792157, 0.733333)
```

Riga 24
```text
PRIMA: 		style.shadow_color = Color(0.27, 0.27, 0.27) if color == DISABLED else SHADOW
DOPO: 		style.shadow_color = Color(0.203922, 0.301961, 0.278431) if color == DISABLED else SHADOW
```

Riga 25
```text
PRIMA: 		if color == Color(0.89, 0.3204, 0.3204):
DOPO: 		if color == Color(0.909804, 0.364706, 0.407843):
```

Riga 26
```text
PRIMA: 			style.shadow_color = Color(0.69, 0.2484, 0.2484)
DOPO: 			style.shadow_color = Color(0.623529, 0.207843, 0.290196)
```

## scenes/balatro/scripts/loading_transition.gd

Riga 36
```text
PRIMA: 	material.set_shader_parameter("base_color", Color("474660"))
DOPO: 	material.set_shader_parameter("base_color", Color("214f50"))
```

Riga 58
```text
PRIMA: 	caption.add_theme_color_override("default_color", Color("fde4b9"))
DOPO: 	caption.add_theme_color_override("default_color", Color("fff0cc"))
```

Riga 59
```text
PRIMA: 	caption.add_theme_color_override("font_outline_color", Color("74ab8e"))
DOPO: 	caption.add_theme_color_override("font_outline_color", Color("347667"))
```

Riga 61
```text
PRIMA: 	caption.add_theme_color_override("font_shadow_color", Color("474660"))
DOPO: 	caption.add_theme_color_override("font_shadow_color", Color("214f50"))
```

## scenes/balatro/scripts/main_menu.gd

Riga 25
```text
PRIMA: const BUTTON_RED := Color(0.89, 0.3204, 0.3204)
DOPO: const BUTTON_RED := Color(0.909804, 0.364706, 0.407843)
```

Riga 125
```text
PRIMA: 			profile_button.draw_circle(Vector2(130, 130), 127, Color("d9d9d9"), true, -1, true)
DOPO: 			profile_button.draw_circle(Vector2(130, 130), 127, Color("e5e8d8"), true, -1, true)
```

Riga 260
```text
PRIMA: 	label.add_theme_color_override("font_color", Color("474660"))
DOPO: 	label.add_theme_color_override("font_color", Color("214f50"))
```

Riga 290
```text
PRIMA: 		outer.add_theme_color_override("font_color", Color("474660"))
DOPO: 		outer.add_theme_color_override("font_color", Color("214f50"))
```

Riga 291
```text
PRIMA: 		outer.add_theme_color_override("font_outline_color", Color("fde4b9"))
DOPO: 		outer.add_theme_color_override("font_outline_color", Color("fff0cc"))
```

Riga 301
```text
PRIMA: 		inner.add_theme_color_override("font_color", Color("474660"))
DOPO: 		inner.add_theme_color_override("font_color", Color("214f50"))
```

Riga 302
```text
PRIMA: 		inner.add_theme_color_override("font_outline_color", Color("fde4b9"))
DOPO: 		inner.add_theme_color_override("font_outline_color", Color("fff0cc"))
```

Riga 322
```text
PRIMA: 	style.bg_color = Color("fde4b9")
DOPO: 	style.bg_color = Color("fff0cc")
```

Riga 323
```text
PRIMA: 	style.border_color = Color("263d30")
DOPO: 	style.border_color = Color("214f50")
```

Riga 331
```text
PRIMA: 	input.add_theme_color_override("font_color", Color("474660"))
DOPO: 	input.add_theme_color_override("font_color", Color("214f50"))
```

Riga 332
```text
PRIMA: 	input.add_theme_color_override("font_placeholder_color", Color("777b72"))
DOPO: 	input.add_theme_color_override("font_placeholder_color", Color("65756b"))
```

Riga 333
```text
PRIMA: 	input.add_theme_color_override("caret_color", Color("474660"))
DOPO: 	input.add_theme_color_override("caret_color", Color("214f50"))
```

## scenes/balatro/scripts/match_controller.gd

Riga 241
```text
PRIMA: 	label.add_theme_color_override("default_color", Color("19271f"))
DOPO: 	label.add_theme_color_override("default_color", Color("153536"))
```

Riga 242
```text
PRIMA: 	label.add_theme_color_override("font_color", Color("19271f"))
DOPO: 	label.add_theme_color_override("font_color", Color("153536"))
```

Riga 273
```text
PRIMA: 	turn_clock.add_theme_color_override("font_color", Color("fde4b9"))
DOPO: 	turn_clock.add_theme_color_override("font_color", Color("fff0cc"))
```

Riga 289
```text
PRIMA: 	damage_shade.color = Color(0.02, 0.03, 0.04, 0.65)
DOPO: 	damage_shade.color = Color(0.082353, 0.207843, 0.211765, 0.65)
```

Riga 343
```text
PRIMA: 	button.fill_color = Color("74ab8e")
DOPO: 	button.fill_color = Color("347667")
```

## scenes/balatro/scripts/mixed_label.gd

Riga 9
```text
PRIMA: 	add_theme_color_override("default_color", Color("474660"))
DOPO: 	add_theme_color_override("default_color", Color("214f50"))
```

Riga 17
```text
PRIMA: 	add_theme_color_override("default_color", Color("474660"))
DOPO: 	add_theme_color_override("default_color", Color("214f50"))
```

## scenes/balatro/scripts/network_lobby.gd

Riga 250
```text
PRIMA: 				avatar.draw_circle(avatar.size / 2.0, 20, Color("d9d9d9"), true, -1, true)
DOPO: 				avatar.draw_circle(avatar.size / 2.0, 20, Color("e5e8d8"), true, -1, true)
```

## scenes/balatro/scripts/pause_menu.gd

Riga 24
```text
PRIMA: 	shade.color = Color(0.19, 0.19, 0.27, 0.85)
DOPO: 	shade.color = Color(0.082353, 0.207843, 0.211765, 0.85)
```

Riga 60
```text
PRIMA: 	quit_button.add_theme_stylebox_override("normal", Style.button_style(Color(0.89, 0.3204, 0.3204)))
DOPO: 	quit_button.add_theme_stylebox_override("normal", Style.button_style(Color(0.909804, 0.364706, 0.407843)))
```

## scenes/balatro/scripts/player_badge.gd

Riga 10
```text
PRIMA: const NAME_TEXT_COLOR := Color("fde4b9")
DOPO: const NAME_TEXT_COLOR := Color("fff0cc")
```

Riga 11
```text
PRIMA: const NAME_OUTLINE_COLOR := Color("74ab8e")
DOPO: const NAME_OUTLINE_COLOR := Color("347667")
```

Riga 12
```text
PRIMA: const NAME_SHADOW_COLOR := Color("474660")
DOPO: const NAME_SHADOW_COLOR := Color("214f50")
```

Riga 146
```text
PRIMA: 		draw_string_outline(draw_font, position_value, value, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, 3, Color("fde4b9"))
DOPO: 		draw_string_outline(draw_font, position_value, value, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, 3, Color("fff0cc"))
```

Riga 154
```text
PRIMA: 		frame.bg_color = Color(0.79, 0.985, 0.51, 0.48)
DOPO: 		frame.bg_color = Color(0.964706, 0.784314, 0.372549, 0.48)
```

Riga 155
```text
PRIMA: 		frame.border_color = Color("fde4b900")
DOPO: 		frame.border_color = Color("fff0cc00")
```

Riga 158
```text
PRIMA: 		frame.shadow_color = Color(0.333, 0.882, 0.0, 0.827)
DOPO: 		frame.shadow_color = Color(0.964706, 0.784314, 0.372549, 0.827)
```

Riga 164
```text
PRIMA: 	draw_circle(avatar, 56, Color("d9d9d9"), true, -1, true)
DOPO: 	draw_circle(avatar, 56, Color("e5e8d8"), true, -1, true)
```

Riga 179
```text
PRIMA: 	draw_string(COUNTER_FONT, baseline, number_text, HORIZONTAL_ALIGNMENT_LEFT, -1, number_size, Color("fde4b9"))
DOPO: 	draw_string(COUNTER_FONT, baseline, number_text, HORIZONTAL_ALIGNMENT_LEFT, -1, number_size, Color("fff0cc"))
```

Riga 182
```text
PRIMA: 	prediction_box.bg_color = Color("474660")
DOPO: 	prediction_box.bg_color = Color("214f50")
```

Riga 185
```text
PRIMA: 	prediction_shadow.bg_color = Color("313145")
DOPO: 	prediction_shadow.bg_color = Color("153536")
```

Riga 193
```text
PRIMA: 		_text(Vector2(125, 169), "/", 16, Color("fde4b9"), COUNTER_FONT, false)
DOPO: 		_text(Vector2(125, 169), "/", 16, Color("fff0cc"), COUNTER_FONT, false)
```

Riga 194
```text
PRIMA: 		_text(Vector2(143, 169), str(prediction), 24, Color("fde4b9"), KIDS_FONT, false)
DOPO: 		_text(Vector2(143, 169), str(prediction), 24, Color("fff0cc"), KIDS_FONT, false)
```

Riga 196
```text
PRIMA: 			_text(Vector2(107, 169), str(taken), 24, Color("fde4b9"), KIDS_FONT, false)
DOPO: 			_text(Vector2(107, 169), str(taken), 24, Color("fff0cc"), KIDS_FONT, false)
```

## scenes/balatro/scripts/profile_picker.gd

Riga 53
```text
PRIMA: 	blank.fill(Color("d9d9d9"))
DOPO: 	blank.fill(Color("e5e8d8"))
```

## scenes/balatro/scripts/profile_picker.js

Riga 18
```text
PRIMA:       root.style.cssText = 'position:fixed;inset:0;z-index:1000;background:#313145bb;display:grid;place-items:center;padding:12px;box-sizing:border-box;touch-action:auto;';
DOPO:       root.style.cssText = 'position:fixed;inset:0;z-index:1000;background:#153536bb;display:grid;place-items:center;padding:12px;box-sizing:border-box;touch-action:auto;';
```

Riga 20
```text
PRIMA:         .bisca-profile{background:#474660;color:#fde4b9;border:3px solid #74ab8e;border-radius:22px;box-shadow:5px 6px #313145;padding:22px;box-sizing:border-box;width:min(520px,94vw);max-height:94dvh;overflow:auto;text-align:center;font:700 17px system-ui;touch-action:auto}
DOPO:         .bisca-profile{background:#214f50;color:#fff0cc;border:3px solid #347667;border-radius:22px;box-shadow:5px 6px #153536;padding:22px;box-sizing:border-box;width:min(520px,94vw);max-height:94dvh;overflow:auto;text-align:center;font:700 17px system-ui;touch-action:auto}
```

Riga 21
```text
PRIMA:         .bisca-profile [hidden]{display:none!important}.bisca-profile h2{margin:0 0 8px;font-size:25px}.bisca-profile p{margin:10px 0}.bisca-profile button{font:inherit;border:2px solid transparent;border-radius:14px;background:#74ab8e;color:#fde4b9;padding:12px 18px;cursor:pointer;box-shadow:3px 4px #313145;touch-action:manipulation}
DOPO:         .bisca-profile [hidden]{display:none!important}.bisca-profile h2{margin:0 0 8px;font-size:25px}.bisca-profile p{margin:10px 0}.bisca-profile button{font:inherit;border:2px solid transparent;border-radius:14px;background:#347667;color:#fff0cc;padding:12px 18px;cursor:pointer;box-shadow:3px 4px #153536;touch-action:manipulation}
```

Riga 22
```text
PRIMA:         .bisca-profile button:hover{border-color:#fde4b9}.bisca-profile button:disabled{opacity:.5;cursor:default}.bisca-profile .photo{display:block;margin:14px auto;width:128px;height:128px;border-radius:50%;border:3px solid #313145;background:#d9d9d9;padding:0;overflow:hidden;color:#474660;font-size:40px;box-shadow:none}.bisca-profile .photo img{width:100%;height:100%;object-fit:cover}.bisca-profile .choices{display:flex;gap:12px;justify-content:center;flex-wrap:wrap}.bisca-profile small{font-weight:400;display:block;margin:12px 0}.bisca-profile video{width:160px;height:160px;object-fit:cover;border-radius:50%}
DOPO:         .bisca-profile button:hover{border-color:#fff0cc}.bisca-profile button:disabled{opacity:.5;cursor:default}.bisca-profile .photo{display:block;margin:14px auto;width:128px;height:128px;border-radius:50%;border:3px solid #153536;background:#e5e8d8;padding:0;overflow:hidden;color:#214f50;font-size:40px;box-shadow:none}.bisca-profile .photo img{width:100%;height:100%;object-fit:cover}.bisca-profile .choices{display:flex;gap:12px;justify-content:center;flex-wrap:wrap}.bisca-profile small{font-weight:400;display:block;margin:12px 0}.bisca-profile video{width:160px;height:160px;object-fit:cover;border-radius:50%}
```

Riga 44
```text
PRIMA:         const ctx = canvas.getContext('2d'); ctx.fillStyle='#d9d9d9'; ctx.fillRect(0,0,192,192);
DOPO:         const ctx = canvas.getContext('2d'); ctx.fillStyle='#e5e8d8'; ctx.fillRect(0,0,192,192);
```

## scenes/balatro/scripts/voice_transport.js

Riga 25
```text
PRIMA:       root.style.cssText='position:fixed;inset:0;z-index:2147483647;background:#14213daa;display:grid;place-items:center;padding:12px;box-sizing:border-box';
DOPO:       root.style.cssText='position:fixed;inset:0;z-index:2147483647;background:#153536aa;display:grid;place-items:center;padding:12px;box-sizing:border-box';
```

Riga 26
```text
PRIMA:       root.innerHTML=`<section role="dialog" aria-modal="true" aria-label="Chat vocale" style="box-sizing:border-box;width:min(480px,100%);max-height:90dvh;overflow:auto;background:#48465f;color:#fde4b9;border:3px solid #74ab8e;border-radius:22px;padding:22px;font:600 16px system-ui"><h2 style="margin-top:0">CHAT VOCALE</h2><p>Premi ATTIVA AUDIO e consenti l'accesso nel browser. Anche i tuoi amici devono attivarla.</p><p data-status role="status"></p><div data-actions style="display:flex;gap:10px;flex-wrap:wrap"></div><div data-people></div><p style="font-size:13px">La partita continua mentre questo pannello e' aperto. Chiudere il pannello non spegne il microfono.</p></section>`;
DOPO:       root.innerHTML=`<section role="dialog" aria-modal="true" aria-label="Chat vocale" style="box-sizing:border-box;width:min(480px,100%);max-height:90dvh;overflow:auto;background:#214f50;color:#fff0cc;border:3px solid #347667;border-radius:22px;padding:22px;font:600 16px system-ui"><h2 style="margin-top:0">CHAT VOCALE</h2><p>Premi ATTIVA AUDIO e consenti l'accesso nel browser. Anche i tuoi amici devono attivarla.</p><p data-status role="status"></p><div data-actions style="display:flex;gap:10px;flex-wrap:wrap"></div><div data-people></div><p style="font-size:13px">La partita continua mentre questo pannello e' aperto. Chiudere il pannello non spegne il microfono.</p></section>`;
```

Riga 28
```text
PRIMA:       const button=(text,action)=>{const b=document.createElement('button');b.textContent=text;b.style.cssText='border:2px solid #fde4b9;border-radius:14px;padding:12px;background:#74ab8e;color:#14213d;font:bold 15px system-ui;cursor:pointer';b.onclick=action;actions.appendChild(b);return b;};
DOPO:       const button=(text,action)=>{const b=document.createElement('button');b.textContent=text;b.style.cssText='border:2px solid #fff0cc;border-radius:14px;padding:12px;background:#347667;color:#153536;font:bold 15px system-ui;cursor:pointer';b.onclick=action;actions.appendChild(b);return b;};
```

Riga 55
```text
PRIMA:         const slider=document.createElement('input');slider.type='range';slider.min='0';slider.max='100';slider.value=String((this.volumes.get(id)??1)*100);slider.style.cssText='display:block;width:100%;accent-color:#74ab8e';slider.setAttribute('aria-label',`Volume ${person.name || 'giocatore'}`);
DOPO:         const slider=document.createElement('input');slider.type='range';slider.min='0';slider.max='100';slider.value=String((this.volumes.get(id)??1)*100);slider.style.cssText='display:block;width:100%;accent-color:#347667';slider.setAttribute('aria-label',`Volume ${person.name || 'giocatore'}`);
```

## scenes/balatro/visuals/settings_knob.svg

Riga 1
```text
PRIMA: <svg xmlns="http://www.w3.org/2000/svg" width="28" height="28" viewBox="0 0 28 28"><circle cx="14" cy="14" r="11" fill="#fde4b9"/></svg>
DOPO: <svg xmlns="http://www.w3.org/2000/svg" width="28" height="28" viewBox="0 0 28 28"><circle cx="14" cy="14" r="11" fill="#fff0cc"/></svg>
```

## scenes/balatro/visuals/settings_knob_hover.svg

Riga 1
```text
PRIMA: <svg xmlns="http://www.w3.org/2000/svg" width="32" height="32" viewBox="0 0 32 32"><circle cx="16" cy="16" r="14" fill="#fde4b9" stroke="#74ab8e" stroke-width="3"/></svg>
DOPO: <svg xmlns="http://www.w3.org/2000/svg" width="32" height="32" viewBox="0 0 32 32"><circle cx="16" cy="16" r="14" fill="#fff0cc" stroke="#347667" stroke-width="3"/></svg>
```

## scenes/balatro/visuals/settings_toggle_off.svg

Riga 1
```text
PRIMA: <svg xmlns="http://www.w3.org/2000/svg" width="70" height="36" viewBox="0 0 70 36"><rect x="2" y="3" width="66" height="30" rx="12" fill="#313145"/><rect x="5" y="5" width="27" height="26" rx="9" fill="#fde4b9"/></svg>
DOPO: <svg xmlns="http://www.w3.org/2000/svg" width="70" height="36" viewBox="0 0 70 36"><rect x="2" y="3" width="66" height="30" rx="12" fill="#153536"/><rect x="5" y="5" width="27" height="26" rx="9" fill="#fff0cc"/></svg>
```

## scenes/balatro/visuals/settings_toggle_on.svg

Riga 1
```text
PRIMA: <svg xmlns="http://www.w3.org/2000/svg" width="70" height="36" viewBox="0 0 70 36"><rect x="2" y="3" width="66" height="30" rx="12" fill="#74ab8e"/><rect x="38" y="5" width="27" height="26" rx="9" fill="#fde4b9"/></svg>
DOPO: <svg xmlns="http://www.w3.org/2000/svg" width="70" height="36" viewBox="0 0 70 36"><rect x="2" y="3" width="66" height="30" rx="12" fill="#347667"/><rect x="38" y="5" width="27" height="26" rx="9" fill="#fff0cc"/></svg>
```

## scenes/balatro/trick_asset/ui_bisca/arrow-left.svg

Riga 2
```text
PRIMA: <path d="M15.1 4.85C15.73 4.85 16.32 5 16.84 5.3C18.07 6.01 18.75 7.44 18.75 9.32V14.67C18.75 16.55 18.07 17.98 16.84 18.69C15.61 19.4 14.04 19.27 12.4 18.33L7.77 15.66C6.14 14.72 5.24 13.42 5.24 12C5.24 10.58 6.14 9.28 7.77 8.34L12.4 5.67C13.34 5.12 14.26 4.85 15.1 4.85ZM15.1 17.64C15.47 17.64 15.81 17.56 16.1 17.39C16.84 16.96 17.25 16 17.25 14.67V9.33C17.25 8.01 16.84 7.04 16.09 6.61C15.34 6.18 14.3 6.31 13.15 6.97L8.52 9.64C7.37 10.3 6.74 11.14 6.74 12C6.74 12.86 7.37 13.7 8.52 14.36L13.15 17.03C13.86 17.44 14.52 17.64 15.1 17.64Z" fill="#FDF0D5"/>
DOPO: <path d="M15.1 4.85C15.73 4.85 16.32 5 16.84 5.3C18.07 6.01 18.75 7.44 18.75 9.32V14.67C18.75 16.55 18.07 17.98 16.84 18.69C15.61 19.4 14.04 19.27 12.4 18.33L7.77 15.66C6.14 14.72 5.24 13.42 5.24 12C5.24 10.58 6.14 9.28 7.77 8.34L12.4 5.67C13.34 5.12 14.26 4.85 15.1 4.85ZM15.1 17.64C15.47 17.64 15.81 17.56 16.1 17.39C16.84 16.96 17.25 16 17.25 14.67V9.33C17.25 8.01 16.84 7.04 16.09 6.61C15.34 6.18 14.3 6.31 13.15 6.97L8.52 9.64C7.37 10.3 6.74 11.14 6.74 12C6.74 12.86 7.37 13.7 8.52 14.36L13.15 17.03C13.86 17.44 14.52 17.64 15.1 17.64Z" fill="#fff0cc"/>
```

Riga 3
```text
PRIMA: <path d="M17 16.7429V7.35396C17 6.68115 16.349 6.20032 15.7059 6.39818L10.7236 7.9312C10.5765 7.97646 10.4419 8.05504 10.3301 8.16084L6.76885 11.5329C6.35152 11.928 6.35237 12.5928 6.77071 12.9869L10.3029 16.3144C10.432 16.4359 10.591 16.521 10.7638 16.5609L15.7751 17.7173C16.4018 17.8619 17 17.386 17 16.7429Z" fill="#FDF0D5" stroke="#FDF0D5"/>
DOPO: <path d="M17 16.7429V7.35396C17 6.68115 16.349 6.20032 15.7059 6.39818L10.7236 7.9312C10.5765 7.97646 10.4419 8.05504 10.3301 8.16084L6.76885 11.5329C6.35152 11.928 6.35237 12.5928 6.77071 12.9869L10.3029 16.3144C10.432 16.4359 10.591 16.521 10.7638 16.5609L15.7751 17.7173C16.4018 17.8619 17 17.386 17 16.7429Z" fill="#fff0cc" stroke="#fff0cc"/>
```

## scenes/balatro/trick_asset/ui_bisca/arrow-right.svg

Riga 2
```text
PRIMA: <path d="M8.9 19.15C8.27 19.15 7.68 19 7.16 18.7C5.93 17.99 5.25 16.56 5.25 14.68V9.33C5.25 7.45 5.93 6.02 7.16 5.31C8.39 4.6 9.96 4.73 11.6 5.67L16.23 8.34C17.86 9.28 18.76 10.58 18.76 12C18.76 13.42 17.86 14.72 16.23 15.66L11.6 18.33C10.66 18.88 9.74 19.15 8.9 19.15ZM8.9 6.36C8.53 6.36 8.19 6.44 7.9 6.61C7.16 7.04 6.75 8 6.75 9.33V14.67C6.75 15.99 7.16 16.96 7.91 17.39C8.66 17.82 9.7 17.69 10.85 17.03L15.48 14.36C16.63 13.7 17.26 12.86 17.26 12C17.26 11.14 16.63 10.3 15.48 9.64L10.85 6.97C10.14 6.56 9.48 6.36 8.9 6.36Z" fill="#FDF0D5"/>
DOPO: <path d="M8.9 19.15C8.27 19.15 7.68 19 7.16 18.7C5.93 17.99 5.25 16.56 5.25 14.68V9.33C5.25 7.45 5.93 6.02 7.16 5.31C8.39 4.6 9.96 4.73 11.6 5.67L16.23 8.34C17.86 9.28 18.76 10.58 18.76 12C18.76 13.42 17.86 14.72 16.23 15.66L11.6 18.33C10.66 18.88 9.74 19.15 8.9 19.15ZM8.9 6.36C8.53 6.36 8.19 6.44 7.9 6.61C7.16 7.04 6.75 8 6.75 9.33V14.67C6.75 15.99 7.16 16.96 7.91 17.39C8.66 17.82 9.7 17.69 10.85 17.03L15.48 14.36C16.63 13.7 17.26 12.86 17.26 12C17.26 11.14 16.63 10.3 15.48 9.64L10.85 6.97C10.14 6.56 9.48 6.36 8.9 6.36Z" fill="#fff0cc"/>
```

Riga 3
```text
PRIMA: <path d="M7 7.25705V16.646C7 17.3188 7.65103 17.7997 8.29409 17.6018L13.2764 16.0688C13.4235 16.0235 13.5581 15.945 13.6699 15.8392L17.2311 12.4671C17.6485 12.072 17.6476 11.4072 17.2293 11.0131L13.6971 7.68563C13.568 7.56406 13.409 7.47899 13.2362 7.43913L8.22486 6.28266C7.59824 6.13806 7 6.61397 7 7.25705Z" fill="#FDF0D5" stroke="#FDF0D5"/>
DOPO: <path d="M7 7.25705V16.646C7 17.3188 7.65103 17.7997 8.29409 17.6018L13.2764 16.0688C13.4235 16.0235 13.5581 15.945 13.6699 15.8392L17.2311 12.4671C17.6485 12.072 17.6476 11.4072 17.2293 11.0131L13.6971 7.68563C13.568 7.56406 13.409 7.47899 13.2362 7.43913L8.22486 6.28266C7.59824 6.13806 7 6.61397 7 7.25705Z" fill="#fff0cc" stroke="#fff0cc"/>
```

## scenes/balatro/trick_asset/ui_bisca/copy-success.svg

Riga 2
```text
PRIMA: <path d="M17.0998 2H12.8998C9.81668 2 8.37074 3.09409 8.06951 5.73901C8.00649 6.29235 8.46476 6.75 9.02167 6.75H11.0998C15.2998 6.75 17.2498 8.7 17.2498 12.9V14.9781C17.2498 15.535 17.7074 15.9933 18.2608 15.9303C20.9057 15.629 21.9998 14.1831 21.9998 11.1V6.9C21.9998 3.4 20.5998 2 17.0998 2Z" fill="#FDF0D5"/>
DOPO: <path d="M17.0998 2H12.8998C9.81668 2 8.37074 3.09409 8.06951 5.73901C8.00649 6.29235 8.46476 6.75 9.02167 6.75H11.0998C15.2998 6.75 17.2498 8.7 17.2498 12.9V14.9781C17.2498 15.535 17.7074 15.9933 18.2608 15.9303C20.9057 15.629 21.9998 14.1831 21.9998 11.1V6.9C21.9998 3.4 20.5998 2 17.0998 2Z" fill="#fff0cc"/>
```

Riga 3
```text
PRIMA: <path d="M11.1 8H6.9C3.4 8 2 9.4 2 12.9V17.1C2 20.6 3.4 22 6.9 22H11.1C14.6 22 16 20.6 16 17.1V12.9C16 9.4 14.6 8 11.1 8ZM12.29 13.65L8.58 17.36C8.44 17.5 8.26 17.57 8.07 17.57C7.88 17.57 7.7 17.5 7.56 17.36L5.7 15.5C5.42 15.22 5.42 14.77 5.7 14.49C5.98 14.21 6.43 14.21 6.71 14.49L8.06 15.84L11.27 12.63C11.55 12.35 12 12.35 12.28 12.63C12.56 12.91 12.57 13.37 12.29 13.65Z" fill="#FDF0D5"/>
DOPO: <path d="M11.1 8H6.9C3.4 8 2 9.4 2 12.9V17.1C2 20.6 3.4 22 6.9 22H11.1C14.6 22 16 20.6 16 17.1V12.9C16 9.4 14.6 8 11.1 8ZM12.29 13.65L8.58 17.36C8.44 17.5 8.26 17.57 8.07 17.57C7.88 17.57 7.7 17.5 7.56 17.36L5.7 15.5C5.42 15.22 5.42 14.77 5.7 14.49C5.98 14.21 6.43 14.21 6.71 14.49L8.06 15.84L11.27 12.63C11.55 12.35 12 12.35 12.28 12.63C12.56 12.91 12.57 13.37 12.29 13.65Z" fill="#fff0cc"/>
```

## scenes/balatro/trick_asset/ui_bisca/copy.svg

Riga 2
```text
PRIMA: <path d="M16 12.9V17.1C16 20.6 14.6 22 11.1 22H6.9C3.4 22 2 20.6 2 17.1V12.9C2 9.4 3.4 8 6.9 8H11.1C14.6 8 16 9.4 16 12.9Z" fill="#FDF0D5"/>
DOPO: <path d="M16 12.9V17.1C16 20.6 14.6 22 11.1 22H6.9C3.4 22 2 20.6 2 17.1V12.9C2 9.4 3.4 8 6.9 8H11.1C14.6 8 16 9.4 16 12.9Z" fill="#fff0cc"/>
```

Riga 3
```text
PRIMA: <path d="M17.0998 2H12.8998C9.81668 2 8.37074 3.09409 8.06951 5.73901C8.00649 6.29235 8.46476 6.75 9.02167 6.75H11.0998C15.2998 6.75 17.2498 8.7 17.2498 12.9V14.9781C17.2498 15.535 17.7074 15.9933 18.2608 15.9303C20.9057 15.629 21.9998 14.1831 21.9998 11.1V6.9C21.9998 3.4 20.5998 2 17.0998 2Z" fill="#FDF0D5"/>
DOPO: <path d="M17.0998 2H12.8998C9.81668 2 8.37074 3.09409 8.06951 5.73901C8.00649 6.29235 8.46476 6.75 9.02167 6.75H11.0998C15.2998 6.75 17.2498 8.7 17.2498 12.9V14.9781C17.2498 15.535 17.7074 15.9933 18.2608 15.9303C20.9057 15.629 21.9998 14.1831 21.9998 11.1V6.9C21.9998 3.4 20.5998 2 17.0998 2Z" fill="#fff0cc"/>
```

## scenes/balatro/trick_asset/ui_bisca/edit.svg

Riga 2
```text
PRIMA: <path d="M19.0201 5.48C17.0801 3.54 15.1801 3.49 13.1901 5.48L11.9801 6.69C11.8801 6.79 11.8401 6.95 11.8801 7.09C12.6401 9.74 14.7601 11.86 17.4101 12.62C17.4501 12.63 17.4901 12.64 17.5301 12.64C17.6401 12.64 17.7401 12.6 17.8201 12.52L19.0201 11.31C20.0101 10.33 20.4901 9.38 20.4901 8.42C20.5001 7.43 20.0201 6.47 19.0201 5.48Z" fill="#FDF0D5"/>
DOPO: <path d="M19.0201 5.48C17.0801 3.54 15.1801 3.49 13.1901 5.48L11.9801 6.69C11.8801 6.79 11.8401 6.95 11.8801 7.09C12.6401 9.74 14.7601 11.86 17.4101 12.62C17.4501 12.63 17.4901 12.64 17.5301 12.64C17.6401 12.64 17.7401 12.6 17.8201 12.52L19.0201 11.31C20.0101 10.33 20.4901 9.38 20.4901 8.42C20.5001 7.43 20.0201 6.47 19.0201 5.48Z" fill="#fff0cc"/>
```

Riga 3
```text
PRIMA: <path d="M15.6098 13.53C15.3198 13.39 15.0398 13.25 14.7698 13.09C14.5498 12.96 14.3398 12.82 14.1298 12.67C13.9598 12.56 13.7598 12.4 13.5698 12.24C13.5498 12.23 13.4798 12.17 13.3998 12.09C13.0698 11.81 12.6998 11.45 12.3698 11.05C12.3398 11.03 12.2898 10.96 12.2198 10.87C12.1198 10.75 11.9498 10.55 11.7998 10.32C11.6798 10.17 11.5398 9.95 11.4098 9.73C11.2498 9.46 11.1098 9.19 10.9698 8.91C10.9486 8.8646 10.9281 8.81944 10.9083 8.77454C10.7607 8.44122 10.3261 8.34377 10.0683 8.60153L4.33983 14.33C4.20983 14.46 4.08983 14.71 4.05983 14.88L3.51983 18.71C3.41983 19.39 3.60983 20.03 4.02983 20.46C4.38983 20.81 4.88983 21 5.42983 21C5.54983 21 5.66983 20.99 5.78983 20.97L9.62983 20.43C9.80983 20.4 10.0598 20.28 10.1798 20.15L15.9011 14.4287C16.1607 14.1691 16.0628 13.7237 15.7252 13.5796C15.6872 13.5634 15.6488 13.5469 15.6098 13.53Z" fill="#FDF0D5"/>
DOPO: <path d="M15.6098 13.53C15.3198 13.39 15.0398 13.25 14.7698 13.09C14.5498 12.96 14.3398 12.82 14.1298 12.67C13.9598 12.56 13.7598 12.4 13.5698 12.24C13.5498 12.23 13.4798 12.17 13.3998 12.09C13.0698 11.81 12.6998 11.45 12.3698 11.05C12.3398 11.03 12.2898 10.96 12.2198 10.87C12.1198 10.75 11.9498 10.55 11.7998 10.32C11.6798 10.17 11.5398 9.95 11.4098 9.73C11.2498 9.46 11.1098 9.19 10.9698 8.91C10.9486 8.8646 10.9281 8.81944 10.9083 8.77454C10.7607 8.44122 10.3261 8.34377 10.0683 8.60153L4.33983 14.33C4.20983 14.46 4.08983 14.71 4.05983 14.88L3.51983 18.71C3.41983 19.39 3.60983 20.03 4.02983 20.46C4.38983 20.81 4.88983 21 5.42983 21C5.54983 21 5.66983 20.99 5.78983 20.97L9.62983 20.43C9.80983 20.4 10.0598 20.28 10.1798 20.15L15.9011 14.4287C16.1607 14.1691 16.0628 13.7237 15.7252 13.5796C15.6872 13.5634 15.6488 13.5469 15.6098 13.53Z" fill="#fff0cc"/>
```

## scenes/balatro/trick_asset/ui_bisca/moon.svg

Riga 2
```text
PRIMA: <path d="M21.5302 15.93C21.3702 15.66 20.9202 15.24 19.8002 15.44C19.1802 15.55 18.5502 15.6 17.9202 15.57C15.5902 15.47 13.4802 14.4 12.0102 12.75C10.7102 11.3 9.9102 9.40999 9.9002 7.36999C9.9002 6.22999 10.1202 5.12999 10.5702 4.08999C11.0102 3.07999 10.7002 2.54999 10.4802 2.32999C10.2502 2.09999 9.7102 1.77999 8.6502 2.21999C4.5602 3.93999 2.0302 8.03999 2.3302 12.43C2.6302 16.56 5.5302 20.09 9.3702 21.42C10.2902 21.74 11.2602 21.93 12.2602 21.97C12.4202 21.98 12.5802 21.99 12.7402 21.99C16.0902 21.99 19.2302 20.41 21.2102 17.72C21.8802 16.79 21.7002 16.2 21.5302 15.93Z" fill="#FDF0D5"/>
DOPO: <path d="M21.5302 15.93C21.3702 15.66 20.9202 15.24 19.8002 15.44C19.1802 15.55 18.5502 15.6 17.9202 15.57C15.5902 15.47 13.4802 14.4 12.0102 12.75C10.7102 11.3 9.9102 9.40999 9.9002 7.36999C9.9002 6.22999 10.1202 5.12999 10.5702 4.08999C11.0102 3.07999 10.7002 2.54999 10.4802 2.32999C10.2502 2.09999 9.7102 1.77999 8.6502 2.21999C4.5602 3.93999 2.0302 8.03999 2.3302 12.43C2.6302 16.56 5.5302 20.09 9.3702 21.42C10.2902 21.74 11.2602 21.93 12.2602 21.97C12.4202 21.98 12.5802 21.99 12.7402 21.99C16.0902 21.99 19.2302 20.41 21.2102 17.72C21.8802 16.79 21.7002 16.2 21.5302 15.93Z" fill="#fff0cc"/>
```

## scenes/balatro/trick_asset/ui_bisca/play.svg

Riga 2
```text
PRIMA: <path d="M7.87 21.28C7.08 21.28 6.33 21.09 5.67 20.71C4.11 19.81 3.25 17.98 3.25 15.57V8.44C3.25 6.02 4.11 4.2 5.67 3.3C7.23 2.4 9.24 2.57 11.34 3.78L17.51 7.34C19.6 8.55 20.76 10.21 20.76 12.01C20.76 13.81 19.61 15.47 17.51 16.68L11.34 20.24C10.13 20.93 8.95 21.28 7.87 21.28ZM7.87 4.22C7.33 4.22 6.85 4.34 6.42 4.59C5.34 5.21 4.75 6.58 4.75 8.44V15.56C4.75 17.42 5.34 18.78 6.42 19.41C7.5 20.04 8.98 19.86 10.59 18.93L16.76 15.37C18.37 14.44 19.26 13.25 19.26 12C19.26 10.75 18.37 9.56 16.76 8.63L10.59 5.07C9.61 4.51 8.69 4.22 7.87 4.22Z" fill="#FDF0D5"/>
DOPO: <path d="M7.87 21.28C7.08 21.28 6.33 21.09 5.67 20.71C4.11 19.81 3.25 17.98 3.25 15.57V8.44C3.25 6.02 4.11 4.2 5.67 3.3C7.23 2.4 9.24 2.57 11.34 3.78L17.51 7.34C19.6 8.55 20.76 10.21 20.76 12.01C20.76 13.81 19.61 15.47 17.51 16.68L11.34 20.24C10.13 20.93 8.95 21.28 7.87 21.28ZM7.87 4.22C7.33 4.22 6.85 4.34 6.42 4.59C5.34 5.21 4.75 6.58 4.75 8.44V15.56C4.75 17.42 5.34 18.78 6.42 19.41C7.5 20.04 8.98 19.86 10.59 18.93L16.76 15.37C18.37 14.44 19.26 13.25 19.26 12C19.26 10.75 18.37 9.56 16.76 8.63L10.59 5.07C9.61 4.51 8.69 4.22 7.87 4.22Z" fill="#fff0cc"/>
```

Riga 3
```text
PRIMA: <path d="M4.10479 12.9453L5.4678 18.7382C5.74795 19.9288 7.02174 20.5913 8.15742 20.137L13.2248 18.1101C13.4073 18.0371 13.578 17.9376 13.7314 17.8149L19.0478 13.5617C20.0486 12.7611 20.0486 11.2389 19.0478 10.4383L13.7785 6.22283C13.5943 6.07544 13.3854 5.96181 13.1616 5.8872L8.10377 4.20126C6.97866 3.82622 5.77621 4.50704 5.51894 5.66476L4.09925 12.0534C4.03393 12.3473 4.03582 12.6522 4.10479 12.9453Z" fill="#FDF0D5" stroke="#FDF0D5"/>
DOPO: <path d="M4.10479 12.9453L5.4678 18.7382C5.74795 19.9288 7.02174 20.5913 8.15742 20.137L13.2248 18.1101C13.4073 18.0371 13.578 17.9376 13.7314 17.8149L19.0478 13.5617C20.0486 12.7611 20.0486 11.2389 19.0478 10.4383L13.7785 6.22283C13.5943 6.07544 13.3854 5.96181 13.1616 5.8872L8.10377 4.20126C6.97866 3.82622 5.77621 4.50704 5.51894 5.66476L4.09925 12.0534C4.03393 12.3473 4.03582 12.6522 4.10479 12.9453Z" fill="#fff0cc" stroke="#fff0cc"/>
```

## scenes/balatro/trick_asset/ui_bisca/volume-cross.svg

Riga 2
```text
PRIMA: <path d="M22.5299 13.42L21.0799 11.97L22.4799 10.57C22.7699 10.28 22.7699 9.79999 22.4799 9.50999C22.1899 9.21999 21.7099 9.21999 21.4199 9.50999L20.0199 10.91L18.5699 9.45999C18.2799 9.16999 17.7999 9.16999 17.5099 9.45999C17.2199 9.74999 17.2199 10.23 17.5099 10.52L18.9599 11.97L17.4699 13.46C17.1799 13.75 17.1799 14.23 17.4699 14.52C17.6199 14.67 17.8099 14.74 17.9999 14.74C18.1899 14.74 18.3799 14.67 18.5299 14.52L20.0199 13.03L21.4699 14.48C21.6199 14.63 21.8099 14.7 21.9999 14.7C22.1899 14.7 22.3799 14.63 22.5299 14.48C22.8199 14.19 22.8199 13.72 22.5299 13.42Z" fill="#FDF0D5"/>
DOPO: <path d="M22.5299 13.42L21.0799 11.97L22.4799 10.57C22.7699 10.28 22.7699 9.79999 22.4799 9.50999C22.1899 9.21999 21.7099 9.21999 21.4199 9.50999L20.0199 10.91L18.5699 9.45999C18.2799 9.16999 17.7999 9.16999 17.5099 9.45999C17.2199 9.74999 17.2199 10.23 17.5099 10.52L18.9599 11.97L17.4699 13.46C17.1799 13.75 17.1799 14.23 17.4699 14.52C17.6199 14.67 17.8099 14.74 17.9999 14.74C18.1899 14.74 18.3799 14.67 18.5299 14.52L20.0199 13.03L21.4699 14.48C21.6199 14.63 21.8099 14.7 21.9999 14.7C22.1899 14.7 22.3799 14.63 22.5299 14.48C22.8199 14.19 22.8199 13.72 22.5299 13.42Z" fill="#fff0cc"/>
```

Riga 3
```text
PRIMA: <path d="M14.02 3.78C12.9 3.16 11.47 3.32 10.01 4.23L7.09 6.06C6.89 6.18 6.66 6.25 6.43 6.25H5.5H5C2.58 6.25 1.25 7.58 1.25 10V14C1.25 16.42 2.58 17.75 5 17.75H5.5H6.43C6.66 17.75 6.89 17.82 7.09 17.94L10.01 19.77C10.89 20.32 11.75 20.59 12.55 20.59C13.07 20.59 13.57 20.47 14.02 20.22C15.13 19.6 15.75 18.31 15.75 16.59V7.41C15.75 5.69 15.13 4.4 14.02 3.78Z" fill="#FDF0D5"/>
DOPO: <path d="M14.02 3.78C12.9 3.16 11.47 3.32 10.01 4.23L7.09 6.06C6.89 6.18 6.66 6.25 6.43 6.25H5.5H5C2.58 6.25 1.25 7.58 1.25 10V14C1.25 16.42 2.58 17.75 5 17.75H5.5H6.43C6.66 17.75 6.89 17.82 7.09 17.94L10.01 19.77C10.89 20.32 11.75 20.59 12.55 20.59C13.07 20.59 13.57 20.47 14.02 20.22C15.13 19.6 15.75 18.31 15.75 16.59V7.41C15.75 5.69 15.13 4.4 14.02 3.78Z" fill="#fff0cc"/>
```

## scenes/balatro/trick_asset/ui_bisca/volume-high.svg

Riga 2
```text
PRIMA: <path d="M17.9998 16.75C17.8398 16.75 17.6898 16.7 17.5498 16.6C17.2198 16.35 17.1498 15.88 17.3998 15.55C18.9698 13.46 18.9698 10.54 17.3998 8.45C17.1498 8.12 17.2198 7.65 17.5498 7.4C17.8798 7.15 18.3498 7.22 18.5998 7.55C20.5598 10.17 20.5598 13.83 18.5998 16.45C18.4498 16.65 18.2298 16.75 17.9998 16.75Z" fill="#FDF0D5"/>
DOPO: <path d="M17.9998 16.75C17.8398 16.75 17.6898 16.7 17.5498 16.6C17.2198 16.35 17.1498 15.88 17.3998 15.55C18.9698 13.46 18.9698 10.54 17.3998 8.45C17.1498 8.12 17.2198 7.65 17.5498 7.4C17.8798 7.15 18.3498 7.22 18.5998 7.55C20.5598 10.17 20.5598 13.83 18.5998 16.45C18.4498 16.65 18.2298 16.75 17.9998 16.75Z" fill="#fff0cc"/>
```

Riga 3
```text
PRIMA: <path d="M19.8299 19.25C19.6699 19.25 19.5199 19.2 19.3799 19.1C19.0499 18.85 18.9799 18.38 19.2299 18.05C21.8999 14.49 21.8999 9.51 19.2299 5.95C18.9799 5.62 19.0499 5.15 19.3799 4.9C19.7099 4.65 20.1799 4.72 20.4299 5.05C23.4999 9.14 23.4999 14.86 20.4299 18.95C20.2899 19.15 20.0599 19.25 19.8299 19.25Z" fill="#FDF0D5"/>
DOPO: <path d="M19.8299 19.25C19.6699 19.25 19.5199 19.2 19.3799 19.1C19.0499 18.85 18.9799 18.38 19.2299 18.05C21.8999 14.49 21.8999 9.51 19.2299 5.95C18.9799 5.62 19.0499 5.15 19.3799 4.9C19.7099 4.65 20.1799 4.72 20.4299 5.05C23.4999 9.14 23.4999 14.86 20.4299 18.95C20.2899 19.15 20.0599 19.25 19.8299 19.25Z" fill="#fff0cc"/>
```

Riga 4
```text
PRIMA: <path d="M14.02 3.78C12.9 3.16 11.47 3.32 10.01 4.23L7.09 6.06C6.89 6.18 6.66 6.25 6.43 6.25H5.5H5C2.58 6.25 1.25 7.58 1.25 10V14C1.25 16.42 2.58 17.75 5 17.75H5.5H6.43C6.66 17.75 6.89 17.82 7.09 17.94L10.01 19.77C10.89 20.32 11.75 20.59 12.55 20.59C13.07 20.59 13.57 20.47 14.02 20.22C15.13 19.6 15.75 18.31 15.75 16.59V7.41C15.75 5.69 15.13 4.4 14.02 3.78Z" fill="#FDF0D5"/>
DOPO: <path d="M14.02 3.78C12.9 3.16 11.47 3.32 10.01 4.23L7.09 6.06C6.89 6.18 6.66 6.25 6.43 6.25H5.5H5C2.58 6.25 1.25 7.58 1.25 10V14C1.25 16.42 2.58 17.75 5 17.75H5.5H6.43C6.66 17.75 6.89 17.82 7.09 17.94L10.01 19.77C10.89 20.32 11.75 20.59 12.55 20.59C13.07 20.59 13.57 20.47 14.02 20.22C15.13 19.6 15.75 18.31 15.75 16.59V7.41C15.75 5.69 15.13 4.4 14.02 3.78Z" fill="#fff0cc"/>
```

## scenes/balatro/trick_asset/ui_bisca/volume-slash.svg

Riga 2
```text
PRIMA: <path d="M17.9998 16.75C17.8398 16.75 17.6898 16.7 17.5498 16.6C17.2198 16.35 17.1498 15.88 17.3998 15.55C18.6598 13.87 18.9298 11.64 18.1198 9.71C17.9598 9.33 18.1398 8.89 18.5198 8.73C18.8998 8.57 19.3398 8.75 19.4998 9.13C20.5198 11.55 20.1698 14.36 18.5998 16.46C18.4498 16.65 18.2298 16.75 17.9998 16.75Z" fill="#FDF0D5"/>
DOPO: <path d="M17.9998 16.75C17.8398 16.75 17.6898 16.7 17.5498 16.6C17.2198 16.35 17.1498 15.88 17.3998 15.55C18.6598 13.87 18.9298 11.64 18.1198 9.71C17.9598 9.33 18.1398 8.89 18.5198 8.73C18.8998 8.57 19.3398 8.75 19.4998 9.13C20.5198 11.55 20.1698 14.36 18.5998 16.46C18.4498 16.65 18.2298 16.75 17.9998 16.75Z" fill="#fff0cc"/>
```

Riga 3
```text
PRIMA: <path d="M19.8299 19.25C19.6699 19.25 19.5199 19.2 19.3799 19.1C19.0499 18.85 18.9799 18.38 19.2299 18.05C21.3699 15.2 21.8399 11.38 20.4599 8.09C20.2999 7.71 20.4799 7.27 20.8599 7.11C21.2399 6.95 21.6799 7.13 21.8399 7.51C23.4299 11.29 22.8899 15.67 20.4299 18.95C20.2899 19.15 20.0599 19.25 19.8299 19.25Z" fill="#FDF0D5"/>
DOPO: <path d="M19.8299 19.25C19.6699 19.25 19.5199 19.2 19.3799 19.1C19.0499 18.85 18.9799 18.38 19.2299 18.05C21.3699 15.2 21.8399 11.38 20.4599 8.09C20.2999 7.71 20.4799 7.27 20.8599 7.11C21.2399 6.95 21.6799 7.13 21.8399 7.51C23.4299 11.29 22.8899 15.67 20.4299 18.95C20.2899 19.15 20.0599 19.25 19.8299 19.25Z" fill="#fff0cc"/>
```

Riga 4
```text
PRIMA: <path d="M14.04 12.96C14.67 12.33 15.75 12.78 15.75 13.67V16.6C15.75 18.32 15.13 19.61 14.02 20.23C13.57 20.48 13.07 20.6 12.55 20.6C11.75 20.6 10.89 20.33 10.01 19.78L9.36998 19.38C8.82998 19.04 8.73998 18.28 9.18998 17.83L14.04 12.96Z" fill="#FDF0D5"/>
DOPO: <path d="M14.04 12.96C14.67 12.33 15.75 12.78 15.75 13.67V16.6C15.75 18.32 15.13 19.61 14.02 20.23C13.57 20.48 13.07 20.6 12.55 20.6C11.75 20.6 10.89 20.33 10.01 19.78L9.36998 19.38C8.82998 19.04 8.73998 18.28 9.18998 17.83L14.04 12.96Z" fill="#fff0cc"/>
```

Riga 5
```text
PRIMA: <path d="M21.77 2.23C21.47 1.93 20.98 1.93 20.68 2.23L15.73 7.18C15.67 5.58 15.07 4.38 14.01 3.79C12.89 3.17 11.46 3.33 10 4.24L7.09 6.06C6.89 6.18 6.66 6.25 6.43 6.25H5.5H5C2.58 6.25 1.25 7.58 1.25 10V14C1.25 16.42 2.58 17.75 5 17.75H5.16L2.22 20.69C1.92 20.99 1.92 21.48 2.22 21.78C2.38 21.92 2.57 22 2.77 22C2.97 22 3.16 21.92 3.31 21.77L21.77 3.31C22.08 3.01 22.08 2.53 21.77 2.23Z" fill="#FDF0D5"/>
DOPO: <path d="M21.77 2.23C21.47 1.93 20.98 1.93 20.68 2.23L15.73 7.18C15.67 5.58 15.07 4.38 14.01 3.79C12.89 3.17 11.46 3.33 10 4.24L7.09 6.06C6.89 6.18 6.66 6.25 6.43 6.25H5.5H5C2.58 6.25 1.25 7.58 1.25 10V14C1.25 16.42 2.58 17.75 5 17.75H5.16L2.22 20.69C1.92 20.99 1.92 21.48 2.22 21.78C2.38 21.92 2.57 22 2.77 22C2.97 22 3.16 21.92 3.31 21.77L21.77 3.31C22.08 3.01 22.08 2.53 21.77 2.23Z" fill="#fff0cc"/>
```

## scenes/button_fill_animate/hold_button.gd

Riga 14
```text
PRIMA: @export var base_color := Color("474660")
DOPO: @export var base_color := Color("214f50")
```

Riga 15
```text
PRIMA: @export var fill_color := Color("74ab8e")
DOPO: @export var fill_color := Color("347667")
```

Riga 16
```text
PRIMA: @export var hover_color := Color("74ab8e")
DOPO: @export var hover_color := Color("347667")
```

Riga 21
```text
PRIMA: @export var confirm_progress_color := Color("74ab8e")
DOPO: @export var confirm_progress_color := Color("347667")
```

## Patch di ripristino dei soli colori

Estrarre la patch seguente e controllarla con git apply --check --unidiff-zero prima di applicarla con git apply --unidiff-zero. Non sovrascrive interi file.

```diff
--- a/scenes/balatro/scripts/button_shadow.gd
+++ b/scenes/balatro/scripts/button_shadow.gd
@@ -4,1 +4,1 @@
-const SHADOW_COLOR := Color("153536")
+const SHADOW_COLOR := Color("14213d")
--- a/scenes/balatro/scripts/card.gd
+++ b/scenes/balatro/scripts/card.gd
@@ -34,1 +34,1 @@
-	joker_arrow.color = Color("42c985") if high else Color("e85d68")
+	joker_arrow.color = Color("35c96a") if high else Color("ed4242")
--- a/scenes/balatro/scripts/card_info.gd
+++ b/scenes/balatro/scripts/card_info.gd
@@ -19,1 +19,1 @@
-	shade.color = Color(0.082353, 0.207843, 0.211765, 0.75)
+	shade.color = Color(0.19, 0.19, 0.27, 0.75)
--- a/scenes/balatro/scripts/game_overlay.gd
+++ b/scenes/balatro/scripts/game_overlay.gd
@@ -54,1 +54,1 @@
-	overlay_shade.color = Color(0.082353, 0.207843, 0.211765, 0.55)
+	overlay_shade.color = Color(0.025, 0.06, 0.035, 0.55)
--- a/scenes/balatro/scripts/lexispell_background.gd
+++ b/scenes/balatro/scripts/lexispell_background.gd
@@ -15,1 +15,1 @@
-	color = Color(0.156863, 0.560784, 0.392157, 1)
+	color = Color(0.341176, 0.509804, 0.423529, 1)
@@ -19,1 +19,1 @@
-	stars.color = Color(0.329412, 0.729412, 0.474510, 1)
+	stars.color = Color(0.454902, 0.670588, 0.556863, 1)
--- a/scenes/balatro/scripts/lexispell_style.gd
+++ b/scenes/balatro/scripts/lexispell_style.gd
@@ -4,1 +4,1 @@
-const NORMAL := Color("214f50")
+const NORMAL := Color("474660")
@@ -5,1 +5,1 @@
-const HOVER := Color("347667")
+const HOVER := Color("74ab8e")
@@ -6,1 +6,1 @@
-const TEXT := Color("fff0cc")
+const TEXT := Color("fde4b9")
@@ -7,1 +7,1 @@
-const SHADOW := Color("153536")
+const SHADOW := Color("313145")
@@ -8,1 +8,1 @@
-const DISABLED := Color(0.345098, 0.435294, 0.4)
+const DISABLED := Color(0.38, 0.38, 0.38)
@@ -9,1 +9,1 @@
-const DISABLED_TEXT := Color(0.760784, 0.792157, 0.733333)
+const DISABLED_TEXT := Color(0.65, 0.65, 0.65)
@@ -24,1 +24,1 @@
-		style.shadow_color = Color(0.203922, 0.301961, 0.278431) if color == DISABLED else SHADOW
+		style.shadow_color = Color(0.27, 0.27, 0.27) if color == DISABLED else SHADOW
@@ -25,1 +25,1 @@
-		if color == Color(0.909804, 0.364706, 0.407843):
+		if color == Color(0.89, 0.3204, 0.3204):
@@ -26,1 +26,1 @@
-			style.shadow_color = Color(0.623529, 0.207843, 0.290196)
+			style.shadow_color = Color(0.69, 0.2484, 0.2484)
--- a/scenes/balatro/scripts/loading_transition.gd
+++ b/scenes/balatro/scripts/loading_transition.gd
@@ -36,1 +36,1 @@
-	material.set_shader_parameter("base_color", Color("214f50"))
+	material.set_shader_parameter("base_color", Color("474660"))
@@ -58,1 +58,1 @@
-	caption.add_theme_color_override("default_color", Color("fff0cc"))
+	caption.add_theme_color_override("default_color", Color("fde4b9"))
@@ -59,1 +59,1 @@
-	caption.add_theme_color_override("font_outline_color", Color("347667"))
+	caption.add_theme_color_override("font_outline_color", Color("74ab8e"))
@@ -61,1 +61,1 @@
-	caption.add_theme_color_override("font_shadow_color", Color("214f50"))
+	caption.add_theme_color_override("font_shadow_color", Color("474660"))
--- a/scenes/balatro/scripts/main_menu.gd
+++ b/scenes/balatro/scripts/main_menu.gd
@@ -25,1 +25,1 @@
-const BUTTON_RED := Color(0.909804, 0.364706, 0.407843)
+const BUTTON_RED := Color(0.89, 0.3204, 0.3204)
@@ -125,1 +125,1 @@
-			profile_button.draw_circle(Vector2(130, 130), 127, Color("e5e8d8"), true, -1, true)
+			profile_button.draw_circle(Vector2(130, 130), 127, Color("d9d9d9"), true, -1, true)
@@ -260,1 +260,1 @@
-	label.add_theme_color_override("font_color", Color("214f50"))
+	label.add_theme_color_override("font_color", Color("474660"))
@@ -290,1 +290,1 @@
-		outer.add_theme_color_override("font_color", Color("214f50"))
+		outer.add_theme_color_override("font_color", Color("474660"))
@@ -291,1 +291,1 @@
-		outer.add_theme_color_override("font_outline_color", Color("fff0cc"))
+		outer.add_theme_color_override("font_outline_color", Color("fde4b9"))
@@ -301,1 +301,1 @@
-		inner.add_theme_color_override("font_color", Color("214f50"))
+		inner.add_theme_color_override("font_color", Color("474660"))
@@ -302,1 +302,1 @@
-		inner.add_theme_color_override("font_outline_color", Color("fff0cc"))
+		inner.add_theme_color_override("font_outline_color", Color("fde4b9"))
@@ -322,1 +322,1 @@
-	style.bg_color = Color("fff0cc")
+	style.bg_color = Color("fde4b9")
@@ -323,1 +323,1 @@
-	style.border_color = Color("214f50")
+	style.border_color = Color("263d30")
@@ -331,1 +331,1 @@
-	input.add_theme_color_override("font_color", Color("214f50"))
+	input.add_theme_color_override("font_color", Color("474660"))
@@ -332,1 +332,1 @@
-	input.add_theme_color_override("font_placeholder_color", Color("65756b"))
+	input.add_theme_color_override("font_placeholder_color", Color("777b72"))
@@ -333,1 +333,1 @@
-	input.add_theme_color_override("caret_color", Color("214f50"))
+	input.add_theme_color_override("caret_color", Color("474660"))
--- a/scenes/balatro/scripts/match_controller.gd
+++ b/scenes/balatro/scripts/match_controller.gd
@@ -241,1 +241,1 @@
-	label.add_theme_color_override("default_color", Color("153536"))
+	label.add_theme_color_override("default_color", Color("19271f"))
@@ -242,1 +242,1 @@
-	label.add_theme_color_override("font_color", Color("153536"))
+	label.add_theme_color_override("font_color", Color("19271f"))
@@ -273,1 +273,1 @@
-	turn_clock.add_theme_color_override("font_color", Color("fff0cc"))
+	turn_clock.add_theme_color_override("font_color", Color("fde4b9"))
@@ -289,1 +289,1 @@
-	damage_shade.color = Color(0.082353, 0.207843, 0.211765, 0.65)
+	damage_shade.color = Color(0.02, 0.03, 0.04, 0.65)
@@ -343,1 +343,1 @@
-	button.fill_color = Color("347667")
+	button.fill_color = Color("74ab8e")
--- a/scenes/balatro/scripts/mixed_label.gd
+++ b/scenes/balatro/scripts/mixed_label.gd
@@ -9,1 +9,1 @@
-	add_theme_color_override("default_color", Color("214f50"))
+	add_theme_color_override("default_color", Color("474660"))
@@ -17,1 +17,1 @@
-	add_theme_color_override("default_color", Color("214f50"))
+	add_theme_color_override("default_color", Color("474660"))
--- a/scenes/balatro/scripts/network_lobby.gd
+++ b/scenes/balatro/scripts/network_lobby.gd
@@ -250,1 +250,1 @@
-				avatar.draw_circle(avatar.size / 2.0, 20, Color("e5e8d8"), true, -1, true)
+				avatar.draw_circle(avatar.size / 2.0, 20, Color("d9d9d9"), true, -1, true)
--- a/scenes/balatro/scripts/pause_menu.gd
+++ b/scenes/balatro/scripts/pause_menu.gd
@@ -24,1 +24,1 @@
-	shade.color = Color(0.082353, 0.207843, 0.211765, 0.85)
+	shade.color = Color(0.19, 0.19, 0.27, 0.85)
@@ -60,1 +60,1 @@
-	quit_button.add_theme_stylebox_override("normal", Style.button_style(Color(0.909804, 0.364706, 0.407843)))
+	quit_button.add_theme_stylebox_override("normal", Style.button_style(Color(0.89, 0.3204, 0.3204)))
--- a/scenes/balatro/scripts/player_badge.gd
+++ b/scenes/balatro/scripts/player_badge.gd
@@ -10,1 +10,1 @@
-const NAME_TEXT_COLOR := Color("fff0cc")
+const NAME_TEXT_COLOR := Color("fde4b9")
@@ -11,1 +11,1 @@
-const NAME_OUTLINE_COLOR := Color("347667")
+const NAME_OUTLINE_COLOR := Color("74ab8e")
@@ -12,1 +12,1 @@
-const NAME_SHADOW_COLOR := Color("214f50")
+const NAME_SHADOW_COLOR := Color("474660")
@@ -146,1 +146,1 @@
-		draw_string_outline(draw_font, position_value, value, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, 3, Color("fff0cc"))
+		draw_string_outline(draw_font, position_value, value, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, 3, Color("fde4b9"))
@@ -154,1 +154,1 @@
-		frame.bg_color = Color(0.964706, 0.784314, 0.372549, 0.48)
+		frame.bg_color = Color(0.79, 0.985, 0.51, 0.48)
@@ -155,1 +155,1 @@
-		frame.border_color = Color("fff0cc00")
+		frame.border_color = Color("fde4b900")
@@ -158,1 +158,1 @@
-		frame.shadow_color = Color(0.964706, 0.784314, 0.372549, 0.827)
+		frame.shadow_color = Color(0.333, 0.882, 0.0, 0.827)
@@ -164,1 +164,1 @@
-	draw_circle(avatar, 56, Color("e5e8d8"), true, -1, true)
+	draw_circle(avatar, 56, Color("d9d9d9"), true, -1, true)
@@ -179,1 +179,1 @@
-	draw_string(COUNTER_FONT, baseline, number_text, HORIZONTAL_ALIGNMENT_LEFT, -1, number_size, Color("fff0cc"))
+	draw_string(COUNTER_FONT, baseline, number_text, HORIZONTAL_ALIGNMENT_LEFT, -1, number_size, Color("fde4b9"))
@@ -182,1 +182,1 @@
-	prediction_box.bg_color = Color("214f50")
+	prediction_box.bg_color = Color("474660")
@@ -185,1 +185,1 @@
-	prediction_shadow.bg_color = Color("153536")
+	prediction_shadow.bg_color = Color("313145")
@@ -193,1 +193,1 @@
-		_text(Vector2(125, 169), "/", 16, Color("fff0cc"), COUNTER_FONT, false)
+		_text(Vector2(125, 169), "/", 16, Color("fde4b9"), COUNTER_FONT, false)
@@ -194,1 +194,1 @@
-		_text(Vector2(143, 169), str(prediction), 24, Color("fff0cc"), KIDS_FONT, false)
+		_text(Vector2(143, 169), str(prediction), 24, Color("fde4b9"), KIDS_FONT, false)
@@ -196,1 +196,1 @@
-			_text(Vector2(107, 169), str(taken), 24, Color("fff0cc"), KIDS_FONT, false)
+			_text(Vector2(107, 169), str(taken), 24, Color("fde4b9"), KIDS_FONT, false)
--- a/scenes/balatro/scripts/profile_picker.gd
+++ b/scenes/balatro/scripts/profile_picker.gd
@@ -53,1 +53,1 @@
-	blank.fill(Color("e5e8d8"))
+	blank.fill(Color("d9d9d9"))
--- a/scenes/balatro/scripts/profile_picker.js
+++ b/scenes/balatro/scripts/profile_picker.js
@@ -18,1 +18,1 @@
-      root.style.cssText = 'position:fixed;inset:0;z-index:1000;background:#153536bb;display:grid;place-items:center;padding:12px;box-sizing:border-box;touch-action:auto;';
+      root.style.cssText = 'position:fixed;inset:0;z-index:1000;background:#313145bb;display:grid;place-items:center;padding:12px;box-sizing:border-box;touch-action:auto;';
@@ -20,1 +20,1 @@
-        .bisca-profile{background:#214f50;color:#fff0cc;border:3px solid #347667;border-radius:22px;box-shadow:5px 6px #153536;padding:22px;box-sizing:border-box;width:min(520px,94vw);max-height:94dvh;overflow:auto;text-align:center;font:700 17px system-ui;touch-action:auto}
+        .bisca-profile{background:#474660;color:#fde4b9;border:3px solid #74ab8e;border-radius:22px;box-shadow:5px 6px #313145;padding:22px;box-sizing:border-box;width:min(520px,94vw);max-height:94dvh;overflow:auto;text-align:center;font:700 17px system-ui;touch-action:auto}
@@ -21,1 +21,1 @@
-        .bisca-profile [hidden]{display:none!important}.bisca-profile h2{margin:0 0 8px;font-size:25px}.bisca-profile p{margin:10px 0}.bisca-profile button{font:inherit;border:2px solid transparent;border-radius:14px;background:#347667;color:#fff0cc;padding:12px 18px;cursor:pointer;box-shadow:3px 4px #153536;touch-action:manipulation}
+        .bisca-profile [hidden]{display:none!important}.bisca-profile h2{margin:0 0 8px;font-size:25px}.bisca-profile p{margin:10px 0}.bisca-profile button{font:inherit;border:2px solid transparent;border-radius:14px;background:#74ab8e;color:#fde4b9;padding:12px 18px;cursor:pointer;box-shadow:3px 4px #313145;touch-action:manipulation}
@@ -22,1 +22,1 @@
-        .bisca-profile button:hover{border-color:#fff0cc}.bisca-profile button:disabled{opacity:.5;cursor:default}.bisca-profile .photo{display:block;margin:14px auto;width:128px;height:128px;border-radius:50%;border:3px solid #153536;background:#e5e8d8;padding:0;overflow:hidden;color:#214f50;font-size:40px;box-shadow:none}.bisca-profile .photo img{width:100%;height:100%;object-fit:cover}.bisca-profile .choices{display:flex;gap:12px;justify-content:center;flex-wrap:wrap}.bisca-profile small{font-weight:400;display:block;margin:12px 0}.bisca-profile video{width:160px;height:160px;object-fit:cover;border-radius:50%}
+        .bisca-profile button:hover{border-color:#fde4b9}.bisca-profile button:disabled{opacity:.5;cursor:default}.bisca-profile .photo{display:block;margin:14px auto;width:128px;height:128px;border-radius:50%;border:3px solid #313145;background:#d9d9d9;padding:0;overflow:hidden;color:#474660;font-size:40px;box-shadow:none}.bisca-profile .photo img{width:100%;height:100%;object-fit:cover}.bisca-profile .choices{display:flex;gap:12px;justify-content:center;flex-wrap:wrap}.bisca-profile small{font-weight:400;display:block;margin:12px 0}.bisca-profile video{width:160px;height:160px;object-fit:cover;border-radius:50%}
@@ -44,1 +44,1 @@
-        const ctx = canvas.getContext('2d'); ctx.fillStyle='#e5e8d8'; ctx.fillRect(0,0,192,192);
+        const ctx = canvas.getContext('2d'); ctx.fillStyle='#d9d9d9'; ctx.fillRect(0,0,192,192);
--- a/scenes/balatro/scripts/voice_transport.js
+++ b/scenes/balatro/scripts/voice_transport.js
@@ -25,1 +25,1 @@
-      root.style.cssText='position:fixed;inset:0;z-index:2147483647;background:#153536aa;display:grid;place-items:center;padding:12px;box-sizing:border-box';
+      root.style.cssText='position:fixed;inset:0;z-index:2147483647;background:#14213daa;display:grid;place-items:center;padding:12px;box-sizing:border-box';
@@ -26,1 +26,1 @@
-      root.innerHTML=`<section role="dialog" aria-modal="true" aria-label="Chat vocale" style="box-sizing:border-box;width:min(480px,100%);max-height:90dvh;overflow:auto;background:#214f50;color:#fff0cc;border:3px solid #347667;border-radius:22px;padding:22px;font:600 16px system-ui"><h2 style="margin-top:0">CHAT VOCALE</h2><p>Premi ATTIVA AUDIO e consenti l'accesso nel browser. Anche i tuoi amici devono attivarla.</p><p data-status role="status"></p><div data-actions style="display:flex;gap:10px;flex-wrap:wrap"></div><div data-people></div><p style="font-size:13px">La partita continua mentre questo pannello e' aperto. Chiudere il pannello non spegne il microfono.</p></section>`;
+      root.innerHTML=`<section role="dialog" aria-modal="true" aria-label="Chat vocale" style="box-sizing:border-box;width:min(480px,100%);max-height:90dvh;overflow:auto;background:#48465f;color:#fde4b9;border:3px solid #74ab8e;border-radius:22px;padding:22px;font:600 16px system-ui"><h2 style="margin-top:0">CHAT VOCALE</h2><p>Premi ATTIVA AUDIO e consenti l'accesso nel browser. Anche i tuoi amici devono attivarla.</p><p data-status role="status"></p><div data-actions style="display:flex;gap:10px;flex-wrap:wrap"></div><div data-people></div><p style="font-size:13px">La partita continua mentre questo pannello e' aperto. Chiudere il pannello non spegne il microfono.</p></section>`;
@@ -28,1 +28,1 @@
-      const button=(text,action)=>{const b=document.createElement('button');b.textContent=text;b.style.cssText='border:2px solid #fff0cc;border-radius:14px;padding:12px;background:#347667;color:#153536;font:bold 15px system-ui;cursor:pointer';b.onclick=action;actions.appendChild(b);return b;};
+      const button=(text,action)=>{const b=document.createElement('button');b.textContent=text;b.style.cssText='border:2px solid #fde4b9;border-radius:14px;padding:12px;background:#74ab8e;color:#14213d;font:bold 15px system-ui;cursor:pointer';b.onclick=action;actions.appendChild(b);return b;};
@@ -55,1 +55,1 @@
-        const slider=document.createElement('input');slider.type='range';slider.min='0';slider.max='100';slider.value=String((this.volumes.get(id)??1)*100);slider.style.cssText='display:block;width:100%;accent-color:#347667';slider.setAttribute('aria-label',`Volume ${person.name || 'giocatore'}`);
+        const slider=document.createElement('input');slider.type='range';slider.min='0';slider.max='100';slider.value=String((this.volumes.get(id)??1)*100);slider.style.cssText='display:block;width:100%;accent-color:#74ab8e';slider.setAttribute('aria-label',`Volume ${person.name || 'giocatore'}`);
--- a/scenes/balatro/visuals/settings_knob.svg
+++ b/scenes/balatro/visuals/settings_knob.svg
@@ -1,1 +1,1 @@
-<svg xmlns="http://www.w3.org/2000/svg" width="28" height="28" viewBox="0 0 28 28"><circle cx="14" cy="14" r="11" fill="#fff0cc"/></svg>
+<svg xmlns="http://www.w3.org/2000/svg" width="28" height="28" viewBox="0 0 28 28"><circle cx="14" cy="14" r="11" fill="#fde4b9"/></svg>
--- a/scenes/balatro/visuals/settings_knob_hover.svg
+++ b/scenes/balatro/visuals/settings_knob_hover.svg
@@ -1,1 +1,1 @@
-<svg xmlns="http://www.w3.org/2000/svg" width="32" height="32" viewBox="0 0 32 32"><circle cx="16" cy="16" r="14" fill="#fff0cc" stroke="#347667" stroke-width="3"/></svg>
+<svg xmlns="http://www.w3.org/2000/svg" width="32" height="32" viewBox="0 0 32 32"><circle cx="16" cy="16" r="14" fill="#fde4b9" stroke="#74ab8e" stroke-width="3"/></svg>
--- a/scenes/balatro/visuals/settings_toggle_off.svg
+++ b/scenes/balatro/visuals/settings_toggle_off.svg
@@ -1,1 +1,1 @@
-<svg xmlns="http://www.w3.org/2000/svg" width="70" height="36" viewBox="0 0 70 36"><rect x="2" y="3" width="66" height="30" rx="12" fill="#153536"/><rect x="5" y="5" width="27" height="26" rx="9" fill="#fff0cc"/></svg>
+<svg xmlns="http://www.w3.org/2000/svg" width="70" height="36" viewBox="0 0 70 36"><rect x="2" y="3" width="66" height="30" rx="12" fill="#313145"/><rect x="5" y="5" width="27" height="26" rx="9" fill="#fde4b9"/></svg>
--- a/scenes/balatro/visuals/settings_toggle_on.svg
+++ b/scenes/balatro/visuals/settings_toggle_on.svg
@@ -1,1 +1,1 @@
-<svg xmlns="http://www.w3.org/2000/svg" width="70" height="36" viewBox="0 0 70 36"><rect x="2" y="3" width="66" height="30" rx="12" fill="#347667"/><rect x="38" y="5" width="27" height="26" rx="9" fill="#fff0cc"/></svg>
+<svg xmlns="http://www.w3.org/2000/svg" width="70" height="36" viewBox="0 0 70 36"><rect x="2" y="3" width="66" height="30" rx="12" fill="#74ab8e"/><rect x="38" y="5" width="27" height="26" rx="9" fill="#fde4b9"/></svg>
--- a/scenes/balatro/trick_asset/ui_bisca/arrow-left.svg
+++ b/scenes/balatro/trick_asset/ui_bisca/arrow-left.svg
@@ -2,1 +2,1 @@
-<path d="M15.1 4.85C15.73 4.85 16.32 5 16.84 5.3C18.07 6.01 18.75 7.44 18.75 9.32V14.67C18.75 16.55 18.07 17.98 16.84 18.69C15.61 19.4 14.04 19.27 12.4 18.33L7.77 15.66C6.14 14.72 5.24 13.42 5.24 12C5.24 10.58 6.14 9.28 7.77 8.34L12.4 5.67C13.34 5.12 14.26 4.85 15.1 4.85ZM15.1 17.64C15.47 17.64 15.81 17.56 16.1 17.39C16.84 16.96 17.25 16 17.25 14.67V9.33C17.25 8.01 16.84 7.04 16.09 6.61C15.34 6.18 14.3 6.31 13.15 6.97L8.52 9.64C7.37 10.3 6.74 11.14 6.74 12C6.74 12.86 7.37 13.7 8.52 14.36L13.15 17.03C13.86 17.44 14.52 17.64 15.1 17.64Z" fill="#fff0cc"/>
+<path d="M15.1 4.85C15.73 4.85 16.32 5 16.84 5.3C18.07 6.01 18.75 7.44 18.75 9.32V14.67C18.75 16.55 18.07 17.98 16.84 18.69C15.61 19.4 14.04 19.27 12.4 18.33L7.77 15.66C6.14 14.72 5.24 13.42 5.24 12C5.24 10.58 6.14 9.28 7.77 8.34L12.4 5.67C13.34 5.12 14.26 4.85 15.1 4.85ZM15.1 17.64C15.47 17.64 15.81 17.56 16.1 17.39C16.84 16.96 17.25 16 17.25 14.67V9.33C17.25 8.01 16.84 7.04 16.09 6.61C15.34 6.18 14.3 6.31 13.15 6.97L8.52 9.64C7.37 10.3 6.74 11.14 6.74 12C6.74 12.86 7.37 13.7 8.52 14.36L13.15 17.03C13.86 17.44 14.52 17.64 15.1 17.64Z" fill="#FDF0D5"/>
@@ -3,1 +3,1 @@
-<path d="M17 16.7429V7.35396C17 6.68115 16.349 6.20032 15.7059 6.39818L10.7236 7.9312C10.5765 7.97646 10.4419 8.05504 10.3301 8.16084L6.76885 11.5329C6.35152 11.928 6.35237 12.5928 6.77071 12.9869L10.3029 16.3144C10.432 16.4359 10.591 16.521 10.7638 16.5609L15.7751 17.7173C16.4018 17.8619 17 17.386 17 16.7429Z" fill="#fff0cc" stroke="#fff0cc"/>
+<path d="M17 16.7429V7.35396C17 6.68115 16.349 6.20032 15.7059 6.39818L10.7236 7.9312C10.5765 7.97646 10.4419 8.05504 10.3301 8.16084L6.76885 11.5329C6.35152 11.928 6.35237 12.5928 6.77071 12.9869L10.3029 16.3144C10.432 16.4359 10.591 16.521 10.7638 16.5609L15.7751 17.7173C16.4018 17.8619 17 17.386 17 16.7429Z" fill="#FDF0D5" stroke="#FDF0D5"/>
--- a/scenes/balatro/trick_asset/ui_bisca/arrow-right.svg
+++ b/scenes/balatro/trick_asset/ui_bisca/arrow-right.svg
@@ -2,1 +2,1 @@
-<path d="M8.9 19.15C8.27 19.15 7.68 19 7.16 18.7C5.93 17.99 5.25 16.56 5.25 14.68V9.33C5.25 7.45 5.93 6.02 7.16 5.31C8.39 4.6 9.96 4.73 11.6 5.67L16.23 8.34C17.86 9.28 18.76 10.58 18.76 12C18.76 13.42 17.86 14.72 16.23 15.66L11.6 18.33C10.66 18.88 9.74 19.15 8.9 19.15ZM8.9 6.36C8.53 6.36 8.19 6.44 7.9 6.61C7.16 7.04 6.75 8 6.75 9.33V14.67C6.75 15.99 7.16 16.96 7.91 17.39C8.66 17.82 9.7 17.69 10.85 17.03L15.48 14.36C16.63 13.7 17.26 12.86 17.26 12C17.26 11.14 16.63 10.3 15.48 9.64L10.85 6.97C10.14 6.56 9.48 6.36 8.9 6.36Z" fill="#fff0cc"/>
+<path d="M8.9 19.15C8.27 19.15 7.68 19 7.16 18.7C5.93 17.99 5.25 16.56 5.25 14.68V9.33C5.25 7.45 5.93 6.02 7.16 5.31C8.39 4.6 9.96 4.73 11.6 5.67L16.23 8.34C17.86 9.28 18.76 10.58 18.76 12C18.76 13.42 17.86 14.72 16.23 15.66L11.6 18.33C10.66 18.88 9.74 19.15 8.9 19.15ZM8.9 6.36C8.53 6.36 8.19 6.44 7.9 6.61C7.16 7.04 6.75 8 6.75 9.33V14.67C6.75 15.99 7.16 16.96 7.91 17.39C8.66 17.82 9.7 17.69 10.85 17.03L15.48 14.36C16.63 13.7 17.26 12.86 17.26 12C17.26 11.14 16.63 10.3 15.48 9.64L10.85 6.97C10.14 6.56 9.48 6.36 8.9 6.36Z" fill="#FDF0D5"/>
@@ -3,1 +3,1 @@
-<path d="M7 7.25705V16.646C7 17.3188 7.65103 17.7997 8.29409 17.6018L13.2764 16.0688C13.4235 16.0235 13.5581 15.945 13.6699 15.8392L17.2311 12.4671C17.6485 12.072 17.6476 11.4072 17.2293 11.0131L13.6971 7.68563C13.568 7.56406 13.409 7.47899 13.2362 7.43913L8.22486 6.28266C7.59824 6.13806 7 6.61397 7 7.25705Z" fill="#fff0cc" stroke="#fff0cc"/>
+<path d="M7 7.25705V16.646C7 17.3188 7.65103 17.7997 8.29409 17.6018L13.2764 16.0688C13.4235 16.0235 13.5581 15.945 13.6699 15.8392L17.2311 12.4671C17.6485 12.072 17.6476 11.4072 17.2293 11.0131L13.6971 7.68563C13.568 7.56406 13.409 7.47899 13.2362 7.43913L8.22486 6.28266C7.59824 6.13806 7 6.61397 7 7.25705Z" fill="#FDF0D5" stroke="#FDF0D5"/>
--- a/scenes/balatro/trick_asset/ui_bisca/copy-success.svg
+++ b/scenes/balatro/trick_asset/ui_bisca/copy-success.svg
@@ -2,1 +2,1 @@
-<path d="M17.0998 2H12.8998C9.81668 2 8.37074 3.09409 8.06951 5.73901C8.00649 6.29235 8.46476 6.75 9.02167 6.75H11.0998C15.2998 6.75 17.2498 8.7 17.2498 12.9V14.9781C17.2498 15.535 17.7074 15.9933 18.2608 15.9303C20.9057 15.629 21.9998 14.1831 21.9998 11.1V6.9C21.9998 3.4 20.5998 2 17.0998 2Z" fill="#fff0cc"/>
+<path d="M17.0998 2H12.8998C9.81668 2 8.37074 3.09409 8.06951 5.73901C8.00649 6.29235 8.46476 6.75 9.02167 6.75H11.0998C15.2998 6.75 17.2498 8.7 17.2498 12.9V14.9781C17.2498 15.535 17.7074 15.9933 18.2608 15.9303C20.9057 15.629 21.9998 14.1831 21.9998 11.1V6.9C21.9998 3.4 20.5998 2 17.0998 2Z" fill="#FDF0D5"/>
@@ -3,1 +3,1 @@
-<path d="M11.1 8H6.9C3.4 8 2 9.4 2 12.9V17.1C2 20.6 3.4 22 6.9 22H11.1C14.6 22 16 20.6 16 17.1V12.9C16 9.4 14.6 8 11.1 8ZM12.29 13.65L8.58 17.36C8.44 17.5 8.26 17.57 8.07 17.57C7.88 17.57 7.7 17.5 7.56 17.36L5.7 15.5C5.42 15.22 5.42 14.77 5.7 14.49C5.98 14.21 6.43 14.21 6.71 14.49L8.06 15.84L11.27 12.63C11.55 12.35 12 12.35 12.28 12.63C12.56 12.91 12.57 13.37 12.29 13.65Z" fill="#fff0cc"/>
+<path d="M11.1 8H6.9C3.4 8 2 9.4 2 12.9V17.1C2 20.6 3.4 22 6.9 22H11.1C14.6 22 16 20.6 16 17.1V12.9C16 9.4 14.6 8 11.1 8ZM12.29 13.65L8.58 17.36C8.44 17.5 8.26 17.57 8.07 17.57C7.88 17.57 7.7 17.5 7.56 17.36L5.7 15.5C5.42 15.22 5.42 14.77 5.7 14.49C5.98 14.21 6.43 14.21 6.71 14.49L8.06 15.84L11.27 12.63C11.55 12.35 12 12.35 12.28 12.63C12.56 12.91 12.57 13.37 12.29 13.65Z" fill="#FDF0D5"/>
--- a/scenes/balatro/trick_asset/ui_bisca/copy.svg
+++ b/scenes/balatro/trick_asset/ui_bisca/copy.svg
@@ -2,1 +2,1 @@
-<path d="M16 12.9V17.1C16 20.6 14.6 22 11.1 22H6.9C3.4 22 2 20.6 2 17.1V12.9C2 9.4 3.4 8 6.9 8H11.1C14.6 8 16 9.4 16 12.9Z" fill="#fff0cc"/>
+<path d="M16 12.9V17.1C16 20.6 14.6 22 11.1 22H6.9C3.4 22 2 20.6 2 17.1V12.9C2 9.4 3.4 8 6.9 8H11.1C14.6 8 16 9.4 16 12.9Z" fill="#FDF0D5"/>
@@ -3,1 +3,1 @@
-<path d="M17.0998 2H12.8998C9.81668 2 8.37074 3.09409 8.06951 5.73901C8.00649 6.29235 8.46476 6.75 9.02167 6.75H11.0998C15.2998 6.75 17.2498 8.7 17.2498 12.9V14.9781C17.2498 15.535 17.7074 15.9933 18.2608 15.9303C20.9057 15.629 21.9998 14.1831 21.9998 11.1V6.9C21.9998 3.4 20.5998 2 17.0998 2Z" fill="#fff0cc"/>
+<path d="M17.0998 2H12.8998C9.81668 2 8.37074 3.09409 8.06951 5.73901C8.00649 6.29235 8.46476 6.75 9.02167 6.75H11.0998C15.2998 6.75 17.2498 8.7 17.2498 12.9V14.9781C17.2498 15.535 17.7074 15.9933 18.2608 15.9303C20.9057 15.629 21.9998 14.1831 21.9998 11.1V6.9C21.9998 3.4 20.5998 2 17.0998 2Z" fill="#FDF0D5"/>
--- a/scenes/balatro/trick_asset/ui_bisca/edit.svg
+++ b/scenes/balatro/trick_asset/ui_bisca/edit.svg
@@ -2,1 +2,1 @@
-<path d="M19.0201 5.48C17.0801 3.54 15.1801 3.49 13.1901 5.48L11.9801 6.69C11.8801 6.79 11.8401 6.95 11.8801 7.09C12.6401 9.74 14.7601 11.86 17.4101 12.62C17.4501 12.63 17.4901 12.64 17.5301 12.64C17.6401 12.64 17.7401 12.6 17.8201 12.52L19.0201 11.31C20.0101 10.33 20.4901 9.38 20.4901 8.42C20.5001 7.43 20.0201 6.47 19.0201 5.48Z" fill="#fff0cc"/>
+<path d="M19.0201 5.48C17.0801 3.54 15.1801 3.49 13.1901 5.48L11.9801 6.69C11.8801 6.79 11.8401 6.95 11.8801 7.09C12.6401 9.74 14.7601 11.86 17.4101 12.62C17.4501 12.63 17.4901 12.64 17.5301 12.64C17.6401 12.64 17.7401 12.6 17.8201 12.52L19.0201 11.31C20.0101 10.33 20.4901 9.38 20.4901 8.42C20.5001 7.43 20.0201 6.47 19.0201 5.48Z" fill="#FDF0D5"/>
@@ -3,1 +3,1 @@
-<path d="M15.6098 13.53C15.3198 13.39 15.0398 13.25 14.7698 13.09C14.5498 12.96 14.3398 12.82 14.1298 12.67C13.9598 12.56 13.7598 12.4 13.5698 12.24C13.5498 12.23 13.4798 12.17 13.3998 12.09C13.0698 11.81 12.6998 11.45 12.3698 11.05C12.3398 11.03 12.2898 10.96 12.2198 10.87C12.1198 10.75 11.9498 10.55 11.7998 10.32C11.6798 10.17 11.5398 9.95 11.4098 9.73C11.2498 9.46 11.1098 9.19 10.9698 8.91C10.9486 8.8646 10.9281 8.81944 10.9083 8.77454C10.7607 8.44122 10.3261 8.34377 10.0683 8.60153L4.33983 14.33C4.20983 14.46 4.08983 14.71 4.05983 14.88L3.51983 18.71C3.41983 19.39 3.60983 20.03 4.02983 20.46C4.38983 20.81 4.88983 21 5.42983 21C5.54983 21 5.66983 20.99 5.78983 20.97L9.62983 20.43C9.80983 20.4 10.0598 20.28 10.1798 20.15L15.9011 14.4287C16.1607 14.1691 16.0628 13.7237 15.7252 13.5796C15.6872 13.5634 15.6488 13.5469 15.6098 13.53Z" fill="#fff0cc"/>
+<path d="M15.6098 13.53C15.3198 13.39 15.0398 13.25 14.7698 13.09C14.5498 12.96 14.3398 12.82 14.1298 12.67C13.9598 12.56 13.7598 12.4 13.5698 12.24C13.5498 12.23 13.4798 12.17 13.3998 12.09C13.0698 11.81 12.6998 11.45 12.3698 11.05C12.3398 11.03 12.2898 10.96 12.2198 10.87C12.1198 10.75 11.9498 10.55 11.7998 10.32C11.6798 10.17 11.5398 9.95 11.4098 9.73C11.2498 9.46 11.1098 9.19 10.9698 8.91C10.9486 8.8646 10.9281 8.81944 10.9083 8.77454C10.7607 8.44122 10.3261 8.34377 10.0683 8.60153L4.33983 14.33C4.20983 14.46 4.08983 14.71 4.05983 14.88L3.51983 18.71C3.41983 19.39 3.60983 20.03 4.02983 20.46C4.38983 20.81 4.88983 21 5.42983 21C5.54983 21 5.66983 20.99 5.78983 20.97L9.62983 20.43C9.80983 20.4 10.0598 20.28 10.1798 20.15L15.9011 14.4287C16.1607 14.1691 16.0628 13.7237 15.7252 13.5796C15.6872 13.5634 15.6488 13.5469 15.6098 13.53Z" fill="#FDF0D5"/>
--- a/scenes/balatro/trick_asset/ui_bisca/moon.svg
+++ b/scenes/balatro/trick_asset/ui_bisca/moon.svg
@@ -2,1 +2,1 @@
-<path d="M21.5302 15.93C21.3702 15.66 20.9202 15.24 19.8002 15.44C19.1802 15.55 18.5502 15.6 17.9202 15.57C15.5902 15.47 13.4802 14.4 12.0102 12.75C10.7102 11.3 9.9102 9.40999 9.9002 7.36999C9.9002 6.22999 10.1202 5.12999 10.5702 4.08999C11.0102 3.07999 10.7002 2.54999 10.4802 2.32999C10.2502 2.09999 9.7102 1.77999 8.6502 2.21999C4.5602 3.93999 2.0302 8.03999 2.3302 12.43C2.6302 16.56 5.5302 20.09 9.3702 21.42C10.2902 21.74 11.2602 21.93 12.2602 21.97C12.4202 21.98 12.5802 21.99 12.7402 21.99C16.0902 21.99 19.2302 20.41 21.2102 17.72C21.8802 16.79 21.7002 16.2 21.5302 15.93Z" fill="#fff0cc"/>
+<path d="M21.5302 15.93C21.3702 15.66 20.9202 15.24 19.8002 15.44C19.1802 15.55 18.5502 15.6 17.9202 15.57C15.5902 15.47 13.4802 14.4 12.0102 12.75C10.7102 11.3 9.9102 9.40999 9.9002 7.36999C9.9002 6.22999 10.1202 5.12999 10.5702 4.08999C11.0102 3.07999 10.7002 2.54999 10.4802 2.32999C10.2502 2.09999 9.7102 1.77999 8.6502 2.21999C4.5602 3.93999 2.0302 8.03999 2.3302 12.43C2.6302 16.56 5.5302 20.09 9.3702 21.42C10.2902 21.74 11.2602 21.93 12.2602 21.97C12.4202 21.98 12.5802 21.99 12.7402 21.99C16.0902 21.99 19.2302 20.41 21.2102 17.72C21.8802 16.79 21.7002 16.2 21.5302 15.93Z" fill="#FDF0D5"/>
--- a/scenes/balatro/trick_asset/ui_bisca/play.svg
+++ b/scenes/balatro/trick_asset/ui_bisca/play.svg
@@ -2,1 +2,1 @@
-<path d="M7.87 21.28C7.08 21.28 6.33 21.09 5.67 20.71C4.11 19.81 3.25 17.98 3.25 15.57V8.44C3.25 6.02 4.11 4.2 5.67 3.3C7.23 2.4 9.24 2.57 11.34 3.78L17.51 7.34C19.6 8.55 20.76 10.21 20.76 12.01C20.76 13.81 19.61 15.47 17.51 16.68L11.34 20.24C10.13 20.93 8.95 21.28 7.87 21.28ZM7.87 4.22C7.33 4.22 6.85 4.34 6.42 4.59C5.34 5.21 4.75 6.58 4.75 8.44V15.56C4.75 17.42 5.34 18.78 6.42 19.41C7.5 20.04 8.98 19.86 10.59 18.93L16.76 15.37C18.37 14.44 19.26 13.25 19.26 12C19.26 10.75 18.37 9.56 16.76 8.63L10.59 5.07C9.61 4.51 8.69 4.22 7.87 4.22Z" fill="#fff0cc"/>
+<path d="M7.87 21.28C7.08 21.28 6.33 21.09 5.67 20.71C4.11 19.81 3.25 17.98 3.25 15.57V8.44C3.25 6.02 4.11 4.2 5.67 3.3C7.23 2.4 9.24 2.57 11.34 3.78L17.51 7.34C19.6 8.55 20.76 10.21 20.76 12.01C20.76 13.81 19.61 15.47 17.51 16.68L11.34 20.24C10.13 20.93 8.95 21.28 7.87 21.28ZM7.87 4.22C7.33 4.22 6.85 4.34 6.42 4.59C5.34 5.21 4.75 6.58 4.75 8.44V15.56C4.75 17.42 5.34 18.78 6.42 19.41C7.5 20.04 8.98 19.86 10.59 18.93L16.76 15.37C18.37 14.44 19.26 13.25 19.26 12C19.26 10.75 18.37 9.56 16.76 8.63L10.59 5.07C9.61 4.51 8.69 4.22 7.87 4.22Z" fill="#FDF0D5"/>
@@ -3,1 +3,1 @@
-<path d="M4.10479 12.9453L5.4678 18.7382C5.74795 19.9288 7.02174 20.5913 8.15742 20.137L13.2248 18.1101C13.4073 18.0371 13.578 17.9376 13.7314 17.8149L19.0478 13.5617C20.0486 12.7611 20.0486 11.2389 19.0478 10.4383L13.7785 6.22283C13.5943 6.07544 13.3854 5.96181 13.1616 5.8872L8.10377 4.20126C6.97866 3.82622 5.77621 4.50704 5.51894 5.66476L4.09925 12.0534C4.03393 12.3473 4.03582 12.6522 4.10479 12.9453Z" fill="#fff0cc" stroke="#fff0cc"/>
+<path d="M4.10479 12.9453L5.4678 18.7382C5.74795 19.9288 7.02174 20.5913 8.15742 20.137L13.2248 18.1101C13.4073 18.0371 13.578 17.9376 13.7314 17.8149L19.0478 13.5617C20.0486 12.7611 20.0486 11.2389 19.0478 10.4383L13.7785 6.22283C13.5943 6.07544 13.3854 5.96181 13.1616 5.8872L8.10377 4.20126C6.97866 3.82622 5.77621 4.50704 5.51894 5.66476L4.09925 12.0534C4.03393 12.3473 4.03582 12.6522 4.10479 12.9453Z" fill="#FDF0D5" stroke="#FDF0D5"/>
--- a/scenes/balatro/trick_asset/ui_bisca/volume-cross.svg
+++ b/scenes/balatro/trick_asset/ui_bisca/volume-cross.svg
@@ -2,1 +2,1 @@
-<path d="M22.5299 13.42L21.0799 11.97L22.4799 10.57C22.7699 10.28 22.7699 9.79999 22.4799 9.50999C22.1899 9.21999 21.7099 9.21999 21.4199 9.50999L20.0199 10.91L18.5699 9.45999C18.2799 9.16999 17.7999 9.16999 17.5099 9.45999C17.2199 9.74999 17.2199 10.23 17.5099 10.52L18.9599 11.97L17.4699 13.46C17.1799 13.75 17.1799 14.23 17.4699 14.52C17.6199 14.67 17.8099 14.74 17.9999 14.74C18.1899 14.74 18.3799 14.67 18.5299 14.52L20.0199 13.03L21.4699 14.48C21.6199 14.63 21.8099 14.7 21.9999 14.7C22.1899 14.7 22.3799 14.63 22.5299 14.48C22.8199 14.19 22.8199 13.72 22.5299 13.42Z" fill="#fff0cc"/>
+<path d="M22.5299 13.42L21.0799 11.97L22.4799 10.57C22.7699 10.28 22.7699 9.79999 22.4799 9.50999C22.1899 9.21999 21.7099 9.21999 21.4199 9.50999L20.0199 10.91L18.5699 9.45999C18.2799 9.16999 17.7999 9.16999 17.5099 9.45999C17.2199 9.74999 17.2199 10.23 17.5099 10.52L18.9599 11.97L17.4699 13.46C17.1799 13.75 17.1799 14.23 17.4699 14.52C17.6199 14.67 17.8099 14.74 17.9999 14.74C18.1899 14.74 18.3799 14.67 18.5299 14.52L20.0199 13.03L21.4699 14.48C21.6199 14.63 21.8099 14.7 21.9999 14.7C22.1899 14.7 22.3799 14.63 22.5299 14.48C22.8199 14.19 22.8199 13.72 22.5299 13.42Z" fill="#FDF0D5"/>
@@ -3,1 +3,1 @@
-<path d="M14.02 3.78C12.9 3.16 11.47 3.32 10.01 4.23L7.09 6.06C6.89 6.18 6.66 6.25 6.43 6.25H5.5H5C2.58 6.25 1.25 7.58 1.25 10V14C1.25 16.42 2.58 17.75 5 17.75H5.5H6.43C6.66 17.75 6.89 17.82 7.09 17.94L10.01 19.77C10.89 20.32 11.75 20.59 12.55 20.59C13.07 20.59 13.57 20.47 14.02 20.22C15.13 19.6 15.75 18.31 15.75 16.59V7.41C15.75 5.69 15.13 4.4 14.02 3.78Z" fill="#fff0cc"/>
+<path d="M14.02 3.78C12.9 3.16 11.47 3.32 10.01 4.23L7.09 6.06C6.89 6.18 6.66 6.25 6.43 6.25H5.5H5C2.58 6.25 1.25 7.58 1.25 10V14C1.25 16.42 2.58 17.75 5 17.75H5.5H6.43C6.66 17.75 6.89 17.82 7.09 17.94L10.01 19.77C10.89 20.32 11.75 20.59 12.55 20.59C13.07 20.59 13.57 20.47 14.02 20.22C15.13 19.6 15.75 18.31 15.75 16.59V7.41C15.75 5.69 15.13 4.4 14.02 3.78Z" fill="#FDF0D5"/>
--- a/scenes/balatro/trick_asset/ui_bisca/volume-high.svg
+++ b/scenes/balatro/trick_asset/ui_bisca/volume-high.svg
@@ -2,1 +2,1 @@
-<path d="M17.9998 16.75C17.8398 16.75 17.6898 16.7 17.5498 16.6C17.2198 16.35 17.1498 15.88 17.3998 15.55C18.9698 13.46 18.9698 10.54 17.3998 8.45C17.1498 8.12 17.2198 7.65 17.5498 7.4C17.8798 7.15 18.3498 7.22 18.5998 7.55C20.5598 10.17 20.5598 13.83 18.5998 16.45C18.4498 16.65 18.2298 16.75 17.9998 16.75Z" fill="#fff0cc"/>
+<path d="M17.9998 16.75C17.8398 16.75 17.6898 16.7 17.5498 16.6C17.2198 16.35 17.1498 15.88 17.3998 15.55C18.9698 13.46 18.9698 10.54 17.3998 8.45C17.1498 8.12 17.2198 7.65 17.5498 7.4C17.8798 7.15 18.3498 7.22 18.5998 7.55C20.5598 10.17 20.5598 13.83 18.5998 16.45C18.4498 16.65 18.2298 16.75 17.9998 16.75Z" fill="#FDF0D5"/>
@@ -3,1 +3,1 @@
-<path d="M19.8299 19.25C19.6699 19.25 19.5199 19.2 19.3799 19.1C19.0499 18.85 18.9799 18.38 19.2299 18.05C21.8999 14.49 21.8999 9.51 19.2299 5.95C18.9799 5.62 19.0499 5.15 19.3799 4.9C19.7099 4.65 20.1799 4.72 20.4299 5.05C23.4999 9.14 23.4999 14.86 20.4299 18.95C20.2899 19.15 20.0599 19.25 19.8299 19.25Z" fill="#fff0cc"/>
+<path d="M19.8299 19.25C19.6699 19.25 19.5199 19.2 19.3799 19.1C19.0499 18.85 18.9799 18.38 19.2299 18.05C21.8999 14.49 21.8999 9.51 19.2299 5.95C18.9799 5.62 19.0499 5.15 19.3799 4.9C19.7099 4.65 20.1799 4.72 20.4299 5.05C23.4999 9.14 23.4999 14.86 20.4299 18.95C20.2899 19.15 20.0599 19.25 19.8299 19.25Z" fill="#FDF0D5"/>
@@ -4,1 +4,1 @@
-<path d="M14.02 3.78C12.9 3.16 11.47 3.32 10.01 4.23L7.09 6.06C6.89 6.18 6.66 6.25 6.43 6.25H5.5H5C2.58 6.25 1.25 7.58 1.25 10V14C1.25 16.42 2.58 17.75 5 17.75H5.5H6.43C6.66 17.75 6.89 17.82 7.09 17.94L10.01 19.77C10.89 20.32 11.75 20.59 12.55 20.59C13.07 20.59 13.57 20.47 14.02 20.22C15.13 19.6 15.75 18.31 15.75 16.59V7.41C15.75 5.69 15.13 4.4 14.02 3.78Z" fill="#fff0cc"/>
+<path d="M14.02 3.78C12.9 3.16 11.47 3.32 10.01 4.23L7.09 6.06C6.89 6.18 6.66 6.25 6.43 6.25H5.5H5C2.58 6.25 1.25 7.58 1.25 10V14C1.25 16.42 2.58 17.75 5 17.75H5.5H6.43C6.66 17.75 6.89 17.82 7.09 17.94L10.01 19.77C10.89 20.32 11.75 20.59 12.55 20.59C13.07 20.59 13.57 20.47 14.02 20.22C15.13 19.6 15.75 18.31 15.75 16.59V7.41C15.75 5.69 15.13 4.4 14.02 3.78Z" fill="#FDF0D5"/>
--- a/scenes/balatro/trick_asset/ui_bisca/volume-slash.svg
+++ b/scenes/balatro/trick_asset/ui_bisca/volume-slash.svg
@@ -2,1 +2,1 @@
-<path d="M17.9998 16.75C17.8398 16.75 17.6898 16.7 17.5498 16.6C17.2198 16.35 17.1498 15.88 17.3998 15.55C18.6598 13.87 18.9298 11.64 18.1198 9.71C17.9598 9.33 18.1398 8.89 18.5198 8.73C18.8998 8.57 19.3398 8.75 19.4998 9.13C20.5198 11.55 20.1698 14.36 18.5998 16.46C18.4498 16.65 18.2298 16.75 17.9998 16.75Z" fill="#fff0cc"/>
+<path d="M17.9998 16.75C17.8398 16.75 17.6898 16.7 17.5498 16.6C17.2198 16.35 17.1498 15.88 17.3998 15.55C18.6598 13.87 18.9298 11.64 18.1198 9.71C17.9598 9.33 18.1398 8.89 18.5198 8.73C18.8998 8.57 19.3398 8.75 19.4998 9.13C20.5198 11.55 20.1698 14.36 18.5998 16.46C18.4498 16.65 18.2298 16.75 17.9998 16.75Z" fill="#FDF0D5"/>
@@ -3,1 +3,1 @@
-<path d="M19.8299 19.25C19.6699 19.25 19.5199 19.2 19.3799 19.1C19.0499 18.85 18.9799 18.38 19.2299 18.05C21.3699 15.2 21.8399 11.38 20.4599 8.09C20.2999 7.71 20.4799 7.27 20.8599 7.11C21.2399 6.95 21.6799 7.13 21.8399 7.51C23.4299 11.29 22.8899 15.67 20.4299 18.95C20.2899 19.15 20.0599 19.25 19.8299 19.25Z" fill="#fff0cc"/>
+<path d="M19.8299 19.25C19.6699 19.25 19.5199 19.2 19.3799 19.1C19.0499 18.85 18.9799 18.38 19.2299 18.05C21.3699 15.2 21.8399 11.38 20.4599 8.09C20.2999 7.71 20.4799 7.27 20.8599 7.11C21.2399 6.95 21.6799 7.13 21.8399 7.51C23.4299 11.29 22.8899 15.67 20.4299 18.95C20.2899 19.15 20.0599 19.25 19.8299 19.25Z" fill="#FDF0D5"/>
@@ -4,1 +4,1 @@
-<path d="M14.04 12.96C14.67 12.33 15.75 12.78 15.75 13.67V16.6C15.75 18.32 15.13 19.61 14.02 20.23C13.57 20.48 13.07 20.6 12.55 20.6C11.75 20.6 10.89 20.33 10.01 19.78L9.36998 19.38C8.82998 19.04 8.73998 18.28 9.18998 17.83L14.04 12.96Z" fill="#fff0cc"/>
+<path d="M14.04 12.96C14.67 12.33 15.75 12.78 15.75 13.67V16.6C15.75 18.32 15.13 19.61 14.02 20.23C13.57 20.48 13.07 20.6 12.55 20.6C11.75 20.6 10.89 20.33 10.01 19.78L9.36998 19.38C8.82998 19.04 8.73998 18.28 9.18998 17.83L14.04 12.96Z" fill="#FDF0D5"/>
@@ -5,1 +5,1 @@
-<path d="M21.77 2.23C21.47 1.93 20.98 1.93 20.68 2.23L15.73 7.18C15.67 5.58 15.07 4.38 14.01 3.79C12.89 3.17 11.46 3.33 10 4.24L7.09 6.06C6.89 6.18 6.66 6.25 6.43 6.25H5.5H5C2.58 6.25 1.25 7.58 1.25 10V14C1.25 16.42 2.58 17.75 5 17.75H5.16L2.22 20.69C1.92 20.99 1.92 21.48 2.22 21.78C2.38 21.92 2.57 22 2.77 22C2.97 22 3.16 21.92 3.31 21.77L21.77 3.31C22.08 3.01 22.08 2.53 21.77 2.23Z" fill="#fff0cc"/>
+<path d="M21.77 2.23C21.47 1.93 20.98 1.93 20.68 2.23L15.73 7.18C15.67 5.58 15.07 4.38 14.01 3.79C12.89 3.17 11.46 3.33 10 4.24L7.09 6.06C6.89 6.18 6.66 6.25 6.43 6.25H5.5H5C2.58 6.25 1.25 7.58 1.25 10V14C1.25 16.42 2.58 17.75 5 17.75H5.16L2.22 20.69C1.92 20.99 1.92 21.48 2.22 21.78C2.38 21.92 2.57 22 2.77 22C2.97 22 3.16 21.92 3.31 21.77L21.77 3.31C22.08 3.01 22.08 2.53 21.77 2.23Z" fill="#FDF0D5"/>
--- a/scenes/button_fill_animate/hold_button.gd
+++ b/scenes/button_fill_animate/hold_button.gd
@@ -14,1 +14,1 @@
-@export var base_color := Color("214f50")
+@export var base_color := Color("474660")
@@ -15,1 +15,1 @@
-@export var fill_color := Color("347667")
+@export var fill_color := Color("74ab8e")
@@ -16,1 +16,1 @@
-@export var hover_color := Color("347667")
+@export var hover_color := Color("74ab8e")
@@ -21,1 +21,1 @@
-@export var confirm_progress_color := Color("347667")
+@export var confirm_progress_color := Color("74ab8e")
```

