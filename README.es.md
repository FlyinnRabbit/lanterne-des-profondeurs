# Lanterne des Profondeurs (Linterna de las Profundidades)

<p align="center"><img src="docs/banner.jpg" width="900" alt="El héroe bajo la Linterna, rodeado de los guardianes de las profundidades"></p>

[English](README.md) · [Français](README.fr.md) · **Español** · [Deutsch](README.de.md)

Roguelite metroidvania 2D para **Godot 4.3+**, inspirado en Hollow Knight: cuevas oscuras, combate
con aguja, rebotes sobre los enemigos, curación con el alma, bancos de descanso y diez jefes.
Todo está dibujado con código: el juego no contiene ni una sola imagen.

**Jugar en el navegador: https://flyinnrabbit.github.io/lanterne-des-profondeurs/**

## Tráiler

<p align="center"><a href="docs/video/trailer_es.mp4"><img src="docs/video/preview.gif" width="820" alt="Vista previa del tráiler: haz clic para verlo"></a></p>

<p align="center"><b><a href="docs/video/trailer_es.mp4">▶ Ver el tráiler (80 s)</a></b> · <a href="docs/booklet/booklet_es.pdf">Folleto (PDF, 10 páginas)</a></p>

## El objetivo

Antaño, la Linterna de las Profundidades iluminaba cada nivel hasta el fondo del mundo. Su llama se ha
apagado. Desde el **Santuario**, toma el ascensor y desciende nivel tras nivel, vence al guardián de cada
uno y **reaviva la Linterna**, y luego vuelve con vida. Cada caída te devuelve al Santuario: tu sombra
guarda las esquirlas perdidas donde caíste, y el ascensor recuerda hasta dónde bajaste.

<p align="center"><img src="docs/screenshots/surface.jpg" width="820" alt="La luz llega por fin a la superficie"></p>

## En resumen

- **12 biomas**; las zonas se generan de nuevo en cada descenso, con grutas, estratos de tres pisos, tornos y trampas propias de cada bioma
- **10 jefes**: 6 guardianes de nivel y 4 jefes finales, cada uno con una fase 2 y su propia música
- **16 tipos de enemigos**, del reptante al mono ladrón, pasando por el mímico y el goblin
- **Combate**: combos de 3 golpes, torbellino cargado, combo aéreo, pogo, ataque en picado, estocada en embestida, parada (perfecta = golpe crítico), hoja de alma, definitivo
- **7 armas** forjadas hasta el nivel 5 por la herrera, **42 emblemas** reforzados hasta el nivel 3 por el joyero
- **El Santuario**: mercader, arsenal, herrera, joyero, cartógrafo, sastra (59 cosméticos), anciano, el Scriptorium y cuatro fiestas al año
- **4 dificultades** más un modo de una sola vida, maldiciones, **Descenso del día** y **Desafío semanal** con clasificaciones en línea y el fantasma del primero, **Desafío de jefes** con su propia clasificación
- Un **duelo local** para dos jugadores: la Arena de las Sombras
- Español, francés, inglés y alemán; teclado y mandos Xbox / PlayStation; navegador, Windows, macOS, Linux y Steam Deck; actualizaciones automáticas
- Todo dibujado en código; música y sonidos originales

## Capturas de pantalla

| | |
|---|---|
| ![El Santuario y sus habitantes](docs/screenshots/sanctuary.jpg) | ![El ascensor baja al siguiente nivel](docs/screenshots/lift_descent.jpg) |
| ![Parada perfecta en el Osario, en Pesadilla](docs/screenshots/nightmare_parry.jpg) | ![La Linterna reavivada](docs/screenshots/lantern_rekindled.jpg) |
| ![Los Jardines Fúngicos](docs/screenshots/fungal_gardens.jpg) | ![La Forja Ardiente](docs/screenshots/blazing_forge.jpg) |
| ![Las Minas de Cristal](docs/screenshots/crystal_mines.jpg) | ![El Abismo Helado](docs/screenshots/frozen_abyss.jpg) |
| ![La Biblioteca Silenciosa](docs/screenshots/silent_library.jpg) | ![La Colmena Zumbante](docs/screenshots/humming_hive.jpg) |
| ![El Cerbero de las Profundidades](docs/screenshots/boss_cerberus.jpg) | ![El Coloso de Hueso](docs/screenshots/boss_bone_colossus.jpg) |
| ![La Reina Enjambre](docs/screenshots/boss_swarm_queen.jpg) | ![Efectos de combate y proyectiles](docs/screenshots/combat_effects.jpg) |
| ![El mapa, un pergamino perdido con su leyenda](docs/screenshots/map.jpg) | ![El arsenal del Santuario](docs/screenshots/arsenal.jpg) |
| ![La costurera del Santuario](docs/screenshots/seamstress.jpg) | ![El guardarropa](docs/screenshots/wardrobe.jpg) |
| ![Algunos atuendos](docs/screenshots/outfits.jpg) | ![Estilos de definitiva](docs/screenshots/ultimates.jpg) |

**Las fiestas en el Santuario** (San Valentín, Pascua, Vigilia de las Sombras, Navidad)

![Las cuatro fiestas](docs/screenshots/festivals.jpg)

**Pantallas de carga** (inicio, entrada en una tienda, ascensor)

| | | |
|---|---|---|
| ![Inicio](docs/screenshots/loading_launch.jpg) | ![Entrada en una tienda](docs/screenshots/loading_shop.jpg) | ![El ascensor](docs/screenshots/loading_lift.jpg) |

*Las capturas muestran la interfaz en inglés o en francés; el juego está en español, inglés, francés y alemán.*

## Descargar y jugar

El juego está disponible en español, inglés, francés y alemán.

### Navegador (PC, Xbox, tableta)
**https://flyinnrabbit.github.io/lanterne-des-profondeurs/** — se actualiza solo con cada envío.
Funcionan teclado, ratón y mando; las partidas se guardan en el navegador.
- **Xbox Series**: abre **Microsoft Edge**, ve a la dirección de arriba y pasa a pantalla completa.
- La primera carga descarga unos 55 MB.
- En el navegador, los nombres de las teclas siguen el teclado QWERTY por defecto: elige otra
  distribución en **Controles → Teclado** si hace falta.

