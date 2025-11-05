# main.py

import uvicorn
from fastapi import FastAPI, Request, Form, HTTPException
from fastapi.responses import HTMLResponse, JSONResponse
from fastapi.staticfiles import StaticFiles
from fastapi.templating import Jinja2Templates
from typing import List
import os

from app.logic import run_main_process



BASE_DIR = os.path.dirname(os.path.abspath(__file__))
app_dir = os.path.join(BASE_DIR, "app")

app = FastAPI(
    title="V2Ray Scraper Web UI",
    description="A web interface by arshiacomplus for scraping and checking V2Ray configs.",
    version="1.0.1"
)

app.mount("/static", StaticFiles(directory=os.path.join(app_dir, "web", "static")), name="static")
templates = Jinja2Templates(directory=os.path.join(app_dir, "web", "templates"))

@app.get("/", response_class=HTMLResponse)
async def get_home_page(request: Request):
    return templates.TemplateResponse("index.html", {"request": request})

@app.post("/api/scrape", response_class=JSONResponse)
async def handle_scrape_request(
    urls: str = Form(...),
    get_location: bool = Form(False)
):

    url_list = [url.strip() for url in urls.splitlines() if url.strip()]
    if not url_list:
        raise HTTPException(status_code=400, detail="No URLs provided. Please enter at least one URL.")

    options = {
        "get_location": get_location
    }
    try:
        final_configs = await run_main_process(url_list, options)
        return {"status": "success", "count": len(final_configs), "configs": final_configs}
    except Exception as e:
        print(f"An error occurred: {e}")
        raise HTTPException(status_code=500, detail=f"An internal server error occurred: {str(e)}")

if __name__ == "__main__":
    print("🚀 Starting V2Ray Scraper Web UI Server...")
    print("✅ Access the UI at: http://127.0.0.1:8000")
    uvicorn.run(
        "main:app",
        host="127.0.0.1",
        port=8000,
        reload=True,
        log_level="info"
    )