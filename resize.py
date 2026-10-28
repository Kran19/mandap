
from PIL import Image

img = Image.open(r"C:/Users/Aviral Shukla/.gemini/antigravity-ide/brain/c9f862f3-332f-46af-924a-2c06f63d0fba/play_store_feature_graphic_1024x512_1790941834061.jpg")
img_resized = img.resize((1024, 512), Image.Resampling.LANCZOS)
img_resized.save(r"d:/mandap/feature_graphic_1024x512.png", "PNG")
print("SUCCESS: 1024x512 feature graphic generated")
