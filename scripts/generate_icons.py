from PIL import Image, ImageDraw
import os

# Colors from design philosophy
BACKGROUND = (10, 10, 18)  # #0a0a12
CYAN = (0, 240, 255)  # #00f0ff
PURPLE = (191, 0, 255)  # #bf00ff
PINK = (255, 0, 170)  # #ff00aa

def create_icon(size):
    """Create app icon with cyberpunk style"""
    img = Image.new('RGBA', (size, size), BACKGROUND)
    draw = ImageDraw.Draw(img)
    
    # Calculate dimensions
    padding = size // 6
    circle_bounds = [
        padding,
        padding,
        size - padding,
        size - padding
    ]
    
    # Create gradient ring effect by drawing multiple circles
    ring_width = max(2, size // 20)
    
    # Outer glow (cyan)
    for i in range(3):
        alpha = int(30 - i * 10)
        glow_color = (*CYAN[:3], alpha)
        glow_bounds = [
            padding - i - 2,
            padding - i - 2,
            size - padding + i + 2,
            size - padding + i + 2
        ]
        draw.ellipse(glow_bounds, outline=glow_color, width=ring_width + 2)
    
    # Main ring with gradient segments
    # Top-right quadrant: Cyan to Purple
    # Bottom-right quadrant: Purple to Pink
    # Bottom-left quadrant: Pink
    # Top-left quadrant: Cyan
    
    # Draw the main ring as an arc with varying colors
    # We'll approximate by drawing the full ellipse with the primary color
    draw.ellipse(circle_bounds, outline=CYAN, width=ring_width)
    
    # Add gradient segments using partial ellipses
    center = size // 2
    radius = (size - 2 * padding) // 2
    
    # Inner decorative element - small circle or timer hand
    inner_size = radius // 2
    inner_bounds = [
        center - inner_size // 2,
        center - inner_size // 2,
        center + inner_size // 2,
        center + inner_size // 2
    ]
    
    # Draw a small glowing dot at the top (12 o'clock position)
    dot_size = max(3, size // 15)
    dot_y = padding + ring_width
    dot_x = center
    
    # Glow for dot
    for i in range(4, 0, -1):
        glow_alpha = int(80 - i * 15)
        glow_size = dot_size + i * 2
        glow_bounds = [
            dot_x - glow_size,
            dot_y - glow_size,
            dot_x + glow_size,
            dot_y + glow_size
        ]
        draw.ellipse(glow_bounds, fill=(*PINK[:3], glow_alpha))
    
    # Main dot
    dot_bounds = [
        dot_x - dot_size,
        dot_y - dot_size,
        dot_x + dot_size,
        dot_y + dot_size
    ]
    draw.ellipse(dot_bounds, fill=PINK)
    
    # Add "W" or timer symbol in center (stylized)
    line_color = (*CYAN[:3], 200)
    line_width = max(1, size // 40)
    
    # Draw two tick marks at 3 and 9 o'clock
    tick_length = radius // 4
    # 3 o'clock
    draw.line([
        (size - padding - ring_width, center),
        (size - padding - ring_width - tick_length, center)
    ], fill=line_color, width=line_width)
    
    # 9 o'clock
    draw.line([
        (padding + ring_width, center),
        (padding + ring_width + tick_length, center)
    ], fill=line_color, width=line_width)
    
    return img

def main():
    # Android icon sizes
    sizes = {
        'mdpi': 48,
        'hdpi': 72,
        'xhdpi': 96,
        'xxhdpi': 144,
        'xxxhdpi': 192
    }
    
    # Create directories if needed
    res_dir = '../android/app/src/main/res'
    
    for density, size in sizes.items():
        mipmap_dir = f'{res_dir}/mipmap-{density}'
        os.makedirs(mipmap_dir, exist_ok=True)
        
        # Create icon
        icon = create_icon(size)
        
        # Save
        output_path = f'{mipmap_dir}/ic_launcher.png'
        icon.save(output_path, 'PNG')
        print(f'Created: {output_path} ({size}x{size})')
    
    print('\nIcons created successfully!')

if __name__ == '__main__':
    main()
