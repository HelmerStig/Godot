# Memoria del progetto

Ultimo aggiornamento: 14 luglio 2026

## Obiettivo attuale

Il repository contiene un prototipo didattico di picchiaduro 2D sviluppato con Godot 4.7. In questa fase la priorità è consolidare il combattimento di base in modalità training prima di introdurre animazioni complete, IA, combo, menu o multiplayer.

## Struttura principale

- `scenes/MainArena.tscn`: arena, terreno, camera, interfaccia e fighter.
- `scenes/Mangler.tscn`: scena del personaggio con corpo, sprite, hitbox e hurtbox.
- `scripts/MainArena.gd`: ciclo del training, timer, UI, camera, KO e reset.
- `scripts/Mangler.gd`: input, movimento, stati, attacchi, danni e collisioni.
- `scripts/CharacterData.gd`: statistiche e configurazione del personaggio.
- `FRAME_DATA.md`: specifiche teoriche del sistema di combattimento.
- `TUTORIAL_ANIMAZIONI.md`: guida futura per integrare le animazioni.

## Lavoro completato

### Arena e training

- Aggiunto `Player2` come bersaglio statico non controllato.
- Attivata la seconda barra della vita.
- Il KO interrompe il training e mostra il vincitore.
- Aggiunta l'azione `reset_training`, associata al tasto `R`.
- Il reset ripristina entrambi i fighter e avvia un nuovo countdown.
- Il timer non può più scendere sotto zero.
- La camera si centra tra i due fighter.
- Corretto il caso in cui lo stage sia più stretto della viewport e gli estremi del clamp risultino invertiti.

### Fighter e combattimento

- Corretto lo stato `BLOCKING`: rilasciando il tasto il fighter torna a `IDLE`.
- Ogni attacco utilizza ora il proprio danno e la propria durata.
- Eliminato il danno fisso di 10 HP applicato a tutti gli attacchi.
- Movimento, salto, danni e durate vengono letti da `CharacterData`.
- Aggiunto il danno dell'attacco corrente per il passaggio tra hitbox e avversario.
- Aggiunto `reset_fighter()` per ripristinare posizione, velocità, vita e stato.
- Le azioni asincrone pendenti vengono invalidate durante hit, KO e reset.
- Una coroutine di attacco o hit-stun precedente non può più ripristinare erroneamente un fighter KO o appena resettato.
- La hitbox viene disabilitata quando un'azione viene annullata.
- Al reset i fighter vengono orientati uno verso l'altro.

## Controlli

- `git diff --check` completato senza errori.
- Non è stato possibile eseguire una validazione headless perché l'eseguibile Godot non era disponibile nel `PATH` della sessione Codex.
- È necessario verificare manualmente nell'editor: movimento, salto, blocco, quattro attacchi, variazione della vita, KO e reset con `R`.

## Decisioni progettuali

- Mantenere per ora una modalità training semplice, senza implementare prematuramente il best-of-three.
- Usare `CharacterData` come fonte dei parametri del fighter, riducendo i valori duplicati nel controller.
- Usare un bersaglio statico prima di introdurre un secondo controller o l'IA.
- Stabilizzare stati, frame data e hitbox prima di aggiungere combo e mosse speciali.
- Le coroutine sono protette tramite un contatore di generazione che invalida le azioni precedenti.

## Priorità successive

1. Collegare gli stati e gli attacchi a `AnimatedSprite2D` e aggiungere feedback visivo dei colpi.
2. Creare una risorsa `AttackData` con danno, startup, active, recovery, hitstun e forma della hitbox.
3. Centralizzare le transizioni in una state machine più formale.
4. Creare hitbox diverse per pugni e calci.
5. Aggiungere un secondo controller oppure una IA basilare.
6. Implementare round, timeout, punteggio e best-of-three.
7. Implementare input buffer, combo e mosse speciali.

## Debito tecnico noto

- `Mangler.gd` gestisce ancora troppe responsabilità: input, fisica, stati, combattimento e danni.
- Le costanti di movimento originali sono ancora dichiarate nello script, anche se i valori effettivi arrivano da `CharacterData`.
- Tutti gli attacchi condividono la stessa hitbox.
- Il flip usa una scala negativa sull'intero `CharacterBody2D`; in futuro è preferibile separare un nodo visuale e un contenitore per le hitbox orientabili.
- Le funzioni di round completo (`end_round_timeout`, `next_round`, `end_match`) sono ancora segnaposto.
- `CharacterData` viene creato con valori di default in memoria; non esistono ancora risorse `.tres` dedicate ai personaggi.
- `node_2d.tscn` sembra una scena iniziale non utilizzata e potrà essere rimossa dopo verifica.

## Controlli attuali

- Movimento: `A`/`D` oppure frecce sinistra/destra.
- Salto: `W`, freccia su o spazio.
- Accovacciamento: `S` o freccia giù.
- Pugno leggero: `J`.
- Pugno pesante: `U`.
- Calcio leggero: `K`.
- Calcio pesante: `I`.
- Blocco: `L`.
- Reset training: `R`.

## Nota per la prossima sessione

Prima di sviluppare nuove funzionalità, avviare `scenes/MainArena.tscn` nell'editor Godot e verificare il comportamento delle modifiche elencate sopra. Se emergono errori di parsing o runtime, correggerli prima di procedere con animazioni o `AttackData`.
