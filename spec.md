# Terrängschack

## Introduktion

* Två spelare ska spela ett schackparti
* De har var sin mobiltelefon.
* Spelaren informeras om motståndarens drag via en pling
* Diagrammet visar partiet

## Admin

* Lägger upp de två spelarnas namn, mail och telefonnummer.
* Admin bestämmer betänketiden, t ex 90m + 30s.
* Under partiet kan Admin se partiet

## Klienten

* Visar schackbrädet
* GUI:t visar spelarnas namn samt hur mycket tid de har kvar.
* Man ska kunna bjuda remi, avslå remi, acceptera remi samt ge upp.

## Servern

* Håller reda på nödvändig information via en databas.
* Ser till att dragen skickas ut till spelarna utan fördröjning.
* Denna ska skrivas i python FastHTML

## Databas

### Tabell Spelare

* ID
* namn
* telefon
* mail

### Tabell Parti

* ID
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
* Skapa en sqlite-databas.
* Lägg in lämpliga rader i databasen. Ett parti, två spelare, några drag
* Spelarna anropar via följande urlar:
	* ?parti=1&spelare=1
	* ?parti=1&spelare=2
* Admin anropar via ?parti=1&spelare=0
* Skapa servern
* Skapa klienten