### Windows
Última versión: pestaña **Releases** → `LanterneDesProfondeurs_Windows.zip`, descomprímelo y ejecuta
`LanterneDesProfondeurs.exe`. El ejecutable no está firmado: Windows SmartScreen puede mostrar
«Windows protegió su PC» → *Más información* → *Ejecutar de todas formas*.

### macOS (Intel y Apple Silicon)
1. Descarga `LanterneDesProfondeurs_macOS.zip` de la Release, descomprímelo y arrastra
   **Lanterne des Profondeurs** a la carpeta Aplicaciones.
2. La aplicación no está notarizada por Apple (haría falta una cuenta de desarrollador de pago), así
   que macOS la bloquea la primera vez:
   - **clic derecho (o Ctrl + clic) en la aplicación → Abrir**, y luego **Abrir** en el cuadro;
   - en **macOS 15 (Sequoia)** y posteriores: abre la aplicación una vez y luego **Ajustes del
     Sistema → Privacidad y seguridad** → abajo, **«Abrir igualmente»**;
   - si macOS dice que «la aplicación está dañada», abre el **Terminal** y escribe:
     `xattr -cr "/Applications/Lanterne des Profondeurs.app"`, y vuelve a abrirla.
3. Después el juego se inicia con normalidad. Los mandos de Xbox y PlayStation funcionan.
   Partidas: `~/Library/Application Support/Godot/app_userdata/Lanterne des Profondeurs/`.

### Linux y Steam Deck
En las Releases: `LanterneDesProfondeurs_Linux_SteamDeck.tar.gz` (Linux x86_64).

**Linux**: extrae el archivo y ejecuta `./LanterneDesProfondeurs.x86_64`
(si hace falta: clic derecho → Propiedades → «Permitir ejecutar», o `chmod +x`).

**Steam Deck**:
1. Pasa al **modo Escritorio** (botón Steam → Apagar → Cambiar a escritorio).
2. Descarga el archivo desde la página de Releases con el navegador y extráelo
   (clic derecho → *Extraer aquí*), por ejemplo en `~/Games/Lanterne`.
3. Abre Steam en modo Escritorio → *Juegos* → **Añadir un juego que no es de Steam a mi biblioteca**
   → *Examinar* → elige `LanterneDesProfondeurs.x86_64` → *Añadir programas seleccionados*.
4. Vuelve al **modo Juego**: el juego está en la biblioteca (pestaña *No de Steam*).
   Se inicia a pantalla completa, los controles de la Deck funcionan directamente
   (A saltar, X atacar, RT embestida, LB parada, Y definitiva, B curar) y se llena la pantalla 16:10.
   El icono `LanterneDesProfondeurs.png` incluido se puede elegir en las propiedades del acceso directo.

### Versión portátil
`LanterneDesProfondeurs_Windows_Portable.zip` / `LanterneDesProfondeurs_Linux_Portable.tar.gz`:
el juego con un archivo `portable.txt`. Mientras ese archivo esté junto al ejecutable, el progreso,
los ajustes y las teclas se guardan en la carpeta `sauvegardes` del juego (no se escribe nada en otro
sitio): copia la carpeta en una memoria USB para llevarte el juego y tu partida. Borra `portable.txt`
para volver a la ubicación habitual de las partidas.

### Abrir el proyecto en Godot
1. Instala Godot 4 (versión estándar, no .NET): https://godotengine.org/download
2. En el gestor de proyectos: **Importar** → elige la carpeta del proyecto (el archivo `project.godot`).
3. Pulsa **F5**.

Para exportarlo tú mismo: *Editor → Administrar plantillas de exportación → Descargar e instalar*,
y luego *Proyecto → Exportar* con uno de los perfiles ya incluidos (Windows Desktop, Linux, macOS, Web).

## Controles (teclado y mando Xbox / XInput)

Las teclas se guardan **por posición** en el teclado: te mueves con **W A S D** en QWERTY y QWERTZ, y
con **Z Q S D** en AZERTY, sin configurar nada. Los nombres que aparecen siguen la distribución del
sistema; si se detecta mal (máquina virtual, Steam Deck…), elige **Controles → Teclado: AZERTY /
QWERTY / QWERTZ**. La tabla usa los nombres QWERTY.

| Acción | Teclado | Mando |
|---|---|---|
| Moverse | A / D o flechas | Stick izquierdo / cruceta |
| Saltar (mantener = más alto) | Espacio | A |
| Atacar | J o **clic izquierdo** | X |
| Atacar hacia arriba / abajo | W o S + J | arriba/abajo + X |
| Agacharse (esquiva los ataques altos) | S o flecha abajo (mantener, en el suelo) | abajo |
| Picado (en el aire) | S + K | abajo + RT |
| Embestida / esquiva | K o Mayús | RT |
| Parada | I o **clic derecho** | LB |
| Hechizo de alma (33 de alma) | O o clic central | RB |
| Definitiva (barra llena) | U o R | Y |
| Curarse (mantener, 33 de alma) | L o F | B |
| Descansar en un banco | W / flecha arriba | arriba |
| Mapa | M | R3 |
| **Pausa y menú** | **Esc o P** | **Menú (Start)** |
| **Inventario / equipo** | **Tab o B** | **Vista (Back)** |

### Menú «Controles»
Esc → **Controles**: haz clic (o confirma con el mando) en una casilla y pulsa la nueva tecla.
Cada acción tiene 2 teclas y 1 botón de mando; si la tecla ya está en uso, las dos acciones se
intercambian. Supr borra una tecla, Esc cancela. Las casillas también aceptan botones del ratón
(izquierdo, derecho, central, laterales). Los menús y el inventario se manejan con el ratón; en el
juego, el cursor se oculta tras 2 segundos sin moverse.
Los ajustes se guardan solos (`user://controls.cfg`). El stick izquierdo siempre mueve al héroe.

### Iconos de controles
Las ayudas en pantalla, carteles, mensajes y el menú Controles muestran **iconos**: teclas y botones
de ratón dibujados para el teclado, A/B/X/Y en color, LB/RT… para un mando Xbox, y cruz / círculo /
cuadrado / triángulo, L1/R2… para un mando PlayStation (símbolos genéricos).

