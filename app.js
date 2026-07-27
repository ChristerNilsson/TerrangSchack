const $ = selector => document.querySelector(selector);
const $$ = selector => document.querySelectorAll(selector);
const files = 'abcdefgh';
const query = new URLSearchParams(location.search);
const gameId = Number(query.get('parti') || 1);
const playerId = Number(query.get('spelare') || 1);

const initialPosition = {
  a8:'bR',b8:'bN',c8:'bB',d8:'bQ',e8:'bK',f8:'bB',g8:'bN',h8:'bR',
  a7:'bP',b7:'bP',c7:'bP',d7:'bP',e7:'bP',f7:'bP',g7:'bP',h7:'bP',
  a2:'wP',b2:'wP',c2:'wP',d2:'wP',e2:'wP',f2:'wP',g2:'wP',h2:'wP',
  a1:'wR',b1:'wN',c1:'wB',d1:'wQ',e1:'wK',f1:'wB',g1:'wN',h1:'wR'
};

let game;
let position = {...initialPosition};
let selected = null;
let pendingMove = null;
let confirmedSquares = new Set();
let gpsWatchId = null;
let latestMoveCount = 0;
let muted = false;
let clockSnapshotAt = Date.now();

const colorOf = piece => piece?.[0];
const opponent = color => color === 'w' ? 'b' : 'w';
const coordinates = square => [files.indexOf(square[0]), Number(square[1])];
const squareAt = (file, rank) => file >= 0 && file < 8 && rank >= 1 && rank <= 8
  ? files[file] + rank : null;

function applyMove(board, move) {
  const piece = board[move.franruta];
  const [fromFile] = coordinates(move.franruta);
  const [toFile, toRank] = coordinates(move.tillruta);
  if (piece?.[1] === 'P' && fromFile !== toFile && !board[move.tillruta]) {
    delete board[squareAt(toFile, toRank + (colorOf(piece) === 'w' ? -1 : 1))];
  }
  delete board[move.franruta];
  board[move.tillruta] = piece;
  if (piece?.[1] === 'P' && (toRank === 1 || toRank === 8)) {
    board[move.tillruta] = colorOf(piece) + 'Q';
  }
  if (piece?.[1] === 'K' && Math.abs(fromFile - toFile) === 2) {
    const rank = colorOf(piece) === 'w' ? 1 : 8;
    const rookFrom = toFile === 6 ? `h${rank}` : `a${rank}`;
    const rookTo = toFile === 6 ? `f${rank}` : `d${rank}`;
    board[rookTo] = board[rookFrom];
    delete board[rookFrom];
  }
}

function rebuildPosition(moves) {
  const board = {...initialPosition};
  moves.forEach(move => applyMove(board, move));
  return board;
}

