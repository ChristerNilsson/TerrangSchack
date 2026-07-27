"""FastHTML-server för Terrängschack."""

import asyncio
import json
import sqlite3
from pathlib import Path

from fasthtml.common import EventStream, FileResponse, JSONResponse, fast_app, serve


ROOT = Path(__file__).resolve().parent
DATABASE = ROOT / "terrangschack.db"
draw_offers: dict[int, int] = {}

app, rt = fast_app(pico=False)


def connect():
    connection = sqlite3.connect(DATABASE)
    connection.row_factory = sqlite3.Row
    connection.execute("PRAGMA foreign_keys = ON")
    return connection


def game_data(game_id: int):
    with connect() as db:
        game = db.execute(
            """SELECT p.*, v.namn AS vit_namn, s.namn AS svart_namn
               FROM parti p
               JOIN spelare v ON v.id = p.vit_id
               JOIN spelare s ON s.id = p.svart_id
               WHERE p.id = ?""",
            (game_id,),
        ).fetchone()
        if not game:
            return None
        moves = [
            dict(row) for row in db.execute(
                "SELECT nummer, franruta, tillruta FROM drag WHERE parti_id=? ORDER BY nummer",
                (game_id,),
            )
        ]
    result = dict(game)
    result["drag"] = moves
    result["remianbud_fran"] = draw_offers.get(game_id)
    return result


def valid_participant(data, player_id: int):
    return player_id == 0 or player_id in (data["vit_id"], data["svart_id"])


@rt("/")
def get(parti: int = 1, spelare: int = 1):
    data = game_data(parti)
    if not data or not valid_participant(data, spelare):
        return JSONResponse({"fel": "Okänt parti eller spelare"}, status_code=404)
    return FileResponse(ROOT / "index.html")


@rt("/api/parti/{parti}")
def get(parti: int, spelare: int):
    data = game_data(parti)
    if not data or not valid_participant(data, spelare):
        return JSONResponse({"fel": "Okänt parti eller spelare"}, status_code=404)
    return JSONResponse(data)


@rt("/api/parti/{parti}/handling")
def post(parti: int, spelare: int, handling: str):
    data = game_data(parti)
    if not data or spelare not in (data["vit_id"], data["svart_id"]):
        return JSONResponse({"fel": "Obehörig spelare"}, status_code=403)
    if handling == "erbjud_remi":
        draw_offers[parti] = spelare
    elif handling == "avsla_remi":
        draw_offers.pop(parti, None)
    elif handling == "acceptera_remi":
        if draw_offers.get(parti) in (None, spelare):
            return JSONResponse({"fel": "Det finns inget remianbud att acceptera"}, status_code=409)
        with connect() as db:
            db.execute("UPDATE parti SET status='remi' WHERE id=?", (parti,))
            db.commit()
        draw_offers.pop(parti, None)
    elif handling == "ge_upp":
        status = "svart vinst" if spelare == data["vit_id"] else "vit vinst"
        with connect() as db:
            db.execute("UPDATE parti SET status=? WHERE id=?", (status, parti))
            db.commit()
    else:
        return JSONResponse({"fel": "Okänd handling"}, status_code=400)
    return JSONResponse(game_data(parti))


@rt("/api/admin/{parti}")
def post(
    parti: int, spelare: int, vit_namn: str, svart_namn: str,
    vit_mail: str, svart_mail: str, vit_telefon: str, svart_telefon: str,
    grundtid: int, inkrement: int,
):
    data = game_data(parti)
    if not data or spelare != 0:
        return JSONResponse({"fel": "Endast admin får ändra partiet"}, status_code=403)
    with connect() as db:
        db.execute(
            "UPDATE spelare SET namn=?, mail=?, telefon=? WHERE id=?",
            (vit_namn, vit_mail, vit_telefon, data["vit_id"]),
        )
        db.execute(
            "UPDATE spelare SET namn=?, mail=?, telefon=? WHERE id=?",
            (svart_namn, svart_mail, svart_telefon, data["svart_id"]),
        )
        db.execute(
            "UPDATE parti SET vit_tid=?, svart_tid=?, inkrement=? WHERE id=?",
            (grundtid, grundtid, inkrement, parti),
        )
        db.commit()
    return JSONResponse(game_data(parti))


@rt("/events/{parti}")
def get(parti: int, spelare: int):
    async def updates():
        previous = None
        while True:
            data = game_data(parti)
            if not data or not valid_participant(data, spelare):
                yield "event: error\ndata: obehörig\n\n"
                return
            current = json.dumps(data, ensure_ascii=False, sort_keys=True)
            if current != previous:
                yield f"data: {current}\n\n"
                previous = current
            await asyncio.sleep(1)
    return EventStream(updates())


@rt("/{fname:path}.{ext:static}")
def get(fname: str, ext: str):
    requested = (ROOT / f"{fname}.{ext}").resolve()
    if ROOT not in requested.parents or not requested.is_file():
        return JSONResponse({"fel": "Filen finns inte"}, status_code=404)
    return FileResponse(requested)


if __name__ == "__main__":
    serve()
