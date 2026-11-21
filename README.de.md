# Lanterne des Profondeurs (Laterne der Tiefe)

<p align="center"><img src="docs/banner.jpg" width="900" alt="Der Held unter der Laterne, umgeben von den Wächtern der Tiefe"></p>

[English](README.md) · [Français](README.fr.md) · [Español](README.es.md) · **Deutsch**

2D-Roguelite-Metroidvania für **Godot 4.3+**, inspiriert von Hollow Knight: dunkle Höhlen,
Nadelkampf, Abprallen von Gegnern, Heilen mit Seele, Rastbänke und zehn Bosse.
Alles wird per Code gezeichnet: Das Spiel enthält kein einziges Bild.

**Im Browser spielen: https://flyinnrabbit.github.io/lanterne-des-profondeurs/**

## Trailer

<p align="center"><a href="docs/video/trailer_de.mp4"><img src="docs/video/preview.gif" width="820" alt="Trailer-Vorschau: zum Ansehen klicken"></a></p>

<p align="center"><b><a href="docs/video/trailer_de.mp4">▶ Trailer ansehen (58 s)</a></b> · <a href="docs/booklet/booklet_de.pdf">Booklet (PDF, 10 Seiten)</a></p>

## Das Ziel

Einst erleuchtete die Laterne der Tiefe jede Ebene bis zum Grund der Welt. Ihre Flamme ist erloschen.
Vom **Heiligtum** aus fährst du mit dem Aufzug Ebene für Ebene hinab, besiegst den Wächter jeder Ebene,
**entfachst die Laterne neu** und kehrst lebend zurück. Jeder Sturz bringt dich ins Heiligtum zurück: Dein
Schatten bewahrt die verlorenen Splitter dort, wo du gefallen bist, und der Aufzug merkt sich deine Tiefe.

<p align="center"><img src="docs/screenshots/surface.jpg" width="820" alt="Das Licht erreicht endlich die Oberfläche"></p>

## Auf einen Blick

- **12 Biome**; die Zonen werden bei jedem Abstieg neu erzeugt, mit Grotten, dreistöckigen Schichten, Seilwinden und Fallen, die zu jedem Biom passen
- **10 Bosse**: 6 Ebenenwächter und 4 Endbosse, jeder mit einer Phase 2 und eigener Musik
- **12 Champions**, einer pro Biom: doppelt so große Minibosse mit goldenem Umriss und eigener Lebensleiste
- **16 Gegnerarten**, vom Kriecher über den Mimik bis zum diebischen Affen und dem Goblin
- **Kampf**: 3-Schlag-Kombos, aufgeladener Wirbel, Luftkombo, Pogo, Sturzangriff, Sprintstoß, Parade (perfekt = kritischer Treffer), Seelenklinge, Ultimative
- **7 Waffen**, von der Schmiedin bis Stufe 5 geschmiedet, **42 Embleme**, vom Juwelier bis Stufe 3 verstärkt
- **Das Heiligtum**: Händler, Arsenal, Schmiedin, Juwelier, Kartograf, Schneiderin (59 Kosmetikartikel), Ältester, das Skriptorium und vier Feste im Jahr
- **4 Schwierigkeitsgrade** plus ein Ein-Leben-Modus, Flüche, **Tagesabstieg** und **Wochenherausforderung** mit Online-Bestenlisten und dem Geist des Ersten, **Boss-Ansturm** mit eigener Bestenliste
- Ein **lokales Duell** für zwei Spieler: die Schattenarena
- Deutsch, Französisch, Englisch und Spanisch; Tastatur und Xbox-/PlayStation-Controller; Browser, Windows, macOS, Linux und Steam Deck; automatische Updates
- Alles in Code gezeichnet; eigene Musik und Sounds

## Screenshots

| | |
|---|---|
| ![Das Heiligtum und seine Bewohner](docs/screenshots/sanctuary.jpg) | ![Der Aufzug fährt zur nächsten Ebene hinab](docs/screenshots/lift_descent.jpg) |
| ![Perfekte Parade im Beinhaus, auf Albtraum](docs/screenshots/nightmare_parry.jpg) | ![Die Laterne, neu entfacht](docs/screenshots/lantern_rekindled.jpg) |
| ![Die Pilzgärten](docs/screenshots/fungal_gardens.jpg) | ![Die Glühende Schmiede](docs/screenshots/blazing_forge.jpg) |
| ![Die Kristallminen](docs/screenshots/crystal_mines.jpg) | ![Der Eisige Abgrund](docs/screenshots/frozen_abyss.jpg) |
| ![Die Stille Bibliothek](docs/screenshots/silent_library.jpg) | ![Der Summende Stock](docs/screenshots/humming_hive.jpg) |
| ![Der Zerberus der Tiefe](docs/screenshots/boss_cerberus.jpg) | ![Der Knochenkoloss](docs/screenshots/boss_bone_colossus.jpg) |
| ![Die Schwarmkönigin](docs/screenshots/boss_swarm_queen.jpg) | ![Kampfeffekte und Geschosse](docs/screenshots/combat_effects.jpg) |
| ![Die Karte, ein verlorenes Pergament mit Legende](docs/screenshots/map.jpg) | ![Das Arsenal des Heiligtums](docs/screenshots/arsenal.jpg) |
| ![Die Schneiderin des Heiligtums](docs/screenshots/seamstress.jpg) | ![Die Garderobe](docs/screenshots/wardrobe.jpg) |
| ![Einige Outfits](docs/screenshots/outfits.jpg) | ![Ultimate-Stile](docs/screenshots/ultimates.jpg) |

**Feste im Heiligtum** (Valentinstag, Ostern, Schattenwacht, Weihnachten)

![Die vier Feste](docs/screenshots/festivals.jpg)

**Ladebildschirme** (Start, Betreten eines Ladens, Aufzug)

| | | |
|---|---|---|
| ![Start](docs/screenshots/loading_launch.jpg) | ![Betreten eines Ladens](docs/screenshots/loading_shop.jpg) | ![Der Aufzug](docs/screenshots/loading_lift.jpg) |

*Die Screenshots zeigen die englische Oberfläche; das Spiel gibt es auf Deutsch, Englisch, Französisch und Spanisch.*

## Herunterladen und spielen

Das Spiel ist auf Deutsch, Englisch, Französisch und Spanisch verfügbar.

### Browser (PC, Xbox, Tablet)
**https://flyinnrabbit.github.io/lanterne-des-profondeurs/** — wird bei jedem Push automatisch aktualisiert.
Tastatur, Maus und Controller funktionieren; Spielstände werden im Browser gespeichert.
- **Xbox Series**: **Microsoft Edge** öffnen, die Adresse oben aufrufen, Vollbild aktivieren.
- Beim ersten Laden werden etwa 55 MB heruntergeladen.
- Im Browser folgen die Tastennamen standardmäßig dem QWERTY-Layout: Wähle bei Bedarf unter
  **Steuerung → Tastatur** ein anderes Layout.

### Windows
Neueste Version: Reiter **Releases** → `LanterneDesProfondeurs_Windows.zip`, entpacken und
`LanterneDesProfondeurs.exe` starten. Die Datei ist nicht signiert: Windows SmartScreen kann
„Der Computer wurde durch Windows geschützt" anzeigen → *Weitere Informationen* → *Trotzdem ausführen*.