function pseudoMoves(board, from, attackOnly = false) {
  const piece = board[from];
  if (!piece) return [];
  const color = colorOf(piece);
  const kind = piece[1];
  const [file, rank] = coordinates(from);
  const result = [];
  const add = (target, captureOnly = false) => {
    if (!target) return false;
    const occupant = board[target];
    if (occupant && colorOf(occupant) === color) return false;
    if (!captureOnly || occupant) result.push(target);
    return !occupant;
  };
  const ray = (df, dr) => {
    for (let step = 1; step < 8; step++) {
      const target = squareAt(file + df * step, rank + dr * step);
      if (!target || !add(target)) break;
    }
  };

  if (kind === 'P') {
    const direction = color === 'w' ? 1 : -1;
    for (const df of [-1, 1]) {
      const target = squareAt(file + df, rank + direction);
      if (attackOnly) {
        if (target) result.push(target);
      } else if (target && board[target] && colorOf(board[target]) !== color) result.push(target);
    }
    if (attackOnly) return result;
    const one = squareAt(file, rank + direction);
    if (one && !board[one]) {
      result.push(one);
      const two = squareAt(file, rank + direction * 2);
      if ((rank === 2 && color === 'w' || rank === 7 && color === 'b') && !board[two]) result.push(two);
    }
    const previous = game?.drag.at(-1);
    if (previous) {
      const movedPiece = rebuildPosition(game.drag.slice(0, -1))[previous.franruta];
      const [pf, pr] = coordinates(previous.franruta);
      const [ptf, ptr] = coordinates(previous.tillruta);
      if (movedPiece?.[1] === 'P' && Math.abs(pr - ptr) === 2 && ptr === rank &&
          Math.abs(ptf - file) === 1 && board[previous.tillruta] === opponent(color) + 'P') {
        result.push(squareAt(ptf, rank + direction));
      }
    }
  } else if (kind === 'N') {
    [[1,2],[2,1],[-1,2],[-2,1],[1,-2],[2,-1],[-1,-2],[-2,-1]]
      .forEach(([df,dr]) => add(squareAt(file + df, rank + dr)));
  } else if (kind === 'B' || kind === 'R' || kind === 'Q') {
    if (kind !== 'R') [[1,1],[1,-1],[-1,1],[-1,-1]].forEach(([df,dr]) => ray(df,dr));
    if (kind !== 'B') [[1,0],[-1,0],[0,1],[0,-1]].forEach(([df,dr]) => ray(df,dr));
  } else if (kind === 'K') {
    for (let df = -1; df <= 1; df++) for (let dr = -1; dr <= 1; dr++) {
      if (df || dr) add(squareAt(file + df, rank + dr));
    }
    if (!attackOnly && !isAttacked(board, from, opponent(color))) {
      const homeRank = color === 'w' ? 1 : 8;
      const moved = new Set((game?.drag || []).flatMap(move => [move.franruta]));
      if (!moved.has(`e${homeRank}`)) {
        if (!moved.has(`h${homeRank}`) && board[`h${homeRank}`] === color+'R' &&
            !board[`f${homeRank}`] && !board[`g${homeRank}`] &&
            !isAttacked(board, `f${homeRank}`, opponent(color)) &&
            !isAttacked(board, `g${homeRank}`, opponent(color))) result.push(`g${homeRank}`);
        if (!moved.has(`a${homeRank}`) && board[`a${homeRank}`] === color+'R' &&
            !board[`b${homeRank}`] && !board[`c${homeRank}`] && !board[`d${homeRank}`] &&
            !isAttacked(board, `d${homeRank}`, opponent(color)) &&
            !isAttacked(board, `c${homeRank}`, opponent(color))) result.push(`c${homeRank}`);
      }
    }
  }
  return result;
}

function isAttacked(board, target, byColor) {
  return Object.keys(board).some(from =>
    colorOf(board[from]) === byColor && pseudoMoves(board, from, true).includes(target));
}

function legalMoves(from) {
  const piece = position[from];
  if (!piece) return [];
  return pseudoMoves(position, from).filter(to => {
    const next = {...position};
    applyMove(next, {franruta: from, tillruta: to});
    const king = Object.keys(next).find(square => next[square] === colorOf(piece) + 'K');
    return king && !isAttacked(next, king, opponent(colorOf(piece)));
  });
}

