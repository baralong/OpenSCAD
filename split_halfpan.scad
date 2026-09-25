// --- Parameters ---
$fn = 64;           // Increased resolution for smooth curves

base_x = 18;       // Base width (mm)
base_y = 15;       // Base depth (mm)
height = 10;       // Total height (mm)
flare = 0.5;       // Flare per side (mm)
wall_thick = 1.0;  // Outer wall and divider thickness (mm)
r_corner = 1.0;    // Outer corner radius (mm)
dividers = 1;      // Number of interior dividing walls

// Magnet Recess Parameters
magnet_dia = 10.5; // Diameter (10.5mm for 10mm magnet tolerance)
magnet_h = 0.5;    // Recess depth (mm)

// --- Derived Calculations ---
top_x = base_x + (flare * 2);
top_y = base_y + (flare * 2);

scale_x = top_x / base_x;
scale_y = top_y / base_y;

// --- Modules ---

// 2D base profile with rounded corners
module rounded_rect(w, h, r) {
    offset(r = r)
        square([w - 2*r, h - 2*r], center = true);
}

// Solid flared pan body
module outer_pan_solid() {
    linear_extrude(height = height, scale = [scale_x, scale_y])
        rounded_rect(base_x, base_y, r_corner);
}

// Interior negative space to subtract
module inner_cavity() {
    in_base_x = base_x - (2 * wall_thick);
    in_base_y = base_y - (2 * wall_thick);
    
    in_top_x = top_x - (2 * wall_thick);
    in_top_y = top_y - (2 * wall_thick);
    
    in_scale_x = in_top_x / in_base_x;
    in_scale_y = in_top_y / in_base_y;
    
    in_r_corner = max(0.1, r_corner - wall_thick);

    translate([0, 0, wall_thick])
        linear_extrude(height = height, scale = [in_scale_x, in_scale_y])
            rounded_rect(in_base_x, in_base_y, in_r_corner);
}

// Underside magnet recess cylinder
module magnet_recess() {
    // Offset slightly below Z=0 (-0.01) to prevent zero-thickness surface rendering glitches
    translate([0, 0, -0.01])
        cylinder(d = magnet_dia, h = magnet_h + 0.01);
}

// Internal divider wall(s) matching the flared profile
module divider_walls() {
    if (dividers > 0) {
        step = top_x / (dividers + 1);
        for (i = [1 : dividers]) {
            x_pos = -top_x/2 + i * step;
            // Center X and Y, but start Z directly at magnet_h
            translate([x_pos - wall_thick/2, -top_y/2, magnet_h])
                cube([wall_thick, top_y, height - magnet_h], center = false);        }
    }
}

module divided_pan() { 
    // --- Main Assembly ---
    difference() {
        outer_pan_solid();
        inner_cavity();
        magnet_recess(); // Subtracted from bottom center
    }

    // Intersect dividers with outer shell so they flare naturally along walls
    intersection() {
        outer_pan_solid();
        divider_walls();
    }
}

module pan_array(x_count, y_count) {
    spacing = 1;
    for (i = [0 : x_count - 1]) {
        for (j = [0 : y_count - 1]) {
            translate([i * (top_x + spacing), j * (top_y + spacing)])
                divided_pan();
        }
    }
}
pan_array(1,1);