### Mando (XInput)
En Windows, Godot lee los mandos Xbox mediante XInput: basta con conectar uno. El juego muestra el
mando detectado, usa los nombres de botones de Xbox, acepta los gatillos en los menús y vibra con los
golpes, el daño y los jefes. La vibración se desactiva en el menú Controles. Las ayudas en pantalla
siguen el último dispositivo usado (teclado o mando).

## Partidas y dificultad

**3 ranuras de guardado**: pantalla de título → «Partidas». Cada ranura tiene su propia partida y su
propia dificultad (por ejemplo una partida Normal y otra Pesadilla). «Continuar» retoma la última ranura
jugada. Logros, cosméticos y opciones son comunes a todas las ranuras. El guardado es automático.

Al empezar: **Jugar** → elige la dificultad (y la opción «Saltar el tutorial»).
También durante una partida: Pausa → «Nueva partida…».

**Una sola vida** (casilla al crear la partida, en todas las dificultades): la primera muerte borra la
ranura (fuera del tutorial). Una pequeña calavera junto a las esquirlas lo recuerda. Los logros y los
cosméticos se conservan, porque son comunes a todas las partidas.

| Dificultad | Alma / definitiva | Enemigos | Daño recibido |
|---|---|---|---|
| Fácil | +35 % / +30 % | más lentos, -25 % de vida, menos numerosos, sin élites | 1 |
| Normal | normal | normales; élites: 8 % al principio, hasta 35 % en lo más hondo | 1 |
| Difícil | -25 % / -20 % | +25 % de velocidad, más agresivos, +35 % de vida, +35 % de enemigos; élites: del 25 % al 65 % | 1 |
| Pesadilla | -40 % / -35 % | +40 % de velocidad, muy agresivos, +60 % de vida, +60 % de enemigos; élites: del 42 % al 85 % | **2** |

Los jefes también son más rápidos y resistentes según la dificultad, pero sus preparaciones nunca bajan
de 0,25 s: incluso en Pesadilla, cada ataque se puede leer y esquivar. Un jefe nunca tiene más de 3 esbirros
invocados vivos a la vez, y no intenta invocar cuando su enjambre está completo.

**Esquirlas**: cada enemigo da un 10 % más por nivel (nivel 6: +50 %), el doble una élite, y el jefe da
60 + 20 × nivel. En Fácil, donde hay menos enemigos y ninguna élite, dan un 40 % más y el jefe un 10 % más:
se progresa más o menos al mismo ritmo que en Normal. Difícil y Pesadilla dan más, gracias a sus enemigos
y élites adicionales.

## El Santuario y los niveles sin fin

Tras el tutorial llegas al **Santuario de la Linterna**, el corazón del juego:
- **Banco**: descansar, recuperar vida, cambiar de emblemas. En las profundidades, cada banco cura solo una vez
  por zona (puedes volver a sentarte para fijar tu punto de regreso y cambiar emblemas), y no justo después de
  un combate (1,5 s).
- **Mercader**: cambia tus esquirlas por **máscaras de vida** (+1 vida máxima, hasta 4), **muescas** de emblema
  y los **emblemas** que aún no has encontrado. Su vieja carreta y su cochinilla de tiro esperan a su lado.
- **Scriptorium** (en su plataforma, encima del mercader): **Maese Pluma**, el búho archivero, lleva los
  registros de tu partida en un gran libro: estadísticas, récords, **bestiario**, **guardianes** vencidos (con
  descripciones y consejos) y tu **colección de emblemas**.
- **Arsenal**: comprar y equipar tu arma base. **Probar** presta un arma mientras sigas en el Santuario.
- **Maniquí de entrenamiento** (a la derecha del arsenal): muestra tu daño por segundo.
- **Sastra**: el guardarropa y los cosméticos.
- **Ascensor**: elegir el **nivel** al que bajar, y los modos especiales (más abajo).
- **Habitantes** que llegan al superar niveles:
  - la **herrera** (nivel 1): forja cada arma hasta el **nivel 5**;
  - el **joyero**, un faraón momificado sobre su plataforma (nivel 2): refuerza **todos tus emblemas** hasta
    el **nivel 3**;
  - el **cartógrafo** (nivel 2): vende una pluma que revela todo el mapa;
  - el **anciano** (nivel 3): la historia de la Linterna.

Un **nivel = 2 zonas generadas** (dos biomas sacados de los 12) **y luego un jefe**. Superarlo te devuelve al
Santuario y **desbloquea el nivel siguiente**, sin fin. Tu vida se conserva en el portal entre las dos zonas
(Fácil y Normal devuelven 1 máscara, Difícil y Pesadilla nada).

**Profundidad**: la vida de los enemigos sube un 18 % por nivel y se detiene en ×4,6 (nivel 21). Velocidad,
agresividad, número y élites suben hasta el nivel 10 a 15 más o menos. El daño recibido nunca aumenta con la
profundidad.

**Morir** en un descenso: vuelves al Santuario y pierdes el botín recogido desde la salida (esquirlas, emblemas,
muescas), pero los niveles desbloqueados y las compras se quedan. Tu **sombra** guarda las esquirlas perdidas
donde caíste: vuelve al mismo nivel y supéralo para recuperarlas (una nueva muerte la sustituye).

### Los modos especiales del ascensor
- **Maldiciones** (Prisa, Oscuridad, Fragilidad): juega cualquier nivel maldito por +50 a 60 % de esquirlas.
- **Descenso del día**: las mismas zonas para todos, gana el mejor tiempo. Clasificación en línea por
  dificultad (top 10 y tu puesto); tu tiempo se envía con el nombre que elijas, y el envío se puede desactivar.
- **Desafío semanal**: uno por semana, en el nivel 4, con una maldición y un arma impuesta que cambian cada
  semana, y su propia clasificación.
- **Fantasma**: en el Descenso del día y el Desafío semanal, el fantasma del primero de la clasificación recorre
  la zona a tu lado (una silueta encapuchada translúcida, con su nombre). Se oculta desde la pantalla de
  clasificaciones.
- **Desafío de jefes** (tras el nivel 6): los jefes seguidos, cronometrados. +600 esquirlas cada vez, +200 más si
  bates tu récord, una muesca de emblema en la primera victoria, y una clasificación en línea.