function renderBoard(element, blackPerspective = false, interactive = false) {
  element.replaceChildren();
  const ranks = blackPerspective ? [1,2,3,4,5,6,7,8] : [8,7,6,5,4,3,2,1];
  const orderedFiles = blackPerspective ? [7,6,5,4,3,2,1,0] : [0,1,2,3,4,5,6,7];
  for (const rank of ranks) for (const file of orderedFiles) {
    const name = files[file] + rank;
    const square = document.createElement('button');
    square.type = 'button';
    square.dataset.square = name;
    square.className = `square ${(file + rank) % 2 ? 'dark' : ''} ${interactive ? 'playable' : ''}`;
    const latest = game?.drag.at(-1);
    if (latest?.franruta === name) square.classList.add('last-from');
    if (latest?.tillruta === name) square.classList.add('last-to');
    square.setAttribute('aria-label', name);
    if (file === orderedFiles[0] || rank === ranks.at(-1)) {
      square.innerHTML = `<span class="coord">${name}</span>`;
    }
    if (position[name]) square.insertAdjacentHTML('beforeend',
      `<img src="img/chesspieces/wikipedia/${position[name]}.png" alt="${position[name]}">`);
    if (interactive) {
      square.addEventListener('click', () => chooseSquare(name));
      const turnColor = game.drag.length % 2 === 0 ? 'w' : 'b';
      const myColor = playerId === game.vit_id ? 'w' : playerId === game.svart_id ? 'b' : null;
      square.draggable = game.status === 'pågår' && turnColor === myColor &&
        colorOf(position[name]) === myColor;
      square.addEventListener('dragstart', event => {
        if (!square.draggable) return event.preventDefault();
        selected = name;
        event.dataTransfer.setData('text/plain', name);
        event.dataTransfer.effectAllowed = 'move';
        showSelection();
        $('#moveHelp').textContent = `Vald pjäs på ${name}. Släpp på en markerad ruta.`;
      });
      square.addEventListener('dragover', event => {
        if (selected && legalMoves(selected).includes(name)) {
          event.preventDefault();
          event.dataTransfer.dropEffect = 'move';
          square.classList.add('drag-target');
        }
      });
      square.addEventListener('dragleave', () => square.classList.remove('drag-target'));
      square.addEventListener('drop', event => {
        event.preventDefault();
        square.classList.remove('drag-target');
        const from = event.dataTransfer.getData('text/plain') || selected;
        if (from && legalMoves(from).includes(name)) stageMove(from, name);
      });
    }
    element.append(square);
  }
}

function chooseSquare(square) {
  if (!game || game.status !== 'pågår') return;
  if (pendingMove) return toast('Styr den blå markören till både från- och tillrutan');
  const turnColor = game.drag.length % 2 === 0 ? 'w' : 'b';
  const myColor = playerId === game.vit_id ? 'w' : playerId === game.svart_id ? 'b' : null;
  if (turnColor !== myColor) return toast('Det är motståndarens tur');
  if (selected && legalMoves(selected).includes(square)) return stageMove(selected, square);
  selected = colorOf(position[square]) === myColor ? square : null;
  showSelection();
  $('#moveHelp').textContent = selected
    ? `Vald pjäs på ${selected}. Välj en markerad målruta.`
    : 'Välj en av dina egna pjäser.';
}

function stageMove(from, to) {
  pendingMove = {from, to};
  selected = null;
  confirmedSquares = new Set();
  showSelection();
  showPendingMove();
  $('#moveHelp').textContent =
    `Drag ${from}–${to} valt. Besök båda rutornas centrum i valfri ordning (0 av 2).`;
  startGpsTracking();
}

function arriveAtSquare(square) {
  if (!pendingMove || ![pendingMove.from, pendingMove.to].includes(square) ||
      confirmedSquares.has(square)) return;
  confirmedSquares.add(square);
  playMoveNotification();
  showPendingMove();
  const count = confirmedSquares.size;
  $('#moveHelp').textContent = count < 2
    ? `${square} nådd och bekräftad. Gå nu till den andra rutan (1 av 2).`
    : 'Båda rutorna är bekräftade. Draget skickas…';
  if (count === 2) submitMove(pendingMove.from, pendingMove.to);
}

function offsetWgs84(latitude, longitude, east, north) {
  const radius = 6378137;
  return {
    lat: latitude + north / radius * 180 / Math.PI,
    lon: longitude + east / (radius * Math.cos(latitude * Math.PI / 180)) * 180 / Math.PI
  };
}

function boardCorners() {
  const half = game.storlek / 2;
  const angle = game.rotation * Math.PI / 180;
  const corner = (east, north) => {
    const rotatedEast = east * Math.cos(angle) - north * Math.sin(angle);
    const rotatedNorth = east * Math.sin(angle) + north * Math.cos(angle);
    return offsetWgs84(game.latitud, game.longitud, rotatedEast, rotatedNorth);
  };
  return {sw:corner(-half,-half), se:corner(half,-half),
    nw:corner(-half,half), ne:corner(half,half)};
}

