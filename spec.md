# Terrängschack

## Introduktion

* Två spelare ska spela ett schackparti i terrängen
* De har var sin mobiltelefon.
* För att ett drag ska gälla, måste både Frånruta och Tillruta besökas. I godtycklig ordning.
* Spelaren styrs via två röster, en för bäring, en för avstånd. Servern anger vilken ruta som ska besökas först.
* Spelaren informeras om motståndarens drag via en röst.
* Diagrammet visar spelarens position och eventuell målruta.

## Admin

* Lägger upp de två spelarnas namn, mail och telefonnummer.
* Anger dessutom var schackbrädet ska ligga i terrängen.
* Admin beger sig till brädets mittpunkt och skapar brädet där.
* Admin kan rotera brädet kring denna mittpunkt i steg om tio grader
* Admin bestämmer brädets storlek, t ex 800 meter.
* Admin bestämmer betänketiden, t ex 90m + 30s.
* Under partiet kan Admin se partiet och var spelarna befinner sig.

## Klienten

* Visar schackbrädet
* Spelaren kan se sin egen position samt sin målruta.
* GUI:t visar spelarnas namn samt hur mycket tid de har kvar.
* Man ska kunna bjuda remi, avslå remi, acceptera remi samt ge upp.

## Servern

* Håller reda på nödvändig information via en databas.
* Ser till att dragen skickas ut till spelarna utan fördröjning.

## Databas

### Tabell Spelare

* ID
* namn
* telefon
* mail
* latitud (wgs84)
* longitud (wgs84)

### Tabell Parti

* ID
* latitud (wgs84)
* longitud (wgs84)
* rotation (grader)
* storlek (meter)
* vit_ID
* svart_ID
* inkrement (sekunder)
* vit_tid (sekunder)
* svart_tid (sekunder)
* status (pågår, remi, vit vinst, svart vinst)

### Tabell Drag

* parti_ID
* nummer
* frånruta (t ex e2)
* tillruta (t ex e4)

## Promptar

* Se till att rutorna är kvadratiska
* Lägg in lämpliga rader i databasen. Ett parti, två spelare, några drag
* Skapa en sqlite-databas.
