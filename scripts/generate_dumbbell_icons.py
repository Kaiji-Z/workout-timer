from PIL import Image, ImageDraw
import os
import math

# Cyberpunk colors
BACKGROUND = (10, 10, 18, 255)  # #0a0a12
DARK_BG = (20, 20, 35, 255)
CYAN = (0, 240, 255)
PURPLE = (191, 0, 255)
PINK = (255, 0, 170)

def draw_rounded_rectangle(draw, bounds, radius, fill):
    """Draw a rounded rectangle"""
    x1, y1, x2, y2 = bounds
    
    # Draw main rectangle
    draw.rectangle([x1 + radius, y1, x2 - radius, y2], fill=fill)
    draw.rectangle([x1, y1 + radius, x2, y2 - radius], fill=fill)
    
    # Draw four corners
    draw.pieslice([x1, y1, x1 + radius * 2, y1 + radius * 2], 180, 270, fill=fill)
    draw.pieslice([x2 - radius * 2, y1, x2, y1 + radius * 2], 270, 360, fill=fill)
    draw.pieslice([x1, y2 - radius * 2, x1 + radius * 2, y2], 90, 180, fill=fill)
    draw.pieslice([x2 - radius * 2, y2 - radius * 2, x2, y2], 0, 90, fill=fill)

def draw_dumbbell(draw, center_x, center_y, width, height, color, glow_color):
    """Draw a dumbbell with glow effect"""
    # Glow effect
    for i in range(4, 0, -1):
        alpha = int(40 - i * 8)
        glow_offset = i * 2
        
        # Left weight glow
        draw.rounded_rectangle(
            [center_x - width//2 - glow_offset, center_y - height//2 - glow_offset,
             center_x - width//6 + glow_offset, center_y + height//2 + glow_offset],
            radius=height//4,
            fill=(*glow_color[:3], alpha)
        )
        
        # Right weight glow
        draw.rounded_rectangle(
            [center_x + width//6 - glow_offset, center_y - height//2 - glow_offset,
             center_x + width//2 + glow_offset, center_y + height//2 + glow_offset],
            radius=height//4,
            fill=(*glow_color[:3], alpha)
        )
        
        # Handle glow
        draw.rounded_rectangle(
            [center_x - width//6 - glow_offset, center_y - height//8 - glow_offset,
             center_x + width//6 + glow_offset, center_y + height//8 + glow_offset],
            radius=height//16,
            fill=(*glow_color[:3], alpha)
        )
    
    # Main dumbbell parts
    # Left weight
    draw.rounded_rectangle(
        [center_x - width//2, center_y - height//2,
         center_x - width//6, center_y + height//2],
        radius=height//4,
        fill=color
    )
    
    # Right weight
    draw.rounded_rectangle(
        [center_x + width//6, center_y - height//2,
         center_x + width//2, center_y + height//2],
        radius=height//4,
        fill=color
    )
    
    # Handle
    draw.rounded_rectangle(
        [center_x - width//6, center_y - height//8,
         center_x + width//6, center_y + height//8],
        radius=height//16,
        fill=color
    )

def create_icon(size):
    """Create app icon with cyberpunk dumbbell"""
    img = Image.new('RGBA', (size, size), (0, 0, 0, 0))
    draw = ImageDraw.Draw(img)
    
    center = size // 2
    padding = size // 12
    
    # Rounded square background with gradient effect
    corner_radius = size // 8
    bg_bounds = [padding, padding, size - padding, size - padding]
    
    # Create gradient background
    for y in range(padding, size - padding):
        progress = (y - padding) / (size - 2 * padding)
        # Gradient from dark blue to dark purple
        r = int(20 + progress * 15)
        g = int(20 - progress * 5)
        b = int(35 + progress * 20)
        
        # Only draw within rounded bounds
        for x in range(padding + corner_radius, size - padding - corner_radius):
            draw.point((x, y), fill=(r, g, b, 255))
    
    # Fill corners
    draw.rounded_rectangle(bg_bounds, radius=corner_radius, fill=DARK_BG)
    
    # Add subtle border glow
    for i in range(3, 0, -1):
        alpha = int(30 - i * 8)
        border_bounds = [
            padding - i, padding - i,
            size - padding + i, size - padding + i
        ]
        draw.rounded_rectangle(
            border_bounds, radius=corner_radius + i,
            outline=(*CYAN, alpha), width=1
        )
    
    # Draw dumbbell
    dumbbell_width = size * 3 // 5
    dumbbell_height = size // 6
    
    draw_dumbbell(
        draw, center, center,
        dumbbell_width, dumbbell_height,
        CYAN, PURPLE
    )
    
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
    
    print('\n✅ Dumbbell icons created successfully!')

if __name__ == '__main__':
    main()
