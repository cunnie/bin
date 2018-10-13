# python3 google_stt.py > /tmp/gcp_stt.json

# https://cloud.google.com/speech-to-text/docs/multiple-voices
# https://cloud.google.com/speech-to-text/docs/reference/libraries#client-libraries-usage-python

# bosh int --path=/gcp_credentials_json <(lpass show deployments.yml) > ~/Downloads/gcp.json
# export GOOGLE_APPLICATION_CREDENTIALS=$HOME/Downloads/gcp.json
import io

# Imports the Google Cloud client library
from google.cloud import speech_v1p1beta1 as speech

# Instantiates a client
client = speech.SpeechClient()

# gsutil cp ~/Google\ Drive/BlabberTabber/meeting2.wav gs://blabbertabber/meeting.wav
audio = client.types.RecognitionAudio(uri="gs://blabbertabber/meeting.wav")

config = speech.types.RecognitionConfig(
    encoding=speech.enums.RecognitionConfig.AudioEncoding.LINEAR16,
    sample_rate_hertz=16000,
    language_code='en-US',
    diarization_speaker_count=2,
    enable_speaker_diarization=True,
    model='video'
)

# https://cloud.google.com/speech-to-text/docs/async-recognize
operation = client.long_running_recognize(config, audio)

print('Waiting for operation to complete...')
response = operation.result(timeout=90)

# Detects speech in the audio file
response = client.recognize(config, audio)

print(response)
