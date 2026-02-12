from PIL import Image, ImageDraw
import os

# Colors from design philosophy
BACKGROUND = (10, 10, 18)  # #0a0a12
CYAN = (0, 240, 255)  # #00f0ff
PURPLE = (191, 0, 255)  # #bf00ff
PINK = (255, 0, 170)  # #ff00aa

def create_round_icon(size):
    """Create round app icon with cyberpunk style"""
    img = Image.new('RGBA', (size, size), (0, 0, 0, 0))
    draw = ImageDraw.Draw(img)
    
    # Create circular background
    circle_bounds = [0, 0, size, size]
    draw.ellipse(circle_bounds, fill=BACKGROUND)
    
    # Calculate dimensions for inner elements
    padding = size // 5
    inner_bounds = [
        padding,
        padding,
        size - padding,
        size - padding
    ]
    
    # Ring width
    ring_width = max(2, size // 15)
    
    # Outer glow
    for i in range(3):
        alpha = int(40 - i * 12)
        glow_color = (*CYAN[:3], alpha)
        glow_bounds = [
            padding - i - 1,
            padding - i - 1,
            size - padding + i + 1,
            size - padding + i + 1
        ]
        draw.ellipse(glow_bounds, outline=glow_color, width=ring_width)
    
    # Main ring
    draw.ellipse(inner_bounds, outline=CYAN, width=ring_width)
    
    # Center dot (glowing pink)
    center = size // 2
    dot_size = max(2, size // 12)
    
    # Glow
    for i in range(3, 0, -1):
        glow_alpha = int(60 - i * 15)
        glow_size = dot_size + i
        glow_bounds = [
            center - glow_size,
            center - glow_size,
            center + glow_size,
            center + glow_size
        ]
        draw.ellipse(glow_bounds, fill=(*PINK[:3], glow_alpha))
    
    # Main dot
    dot_bounds = [
        center - dot_size,
        center - dot_size,
        center + dot_size,
        center + dot_size
    ]
    draw.ellipse(dot_bounds, fill=PINK)
    
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
    
    res_dir = '../android/app/src/main/res'
    
    for density, size in sizes.items():
        mipmap_dir = f'{res_dir}/mipmap-{density}'
        os.makedirs(mipmap_dir, exist_ok=True)
        
        # Create round icon
        icon = create_round_icon(size)
        
        # Save
        output_path = f'{mipmap_dir}/ic_launcher_round.png'
        icon.save(output_path, 'PNG')
        print(f'Created: {output_path} ({size}x{size})')
    
    print('\nRound icons created successfully!')

if __name__ == '__main__':
    main()
