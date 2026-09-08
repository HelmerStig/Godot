# Smoke test triage — risolto

Baseline precedente al riallineamento, verificata il 1 settembre 2026 con Godot 4.7:

- 469 asserzioni superate;
- 27 asserzioni fallite;
- nessun errore di parsing;
- nessun errore di flush delle query fisiche dopo la correzione delle hitbox.

## Esito

Il riallineamento è concluso: la baseline corrente contiene 496 asserzioni superate,
zero fallimenti e termina con `SMOKE_TESTS_OK`. Dei 27 fallimenti iniziali, 17 erano
aspettative non più allineate, 8 erano problemi di orchestrazione o a cascata e 2
hanno evidenziato incoerenze runtime:

- la parata del light punch basso forzava `LOW` nonostante la variante `MID`;
- `get_hit_reaction_start_frame()` ignorava il frame configurato nella variante.

## Aspettative obsolete

| Riga | Area | Motivo | Azione sul test |
|---:|---|---|---|
| 1886 | light punch Mangler | Coordinate atlas storiche; il runtime usa il foglio corrente con 18 frame. | Verificare la sequenza corrente invece delle vecchie regioni. |
| 1901 | medium punch Mangler | Il runtime combina 10 frame di preparazione, 16 d'impatto e 16 di ritorno a 48 FPS. | Attendere 42 frame a 48 FPS. |
| 1919 | medium punch Mangler | Picco e ultimo frame appartengono ormai a tre fogli distinti. | Verificare i tre segmenti correnti. |
| 1977 | light kick basso Mangler | La sequenza corrente usa 6-22 e 21-7, per 31 frame a 48 FPS. | Aggiornare conteggio, FPS e regioni. |
| 2456 | sweep Mangler | `crouched_heavy_kick` usa ora tutti i 49 frame a 48 FPS. | Sostituire l'attesa storica 32-48 a 24 FPS. |
| 2472 | sweep Mangler | Primo e ultimo frame non sono più i sorgenti 32 e 48. | Verificare sorgenti 1 e 49. |
| 2479 | medium kick basso Mangler | La sequenza corrente contiene 49 frame a 48 FPS. | Aggiornare conteggio e FPS. |
| 2679 | hurt mid Mangler | Il test conserva i vecchi 16 FPS. | Usare gli FPS configurati nello `SpriteFrames` corrente. |
| 2695 | hurt high Mangler | Il test conserva i vecchi 16 FPS. | Usare gli FPS correnti. |
| 2711 | hurt low Mangler | Il test conserva i vecchi 16 FPS. | Usare gli FPS correnti. |
| 2732 | sweep knockdown Mangler | Il runtime registra 49 frame, non 25. | Attendere 49 frame. |
| 2736 | sweep knockdown Mangler | Il runtime usa 48 FPS, non 24. | Aggiornare gli FPS attesi. |
| 3956 | medium punch Mangler | La risorsa corrente usa hitbox `185x35` in `(92.5, -210)`. | Leggere l'aspettativa da `AttackVariantData`. |
| 4044 | medium kick Mangler | Lo startup è espresso a 48 FPS; il test divide ancora per 24. | Confrontare con `get_phase_durations()`. |
| 4146 | sweep Mangler | La variante corrente usa startup 22f e active 7f a 48 FPS. | Rimuovere i vecchi valori 3f/2f a 24 FPS. |
| 4177 | heavy punch basso Mangler | La variante corrente è `HIGH`; anche la documentazione descrive `hurt_high`. | Correggere l'aspettativa `LOW`. |
| 4263 | light punch basso Mangler | La variante è `MID`, quindi una parata corretta usa `block_mid`. | Sostituire `block_low` con `block_mid`. |
| 4369 | sweep knockdown Mangler | Con 49 frame a 48 FPS più 0,35 s di hold, a 1,65 s la recovery è già iniziata. | Calcolare l'attesa dalla durata runtime. |

## Orchestrazione e fallimenti a cascata

| Riga | Area | Causa osservata | Azione sul test |
|---:|---|---|---|
| 1735 | corsa Arianna | `live_run_started` è falso: il test lascia Arianna in `STANDING_UP` dopo la mossa precedente. | Ripristinare esplicitamente fighter, input e collisioni prima del caso. |
| 1769 | back jump Arianna | Cascata dal caso precedente; il back jump non viene avviato. | Isolare il caso e partire da `IDLE` a terra. |
| 4012 | light kick Mangler | L'animazione visiva dura 29f, mentre startup+active+recovery durano 31f. Il test controlla durante la recovery logica. | Attendere la durata della variante più un physics frame. |
| 4015 | light kick basso Mangler | Il nuovo attacco viene rifiutato perché il light kick precedente è ancora attivo. | Risolvere prima l'attesa della riga 4012. |
| 4021 | hitbox light kick basso | Cascata: la variante bassa non è stata avviata. | Verificare dopo un avvio isolato riuscito. |
| 4027 | reazione light kick basso | Cascata: viene applicato ancora il contesto dell'attacco precedente. | Verificare `hurt_low` usando la variante corrente. |
| 4201 | medium punch basso Mangler | Il test attende una durata storica del heavy punch precedente e il nuovo attacco viene rifiutato. | Attendere la fine effettiva dell'azione o cancellarla esplicitamente. |
| 4208 | hitbox medium punch basso | Cascata: la variante bassa non è stata avviata. | Verificare dopo un setup isolato. |
| 4214 | timing medium punch basso | Cascata: viene interrogata la variante precedente. | Confrontare direttamente l'`AttackVariantData` crouched. |

## Regola per il riallineamento

I test aggiornati dovrebbero usare `AttackVariantData` come fonte dei timing, della
hitbox e dell'altezza del colpo. Le regioni degli atlas vanno controllate soltanto nei
test dedicati allo slicing. Ogni test di comportamento deve iniziare da uno stato
esplicito e attendere almeno un physics frame oltre la durata logica dell'azione.