function squareCenter(name) {
  const [file, rank] = coordinates(name);
  const u = (file + .5) / 8;
  const v = (rank - .5) / 8;
  const {sw,se,nw,ne} = boardCorners();
  const interpolate = key =>
    sw[key]*(1-u)*(1-v) + se[key]*u*(1-v) + nw[key]*(1-u)*v + ne[key]*u*v;
  return {lat:interpolate('lat'), lon:interpolate('lon')};
}

function distanceMeters(a, b) {
  const radius = 6371000;
  const toRadians = degrees => degrees * Math.PI / 180;
  const dLat = toRadians(b.lat-a.lat);
  const dLon = toRadians(b.lon-a.lon);
  const value = Math.sin(dLat/2)**2 + Math.cos(toRadians(a.lat)) *
    Math.cos(toRadians(b.lat)) * Math.sin(dLon/2)**2;
  return 2 * radius * Math.atan2(Math.sqrt(value), Math.sqrt(1-value));
}

function handleGpsPosition(positionEvent) {
  $('#gpsStatus').textContent = `±${Math.round(positionEvent.coords.accuracy)} m`;
  if (!pendingMove) return;
  const current = {lat:positionEvent.coords.latitude, lon:positionEvent.coords.longitude};
  const remaining = [pendingMove.from,pendingMove.to]
    .filter(name => !confirmedSquares.has(name))
    .map(name => ({name,distance:distanceMeters(current,squareCenter(name))}))
    .sort((a,b) => a.distance-b.distance);
  remaining.filter(target => target.distance < 25)
    .forEach(target => arriveAtSquare(target.name));
  const next = remaining.find(target => !confirmedSquares.has(target.name));
  $('#gpsTarget').textContent = next ? next.name.toUpperCase() : 'KLAR';
  $('#gpsDistance').textContent = next ? `${Math.round(next.distance)} m` : '0 m';
}

function startGpsTracking() {
  if (!navigator.geolocation) {
    $('#gpsStatus').textContent = 'SAKNAS';
    return toast('Den här enheten saknar GPS-stöd');
  }
  if (gpsWatchId !== null) navigator.geolocation.clearWatch(gpsWatchId);
  $('#gpsStatus').textContent = 'SÖKER…';
  gpsWatchId = navigator.geolocation.watchPosition(
    handleGpsPosition,
    error => {
      $('#gpsStatus').textContent = 'FEL';
      toast(error.code === 1 ? 'Tillåt platsåtkomst för att genomföra draget' :
        'GPS-positionen kunde inte hämtas');
    },
    {enableHighAccuracy:true, maximumAge:1000, timeout:15000}
  );
}

function showPendingMove() {
  $$('#board .square').forEach(square =>
    square.classList.remove('move-from','move-to','confirmed'));
  if (!pendingMove) return;
  const from = $(`#board [data-square="${pendingMove.from}"]`);
  const to = $(`#board [data-square="${pendingMove.to}"]`);
  from?.classList.add('move-from');
  to?.classList.add('move-to');
  confirmedSquares.forEach(name =>
    $(`#board [data-square="${name}"]`)?.classList.add('confirmed'));
}

function showSelection() {
  $$('#board .square').forEach(square => square.classList.remove('selected','legal','capture'));
  if (!selected) return;
  $(`#board [data-square="${selected}"]`).classList.add('selected');
  legalMoves(selected).forEach(target => {
    const square = $(`#board [data-square="${target}"]`);
    square.classList.add('legal');
    if (position[target]) square.classList.add('capture');
  });
}

async function submitMove(from, to) {
  const parameters = new URLSearchParams({spelare: playerId, franruta: from, tillruta: to});
  const response = await fetch(`/api/parti/${gameId}/drag?${parameters}`, {method: 'POST'});
  const data = await response.json();
  if (!response.ok) return toast(data.fel || 'Draget kunde inte sparas');
  selected = null;
  pendingMove = null;
  confirmedSquares.clear();
  if (gpsWatchId !== null) {
    navigator.geolocation.clearWatch(gpsWatchId);
    gpsWatchId = null;
  }
  $('#moveHelp').textContent = 'Draget är skickat. Väntar på motståndaren.';
  latestMoveCount = data.drag.length;
  updateGame(data, false);
}

