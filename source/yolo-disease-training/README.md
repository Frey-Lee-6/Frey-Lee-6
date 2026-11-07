# YOLO Disease Training Experiments

A Python experiment workflow for crop disease detection, including dataset splitting, label counting, standard YOLO training, and a three-stage fine-tuning schedule.

**Python · Ultralytics YOLO · PyTorch**

[Project overview](../../projects/crop-disease.md) · [Training script](train.py) · [Dataset example](data.example.yaml)

## Included files

| File | Purpose |
| --- | --- |
| `train.py` | Standard training, staged training, and validation/test evaluation calls |
| `split_dataset.py` | Copy JPG images and matching label files into a 70/20/10 split |
| `analyze_dataset.py` | Count class IDs in the source label directory |
| `data.example.yaml` | Dataset paths and example disease labels |
| `requirements.txt` | Declared Python dependencies |

## Environment setup

Create an isolated environment, then install the declared dependencies. The requirements use minimum versions, so record the actual installed versions when running an experiment.

```sh
git clone https://github.com/Frey-Lee-6/Frey-Lee-6.git
cd Frey-Lee-6/source/yolo-disease-training
python -m venv .venv
```

Activate the environment for your shell.

```powershell
# Windows PowerShell
.\.venv\Scripts\Activate.ps1
```

```sh
# macOS or Linux
source .venv/bin/activate
```

```sh
python -m pip install -r requirements.txt
```

Select a PyTorch installation compatible with your hardware if you intend to use CUDA. Check the installed Ultralytics version's YOLO11 support before using the default checkpoint. [Ultralytics installation guidance](https://docs.ultralytics.com/quickstart/)

## Prepare the dataset

Use images with YOLO detection labels. Each label row should identify a class and a normalized bounding box.

```text
class_id x_center y_center width height
```

For an already partitioned dataset, use this layout.

```text
dataset/
├── train/
│   ├── images/
│   └── labels/
├── val/
│   ├── images/
│   └── labels/
└── test/
    ├── images/
    └── labels/
```

Copy `data.example.yaml` to `data.yaml`. Set `path` to the dataset's absolute path and align the class names with the numeric IDs in the annotations.

The example labels are `0 BrownSpot`, `1 RiceBlast`, and `2 BacterialBlight`. The numeric prefixes are part of the current label strings. Some inherited experiment names refer to corn, so confirm the actual data rather than inferring the crop from those names.

### Optional split utility

Place the original JPG images in `train/images` and labels in `train/labels`, then run the following command from a clean working directory.

```sh
python split_dataset.py
```

The utility copies files into `dataset/` with a 70/20/10 split and random seed 42. It processes lowercase `.jpg` matches and copies a label only if the matching file exists. It does not clear old output or establish whether a missing label is intentional. Validate image/label pairs and retain a split manifest before using the output for reported results.

## Training interface

Inspect the available arguments first.

```sh
python train.py --help
```

| Argument | Default | Meaning |
| --- | --- | --- |
| `--data` | `data.yaml` | Dataset configuration |
| `--model` | `yolo11n.pt` | Initial weights |
| `--img-size` | `640` | Input image size |
| `--epochs` | `100` | Total epochs |
| `--device` | `0` | Compute device, such as `0` or `cpu` |
| `--project` | `corn_disease_final` | Experiment output project |
| `--three-stage` | Disabled | Enable staged fine-tuning |

After resolving the output-path issue below, the intended standard-training invocation is as follows.

```sh
python train.py --data data.yaml --model yolo11n.pt --device cpu --epochs 100
```

Add `--three-stage` to select the staged schedule.

| Stage | Epoch allocation | Configured freeze count | Initial learning rate |
| --- | --- | --- | --- |
| 1 | 30% | 10 | 0.01 |
| 2 | 40% | 5 | 0.001 |
| 3 | Remaining epochs | 0 | 0.0001 |

All stages use a batch size of 8. Integer rounding affects the allocation for small epoch counts.

## Current execution issue

The script passes `project=project_name` to the trainer but constructs subsequent checkpoint paths with an additional `runs/detect/` prefix. Depending on the resolved output directory, the next stage can fail to locate `best.pt`, and the printed final path can be inaccurate.

Before a complete run, align checkpoint loading with the actual training output. The three-stage workflow remains unverified in this release.

## Evaluation

The script calls validation on the validation and test splits and prints precision, recall, mAP@0.5, and mAP@0.5:0.95. Dataset images, trained checkpoints, and a verified result table are not bundled.

For a reproducible comparison, retain the dataset source and license, split manifest, dependency versions, training arguments, random seeds, checkpoint identity, and evaluation output. This enables later comparison of the standard and staged schedules.