- **Clasificaciones**: del día, de la semana y del Desafío de jefes, todas desde el ascensor.

Hay 29 **logros**, visibles desde la pantalla de título o el menú de pausa.

### Los 12 biomas

| Bioma | Características |
|---|---|
| Las Profundidades | cuevas azuladas, colinas y pozos, reptantes y voladores |
| Los Jardines Fúngicos | paredes que escalar, pozos, muchos escupidores |
| La Ciudadela Sumergida | pilares sobre pinchos, arenas, puentes |
| Las Minas de Cristal | grandes abismos (Embestida), pasillos bajos, voladores |
| La Forja Ardiente | pinchos por todas partes, brasas, muchos reptantes |
| La Biblioteca Silenciosa | escalada y plataformas, enjambres de voladores |
| El Abismo Helado | nieve, puentes frágiles y abismos, escupidores |
| La Colmena Zumbante | pasillos estrechos invadidos por voladores |
| El Osario | colinas y arenas, reptantes y escupidores |
| La Jungla Anegada | plataformas, islotes y puentes de lianas, limos y monos |
| Las Arenas Enterradas | dunas, fosos y bloques frágiles, escorpiones y topos |
| El Templo Antiguo | columnas, arenas y cuchillas, goblins y lanceros |

### Profundidades: grutas y estratos

| | | |
|---|---|---|
| ![Gruta de los Jardines Fúngicos](docs/screenshots/grotto_gardens.jpg) | ![Gruta de la Biblioteca Silenciosa](docs/screenshots/grotto_library.jpg) | ![Torno al pie de un pozo (Minas de Cristal)](docs/screenshots/strata_winch.jpg) |

Los niveles ya no son simples franjas planas:
- **Grutas** (todos los biomas): agujeros en el camino llevan a una gruta excavada bajo el nivel,
  dispuesta según el bioma (setas gigantes, estanterías, celdas de panal, sala inundada, cripta de
  huesos, estalagmitas de cristal, puente de hielo frágil, fosas de brasas…). Cada una esconde un
  **cofre**, enemigos y a veces un **mercader** o un emblema.
- **Estratos** (las Profundidades, las Minas de Cristal, el Abismo Helado, la Forja Ardiente): el nivel
  se hunde en tres pisos. El primero va hacia la derecha, el segundo vuelve hacia la izquierda y el
  tercero va de nuevo a la derecha hasta la salida. Un pozo ancho une cada piso con el siguiente.
- **Torno**: al pie de cada gruta y de cada pozo cuelga una cuerda de un torno. **Arriba** a su lado
  (o contra la cuerda en pleno salto, o **Abajo** al borde del pozo) para agarrarte, y luego **Arriba** / **Abajo**
  para subir o bajar a tu ritmo. **Salto** para saltar de la cuerda, **Abajo + Salto** para soltarte.

### Salas especiales
- **Tesoro**: un suelo agrietado esconde un cofre; rómpelo (golpes hacia abajo o picado).
- **Desafío cronometrado**: toca la estela del reloj de arena y llega a la bandera en 13 segundos.
- **Arena de élites**: despierta el altar, vence a tres élites y gana esquirlas y un emblema.
- **Mercader ambulante**: a veces cerca del banco de mitad de zona (las compras cuentan como botín).

### Trampas y plataformas
Las zonas tienen relieve (el suelo sube y baja de una sala a otra) y salas variadas: islas flotantes, pozos en
zigzag, caminos dobles, cuevas bajas, puentes frágiles, abismos con plataforma móvil, pasillos de cuchillas.
- **Fosos de pinchos**: caer cuesta una máscara y te devuelve al último suelo seguro.
- **Tótem de dardos**: dispara a la altura de la cabeza. Agáchate, salta o para.
- **Cuchilla péndulo**: su punto más bajo pasa justo por encima del héroe agachado.
- **Estalactita**: cae cuando pasas por debajo.
- **Bloques frágiles**: se hunden poco después de pisarlos y luego se rehacen.
- **Plataforma móvil**: va y viene sobre un abismo.
- **Plataforma que se derrumba** (Minas de Cristal): cede bajo tus pies en una lluvia de cascotes.

**Trampas de bioma**, con un ciclo legible (avisan antes de golpear). Hay de 1 a 4 por zona según la
profundidad, nunca unas encima de otras y nunca cerca del jefe:

| Trampa | Biomas |
|---|---|
| Pinchos que salen y entran | todos |
| Hongo de gas tóxico | Jardines Fúngicos, Colmena Zumbante, Jungla Anegada |
| Géiser de llamas | Forja Ardiente, Arenas Enterradas |
| Géiser de hielo | Abismo Helado |
| Onda de cristal que corre por el suelo | Minas de Cristal |
| Remolino de páginas voladoras | Biblioteca Silenciosa |
| Mano esquelética que te agarra (la embestida te libera) | Osario |
| Tubería de vapor, con los colores del bioma | Ciudadela Sumergida, Templo Antiguo |
| Gota que cae | Las Profundidades |

Las trampas también hieren a los enemigos, pero solo a los que acabas de golpear o de lanzar.

## Combate

- **Combo en el suelo**: tres golpes; el 3.º es un **golpe final** más amplio y fuerte.
- **Golpe cargado**: mantén Atacar unos 0,7 s (la aguja brilla) y suelta = un **torbellino** que
  golpea alrededor.
- **Estocada**: ataca **durante (o justo después de) una Embestida** = un golpe perforante en línea recta.
  **Lanza lejos a los enemigos** (no a los jefes, ni con los shurikens), y vuelve a empujar 2 s después.
- **Combo aéreo** (distinto del de suelo): tajo, **tajo ascendente** que te vuelve a elevar y un
  **giro** que golpea alrededor.
- **Picado**: en el aire, abajo + Embestida. Caes en picado, rebotas en el enemigo golpeado o provocas
  una **onda expansiva** al aterrizar. Uno por salto. Tras un picado aterrizas de pie: solo vuelves a
  agacharte después de soltar abajo.
- **Agacharse**: mantén abajo en el suelo. Más lento, pero los ataques altos pasan por encima (estocada
  del lancero, barrido del Coloso, dardos, cuchillas pendulares). Atacar agachado = golpe bajo.
