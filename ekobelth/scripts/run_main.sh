#!/bin/bash
cd "$(dirname "$0")/.."
source .venv/bin/activate
python -m backend.main_api
