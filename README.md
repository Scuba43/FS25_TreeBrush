# FS25_TreeBrush (Baum-Brush)

Script-Mod für **Farming Simulator 25**: Entfernt im **Bau-Modus** (und zu Fuß) mit einer
Brush-Funktion eine große Anzahl an Bäumen und Stümpfen auf einmal – per Raycast unter den
Mauszeiger, mit einstellbarem Radius und sichtbarem Brush-Kreis.

## Installation

1. Den Ordner `FS25_TreeBrush` als ZIP packen (Ordnerstruktur beibehalten, `modDesc.xml` muss
   im ZIP-Hauptordner liegen) **oder** den kompletten Ordner direkt in den Mods-Ordner kopieren:
   - Windows: `C:\Users\<Name>\Documents\My Games\FarmingSimulator2025\mods\`
2. Spiel starten, Mod in der Modliste aktivieren.

## Bedienung (Standardbelegung, im Spiel umbelegbar unter Optionen → Tastenbelegung)

| Taste | Funktion |
|---|---|
| `T` | Baum-Brush an/aus |
| `Mittlere Maustaste` | Brush anwenden – **halten** und über den Wald ziehen |
| `Bild auf` / `Bild ab` | Radius vergrößern / verkleinern (2–30 m) |

- Ein roter Kreis zeigt die Brush-Position und den Radius auf dem Boden.
- Pro „Pinselstrich“ (alle 0,2 s beim Halten) werden alle statischen SplitShapes
  (Wildbäume der Karte **und** Stümpfe) im Radius entfernt.
- Konsolenbefehl (Öffnen mit `~`): `treeBrushRadius 15`

## Hinweise

- **Baugrundstücks-/Deko-Bäume**, die über das Baumenu im Bau-Modus platziert wurden, sind
  normale Placeables – diese werden weiterhin über das Baumenu gelöscht. Der Brush entfernt
  Kartenbäume (SplitShapes) und Stümpfe.
- **Multiplayer:** Das Entfernen wird als Event serverseitig ausgeführt (`cutTrees`-Berechtigung
  wird geprüft). Getestet für Singleplayer; im Dedicated-Server-Betrieb bitte vorher testen.
- Gelöschte Bäume sind **nicht wiederherstellbar** (kein Undo) – am besten vorher speichern.

## Technik

- `modDesc.xml` (descVersion 114): Aktionen, InputBindings, L10N (de/en), Icon.
- `TreeBrush.lua`: Kamera-Raycast durch den Mauszeiger (`unProject` + `raycastClosest` auf
  Terrain), Baumsuche per `overlapBox` mit `CollisionFlag.TREE`, Filter auf
  `ClassIds.MESH_SPLIT_SHAPE` + `getSplitType ~= 0` + statisch, Löschung über
  `treePlantManager:removingSplitShape` + `delete` (gleicher Ansatz wie der LumberJack-Mod).
- `events/TreeBrushDeleteEvent.lua`: Multiplayer-Event mit `read/writeSplitShapeIdFromStream`.
