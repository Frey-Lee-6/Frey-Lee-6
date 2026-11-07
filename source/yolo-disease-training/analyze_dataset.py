import os
from pathlib import Path
from collections import Counter

labels_dir = Path("train/labels")
class_counts = Counter()

total_images = 0
for label_file in labels_dir.glob("*.txt"):
    total_images += 1
    with open(label_file, 'r') as f:
        for line in f:
            parts = line.strip().split()
            if parts:
                class_id = int(parts[0])
                class_counts[class_id] += 1

print(f"数据集统计:")
print(f"总图片数: {total_images}")
print(f"总目标数: {sum(class_counts.values())}")
print(f"\n类别分布:")
class_names = ["0 BrownSpot", "1 RiceBlast", "2 BacterialBlight"]
for class_id, count in sorted(class_counts.items()):
    print(f"  {class_names[class_id]}: {count} 个目标")