$$('.nav').forEach(button => button.addEventListener('click', () => {
  $$('.nav,.view').forEach(element => element.classList.remove('active'));
  button.classList.add('active');
  $('#' + button.dataset.view).classList.add('active');
}));

$('#sound').addEventListener('click', () => {
  muted = !muted;
  $('#sound').textContent = muted ? '×♪' : '◖))';
  toast(muted ? 'Ljud av' : 'Ljud på');
});

function toast(message) {
  const element = $('#toast');
  element.textContent = message;
  element.classList.add('show');
  clearTimeout(element.timer);
  element.timer = setTimeout(() => element.classList.remove('show'), 2600);
}

function playMoveNotification() {
  if (!muted) new Audio('sounds/soundUp.wav').play().catch(() => {});
}

async function action(name, confirmation) {
  if (confirmation && !confirm(confirmation)) return;
  const response = await fetch(`/api/parti/${gameId}/handling?spelare=${playerId}&handling=${name}`, {method:'POST'});
  const data = await response.json();
  if (!response.ok) return toast(data.fel || 'Åtgärden misslyckades');
  updateGame(data, false);
  toast({erbjud_remi:'Remianbud skickat',acceptera_remi:'Partiet är remi',
    avsla_remi:'Remianbud avslaget',ge_upp:'Partiet har avslutats'}[name]);
}

$('#draw').onclick = () => action('erbjud_remi');
$('#acceptDraw').onclick = () => action('acceptera_remi');
$('#declineDraw').onclick = () => action('avsla_remi');
$('#resign').onclick = () => action('ge_upp', 'Vill du verkligen ge upp partiet?');

$('#setup').addEventListener('submit', async event => {
  event.preventDefault();
  const [grundtid, inkrement] = $('#timeControl').value.split(',');
  const parameters = new URLSearchParams({spelare:playerId,vit_namn:$('#wName').value,
    svart_namn:$('#bName').value,vit_mail:$('#wMail').value,svart_mail:$('#bMail').value,
    vit_telefon:$('#wPhone').value,svart_telefon:$('#bPhone').value,grundtid,inkrement,
    latitud:$('#boardLat').value,longitud:$('#boardLon').value,
    rotation:$('#boardRotation').value,storlek:$('#boardSize').value});
  const response = await fetch(`/api/admin/${gameId}?${parameters}`, {method:'POST'});
  const data = await response.json();
  if (!response.ok) return toast(data.fel || 'Uppdateringen misslyckades');
  updateGame(data, false);
  toast('Spelaruppgifterna och betänketiden är uppdaterade');
});

function clock(seconds) {
  const hours = Math.floor(seconds / 3600);
  const minutes = Math.floor(seconds % 3600 / 60);
  return `${hours}:${String(minutes).padStart(2,'0')}:${String(seconds%60).padStart(2,'0')}`;
}

function displayClocks() {
  if (!game) return;
  const whiteTurn = game.drag.length % 2 === 0;
  const elapsed = game.status === 'pågår' ? Math.floor((Date.now() - clockSnapshotAt) / 1000) : 0;
  const whiteSeconds = Math.max(0, game.vit_tid - (whiteTurn ? elapsed : 0));
  const blackSeconds = Math.max(0, game.svart_tid - (whiteTurn ? 0 : elapsed));
  $('#whiteClock').textContent = clock(whiteSeconds);
  $('#blackClock').textContent = clock(blackSeconds);
  $('#adminWhiteClock').textContent = clock(whiteSeconds);
  $('#adminBlackClock').textContent = clock(blackSeconds);
  $$('.player').forEach(element => element.classList.remove('clock-active'));
  $$('.admin-clocks article').forEach(element => element.classList.remove('clock-active'));
  if (game.status === 'pågår') {
    (whiteTurn ? $('.player:not(.black)') : $('.player.black')).classList.add('clock-active');
    (whiteTurn ? $('#adminWhiteClockBox') : $('#adminBlackClockBox')).classList.add('clock-active');
  }
}