### macOS (Intel und Apple Silicon)
1. `LanterneDesProfondeurs_macOS.zip` aus dem Release herunterladen, entpacken und
   **Lanterne des Profondeurs** in den Programme-Ordner ziehen.
2. Die App ist nicht von Apple notarisiert (dafür wäre ein kostenpflichtiges Entwicklerkonto nötig),
   daher blockiert macOS sie beim ersten Start:
   - **Rechtsklick (oder Ctrl-Klick) auf die App → Öffnen**, dann im Dialog **Öffnen**;
   - unter **macOS 15 (Sequoia)** und neuer: die App einmal öffnen, dann **Systemeinstellungen →
     Datenschutz & Sicherheit** → ganz unten **„Dennoch öffnen"**;
   - meldet macOS, „die App ist beschädigt", öffne das **Terminal** und gib ein:
     `xattr -cr "/Applications/Lanterne des Profondeurs.app"`, dann die App erneut öffnen.
3. Danach startet das Spiel normal. Xbox- und PlayStation-Controller funktionieren.
   Spielstände: `~/Library/Application Support/Godot/app_userdata/Lanterne des Profondeurs/`.

### Linux und Steam Deck
In den Releases: `LanterneDesProfondeurs_Linux_SteamDeck.tar.gz` (Linux x86_64).

