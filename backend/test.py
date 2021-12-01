import tensorflow as tf
import tensorflow_hub as hub
import os
import matplotlib.pyplot as plt
from PIL import Image
from flask import Flask, flash, request, redirect, url_for
import requests
from werkzeug.utils import secure_filename
from flask_ngrok import run_with_ngrok

os.environ['CUDA_VISIBLE_DEVICES'] = '-1'
UPLOAD_FOLDER = './uploads'
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
    pil_img.save("stylized4.png")

content = './me.png'
style = './blob.jpg'

get_final_img(content, style, hub_module)

