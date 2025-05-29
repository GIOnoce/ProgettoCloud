# LoadData.py
# Modulo di supporto per MyTEDx Rewind – Caricamento dei dati

import pandas as pd
import os

DATASET_DIR = "dataset/"
DEFAULT_TALKS = os.path.join(DATASET_DIR, "talks.csv")
DEFAULT_WATCH_NEXT = os.path.join(DATASET_DIR, "watch_next.csv")
DEFAULT_TRANSCRIPTS = os.path.join(DATASET_DIR, "transcripts.csv")

def load_talks(path=DEFAULT_TALKS):
    if not os.path.exists(path):
        raise FileNotFoundError(f"File talks non trovato: {path}")
    return pd.read_csv(path)

def load_watch_next(path=DEFAULT_WATCH_NEXT):
    if not os.path.exists(path):
        raise FileNotFoundError(f"File watch_next non trovato: {path}")
    return pd.read_csv(path)

def load_transcripts(path=DEFAULT_TRANSCRIPTS):
    if not os.path.exists(path):
        raise FileNotFoundError(f"File transcripts non trovato: {path}")
    return pd.read_csv(path)

def load_all():
    talks = load_talks()
    watch_next = load_watch_next()
    transcripts = load_transcripts()
    return talks, watch_next, transcripts