- **Hechizo de alma**: una hoja de alma lanzada hacia delante que **atraviesa** a los enemigos (cuesta
  33 de alma, lo mismo que una curación: tú eliges).
- **Parada**: una ventana corta (0,2 s). Un contacto parado aturde al enemigo; un jefe parado queda
  aturdido un segundo. Una espora parada vuelve hacia los enemigos. Da alma y mucha carga de definitiva.
- **Parada perfecta**: parar en el último instante muestra «¡PERFECTA!»; una **luz dorada** brilla en
  la punta del arma y el siguiente golpe es **crítico: daño ×1,5** (redondeado hacia arriba, siempre al menos +1).
- **Esquiva**: durante la Embestida atraviesas enemigos y proyectiles (no los pinchos).
- **Definitiva**: la barra dorada se llena al golpear (+6) y al parar (+25). Llena, el héroe se queda
  quieto, se carga medio segundo (invulnerable) y libera una onda expansiva: 8 de daño a todo lo
  cercano, y las esporas se destruyen.
- Un golpe de aguja también destruye las esporas enemigas.
- **Retroceso**: cada golpe empuja un poco al héroe (unos 9 px en los dos primeros golpes del combo,
  24 px en el golpe final, nada agachado): todo el combo alcanza a un objetivo que no se mueve.
- **Avisos de ataque**: un «!» amarillo sobre un enemigo que prepara un golpe; naranja con una flecha
  cuando es un ataque alto (agáchate).

### El arsenal

| Arma | Precio | Estilo | Nivel 2 (herrera) |
|---|---|---|---|
| Aguja del Vigía | — | equilibrada | el golpe final lanza una corta hoja de aire |
| Garras Gemelas | 180 | una garra en cada mano: cada ataque golpea dos veces (0,6 de daño por garra, 1 por garra en un golpe potente), muy rápidas, alcance corto, la mitad de alma por garra | sangrado: cada golpe de garra tiene un 20 % de probabilidad (50 % con el Colmillo Sangriento) de quitar 1 de vida más un segundo después |
| Látigo de Zarzas | 150 | alcance muy largo hacia delante y hacia arriba, algo más lento | atrae a los enemigos pequeños |
| Martillo de Yunque | 220 | lento, +1 de daño, gran retroceso, aturde | el golpe final lanza una onda expansiva a ambos lados (sube los escalones) |
| Estrellas de Luna (shurikens) | 260 | a distancia; golpe final = 3 estrellas, torbellino = 8 en círculo, estocada = una gran estrella perforante | vuelven como un bumerán y golpean de nuevo |
| Guadaña del Espigador | 240 | gran arco en media luna delante y arriba, siega a varios enemigos; el golpe final es un torbellino | cada enemigo segado devuelve alma, el torbellino lanza una hoja fantasma que vuelve |
| Bastón de Anillos de Cobre | 230 | estocada larga y rápida; agachado, salto con pértiga | el golpe final cae como un golpe gigante y lanza una onda por el suelo |

La herrera sube luego cada arma hasta el **nivel 5**: el nivel 2 da el efecto especial de arriba (nivel 1 superado), los niveles 3, 4 y 5 (niveles 2, 3 y 5) refuerzan lo que mejor hace el arma: +1 de daño, +12 % de alcance, +10 % de velocidad de ataque o +8 % de probabilidad de crítico.

Estrellas de Luna: como mucho 3 estrellas simples en pantalla, menos alma por golpe, y los jefes solo
reciben el 75 % del daño a distancia.

### Emblemas
Tab abre el inventario (el juego se pausa): objetos, esquirlas, estadísticas y la cuadrícula de
**emblemas** que encontrar en las zonas. Cada emblema cuesta muescas; empiezas con 3 y puedes encontrar
(anillos dorados) o comprar más. Solo puedes cambiar el equipo **sentado en un banco**.

| Emblema | Coste | Efecto |
|---|---|---|
| Aguja Larga | 2 | alcance de los golpes +40 % |
| Corazón de Cristal | 2 | +2 máscaras de vida |
| Capa Veloz | 1 | carrera +12 %, la Embestida se recarga el doble de rápido |
| Caparazón Espinoso | 2 | unas espinas hieren a los enemigos cercanos cuando te golpean |
| Espejo Perfecto | 1 | ventana de parada de 0,35 s |
| Alma Voraz | 2 | más alma y definitiva en cada golpe |
| Concentración Viva | 1 | curación casi el doble de rápida |
| Fuerza Bruta | 3 | +1 de daño, pero golpes un 20 % más lentos |
| Meteoro Ardiente | 2 | un picado que acierta prepara un golpe crítico |
| Reposo de la Sombra | 2 | agachado fuera de combate, el alma sube despacio hasta 33; curación agachado 1,5× más rápida |
| Eco Perfecto | 2 | una parada perfecta lanza una hoja de alma gratis |
| Paso Ligero | 1 | cruzar una trampa sin ser golpeado da 5 esquirlas |
| Hoja de Rebote | 1 | rebotar en un enemigo te impulsa un 25 % más alto y devuelve 6 de alma |
| Yunque Caído | 2 | picado +1 de daño, onda expansiva un 50 % más ancha |
| Parada Cortante | 2 | una parada lograda inflige 2 de daño al atacante |
| Embestida Espectral | 2 | la Embestida hiere a los enemigos que atraviesa (1 de daño) |
| Cosecha de Alma | 1 | cada enemigo vencido devuelve 8 de alma |
| Olfato del Saqueador | 1 | cofres de las grutas y escondites: +60 % de esquirlas |
| Nudo de Escalador | 1 | trepas por las cuerdas el doble de rápido; el primer agarre de cada cuerda devuelve 33 de alma |
| Último Aliento | 3 | un golpe fatal te deja con 1 máscara, una vez por zona |
| Colmillo Sangriento | 2 | +30 % de probabilidad de hacer sangrar con cada golpe, con cualquier arma (1 de daño un segundo después); 50 % con las Garras Gemelas niv. 2 |
| Alma Ardiente | 2 | la hoja de alma (hechizo) inflige 1 de daño más |
| Linterna Frugal | 1 | curarse solo cuesta 27 de alma en vez de 33 |
| Ala de Polilla | 3 | permite un segundo salto en el aire, algo más bajo que el primero |
| Sombra Gemela | 2 | dos Embestidas en el aire en vez de una antes de tocar el suelo |
| Piel de Piedra | 2 | tras recibir un golpe, la invulnerabilidad dura un 40 % más |
| Bolsa del Mercader | 1 | los enemigos vencidos sueltan un 20 % más de esquirlas |
| Cáliz de Savia | 3 | cada 15 enemigos vencidos, recupera una máscara |
| Corazón de Tormenta | 2 | el definitivo se carga un 25 % más rápido (golpes y paradas) |
| Onda Trueno | 2 | la onda del definitivo es un 30 % más amplia |
| Suelas de Corteza | 1 | el primer golpe de trampa de cada nivel se ignora |
| Péndulo | 1 | una parada exitosa recarga al instante la Embestida y da 5 de alma más |
| Colmillo del Cazador | 2 | +1 de daño contra enemigos por debajo del 40 % de su vida |
| Escarcha Mordaz | 2 | 15 % de probabilidad por golpe de congelar brevemente al enemigo (0,6 s, no jefes) |
| Ojo de Halcón | 2 | +8 % de probabilidad de golpe crítico |
| Punta de Obsidiana | 2 | los golpes críticos infligen ×2 en vez de ×1,5 |
| Velo de Alma | 3 | con 33 de alma, un golpe recibido lo absorbe el alma en vez de las máscaras (una vez cada 8 s) |
| Furia del Herido | 2 | con 1 máscara, +1 de daño en todos los golpes |
| Cometa | 1 | el golpe cargado (torbellino) se prepara un 40 % más rápido |
| Savia Bendita | 2 | cada curación tiene un 25 % de probabilidad de recuperar una máscara más |
| Danza de Hojas | 2 | el golpe final del combo inflige +1 de daño y da 4 de alma |
| Oración del Banco | 1 | sentarse en un banco llena el alma hasta 33 |

