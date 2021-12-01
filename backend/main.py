import tensorflow as tf
import tensorflow_hub as hub
import os
import matplotlib.pyplot as plt
from PIL import Image
from flask import Flask, flash, request, redirect, send_file, Response
import requests
from werkzeug.utils import secure_filename
from flask_ngrok import run_with_ngrok
import base64

os.environ['CUDA_VISIBLE_DEVICES'] = '-1'
UPLOAD_FOLDER = './uploads'
RESULT_FOLDER = './results'
ALLOWED_FORMATS = ['png', 'jpg', 'jpeg']


def img_scaler(image, max_dim = 512):
  original_shape = tf.cast(tf.shape(image)[:-1], tf.float32)
  scale_ratio = max_dim / max(original_shape)
  new_shape = tf.cast(original_shape * scale_ratio, tf.int32)
  return tf.image.resize(image, new_shape)

def load_img(path_to_img):
  img = tf.io.read_file(path_to_img)
  img = tf.image.decode_image(img, channels=3)
  img = tf.image.convert_image_dtype(img, tf.float32)
  img = img_scaler(img)
  return img[tf.newaxis, :]



hub_module = hub.load('https://tfhub.dev/google/magenta/arbitrary-image-stylization-v1-256/1')

def get_final_img(content, style, model):
    content_img = load_img(content)
    style_img = load_img(style)
    stylized_tensor = model(tf.constant(content_img), tf.constant(style_img))[0][0]
    pil_img = tf.keras.preprocessing.image.array_to_img(stylized_tensor)
    pil_img.save(f"{RESULT_FOLDER}/stylized.png")

app = Flask(__name__)
app.config['UPLOAD_FOLDER'] = UPLOAD_FOLDER
run_with_ngrok(app)

def allowed_extensions(filename):
    extension = filename.split('.')[1]
    if extension in ALLOWED_FORMATS:
        return True
    else:
        return False

@app.route('/upload', methods=['POST', 'GET'])
def upload_files():
    content = request.files['content']
    style = request.files['style']
    content_path = secure_filename(content.filename)
    style_path = secure_filename(style.filename)

    content_path = content_path.split("/")[-1]
    style_path = style_path.split("/")[-1]

    if allowed_extensions(content_path) and allowed_extensions(style_path):
        content.save("./"+UPLOAD_FOLDER+"/"+content_path)
        style.save("./"+UPLOAD_FOLDER+"/"+style_path)
        
        new_content_path = f"./{UPLOAD_FOLDER}/{content_path}"
        new_style_path = f"./{UPLOAD_FOLDER}/{style_path}"
        get_final_img(new_content_path, new_style_path, hub_module)
#         with open('stylized.png', 'rb') as final_img:
#             encoded_img = base64.b64encode(final_img.read())

        return send_file(f'{RESULT_FOLDER}/stylized.png', mimetype='image/png')

if __name__ == '__main__':
    app.run()
