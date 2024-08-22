# Creates a big file for context
# export GUTENBERG_MIRROR=http://mirrors.xmission.com/gutenberg/
import re
from gutenberg.acquire import load_etext
from gutenberg.cleanup import strip_headers

# Download and clean text
text_id = 2701 # Moby Dick
text = strip_headers(load_etext(text_id)).strip()
words = re.findall(r'\b\w+\b', text.lower())

# Ensure enough words
if len(words) < 131072:
    print("Text doesn't have enough words. Choose a larger text.")
else:
    # Take the first 131072 words
    first_131072_words = words[:131072]

    # Write to file
    with open("/tmp/words.txt", "w") as f:
        for word in first_131072_words:
            f.write(word + "\n")