El **joyero**, un faraón momificado que se instala en el Santuario tras el nivel 2, refuerza **todos los emblemas que tienes**, equipados o no: nivel 2 (nivel 2 superado) y luego nivel 3 (nivel 4). Cada emblema gana potencia (por ejemplo Corazón de Cristal: +2, +3 y luego +4 máscaras). El inventario y el Scriptorium muestran los 42 emblemas en una lista desplazable.

Los efectos se definen en `scripts/charms.gd` y se aplican en `scripts/player.gd`.

## Enemigos
- **Reptante**, **Volador**, **Escupidor**: lo básico. El reptante te detecta y embiste, el volador rodea los muros para alcanzarte, el escupidor lanza esporas.
- **Saltador**: un saltamontes que salta sobre ti.
- **Guardia con escudo**: bloquea los golpes de frente. Golpéalo desde arriba, por detrás o con la definitiva.
- **Bulbo explosivo**: rueda hacia ti, se enciende y explota (también hiere a los enemigos cercanos).
- **Tejedora**: una araña colgada del techo que escupe telarañas pegajosas (el Impulso las rompe), cae sobre su presa y vuelve a subir por su hilo.
- **Lancero**: toma posición y lanza una larga estocada; una parada lo aturde.
- **Espectro**: se desvanece (intocable), reaparece cerca de ti y lanza un orbe lento.
- **Mono ladrón**: salta por todas partes, lanza frutas y te roba esquirlas; mátalo antes de que huya para recuperarlas.
- **Mímico**: un falso escondite de tesoro que muerde y salta hacia ti.
- **Polilla apagadora**: llega en grupo y lo oscurece todo girando alrededor de tu linterna.
- **Topo excavador**: excava hasta ti y surge bajo tus pies tras un aviso (suelo agrietado, «!»).
- **Limo**: avanza a saltos; al morir, se divide en dos limos pequeños.
- **Escorpión**: arma el aguijón y pica; el veneno cuesta una máscara más poco después (nunca mata).
- **Goblin**: lanza dagas de lejos, golpea dos veces de cerca y huye cuando flaquea.
- **Élites** (brillo rojo): más vida, más rápidos, botín doble y un ataque extra — el reptante embiste,
  el volador cae en picado, el escupidor lanza 3 esporas, el saltador encadena dos saltos, el guardia
  carga con su escudo.

Ningún enemigo puede golpear a través de una pared. Los enemigos duros y las élites son más frecuentes
cuanto más bajas.

## Jefes

El Guardián siempre es el primero; los otros cinco llegan en un **orden propio de cada partida** y
luego el ciclo vuelve a empezar, más duro. Cada uno tiene su forma, sus ataques, una **fase 2** a media
vida y su propio tema musical. Parar un contacto aturde al jefe un segundo.

| Jefe | Estilo | Ataques |
|---|---|---|
| Guardián del Pozo | escarabajo acorazado | embestida anunciada, salto aplastante; fase 2: ondas expansivas en el suelo |
| La Abadesa Sumergida | reina de las esporas | embestida, salto, ráfaga en abanico, anillo de esporas (más denso en fase 2) |
| La Reina Enjambre | avispa gigante **voladora** | picados (encadenados en fase 2), ráfaga de aguijones dirigida, anillos en espiral, invoca voladores |
| El Coloso de Hueso | gigante de huesos | puñetazo al suelo (ondas + caída de rocas), barrido del brazo; fase 2: salto + fila de pilares de hueso |
| El Gusano de las Profundidades | gusano **excavador** | se entierra, un rastro de polvo lo delata, surge bajo tus pies escupiendo ácido; embestida; fase 2: tres embestidas desde el suelo + ondas |
| El Caballero Espectral | duelista fantasma | estocadas relámpago (combos ×3 en fase 2), **se teletransporta a tu espalda**, pilares espectrales en línea, ráfaga de brasas |

### Jefes finales
En el nivel 7 (y luego cada 7 niveles), un **jefe final**, cada uno con su tema. El sorteo da prioridad a un
jefe final que **nunca has vencido**: te enfrentas a los cuatro en cuatro combates finales (nivel 28 como
mucho). El Descenso del día, el Desafío semanal y el Desafío de jefes mantienen el mismo sorteo para todos.
- **La Sombra de la Linterna**: coronas de brasas, barrido a la altura de la cabeza, lluvia de cenizas,
  columnas de luz, espectros en la fase 2.
