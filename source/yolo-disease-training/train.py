import os
import sys
import argparse
from pathlib import Path
import torch
import yaml

def check_yolo_available():
    try:
        from ultralytics import YOLO
        return True
    except ImportError:
        return False

def train_three_stage(data_yaml, model_name='yolo11n.pt', img_size=640, epochs=100, device='0', project_name='corn_disease_final'):
    from ultralytics import YOLO
    from datetime import datetime
    
    timestamp = datetime.now().strftime('%Y%m%d_%H%M%S')
    
    print(f"=" * 60)
    print(f"开始三阶段训练策略")
    print(f"项目名称: {project_name}_{timestamp}")
    print(f"=" * 60)
    
    model = YOLO(model_name)
    
    total_epochs = epochs
    stage1_epochs = int(total_epochs * 0.3)
    stage2_epochs = int(total_epochs * 0.4)
    stage3_epochs = total_epochs - stage1_epochs - stage2_epochs
    
    print(f"\n第一阶段: 热身训练 ({stage1_epochs} epochs)")
    print(f"- 冻结骨干网络，训练头部")
    print(f"- 较高的学习率")
    results = model.train(
        data=data_yaml,
        epochs=stage1_epochs,
        imgsz=img_size,
        device=device,
        batch=8,
        patience=50,
        save=True,
        plots=True,
        lr0=0.01,
        lrf=0.1,
        freeze=10,
        project=project_name,
        name=f'stage1_{timestamp}'
    )
    
    print(f"\n第二阶段: 精调训练 ({stage2_epochs} epochs)")
    print(f"- 解冻大部分层，使用中等学习率")
    best_model1 = f'runs/detect/{project_name}/stage1_{timestamp}/weights/best.pt'
    model = YOLO(best_model1)
    results = model.train(
        data=data_yaml,
        epochs=stage2_epochs,
        imgsz=img_size,
        device=device,
        batch=8,
        patience=50,
        save=True,
        plots=True,
        lr0=0.001,
        lrf=0.01,
        freeze=5,
        project=project_name,
        name=f'stage2_{timestamp}'
    )
    
    print(f"\n第三阶段: 最终精调 ({stage3_epochs} epochs)")
    print(f"- 解冻所有层，使用低学习率进行最终优化")
    best_model2 = f'runs/detect/{project_name}/stage2_{timestamp}/weights/best.pt'
    model = YOLO(best_model2)
    results = model.train(
        data=data_yaml,
        epochs=stage3_epochs,
        imgsz=img_size,
        device=device,
        batch=8,
        patience=50,
        save=True,
        plots=True,
        lr0=0.0001,
        lrf=0.001,
        freeze=0,
        project=project_name,
        name=f'stage3_{timestamp}'
    )
    
    final_model = f'runs/detect/{project_name}/stage3_{timestamp}/weights/best.pt'
    print(f"\n" + "=" * 60)
    print(f"三阶段训练完成！")
    print(f"最终模型: {final_model}")
    print(f"=" * 60)
    
    val_results = model.val(data=data_yaml, imgsz=img_size, device=device, split='val')
    print_results(val_results, "验证集")
    
    test_results = model.val(data=data_yaml, imgsz=img_size, device=device, split='test')
    print_results(test_results, "测试集")
    
    return final_model

def print_results(results, title="验证集"):
    print(f"\n{title}:")
    print(f"    - 精确率 (Precision): {results.box.mp:.2%}")
    print(f"    - 召回率 (Recall): {results.box.mr:.2%}")
    print(f"    - mAP@0.5: {results.box.map50:.2%}")
    print(f"    - mAP@0.5:0.95: {results.box.map:.2%}")

def train_normal(data_yaml, model_name='yolo11n.pt', img_size=640, epochs=100, device='0', project_name='corn_disease_final'):
    from ultralytics import YOLO
    from datetime import datetime
    
    timestamp = datetime.now().strftime('%Y%m%d_%H%M%S')
    
    print(f"=" * 60)
    print(f"开始标准训练策略")
    print(f"项目名称: {project_name}_{timestamp}")
    print(f"=" * 60)
    
    model = YOLO(model_name)
    
    results = model.train(
        data=data_yaml,
        epochs=epochs,
        imgsz=img_size,
        device=device,
        batch=8,
        patience=50,
        save=True,
        plots=True,
        project=project_name,
        name=f'normal_{timestamp}'
    )
    
    final_model = f'runs/detect/{project_name}/normal_{timestamp}/weights/best.pt'
    print(f"\n训练完成！")
    print(f"最终模型: {final_model}")
    
    val_results = model.val(data=data_yaml, imgsz=img_size, device=device, split='val')
    print_results(val_results, "验证集")
    
    test_results = model.val(data=data_yaml, imgsz=img_size, device=device, split='test')
    print_results(test_results, "测试集")
    
    return final_model

def main():
    parser = argparse.ArgumentParser(description='玉米病害检测训练脚本')
    parser.add_argument('--data', type=str, default='data.yaml', help='数据集配置文件路径')
    parser.add_argument('--model', type=str, default='yolo11n.pt', help='预训练模型')
    parser.add_argument('--img-size', type=int, default=640, help='输入图像尺寸')
    parser.add_argument('--epochs', type=int, default=100, help='总训练轮数')
    parser.add_argument('--device', type=str, default='0', help='使用的设备 (0 或 cpu)')
    parser.add_argument('--project', type=str, default='corn_disease_final', help='项目名称，用于避免覆盖之前结果')
    parser.add_argument('--three-stage', action='store_true', help='使用三阶段训练策略')
    
    args = parser.parse_args()
    
    if not check_yolo_available():
        print("错误: 未检测到 ultralytics 库")
        print("请运行: pip install ultralytics")
        return
    
    data_path = Path(args.data)
    if not data_path.exists():
        print(f"错误: 找不到数据集配置文件 {args.data}")
        return
    
    if args.three_stage:
        final_model = train_three_stage(
            data_yaml=args.data,
            model_name=args.model,
            img_size=args.img_size,
            epochs=args.epochs,
            device=args.device,
            project_name=args.project
        )
    else:
        final_model = train_normal(
            data_yaml=args.data,
            model_name=args.model,
            img_size=args.img_size,
            epochs=args.epochs,
            device=args.device,
            project_name=args.project
        )

if __name__ == '__main__':
    main()
