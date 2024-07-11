import time
import torch
from transformers import AutoTokenizer, AutoModelForQuestionAnswering

# Print the memory allocated on GPU before loading the model
print(f"Memory allocated: {torch.cuda.memory_allocated() / 1024 ** 2:.2f} MB")
print(f"Memory reserved: {torch.cuda.memory_reserved() / 1024 ** 2:.2f} MB")

# Check if GPU is available
# device = torch.device('cuda' if torch.cuda.is_available() else 'cpu')
# device = torch.device('cpu')
device = torch.device('cuda')

# Load the tokenizer and the model
tokenizer = AutoTokenizer.from_pretrained('google-bert/bert-large-uncased-whole-word-masking-finetuned-squad')
model = AutoModelForQuestionAnswering.from_pretrained('google-bert/bert-large-uncased-whole-word-masking-finetuned-squad')

# Move the model to the GPU
model.to(device)
# Print the memory allocated on GPU after loading the model
print(f"Memory allocated: {torch.cuda.memory_allocated() / 1024 ** 2:.2f} MB")
print(f"Memory reserved: {torch.cuda.memory_reserved() / 1024 ** 2:.2f} MB")

# Input text
# text = "I love using Hugging Face models for NLP tasks!"
context = ("""It little profits that an idle king,
By this still hearth, among these barren crags,
Match'd with an aged wife, I mete and dole
Unequal laws unto a savage race,
That hoard, and sleep, and feed, and know not me.
I cannot rest from travel: I will drink
Life to the lees: All times I have enjoy'd
Greatly, have suffer'd greatly, both with those
That loved me, and alone, on shore, and when
Thro' scudding drifts the rainy Hyades
Vext the dim sea: I am become a name;
For always roaming with a hungry heart
Much have I seen and known; cities of men
And manners, climates, councils, governments,
Myself not least, but honour'd of them all;
And drunk delight of battle with my peers,
Far on the ringing plains of windy Troy.
I am a part of all that I have met;
Yet all experience is an arch wherethro'
Gleams that untravell'd world whose margin fades
For ever and forever when I move.
How dull it is to pause, to make an end,
To rust unburnish'd, not to shine in use!
As tho' to breathe were life! Life piled on life
Were all too little, and of one to me
Little remains: but every hour is saved
From that eternal silence, something more,
A bringer of new things; and vile it were
For some three suns to store and hoard myself,
And this gray spirit yearning in desire
To follow knowledge like a sinking star,
Beyond the utmost bound of human thought.

         This is my son, mine own Telemachus,
To whom I leave the sceptre and the isle,—
Well-loved of me, discerning to fulfil
This labour, by slow prudence to make mild
A rugged people, and thro' soft degrees
Subdue them to the useful and the good.
Most blameless is he, centred in the sphere
Of common duties, decent not to fail
In offices of tenderness, and pay
Meet adoration to my household gods,
When I am gone. He works his work, I mine.
""")

question = "What is my son's name?"

# Tokenize the text
inputs = tokenizer(question, context, return_tensors="pt")
# Move input tensors to the GPU
inputs = {k: v.to(device) for k, v in inputs.items()}

tokens = tokenizer.tokenize(question, context)
num_tokens = len(tokens)

# Perform inference and measure the time taken
start_time = time.time()
with torch.no_grad():
         outputs = model(**inputs)
end_time = time.time()

# Get the start and end positions of the answer
answer_start = torch.argmax(outputs.start_logits)
answer_end = torch.argmax(outputs.end_logits) + 1

# Convert tokens to the answer
answer = tokenizer.convert_tokens_to_string(tokenizer.convert_ids_to_tokens(inputs['input_ids'][0][answer_start:answer_end]))
# Calculate the time taken
time_taken = end_time - start_time

# Calculate tokens per second
tokens_per_second = num_tokens / time_taken

print(f"Number of tokens: {num_tokens}")
print(f"Time taken: {time_taken:.4f} seconds")
print(f"Tokens per second: {tokens_per_second:.2f}")
print(f"Question: {question}")
print(f"Answer: {answer}")