- **El Cerbero de las Profundidades**: aliento de brasas de las tres cabezas, salto con onda expansiva, triple
  mordisco a la altura de la cabeza (agáchate), aullido que hace brotar llamas.
- **El Centauro Arquero**: galopa de un lado a otro de la arena, ráfagas de flechas, lluvia de flechas marcada
  en el suelo, lanzazo a la altura de la cabeza (agáchate), salta por encima del jugador.
- **El Ojo de Abajo**: tentáculos que brotan del suelo, un rayo que barre la arena a la altura de la cabeza
  (agáchate) o a ras de suelo (salta), espirales de esporas, ojos voladores.

Vencerlo lanza **el final**: la Linterna vuelve a encenderse, la luz sube nivel a nivel hasta el Santuario y
luego la superficie, y pasan los créditos. Después, los niveles continúan.
Logro «Los cuatro guardianes»: vence a los cuatro.

## Duelo local: la Arena de las Sombras

Dos jugadores se enfrentan en la misma pantalla. Para jugar a distancia, usa **Parsec**: comparte la pantalla
y pasa al juego el mando del segundo jugador.
1. Activa **Opciones → Arena de las Sombras en el Santuario** (desactivado por defecto): el estandarte de la
   arena aparece en el Santuario.
2. Conecta un segundo mando. El jugador 1 juega con el teclado (o el primer mando), el jugador 2 con el segundo.
3. En el estandarte, cada jugador elige su arma y luego **¡Luchar!**

Reglas: en igualdad. Sin emblemas, todas las armas al nivel 2, 9 máscaras cada uno, gana el primero en ganar
**3 rondas**. La parada funciona contra el otro jugador y lo empuja; un proyectil nunca golpea a quien lo
lanzó. La arena tiene un suelo y tres plataformas al alcance de un salto; los dos jugadores empiezan cara a cara.

## Gráficos

Todo está dibujado con código, con un estilo detallado y pintado:

- **roca** texturizada por un shader propio de cada bioma (estratos, sillares, cristal, vetas de lava,
  hielo, panal, huesos), más oscura en profundidad y con los bordes iluminados;
- **suelos decorados** según el bioma (hierba, setas luminosas, cristales, cráneos, libros, velas,
  nieve, miel) y **fondos con paralaje** en tres planos con niebla y rayos de luz;
- **héroe, enemigos, 10 jefes y habitantes del Santuario** con sombreado, brillos y detalles;
- **trampas, rejas, pilares de ataque, portal de salida** (un diseño por bioma) y **el final**;
- **emblemas**: cada uno tiene su medallón grabado y su icono; los **golpes de arma** dejan estelas pintadas;
- **interfaz**: frasco de alma de cristal con aro de latón, máscaras pintadas, barra de definitiva de
  latón, cristal de esquirlas facetado y minimapa de pergamino;
- **menús y pantalla de título**: fondo pintado (pozo, linterna, brasas), paneles de madera oscura y latón;
- **efectos de combate**: estrella de impacto, anillo de muerte con humo y restos, esquirlas que vuelan
  hacia el héroe, polvo al aterrizar, imagen residual de la Embestida, proyectiles con estela;
- **ambiente por bioma**: esporas y luciérnagas, nieve, páginas volando, brasas, fuegos fatuos, goteo
  del techo, lava que burbujea, grupos de cristales luminosos;
- **mapa** dibujado como un mapa perdido: pergamino rasgado, doblado, manchado y quemado.

## Mapa, opciones y accesibilidad
- **Mapa** (M / R3): todo lo que has descubierto de la zona, con un pictograma y una leyenda para cada
  lugar encontrado (banco, salida, mercader, habitantes, cofres, emblemas, altar, desafío, sombra…).
  **Minimapa** en la esquina superior derecha (Opciones).
- **Idioma**: Automático (idioma del sistema), Français, English, Español, Deutsch.
  Las traducciones están en `tools/translations.py`; `python3 tools/translations.py` regenera
  `scripts/translations.gd`.
- **Tamaño de la interfaz** (60–160 %) y **de los menús** (60–130 %), **zoom de la cámara**,
  **pantalla completa** (también F11), **sincronización vertical**.
- **Calidad gráfica**: Alta, Equilibrada (sin rayos de luz ni bancos de niebla en el fondo, la mitad de
  partículas) o Baja (solo el fondo lejano, sin luces 2D salvo las del héroe, sin partículas ni viñeta).
  Equilibrada por defecto en Mac y en el navegador. El cambio es inmediato.
- **Barras de vida de los enemigos** y **daño infligido** mostrados un momento arriba a la derecha.
- **Ayudas en pantalla**, **temblor de pantalla** (0–150 %), **pausa al impacto**, **vibración** del mando.
- **Accesibilidad**: peligros de alto contraste (daltonismo), agacharse en modo alternar, velocidad
  del juego 100 / 90 / 80 / 70 %.
- **Estadísticas del descenso** (enemigos, daño, críticos, paradas perfectas, golpes recibidos, tiempo)
  mostradas al volver al Santuario.

Todo se guarda en `user://settings.cfg`.

## Cosméticos y guardarropa
La **costurera** del Santuario (a la izquierda del banco) abre el guardarropa, donde cambias el aspecto
del héroe con una vista previa animada: **59 cosméticos** en 6 categorías, 21 de ellos de temporada.
Todo es puramente visual y común a todas las ranuras. Las capas claras están atenuadas para no
deslumbrar sobre los fondos oscuros.

| Categoría | Ejemplos |
|---|---|
| Capa | sombra, brasa, musgo, escarcha, amatista, marfil, Vigía dorado, noche estrellada |
| Bufanda | turquesa, escarlata, dorada, blanca, violeta, brasa viva |
| Tocado | pluma de cuervo, vela, corona de flores, corona de oro, aureola, cuernos de hueso |
| Estela y brillo | color de la Embestida, del ojo y de los golpes: brasa, escarcha, espectro, oro puro… |
| Compañero | luciérnaga, polilla, fuego fatuo, linternita, avispa de la Reina (sigue al héroe, puramente decorativo) |
| Definitiva | aspecto de la onda expansiva: onda dorada, nova de escarcha, hoguera, eclipse, enjambre espectral |

