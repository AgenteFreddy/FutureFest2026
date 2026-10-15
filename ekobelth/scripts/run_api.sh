#!/bin/bash
cd "$(dirname "$0")/.."
source .venv/bin/activate
python -m backend.ia_eko_api