**Linux**: Archiv entpacken und `./LanterneDesProfondeurs.x86_64` starten
(falls nötig: Rechtsklick → Eigenschaften → „Als Programm ausführen erlauben" oder `chmod +x`).

**Steam Deck**:
1. In den **Desktop-Modus** wechseln (Steam-Taste → Ein/Aus → Zum Desktop wechseln).
2. Das Archiv im Browser von der Release-Seite herunterladen und entpacken
   (Rechtsklick → *Hier entpacken*), zum Beispiel nach `~/Games/Lanterne`.
3. Steam im Desktop-Modus öffnen → *Spiele* → **Ein Nicht-Steam-Spiel zu meiner Bibliothek hinzufügen**
   → *Durchsuchen* → `LanterneDesProfondeurs.x86_64` wählen → *Ausgewählte Programme hinzufügen*.
4. Zurück in den **Spielmodus**: Das Spiel steht in der Bibliothek (Reiter *Nicht-Steam*).
   Es startet im Vollbild, die Deck-Steuerung funktioniert sofort
   (A springen, X angreifen, RT Sprint, LB parieren, Y Ultimate, B heilen) und füllt den 16:10-Bildschirm.
   Das mitgelieferte Symbol `LanterneDesProfondeurs.png` kann in den Verknüpfungs-Eigenschaften gewählt werden.

### Portable Version
`LanterneDesProfondeurs_Windows_Portable.zip` / `LanterneDesProfondeurs_Linux_Portable.tar.gz`:
das Spiel mit einer Datei `portable.txt`. Solange diese Datei neben der ausführbaren Datei liegt,
werden Fortschritt, Einstellungen und Tasten im Spielordner `sauvegardes` gespeichert (sonst wird
nirgends etwas geschrieben): Kopiere den Ordner auf einen USB-Stick, um Spiel und Spielstand mitzunehmen.
Lösche `portable.txt`, um zum üblichen Speicherort zurückzukehren.

### Das Projekt in Godot öffnen
1. Godot 4 installieren (Standardversion, nicht .NET): https://godotengine.org/download
2. In der Projektverwaltung: **Importieren** → den Projektordner (die Datei `project.godot`) wählen.
3. **F5** drücken.

Selbst exportieren: *Editor → Exportvorlagen verwalten → Herunterladen und installieren*,
dann *Projekt → Exportieren* mit einem der mitgelieferten Profile (Windows Desktop, Linux, macOS, Web).

## Steuerung (Tastatur und Xbox-/XInput-Controller)

Tasten werden **nach ihrer Position** auf der Tastatur gespeichert: Auf QWERTY und QWERTZ bewegst du
dich mit **W A S D**, auf AZERTY mit **Z Q S D**, ganz ohne Einstellung. Die angezeigten Namen folgen
dem Layout des Systems; wird es falsch erkannt (virtuelle Maschine, Steam Deck …), wähle **Steuerung →
Tastatur: AZERTY / QWERTY / QWERTZ**. Die Tabelle verwendet die QWERTY-/QWERTZ-Namen.

| Aktion | Tastatur | Controller |
|---|---|---|
| Bewegen | A / D oder Pfeiltasten | Linker Stick / Steuerkreuz |
| Springen (halten = höher) | Leertaste | A |
| Angreifen | J oder **Linksklick** | X |
| Nach oben / unten angreifen | W oder S + J | oben/unten + X |
| Ducken (weicht hohen Angriffen aus) | S oder Pfeil unten (halten, am Boden) | unten |
| Sturzangriff (in der Luft) | S + K | unten + RT |
| Sprint / Ausweichen | K oder Umschalt | RT |
| Parieren | I oder **Rechtsklick** | LB |
| Seelenzauber (33 Seele) | O oder Mittelklick | RB |
| Ultimate (Leiste voll) | U oder R | Y |
| Heilen (halten, 33 Seele) | L oder F | B |
| Auf einer Bank rasten | W / Pfeil oben | oben |
| Karte | M | R3 |
| **Pause und Menü** | **Esc oder P** | **Menü (Start)** |
| **Inventar / Ausrüstung** | **Tab oder B** | **Ansicht (Back)** |

### Menü „Steuerung"
Esc → **Steuerung**: Klicke (oder bestätige mit dem Controller) auf ein Feld und drücke die neue Taste.
Jede Aktion hat 2 Tasten und 1 Controllertaste; ist die Taste schon belegt, werden die beiden Aktionen
getauscht. Entf löscht eine Taste, Esc bricht ab. Die Felder nehmen auch Maustasten an (links, rechts,
Mitte, Seitentasten). Menüs und Inventar lassen sich mit der Maus bedienen; im Spiel verschwindet der
Mauszeiger nach 2 Sekunden ohne Bewegung.
Die Einstellungen werden automatisch gespeichert (`user://controls.cfg`). Der linke Stick bewegt den Helden immer.

### Tastensymbole
Bildschirmhinweise, Schilder, Meldungen und das Steuerungsmenü zeigen **Symbole**: gezeichnete Tasten
und Maustasten für die Tastatur, farbige A/B/X/Y und LB/RT … für einen Xbox-Controller, und Kreuz /
Kreis / Quadrat / Dreieck, L1/R2 … für einen PlayStation-Controller (allgemeine Symbole).

### Controller (XInput)
Unter Windows liest Godot Xbox-Controller über XInput: einfach anschließen. Das Spiel zeigt den erkannten
Controller an, verwendet die Xbox-Tastennamen, akzeptiert die Trigger in Menüs und vibriert bei Treffern,
Schaden und Bossen. Die Vibration lässt sich im Steuerungsmenü abschalten. Die Bildschirmhinweise folgen
dem zuletzt benutzten Gerät (Tastatur oder Controller).

## Spielstände und Schwierigkeit

**3 Speicherplätze**: Titelbildschirm → „Spielstände". Jeder Platz hat seinen eigenen Spielstand und seine
eigene Schwierigkeit (zum Beispiel ein Normal- und ein Albtraum-Spiel). „Fortsetzen" lädt den zuletzt
gespielten Platz. Erfolge, Kosmetik und Optionen gelten für alle Plätze. Gespeichert wird automatisch.

Zum Start: **Spielen** → Schwierigkeit wählen (und die Option „Tutorial überspringen").
Auch während eines Spiels: Pause → „Neues Spiel …".

Das **Tutorial** hat zwei Etagen. Oben: Bewegung, Kampf, Parade, Sprint, Seele, Ultimate und Bänke.
Unten, nach dem Abstieg an einer Winde: eine einstürzende Brücke, ein rissiger Fels zum Zerschlagen, ein
Emblem zum Ausrüsten auf einer Bank, Splitter und die Karte. Splitter aus dem Tutorial bleiben erhalten.

**Nur ein Leben** (Kästchen beim Erstellen des Spiels, in jeder Schwierigkeit): Der erste Tod löscht den
Speicherplatz (außerhalb des Tutorials). Ein kleiner Schädel neben den Splittern erinnert daran. Erfolge und
Kosmetik bleiben erhalten, da sie für alle Spielstände gelten.

| Schwierigkeit | Seele / Ultimate | Gegner | Erlittener Schaden |
|---|---|---|---|
| Leicht | +35 % / +30 % | langsamer, -25 % Leben, weniger zahlreich, keine Eliten | 1 |
| Normal | normal | normal; Eliten: 8 % am Anfang, bis 35 % in der Tiefe | 1 |
| Schwer | -25 % / -20 % | +25 % Tempo, aggressiver, +35 % Leben, +35 % Gegner; Eliten: 25 % bis 65 % | 1 |
| Albtraum | -40 % / -35 % | +40 % Tempo, sehr aggressiv, +60 % Leben, +60 % Gegner; Eliten: 42 % bis 85 % | **2** |

Auch die Bosse werden je nach Schwierigkeit schneller und zäher, doch ihre Ausholbewegungen dauern nie
weniger als 0,25 s: Selbst auf Albtraum lässt sich jeder Angriff lesen und ausweichen. Ein Boss hat nie mehr
als 3 beschworene Diener gleichzeitig am Leben und beschwört nicht, solange sein Schwarm vollständig ist.

**Splitter**: Jeder Gegner gibt pro Ebene 10 % mehr (Ebene 6: +50 %), eine Elite das Doppelte, und der Boss
60 + 20 × Ebene. In Leicht, mit weniger Gegnern und ohne Eliten, geben Gegner 40 % mehr und der Boss 10 %
mehr: Man kommt etwa so schnell voran wie in Normal. Schwer und Albtraum bringen mehr, durch ihre
zusätzlichen Gegner und Eliten.

## Das Heiligtum und die endlosen Ebenen

Nach dem Tutorial kommst du im **Heiligtum der Laterne** an, dem Herz des Spiels:
- **Bank**: ausruhen, Leben auffüllen, Embleme wechseln. In der Tiefe heilt jede Bank nur einmal pro Zone
  (du kannst dich erneut setzen, um deinen Rückkehrpunkt festzulegen und Embleme zu wechseln), und nicht direkt
  nach einem Kampf (1,5 s).
- **Händler**: tauscht Splitter gegen **Lebensmasken** (+1 maximales Leben, bis zu 4), Emblem-**Kerben** und die
  **Embleme**, die du noch nicht gefunden hast. Sein alter Karren und seine Zugassel warten neben ihm.
- **Skriptorium** (auf seiner Plattform über dem Händler): **Meister Feder**, die Archiv-Eule, führt die
  Register deines Spielstands in einem großen Buch: Statistiken, Rekorde, ein **Bestiarium**, die besiegten
  **Wächter** (mit Beschreibungen und Tipps) und deine **Emblemsammlung**.
- **Arsenal**: deine Grundwaffe kaufen und ausrüsten. **Ausprobieren** leiht eine Waffe, solange du im
  Heiligtum bleibst.
- **Trainingspuppe** (rechts vom Arsenal): zeigt deinen Schaden pro Sekunde.
- **Schneiderin**: die Garderobe und die Kosmetik.
- **Aufzug**: die **Ebene** wählen, in die du hinabsteigst, und die Sondermodi (siehe unten). Eine Leiste
  zeigt den Weg bis **Ebene 7**, wo die Laterne erloschen ist: besiegte Ebenen in Gold, die offene umkreist,
  die nächsten mit Schloss. Nach Ebene 7 zeigt sie den aktuellen Zyklus (8-14, 15-21 …) mit seinem Endboss.
- **Bewohner**, die mit jeder geschafften Ebene kommen:
  - die **Schmiedin** (Ebene 1): schmiedet jede Waffe bis **Stufe 5**;
  - der **Juwelier**, ein mumifizierter Pharao auf seiner Plattform (Ebene 2): verstärkt **alle deine Embleme**
    bis **Stufe 3**;
  - der **Kartograf** (Ebene 2): verkauft eine Feder, die die ganze Karte aufdeckt;
  - der **Älteste** (Ebene 3): die Geschichte der Laterne.

Eine **Ebene = 2 erzeugte Zonen** (zwei Biome aus den 12) **und dann ein Boss**. Wer sie schafft, kehrt ins
Heiligtum zurück und **schaltet die nächste Ebene frei**, endlos. Dein Leben bleibt am Portal zwischen den
beiden Zonen erhalten (Leicht und Normal geben 1 Maske zurück, Schwer und Albtraum nichts).

**Tiefe**: das Leben der Gegner steigt um 18 % pro Ebene und hört bei ×4,6 auf (Ebene 21). Tempo, Aggressivität,
Anzahl und Eliten steigen bis etwa Ebene 10 bis 15. Der erlittene Schaden wächst nie mit der Tiefe.

**Sterben** im Abstieg: zurück ins Heiligtum, und die seit dem Aufbruch gesammelte Beute (Splitter, Embleme,
Kerben) ist verloren, aber freigeschaltete Ebenen und Käufe bleiben. Dein **Schatten** bewahrt die verlorenen
Splitter dort, wo du gefallen bist: kehre zur selben Ebene zurück und schaffe sie, um sie zurückzuholen (ein
neuer Tod ersetzt ihn).

### Die Sondermodi des Aufzugs
- **Flüche** (Eile, Dunkelheit, Zerbrechlichkeit): jede Ebene verflucht spielen, für +50 bis 60 % Splitter.
- **Tagesabstieg**: dieselben Zonen für alle, die beste Zeit gewinnt. Online-Bestenliste pro Schwierigkeitsgrad
  (Top 10 und dein Rang); deine Zeit wird mit dem Namen deiner Wahl gesendet, das Senden lässt sich abschalten.
- **Wochenherausforderung**: eine pro Woche, auf Ebene 4, mit einem Fluch und einer vorgegebenen Waffe, die
  jede Woche wechseln, und eigener Bestenliste.
- **Geist**: im Tagesabstieg und in der Wochenherausforderung läuft der Geist des aktuellen Ersten die Zone
  neben dir ab (eine durchscheinende Kapuzengestalt mit Namen). Er lässt sich im Bestenlisten-Bildschirm
  ausblenden.
- **Boss-Ansturm** (nach Ebene 6): die Bosse nacheinander, mit Zeitmessung. +600 Splitter jedes Mal, +200 mehr
  bei neuer Bestzeit, eine Emblem-Kerbe beim ersten Sieg, und eine Online-Bestenliste.
- **Bestenlisten**: Tag, Woche und Boss-Ansturm, alle über den Aufzug.

Es gibt 29 **Erfolge**, einsehbar über den Titelbildschirm oder das Pausenmenü.

### Die 12 Biome

| Biom | Merkmale |
|---|---|
| Die Tiefen | bläuliche Höhlen, Hügel und Schächte, Kriecher und Flieger |
| Die Pilzgärten | Wände zum Erklimmen, Schächte, viele Spucker |
| Die Versunkene Zitadelle | Säulen über Stacheln, Arenen, Brücken |
| Die Kristallminen | große Abgründe (Sprint), niedrige Gänge, Flieger |
| Die Glühende Schmiede | überall Stacheln, Glut, viele Kriecher |
| Die Stille Bibliothek | Klettern und Plattformen, Fliegerschwärme |
| Der Eisige Abgrund | Schnee, brüchige Brücken und Abgründe, Spucker |
| Der Summende Stock | enge Gänge voller Flieger |
| Das Beinhaus | Hügel und Arenen, Kriecher und Spucker |
| Der Versunkene Dschungel | Plattformen, Inseln und Lianenbrücken, Schleime und Affen |
| Der Verschüttete Sand | Dünen, Gruben und brüchige Blöcke, Skorpione und Maulwürfe |
| Der Antike Tempel | Säulen, Arenen und Klingen, Kobolde und Lanzenträger |

### Tiefen: Grotten und Schichten

| | | |
|---|---|---|
| ![Grotte der Pilzgärten](docs/screenshots/grotto_gardens.jpg) | ![Grotte der Stillen Bibliothek](docs/screenshots/grotto_library.jpg) | ![Seilwinde am Fuß eines Schachts (Kristallminen)](docs/screenshots/strata_winch.jpg) |

Die Zonen sind keine flachen Streifen mehr:
- **Grotten** (alle Biome): Löcher im Weg führen in eine Grotte unter der Zone, gestaltet nach dem
  Biom (Riesenpilze, Bücherregale, Wabenzellen, überflutete Halle, Knochengruft, Kristallstalagmiten,
  brüchige Eisbrücke, Glutgruben …). Jede verbirgt eine **Truhe**, Gegner und manchmal einen
  **Händler** oder ein Emblem.
- **Schichten** (die Tiefen, die Kristallminen, der Eisige Abgrund, die Glühende Schmiede): Die Zone
  führt über drei Etagen hinab. Die erste geht nach rechts, die zweite zurück nach links, die dritte
  wieder nach rechts bis zum Ausgang. Ein breiter Schacht verbindet jede Etage mit der nächsten.
- **Seilwinde**: Am Fuß jeder Grotte und jedes Schachts hängt ein Seil an einer Winde. **Oben** daneben
  (oder mitten im Sprung am Seil, oder **Unten** am Schachtrand) packst du es, dann kletterst du mit **Oben** / **Unten**
  in deinem Tempo. **Sprung** springt vom Seil ab, **Unten + Sprung** lässt los.

### Besondere Räume
- **Schatz**: Ein rissiger Boden verbirgt eine Truhe; zerschlage ihn (Schläge nach unten oder Sturzangriff).
- **Zeitprüfung**: Berühre die Sanduhr-Spur und erreiche die Flagge in 13 Sekunden.
- **Elite-Arena**: Wecke den Altar, besiege drei Eliten und gewinne Splitter und ein Emblem.
- **Fahrender Händler**: manchmal nahe der Bank in der Zonenmitte (Käufe zählen als Beute).

### Fallen und Plattformen
Die Zonen haben ein Relief (der Boden steigt und fällt von Raum zu Raum) und abwechslungsreiche Räume: schwebende
Inseln, Zickzack-Schächte, Doppelwege, niedrige Höhlen, brüchige Brücken, Abgründe mit beweglicher Plattform,
Klingengänge.
- **Stachelgruben**: hineinzufallen kostet eine Maske und setzt dich auf den letzten sicheren Boden zurück.
- **Pfeiltotem**: schießt auf Kopfhöhe. Duck dich, spring oder pariere.
- **Pendelklinge**: ihr tiefster Punkt geht knapp über den geduckten Helden hinweg.
- **Stalaktit**: fällt, wenn du darunter hindurchgehst.
- **Brüchige Brücken**: stürzen kurz nach dem Betreten ein und bilden sich dann neu. Jedes Biom hat eigene
  (Bretter, Knochen, Bücher, Pilzhüte, Eis, Waben …).
- **Rissige Felsen**: versperren einen Durchgang; schlag zu, bis sie nachgeben. Ihr Material hängt vom Biom ab.
- **Bewegliche Plattform**: pendelt über einem Abgrund.
- **Einstürzende Plattform** (Kristallminen): gibt unter dir in einem Schuttregen nach.

**Biomfallen**, mit lesbarem Zyklus (sie warnen, bevor sie zuschlagen). Je nach Tiefe gibt es 1 bis 4 pro Zone,
nie übereinander und nie in der Nähe des Bosses:

| Falle | Biome |
|---|---|
| Ein- und ausfahrende Stacheln | alle |
| Giftgaspilz | Pilzgärten, Summender Stock, Versunkener Dschungel |
| Flammengeysir | Glühende Schmiede, Verschütteter Sand |
| Eisgeysir | Eisiger Abgrund |
| Kristallwelle, die über den Boden läuft | Kristallminen |
| Wirbel fliegender Seiten | Stille Bibliothek |
| Skeletthand, die dich packt (der Sprint befreit) | Beinhaus |
| Dampfrohr in den Farben des Bioms | Versunkene Zitadelle, Antiker Tempel |
| Fallender Tropfen | Die Tiefen |

Fallen verletzen auch Gegner, aber nur die, die du gerade getroffen oder weggestoßen hast.

## Kampf

- **Bodenkombo**: drei Schläge; der 3. ist ein breiterer, stärkerer **Abschlussschlag**.
- **Aufgeladener Schlag**: Angriff etwa 0,7 s halten (die Nadel leuchtet) und loslassen = ein **Wirbel**,
  der rundum trifft.
- **Ausfall**: greife **während (oder direkt nach) einem Sprint** an = ein durchbohrender Stoß in gerader Linie.
  Er **schleudert Gegner weit weg** (keine Bosse, nicht mit den Shuriken) und stößt 2 s später wieder.
- **Luftkombo** (anders als am Boden): Hieb, **Aufwärtshieb**, der dich wieder anhebt, und eine
  **Drehung**, die rundum trifft.
- **Sturzangriff**: in der Luft unten + Sprint. Du stürzt hinab, prallst vom getroffenen Gegner ab oder
  löst bei der Landung eine **Schockwelle** aus. Einer pro Sprung. Nach einem Sturzangriff landest du
  stehend: Erst nach dem Loslassen von unten duckst du dich wieder.
- **Ducken**: unten am Boden halten. Langsamer, aber hohe Angriffe gehen darüber hinweg (Ausfall des
  Lanzenträgers, Schwung des Kolosses, Pfeile, Pendelklingen). Geduckt angreifen = tiefer Schlag.
- **Seelenzauber**: eine nach vorn geschleuderte Seelenklinge, die Gegner **durchdringt** (kostet 33 Seele,
  genauso viel wie eine Heilung: Du entscheidest).
- **Parieren**: ein kurzes Fenster (0,2 s). Ein parierter Kontakt betäubt den Gegner; ein parierter Boss ist
  eine Sekunde betäubt. Eine parierte Spore fliegt zurück zu den Gegnern. Gibt Seele und viel Ultimate-Ladung.
- **Perfekte Parade**: Pariere im letzten Moment und es erscheint „PERFEKT!"; ein **goldenes Licht** leuchtet
  an der Waffenspitze, und der nächste Treffer ist **kritisch: Schaden ×1,5** (aufgerundet, immer mindestens +1).
- **Ausweichen**: Während des Sprints gehst du durch Gegner und Geschosse hindurch (nicht durch Stacheln).
- **Ultimate**: Die goldene Leiste füllt sich durch Treffer (+6) und Paraden (+25). Ist sie voll, bleibt der
  Held stehen, lädt eine halbe Sekunde auf (unverwundbar) und entfesselt eine Schockwelle: 8 Schaden an
  allem in der Nähe, Sporen werden zerstört.
- Ein Nadeltreffer zerstört auch gegnerische Sporen.
- **Rückstoß**: Jeder Treffer schiebt den Helden ein wenig zurück (etwa 9 px bei den ersten beiden
  Kombo-Schlägen, 24 px beim Abschlussschlag, nichts geduckt): Die ganze Kombo trifft ein stillstehendes Ziel.
- **Angriffswarnungen**: ein gelbes „!" über einem Gegner, der einen Schlag vorbereitet; orange mit Pfeil
  bei einem hohen Angriff (ducken).

### Das Arsenal

| Waffe | Preis | Stil | Stufe 2 (Schmiedin) |
|---|---|---|---|
| Nadel des Wächters | — | ausgewogen | der Abschlussschlag schleudert eine kurze Luftklinge |
| Zwillingsklauen | 180 | eine Klaue an jeder Hand: Jeder Angriff trifft zweimal (0,6 Schaden pro Klaue, 1 pro Klaue bei einem starken Schlag), sehr schnell, kurze Reichweite, halb so viel Seele pro Klaue | Blutung: Jeder Klauenhieb hat 20 % Chance (50 % mit dem Blutzahn), dass der Gegner eine Sekunde später noch 1 Leben verliert |
| Dornenpeitsche | 150 | sehr große Reichweite nach vorn und oben, etwas langsamer | zieht kleine Gegner heran |
| Ambosshammer | 220 | langsam, +1 Schaden, starker Rückstoß, betäubt | der Abschlussschlag sendet zu beiden Seiten eine Schockwelle (steigt Stufen hinauf) |
| Mondsterne (Shuriken) | 260 | Fernkampf; Abschluss = 3 Sterne, Wirbel = 8 im Kreis, Ausfall = ein großer durchbohrender Stern | kehren wie ein Bumerang zurück und treffen erneut |
| Sense des Ährenlesers | 240 | großer Halbmondbogen vorn und oben, mäht mehrere Gegner; der Abschluss ist ein Wirbel | jeder gemähte Gegner gibt Seele, der Wirbel schleudert eine zurückkehrende Geisterklinge |
| Kupferberingter Stab | 230 | langer, schneller Stoß; in der Hocke Stabhochsprung | der Abschluss saust als Riesenschlag herab und schickt eine Bodenwelle |

Die Schmiedin bringt danach jede Waffe bis **Stufe 5**: Stufe 2 gibt den Spezialeffekt oben (Ebene 1 geschafft), Stufen 3, 4 und 5 (Ebenen 2, 3 und 5) stärken, was die Waffe am besten kann: +1 Schaden, +12 % Reichweite, +10 % Angriffstempo oder +8 % Chance auf kritische Treffer.

Mondsterne: höchstens 3 einfache Sterne gleichzeitig auf dem Bildschirm, weniger Seele pro Treffer, und
Bosse erleiden nur 75 % des Fernkampfschadens.

### Embleme
Tab öffnet das Inventar (das Spiel pausiert): Gegenstände, Splitter, Statistiken und das Raster der
**Embleme**, die in den Zonen zu finden sind. Jedes Emblem kostet Kerben; du beginnst mit 3 und kannst
weitere finden (goldene Ringe) oder kaufen. Die Ausrüstung lässt sich nur **auf einer Bank sitzend** ändern.

| Emblem | Kosten | Wirkung |
|---|---|---|
| Lange Nadel | 2 | Reichweite der Schläge +40 % |
| Kristallherz | 2 | +2 Lebensmasken |
| Flinker Umhang | 1 | Laufen +12 %, Sprint lädt doppelt so schnell nach |
| Dornenpanzer | 2 | Dornen verletzen nahe Gegner, wenn du getroffen wirst |
| Perfekter Spiegel | 1 | Paradefenster 0,35 s |
| Gierige Seele | 2 | mehr Seele und Ultimate bei jedem Treffer |
| Lebendige Sammlung | 1 | Heilung fast doppelt so schnell |
| Rohe Kraft | 3 | +1 Schaden, aber Schläge 20 % langsamer |
| Glühender Meteor | 2 | ein treffender Sturzangriff bereitet einen kritischen Treffer vor |
| Ruhe des Schattens | 2 | geduckt außerhalb des Kampfes steigt die Seele langsam bis 33; geduckt heilen 1,5× schneller |
| Perfektes Echo | 2 | eine perfekte Parade schleudert gratis eine Seelenklinge |
| Leichter Schritt | 1 | eine Falle ungetroffen passieren gibt 5 Splitter |
| Prallklinge | 1 | Abprallen von einem Gegner katapultiert dich 25 % höher und gibt 6 Seele |
| Fallender Amboss | 2 | Sturzangriff +1 Schaden, Schockwelle 50 % breiter |
| Schneidende Parade | 2 | eine gelungene Parade fügt dem Angreifer 2 Schaden zu |
| Geistersprint | 2 | der Sprint verletzt durchquerte Gegner (1 Schaden) |
| Seelenernte | 1 | jeder besiegte Gegner gibt 8 Seele |
| Spürnase des Plünderers | 1 | Grottentruhen und Verstecke: +60 % Splitter |
| Kletterknoten | 1 | doppelt so schnell am Seil klettern; das erste Greifen jedes Seils gibt 33 Seele |
| Letzter Atemzug | 3 | ein tödlicher Treffer lässt dich mit 1 Maske überleben, einmal pro Zone |
| Blutzahn | 2 | +30 % Chance auf Blutung bei jedem Treffer, mit jeder Waffe (1 Schaden eine Sekunde später); 50 % mit den Zwillingsklauen St. 2 |
| Glühende Seele | 2 | die Seelenklinge (Zauber) verursacht 1 Schaden mehr |
| Genügsame Laterne | 1 | heilen kostet nur 27 Seele statt 33 |
| Mottenflügel | 3 | erlaubt einen zweiten Sprung in der Luft, etwas niedriger als der erste |
| Zwillingsschatten | 2 | zwei Sprints in der Luft statt einem vor der Landung |
| Steinhaut | 2 | nach einem Treffer hält die Unverwundbarkeit 40 % länger |
| Händlerbeutel | 1 | besiegte Gegner lassen 20 % mehr Splitter fallen |
| Saftkelch | 3 | alle 15 besiegten Gegner wird eine Maske wiederhergestellt |
| Sturmherz | 2 | die Ultimative lädt 25 % schneller (Treffer und Paraden) |
| Donnerwelle | 2 | die Welle der Ultimativen ist 30 % breiter |
| Rindensohlen | 1 | der erste Fallentreffer jeder Ebene wird ignoriert |
| Pendel | 1 | eine gelungene Parade lädt den Sprint sofort auf und gibt 5 Seele mehr |
| Jägerzahn | 2 | +1 Schaden gegen Gegner unter 40 % ihrer Lebenspunkte |
| Beißender Frost | 2 | 15 % Chance pro Treffer, den Gegner kurz einzufrieren (0,6 s, keine Bosse) |
| Falkenauge | 2 | +8 % Chance auf kritische Treffer |
| Obsidianspitze | 2 | kritische Treffer verursachen ×2 statt ×1,5 |
| Seelenschleier | 3 | mit 33 Seele wird ein Treffer von der Seele statt von den Masken absorbiert (einmal alle 8 s) |
| Zorn des Verwundeten | 2 | bei 1 Maske +1 Schaden bei allen Treffern |
| Komet | 1 | der aufgeladene Angriff (Wirbel) lädt 40 % schneller |
| Gesegneter Saft | 2 | jede Heilung hat 25 % Chance, eine zusätzliche Maske wiederherzustellen |
| Klingentanz | 2 | der Abschlussschlag der Kombo verursacht +1 Schaden und gibt 4 Seele |
| Bankgebet | 1 | auf einer Bank sitzen füllt die Seele bis 33 |

Der **Juwelier**, ein mumifizierter Pharao, der sich nach Ebene 2 im Heiligtum niederlässt, verstärkt **alle Embleme, die du besitzt**, ob getragen oder nicht: Stufe 2 (Ebene 2 geschafft), dann Stufe 3 (Ebene 4). Jedes Emblem wird stärker (zum Beispiel Glasherz: +2, +3, dann +4 Masken). Inventar und Skriptorium zeigen die 42 Embleme in einer scrollbaren Liste.

Die Wirkungen sind in `scripts/charms.gd` definiert und werden in `scripts/player.gd` angewendet.

## Gegner
- **Kriecher**, **Flieger**, **Spucker**: die Grundlagen. Der Kriecher entdeckt dich und stürmt los, der Flieger umfliegt Mauern, um dich zu erreichen, der Spucker schießt Sporen.
- **Springer**: eine Heuschrecke, die auf dich springt.
- **Schildwache**: blockt Schläge von vorn. Triff sie von oben, von hinten oder mit dem Ultimate.
- **Sprengknolle**: rollt auf dich zu, leuchtet auf und explodiert (verletzt auch nahe Gegner).
- **Weberin**: eine an der Decke hängende Spinne, die klebrige Netze spuckt (Sprinten reißt sie los), auf ihre Beute stürzt und an ihrem Faden zurückklettert.
- **Lanzenträger**: geht in Stellung und führt einen langen Ausfall aus; eine Parade betäubt ihn.
- **Geist**: verblasst (unberührbar), taucht neben dir wieder auf und schleudert eine langsame Kugel.
- **Diebischer Affe**: springt überall herum, wirft Früchte und stiehlt dir Splitter; töte ihn, bevor er flieht, um alles zurückzubekommen.
- **Mimik**: ein falsches Schatzversteck, das beißt und auf dich zuhüpft.
- **Löschmotte**: kommt in Gruppen und verdunkelt alles, während sie deine Laterne umkreist.
- **Wühlmaulwurf**: gräbt sich zu dir und bricht nach einer Warnung (rissiger Boden, „!“) unter deinen Füßen hervor.
- **Schleim**: bewegt sich in Sprüngen; getötet, teilt er sich in zwei kleine Schleime.
- **Skorpion**: spannt den Stachel und sticht; das Gift kostet kurz darauf eine weitere Maske (nie tödlich).
- **Kobold**: wirft Dolche aus der Ferne, schlägt aus der Nähe zweimal zu und flieht, wenn er schwächelt.
- **Eliten** (rotes Leuchten): mehr Leben, schneller, doppelte Beute und ein Zusatzangriff — der Kriecher
  stürmt, der Flieger stürzt herab, der Spucker spuckt 3 Sporen, der Springer springt zweimal hintereinander,
  die Wache stürmt mit ihrem Schild.
- **Champions** (goldener Umriss): Ab Ebene 2 verbirgt etwa jeder zweite oder dritte Abschnitt ohne Boss
  den Champion seines Bioms, doppelt so groß, mit eigener Lebensleiste und vielen Splittern als Belohnung.
  Einmal besiegt, kehrt er nicht zurück. Der Große Anglerfisch (Tiefen), der Mutterbovist (Gärten), der
  Ertrunkene Kapitän (Zitadelle), die Uralte Schildkröte (Minen), der Schmiedekobold (Schmiede), das Verbotene
  Grimoire (Bibliothek), der Gletschergolem (Abgrund), die Wächterdrohne (Bienenstock), der Skelettkönig
  (Beinhaus), der Affenkönig (Dschungel), der Kaiserskorpion (Sande) und der Koboldhäuptling (Tempel).

Kein Gegner kann durch eine Wand treffen. Zähe Gegner und Eliten werden häufiger, je tiefer du kommst.

## Bosse

Der Wächter ist immer der erste; die fünf anderen kommen in einer **für jedes Spiel eigenen Reihenfolge**,
dann beginnt der Zyklus von vorn, schwerer. Jeder hat seine Gestalt, seine Angriffe, eine **Phase 2** bei
halbem Leben und sein eigenes Thema. Einen Kontakt zu parieren betäubt den Boss für eine Sekunde.

| Boss | Stil | Angriffe |
|---|---|---|
| Wächter des Schachts | gepanzerter Käfer | angekündigter Ansturm, Stampfsprung; Phase 2: Schockwellen am Boden |
| Die Versunkene Äbtissin | Sporenkönigin | Ansturm, Sprung, Fächersalve, Sporenring (dichter in Phase 2) |
| Die Schwarmkönigin | **fliegende** Riesenwespe | Sturzflüge (verkettet in Phase 2), gezielte Stachelsalve, Spiralringe, ruft Flieger |
| Der Knochenkoloss | Knochenriese | Bodenschlag (Wellen + Steinschlag), Armschwung; Phase 2: Sprung + Reihe von Knochensäulen |
| Der Wurm der Tiefe | **grabender** Wurm | taucht ab, eine Staubspur verrät ihn, bricht unter dir hervor und spuckt Säure; Ansturm; Phase 2: drei Stürme aus dem Boden + Wellen |
| Der Geisterritter | Geisterduellant | Blitzausfälle (Dreierkombos in Phase 2), **teleportiert sich hinter dich**, Geistersäulen in Reihe, Glutsalve |

### Endbosse
Auf Ebene 7 (dann alle 7 Ebenen) wartet ein **Endboss**, jeder mit eigenem Thema. Die Auslosung bevorzugt einen
Endboss, den du **noch nie besiegt** hast: du triffst alle vier in vier Endkämpfen (spätestens Ebene 28).
Tagesabstieg, Wochenherausforderung und Boss-Ansturm behalten für alle dieselbe Auslosung.
- **Der Schatten der Laterne**: Glutkronen, Schwung auf Kopfhöhe, Ascheregen, Lichtsäulen, Gespenster in
  Phase 2.
- **Der Zerberus der Tiefe**: Glutatem aus drei Köpfen, Sprung mit Schockwelle, dreifacher Biss auf Kopfhöhe
  (ducken), ein Heulen, das Flammen hervorbrechen lässt.
- **Der Kentaur-Bogenschütze**: galoppiert durch die Arena, Pfeilsalven, am Boden markierter Pfeilregen,
  Lanzenstoß auf Kopfhöhe (ducken), springt über den Spieler.
- **Das Auge von unten**: Tentakel brechen aus dem Boden, ein Strahl fegt auf Kopfhöhe (ducken) oder am Boden
  (springen) durch die Arena, Sporenspiralen, fliegende Augen.

Ein Sieg startet **das Ende**: die Laterne wird wieder entzündet, das Licht steigt Ebene um Ebene bis zum
Heiligtum und dann an die Oberfläche, und der Abspann läuft. Danach gehen die Ebenen weiter.
Erfolg „Die vier Wächter": besiege alle vier.

## Lokales Duell: die Schattenarena

Zwei Spieler kämpfen am selben Bildschirm gegeneinander. Um aus der Ferne zu spielen, nutze **Parsec**: es
überträgt den Bildschirm und reicht den Controller des zweiten Spielers an das Spiel weiter.
1. Schalte **Optionen → Schattenarena im Heiligtum** ein (standardmäßig aus): das Banner der Arena erscheint im
   Heiligtum.
2. Schließe einen zweiten Controller an. Spieler 1 spielt mit der Tastatur (oder dem ersten Controller),
   Spieler 2 mit dem zweiten.
3. Am Banner wählt jeder Spieler seine Waffe, dann **Kämpfen!**

Regeln: gleiche Bedingungen. Keine Embleme, alle Waffen auf Stufe 2, je 9 Masken, wer zuerst **3 Runden**
gewinnt, gewinnt. Die Parade wirkt gegen den anderen Spieler und stößt ihn zurück; ein Geschoss trifft nie
seinen Werfer. Die Arena hat einen Boden und drei Plattformen in Sprungweite; beide Spieler starten einander
zugewandt.

## Grafik

Alles wird per Code gezeichnet, in einem detaillierten, gemalten Stil:

- **Fels**, texturiert von einem eigenen Shader pro Biom (Schichten, Quader, Kristall, Lavaadern, Eis,
  Waben, Knochen), dunkler in der Tiefe, mit beleuchteten Kanten;
- **verzierte Böden** je nach Biom (Gras, leuchtende Pilze, Kristalle, Schädel, Bücher, Kerzen, Schnee,
  Honig) und **Parallax-Hintergründe** in drei Ebenen mit Nebel und Lichtstrahlen;
- eine **dritte Ebene** zwischen Hintergrund und Held, in jedem Biom anders: Pilzteich, Sumpf, heiliger
  Brunnen, Eingang einer Kristallmine, Vulkan mit Lavaströmen, Honigfluss, Armillarsphäre, gefrorener
  Wasserfall, Knochenrutsche, Dschungelfluss, Treibsand, römischer Brunnen;
- **Held, Gegner, 10 Bosse und Bewohner des Heiligtums** mit Schattierung, Glanzlichtern und Details;
- **Fallen, Gitter, Angriffssäulen, Ausgangsportal** (ein Design pro Biom) und **das Ende**;
- **Embleme**: jedes hat sein graviertes Medaillon und sein Symbol; **Waffenschläge** hinterlassen gemalte Spuren;
- **Oberfläche**: gläserne Seelenflasche mit Messingring, gemalte Masken, Ultimate-Leiste aus Messing,
  facettierter Splitterkristall und Pergament-Minikarte;
- **Menüs und Titelbildschirm**: gemalter Hintergrund (Schacht, Laterne, Glut), Tafeln aus dunklem Holz und Messing;
- **Kampfeffekte**: Trefferstern, Todesring mit Rauch und Trümmern, Splitter, die zum Helden fliegen,
  Landestaub, Sprint-Nachbild, Geschosse mit Schweif;
- **Atmosphäre pro Biom**: Sporen und Glühwürmchen, Schnee, fliegende Seiten, Glut, Irrlichter, tropfende
  Decken, brodelnde Lava, leuchtende Kristallgruppen;
- **Karte**, gezeichnet wie eine verlorene Karte: zerrissenes, gefaltetes, fleckiges und angesengtes Pergament.

## Karte, Optionen und Barrierefreiheit
- **Karte** (M / R3): alles Entdeckte der Zone, mit einem Piktogramm und einer Legende für jeden gefundenen
  Ort (Bank, Ausgang, Händler, Bewohner, Truhen, Embleme, Altar, Prüfung, Schatten …).
  **Minikarte** oben rechts (Optionen).
- **Sprache**: Automatisch (Systemsprache), Français, English, Español, Deutsch.
  Die Übersetzungen liegen in `tools/translations.py`; `python3 tools/translations.py` erzeugt
  `scripts/translations.gd` neu.
- **Größe der Oberfläche** (60–160 %) und **der Menüs** (60–130 %), **Kamerazoom**,
  **Vollbild** (auch F11), **vertikale Synchronisation**.
- **Grafikqualität**: Hoch, Ausgewogen (keine Lichtstrahlen und Nebelbänke im Hintergrund, halb so viele
  Partikel) oder Niedrig (nur der ferne Hintergrund, keine 2D-Lichter außer denen des Helden, keine Partikel
  und keine Vignette). Ausgewogen ist auf dem Mac und im Browser voreingestellt. Die Änderung wirkt sofort.
- **Lebensleisten der Gegner** und **verursachter Schaden**, kurz oben rechts angezeigt.
- **Bildschirmhinweise**, **Bildschirmwackeln** (0–150 %), **Trefferstopp**, **Controller-Vibration**.
- **Barrierefreiheit**: kontrastreiche Gefahren (Farbenblindheit), Ducken als Umschalter,
  Spieltempo 100 / 90 / 80 / 70 %.
- **Abstiegsstatistik** (Gegner, Schaden, kritische Treffer, perfekte Paraden, erlittene Treffer, Zeit),
  angezeigt bei der Rückkehr ins Heiligtum.

Alles wird in `user://settings.cfg` gespeichert.

## Kosmetik und Garderobe
Die **Schneiderin** im Heiligtum (links von der Bank) öffnet die Garderobe, in der du das Aussehen des
Helden mit animierter Vorschau änderst: **59 Kosmetikartikel** in 6 Kategorien, davon 21 saisonale.
Alles ist rein optisch und gilt für alle Speicherplätze. Helle Umhänge sind abgedunkelt, damit sie auf
dunklen Hintergründen nicht blenden.

| Kategorie | Beispiele |
|---|---|
| Umhang | Schatten, Glut, Moos, Frost, Amethyst, Elfenbein, Goldener Wächter, Sternennacht |
| Schal | Türkis, Scharlach, Gold, Weiß, Violett, Lebendige Glut |
| Kopfschmuck | Rabenfeder, Kerze, Blumenkranz, Goldkrone, Heiligenschein, Knochenhörner |
| Spur und Glanz | Farbe von Sprint, Auge und Schlägen: Glut, Frost, Geist, Reines Gold … |
| Begleiter | Glühwürmchen, Motte, Irrlicht, kleine Laterne, Wespe der Königin (folgt dem Helden, rein dekorativ) |
| Ultimate | Aussehen der Schockwelle: Goldwelle, Frostnova, Freudenfeuer, Finsternis, Geisterschwarm |

Drei Wege, sie zu bekommen:
- bei der Schneiderin mit Splittern **kaufen** (die häufigsten);
- einen **Erfolg** erringen: Die Belohnung steht in der Erfolgsliste;
- einen **Boss besiegen**: Koloss, Königin, Ritter, Zerberus und Auge haben je einen seltenen Kosmetikartikel
  (25 % Chance pro Sieg).

Es gibt **29 Erfolge**, von denen mehrere Kosmetik geben, darunter „Kalender des Wächters": das Geschenk
aller vier Feste öffnen.

### Feste
Vier Feste kehren jedes Jahr automatisch nach dem Datum wieder. Während jedes Festes wird das Heiligtum
geschmückt, einmal im Jahr lässt sich ein **Geschenk** öffnen (der Kopfschmuck des Festes und 50 Splitter),
und die Schneiderin verkauft die Festkollektion. Was du gewinnst oder kaufst, bleibt das ganze Jahr.

| Fest | Daten | Geschenk | Im Verkauf |
|---|---|---|---|
| Valentinstag | 8. – 16. Februar | Herzdiadem | Rosenumhang, Spur Pochendes Herz, Herzchen, Ultimate Liebespfeil |
| Ostern | eine Woche vor bis eine Woche nach | Hasenohren | Frühlingsumhang, Küken, Ultimate Schlüpfen |
| Schattenwacht | 20. Oktober – 2. November | geschnitzter Kürbis | Wachtumhang, Kürbisfeuer, Fledermaus, Ultimate Fledermauswolke |
| Weihnachten | 1. Dezember – 6. Januar | Weihnachtsmütze | Weihnachtsumhang, Lichterkette, Rentiergeweih, Schneeflocken, lebende Flocke, Ultimate Weihnachtsstern |

Jedes Fest hat seine eigene **Musik** im Heiligtum und auf dem Titelbildschirm, für das Spiel komponiert
von `tools/synth_fetes.py` (dieselben Instrumente wie der Rest des Soundtracks, keine existierende Melodie).

Ein Fest außerhalb der Saison testen: das Spiel mit der Umgebungsvariable
`LANTERNE_EVENT=noel` starten (oder `halloween`, `valentin`, `paques`).

## Ladebildschirme
Alle per Code gezeichnet, im Stil des Spiels; jede Taste beschleunigt sie.
- **Start**: In der Dunkelheit entzündet sich eine Laterne, Glut steigt auf, Titel und ein Tipp erscheinen,
  und eine Reihe aufglühender Glutstücke dient als Fortschrittsanzeige, begleitet vom Knistern der Glut
  (vom Spiel synthetisiert).
- **Betreten eines Ladens**: Zwei messingbeschlagene Holzflügel schließen sich über dem Schild des Bewohners
  (Beutel, Amboss, Karte und Feder, Schriftrolle, Garnrolle, gekreuzte Klingen) und öffnen sich zur Theke.
- **Aufzug**: Der Käfig mit dem Helden in seinem Outfit fährt durch einen Steinschacht hinab, während die
  Ketten rasseln; die Nummer der Ebene ist in eine Messingplatte unter dem Käfig graviert. Die Zone wird
  während der Fahrt gebaut, und der Käfig hält mit einem dumpfen Schlag. Nach einer geschafften Ebene fährt
  er zurück ins Heiligtum. Die Ketten sind eine lizenzfreie Aufnahme (`sfx/lift_chains.ogg`).

## Automatische Updates
Beim Start fragt das Spiel (Windows, macOS, Linux, Steam Deck) bei GitHub das neueste Release ab.
Ist es neuer:
- wird ein kleiner **Patch** (Skripte und Shader, einige Hundert KB) heruntergeladen und beim nächsten Start
  angewendet — der Titelbildschirm bietet **„Update bereit — neu starten"** an;
- reicht der Patch nicht (neue Musik, neue Godot-Version), zeigt der Titelbildschirm
  **„Version verfügbar — herunterladen"** und öffnet die Release-Seite.

Die Versionsnummer steht unten auf dem Titelbildschirm. **Optionen → Automatische Updates** schaltet das
Herunterladen ab (der Hinweis erscheint weiterhin). Ohne Netz passiert nichts. Startet das Spiel mit einem
Patch nicht richtig, wird dieser beim nächsten Start entfernt. Die Browserversion ist immer aktuell.
Details: `scripts/updater.gd`; der Patch wird vom Release-Workflow erzeugt (Exportprofil „Patch").
Erhöhe `config/data_gen` in `project.godot`, wenn du Musik, Sounds oder Bilder hinzufügst: Ältere
Installationen sehen dann den Download-Hinweis.

## Musik und Sounds
Ein **eigener**, für das Spiel erzeugter Soundtrack (ohne fremdes Material): 32 Loops in `music/` — ein oder zwei
pro Biom, die überblendet ineinander übergehen, ein Thema pro Boss (jedes mit eigenem Motiv, Rhythmus und Instrumenten), eines für das Tutorial, eines für das
Heiligtum und eines pro Fest. Die Soundeffekte liegen in `sfx/`, mit eigenen Klängen für jede Waffe,
für kritische Treffer und für die perfekte Parade. Lautstärken **Gesamt / Musik / Effekte** in den
Optionen; die Musik wird leiser, wenn das Spiel pausiert.

## Tests
`tests/test_run.gd` durchläuft die Zonen automatisch (simulierte Eingaben, Bosse, Menüs):
`godot --headless --fixed-fps 120 -s res://tests/test_run.gd`.
`tests/dump_maps.gd` erzeugt Hunderte Zonen, um zu prüfen, dass alle schaffbar sind.

**Ranglisten-Server**: `server/` (Cloudflare Worker + D1), bereitgestellt durch den Workflow
„Classement (Cloudflare)" mit den Secrets `CLOUDFLARE_API_TOKEN` und `CLOUDFLARE_ACCOUNT_ID`.
`node server/test_worker.mjs` testet ihn; `node server/dev_server.mjs` startet ihn lokal (Spiel mit
`LANTERNE_LEADERBOARD_URL=http://127.0.0.1:8787` starten).

## Lizenz
Copyright (c) 2026 FlyinnRabbit. **Alle Rechte vorbehalten.** Laterne der Tiefen ist ein kommerzielles Spiel:
Code, Grafik, Musik, Sounds, Texte und Name gehören dem Autor.
- **Quellcode**: zum Lesen veröffentlicht. Ihn zu kopieren, zu ändern, zu kompilieren, weiterzuverbreiten oder
  Teile davon (Code, Grafik, Musik, Sounds) in einem anderen Projekt zu verwenden, ist ohne schriftliche
  Genehmigung nicht erlaubt.
- **Kostenlose Versionen** (Browser und GitHub-Downloads): Du darfst sie für den persönlichen, nicht kommerziellen
  Gebrauch installieren und spielen, aber nicht weiterverbreiten, anderswo hosten oder verkaufen.
- **Steam-Version**: Es gelten der Steam-Nutzungsvertrag und die Bedingungen auf der Shopseite des Spiels.
- **Videos, Streams und Screenshots**, monetarisiert oder nicht: erlaubt, solange sie sich nicht als offiziell ausgeben.

Vollständiger Text: `LICENSE` (auf Englisch). Die Godot-Engine steht unter der MIT-Lizenz; `sfx/lift_chains.ogg`
stammt aus der Aufnahme *Chains Chiming* von freesound_community auf Pixabay (Pixabay-Inhaltslizenz).
Das Spiel ist von Hollow Knight (Team Cherry) inspiriert, übernimmt aber keine seiner Figuren oder Inhalte.
