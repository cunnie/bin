# https://cloud.google.com/speech-to-text/docs/reference/libraries#client-libraries-usage-python

# bosh int --path=/gcp_credentials_json <(lpass show deployments.yml) > ~/Downloads/gcp.json
# export GOOGLE_APPLICATION_CREDENTIALS=$HOME/Downloads/gcp.json
import io

# Imports the Google Cloud client library
from google.cloud import speech
from google.cloud.speech import enums
from google.cloud.speech import types

# Instantiates a client
client = speech.SpeechClient()

# The name of the audio file to transcribe
file_name = "/Users/cunnie/Google Drive/BlabberTabber/meeting2.wav"

# Loads the audio into memory
with io.open(file_name, 'rb') as audio_file:
    content = audio_file.read()
    audio = types.RecognitionAudio(content=content)

config = types.RecognitionConfig(
    encoding=enums.RecognitionConfig.AudioEncoding.LINEAR16,
    sample_rate_hertz=16000,
    language_code='en-US',
    diarization_speaker_count=2,
    enable_speaker_diarization=True,
    model='video'
)

# Detects speech in the audio file
response = client.recognize(config, audio)

print(response)
