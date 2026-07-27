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
* Klienten ska vara ansvarig för att visa senaste drag samt även bara acceptera tillåtna drag.
* Senaste draget visas genom att bakgrundsfärgerna för Från och Till visas med annan färg.
* Aktuell schackklocka ska ticka ner
* Visa dragen med kort schacknotation. T ex Sf3
* Klockorna ska visas även för Admin. En klocka ska dessutom ticka ner.

* För att ett drag ska godkännas, t ex e2-e4, måste spelaren högerklicka både på e2 och e4 i godtycklig ordning. Ordningen blir vänsterklick på e2, vänsterklick på e4, högerklick på den ena rutan, därefter högerklick på den andra rutan.

* Klienten ska nu markera aktuell ruta. Denna kan påverkas med fyra knappar, upp, ner, vänster, höger. Istället för att högerklicka på en ruta, ska man nu ta sig till rutan mha dessa fyra knappar.

* De fyra knapparna ska nu ersättas med att man fysiskt, i terrängen, går till de båda rutorna. När man nått en ruta, hörs en pling och man går till nästa ruta. Då båda rutorna nåtts, utförs draget.

* Om schackbrädet är 800 meter stort, är varje ruta 100x100. Om avståndet till rutans centrum är mindre än 25 meter, har man nått rutan. Här används alltså mobiltelefonens GPS. Målrutans centrum kan beräknas eftersom man vet schackbrädets centrum och storlek, samt rotationen. Det borde gå att approximera genom att antaga att WGS84 uppför sig linjärt vid små avstånd. Beräkna först de fyra hörnens WGS84-koordinater och därefter kan de 64 rutornas WGS84-koordinater beräknas med interpolation.