Tres maneras de conseguirlos:
- **comprarlos** a la costurera con esquirlas (los más comunes);
- conseguir un **logro**: la recompensa aparece en la lista de logros;
- **vencer a un jefe**: el Coloso, la Reina, el Caballero, el Cerbero y el Ojo tienen cada uno un
  cosmético raro (25 % de probabilidad por victoria).

Hay **29 logros**, varios de los cuales dan un cosmético, entre ellos «Calendario del Vigía»: abrir el
regalo de las cuatro fiestas.

### Fiestas
Cuatro fiestas vuelven cada año, automáticamente, según la fecha. Durante cada una, el Santuario se
decora, se puede abrir un **regalo** una vez al año (el tocado de la fiesta y 50 esquirlas) y la
costurera vende la colección de la fiesta. Lo que ganes o compres se queda todo el año.

| Fiesta | Fechas | Regalo | A la venta |
|---|---|---|---|
| San Valentín | 8 – 16 de febrero | diadema de corazones | capa de rosas, estela corazón palpitante, corazoncito, definitiva Flechazo |
| Pascua | de la semana anterior a la semana posterior | orejas de conejo | capa de primavera, pollito, definitiva Eclosión |
| Vigilia de las Sombras | 20 de octubre – 2 de noviembre | calabaza tallada | capa de la vigilia, fuego de calabaza, murciélago, definitiva Nube de murciélagos |
| Navidad | 1 de diciembre – 6 de enero | gorro de Navidad | capa de Navidad, guirnalda luminosa, astas de reno, copos de nieve, copo viviente, definitiva Estrella de Navidad |

Cada fiesta tiene su **música** en el Santuario y en la pantalla de título, compuesta para el juego por
`tools/synth_fetes.py` (los mismos instrumentos que el resto de la banda sonora, ninguna melodía existente).

Para probar una fiesta fuera de temporada: inicia el juego con la variable de entorno
`LANTERNE_EVENT=noel` (o `halloween`, `valentin`, `paques`).

## Pantallas de carga
Todas dibujadas con código, con el estilo del juego; cualquier tecla las acelera.
- **Inicio**: en la oscuridad se enciende una linterna, suben las brasas y aparecen el título y un
  consejo, con una fila de brasas que se encienden a modo de barra de progreso, con el crepitar de
  las brasas de fondo (sintetizado por el juego).
- **Entrada en una tienda**: dos hojas de madera tachonadas de latón se cierran sobre el letrero del
  habitante (bolsa, yunque, mapa y pluma, pergamino, carrete, hojas cruzadas) y se abren sobre el mostrador.
- **Ascensor**: la jaula, con el héroe con su atuendo, baja por un pozo de piedra mientras traquetean
  las cadenas; el número del nivel está grabado en una placa de latón bajo la jaula. La zona se
  construye durante el descenso y la jaula se detiene con un golpe sordo. Vuelve a subir al Santuario
  tras superar un nivel. Las cadenas son una grabación libre de derechos (`sfx/lift_chains.ogg`).

## Actualizaciones automáticas
Al iniciarse, el juego (Windows, macOS, Linux, Steam Deck) consulta a GitHub la última Release.
Si es más reciente:
- se descarga un pequeño **parche** (scripts y shaders, unos cientos de KB) que se aplica en el
  siguiente inicio — la pantalla de título ofrece **«Actualización lista — reiniciar»**;
- si el parche no basta (música nueva, nueva versión de Godot), la pantalla de título muestra
  **«Versión disponible — descargar»** y abre la página de la Release.

El número de versión aparece en la parte inferior de la pantalla de título. **Opciones →
Actualizaciones automáticas** desactiva la descarga (el aviso sigue apareciendo). Sin red, no pasa
nada. Si el juego no arranca bien con un parche, este se elimina en el siguiente inicio. La versión del
navegador siempre está al día. Detalles: `scripts/updater.gd`; el parche lo genera el flujo de
publicación (perfil de exportación «Patch»). Aumenta `config/data_gen` en `project.godot` al añadir
música, sonidos o imágenes: las instalaciones antiguas verán entonces el aviso de descarga.

## Música y sonidos
Una banda sonora **original** generada para el juego (sin material de terceros): 32 pistas en bucle en
`music/` — una o dos por bioma que se encadenan con fundido, un tema por jefe, uno para el tutorial,
uno para el Santuario y uno por fiesta. Los efectos de sonido están en `sfx/`, con sonidos propios de
cada arma, de los golpes críticos y de la parada perfecta. Volúmenes **general / música / efectos** en
Opciones; la música baja un poco cuando el juego está en pausa.

## Pruebas
`tests/test_run.gd` recorre las zonas automáticamente (entradas simuladas, jefes, menús):
`godot --headless --fixed-fps 120 -s res://tests/test_run.gd`.
`tests/dump_maps.gd` genera cientos de zonas para comprobar que todas se pueden completar.

**Servidor de la clasificación**: `server/` (Cloudflare Worker + D1), desplegado por el workflow
«Classement (Cloudflare)» con los secretos `CLOUDFLARE_API_TOKEN` y `CLOUDFLARE_ACCOUNT_ID`.
`node server/test_worker.mjs` lo prueba; `node server/dev_server.mjs` lo ejecuta en local (juego lanzado con
`LANTERNE_LEADERBOARD_URL=http://127.0.0.1:8787`).

## Licencia
Copyright (c) 2026 FlyinnRabbit. **Todos los derechos reservados.** Puedes descargar, instalar y ejecutar el
juego para uso personal y no comercial. Modificarlo, redistribuirlo, publicarlo o venderlo, total o
parcialmente, no está permitido sin permiso por escrito. Texto completo: `LICENSE` (en inglés).
Excepción: `sfx/lift_chains.ogg` procede de la grabación *Chains Chiming* de freesound_community en Pixabay (licencia de contenido de Pixabay).
El juego se inspira en Hollow Knight (Team Cherry), pero no reutiliza ninguno de sus personajes ni recursos.
