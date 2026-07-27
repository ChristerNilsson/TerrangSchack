const $ = selector => document.querySelector(selector);
const $$ = selector => document.querySelectorAll(selector);

const pieces = {
  a8:'bR',b8:'bN',c8:'bB',d8:'bQ',e8:'bK',f8:'bB',g8:'bN',h8:'bR',
  a7:'bP',b7:'bP',c7:'bP',d7:'bP',e7:'bP',f7:'bP',g7:'bP',h7:'bP',
  a2:'wP',b2:'wP',c2:'wP',d2:'wP',e2:'wP',f2:'wP',g2:'wP',h2:'wP',
  a1:'wR',b1:'wN',c1:'wB',d1:'wQ',e1:'wK',f1:'wB',g1:'wN',h1:'wR'
};
delete pieces.e2;
delete pieces.g8;
pieces.e4 = 'bN';

function renderBoard(element, blackPerspective = false) {
  element.replaceChildren();
  const ranks = blackPerspective ? [1,2,3,4,5,6,7,8] : [8,7,6,5,4,3,2,1];
  const files = blackPerspective ? [7,6,5,4,3,2,1,0] : [0,1,2,3,4,5,6,7];
  for (const rank of ranks) {
    for (const file of files) {
      const position = 'abcdefgh'[file] + rank;
      const square = document.createElement('div');
      square.className = `square ${(file + rank) % 2 ? 'dark' : ''}`;
      if (file === 0 || rank === 1) square.innerHTML = `<span class="coord">${position}</span>`;
      if (pieces[position]) {
        square.insertAdjacentHTML('beforeend',
          `<img src="img/chesspieces/wikipedia/${pieces[position]}.png" alt="${pieces[position]}">`);
      }
      element.append(square);
    }
  }
}

renderBoard($('#board'));
renderBoard($('#adminBoard'));

$$('.nav').forEach(button => button.addEventListener('click', () => {
  $$('.nav,.view').forEach(element => element.classList.remove('active'));
  button.classList.add('active');
  $('#' + button.dataset.view).classList.add('active');
}));

let muted = false;
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

const query = new URLSearchParams(location.search);
const gameId = Number(query.get('parti') || 1);
const playerId = Number(query.get('spelare') || 1);
let latestMoveCount = 0;

async function action(name, confirmation) {
  if (confirmation && !confirm(confirmation)) return;
  const response = await fetch(
    `/api/parti/${gameId}/handling?spelare=${playerId}&handling=${name}`,
    {method: 'POST'}
  );
  const data = await response.json();
  if (!response.ok) return toast(data.fel || 'Åtgärden misslyckades');
  updateGame(data);
  const messages = {
    erbjud_remi: 'Remianbud skickat',
    acceptera_remi: 'Remianbud accepterat – partiet är remi',
    avsla_remi: 'Remianbud avslaget',
    ge_upp: 'Partiet har avslutats'
  };
  toast(messages[name]);
}

$('#draw').addEventListener('click', () => action('erbjud_remi'));
$('#acceptDraw').addEventListener('click', () => action('acceptera_remi'));
$('#declineDraw').addEventListener('click', () => action('avsla_remi'));
$('#resign').addEventListener('click', () => {
  action('ge_upp', 'Vill du verkligen ge upp partiet?');
});

$('#setup').addEventListener('submit', async event => {
  event.preventDefault();
  const [grundtid, inkrement] = $('#timeControl').value.split(',');
  const parameters = new URLSearchParams({
    spelare: playerId,
    vit_namn: $('#wName').value,
    svart_namn: $('#bName').value,
    vit_mail: $('#wMail').value,
    svart_mail: $('#bMail').value,
    vit_telefon: $('#wPhone').value,
    svart_telefon: $('#bPhone').value,
    grundtid,
    inkrement
  });
  const response = await fetch(`/api/admin/${gameId}?${parameters}`, {method: 'POST'});
  const data = await response.json();
  if (!response.ok) return toast(data.fel || 'Uppdateringen misslyckades');
  updateGame(data);
  toast('Spelaruppgifterna och betänketiden är uppdaterade');
});

function clock(seconds) {
  const hours = Math.floor(seconds / 3600);
  const minutes = Math.floor(seconds % 3600 / 60);
  const remaining = seconds % 60;
  return `${hours}:${String(minutes).padStart(2,'0')}:${String(remaining).padStart(2,'0')}`;
}

function updateGame(data) {
  $('#whiteName').textContent = data.vit_namn;
  $('#blackName').textContent = data.svart_namn;
  $('#whiteClock').textContent = clock(data.vit_tid);
  $('#blackClock').textContent = clock(data.svart_tid);
  $('#whiteRole').textContent = playerId === data.vit_id ? 'VIT · DU' : 'VIT';
  $('#blackRole').textContent = playerId === data.svart_id ? 'SVART · DU' : 'SVART';
  const newMoveCount = data.drag.length;
  if (latestMoveCount && newMoveCount > latestMoveCount) playMoveNotification();
  latestMoveCount = newMoveCount;
  const offerFromOpponent = data.remianbud_fran && data.remianbud_fran !== playerId;
  $('#acceptDraw').hidden = !offerFromOpponent;
  $('#declineDraw').hidden = !offerFromOpponent;
  $('#draw').hidden = Boolean(data.remianbud_fran) || data.status !== 'pågår';
  $('#resign').hidden = data.status !== 'pågår';
}

async function start() {
  const response = await fetch(`/api/parti/${gameId}?spelare=${playerId}`);
  if (!response.ok) return toast('Partiet kunde inte hämtas');
  const data = await response.json();
  updateGame(data);

  if (playerId === 0) {
    $('.nav[data-view="game"]').hidden = true;
    $('.nav[data-view="admin"]').click();
  } else {
    $('.nav[data-view="admin"]').hidden = true;
    renderBoard($('#board'), playerId === data.svart_id);
  }

  const events = new EventSource(`/events/${gameId}?spelare=${playerId}`);
  events.onmessage = event => updateGame(JSON.parse(event.data));
}

start();
