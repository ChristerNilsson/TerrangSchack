const $=s=>document.querySelector(s), $$=s=>document.querySelectorAll(s);
const pieces={a8:'bR',b8:'bN',c8:'bB',d8:'bQ',e8:'bK',f8:'bB',g8:'bN',h8:'bR',a7:'bP',b7:'bP',c7:'bP',d7:'bP',e7:'bP',f7:'bP',g7:'bP',h7:'bP',a2:'wP',b2:'wP',c2:'wP',d2:'wP',e2:'wP',f2:'wP',g2:'wP',h2:'wP',a1:'wR',b1:'wN',c1:'wB',d1:'wQ',e1:'wK',f1:'wB',g1:'wN',h1:'wR'};
delete pieces.e2; delete pieces.g8; pieces.e4='bN';
for(let rank=8;rank>=1;rank--) for(let file=0;file<8;file++){
  const pos='abcdefgh'[file]+rank, square=document.createElement('div');
  square.className='square '+((file+rank)%2?'dark':'')+(pos==='f3'?' target':'');
  if(file===0||rank===1) square.innerHTML=`<span class="coord">${pos}</span>`;
  if(pieces[pos]) square.insertAdjacentHTML('beforeend',`<img src="img/chesspieces/wikipedia/${pieces[pos]}.png" alt="${pieces[pos]}">`);
  $('#board').append(square);
}
$$('.nav').forEach(b=>b.onclick=()=>{$$('.nav,.view').forEach(x=>x.classList.remove('active'));b.classList.add('active');$('#'+b.dataset.view).classList.add('active')});
let muted=false; $('#sound').onclick=()=>{muted=!muted;$('#sound').textContent=muted?'×♪':'◖))';toast(muted?'Ljud av':'Ljud på')};
function toast(message){const t=$('#toast');t.textContent=message;t.classList.add('show');clearTimeout(t.timer);t.timer=setTimeout(()=>t.classList.remove('show'),2600)}
function speak(){if(muted)return toast('Slå på ljudet för vägledning');if('speechSynthesis'in window){speechSynthesis.cancel();speechSynthesis.speak(new SpeechSynthesisUtterance('Bäring sjuttiotvå grader. Avstånd etthundraåttiofyra meter.'))}toast('Vägledning spelas upp')}
$('#repeat').onclick=speak;
$('#draw').onclick=()=>toast('Remianbud skickat till Erik');
$('#resign').onclick=()=>confirm('Vill du verkligen ge upp partiet?')&&toast('Partiet har avslutats');
$('#size').oninput=e=>$('#sizeOut').value=e.target.value+' m';
$('#rotation').oninput=e=>{$('#rotationOut').value=e.target.value+'°'};
$('#locate').onclick=()=>{if(!navigator.geolocation)return toast('Positionering stöds inte');toast('Hämtar position…');navigator.geolocation.getCurrentPosition(p=>{$('#coords').textContent=`WGS84 ${p.coords.latitude.toFixed(4)}, ${p.coords.longitude.toFixed(4)}`;toast('Mittpunkten är uppdaterad')},()=>toast('Kunde inte läsa positionen'))};
$('#setup').onsubmit=e=>{e.preventDefault();$('#whiteName').textContent=$('#wName').value;$('#blackName').textContent=$('#bName').value;toast('Partiet är skapat och inbjudningarna skickade')};
let seconds=5262;setInterval(()=>{seconds--;const h=Math.floor(seconds/3600),m=Math.floor(seconds%3600/60),s=seconds%60;$('#whiteClock').textContent=`${h}:${String(m).padStart(2,'0')}:${String(s).padStart(2,'0')}`},1000);
