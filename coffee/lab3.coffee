echo = console.log
echo 'adam'
# Starta nytt spel
game = new Chess()

# Hämta DOM-elementet
boardDiv = document.getElementById('board')

# Skapa brädet utan drag-and-drop 
board = Chessboard(boardDiv,
  draggable: false
  position: 'start'
)

# Spara vald frånruta
selectedSquare = null

# Spara senaste draget
lastMove = null

# Rensa alla highlights
clearHighlights = ->
  squares = boardDiv.querySelectorAll('.square-55d63')
  for square in squares
    square.style.background = ''

# Highlighta en ruta
highlightSquare = (square, color = '#a9a9a9') ->
  el = boardDiv.querySelector("[data-square='#{square}']")
  if el
    el.style.background = color

# Lägg på klickhantering
boardDiv.addEventListener 'click', (event) ->

  target = event.target
  echo target.classList
  # Om klick på ruta
  if target.classList.contains('square-55d63')

    square = target.getAttribute('data-square')

    if selectedSquare
      # Andra klicket → försök göra drag
      move = game.move(
        from: selectedSquare
        to: square
        promotion: 'q'
      )

      if move
        board.position(game.fen())
        lastMove = move
        # Efter lyckat drag:
        clearHighlights()
        highlightSquare(move.from, '#f6f669')  # Ljusgul frånruta
        highlightSquare(move.to, '#baca44')    # Ljusgrön toruta

      # Nollställ efter försök
      selectedSquare = null

    else
      # Första klicket
      selectedSquare = square
      clearHighlights()

      # Visa senaste drag
      if lastMove
        highlightSquare(lastMove.from, '#f6f669')
        highlightSquare(lastMove.to, '#baca44')

      # Markera vald ruta
      highlightSquare(square, '#a9a9a9')
