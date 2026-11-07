import os
import shutil
import random
from pathlib import Path

def split_dataset():
    random.seed(42)
    
    base_dir = Path("train")
    images_dir = base_dir / "images"
    labels_dir = base_dir / "labels"
    
    output_base = Path("dataset")
    splits = {
        "train": 0.7,
        "val": 0.2,
        "test": 0.1
    }
    
    image_files = list(images_dir.glob("*.jpg"))
    random.shuffle(image_files)
    
    total = len(image_files)
    train_end = int(total * splits["train"])
    val_end = train_end + int(total * splits["val"])
    
    split_files = {
        "train": image_files[:train_end],
        "val": image_files[train_end:val_end],
        "test": image_files[val_end:]
    }
    
    print(f"数据集总数: {total} 张")
    for split_name, files in split_files.items():
        print(f"  {split_name}: {len(files)} 张")
    
    for split_name, files in split_files.items():
        img_out = output_base / split_name / "images"
        lbl_out = output_base / split_name / "labels"
        img_out.mkdir(parents=True, exist_ok=True)
        lbl_out.mkdir(parents=True, exist_ok=True)
        
        for img_path in files:
            lbl_path = labels_dir / (img_path.stem + ".txt")
            
            shutil.copy2(img_path, img_out / img_path.name)
            if lbl_path.exists():
                shutil.copy2(lbl_path, lbl_out / lbl_path.name)
    
    print("\n数据集划分完成！")
    print(f"输出目录: {output_base.absolute()}")

if __name__ == "__main__":
    split_dataset()
