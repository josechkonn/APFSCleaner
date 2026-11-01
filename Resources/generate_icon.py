import os
import math
from PIL import Image, ImageDraw, ImageFilter

def create_mac_app_icon():
    size = 1024
    img = Image.new("RGBA", (size, size), (0, 0, 0, 0))
    
    # 1. Squircle estándar de macOS (HIG)
    margin = 105
    squircle_box = [margin, margin, size - margin, size - margin]
    corner_radius = 185

    # Máscara squircle
    mask = Image.new("L", (size, size), 0)
    draw_mask = ImageDraw.Draw(mask)
    draw_mask.rounded_rectangle(squircle_box, radius=corner_radius, fill=255)

    # 2. Sombra de profundidad de macOS
    shadow_mask = Image.new("RGBA", (size, size), (0, 0, 0, 0))
    draw_shadow = ImageDraw.Draw(shadow_mask)
    shadow_box = [margin, margin + 28, size - margin, size - margin + 40]
    draw_shadow.rounded_rectangle(shadow_box, radius=corner_radius, fill=(0, 0, 0, 130))
    shadow_blur = shadow_mask.filter(ImageFilter.GaussianBlur(radius=30))
    img.paste(shadow_blur, (0, 0), shadow_blur)

    # 3. Lienzo Cósmico CleanMyMac: Deep Midnight a Cosmic Indigo & Violet
    bg = Image.new("RGBA", (size, size), (0, 0, 0, 0))
    draw_bg = ImageDraw.Draw(bg)
    
    for y in range(margin, size - margin):
        factor = (y - margin) / (size - 2 * margin)
        # De Deep Midnight (#0A0B1A) a Royal Indigo (#180E38) y Cosmic Plum (#280D48)
        if factor < 0.5:
            f2 = factor * 2
            r = int(10 * (1 - f2) + 24 * f2)
            g = int(11 * (1 - f2) + 14 * f2)
            b = int(26 * (1 - f2) + 56 * f2)
        else:
            f2 = (factor - 0.5) * 2
            r = int(24 * (1 - f2) + 40 * f2)
            g = int(14 * (1 - f2) + 13 * f2)
            b = int(56 * (1 - f2) + 72 * f2)
        draw_bg.line([(margin, y), (size - margin, y)], fill=(r, g, b, 255))

    # Resplandor radial cósmico superior derecho (Aurora Glow)
    glow_overlay = Image.new("RGBA", (size, size), (0, 0, 0, 0))
    draw_glow = ImageDraw.Draw(glow_overlay)
    draw_glow.ellipse([size - 380, margin - 50, size + 150, margin + 480], fill=(133, 41, 230, 140)) # Violeta
    draw_glow.ellipse([margin - 80, size - 420, margin + 450, size + 100], fill=(0, 229, 255, 90))   # Neón Cyan
    glow_blurred = glow_overlay.filter(ImageFilter.GaussianBlur(80))
    bg.alpha_composite(glow_blurred)

    # Borde biselado superior con luz especular (cristal)
    border_overlay = Image.new("RGBA", (size, size), (0, 0, 0, 0))
    draw_border = ImageDraw.Draw(border_overlay)
    draw_border.rounded_rectangle(squircle_box, radius=corner_radius, outline=(255, 255, 255, 65), width=3)
    bg.alpha_composite(border_overlay)

    # 4. Elemento Central: Disco APFS Holográfico 3D con Núcleo Neón
    center_x, center_y = size // 2, size // 2 + 10
    disk_radius = 270

    disk_img = Image.new("RGBA", (size, size), (0, 0, 0, 0))
    draw_disk = ImageDraw.Draw(disk_img)

    # Sombra del disco
    draw_disk.ellipse(
        [center_x - disk_radius, center_y - disk_radius + 20, center_x + disk_radius, center_y + disk_radius + 20],
        fill=(0, 0, 0, 120)
    )
    disk_img = disk_img.filter(ImageFilter.GaussianBlur(16))
    draw_disk_front = ImageDraw.Draw(disk_img)

    # Capas de placas concéntricas del disco APFS
    for r_i in range(disk_radius, 0, -1):
        ratio = r_i / disk_radius
        wave = math.sin(ratio * 30) * 12
        r_c = max(15, min(95, int(22 + (1 - ratio) * 55 + wave)))
        g_c = max(20, min(115, int(30 + (1 - ratio) * 65 + wave)))
        b_c = max(40, min(150, int(60 + (1 - ratio) * 85 + wave)))
        draw_disk_front.ellipse(
            [center_x - r_i, center_y - r_i, center_x + r_i, center_y + r_i],
            outline=(r_c, g_c, b_c, 255),
            width=2
        )

    # Bloques de datos APFS flotantes (anillo luminoso de bloques)
    num_blocks = 16
    for i in range(num_blocks):
        angle = (i / num_blocks) * 2 * math.pi
        rad = disk_radius - 36
        bx = center_x + int(math.cos(angle) * rad)
        by = center_y + int(math.sin(angle) * rad)
        
        # Alternancia entre Bloques Cian (Almacenamiento Local) y Azul Eléctrico (Externo)
        fill_color = (0, 229, 255, 230) if i % 2 == 0 else (59, 130, 246, 210)
        draw_disk_front.rounded_rectangle(
            [bx - 9, by - 9, bx + 9, by + 9],
            radius=4,
            fill=fill_color,
            outline=(255, 255, 255, 220)
        )

    # Anillo exterior de luz neón
    draw_disk_front.ellipse(
        [center_x - disk_radius, center_y - disk_radius, center_x + disk_radius, center_y + disk_radius],
        outline=(0, 229, 255, 160),
        width=3
    )

    # Núcleo de Cristal / Prisma Central
    hub_radius = 85
    for r_h in range(hub_radius, 0, -1):
        h_ratio = r_h / hub_radius
        v_r = int(30 + h_ratio * 100)
        v_g = int(20 + h_ratio * 80)
        v_b = int(70 + h_ratio * 180)
        draw_disk_front.ellipse(
            [center_x - r_h, center_y - r_h, center_x + r_h, center_y + r_h],
            fill=(v_r, v_g, v_b, 255)
        )
    # Lente central con destello
    draw_disk_front.ellipse(
        [center_x - 28, center_y - 28, center_x + 28, center_y + 28],
        fill=(10, 14, 30, 255),
        outline=(0, 229, 255, 200),
        width=2
    )

    # 5. Destello de Limpieza Prismático "Aurora Sparkle" (CleanMyMac Standard)
    spark_img = Image.new("RGBA", (size, size), (0, 0, 0, 0))
    draw_spark = ImageDraw.Draw(spark_img)

    sx, sy = center_x + 145, center_y - 145
    spark_len = 145
    spark_w = 26

    # Resplandor exterior esmeralda/turquesa del destello
    draw_spark.ellipse([sx - 110, sy - 110, sx + 110, sy + 110], fill=(0, 255, 210, 80))
    draw_spark.ellipse([sx - 60, sy - 60, sx + 60, sy + 60], fill=(224, 46, 204, 70))
    spark_img = spark_img.filter(ImageFilter.GaussianBlur(18))
    draw_spark2 = ImageDraw.Draw(spark_img)

    # Puntas verticales y horizontales afiladas
    draw_spark2.polygon([
        (sx, sy - spark_len),
        (sx + spark_w // 2, sy),
        (sx, sy + spark_len),
        (sx - spark_w // 2, sy)
    ], fill=(255, 255, 255, 255))

    draw_spark2.polygon([
        (sx - spark_len, sy),
        (sx, sy + spark_w // 2),
        (sx + spark_len, sy),
        (sx, sy - spark_w // 2)
    ], fill=(255, 255, 255, 255))

    # Rayo diagonal secundario
    diag_len = 50
    draw_spark2.line([(sx - diag_len, sy - diag_len), (sx + diag_len, sy + diag_len)], fill=(255, 255, 255, 200), width=4)
    draw_spark2.line([(sx - diag_len, sy + diag_len), (sx + diag_len, sy - diag_len)], fill=(255, 255, 255, 200), width=4)

    # Centro de luz
    draw_spark2.ellipse([sx - 18, sy - 18, sx + 18, sy + 18], fill=(0, 255, 220, 255))
    draw_spark2.ellipse([sx - 8, sy - 8, sx + 8, sy + 8], fill=(255, 255, 255, 255))

    # 6. Símbolo de Puente a Disco Externo en la esquina inferior izquierda
    bridge_img = Image.new("RGBA", (size, size), (0, 0, 0, 0))
    draw_bridge = ImageDraw.Draw(bridge_img)
    bx_pos, by_pos = center_x - 145, center_y + 145
    # Pastilla externa de almacenamiento
    draw_bridge.rounded_rectangle([bx_pos - 42, by_pos - 26, bx_pos + 42, by_pos + 26], radius=10, fill=(20, 28, 55, 220), outline=(59, 130, 246, 220), width=3)
    # LED verde activo
    draw_bridge.ellipse([bx_pos - 26, by_pos - 5, bx_pos - 16, by_pos + 5], fill=(31, 224, 140, 255))
    # Flecha hacia el disco
    draw_bridge.line([(bx_pos + 2, by_pos), (bx_pos + 22, by_pos)], fill=(0, 229, 255, 255), width=3)
    draw_bridge.polygon([(bx_pos + 26, by_pos), (bx_pos + 18, by_pos - 6), (bx_pos + 18, by_pos + 6)], fill=(0, 229, 255, 255))

    # Composición final
    content = Image.new("RGBA", (size, size), (0, 0, 0, 0))
    content.alpha_composite(bg)
    content.alpha_composite(disk_img)
    content.alpha_composite(bridge_img)
    content.alpha_composite(spark_img)

    final_icon = Image.new("RGBA", (size, size), (0, 0, 0, 0))
    final_icon.paste(content, (0, 0), mask)
    img.alpha_composite(final_icon)

    # Guardar en iconset
    iconset_dir = "/tmp/APFSCleaner.iconset"
    os.makedirs(iconset_dir, exist_ok=True)

    sizes = [
        (16, "icon_16x16.png"),
        (32, "icon_16x16@2x.png"),
        (32, "icon_32x32.png"),
        (64, "icon_32x32@2x.png"),
        (128, "icon_128x128.png"),
        (256, "icon_128x128@2x.png"),
        (256, "icon_256x256.png"),
        (512, "icon_256x256@2x.png"),
        (512, "icon_512x512.png"),
        (1024, "icon_512x512@2x.png"),
    ]

    for s, name in sizes:
        resized = img.resize((s, s), Image.Resampling.LANCZOS)
        resized.save(os.path.join(iconset_dir, name), "PNG")

    print(f"✅ Iconset generado en {iconset_dir}")

if __name__ == "__main__":
    create_mac_app_icon()
