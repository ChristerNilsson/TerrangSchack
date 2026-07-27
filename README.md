# Terrängschack

Starta FastHTML-servern:

```powershell
python -m pip install -r requirements.txt
python server.py
```

Öppna därefter någon av vyerna:

- Vit spelare: <http://localhost:5001/?parti=1&spelare=1>
- Svart spelare: <http://localhost:5001/?parti=1&spelare=2>
- Admin: <http://localhost:5001/?parti=1&spelare=0>

Servern använder `terrangschack.db`. Realtidsuppdateringar skickas med
Server-Sent Events och motståndardrag aviseras med ett pling i klienten.
