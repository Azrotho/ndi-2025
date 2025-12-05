#!/usr/bin/env python3
"""
Analyse spectrale de la musique pour le visualiseur Godot.
Génère un fichier JSON avec les données de fréquences à chaque frame.
"""

import numpy as np
import json
import os
from pathlib import Path

try:
    import librosa
except ImportError:
    print("Installation de librosa...")
    os.system("pip install librosa")
    import librosa

# Configuration
MUSIC_FILE = "../assets/musics/zone3.ogg"
OUTPUT_FILE = "../assets/musics/zone3_spectrum.json"
NUM_BARS = 24  # Nombre de barres du visualiseur
FPS = 30  # Frames par seconde pour l'analyse
MIN_FREQ = 20  # Hz
MAX_FREQ = 16000  # Hz

def analyze_music(music_path: str, output_path: str):
    """Analyse la musique et génère le fichier JSON."""
    
    print(f"Chargement de {music_path}...")
    
    # Charger le fichier audio
    y, sr = librosa.load(music_path, sr=None)
    duration = librosa.get_duration(y=y, sr=sr)
    
    print(f"Durée: {duration:.2f}s, Sample rate: {sr}Hz")
    
    # Calculer le nombre de frames
    hop_length = int(sr / FPS)
    n_frames = int(duration * FPS)
    
    print(f"Analyse de {n_frames} frames à {FPS} FPS...")
    
    # Calculer le spectrogramme
    # Utiliser une FFT plus grande pour une meilleure résolution en basses fréquences
    n_fft = 4096
    
    # Spectrogramme de magnitude
    S = np.abs(librosa.stft(y, n_fft=n_fft, hop_length=hop_length))
    
    # Convertir en dB
    S_db = librosa.amplitude_to_db(S, ref=np.max)
    
    # Fréquences correspondant à chaque bin
    freqs = librosa.fft_frequencies(sr=sr, n_fft=n_fft)
    
    # Calculer les plages de fréquences pour chaque barre (échelle logarithmique)
    bar_freqs = []
    for i in range(NUM_BARS + 1):
        freq = MIN_FREQ * (MAX_FREQ / MIN_FREQ) ** (i / NUM_BARS)
        bar_freqs.append(freq)
    
    # Données de sortie
    spectrum_data = {
        "fps": FPS,
        "duration": duration,
        "num_bars": NUM_BARS,
        "frames": []
    }
    
    print("Extraction des données spectrales...")
    
    # Pour chaque frame temporelle
    for frame_idx in range(min(S.shape[1], n_frames)):
        frame_spectrum = S_db[:, frame_idx]
        
        bars = []
        for bar_idx in range(NUM_BARS):
            freq_low = bar_freqs[bar_idx]
            freq_high = bar_freqs[bar_idx + 1]
            
            # Trouver les bins correspondants
            bin_low = np.searchsorted(freqs, freq_low)
            bin_high = np.searchsorted(freqs, freq_high)
            
            if bin_high > bin_low:
                # Moyenne des magnitudes dans cette plage
                magnitude = np.mean(frame_spectrum[bin_low:bin_high])
            else:
                magnitude = frame_spectrum[min(bin_low, len(frame_spectrum) - 1)]
            
            # Normaliser de dB à 0-1
            # La musique est jouée à -21dB en jeu, donc on ajuste la plage
            # Les valeurs sont généralement entre -80dB et 0dB dans l'analyse
            # On décale pour compenser le volume de lecture
            normalized = (magnitude + 60) / 60  # Plage plus restreinte pour plus de sensibilité
            normalized = max(0.0, min(1.0, normalized))
            
            # Courbe de réponse plus naturelle (moins d'amplification)
            normalized = normalized ** 0.8
            normalized = max(0.0, min(1.0, normalized))
            
            bars.append(round(float(normalized), 3))
        
        spectrum_data["frames"].append(bars)
        
        if frame_idx % 100 == 0:
            print(f"  Frame {frame_idx}/{n_frames}")
    
    # Détecter les beats
    print("Détection des beats...")
    tempo, beat_frames = librosa.beat.beat_track(y=y, sr=sr, hop_length=hop_length)
    
    # Convertir en temps en secondes (pour le visualiseur Godot)
    beat_times = librosa.frames_to_time(beat_frames, sr=sr, hop_length=hop_length)
    beat_times_list = [round(float(t), 3) for t in beat_times]
    
    # Gérer le cas où tempo est un array
    if hasattr(tempo, '__len__'):
        tempo = tempo[0] if len(tempo) > 0 else 120.0
    spectrum_data["tempo"] = float(tempo)
    spectrum_data["beats"] = beat_times_list  # En secondes, pas en indices!
    
    # Sauvegarder le JSON
    print(f"Sauvegarde dans {output_path}...")
    
    with open(output_path, 'w') as f:
        json.dump(spectrum_data, f)
    
    # Calculer la taille du fichier
    file_size = os.path.getsize(output_path) / 1024
    print(f"Terminé! Fichier: {file_size:.1f} KB")
    print(f"  - {len(spectrum_data['frames'])} frames")
    print(f"  - Tempo détecté: {tempo:.1f} BPM")
    print(f"  - {len(beat_times_list)} beats détectés")

if __name__ == "__main__":
    script_dir = Path(__file__).parent
    music_path = script_dir / MUSIC_FILE
    output_path = script_dir / OUTPUT_FILE
    
    if not music_path.exists():
        print(f"Erreur: Fichier non trouvé: {music_path}")
        exit(1)
    
    analyze_music(str(music_path), str(output_path))