function moveLabel(move, index) {
  if (!move) return 'Inga drag';
  const pieceNames = {P:'',N:'S',B:'L',R:'T',Q:'D',K:'K'};
  const before = rebuildPosition(game.drag.slice(0, index));
  const piece = before[move.franruta];
  if (!piece) return `${move.franruta}–${move.tillruta}`;
  const [fromFile] = coordinates(move.franruta);
  const [toFile, toRank] = coordinates(move.tillruta);
  if (piece[1] === 'K' && Math.abs(fromFile - toFile) === 2) {
    return toFile === 6 ? 'O-O' : 'O-O-O';
  }
  const capture = Boolean(before[move.tillruta]) || (piece[1] === 'P' && fromFile !== toFile);
  let notation = pieceNames[piece[1]];
  if (piece[1] === 'P' && capture) notation += move.franruta[0];
  if (capture) notation += 'x';
  notation += move.tillruta;
  if (piece[1] === 'P' && (toRank === 1 || toRank === 8)) notation += '=D';
  const after = {...before};
  applyMove(after, move);
  const enemyKing = Object.keys(after).find(square => after[square] === opponent(colorOf(piece)) + 'K');
  if (enemyKing && isAttacked(after, enemyKing, colorOf(piece))) notation += '+';
  return notation;
}

function updateGame(data, notify = true) {
  game = data;
  clockSnapshotAt = Date.now() - Math.max(0, Date.now() / 1000 - data.tur_startade) * 1000;
  position = rebuildPosition(data.drag);
  $('#whiteName').textContent = data.vit_namn;
  $('#blackName').textContent = data.svart_namn;
  $('#adminWhiteName').textContent = data.vit_namn;
  $('#adminBlackName').textContent = data.svart_namn;
  $('#boardLat').value = data.latitud;
  $('#boardLon').value = data.longitud;
  $('#boardRotation').value = data.rotation;
  $('#boardSize').value = data.storlek;
  displayClocks();
  $('#whiteRole').textContent = playerId === data.vit_id ? 'VIT · DU' : 'VIT';
  $('#blackRole').textContent = playerId === data.svart_id ? 'SVART · DU' : 'SVART';
  $('#moveNumber').textContent = `DRAG ${Math.floor(data.drag.length / 2) + 1}`;
  const whiteTurn = data.drag.length % 2 === 0;
  const myTurn = playerId === (whiteTurn ? data.vit_id : data.svart_id);
  $('#turnStatus').textContent = data.status !== 'pågår'
    ? `Partiet är ${data.status}`
    : myTurn ? 'Ditt drag' : 'Motståndarens drag';
  const latestNotation = moveLabel(data.drag.at(-1), data.drag.length - 1);
  $('#lastMove').textContent = latestNotation;
  $('#adminLastMove').textContent = latestNotation;
  if (notify && latestMoveCount && data.drag.length > latestMoveCount) playMoveNotification();
  latestMoveCount = data.drag.length;
  const opponentOffer = data.remianbud_fran && data.remianbud_fran !== playerId;
  $('#acceptDraw').hidden = !opponentOffer;
  $('#declineDraw').hidden = !opponentOffer;
  $('#draw').hidden = Boolean(data.remianbud_fran) || data.status !== 'pågår';
  $('#resign').hidden = data.status !== 'pågår';
  if (playerId !== 0) renderBoard($('#board'), playerId === data.svart_id, true);
  renderBoard($('#adminBoard'));
  showPendingMove();
}

async function start() {
  const response = await fetch(`/api/parti/${gameId}?spelare=${playerId}`);
  if (!response.ok) return toast('Partiet kunde inte hämtas');
  const data = await response.json();
  updateGame(data, false);
  if (playerId === 0) {
    $('.nav[data-view="game"]').hidden = true;
    $('.nav[data-view="admin"]').click();
  } else {
    $('.nav[data-view="admin"]').hidden = true;
  }
  const events = new EventSource(`/events/${gameId}?spelare=${playerId}`);
  events.onmessage = event => updateGame(JSON.parse(event.data));
}

start();
setInterval(displayClocks, 250);
$('#startGps').onclick = startGpsTracking;
