from PIL import Image, ImageDraw
import os

# Colors from design philosophy
BACKGROUND = (10, 10, 18, 255)  # #0a0a12 with alpha
CYAN = (0, 240, 255)
PURPLE = (191, 0, 255)
PINK = (255, 0, 170)

def create_icon(size):
    """Create app icon with cyberpunk style - high quality"""
    # Create RGBA image
    img = Image.new('RGBA', (size, size), BACKGROUND)
    draw = ImageDraw.Draw(img)
    
    center = size // 2
    
    # Outer circle padding
    padding = size // 8
    
    # Calculate ring dimensions
    ring_outer_radius = (size - 2 * padding) // 2
    ring_inner_radius = ring_outer_radius - max(4, size // 20)
    
    # Draw outer glow (multiple layers for smooth gradient)
    for i in range(8, 0, -1):
        alpha = int(30 * (1 - i/8))
        glow_radius = ring_outer_radius + i
        glow_color = (*CYAN, alpha)
        
        # Draw glow ring
        for angle in range(360):
            import math
            rad = math.radians(angle)
            x1 = center + (glow_radius - 1) * math.cos(rad)
            y1 = center + (glow_radius - 1) * math.sin(rad)
            x2 = center + glow_radius * math.cos(rad)
            y2 = center + glow_radius * math.sin(rad)
            draw.line([(x1, y1), (x2, y2)], fill=glow_color, width=1)
    
    # Draw the main ring (gradient from cyan to purple)
    import math
    for angle in range(360):
        rad = math.radians(angle)
        # Interpolate color from cyan to purple
        t = angle / 360.0
        r = int(CYAN[0] * (1-t) + PURPLE[0] * t)
        g = int(CYAN[1] * (1-t) + PURPLE[1] * t)
        b = int(CYAN[2] * (1-t) + PURPLE[2] * t)
        
        # Outer edge
        x1 = center + ring_inner_radius * math.cos(rad)
        y1 = center + ring_inner_radius * math.sin(rad)
        x2 = center + ring_outer_radius * math.cos(rad)
        y2 = center + ring_outer_radius * math.sin(rad)
        
        draw.line([(x1, y1), (x2, y2)], fill=(r, g, b, 255), width=1)
    
    # Draw center dot with glow
    dot_radius = max(4, size // 16)
    
    # Multi-layer glow
    for i in range(6, 0, -1):
        glow_alpha = int(50 * (1 - i/6))
        glow_radius = dot_radius + i * 2
        glow_color = (*PINK, glow_alpha)
        
        for angle in range(360):
            rad = math.radians(angle)
            x = center + glow_radius * math.cos(rad)
            y = center + glow_radius * math.sin(rad)
            if 0 <= int(x) < size and 0 <= int(y) < size:
                draw.point((int(x), int(y)), fill=glow_color)
    
    # Main center dot
    for x in range(center - dot_radius, center + dot_radius + 1):
        for y in range(center - dot_radius, center + dot_radius + 1):
            if (x - center) ** 2 + (y - center) ** 2 <= dot_radius ** 2:
                draw.point((x, y), fill=(*PINK, 255))
    
    return img

def main():
    sizes = {
        'mdpi': 48,
        'hdpi': 72,
        'xhdpi': 96,
        'xxhdpi': 144,
        'xxxhdpi': 192
    }
    
    res_dir = 'android/app/src/main/res'
    
    for density, size in sizes.items():
        mipmap_dir = f'{res_dir}/mipmap-{density}'
        os.makedirs(mipmap_dir, exist_ok=True)
        
        icon = create_icon(size)
        output_path = f'{mipmap_dir}/ic_launcher.png'
        icon.save(output_path, 'PNG')
        print(f'Created: {output_path} ({size}x{size})')
    
    print('\nAll icons regenerated!')

if __name__ == '__main__':
    main()
