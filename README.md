# DON'T TOUCH THE GROUND

Party game multijugador de Roblox (2–20 jugadores): sobrevive sobre plataformas mientras la lava sube, los eventos aleatorios complican la partida y el último en pie gana **Wins** para comprar cosméticos.

El juego entero está escrito en código Luau y se sincroniza con Roblox Studio mediante [Rojo](https://rojo.space). Los mapas, el lobby, los accesorios y los efectos se construyen por código con piezas nativas (Parts, ParticleEmitters, Trails, Beams), así que no dependen de mallas ni animaciones subidas.

---

## Cómo abrirlo en Roblox Studio

1. Instala las herramientas con [Rokit](https://github.com/rojo-rbx/rokit): `rokit install` (versiones en `rokit.toml`).
2. Instala el plugin de Rojo en Studio.
3. Ejecuta `rojo serve` en la raíz del repositorio y pulsa **Connect** en el plugin, o genera el place con `rojo build default.project.json -o DontTouchTheGround.rbxl`.
4. En *Game Settings → Security* activa **Enable Studio Access to API Services** si quieres probar el guardado real. Sin eso el juego usa perfiles en memoria y avisa en la consola.
5. Para probar varios jugadores: *Test → Clients and Servers → 2–4 jugadores*. Con 1 jugador la ronda es de **entrenamiento** (sin Wins).

### Comandos de QA (solo en Studio o para `GameConfig.AdminUserIds`)
Escríbelos en el chat:

| Comando | Efecto |
|---|---|
| `/dttg wins 100` | Suma Wins disponibles |
| `/dttg coins 5000` | Suma Coins |
| `/dttg xp 3000` | Suma XP |
| `/dttg unlockall` | Desbloquea todo el catálogo |
| `/dttg event meteors` | Lanza un evento (cualquier id de `EventConfig`) durante una ronda |
| `/dttg resetdata` | Reinicia tu perfil |

### Controles
- **Teclado:** B tienda · I colección · G emotes · J misiones · Q/E cambiar de jugador espectado.
- **Mando:** Y tienda · X emotes · cruceta ↑ misiones · cruceta ↓ colección · B cerrar · LB/RB espectar.
- **Móvil:** botones laterales y del HUD. La UI se escala según la pantalla y evita las esquinas inferiores (joystick y salto).

---

## Estructura

```
src/shared        → ReplicatedStorage.Shared
  Config/         precios, rarezas, catálogo, mapas, eventos, misiones, logros, audio
  Logic/          lógica pura y testeable (rondas, lava, recompensas, niveles, tienda,
                  rotación de destacados, misiones, director de dificultad, movimiento de plataformas)
  Util/           Maid, Signal, PRNG determinista, RateLimiter, Build, Format
  Visual/         motor de efectos FxKit y la implementación visual de cada cosmético
  Net/Remotes     definición de todos los remotes
src/server        → ServerScriptService.Server
  Services/       RoundService, MapService, HazardService, EventService, PlayerDataService,
                  CurrencyService, RewardService, CosmeticService, ShopService, InventoryService,
                  EquipmentService, QuestService, AchievementService, LeaderboardService,
                  LobbyService, EmoteService, FXService, AdminService
  Maps/           Lobby + 6 mapas procedurales + PlatformFactory
  Events/         20 eventos (un módulo por evento, con limpieza por Maid)
src/client        → StarterPlayerScripts.Client
  Controllers/    UIController, CosmeticRenderer (efectos), AudioController, PlatformController,
                  LavaController, MovementController, EmoteController, CameraController...
  UI/             HUD, tienda/colección, emotes, misiones, ajustes, resultados, notificaciones
tests/            suite Lune (lógica, economía, mapas, todos los cosméticos)
scripts/          check.sh (todas las comprobaciones) y check_props.py
```

### Principios
- **El servidor decide todo:** quién gana, quién muere, el nivel de la lava, las recompensas y las compras. El cliente solo dibuja y mueve a su propio personaje.
- **Eliminación sin `Touched`:** el servidor compara la altura de los pies con la altura de la lava 20 veces por segundo, así que no hay fallos de colisión.
- **Plataformas móviles deterministas:** el servidor solo escribe atributos (tipo de movimiento, inicio y fin en hora del servidor). Cada cliente anima su copia con la misma fórmula (`PlatformMotion`), sin coste de red, y el servidor usa esa misma fórmula para saber quién pisa qué.
- **Cosméticos 100 % en cliente:** el servidor publica el equipamiento como atributos del personaje (`Cos_Trail`, `Cos_Acc_Head`…) y cada cliente los renderiza con calidad Baja, Media o Alta, recorte por distancia y la opción de ocultar los efectos de los demás.
- **Añadir un cosmético:** una entrada en `Config/CosmeticCatalog.luau` con un id estable, más su función visual con el mismo id en `Visual/`. Los tests fallan si falta una de las dos.

---

## Contenido

- **Rondas:** Lobby → Intermedio (15 s, votación entre 3 mapas) → Selección → Preparación (5 s, cuenta atrás) → Ronda (180 s) → Muerte súbita (lava extrema + Final Collapse, máximo 45 s) → Resultados → Lobby. Cada ronda va en `pcall` con limpieza completa para que un error nunca bloquee el servidor.
- **Lava:** estable durante 20 s, luego sube a 0.12, 0.24 y 0.42 studs/s, y a 1.6 en muerte súbita. Avisa antes de cada aceleración. Los tests garantizan que alcanza la cima de todos los mapas.
- **Plataformas:** Normal, Frágil, Desaparecedora, Móvil, Giratoria, Rebotadora, Resbaladiza, Temporal, Falsa y Checkpoint (protegida solo 6 s). Cada tipo tiene color, borde luminoso, símbolo y material propios.
- **20 eventos** con duración, dificultad, probabilidad, aviso y sonido. Un director de dificultad no lanza nada antes de 22 s, sube la intensidad con el tiempo, limita los eventos simultáneos con un presupuesto y bloquea combinaciones imposibles mediante etiquetas.
- **6 mapas:** Rainbow Sky (espirales), Lava Factory (torres con rampas, cintas, pistón, engranajes), Candy Disaster (tarta escalonada y piruletas), Sky Islands (islas con ruta completa sin saltar), Neon City (azoteas en serpiente y coches voladores) y Volcano Escape (doble hélice alrededor del volcán).
- **Economía:** ganar da 1 Win + 100 Coins; 2.º, 50 Coins; 3.º, 30 Coins; participar, 5 Coins; sobrevivir 60 s, 15 Coins más un extra cada 30 s; primera victoria del día, +1 Win. No se dan Wins sin al menos 2 jugadores activos (no AFK) ni en rondas de menos de 25 s. Cada ronda tiene un id que el perfil recuerda para no pagarla dos veces.
- **176 cosméticos** en 10 categorías y 5 rarezas, con tienda destacada diaria (−15 %), 7 colecciones con recompensa, 16 logros, nivel por XP con recompensas y 3 presets.

### Ritmo de la economía (estimación)
Con unos 10 jugadores por servidor, un jugador medio gana alrededor de 1 de cada 10 rondas: unas 2 Wins por hora más la bonificación diaria. Los Common (2–5) y Rare (6–15) se consiguen en las primeras sesiones; los Epic (16–40), en pocos días; los Legendary (41–100), en semanas; los Mythic (101–250) son objetivos a largo plazo. Las Coins compran emotes y sirven para progresar sin depender solo de ganar. Todo se ajusta en `Config/EconomyConfig.luau` y en los precios del catálogo.

---

## Comprobaciones automáticas

`./scripts/check.sh` (también en GitHub Actions) ejecuta:

1. **StyLua:** formato.
2. **Selene:** lint (requiere `selene generate-roblox-std`).
3. **luau-lsp analyze:** verificación de tipos con las definiciones reales de la API de Roblox. Lógica compartida en `--!strict`.
4. **check_props.py:** valida contra la API de Roblox los nombres de propiedades de las tablas `new("Clase", {...})` de la UI.
5. **Lune** (47 tests): lógica de rondas, empates, recompensas, anti-AFK, niveles, migración de datos, tienda, equipamiento, rotación de destacados, misiones, logros y director de eventos. También construye los 6 mapas y el lobby con instancias reales y monta los 176 cosméticos sobre un rig R15 sintético.
6. **rojo build:** genera el `.rbxl`.

---

## Qué está verificado y qué no

**Verificado fuera de Roblox:** todo lo de la lista anterior. Los nombres de propiedades de mapas y cosméticos los valida Lune con la base de datos de reflexión de Roblox.

**Pendiente de probar en Roblox Studio** (no se pudo ejecutar el motor en este entorno):
- La jugabilidad real con varios clientes: sensación de salto, plataformas móviles arrastrando al personaje, cámara y espectador.
- Que las animaciones procedurales sobrescriben al Animator en `PreSimulation` como se espera, y que los ejes de los emotes quedan bien en todos los avatares (sobre todo R6 y Rthro).
- El aspecto de la UI en móvil y la navegación con mando.
- El guardado real con DataStore (bloqueo de sesión entre servidores, `BindToClose`).
- El rendimiento en dispositivos modestos.

## Antes de publicar
- **Audio:** `Config/AudioConfig.luau` usa sonidos internos de Roblox (`rbxasset://`) como provisionales y deja la **música vacía a propósito**. Sube pistas propias o con licencia y pega sus ids.
- **Iconos:** los iconos de la UI son emoji y glifos Unicode. Puedes sustituirlos por imágenes subidas si quieres un estilo propio.
- Rellena `GameConfig.AdminUserIds` solo con cuentas de confianza.
- Activa el acceso a API en la experiencia publicada y revisa los nombres de los DataStores en `GameConfig.Data`.
- Haz la pasada de pruebas de la fase 5: varias personas, móvil, mando, guardado y todos los cosméticos.
