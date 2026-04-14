import os
import subprocess
import tempfile
import shutil

## frame extractor
def extract_frames(video_path : str, output_folder : str) -> list[str]:
    """Extract frames from a video file.
    
    Args:
        video_path (str): Path to the video file.
        output_folder (str): Path to the folder where frames will be extracted.
    
    Returns:
        list[str]: List of paths to the extracted frames.
    """
    print(f"[*] Extracting 1 frame per second from {video_path}...")
    # output pattern (using PNG to avoid lossy compression destroying watermarks)
    frame_pattern = os.path.join(output_folder, "frame_%04d.png")    
    command = [
        "ffmpeg",
        "-y", # Overwrite output files without asking
        "-i", video_path,
        "-vf", "fps=1", # The 1 FPS filter
        frame_pattern
    ]
    
    # check=True forces Python to throw an exception if FFmpeg fails
    subprocess.run(command, stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL, check=True)
    
    # Collecting and sorting the extracted frames
    frames = [os.path.join(output_folder, f) for f in os.listdir(output_folder) if f.endswith(".png")]
    return sorted(frames)

def stitch_video(frames_dir: str, original_video_path: str, output_video_path: str):
    """
    Stitches the 1 FPS frame sequence back together and maps the original audio.
    """
    print(f"[*] Reassembling video to {output_video_path}...")
    
    frame_pattern = os.path.join(frames_dir, "frame_%04d.png")
    
    command = [
        "ffmpeg",
        "-y",
        "-framerate", "1", # Matching extraction rate
        "-i", frame_pattern,
        "-i", original_video_path, # Pull audio from here
        "-map", "0:v", # Use video from input 0 (the frames)
        "-map", "1:a", # Use audio from input 1 (the original video)
        "-c:v", "libx264", # Standard MP4 video codec
        "-c:a", "copy", # Do not re-encode audio (saves time)
        "-pix_fmt", "yuv420p", # Ensures compatibility across all media players
        "-shortest", # Stop encoding when the shortest stream ends
        output_video_path
    ]
    
    subprocess.run(command, stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL, check=True)

