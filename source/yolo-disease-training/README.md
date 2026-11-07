# YOLO 作物病害训练实验

这份源码包含单阶段训练、分阶段微调和数据集划分。公开示例沿用该版本的三个标签，分别为 BrownSpot、RiceBlast 和 BacterialBlight。

## 准备与运行

1. 创建 Python 虚拟环境并运行 `python -m pip install -r requirements.txt`。
2. 准备 YOLO 格式的图像与标签。已有训练、验证和测试目录时，可以直接配置路径。也可在干净目录中将原始 JPG 放入 `train/images`、标签放入 `train/labels`，再运行 `python split_dataset.py`。
3. 复制 `data.example.yaml` 为 `data.yaml`，将 `path` 改成数据集的实际绝对路径，并核对标签编号。
4. 运行 `python train.py --data data.yaml --model yolo11n.pt --device cpu`。有可用的 CUDA 显卡时可指定 `--device 0`。运行 `python train.py --help` 查看其他选项。

数据集和模型权重需自行准备。本页展示训练流程，未复跑完整训练，未发布性能指标。
