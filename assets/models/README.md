# ML Model Assets

This directory contains TensorFlow Lite models for on-device inference.

## Required Models (not included in repo — download separately)

### YOLOv8-nano (`yolov8n.tflite`)
- Object detection model (~6MB)
- COCO dataset: 80 object classes
- Download: Export from Ultralytics or use pre-converted model
- Labels: `labels_yolo.txt`

### MobileNetV3-Small (`mobilenet_v3.tflite`)
- Image classification model (~5MB)
- ImageNet: 1000 classes
- Download: TensorFlow Hub or TFLite model zoo
- Labels: `labels_mobilenet.txt`

## Setup

1. Download models from the links above
2. Place `.tflite` files in this directory
3. The app will detect if models are missing and fall back to LLM-only analysis

## Label Files
- `labels_yolo.txt` — COCO 80-class labels (included)
- `labels_mobilenet.txt` — ImageNet 1000-class labels (download with model)
- `category_mapping.json` — Maps YOLO/ImageNet labels to inventory categories (included)
